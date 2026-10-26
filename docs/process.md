# How we make a Roblox game

The full workflow, with the diagram, lives in the [Roblox Game Pipeline](https://claude.ai/artifact/7YLDNGR8ie3QxgZ1b4REro) page. This is the short version.

| # | Stage | Output | Gate before moving on |
|---|-------|--------|------------------------|
| 01 | Idea intake | One-page concept | Not a direct copy of a game already on Roblox |
| 02 | Game design doc | Core loop, MVP list, monetization | Yazeed approves the doc |
| 03 | Greybox prototype | Playable core loop, no art (1 to 2 weeks) | Fun with 5 outside players, max 2 rounds |
| 04 | Production | One PR per feature | |
| 05 | Alpha test | 20+ outside players, funnel, bug list | Retention and bugs at target |
| 06 | Launch prep | Store page, passes, questionnaire | |
| 07 | Publish and soft launch | Public game, small ad spend | |
| 08 | Live ops | Weekly metrics report and one update per cycle | Loops back to production |

## Where code goes

- `games/<game-name>/` holds one game: its Rojo project, `wally.toml`, `src/` and `tests/`.
- `shared/` is for Luau libraries reused across games. It is empty until a second game needs something.
- Every change lands through a pull request, and CI runs StyLua and Selene on each one.
