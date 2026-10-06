# School Map — AI Recreation Brief

This document translates the user's hand-drawn school map into a clean, implementation-friendly layout brief. When sending the copy-ready prompt to an image-capable AI, attach the original map image from the chat as its visual reference. The **relative placement and room arrangement in the drawing are authoritative**. Recreate the arrangement faithfully; do not optimize, mirror, rotate, add floors, or move rooms. Exact physical scale and some door marks are not recoverable from the sketch and are called out below.

## Copy-ready prompt

> Read this entire `MAP_RECREATION.md` file and use the attached hand-drawn map image as the visual reference. Recreate the school floor plan as a clean, readable, top-down 2D plan for a third-person horror game blockout. Preserve the original room positions, relative sizes, neighboring relationships, orientation, and overall footprint, using the coordinate table and adjacency notes in this document. The top of the page is the top of the map; do not rotate or mirror it. Use simple rectangular walls and clearly visible corridor space. Keep rooms labeled as listed here. Draw door openings only where described or visibly marked in the reference; where a door is unclear, mark it as unresolved instead of inventing a new route. Do not add rooms, wings, stairs, extra exits, furniture, props, or a second floor. This is a faithful reconstruction, not a redesign. Make walls and doors easy to inspect and output a clean orthographic top-down plan with labels and a coordinate grid. Use the normalized layout table as approximate proportions, not world-unit measurements. Preserve the gym at upper-left, library near upper-center, Cafe below the Library, Lab/Science block on the right, Outside on the left-middle, broad Lobby in the lower center, and Nurse Office/Main Office near the lower-right entrance in the positions described here.

## Orientation and coordinate frame

- View: orthographic, directly overhead.
- `x` increases to the right; `y` increases downward, matching the supplied photograph after mentally correcting the page perspective.
- Reference canvas: `1000 × 1000` normalized units. `(0,0)` is the upper-left of the map's overall footprint; `(1000,1000)` is its lower-right.
- Bounding boxes below are approximate `(left, top, width, height)` values transcribed from the photo. They preserve relative placement but are **not** surveyed measurements and need not fit together with CAD precision.
- The sketch has perspective distortion and hand-drawn wall wobble. Straighten walls for the clean plan while keeping room proportions and adjacency recognizable.

## Room placement table

| Room / area label | Approx. bounds `(x, y, w, h)` | Placement and interpretation |
|---|---:|---|
| Locker Room | `(0, 95, 140, 125)` | Upper-left edge, above/left of Gym; adjacent to the upper circulation band. |
| Auditorium | `(265, 20, 240, 95)` | Near top edge, left of Bathroom; opening faces the corridor below. |
| Bathroom | `(600, 25, 170, 95)` | Top row, between Auditorium and Cafeteria. |
| Cafeteria | `(770, 0, 175, 120)` | Upper-right corner, right of Bathroom; label reads “cafeteria.” |
| Gym | `(40, 205, 265, 235)` | Large upper-left room below Locker Room; extends farther left than central rooms. |
| Library | `(340, 125, 280, 120)` | Upper-middle, right of gym/corridor gap and left of the two upper-right classrooms. |
| Classroom A (upper right, left) | `(645, 125, 170, 120)` | East/right of Library, beneath the upper circulation band. |
| Classroom B (upper right, right) | `(810, 120, 175, 125)` | Immediately right of Classroom A at far-right edge. |
| Cafe | `(340, 260, 280, 175)` | Below Library and left of Lab/Science block; separate from Cafeteria. Label reads “cafe.” |
| Kitchen | `(495, 275, 120, 75)` | Small inset room/area inside Cafe at its upper-right; retain shared boundary and marked opening. |
| Lab Room | `(645, 255, 330, 125)` | Right-middle block, below upper-right classrooms and above Science Classroom. |
| Science Classroom | `(645, 380, 330, 125)` | Directly below Lab Room in the same right-side block. Treat as a separate labeled room connected through the partition opening shown. |
| Outside | `(140, 445, 165, 320)` | Exterior area in the left-middle/lower-left, below Gym and left of lower classroom pair; keep distinct from interior corridors. |
| Classroom C (lower pair, left) | `(335, 445, 145, 155)` | First of two side-by-side rooms immediately right of Outside. |
| Classroom D (lower pair, right) | `(480, 445, 145, 155)` | Immediately right of Classroom C; both are above Lobby and below Cafe. |
| Classroom E (lower-right) | `(665, 510, 320, 165)` | Right side, below Science Classroom and above/right of Nurse Office and Lobby. |
| Lobby | `(300, 580, 640, 190)` | Large lower-central open interior; broad horizontal extent. Connects lower classrooms, Entrance, Nurse Office, and Main Office zone. |
| Nurse Office | `(895, 650, 100, 105)` | Small room at lower-right/right edge of Lobby and above Main Office. This is the player start. |
| Main Office | `(675, 745, 325, 145)` | Lower-right/bottom edge, adjacent to Entrance/Lobby area. Keys are located here. |
| Entrance | point/edge near `(585, 765)` | Exterior opening along the bottom boundary of Lobby, left of Main Office. It is labeled “Entrance”; do not confuse it with Main Office. |

