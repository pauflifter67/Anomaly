# SECOND WIND — Anomaly Protocol

**OBSERVE. REMEMBER. SURVIVE.**

A first-person 3D anomaly-spotting game made for **Hack Club Haven** (theme: **BOUNCE BACK**).
Walk through a "perfectly normal" place, memorize it, then walk it again and report what changed.

Built with **Godot 4.7** (GDScript) by a team of four beginners.

## How to play

1. Walk through the **reference corridor**. Everything here is exactly as it should be. Remember it.
2. Enter the next corridor. Something may be different. Or nothing at all.
3. Reach the exit door and file your **Observation Report**: how many anomalies did you find?
4. A wrong report costs a mistake. Run out of mistakes and the protocol is terminated. Bounce back and try again.

### Controls

| Key | Action |
|---|---|
| W A S D | Move |
| Shift | Run |
| Mouse | Look |
| F | Flashlight |
| E | Interact (doors, report) |
| H | Hint (Easy only, once per corridor) |
| Esc | Pause |

### Maps

| Map | Setting | Recommended |
|---|---|---|
| The Hotel | Meridian Grand, 7th floor | Easy – Normal |
| The Station | Hollowmere Terminus | Normal |
| The Underground | Blackwater line, sealed 19 years ago | Hard |

Clear 3 rounds on a map to unlock the next one.

### Difficulty

| | Anomalies | Time per round | Mistakes allowed | Hints |
|---|---|---|---|---|
| Easy | obvious, up to 2 | none | 3 | yes |
| Normal | mixed, up to 3 | 3 min | 2 | no |
| Hard | very subtle, up to 4 | 90 sec | 1 | no |

## Run from source

1. Install [Godot 4.7](https://godotengine.org/download) (standard version, not .NET).
2. Clone this repository.
3. Open `project.godot` in Godot and press **F5**.

## Export (Windows)

Needs export templates installed (Editor → Manage Export Templates).
Project → Export → preset **Windows Desktop** → output goes to `сборка/SecondWind.exe`.

## Team

Second Wind Team — made for Hack Club Haven.

## License

MIT (see the `LICENSE` file in the `main` branch).
