# School Bell

`scripts/school/school_bell.gd` owns the Bell state and scheduling. Its reusable scene is `scenes/school_bell.tscn`, instanced by `scenes/school_foundation.tscn`. The existing imported-model main scene is unchanged. No Player or Monster references, UI, audio, lighting, or movement are controlled.

## Inspector settings

- `minimum_interval`, `maximum_interval`: provisional defaults 30–60 seconds, measured from Bell end to next start. The first Bell also waits a random interval.
- `bell_duration`: 10 seconds by default; sampled at Bell start, remains fixed for that cycle.
- `objectives_for_maximum_pressure`: provisional default 6 completed objectives.
- `completed_interval_multiplier`: provisional default 0.5. Both interval bounds shrink linearly with progress, reaching 15–30 seconds at six objectives with defaults. Progress is clamped for pressure calculations, so extra objectives cannot shrink intervals indefinitely.
- `auto_start`: true. Disable to bind consumers and initial progress before calling `start_scheduling()`.
- `debug_transitions`: false. Enable for one output line per transition. No next-Bell countdown is printed or sent in snapshots.

These are tuning defaults, not final game-design decisions. Minimum/maximum values are sorted if reversed; durations and interval lower bounds are at least 0.05 seconds. The upper interval bound stays at least 0.05 seconds above the lower bound, even if configured equal, retaining random timing. Nonfinite timing values use defaults. The random generator is randomized on ready, with no fixed production seed.

## Public interfaces

| Name | Behavior |
| --- | --- |
| `bell_active: bool` | Read-only authoritative active/inactive state. |
| `bell_state_changed(snapshot: SchoolBell.BellSnapshot)` | Exactly one publication on each actual start/end; no initial false publication or per-frame events. |
| `get_bell_snapshot() -> SchoolBell.BellSnapshot` | Fresh snapshot for initial/late subscriber synchronization. |
| `set_objective_progress(completed_objectives: int) -> void` | Called by integration when objective progress changes. Negative counts become zero; changing progress does not reroll the pending wait or alter active duration. Applies on the next scheduled interval. |
| `get_interval_bounds() -> Vector2` | Effective minimum and maximum, for tuning/testing; does not expose the chosen deadline. |
| `start_scheduling() -> void` | Starts a new random wait; repeated calls while running do nothing. |
| `stop_scheduling() -> void` | Cancels scheduling; if active, publishes false once. Repeated stops do nothing. |

The nested typed `BellSnapshot` implements the existing documented fields: `active`, `final_escape`, `remaining_seconds`, `progression_index`, and `active_safe_room_ids`. Inactive snapshots have zero remaining seconds; active snapshots contain remaining Bell duration. Final escape stays false and safe-room IDs stay empty in this Bell-only slice. Duration progression, final escape, safe-room selection, audio, and lighting remain separate work. No existing contract signature is changed.

```gdscript
# Integration owns these references. Connect before starting when auto_start=false.
bell.bell_state_changed.connect(monster.set_bell_state)
monster.set_bell_state(bell.get_bell_snapshot()) # Initial synchronization.
bell.set_objective_progress(completed_objectives)
bell.start_scheduling()
```

The integration owner must forward objective updates; this component does not inspect another owner's private scene tree or inventory. It inherits normal SceneTree pause behavior and game time scale. Long frames perform at most one transition, preserving a full active duration instead of bursting missed start/end events in one frame. State and next-phase timing are committed before signal emission. On teardown consumers should be removed/rebound with the scene; call `stop_scheduling()` before removing the Bell alone if consumers remain alive.

## Verification

Run `Godot --headless --path . --script res://tests/school_bell_test.gd` using your Godot executable. Tests cover exact-once start/end, duration, randomized bounded intervals, progress scaling, pending-wait preservation, snapshot isolation, invalid timing, stop/restart, long frames, SceneTree pause, and actual engine-driven cycles. Godot 4.7.2 run passed: 114 transitions, zero failures (the real-time portion's count may vary slightly by machine). Host log/certificate-store errors appeared but did not fail these offline checks.

Manual steps:

1. Open `scenes/school_bell.tscn`, temporarily set intervals to 2 and 4 seconds, duration to 1 second, and enable `debug_transitions`.
2. Run the current scene with F6. This logic-only scene has no camera/display. Watch Output: a varying wait, one `bell_active=true`, about one second later one `bell_active=false`, then another varying wait. There should be no repeated state messages during either phase.
3. In a temporary integration script, call `set_objective_progress(6)`. With the default multiplier, subsequent waits use 1–2 seconds; the currently scheduled wait finishes unchanged. Bell duration remains one second.
4. Call `stop_scheduling()` twice during an active Bell. Expect one false event and no further cycles. Call `start_scheduling()` twice; expect one pending schedule.
5. Pause the SceneTree during a wait or active Bell and resume; phase time should freeze during pause. Restore Inspector settings after testing.

Created: `scripts/school/school_bell.gd`, `scenes/school_bell.tscn`, `tests/school_bell_test.gd`, `SCHOOL_BELL.md`. Updated: School foundation scene and handoff, plus School progress/backlog notes. Godot script `.uid` sidecars are versioned when generated.
