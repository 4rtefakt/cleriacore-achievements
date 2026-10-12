# Achievements

Thirty achievements for **Ys Origin** on CleriaCore, kept across **all your saves**. A card appears when one is
earned; **F1 > Mods > Achievements** lists them all with the date earned or your progress.

| | |
|---|---|
| **Fighting** | First Blood, Hunter (100 kills), Slayer (1 000), Exterminator (5 000), Chain Fighter (a kill at combo 30+), Overkill (500 damage in one hit), Still Standing (survive a hit worth half your HP) |
| **Growing** | Apprentice, Veteran, Legend (levels 10, 30, 60), Deep Pockets (100 000 SP), Devout (10 blessings) |
| **Exploring** | Lockpick (10 chests), Treasure Hunter (40), Key Master (all twelve locked doors), Glutton (200 drops) |
| **Bosses** | One for each of the six floor bosses, Untouchable (a boss fight won without a single hit), Close Call (won with a tenth of your HP or less) |
| **Finishing** | Summit (finish the game), one for each character, Deathless (no death in that save), Swift (under four hours of play) |

The mod only watches. It changes no number of the game.

## Install

1. Download `4rtefakt.achievements-1.0.0.cleriamod` from the [releases](../../releases).
2. Double-click it (or use F1 > Mods > *Install a mod file...*).
3. Turn **Achievements** on in F1 > Mods and restart CleriaCore.

Needs a CleriaCore with mod API 6.

## How it works

One Lua file, [main.lua](main.lua), about 170 lines. An achievement is a row in a table and one `earn("key")`
where it happens:

```lua
local hits_here = 0                                        -- hits taken since this room was entered
cleria.events.on("room_enter", function() hits_here = 0 end)
cleria.combat.add_filter("damage", function(q)
    if q.dir == "taken" and q.value > 0 then hits_here = hits_here + 1 end
    return nil                                             -- only watching
end)
cleria.events.on("boss_defeated", function(e)
    if hits_here == 0 then earn("untouchable") end
    if P.hp() <= P.max_hp() / 10 then earn("close_call") end
    if e.flag and e.flag <= 225 then earn("boss" .. e.flag) end
end)
```

| Part | API |
|---|---|
| Counts | the events `enemy_killed`, `chest_opened`, `door_opened`, `blessing_bought`, `pickup_collected` |
| Hitless fights, big hits, combos | the `"damage"` and `"exp"` combat filters used as probes |
| Bosses and the ending | `boss_defeated` with its flag, `game.character()` |
| Across saves | `cleria.data` (a JSON file of the install) |
| Per save (deaths, play time) | `cleria.save` |
| The cards and the list | `cleria.notice`, `cleria.ui.page` |

One thing the tests found: continuing after a death can bring back a save's storage as it was *before* the death
(the game reloads its continue snapshot), which silently erased the death count. The mod carries the count over
that reload.

## Tests

`python .dev/run.py` runs six cases through CleriaCore's headless harness: a kill, level 30 and a full wallet earn
their four achievements, which are still there after a restart; a boss flag with no hit taken earns the boss and
Untouchable; the same after a hit at 5 HP earns Close Call and not Untouchable; the end of Yunica's story earns
Summit, her tale, Deathless and Swift; the same after a death and a continue does not earn Deathless; a hit of half
the max HP earns Still Standing.

Not covered by a test: the counted ones beyond the first (100 kills, chests, doors, blessings, drops), Chain
Fighter and Overkill. Nobody has earned them in a real run yet.

## More CleriaCore mods

Each one is a small Lua mod that shows a different part of the mod API:

- [Mutators](https://github.com/4rtefakt/cleriacore-mutators): challenge rules: Glass Cannon, Berserker, One Hit, Vampire, Midas, Famine, Permadeath, a level cap
- [Solo Randomizer](https://github.com/4rtefakt/cleriacore-solo-randomizer): the tower's chests shuffled from a seed, always beatable, no server
- [Daily Challenge](https://github.com/4rtefakt/cleriacore-daily-challenge): the date shuffles the chests and picks two rules, the same for everyone
- [Roguelite Perks](https://github.com/4rtefakt/cleriacore-roguelite-perks): every boss beaten lets you choose one of three random perks
- [New Game+](https://github.com/4rtefakt/cleriacore-new-game-plus): start again with part of your level, SP and weapon against a harder tower
- [Level Sync](https://github.com/4rtefakt/cleriacore-level-sync): monsters fight as if they were near your level
- [Adaptive Difficulty](https://github.com/4rtefakt/cleriacore-adaptive-difficulty): enemies hit softer after each death, and return to normal as you progress
- [Run HUD](https://github.com/4rtefakt/cleriacore-run-hud): room and run time, kills, deaths, damage per second
- [Bestiary+](https://github.com/4rtefakt/cleriacore-bestiary): a per-save hunting log of every monster killed
- [Autosave+](https://github.com/4rtefakt/cleriacore-autosave): rolling autosaves on a timer, after bosses and in new zones
- [Debug Menu](https://github.com/4rtefakt/cleriacore-debug-menu): change level, SP, items, gear, skills, blessings, warps and flags
- [Crowd Control](https://github.com/4rtefakt/cleriacore-crowd-control): Twitch chat votes on what happens to you
- [LiveSplit Autosplitter](https://github.com/4rtefakt/cleriacore-livesplit): starts and splits LiveSplit over its WebSocket server
- [Archipelago](https://github.com/4rtefakt/ys-origin-cleriacore-ap): the multiworld randomizer client, the biggest one

## About

Written with AI assistance (Claude Code) as a showcase of the CleriaCore mod API, and tested as described above.
MIT license.
