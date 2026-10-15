# Original game audio

All eight WAV files are original sounds synthesized locally by
`tools/generate_game_audio.py`. No recordings, downloaded sounds, music, sample
libraries, voices, or third-party audio were used. They are deliberately simple
placeholder-quality sounds, ready for later art direction.

The generated WAV assets are dedicated to the public domain under **CC0 1.0**
(SPDX: `CC0-1.0`): to the extent possible under law, the contributors waive all
copyright and related rights in these generated audio assets. See
[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/).

Regenerate with `python tools/generate_game_audio.py` (Python standard library).
Fixed seeds produce identical bytes. Format: mono 22,050 Hz, signed 16-bit PCM
WAV; approximately 0.93 MB total uncompressed. No runtime synthesis or dependency.

| File | Synthesis |
| --- | --- |
| footstep_walk.wav | Filtered seeded noise, decaying heel/sole/toe impacts |
| footstep_sprint.wav | Heavier low-frequency impact with a longer tail |
| door_open.wav | Low filtered movement noise, hinge oscillation, latch impact |
| item_pickup.wav | Three staggered decaying sine tones |
| school_bell.wav | Repeated inharmonic metallic strikes, soft endpoints |
| school_ambience.wav | Periodic HVAC/electrical hum and randomized tonal air |
| chase_tension.wav | Periodic low detuned drone and slow pulse |
| capture_hit.wav | Short enveloped noise/metallic hit with descending low tone |

The ambience/drone use frequencies on an eight-second period for seamless loops.
Bell repeats while School reports Bell active. Runtime loop copies are local to
the scene. Walking/sprinting uses its own presentation cadence, grounded measured
movement and existing Player movement state. **No audible cue emits NoiseEvent**
or changes AI noise tuning. Door/pickup hooks run only after School success.
Capture suspends Bell/tension; restoration resumes the requested Bell layer.
Victory stops all audio; Restart frees all players with the old game scene.
