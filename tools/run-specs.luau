--!nocheck
-- Runs a game's TestEZ specs outside Studio with Lune, so CI can run them on every pull request.
-- Usage, from the repo root: lune run tools/run-specs games/<game-name>
--
-- The specs require modules through the Rojo tree (game:GetService("ReplicatedStorage").Shared.X), so this
-- script reads the game's Rojo project, stands in for those instances with plain tables backed by files,
-- and gives each module Roblox's datatypes (Vector3, Color3, CFrame) from Lune's roblox library.
-- It supports the parts of TestEZ our specs use: describe, it, beforeEach, afterEach, and expect(...) with
-- to.equal, to.be.near, to.be.ok, to.be.a, to.throw and never. Code that needs a running game (services,
-- Instances, physics) can't run here; keep that out of the modules the specs cover.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local gameDir = process.args[1]
if not gameDir then
	print("Usage: lune run tools/run-specs games/<game-name>")
	process.exit(2)
end

local projectFile = `{gameDir}/test.project.json`
if not fs.isFile(projectFile) then
	projectFile = `{gameDir}/default.project.json`
end
local project = serde.decode("json", fs.readFile(projectFile))

-- Stand-in instances ----------------------------------------------------------------------------------------

local VirtualInstance = {}

local function newInstance(name, parent, file)
	return setmetatable({ Name = name, Parent = parent, __file = file, __children = {} }, VirtualInstance)
end

local function child(instance, name)
	return rawget(instance, "__children")[name]
end

VirtualInstance.__index = function(instance, key)
	if key == "WaitForChild" then
		return function(self, name)
			return child(self, name) or error(`{name} is not a child of {rawget(self, "Name")}`)
		end
	elseif key == "FindFirstChild" then
		return function(self, name)
			return child(self, name)
		end
	end
	local found = child(instance, key)
	if found == nil then
		error(`{key} is not a valid member of {rawget(instance, "Name")}`, 2)
	end
	return found
end

-- Mirrors a folder of Luau files the way Rojo syncs it. File access in Lune can yield, and a metamethod
-- can't, so the whole tree is read up front.
local function mirrorDir(instance, dir)
	for _, entry in fs.readDir(dir) do
		local path = `{dir}/{entry}`
		if fs.isDir(path) then
			local init = if fs.isFile(`{path}/init.luau`) then `{path}/init.luau` else nil
			local folder = newInstance(entry, instance, init)
			rawget(instance, "__children")[entry] = folder
			mirrorDir(folder, path)
		else
			local name = string.match(entry, "^(.-)%.luau?$")
			if name and name ~= "init" then
				-- Script suffixes (.server, .client) are part of the file name, not the instance name
				name = string.gsub(name, "%.server$", "")
				name = string.gsub(name, "%.client$", "")
				rawget(instance, "__children")[name] = newInstance(name, instance, path)
			end
		end
	end
end

-- Builds the stand-in for one node of the Rojo tree.
local function fromTree(name, node, parent)
	local path = node["$path"]
	if type(path) == "table" then
		path = path.optional
	end
	local instance = newInstance(name, parent, nil)
	if type(path) == "string" then
		local full = `{gameDir}/{path}`
		if fs.isDir(full) then
			mirrorDir(instance, full)
		elseif fs.isFile(full) then
			rawset(instance, "__file", full)
		end
	end
	for key, value in node do
		if string.sub(key, 1, 1) ~= "$" and type(value) == "table" then
			rawget(instance, "__children")[key] = fromTree(key, value, instance)
		end
	end
	return instance
end

local dataModel = fromTree("game", project.tree, nil)
rawset(dataModel, "GetService", function(self, serviceName)
	return child(self, serviceName) or error(`{serviceName} is not in the Rojo project`)
end)

-- Module loading --------------------------------------------------------------------------------------------

local cache = {}
local loading = {}
local makeEnvironment

local function virtualRequire(target)
	if type(target) ~= "table" or getmetatable(target) ~= VirtualInstance then
		error("require expects a module from the Rojo tree", 2)
	end
	local file = rawget(target, "__file") or error(`{rawget(target, "Name")} is not a module`, 2)
	if cache[file] ~= nil then
		return cache[file]
	end
	if loading[file] then
		error(`Circular require of {file}`, 2)
	end
	loading[file] = true
	local chunk = luau.load(fs.readFile(file), { debugName = file, environment = makeEnvironment(target) })
	local result = chunk()
	loading[file] = nil
	cache[file] = result
	return result
