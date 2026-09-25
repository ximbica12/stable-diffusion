# Ragdoll Sims V6 — AI + Prop Rework

This branch tracks the V6 redesign built against Godot 4.5.1.

## Why V5 was removed

The screenshots from V5 showed two failure modes:
- the always-on full-body PhysicalBone3D ragdoll could stretch the skinned mesh into long spikes / spaghetti;
- the first-person penis rig was an unstable articulated chain and did not provide a useful object interaction loop.

V6 removes both assumptions instead of trying to tune them again.

## V6 architecture

- Original first-person penis meshes and PhysicalBone3D colliders are disabled.
- Three procedural dildo/prop sizes are created as independent RigidBody3D objects (SLIM, STANDARD, LARGE).
- Props can be picked up, held, moved, rotated, released and respawned.
- The doll's original 149-bone deform skeleton is retained. V6 does **not** add unweighted deform bones, because that would not improve the skin and can make deformation worse.
- A 12-anchor control/reaction rig is attached to the existing skeleton (genital, buttocks, breasts, chest, mouth/jaw, thighs, hips and hands).
- Full-body ragdoll is no longer enabled on startup. The doll uses controlled animation/pose playback.
- Local behavior AI states: CALM, NOTICE, REACTING, RECOVER, MANUAL.
- Stable pose set uses authored animation frames/loops: Neutral, Relax, Look, Hip, Lean, Bend, Low, Rumba and Twerk.
- Contact with props or direct body-zone touches feeds the reaction state and AI.
- Old rubber/jiggle balloon audio loops are disabled.
- Old ClothingUI / AnimationUI popups are retired and replaced with one unified V6 menu.
- Unified menu includes AI toggle, pose controls, prop spawn/reset/release and outfit toggles.
- Thread-safe interaction path: no force_raycast_update / direct-space query abuse.

## Controls

- LMB: grab prop / touch reaction zone
- RMB: stronger direct touch reaction
- E: release held prop
- T: cycle and spawn next prop
- Q: next pose
- R: AI on/off
- X: reset prop rack
- C: recover/reset doll
- M or Esc: unified menu
- Mouse wheel: hold distance
- Shift + wheel: prop twist
- WASD: move

## Validation performed

Godot 4.5.1 parse test: PASS.

Full scene / threaded physics test:
- human script = res://human.gd
- human skeleton = 149 bones
- full ragdoll inactive on startup
- old penis visible meshes = 0
- old penis live collision bodies = 0
- old penis simulator inactive
- initial props = 3
- reaction anchors = 12
- ray interaction mask = body zones + props
- V6 HUD/menu created
- BEND pose applies successfully
- genital prop contact registers
- reaction meter increases
- doll AI enters REACTING
- prop spawn-and-hold path works

Stress test:
- all 9 poses cycled
- key skeleton transforms remained finite
- repeated genital contact increased reaction to ~0.67
- no Space state / dss errors observed
- result: V6_STRESS_OK

The complete packaged game PCK and Windows E5700-compatible runtime are distributed as the generated ChatGPT artifact, not committed to this unrelated repository.
