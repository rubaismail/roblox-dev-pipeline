# Countdown Crew: greybox playtest

This is the script for stage 03 of [the pipeline](../../../docs/process.md). The gate is: **is the core loop fun with 5 outside players?** The design is in the [design doc](https://claude.ai/artifact/HbBDqWLaqgfps8EDoAJpEk).

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

## 3. The session (5 outside players, about 40 minutes)

"Outside" means they didn't build the game and haven't watched it being built. Publish to a private place or use a team test so they can join from their own devices. At least 2 should be on phones.

1. **Brief (2 min).** Say only: "You're a ground crew. Build the rocket shown at the top before the countdown hits zero. E grabs, F works, Q throws." Don't explain stations; finding them out is part of what we're testing.
2. **Play 2 missions (about 15 min)** with voice or in the same room. Don't help unless someone is stuck for over 60 s, and write down every time you had to.
3. **Free choice (5 min).** Say "That's all we need; you can stop or keep playing." Write down who keeps playing.
4. **Questions (10 min)**, one at a time, before any discussion:
    1. What was the funniest moment?
    2. When were you confused?
    3. Which station did you like least, and why?
    4. Would you play this with your friends? (Yes, maybe, no.)
    5. Phone players: was anything hard to press or reach?

## 4. Watch for

Write down the time and what happened:

- Moments of laughter or shouting, and what caused them, especially at launches.
- Players standing idle for over 10 s with nothing to do (the crew is too big for the work, or the flow is unclear).
- Wrong placements: tank on the crane without fuel, sections out of order, parts on the wrong station.
- Times someone said "what do I do?" or "where does this go?"
- Fires: how many, and whether anyone noticed in time.
- Did anyone use HOLD or LAUNCH NOW, and did they understand them?
- Outcome of every launch, and the final stars.

## 5. Pass or fail

The gate passes when **all** of these are true:

- At least 3 of 5 players ask to play again, or keep playing in the free-choice period.
- At least half the launches get off the pad by the second mission. The crew learned the flow without being taught.
- Nobody was stuck for over 60 s more than once.
- No bug made a launch unwinnable.

Fail on any one and the PR thread gets a short report: what failed, the notes, and the one change to try next. The pipeline allows 2 rounds before shelving.

## 6. Report

Post in the project thread: the checklist results, the notes from step 4, the answers, and pass or fail. Tuning numbers to change go in `src/shared/Tuning.luau` or `src/shared/Missions.luau`.
