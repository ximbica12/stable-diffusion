# Ragdoll Sims V7 — targeted interaction rework

V7 replaces the V6 random dance/pose AI and primitive procedural toy with a deterministic, target-driven interaction system for Godot 4.5.1.

## Research bases

- **Alexofp/BDCC** — open-source adult Godot project, MIT licensed. V7 uses `Player/Props/CanineDildo.glb` as the detailed prop model and carries the upstream MIT notice in the packaged artifact.
- **Alexofp/BDCC2** — used as an architecture reference only: explicit SexEngine activities, participant AI/state logic, pose abstractions and AnimationTree/BlendTree structure. BDCC2 code is MIT, while its assets are CC BY-NC-SA 4.0, so no BDCC2 assets are bundled.
- **Godot 4.5.1 SkeletonIK3D/FABRIK** — reviewed as a targeting reference. The V7 patch uses bounded procedural bone control on the existing 149-bone rig instead of forcing an un-authored full-body IK solution.
- **Godot RigidBody3D + Quaternion** — V7 keeps released props under physics and freezes them only while held. Held orientation is stored as an unclamped quaternion relative to the camera, enabling full yaw/pitch/roll rotation.

## Behavioral changes

- No random dancing or automatic pose cycling.
- Default state remains IDLE until a held prop is actually near and aligned to a target.
- Three directional slots: ORAL, VAGINAL, ANAL.
- Slot solver checks shaft alignment, lateral offset, approach distance and signed insertion depth.
- Oral reaction uses head/neck tracking plus jaw, lower lip and tongue bones.
- Vaginal/anal reactions use hips, spine, upper legs, butt and crotch bones progressively.
- The original first-person penis rig remains disabled.
- Full-body PhysicalBone3D ragdoll remains disabled during normal gameplay to avoid mesh stretching.
- Old rubber/jiggle audio loop remains disabled.
- UI reduced to a small status line, crosshair and optional help strip.

## Validation

Godot 4.5.1 full-scene stress test:
- 149-bone skeleton preserved.
- 180 idle frames remained IDLE.
- 720 free-rotation updates kept an orthonormal finite transform (determinant ~1).
- Imported detailed prop model present as MeshInstance3D.
- ORAL auto-target: pass.
- VAGINAL auto-target: pass.
- ANAL auto-target: pass.
- Key skeleton transforms remained finite.
- Packed PCK repeated the same test: `V7_STRESS_OK`.
