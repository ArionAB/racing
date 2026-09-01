extends Node
## SE INTREPATRUND baloanele aterizate?
##
## In captura, coltul din dreapta-jos e un morman de panze suprapuse care se
## citeste ca gramada de umbrele, nu ca baloane pe camp. Se masoara distanta
## intre centrele panzelor aterizate si raza lor reala din AABB.
##
## ATENTIE la ce se numara: `*_umflatura*` sunt umflaturile puse INTENTIONAT
## peste panza lor (o panza intinsa pe jos care se umfla), deci suprapunerea lor
## cu propriul parinte e ceruta, nu defect. Se raporteaza separat.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"


func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	var items: Array = []
	_walk(t, items)
	print("panze aterizate gasite: %d" % items.size())
	var bad := 0
	for i in items.size():
		for j in range(i + 1, items.size()):
			var a: Array = items[i]
			var b: Array = items[j]
			var pa: Vector3 = a[1]
			var pb: Vector3 = b[1]
			var d := Vector2(pa.x - pb.x, pa.z - pb.z).length()
			var need: float = (a[2] as float) + (b[2] as float)
			if d >= need:
				continue
			# Umflatura peste propria panza: cerut, nu defect.
			var na: String = a[0]
			var nb: String = b[0]
			var base_a := na.split("_umflatura")[0]
			var base_b := nb.split("_umflatura")[0]
			if base_a == base_b:
				continue
			bad += 1
			print("  SUPRAPUNERE %s <-> %s: %.1f m, ar trebui %.1f" % [na, nb, d, need])
	print("perechi suprapuse: %d" % bad)
	get_tree().quit()


func _walk(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Node3D and String(c.name).contains("panza"):
			var mi := _first_mesh(c)
			if mi != null:
				var ab := mi.get_aabb()
				var sc: Vector3 = (c as Node3D).global_transform.basis.get_scale()
				var r: float = maxf(ab.size.x * sc.x, ab.size.z * sc.z) * 0.5
				out.append([String(c.name), (c as Node3D).global_position, r])
		_walk(c, out)


func _first_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n as MeshInstance3D
	for c in n.get_children():
		var m := _first_mesh(c)
		if m != null:
			return m
	return null
