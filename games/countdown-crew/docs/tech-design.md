# Countdown Crew: tech design and risk register

Stage 02 outputs that the greybox is built on. The game design itself is in the [design doc](https://claude.ai/artifact/HbBDqWLaqgfps8EDoAJpEk). This file covers the build as it stands in the greybox. It grows a save schema and analytics plan at the vertical slice (stage 04).

## Client and server split

The server is authoritative for everything that affects the outcome. The client only asks.

| Concern | Owner | Where |
|---|---|---|
| Mission phases, countdown, HOLD, LAUNCH NOW | Server | `src/server/Mission.luau` |
| Which item a player holds, where items sit, stacking | Server | `src/server/Items.luau`, `Mission.luau` |
| Bolting, fuelling, fires, extinguishing, conveyor | Server | `src/server/Stations.luau` |
| Flight outcome and points | Server, from pure rules | `src/shared/FlightModel.luau`, `Scoring.luau` |
| What Grab or Use would act on | Shared; the server acts on it, the client only highlights | `src/shared/Interaction.luau` |
| Camera, HUD, input, dash | Client | `src/client/` |
| Physics of a thrown item while it flies | The thrower's client, then back to the server after 1.5 s | `Items.throw` |
| The dash | Client (the player owns their character's physics) | `Controls.luau` |

Rules that decide outcomes live in plain modules with no services, covered by specs that run in CI: `Parts`, `PartState`, `StationRules`, `FlightModel`, `Scoring`, `Missions`, `RateLimiter`. Tuning numbers are all in `Tuning.luau`.

## Remotes and validation

| Remote | Direction | Payload | Validation |
|---|---|---|---|
| `CrewAction` | Client to server | One action name | Must be a string in `Net.Actions`. Each player is rate-limited to bursts of 20, then 10 a second; `UseEnd` is never dropped. Every action is checked against server state: the phase (items only move during the countdown), the caller's own character, reach (`Tuning.INTERACT_RANGE` from the station or item), and what the caller holds. LAUNCH NOW only counts with every section stacked. |
| `LaunchResult` | Server to clients | Outcome, label, reason, points, lines | Display only |
| `MissionState` attributes | Server to clients | Phase, time, recipe, stack, score, holds, stars | Display only. `TimeLeft` only changes once a second. |

Known gap: a thrower's client simulates its thrown item for 1.5 s and could move it anywhere in that time. That's acceptable in a co-op game with no currency. Before beta it gets a server check on where the item lands (the exploit pass in the security bar).

## Save schema

None in the greybox: nothing persists between missions. Stars, coins and cosmetics arrive at the vertical slice, with a versioned, session-locked schema (ProfileStore) per the data bar.

## Performance budget

The greybox targets the default quality bars. Per frame, the server scans tagged items (at most about 8 on the pad) for each player holding Use; clients run the highlight at 10 Hz. Neither is a concern at 6 players. Measure with the MicroProfiler at the vertical slice.

## Risk register

| Risk | Likelihood | Impact | Owner | How we retire it | Status |
|---|---|---|---|---|---|
| The core loop isn't fun: the building is busywork and the launch doesn't pay off | Medium | High | Yazeed | G2 playtests with the greybox | Open: the greybox is built |
| Phone controls are too fiddly for grab, use and throw | High | High | Claude engineering | Smoke-test step 14, then the phone testers at G2 | Open |
| Grabbing and throwing feel laggy because the server decides | Medium | Medium | Claude engineering | 2-player local server test, then a real session at G2 | Open |
| Large crews stand idle with only one conveyor | Medium | Medium | Design | Watch idle time at G2; add a second conveyor or a second rocket if needed | Open |
| Players don't understand stacking order, so rockets blow up and it feels unfair | Medium | Medium | Design | The build-order strip on the HUD plus the reason on every result; watch at G2 | Open |
| The game is a copy of something already on Roblox | Low | High | Yazeed | Originality scan for Overcooked-style and rocket games, done at G1 | Retired: cooking copies exist, but no timed co-op rocket crew game was found |
| An exploiter moves thrown items | Low | Low | Claude engineering | A server landing check, plus the exploit pass before beta | Open, accepted for the greybox |