Coordinates for Entrance are a location/threshold, not a room rectangle. Room boxes are approximate and may overlap slightly where the source has shared/imprecise walls. Use the visible adjacency and corridors to resolve the clean blockout.

## Corridor and adjacency reading

1. A long upper corridor runs left-to-right beneath Auditorium, Bathroom, and Cafeteria. Locker Room and Gym occupy the far-left side below/along this band.
2. Library sits below the upper corridor around upper-center. The two upper-right classrooms continue to its right.
3. A crosswise circulation band separates Library/upper classrooms from Cafe and Lab Room below.
4. Cafe and Kitchen are center-left; Lab Room and Science Classroom form the stacked block on the right.
5. Outside occupies left-middle/lower-left and is not an interior corridor.
6. Two lower classrooms sit between Outside and Lobby, side-by-side above the Lobby.
7. Lobby is the broad lower-central space. Classroom E is at its upper-right side, Nurse Office at its right/lower-right edge, and Main Office along the bottom-right.
8. Entrance is a separate exterior threshold at the bottom of Lobby, left of Main Office.
9. Main Office is adjacent to the Entrance/Lobby side; Nurse Office is the start room and keys are in Main Office.

## Door/opening interpretation

The short gaps in walls indicate doors/openings. Use the image for exact local placement; these textual notes clarify only general adjacency. Do not invent doors to make every room directly connected. Apparent connections include:

- Locker Room to upper circulation.
- Gym to nearby circulation; a lower/right-side opening appears in the sketch.
- Auditorium to corridor below; Bathroom and Cafeteria to upper corridor.
- Library to surrounding corridor(s); both upper-right classrooms to circulation along/below them.
- Cafe to surrounding circulation; Kitchen to Cafe through its marked opening.
- Lab Room to Science Classroom through the horizontal partition opening near the right side.
- Lower Classroom C and D toward the Lobby-side corridor through lower-wall openings.
- Classroom E toward Lobby through a lower-edge opening.
- Nurse Office to Lobby and adjacent Main Office.
- Main Office to Entrance/Lobby side at upper/left boundary.
- Entrance through the bottom Lobby boundary to exterior.

Gameplay doors start closed. Keys in Main Office allow opening locked doors. The route from Nurse Office to Main Office must be accessible before obtaining keys; exact lock exceptions are a gameplay decision to resolve during blockout. Once opened, doors stay open. Door widths and hinge directions are unspecified; keep them simple and consistent.

## Room names

Use these labels: **Locker Room, Auditorium, Bathroom, Cafeteria, Gym, Library, Classroom, Classroom, Cafe, Kitchen, Lab Room, Science Classroom, Outside, Classroom, Classroom, Classroom, Lobby, Nurse Office, Main Office, Entrance.** There are five rooms labeled only “Classroom”: two upper-right, two side-by-side below Cafe, and one lower-right. Use implementation IDs `classroom_a` through `classroom_e` if unique IDs are needed, while retaining the visible label “Classroom” unless the team asks for more descriptive labels.

## Ambiguities to preserve for review

- Exact physical measurements and scale are not in the drawing. Do not convert normalized units to meters as if measured.
- Gym/Outside boundary and nearby door marks are rough; preserve visible adjacency and flag uncertain opening placement.
- Cafe/Kitchen partition and doorway are imprecise.
- Lab Room and Science Classroom are treated here as two adjacent rooms because both labels appear in the sketch.
- Several corridor widths and upper-room door openings are unclear. Keep circulation continuous and recognizable; flag uncertain door placement for team confirmation.
- The drawing does not specify windows, furniture, props, wall thickness, room heights, or a second floor. Do not add these as map facts.

## Godot graybox handoff

Use one ground floor, box-shaped room footprints, continuous walkable corridors, stable room IDs, and explicit door gaps at the positions shown. Choose world scale only after agreeing on a player-height/corridor-width reference. Preserve map orientation so top remains the sketch's top. Expose room IDs/bounds to minimap and Monster navigation systems. The minimap mirrors this layout and shows objective/item markers only; never show monster position.
