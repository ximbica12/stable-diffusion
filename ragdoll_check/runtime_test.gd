extends SceneTree

func _init():
	var human_script = load("res://human.gd")
	if human_script == null:
		push_error("Failed to load human.gd")
		quit(10)
		return

	var human := Node3D.new()
	human.name = "Human"
	human.set_script(human_script)

	var skeleton := Skeleton3D.new()
	skeleton.name = "GeneralSkeleton"
	human.add_child(skeleton)

	var names = [
		"Hips",
		"Penis0_metarig.000",
		"Penis1_metarig.000",
		"Penis2_metarig.000",
		"Penis3_metarig.000",
		"Penis4_metarig.000",
		"Penis5_metarig.000",
	]
	for i in range(names.size()):
		skeleton.add_bone(names[i])
		if i > 0:
			skeleton.set_bone_parent(i, i - 1)
		var rest := Transform3D.IDENTITY
		rest.origin = Vector3(0.0, 0.0, float(i) * 0.08)
		skeleton.set_bone_rest(i, rest)

	var simulator := PhysicalBoneSimulator3D.new()
	simulator.name = "PhysicalBoneSimulator3D"
	skeleton.add_child(simulator)

	var hips := PhysicalBone3D.new()
	hips.name = "Physical Bone Hips"
	hips.set("bone_name", &"Hips")
	hips.joint_type = PhysicalBone3D.JOINT_TYPE_PIN
	var hips_collision := CollisionShape3D.new()
	var hips_shape := SphereShape3D.new()
	hips_shape.radius = 0.1
	hips_collision.shape = hips_shape
	hips.add_child(hips_collision)
	simulator.add_child(hips)

	get_root().add_child(human)
	await process_frame
	await process_frame

	var penis_count := 0
	var invalid_count := 0
	for child in simulator.get_children():
		if child is PhysicalBone3D and "penis" in child.name.to_lower():
			penis_count += 1
			if child.get_bone_id() < 0:
				invalid_count += 1
			if child.gravity_scale != 0.0:
				push_error("Penis physical bone gravity was not stabilized.")
				quit(12)
				return

	print("PENIS_BONES_CREATED=", penis_count)
	print("PENIS_BONES_INVALID=", invalid_count)
	print("HIPS_LOCK_Y=", hips.axis_lock_linear_y)
	if penis_count != 6 or invalid_count != 0 or not hips.axis_lock_linear_y:
		push_error("Runtime gameplay patch self-test failed.")
		quit(13)
		return
	print("RUNTIME_PATCH_TEST_OK")
	quit(0)
