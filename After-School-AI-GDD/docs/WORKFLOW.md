# AI Feature Workflow

Use this workflow for every implementation slice. The reference project used branch/spec/plan/build/review; follow the spirit without assuming its Git rules or test framework apply to this repository.

## 1. Establish context

Read `AGENTS.md`, `PROGRESS.md`, `CONTRACTS.md`, the relevant `GAME_SPEC.md` sections, and your owner brief. Inspect the real repository, current branch/status, scene tree, naming style, engine version, and available tests. Do not run cleanup or overwrite existing work.

## 2. Define the slice

State the owner, exact files/systems in scope, contract methods/signals involved, known tuning values, unresolved dependencies, and acceptance checks. If the slice requires an **OPEN** design choice, isolate the choice and keep it configurable. Do not expand scope to “finish the whole game” unless asked.

## 3. Plan and implement

Make a short ordered plan. Implement one cohesive slice within the owner's boundaries. Prefer typed code and exported tuning settings; avoid hidden magic numbers. Reuse existing project patterns and approved assets. The user creates assets; list needed files in `docs/ASSETS.md` instead of generating or editing them. Do not add a plugin, package, or asset pack without approval.

## 4. Verify and hand off

Run the checks the human requested and those already established by the repo. If none exist, do not invent/run a test suite unless asked; inspect the implementation and report the unverified behavior. Include changed files, checks/results, known limitations, a concrete manual play step, and needed handoffs. Update only your progress section and relevant TODO status.

## Copy-ready owner prompts

### Evan — Monster System

> Read `AGENTS.md`, `docs/PROGRESS.md`, `docs/CONTRACTS.md`, `docs/GAME_SPEC.md` sections 6–9, and `docs/owners/EVAN_MONSTER.md`. Inspect the existing Godot project and implement only my assigned Monster System task: **[paste one task from TODO.md]**. Preserve all contracts and owner boundaries. Do not invent unresolved values; expose provisional tuning and report it. Verify only with existing/requested checks, update my section of `docs/PROGRESS.md`, and report files, results, and handoffs.

### Zion — School System

> Read `AGENTS.md`, `docs/PROGRESS.md`, `docs/CONTRACTS.md`, `docs/GAME_SPEC.md` sections 4–5, 8–9, and `docs/owners/ZION_SCHOOL.md`. Inspect the existing Godot project and implement only my assigned School System task: **[paste one task from TODO.md]**. Preserve all contracts and owner boundaries. Do not invent the floorplan or unresolved Bell/safe-room/checkpoint rules; expose provisional tuning and report decisions needed. Verify only with existing/requested checks, update my section of `docs/PROGRESS.md`, and report files, results, and handoffs.

### Rhaiyn — Player System

> Read `AGENTS.md`, `docs/PROGRESS.md`, `docs/CONTRACTS.md`, `docs/GAME_SPEC.md` sections 3–4, 6, 9, and `docs/owners/RHAIYN_PLAYER.md`. Inspect the existing Godot project and implement only my assigned Player System task: **[paste one task from TODO.md]**. Preserve all contracts and owner boundaries. Do not invent unresolved movement/stamina/camera values; expose provisional tuning and report it. Never show the monster on the minimap. Verify only with existing/requested checks, update my section of `docs/PROGRESS.md`, and report files, results, and handoffs.

## Human review checkpoint

Before a slice changes shared contracts, project settings, main scene integration, floorplan assumptions, or an **OPEN** design rule, present the concrete proposed change and affected owners for team agreement. Continue independent work that does not depend on the decision.