end

local testGlobals = {}

function makeEnvironment(scriptInstance)
	local environment = {
		game = dataModel,
		script = scriptInstance,
		require = virtualRequire,
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		Color3 = roblox.Color3,
		CFrame = roblox.CFrame,
		UDim2 = roblox.UDim2,
		Enum = roblox.Enum,
	}
	for name, value in testGlobals do
		environment[name] = value
	end
	return environment
end

-- A small TestEZ ----------------------------------------------------------------------------------------------

local passed, failed = 0, 0
local failures = {}
local scope = {}
local hooks = { { before = {}, after = {} } }

local function fullName(name)
	local parts = table.clone(scope)
	table.insert(parts, name)
	return table.concat(parts, " > ")
end

function testGlobals.describe(name, body)
	table.insert(scope, name)
	table.insert(hooks, { before = {}, after = {} })
	body()
	table.remove(hooks)
	table.remove(scope)
end

function testGlobals.beforeEach(fn)
	table.insert(hooks[#hooks].before, fn)
end

function testGlobals.afterEach(fn)
	table.insert(hooks[#hooks].after, fn)
end

function testGlobals.it(name, body)
	local ok, err = pcall(function()
		for _, level in hooks do
			for _, fn in level.before do
				fn()
			end
		end
		body()
		for index = #hooks, 1, -1 do
			for _, fn in hooks[index].after do
				fn()
			end
		end
	end)
	if ok then
		passed += 1
	else
		failed += 1
		table.insert(failures, `{fullName(name)}\n    {err}`)
	end
end

local function format(value)
	return if type(value) == "string" then `"{value}"` else tostring(value)
end

function testGlobals.expect(value)
	local negated = false
	local expectation = {}
	local function check(condition, message)
		if condition == negated then
			error((if negated then "Expected not: " else "Expected: ") .. message, 3)
		end
		return expectation
	end
	setmetatable(expectation, {
		__index = function(_, key)
			if key == "to" or key == "be" or key == "been" or key == "have" or key == "was" or key == "at" then
				return expectation
			elseif key == "never" then
				negated = not negated
				return expectation
			elseif key == "equal" then
				return function(expected)
					return check(value == expected, `{format(value)} to equal {format(expected)}`)
				end
			elseif key == "near" then
				return function(expected, limit)
					limit = limit or 1e-7
					return check(math.abs(value - expected) <= limit, `{format(value)} to be near {format(expected)}`)
				end
			elseif key == "ok" then
				return function()
					return check(value ~= nil and value ~= false, `{format(value)} to be ok`)
				end
			elseif key == "a" or key == "an" then
				return function(typeName)
					return check(typeof(value) == typeName, `{format(value)} to be a {typeName}`)
				end
			elseif key == "throw" then
				return function(fragment)
					local ok, err = pcall(value)
					local matches = not ok and (fragment == nil or string.find(tostring(err), fragment, 1, true) ~= nil)
					return check(matches, `function to throw {format(fragment)}`)
				end
			end
			error(`expect(...).{key} is not supported by tools/run-specs`, 2)
		end,
	})
	return expectation
end

-- Run ----------------------------------------------------------------------------------------------------------

local testsDir = `{gameDir}/tests`
local specFiles = {}
local function collect(dir)
	for _, entry in fs.readDir(dir) do
		local path = `{dir}/{entry}`
		if fs.isDir(path) then
			collect(path)
		elseif string.match(entry, "%.spec%.luau$") then
			table.insert(specFiles, path)
		end
	end
end
collect(testsDir)
table.sort(specFiles)

for _, file in specFiles do
	local specName = string.match(file, "([^/]+)%.spec%.luau$")
	table.insert(scope, specName)
	local ok, err = pcall(function()
		local specScript = newInstance(specName, nil, file)
		local spec = luau.load(fs.readFile(file), { debugName = file, environment = makeEnvironment(specScript) })()
		spec()
	end)
	if not ok then
		failed += 1
		table.insert(failures, `{specName} failed to load\n    {err}`)
	end
	table.remove(scope)
end

for _, failure in failures do
	print(`FAIL {failure}`)
end
print(`{passed} passed, {failed} failed, {#specFiles} spec files`)
process.exit(if failed > 0 then 1 else 0)
