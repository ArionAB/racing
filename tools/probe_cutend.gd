extends Node
## Silueta REALA a taieturii: se citeste din mesh-ul construit, nu se recalculeaza.
##
## Prima versiune isi facea propria copie a formulei de creasta si a ramas sa
## raporteze cifrele VECHI dupa ce logica din CliffFace s-a schimbat — o sonda
## care masoara altceva decat ce se randeaza. Acum ia mesh-ul „Taietura ..." si
## masoara inaltimea lui pe felii, plus distanta pe orizontala pana la terenul
## din spate (ca sa prinda cazul „lespede detasata in nisip").
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"


func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	var mi := _find(t)
	if mi == null:
		print("NU EXISTA mesh de taietura — ce exista sub CliffFaces:")
		_dump(t, 0)
		get_tree().quit()
		return
	var aabb := mi.get_aabb()
	print("mesh %s: marime=(%.1f, %.1f, %.1f)" % [mi.name, aabb.size.x, aabb.size.y, aabb.size.z])
	var verts := (mi.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array
	print("vertecsi: %d" % verts.size())
	# Inaltimea panzei pe felii de-a lungul axei lungi.
	var axis := 0 if aabb.size.x >= aabb.size.z else 2
	var lo: float = aabb.position[axis]
	var hi: float = lo + aabb.size[axis]
	var space := get_viewport().world_3d.direct_space_state
	for k in 14:
		var a := lo + (hi - lo) * float(k) / 14.0
		var b := lo + (hi - lo) * float(k + 1) / 14.0
		var ymin := 1e9
		var ymax := -1e9
		var cx := 0.0
		var cz := 0.0
		var cnt := 0
		for v in verts:
			var g: Vector3 = mi.global_transform * v
			if g[axis] < a or g[axis] >= b:
				continue
			ymin = minf(ymin, g.y)
			ymax = maxf(ymax, g.y)
			cx += g.x
			cz += g.z
			cnt += 1
		if cnt == 0:
			print("  felie %2d: goala" % k)
			continue
		print("  felie %2d: inaltime %5.1f m  (%d vertecsi)" % [k, ymax - ymin, cnt])
	get_tree().quit()


func _dump(n: Node, d: int) -> void:
	for c in n.get_children():
		var nm := String(c.name)
		if nm.contains("Faleza") or nm.contains("Cliff") or nm.contains("Taietura"):
			print("   %s%s (%s)" % ["  ".repeat(d), nm, c.get_class()])
		_dump(c, d + 1)


func _find(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D and String(n.name).begins_with("Taietura"):
		return n as MeshInstance3D
	for c in n.get_children():
		var m := _find(c)
		if m != null:
			return m
	return null
