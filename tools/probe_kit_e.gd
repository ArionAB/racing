extends Node3D
## Sonda de masurat piesele de kit folosite la POI E: gabarit, origine,
## noduri de mesh, si sloturile de paleta pe care le matura UV-urile.
##
## Numele unui slot minte (SAND_MID e portocaliu, nu crem), deci masuram
## intervalul de u al fiecarei suprafete si il traducem in indici de slot.

const PATHS := [
	"res://assets/models/cappadocia/plants/vine_row.glb",
	"res://assets/models/cappadocia/plants/poplar_a.glb",
	"res://assets/models/cappadocia/plants/poplar_b.glb",
	"res://assets/models/cappadocia/plants/shrub_dry.glb",
	"res://assets/models/cappadocia/buildings/farmhouse.glb",
	"res://assets/models/cappadocia/props/balloon_landed.glb",
	"res://assets/models/cappadocia/props/balloon_basket.glb",
	"res://assets/models/cappadocia/props/balloon_envelope_a.glb",
	"res://assets/models/cappadocia/props/pottery_cart.glb",
]


func _ready() -> void:
	for p in PATHS:
		_report(p)
	get_tree().quit()


func _report(path: String) -> void:
	var ps := load(path) as PackedScene
	if ps == null:
		print("LIPSA ", path)
		return
	var root := ps.instantiate()
	print("\n=== ", path.get_file(), " ===")
	var agg := AABB()
	var first := true
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xf := _xform_to_root(mi, root)
		var ab := xf * mi.mesh.get_aabb()
		if first:
			agg = ab
			first = false
		else:
			agg = agg.merge(ab)
		var tris := 0
		var slots := {}
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			var vtx: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			tris += (idx.size() / 3) if idx.size() > 0 else (vtx.size() / 3)
			var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
			for u in uv:
				slots[int(floor(u.x * 32.0))] = true
		var keys := slots.keys()
		keys.sort()
		print("  %-28s tri=%5d  y=[%.2f..%.2f] size=(%.2f,%.2f,%.2f) sloturi=%s"
			% [mi.name, tris, ab.position.y, ab.end.y,
			ab.size.x, ab.size.y, ab.size.z, str(keys)])
	print("  TOTAL gabarit: size=(%.2f, %.2f, %.2f)  origine y=%.2f"
		% [agg.size.x, agg.size.y, agg.size.z, agg.position.y])
	root.free()


func _xform_to_root(n: Node3D, root: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur := n
	while cur != null and cur != root:
		xf = cur.transform * xf
		cur = cur.get_parent() as Node3D
	return xf
