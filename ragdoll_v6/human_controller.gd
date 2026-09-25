extends Node3D

# V6 replaces the always-on full-body ragdoll with a controlled animation/pose
# controller. The original model already has 149 deform bones; continuously
# simulating 53 PhysicalBone3D bodies was the source of the stretched/spaghetti
# mesh seen in V5. Physics is now opt-in, while the AI uses authored animation.

var skeleton: Skeleton3D
var simulator: PhysicalBoneSimulator3D
var anim_player: AnimationPlayer
var is_ragdoll: bool = false
var ai_enabled: bool = true
var ai_state: String = "CALM"
var current_pose: String = "NEUTRAL"
var _idle_timer: float = 2.5
var _reaction_timer: float = 0.0
var _rng := RandomNumberGenerator.new()

func _ready():
    _rng.randomize()
    skeleton = find_child("GeneralSkeleton", true, false) as Skeleton3D
    if not skeleton:
        skeleton = find_child("Skeleton3D", true, false) as Skeleton3D
    if skeleton:
        simulator = skeleton.find_child("PhysicalBoneSimulator3D", true, false) as PhysicalBoneSimulator3D
    anim_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
    if not skeleton or not simulator:
        print("V6 HUMAN: missing skeleton/simulator on ", name)
        return
    _enter_controlled_mode()
    play_pose("NEUTRAL")

func _process(delta: float):
    if not ai_enabled or is_ragdoll or not anim_player:
        return
    if _reaction_timer > 0.0:
        _reaction_timer = maxf(0.0, _reaction_timer - delta)
        if _reaction_timer <= 0.0:
            ai_state = "RECOVER"
            _idle_timer = 1.2
        return
    _idle_timer -= delta
    if _idle_timer <= 0.0:
        ai_state = "CALM"
        var roll := _rng.randi_range(0, 4)
        match roll:
            0: play_pose("NEUTRAL")
            1: play_pose("RELAX")
            2: play_pose("LOOK")
            3: play_pose("HIP")
            _: play_pose("RUMBA")
        _idle_timer = _rng.randf_range(3.0, 6.5)

func _enter_controlled_mode():
    if not skeleton or not simulator:
        return
    if is_ragdoll:
        simulator.physical_bones_stop_simulation()
    simulator.active = false
    skeleton.animate_physical_bones = false
    is_ragdoll = false
    for child in simulator.get_children():
        if child is PhysicalBone3D:
            child.linear_velocity = Vector3.ZERO
            child.angular_velocity = Vector3.ZERO

func set_ai_enabled(enabled: bool):
    ai_enabled = enabled
    ai_state = "CALM" if enabled else "MANUAL"
    if not enabled and anim_player:
        anim_player.pause()

func play_animation(anim_name: String):
    if not anim_player or not skeleton or not simulator:
        return
    _enter_controlled_mode()
    if anim_name == "":
        stop_animation()
        return
    if anim_player.has_animation(anim_name):
        current_pose = anim_name
        anim_player.speed_scale = 1.0
        anim_player.play(anim_name)

func stop_animation():
    if anim_player:
        anim_player.stop()
    if skeleton:
        skeleton.reset_bone_poses()
    current_pose = "NEUTRAL"

func _hold_animation_pose(anim_name: String, time_sec: float, pose_name: String):
    if not anim_player or not anim_player.has_animation(anim_name):
        return
    _enter_controlled_mode()
    anim_player.speed_scale = 1.0
    anim_player.play(anim_name)
    anim_player.seek(time_sec, true)
    anim_player.pause()
    current_pose = pose_name

func play_pose(pose_name: String):
    if not anim_player or not skeleton:
        return
    var p := pose_name.to_upper()
    match p:
        "NEUTRAL":
            anim_player.stop()
            skeleton.reset_bone_poses()
            current_pose = "NEUTRAL"
        "RELAX":
            _hold_animation_pose("Rumba/mixamo_com", 0.35, "RELAX")
        "LOOK":
            _hold_animation_pose("Rumba/mixamo_com", 1.25, "LOOK")
        "HIP":
            _hold_animation_pose("twerk/mixamo_com", 2.75, "HIP")
        "LEAN":
            _hold_animation_pose("twerk/mixamo_com", 5.60, "LEAN")
        "BEND":
            _hold_animation_pose("twerk/mixamo_com", 9.40, "BEND")
        "LOW":
            _hold_animation_pose("twerk/mixamo_com", 12.10, "LOW")
        "RUMBA":
            _enter_controlled_mode()
            current_pose = "RUMBA"
            anim_player.speed_scale = 0.55
            anim_player.play("Rumba/mixamo_com")
        "TWERK":
            _enter_controlled_mode()
            current_pose = "TWERK"
            anim_player.speed_scale = 0.55
            anim_player.play("twerk/mixamo_com")
        _:
            play_pose("NEUTRAL")

func react_to(zone: String, intensity: float, reaction_total: float):
    if not ai_enabled or not anim_player:
        return
    _enter_controlled_mode()
    var z := zone.to_upper()
    var strength := clampf(maxf(intensity, reaction_total), 0.0, 1.0)
    if z == "GENITAL" or z == "BUTT":
        ai_state = "REACTING"
        current_pose = "REACTIVE LOWER"
        anim_player.speed_scale = lerpf(0.35, 1.25, strength)
        if anim_player.current_animation != "twerk/mixamo_com" or not anim_player.is_playing():
            anim_player.play("twerk/mixamo_com")
        _reaction_timer = lerpf(0.65, 1.8, strength)
    elif z == "BREAST" or z == "CHEST" or z == "MOUTH":
        ai_state = "REACTING"
        current_pose = "REACTIVE UPPER"
        anim_player.speed_scale = lerpf(0.35, 0.95, strength)
        if anim_player.current_animation != "Rumba/mixamo_com" or not anim_player.is_playing():
            anim_player.play("Rumba/mixamo_com")
        _reaction_timer = lerpf(0.45, 1.25, strength)
    else:
        ai_state = "NOTICE"
        _reaction_timer = 0.45

func enter_ragdoll():
    # Kept for compatibility, but no longer the default gameplay state.
    if not skeleton or not simulator:
        return
    if anim_player:
        anim_player.stop()
    skeleton.animate_physical_bones = false
    simulator.active = true
    simulator.physical_bones_start_simulation()
    is_ragdoll = true
    ai_state = "RAGDOLL"

func recover_from_ragdoll():
    _enter_controlled_mode()
    play_pose("NEUTRAL")
    ai_state = "CALM" if ai_enabled else "MANUAL"

func get_ai_state() -> String:
    return ai_state

func get_pose_name() -> String:
    return current_pose
