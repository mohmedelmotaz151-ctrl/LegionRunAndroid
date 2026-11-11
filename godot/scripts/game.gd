extends Node3D

const ROAD_WIDTH := 12.0
const MAX_SOLDIERS := 36
const RUN_SPEED := 10.0
const FINISH_DISTANCE := 260.0

var squad_count: int = 8
var distance: float = 0.0
var lane: int = 0
var game_over := false
var won := false
var swipe_start := Vector2.ZERO
var spawn_gate_at := 16.0
var spawn_hazard_at := 27.0
var finish_spawned := false
var soldiers: Array[Node3D] = []
var moving_objects: Array[Node3D] = []
var hud_count: Label
var hud_level: Label
var hud_distance: ProgressBar
var message_label: Label
var restart_button: Button
var squad_root: Node3D
var camera: Camera3D
var road_material: StandardMaterial3D

func _ready() -> void:
	_build_world()
	_build_ui()
	_build_squad()
	_spawn_gate(-18.0, 2, 3, 1)
	_spawn_hazard(-35.0, 0)
	_update_hud()

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.72, 0.88)
	env.ambient_light_energy = 0.65
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

	road_material = _material(Color(0.12, 0.16, 0.21), 0.1)
	var road := MeshInstance3D.new()
	var road_mesh := BoxMesh.new()
	road_mesh.size = Vector3(ROAD_WIDTH, 0.25, 1200.0)
	road.mesh = road_mesh
	road.material_override = road_material
	road.position = Vector3(0, -0.18, -560.0)
	add_child(road)

	for side in [-1, 1]:
		var edge := MeshInstance3D.new()
		var edge_mesh := BoxMesh.new()
		edge_mesh.size = Vector3(0.22, 0.08, 1200.0)
		edge.mesh = edge_mesh
		edge.material_override = _material(Color(0.95, 0.72, 0.18), 0.2)
		edge.position = Vector3(side * 5.65, -0.02, -560.0)
		add_child(edge)
		for i in range(30):
			var marker := MeshInstance3D.new()
			var marker_mesh := BoxMesh.new()
			marker_mesh.size = Vector3(0.12, 0.025, 2.0)
			marker.mesh = marker_mesh
			marker.material_override = _material(Color(0.7, 0.76, 0.82), 0.15)
			marker.position = Vector3(0, -0.035, -i * 22.0 - 8.0)
			add_child(marker)

	camera = Camera3D.new()
	camera.position = Vector3(0, 7.8, 12.5)
	camera.rotation_degrees = Vector3(24.0, 0.0, 0.0)
	camera.current = true
	camera.fov = 62.0
	add_child(camera)

	squad_root = Node3D.new()
	squad_root.position = Vector3(0, 0, 1.0)
	add_child(squad_root)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.size = Vector2(684, 132)
	layer.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.055, 0.11, 0.88)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	panel.add_theme_stylebox_override("panel", style)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	var row := HBoxContainer.new()
	column.add_child(row)
	hud_level = Label.new()
	hud_level.text = "LEVEL 01"
	hud_level.add_theme_font_size_override("font_size", 26)
	hud_level.add_theme_color_override("font_color", Color(1.0, 0.78, 0.22))
	row.add_child(hud_level)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	hud_count = Label.new()
	hud_count.add_theme_font_size_override("font_size", 26)
	hud_count.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(hud_count)
	hud_distance = ProgressBar.new()
	hud_distance.max_value = FINISH_DISTANCE
	hud_distance.value = 0
	hud_distance.custom_minimum_size = Vector2(0, 18)
	column.add_child(hud_distance)

	message_label = Label.new()
	message_label.position = Vector2(40, 430)
	message_label.size = Vector2(640, 160)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 34)
	message_label.add_theme_color_override("font_color", Color.WHITE)
	message_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	message_label.add_theme_constant_override("shadow_offset_x", 2)
	message_label.add_theme_constant_override("shadow_offset_y", 3)
	layer.add_child(message_label)
	message_label.text = ""

	restart_button = Button.new()
	restart_button.text = "PLAY AGAIN"
	restart_button.position = Vector2(220, 640)
	restart_button.size = Vector2(280, 72)
	restart_button.add_theme_font_size_override("font_size", 25)
	restart_button.visible = false
	restart_button.pressed.connect(_restart)
	layer.add_child(restart_button)

func _build_squad() -> void:
	for child in squad_root.get_children():
		child.queue_free()
	soldiers.clear()
	for i in range(mini(squad_count, MAX_SOLDIERS)):
		var soldier := _make_soldier(Color(0.12, 0.42, 0.92), Color(0.08, 0.15, 0.28))
		squad_root.add_child(soldier)
		soldiers.append(soldier)
	_position_squad()

