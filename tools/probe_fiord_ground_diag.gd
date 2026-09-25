extends Node
## DIAGNOSTIC unic, de arunc, pentru sarcina "sol + apa Fiordland".
##
## Citeste direct vertex colors de pe mesh-ul Terrain (fara sa treaca prin
## randare), ca sa separe tint-ul de vertex de lumina/shader — memoria
## `suprafata-palida-e-lumina`. Grupeaza pe panta (din normala mesh-ului,
## generata de SurfaceTool.generate_normals()) ca sa vada daca scarpul (fete
## aproape verticale) are alta culoare decat platoul.
##
## Rulare: godot --headless --path . res://tools/ProbeFiordGroundDiag.tscn -- --track=16

var _track: Node = null
var _frames: int = 0


func _ready() -> void:
	var path := "res://scenes/tracks/Track16.tscn"
	_track = (load(path) as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(_track)
	set_process(true)


func _find_terrain(root: Node) -> MeshInstance3D:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n.name == &"Terrain" and n is MeshInstance3D:
			return n as MeshInstance3D
		for c in n.get_children():
			stack.append(c)
	return null


func _process(_delta: float) -> void:
	_frames += 1
	if _frames < 3:
		return
	var terrain := _find_terrain(_track)
	if terrain == null:
		push_error("nu am gasit Terrain")
		get_tree().quit(1)
		return
	var mesh := terrain.mesh as ArrayMesh
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	print("verts=", verts.size(), " colors=", colors.size(), " normals=", normals.size())

	# Grupeaza pe panta: unghiul normalei fata de UP (grade).
	var flat_sum := Color(0, 0, 0, 0)
	var flat_n := 0
	var steep_sum := Color(0, 0, 0, 0)
	var steep_n := 0
	var mid_sum := Color(0, 0, 0, 0)
	var mid_n := 0
	var alpha_sum := 0.0
	var max_slope := 0.0
	for i in verts.size():
		var nrm: Vector3 = normals[i]
		var slope_deg := rad_to_deg(acos(clampf(nrm.y, -1.0, 1.0)))
		max_slope = maxf(max_slope, slope_deg)
		var c: Color = colors[i]
		alpha_sum += c.a
		if slope_deg < 15.0:
			flat_sum += c
			flat_n += 1
		elif slope_deg > 38.0:
			steep_sum += c
			steep_n += 1
		else:
			mid_sum += c
			mid_n += 1

	print("--- VERTEX COLOR (COLOR.rgb = tint*shade, COLOR.a = grass_w) ---")
	if flat_n > 0:
		var m: Color = flat_sum / float(flat_n)
		print("PLAT   (<15 deg, n=%d): rgb=(%.3f,%.3f,%.3f) a(grass_w)=%.4f" %
			[flat_n, m.r, m.g, m.b, m.a])
	if mid_n > 0:
		var m2: Color = mid_sum / float(mid_n)
		print("MEDIU  (15-38, n=%d): rgb=(%.3f,%.3f,%.3f) a(grass_w)=%.4f" %
			[mid_n, m2.r, m2.g, m2.b, m2.a])
	if steep_n > 0:
		var m3: Color = steep_sum / float(steep_n)
		print("ABRUPT (>38 deg, n=%d): rgb=(%.3f,%.3f,%.3f) a(grass_w)=%.4f" %
			[steep_n, m3.r, m3.g, m3.b, m3.a])
	print("max_slope_deg=", max_slope)
	print("grass_w mediu pe tot terenul=", alpha_sum / float(verts.size()))

	print("ground_tint (fiordland, din theme_flag) = MARBLE_GREY.lerp(CACTUS_GREEN, 0.28) = ",
		Palette.color(Palette.MARBLE_GREY).lerp(Palette.color(Palette.CACTUS_GREEN), 0.28))

	get_tree().quit(0)
