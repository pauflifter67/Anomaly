# Текст для страницы itch.io (копировать в поля)

## Title
SECOND WIND — Anomaly Protocol

## Project URL (slug)
second-wind-anomaly-protocol

## Short description / tagline (до ~100 символов)
Memorize the place. Find what changed. Bounce back. A first-person anomaly-spotting game.

## Kind of project
Downloadable

## Classification
Game

## Release status
Prototype  (или "In development", если будете дорабатывать)

## Pricing
$0 or donate  (или No payments)

## Genre
Survival / Horror (itch позволяет один основной жанр; "Puzzle" тоже подходит)

## Tags (до 10)
anomaly, horror, first-person, 3d, atmospheric, godot, singleplayer, spot-the-difference, hack-club, short

## Made with
Godot

## Platforms
Windows

## Inputs
Keyboard, Mouse

## Number of players
Singleplayer

## Average session
A few minutes

## Accessibility
(по желанию) Easy mode: no time limit, 3 mistakes, optional hints.

---

## Description (вставлять в большое поле, поддерживается Markdown-подобное форматирование itch)

**OBSERVE. REMEMBER. SURVIVE.**

Everything here is exactly as it should be. Until it is not.

**SECOND WIND — Anomaly Protocol** is a first-person 3D game about paying attention.
You walk through a silent, "perfectly normal" place and memorize every detail:
the doors, the lamps, the paintings, the clocks. Then you walk it again.
Something may be different. Or nothing at all.

Reach the exit and file your **Observation Report**: how many anomalies did you find?
Report wrong, and you lose a mistake. Run out of mistakes, and the protocol ends.
Every mistake teaches the eye. Breathe. Look again. **Bounce back.**

### Features
- 3 handcrafted locations: the Hotel, the Station, the Underground
- A reference corridor to memorize before every run
- Anomalies from obvious to nearly invisible
- 3 difficulty levels: from "learn to look" to "doubt everything"
- Maps unlock as you clear rounds
- Flashlight, sprint, head bob, full settings menu (FOV, sensitivity, quality, fullscreen)
- Saves your progress and best scores

### Locations
- **The Hotel** — Meridian Grand, 7th floor. A silent luxury corridor.
- **The Station** — Hollowmere Terminus. No train has left in years.
- **The Underground** — Blackwater line, sealed 19 years ago. Near darkness. The hardest protocol.

### Difficulty
| | Anomalies | Time | Mistakes | Hints |
|---|---|---|---|---|
| Easy | obvious, up to 2 | no limit | 3 | yes (H) |
| Normal | mixed, up to 3 | 3 min / round | 2 | no |
| Hard | very subtle, up to 4 | 90 sec / round | 1 | no |

### Controls
- **WASD** — move
- **Shift** — run
- **Mouse** — look
- **F** — flashlight
- **E** — interact
- **H** — hint (Easy)
- **Esc** — pause

### About
Made by a team of four beginners for the **Hack Club Haven** game jam.
Theme: **BOUNCE BACK**. Built with Godot 4.7.

### Notes
- Windows only for now (64-bit).
- Windows may show a SmartScreen warning because the exe is unsigned: click "More info" → "Run anyway".
- Found a bug or have feedback? Leave a comment below!

---

## Что загрузить

1. Cover image: 630x500 (минимум 315x250). Можно взять `ассеты/текстуры/превью/отель.png` и подогнать.
2. Screenshots: 3–5 штук, по одному на локацию (вокзал.png, метро.png, отель.png подойдут, лучше реальные скриншоты из игры).
3. Файл: `SecondWind.zip` (внутри `SecondWind.exe`), отметить галочкой Windows.
4. Embed в Hack Club: ссылка на itch-страницу + репозиторий https://github.com/pauflifter67/Anomaly

## Порядок публикации

1. Godot → Editor → Manage Export Templates → Download and Install (~1 ГБ, один раз).
2. Project → Export → Windows Desktop → Export Project → `сборка/SecondWind.exe`.
3. Заархивировать: `Compress-Archive сборка\SecondWind.exe SecondWind.zip`.
4. itch.io → Create new project → вставить поля выше → загрузить zip → Visibility: Draft → проверить → Public.
