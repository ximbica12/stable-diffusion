extends Node3D

var skeleton: Skeleton3D
var simulator: PhysicalBoneSimulator3D
var anim_player: AnimationPlayer
var is_ragdoll: bool = false
var hips: PhysicalBone3D

@export var stabilize_ragdoll: bool = true
@export var penis_physics_enabled: bool = true
@export var penis_hit_radius: float = 0.10
@export var penis_mass: float = 0.22

var _dynamic_penis_bones: Array[PhysicalBone3D] = []

func _ready():
	skeleton = find_child("GeneralSkeleton", true, false) as Skeleton3D
	if not skeleton:
		skeleton = find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton:
		simulator = skeleton.find_child("PhysicalBoneSimulator3D", true, false) as PhysicalBoneSimulator3D
	anim_player = find_child("AnimationPlayer", true, false) as AnimationPlayer

	if not skeleton or not simulator:
		print("ERROR: Missing nodes on ", name)
		return

	# The exported scene has a penis bone chain but no PhysicalBone3D nodes for it.
	# Create those bodies at runtime so the game's existing grab/slap code can raycast
	# and manipulate the penis exactly like the other physical body parts.
	if penis_physics_enabled:
		_create_missing_penis_physical_bones()

	hips = _find_hips()
	is_ragdoll = true
	simulator.active = true
	simulator.physical_bones_start_simulation()
	_enforce_stability(true)

func _physics_process(_delta):
	if is_ragdoll and stabilize_ragdoll:
		# Original HOLD/SLAP logic restores gravity_scale to 1.0. Enforce zero gravity
		# after that so the model stays upright instead of collapsing every frame.
		_enforce_stability(false)

func _create_missing_penis_physical_bones():
	_dynamic_penis_bones.clear()

	for bone_idx in range(skeleton.get_bone_count()):
		var bone_name := skeleton.get_bone_name(bone_idx)
		if "penis" not in bone_name.to_lower():
			continue

		var already_bound := false
		for child in simulator.get_children():
			if child is PhysicalBone3D and child.get_bone_id() == bone_idx:
				already_bound = true
				break
		if already_bound:
			continue

		var physical_bone := PhysicalBone3D.new()
		physical_bone.name = "Physical Bone " + String(bone_name)
		physical_bone.set("bone_name", bone_name)
		physical_bone.joint_type = PhysicalBone3D.JOINT_TYPE_PIN
		physical_bone.mass = penis_mass
		physical_bone.gravity_scale = 0.0
		physical_bone.linear_damp = 3.5
		physical_bone.angular_damp = 3.5
		physical_bone.can_sleep = false
		# Raycasts use collision layer 1 in the original game. Mask 0 prevents these
		# small helper bodies from physically colliding with the rest of the ragdoll.
		physical_bone.collision_layer = 1
		physical_bone.collision_mask = 0

		# Pin joints match the game's existing interaction code and keep each segment
		# attached while still allowing free rotational bend/jiggle.
		physical_bone.set("joint_constraints/bias", 0.25)
		physical_bone.set("joint_constraints/damping", 0.8)
		physical_bone.set("joint_constraints/impulse_clamp", 0.0)

		var collision := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = penis_hit_radius
		collision.shape = sphere
		physical_bone.add_child(collision)
		simulator.add_child(physical_bone)

		# POST_ENTER_TREE binds bone_name to the Skeleton3D. Keep only valid bindings.
		if physical_bone.get_bone_id() >= 0:
			_dynamic_penis_bones.append(physical_bone)
		else:
			physical_bone.queue_free()

func _enforce_stability(reset_velocity: bool):
	if not simulator:
		return

	for child in simulator.get_children():
		if child is PhysicalBone3D:
			# Zero gravity preserves ragdoll interaction but removes the constant collapse.
			if child.gravity_scale != 0.0:
				child.gravity_scale = 0.0
			if reset_velocity:
				child.linear_velocity = Vector3.ZERO
				child.angular_velocity = Vector3.ZERO

	hips = _find_hips()
	if stabilize_ragdoll and hips:
		# Prevent vertical drop and forward/backward tipping while keeping horizontal
		# movement and yaw available for the existing interaction system.
		hips.axis_lock_linear_y = true
		hips.axis_lock_angular_x = true
		hips.axis_lock_angular_z = true
		hips.gravity_scale = 0.0
		if reset_velocity:
			hips.linear_velocity = Vector3.ZERO
			hips.angular_velocity = Vector3.ZERO

func play_animation(anim_name: String):
	if not anim_player or not skeleton or not simulator:
		return
	if anim_name == "":
		anim_player.stop()
		return

	if is_ragdoll:
		var hips_node = _find_hips()
		if hips_node:
			var hips_pos = hips_node.global_position
			# Preserve the model's current Y instead of forcing it to world Y=0.
			global_position = Vector3(hips_pos.x, global_position.y, hips_pos.z)
		is_ragdoll = false
		simulator.physical_bones_stop_simulation()
		simulator.active = false
		skeleton.animate_physical_bones = false
		skeleton.position = Vector3.ZERO
		skeleton.rotation = Vector3.ZERO
		await get_tree().process_frame
		await get_tree().process_frame

	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)

func stop_animation():
	if anim_player:
		anim_player.stop()

func enter_ragdoll():
	if not skeleton or not simulator:
		return
	if anim_player:
		anim_player.stop()
	is_ragdoll = true
	skeleton.animate_physical_bones = false
	simulator.active = true
	simulator.physical_bones_start_simulation()
	_enforce_stability(true)

func _find_hips() -> PhysicalBone3D:
	if not simulator:
		return null
	for child in simulator.get_children():
		if child is PhysicalBone3D:
			var n := child.name.to_lower()
			if "hips" in n or "pelvis" in n:
				return child
	return null

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_C:
			enter_ragdoll()
