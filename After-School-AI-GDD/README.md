# After School — AI Implementation Package

*After School* is a third-person school horror game built in Godot 4. This package is the shared implementation brief for Evan (Monster System), Zion (School System), and Rhaiyn (Player System). It turns the agreed design into system boundaries, interfaces, implementation order, and acceptance criteria without pretending that undecided map or tuning values are final.

## Start here

| Read | For |
|---|---|
| [AGENTS.md](AGENTS.md) | Canonical instructions and owner boundaries for every AI agent |
| [docs/GAME_SPEC.md](docs/GAME_SPEC.md) | Player-facing rules, world flow, known defaults, and open tuning values |
| [docs/MAP_RECREATION.md](docs/MAP_RECREATION.md) | AI-ready top-down reconstruction brief based on the supplied hand-drawn map |
| [docs/CONTRACTS.md](docs/CONTRACTS.md) | Cross-system signals, methods, data shapes, and ownership of each interface |
| [docs/TEAM.md](docs/TEAM.md) | Responsibilities, files, handoffs, and integration ownership |
| [docs/ASSETS.md](docs/ASSETS.md) | Asset ownership, request manifest, and handoff rules |
| [docs/WORKFLOW.md](docs/WORKFLOW.md) | Repeatable AI task workflow and copy-ready owner prompts |
| [docs/PROGRESS.md](docs/PROGRESS.md) | Current baseline and handoff notes |
| [docs/TODO.md](docs/TODO.md) | Implementation backlog and decisions still needed |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Confirmed decisions and explicit unresolved questions |
| [docs/SCENE_ARCHITECTURE.md](docs/SCENE_ARCHITECTURE.md) | Suggested Godot scene and autoload layout |
| [docs/owners/EVAN_MONSTER.md](docs/owners/EVAN_MONSTER.md) | Evan's implementation brief and acceptance checks |
| [docs/owners/ZION_SCHOOL.md](docs/owners/ZION_SCHOOL.md) | Zion's implementation brief and acceptance checks |
| [docs/owners/RHAIYN_PLAYER.md](docs/owners/RHAIYN_PLAYER.md) | Rhaiyn's implementation brief and acceptance checks |

## Project baseline

- Engine: Godot 4.x, GDScript. Pin the exact Godot minor version when the project repo is created.
- Perspective: third-person; horizontal camera rotation; school minimap and objective at top-left.
- Build intent: implement one owner system at a time against [CONTRACTS.md](docs/CONTRACTS.md); integrate through public signals and methods.
- Unknown repo-specific details: existing project layout, renderer/export targets, physical map scale/ambiguous door openings, asset paths, and team Git workflow. Inspect the actual project before creating or moving files.

This is a design and implementation package, not a claim that game code or assets already exist. Any value marked **OPEN** must be tuned or decided by the human/team; agents should use only clearly labeled temporary defaults and report them.
