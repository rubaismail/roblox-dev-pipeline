# Working in this repo

This repo holds our Roblox games and the process we make them with. Read `docs/process.md` before starting any task. It decides which stage a game is in and what that stage is allowed to produce.

## Rules

- Know which stage and gate the game is at, and do only that stage's work. Do not build production features during a prototype, and do not polish before G2.
- Gates are Yazeed's decisions. Prepare the packet with `docs/templates/gate-review.md` and give a recommendation. Never treat a gate as passed on your own.
- Every PR meets the Definition of Done in `docs/process.md`. The PR template carries it as a checklist.
- Hold code to the security, data and performance bars in `docs/process.md`. The server is authoritative, every remote is validated, and saves are versioned and session-locked.
- Before recommending a new game idea, search Roblox for direct copies. Live player counts cannot be read from a Claude session, so ask Yazeed for them and never report counts from page scrapes.

## Keep the process current

The process is supposed to improve as we learn. When something in it turns out to be wrong, missing, wasteful or unclear, do not quietly work around it:

1. Propose the edit to `docs/process.md` in a PR titled `Process: <what changed>`, or put it in the PR you are already working on if it is small.
2. Add one line to the Process changelog table that says what changed and what happened that led to it.
3. Tell Yazeed in one sentence what you changed and why.

Gate reviews, sprint retros and postmortems always end with a "process feedback" section. Every item in it gets a changelog line.
