# Agent instructions: After School

This is the canonical instruction file for AI work on *After School*. Read it before editing. The per-owner files linked below define each agent's allowed work. This documentation package may be copied into the game repository; if so, keep this file at the repository root and preserve the relative links.

## Rule 1: Read the shared source of truth

Before each task, read in order:

1. `docs/PROGRESS.md` for current status and handoffs.
2. `docs/CONTRACTS.md` for the frozen system interfaces.
3. The relevant sections of `docs/GAME_SPEC.md`.
4. Your owner brief: `docs/owners/EVAN_MONSTER.md`, `docs/owners/ZION_SCHOOL.md`, or `docs/owners/RHAIYN_PLAYER.md`.
5. `docs/WORKFLOW.md` and the current task in `docs/TODO.md` as needed.

Inspect the actual repository and existing conventions before creating files. This package does not assert that proposed folders, scenes, assets, or tools already exist.

## Rule 2: Work only in your owner's area

| Owner | System |
|---|---|
| Evan | Monster System — AI, perception, navigation behavior, capture request |
| Zion | School System — rooms, doors, keys, progression, Bell, lighting, safe rooms, world checkpoint data, exit |
| Rhaiyn | Player System — movement, stamina, camera, interaction, HUD/minimap/objectives, player-side checkpoint/death presentation |

Each owner may edit their own system and their own progress section. Do not edit another owner's scripts or scenes. The user handles asset production, including use of AI tools. Asset creation is outside the teammates' default implementation scope; agents should focus on their assigned code/system work and use available project assets or clearly identified placeholders. Only create or modify assets when the user explicitly includes that in the task. Use public interfaces in `docs/CONTRACTS.md` and request a contract change if necessary. Shared bootstrap/main scene, project settings, shared data types, and integration wiring must be assigned explicitly by the team before editing; the package does not silently assign them.

## Rule 3: Contracts stay frozen during feature work

Do not change `docs/CONTRACTS.md`, shared data definitions, signal names, or method signatures to make a feature compile. Propose a change in `docs/DECISIONS.md`, explain affected owners, and get team agreement before implementing it. Use typed Godot 4 GDScript and signals/public methods across system boundaries; do not reach into another system's node tree by relative path.

## Rule 4: Do not invent major mechanics

Follow confirmed rules in `GAME_SPEC.md`. Values labeled **OPEN** are not design approvals. Do not decide bell cadence, map topology, safe-room count, precise perception distances, attack timing, camera distance, stamina numbers, or checkpoint treatment for the keys by silently choosing a value. If a value blocks progress, use a clearly named temporary export setting, avoid baking it into shared contracts, and report the decision needed.

## Rule 5: Implement in small, reviewable slices

For each task: identify owner and acceptance checks → inspect current project → propose a brief plan → implement only that slice → run the requested checks (or report why they cannot run) → update the owner's progress and handoff notes. Do not add unrelated features. Do not claim a test passed unless its output was observed. Ask before destructive file operations, adding dependencies/assets, or changing shared project configuration.

## Rule 6: Leave a handoff trail

Update only your section in `docs/PROGRESS.md` with status, changed files, verification, next step, and what another owner needs to know. Update `docs/TODO.md` when work status changes. Record agreed design changes in `docs/DECISIONS.md`; never rewrite history to make an unresolved value look settled.

## Owner quick starts

- **Evan:** Read `docs/owners/EVAN_MONSTER.md`, then implement the assigned Monster System slice only.
- **Zion:** Read `docs/owners/ZION_SCHOOL.md`, then implement the assigned School System slice only.
- **Rhaiyn:** Read `docs/owners/RHAIYN_PLAYER.md`, then implement the assigned Player System slice only.

## Never

- Show monster location on the minimap.
- Let the monster open, close, or pass through a closed door.
- Let the monster teleport during Bell chase.
- Treat an inactive room or ordinary lit room as safe during Bell chase.
- Reset player/world state to the latest run state after death; restore the saved item checkpoint.
- Change another owner's files or a frozen contract without coordination.
- Expand an implementation task into asset production unless the user asks for it.
- Fill an **OPEN** design decision with an unreported permanent assumption.
