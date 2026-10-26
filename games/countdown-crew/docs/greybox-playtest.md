# Countdown Crew: greybox playtest

This is the script for stage 03 of [the pipeline](../../../docs/process.md), leading to gate **G2 Fun proven**: at least 8 outside players in at least 2 sessions, following the [playtest protocol](../../../docs/process.md#playtest-protocol). The design is in the [design doc](https://claude.ai/artifact/HbBDqWLaqgfps8EDoAJpEk), and the risks this greybox has to retire are in the [risk register](tech-design.md#risk-register).

The greybox has one mission (Earth Pad, 3 launches), built from code with grey parts. There's no art, sound, saving, shop or tutorial yet; testers are told so up front.

## 1. Build and open the place

From `games/countdown-crew`:

```sh
rojo build default.project.json -o countdown-crew.rbxl
```

Open `countdown-crew.rbxl` in Studio. To work on the code live instead, open any place, run `rojo serve`, and connect from the Rojo plugin. A template baseplate and spawn are removed automatically when the game starts.

## 2. Smoke test, solo (10 minutes, before inviting anyone)

Press **Play** (F5). Run every check below. If any one fails, stop and report it in the PR thread instead of running the session.

| # | Do this | Expect |
|---|---------|--------|
| 1 | Wait 5 s after spawning | Briefing banner, then the countdown starts at 2:20 (solo gets 1.4x time). The build order shows at the top. |
| 2 | Walk to the conveyor's right end, press **E** | The first part (Engine) is picked up and floats in front of you. Whatever **E** would act on is outlined. |
| 3 | Walk to a workbench, press **E**, then hold **F** | The part sits on the bench; the yellow bar fills in about 2.5 s. |
| 4 | Pick the bolted engine up and press **E** at the yellow crane | The engine appears on the rocket behind the fence; the first chip turns green. |
| 5 | Bolt the fuel tank, place it on the blue fuel pump, and walk away | The blue bar fills in 6 s, turns red, and about 6 s later the pump catches fire and the tank is gone. A new tank arrives on the conveyor. |
| 6 | Grab the red extinguisher, stand at the pump, hold **F** | The fire goes out in about 1.5 s. |
| 7 | Press **Q** while holding a part | It's thrown forward. |
| 8 | Press **Shift** while moving | A short dash. |
| 9 | Press **H** | 15 s are added; "Holds left" drops to 1. |
| 10 | Finish the rocket, press **L** | It launches early: the camera follows it, and a banner shows the outcome, the reason and the points. |
| 11 | Let launch 2 run out with nothing stacked | It blows up on the pad (no damage to you) and scores 0. |
| 12 | Finish all 3 launches | The results banner shows stars and the total, then a new mission starts after the intermission. |
| 13 | **Test > Clients and Servers**: start a local server with 2 players | Both players see the same parts, fires and timer. One player can throw a part to the other, who catches it with empty hands. |
| 14 | In the Device Emulator, pick a phone | Grab, Use, Throw and Dash touch buttons appear; HOLD and LAUNCH NOW are tappable top-right; there's no jump button. |

## 3. The sessions (at least 8 outside players across at least 2 sessions, about 40 minutes each)

"Outside" means they didn't build the game and haven't watched it being built. Publish to a private place or use a team test so they can join from their own devices. At least 2 should be on phones.

1. **Brief (2 min).** Say only: "You're a ground crew. Build the rocket shown at the top before the countdown hits zero. E grabs, F works, Q throws." Don't explain stations; finding them out is part of what we're testing.
2. **Play 2 missions (about 15 min)** with voice or in the same room. Don't help unless someone is stuck for over 60 s, and write down every time you had to.
3. **Free choice (5 min).** Say "That's all we need; you can stop or keep playing." Write down who keeps playing.
4. **Survey (10 min)**, each tester answers alone before any discussion. The first four are the studio's standard survey; the rest are specific to this greybox.
    1. How fun was it, from 1 to 5?
    2. Would you play it again?
    3. What was confusing?
    4. How would you describe this game to a friend?
    5. What was the funniest moment?
    6. Which station did you like least, and why?
    7. Phone players: was anything hard to press or reach?

## 4. Watch for

Write down the time and what happened:

- Moments of laughter or shouting, and what caused them, especially at launches.
- Players standing idle for over 10 s with nothing to do (the crew is too big for the work, or the flow is unclear).
- Wrong placements: tank on the crane without fuel, sections out of order, parts on the wrong station.
- Times someone said "what do I do?" or "where does this go?"
- Fires: how many, and whether anyone noticed in time.
- Did anyone use HOLD or LAUNCH NOW, and did they understand them?
- Outcome of every launch, and the final stars.

## 5. What G2 needs

The gate criteria are in [docs/process.md](../../../docs/process.md#phases-and-gates). For this greybox, the evidence Yazeed reads at G2 is:

- **Would play again:** a majority of all testers say yes, or keep playing in the free-choice period.
- **Finish unprompted:** a clear majority finish a full 3-launch mission without being prompted.
- **Learning:** by the second mission, at least half the launches get off the pad, so crews learn the flow without being taught.
- **Risks:** each open row in the [risk register](tech-design.md#risk-register) is retired or has a plan.
- **Bugs:** no bug made a launch unwinnable.

If the first round falls short, the report names the one change to try next, and the second round tests it. The pipeline kills or returns the game after 2 failed rounds.

## 6. Report

Write one [playtest report](../../../docs/templates/playtest-report.md) per session, on the same day, and post it in the project thread. Bugs become GitHub Issues with a severity label. Tuning numbers to change go in `src/shared/Tuning.luau` or `src/shared/Missions.luau`. The G2 decision uses the [gate review template](../../../docs/templates/gate-review.md).