func _make_soldier(uniform_color: Color, helmet_color: Color) -> Node3D:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.23
	body_mesh.height = 1.05
	body.mesh = body_mesh
	body.material_override = _material(uniform_color, 0.25)
	body.position.y = 0.72
	root.add_child(body)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.19
	head_mesh.height = 0.38
	head.mesh = head_mesh
	head.material_override = _material(Color(0.78, 0.57, 0.42), 0.25)
	head.position.y = 1.42
	root.add_child(head)

	var helmet := MeshInstance3D.new()
	var helmet_mesh := SphereMesh.new()
	helmet_mesh.radius = 0.22
	helmet_mesh.height = 0.22
	helmet.mesh = helmet_mesh
	helmet.material_override = _material(helmet_color, 0.32)
	helmet.position.y = 1.56
	root.add_child(helmet)

	for side in [-1, 1]:
		var arm := MeshInstance3D.new()
		var arm_mesh := CapsuleMesh.new()
		arm_mesh.radius = 0.075
		arm_mesh.height = 0.62
		arm.mesh = arm_mesh
		arm.material_override = _material(uniform_color.darkened(0.12), 0.2)
		arm.position = Vector3(side * 0.27, 0.77, -0.01)
		arm.rotation.z = deg_to_rad(side * -13.0)
		root.add_child(arm)

	for side in [-1, 1]:
		var leg := MeshInstance3D.new()
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.09
		leg_mesh.height = 0.58
		leg.mesh = leg_mesh
		leg.material_override = _material(Color(0.08, 0.12, 0.18), 0.18)
		leg.position = Vector3(side * 0.12, 0.27, 0.0)
		root.add_child(leg)
	return root

func _position_squad() -> void:
	for i in range(soldiers.size()):
		var row_index := i / 4
		var col_index := i % 4
		var x := (float(col_index) - 1.5) * 0.72
		var z := float(row_index) * 0.82
		soldiers[i].position = Vector3(x, 0, z)
		soldiers[i].rotation.y = 0.0

func _spawn_gate(z_pos: float, left_value: int, right_value: int, mode: int) -> void:
	var gate_pair := Node3D.new()
	gate_pair.position.z = z_pos
	add_child(gate_pair)
	moving_objects.append(gate_pair)
	_make_gate(gate_pair, -2.55, left_value, mode)
	_make_gate(gate_pair, 2.55, right_value, mode)

func _make_gate(parent: Node3D, x_pos: float, value: int, mode: int) -> void:
	var color := Color(0.08, 0.72, 0.42) if mode == 1 else Color(0.1, 0.48, 0.95)
	var arch := Node3D.new()
	arch.position.x = x_pos
	parent.add_child(arch)
	for side in [-1, 1]:
		var post := MeshInstance3D.new()
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.16, 3.0, 0.22)
		post.mesh = post_mesh
		post.material_override = _material(color, 0.25)
		post.position = Vector3(side * 1.15, 1.5, 0)
		arch.add_child(post)
	var top := MeshInstance3D.new()
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(2.45, 0.28, 0.28)
	top.mesh = top_mesh
	top.material_override = _material(color, 0.25)
	top.position.y = 2.92
	arch.add_child(top)
	var label := Label3D.new()
	label.text = ("+" if mode == 1 else "×") + str(value)
	label.font_size = 72
	label.pixel_size = 0.006
	label.position = Vector3(0, 2.35, -0.18)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color.WHITE
	arch.add_child(label)
	arch.set_meta("lane", -1 if x_pos < 0 else 1)
	arch.set_meta("value", value)
	arch.set_meta("mode", mode)

func _spawn_hazard(z_pos: float, x_lane: int) -> void:
	var hazard := Node3D.new()
	hazard.position = Vector3(float(x_lane) * 2.0, 0, z_pos)
	add_child(hazard)
	moving_objects.append(hazard)
	var block := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.5, 1.7, 1.0)
	block.mesh = mesh
	block.material_override = _material(Color(0.78, 0.12, 0.16), 0.25)
	block.position.y = 0.85
	hazard.add_child(block)
	var stripe := MeshInstance3D.new()
	var stripe_mesh := BoxMesh.new()
	stripe_mesh.size = Vector3(1.56, 0.16, 1.05)
	stripe.mesh = stripe_mesh
	stripe.material_override = _material(Color(1.0, 0.78, 0.12), 0.3)
	stripe.position.y = 1.0
	hazard.add_child(stripe)

