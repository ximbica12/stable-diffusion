# Ragdoll Sims — V5 NSFW Interaction Rework

Target: Godot 4.5.1, Windows x86_64, compatibility build for Intel Pentium E5700 / SSE2.

## Why V4 felt broken

The previous patch hard-locked the human pelvis translation, so the character could not visibly react to contact. The penis chain also had two engine/gameplay problems: generic wake-up code could start the Root/Hips anchor bodies, and generic interaction-mode code could overwrite the penis solver profile. The original rubber/jiggle loop also produced the balloon-like sound.

## V5 rework

- Soft pelvis anchor: translation is dynamic and springs back instead of being hard-locked.
- Dedicated 6-segment penis physics profile with tapered mass, damping, angular limits and 6DOF angular springs.
- Root/Hips penis anchor bodies are never started by grab/wake logic.
- SOFT / NATURAL / FIRM penis profiles.
- Genital, butt, breast, pelvis, thigh and torso reaction zones.
- Genital-contact priority despite the source asset's overlapping pelvis/thigh capsules.
- Two tip segments receive selective collision exceptions around the coarse pelvis geometry so the final approach is not blocked by the original ragdoll capsules.
- Gentle auto-alignment near the genital target.
- Procedural reaction meter and coordinated pelvis/spine/chest impulses.
- Manual grabbing/slapping also feeds the body-reaction system.
- rubber.wav / jiggle.wav balloon loop disabled.
- A small procedural low-frequency contact sound replaces the rubber squeak.
- Thread-safe interaction flow: no force_raycast_update() / direct-space query from unsafe timing.
- Controls added: R reactions, T penis physics profile, X reset penis.

## Validation

Godot 4.5.1 parser: PASS.

Full threaded-physics runtime test:
- PCK loads: PASS
- 6 penis PhysicalBone3D bodies active: PASS
- Root/Hips penis anchors remain static: PASS
- waking/grabbing cannot start Root/Hips: PASS
- penis solver survives interaction-mode changes: PASS
- human pelvis uses soft translational anchor: PASS
- balloon/rubber audio disabled: PASS
- reaction HUD created: PASS
- genital zone detected: PASS
- genital contact activates reaction system: PASS
- reaction meter increases from penis contact: PASS
- pelvis remains bounded by soft anchor: PASS
- sustained solver positions remain finite: PASS
- no Space state is inaccessible / dss is null errors observed in the V5 test.

The packaged game is built separately from this repository branch because the source game assets/PCK are conversation-provided files rather than repository assets.
