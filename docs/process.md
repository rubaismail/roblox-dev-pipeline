# How we make a Roblox game

Eight stages take a game from a raw idea to live ops. Four gates stop weak ideas early, while they are cheap to kill. Yazeed makes the call at every gate; a Claude thread brings the evidence and a recommendation. The same workflow, styled, is on the [Roblox Game Pipeline](https://claude.ai/artifact/7YLDNGR8ie3QxgZ1b4REro) page.

```mermaid
flowchart TD
    subgraph Decide
        S1[01 Idea intake] --> G1{Direct copy<br/>already on Roblox?}
        G1 -- yes: add a twist or drop it --> S1
        G1 -- no --> S2[02 Game design doc]
        S2 --> G2{Yazeed approves<br/>the design doc?}
        G2 -- no: revise scope --> S2
    end
    subgraph Build
        G2 -- yes --> S3[03 Greybox prototype]
        S3 --> G3{Fun with 5<br/>outside players?}
        G3 -- no: iterate, max 2 rounds, then shelve --> S3
        G3 -- yes --> S4[04 Production]
        S4 --> S5[05 Alpha test]
        S5 --> G4{Retention and<br/>bugs at target?}
        G4 -- no: fix the biggest drop-off --> S4
    end
    subgraph Ship and run
        G4 -- yes --> S6[06 Launch prep]
        S6 --> S7[07 Publish and soft launch]
        S7 --> S8[08 Live ops]
        S8 -- weekly update cycle --> S4
    end
```

## Stages

| # | Stage | Owner | Output | Gate before moving on |
|---|-------|-------|--------|------------------------|
| 01 | Idea intake | Yazeed brings the idea, a Claude thread writes it up | One-page concept: hook, the game it is like, player count, session length, audience | Not a direct copy of a game already on Roblox |
| 02 | Game design doc | Claude thread drafts, Yazeed edits | Core loop (every 30 seconds, 5 minutes, per session), progression, MVP list, what is cut, monetization | Yazeed approves; the MVP fits in about 6 weeks |
| 03 | Greybox prototype | Yazeed in Studio, Claude threads write the Luau | Playable core loop with grey parts and no art (1 to 2 weeks) | Fun with 5 outside players; shelve after 2 failed rounds |
| 04 | Production | Claude threads open one PR per feature, Yazeed reviews and builds maps and art | MVP: saving, UI, tutorial, sound, art, mobile controls, analytics events | |
| 05 | Alpha test | Yazeed runs sessions, a thread reads the analytics | Playtests with 20+ outside players, a new-player funnel, a bug list | No crash or data-loss bugs; day-1 return rate hits the target set in the design doc |
| 06 | Launch prep | Yazeed, a thread drafts store copy and the checklist | Icon, thumbnails, description, priced passes and products, maturity questionnaire, odds for any paid random items | |
| 07 | Publish and soft launch | Yazeed | Public game, small ad or sponsored-experience budget | |
| 08 | Live ops | A recurring thread reads the Creator Dashboard weekly, Yazeed picks the update | Weekly report on retention, session length, concurrents and payer rate, then one focused update | Loops back to production |

## Gate checks in practice

- **Originality.** Search Roblox for the genre and its obvious names before recommending anything. A twist has to change the core loop, not just the theme. Live player counts cannot be read from a Claude session, so Yazeed checks them on Roblox directly.
- **Fun.** Testers did not make the game and play for 15 minutes. The signal is whether they ask to play again.
- **Ready.** Targets for retention come from the design doc, so the bar is set before anyone sees the numbers.

## Where code goes

- `games/<game-name>/` holds one game: its Rojo project, `wally.toml`, `src/` and `tests/`. The README covers setup and adding a game.
- `shared/` is for Luau libraries reused across games. It is empty until a second game needs something.
- Every change lands through a pull request, and CI runs StyLua and Selene on each one.