func _spawn_finish() -> void:
	finish_spawned = true
	var finish := Node3D.new()
	finish.position.z = -FINISH_DISTANCE
	finish.set_meta("finish", true)
	add_child(finish)
	moving_objects.append(finish)
	var banner := MeshInstance3D.new()
	var banner_mesh := BoxMesh.new()
	banner_mesh.size = Vector3(ROAD_WIDTH, 0.35, 0.35)
	banner.mesh = banner_mesh
	banner.material_override = _material(Color(0.95, 0.7, 0.12), 0.2)
	banner.position.y = 3.3
	finish.add_child(banner)
	var label := Label3D.new()
	label.text = "FINAL BATTLE"
	label.font_size = 92
	label.position.y = 4.0
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	finish.add_child(label)
	for i in range(12):
		var enemy := _make_soldier(Color(0.72, 0.12, 0.16), Color(0.25, 0.04, 0.06))
		enemy.position = Vector3((float(i % 6) - 2.5) * 0.8, 0, -2.0 - float(i / 6) * 1.2)
		finish.add_child(enemy)

func _input(event: InputEvent) -> void:
	if game_over:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start = event.position
		else:
			var delta := event.position.x - swipe_start.x
			if absf(delta) > 24.0:
				_change_lane(-1 if delta < 0.0 else 1)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			swipe_start = event.position
		else:
			var delta := event.position.x - swipe_start.x
			if absf(delta) > 24.0:
				_change_lane(-1 if delta < 0.0 else 1)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_LEFT or event.keycode == KEY_A:
			_change_lane(-1)
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			_change_lane(1)

func _change_lane(direction: int) -> void:
	lane = clampi(lane + direction, -1, 1)

func _process(delta: float) -> void:
	if game_over:
		return
	distance += RUN_SPEED * delta
	squad_root.position.x = lerpf(squad_root.position.x, float(lane) * 2.0, minf(delta * 9.0, 1.0))
	for i in range(soldiers.size()):
		soldiers[i].position.y = absf(sin(Time.get_ticks_msec() * 0.009 + float(i))) * 0.055
	for obj in moving_objects.duplicate():
		obj.position.z += RUN_SPEED * delta
		if obj.position.z >= -0.5 and obj.position.z <= RUN_SPEED * delta + 0.2:
			if obj.get_child_count() > 0 and obj.get_child(0).has_meta("lane"):
				_apply_gate(obj)
				continue
			elif not obj.has_meta("finish") and absf(obj.position.x - squad_root.position.x) < 1.35:
				_end_game(false, "SQUAD HIT!\nTRY ANOTHER ROUTE")
				return
		if obj.position.z > 18.0:
			moving_objects.erase(obj)
			obj.queue_free()
	if distance >= spawn_gate_at:
		_spawn_gate(-70.0, randi_range(1, 3), randi_range(1, 4), 1 if randi_range(0, 1) == 0 else 2)
		spawn_gate_at += 42.0
	if distance >= spawn_hazard_at:
		_spawn_hazard(-72.0, randi_range(-1, 1))
		spawn_hazard_at += 34.0
	if distance >= FINISH_DISTANCE - 42.0 and not finish_spawned:
		_spawn_finish()
	if distance >= FINISH_DISTANCE:
		_end_game(squad_count >= 10, "VICTORY!\nYOUR LEGION WON" if squad_count >= 10 else "DEFEAT\nGROW YOUR LEGION")
	_update_hud()

func _apply_gate(pair: Node3D) -> void:
	var selected: Node3D = null
	for child in pair.get_children():
		if child.has_meta("lane") and int(child.get_meta("lane")) == lane:
			selected = child
			break
	if selected == null:
		return
	var value := int(selected.get_meta("value"))
	var mode := int(selected.get_meta("mode"))
	if mode == 1:
		squad_count += value
	else:
		squad_count *= value
	squad_count = clampi(squad_count, 1, 120)
	_build_squad()
	_update_hud()
	pair.set_meta("passed", true)
	moving_objects.erase(pair)
	pair.queue_free()

func _update_hud() -> void:
	if is_instance_valid(hud_count):
		hud_count.text = "SQUAD  %03d" % squad_count
		hud_distance.value = minf(distance, FINISH_DISTANCE)
		hud_level.text = "LEVEL  %02d" % (1 + int(distance / FINISH_DISTANCE))

func _end_game(victory: bool, text: String) -> void:
	if game_over:
		return
	game_over = true
	won = victory
	message_label.text = text
	message_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.24) if victory else Color(1.0, 0.32, 0.3))
	restart_button.visible = true

func _restart() -> void:
	get_tree().reload_current_scene()

func _material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = 0.58
	return mat
