extends SceneTree
## TEMPORAR: verifica ca ruptura de accente a pastrat IARBA (slot 12) pe atlas
## pe piesele de zidarie, si ca restul corpului a primit `inca_stone`.
## Fara asta, "clasa s-a aplicat" nu spune daca a sters exact ce trebuia pastrat.
const PIECES := ["structures/inca_wall_a", "structures/inca_wall_b",
	"structures/inca_stair_a", "structures/inca_stair_b",
	"structures/inca_bridge_ledge", "buildings/inca_house_a",
	"buildings/guardhouse", "buildings/inca_house_b"]
var _h: WorldProp = null
var _f := 0

func _process(_d: float) -> bool:
	if _h == null:
		_h = WorldProp.new()
		for p in PIECES:
			var scn: PackedScene = load("res://assets/models/machupicchu/%s.glb" % p)
			var inst: Node3D = scn.instantiate()
			inst.name = p.get_file()
			_h.add_child(inst)
		root.add_child(_h)
		return false
	_f += 1
	if _f < 3:
		return false
	var world := Palette.world_material()
	print("=== RUPTURA DE ACCENTE, zidaria incasa ===")
	for child in _h.get_children():
		print("- ", child.name)
		_dump(child, world, "    ")
	quit()
	return true

func _dump(n: Node, world: Material, ind: String) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var m := mi.material_override
		var tag := "ATLAS(pictat)" if m == world else ("CLASA:" + m.resource_name if m != null else "—")
		var tris := 0
		if mi.mesh != null:
			for si in mi.mesh.get_surface_count():
				tris += mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX].size() / 3
		print(ind, mi.name, "  ", tag, "  (~", tris, " tri)")
	for c in n.get_children():
		_dump(c, world, ind)
