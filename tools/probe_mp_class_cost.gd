extends SceneTree
## TEMPORAR (pasul 4, clasele de textura Machu Picchu): masoara COSTUL REAL in
## materiale al claselor, plantand cate o instanta din fiecare piesa de kit care
## ar purta o clasa, si numarand materialele UNICE exact ca probe_decor
## (all_mats pe instance_id, deduplicat global).
##
##   godot --headless --path <wt> --script res://tools/probe_mp_class_cost.gd
##
## Piesele sunt cele din inventarul masurat care ating clasele candidate:
## zidarie (ziduri/trepte/ruine/fantana), padure de nori (ferigi/bambus/bromelii),
## stanca de orizont, bolovani cu muschi, copaci.
const PIECES := [
	"structures/inca_wall_a", "structures/inca_wall_b",
	"structures/inca_stair_a", "structures/inca_stair_b",
	"structures/inca_bridge_ledge", "structures/fountain_basin",
	"buildings/inca_house_a", "buildings/inca_house_b", "buildings/guardhouse",
	"plants/tree_fern", "plants/bamboo_clump", "plants/bromeliad",
	"plants/orchid_cluster", "plants/polylepis_a", "plants/polylepis_b",
	"rocks/moss_boulder_a", "rocks/moss_boulder_b", "rocks/moss_boulder_c",
	"rocks/gorge_far_wall", "rocks/huayna_picchu", "rocks/machu_picchu_mountain",
	"animals/condor", "animals/llama",
	"props/tent_a", "props/tent_b", "props/backpack_pile",
]

var _t: Node = null
var _f := 0
## Cate clase candidate se aplica in rularea asta (0 = doar kitul, pe atlas).
var _n_classes := 0

## Clasele candidate, in ORDINEA in care se adauga cumulativ, si piesele care
## le poarta. Fiecare rulare cu --classes=k aplica primele k.
const CANDIDATES := [
	["inca_stone", ["Inca_Wall_A", "Inca_Wall_B", "Inca_Stair_A",
		"Inca_Stair_B", "Inca_Bridge_Ledge", "House_Ruin", "Basin"]],
	# Reutilizari, ZERO clase noi: macchia pentru padurea de nori, rock pentru
	# stanca de orizont, bark pentru trunchiuri. Se masoara ce costa fiecare.
	["macchia", ["Tree_Fern", "Bamboo_Clump", "Bromeliad"]],
	["rock", ["Machu_Picchu_Mountain", "Huayna_Picchu", "Gorge_Far_Wall"]],
	["bark", ["Polylepis_A", "Polylepis_B"]],
]

func _process(_d: float) -> bool:
	if _t == null:
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--classes="):
				_n_classes = int(a.trim_prefix("--classes="))
		var ps: PackedScene = load("res://scenes/tracks/Track15.tscn")
		_t = ps.instantiate()
		root.add_child(_t)
		return false
	_f += 1
	if _f == 2:
		_plant()
		return false
	if _f < 6:
		return false
	_report()
	quit()
	return true


## Planteaza piesele sub un WorldProp, ca in decorul manual: asa trec prin
## _remap_model_slots / _apply_model_classes, adica exact drumul din joc.
func _plant() -> void:
	var holder := WorldProp.new()
	holder.name = "SondaClase"
	var x := 0.0
	for p in PIECES:
		var path := "res://assets/models/machupicchu/%s.glb" % p
		if not ResourceLoader.exists(path):
			print("LIPSA: ", path)
			continue
		var scn: PackedScene = load(path)
		var inst: Node3D = scn.instantiate()
		inst.position = Vector3(x, 0.0, 0.0)
		x += 30.0
		holder.add_child(inst)
	# Copiii intra INAINTE de add_child(holder): `_ready` al lui WorldProp
	# (apply_class_materials + _apply_model_classes) trebuie sa-i gaseasca
	# deja acolo, altfel piesele raman cu materialul lor din .glb si
	# masuratoarea numara 26 de atlasuri in loc de unul.
	_t.add_child(holder)
	# Aplica primele `_n_classes` clase candidate, exact prin drumul din joc
	# (`Palette.apply_class_materials`, acelasi pe care il cheama WorldProp).
	if _n_classes > 0:
		var map := {}
		for i in range(mini(_n_classes, CANDIDATES.size())):
			var cls: String = CANDIDATES[i][0]
			for part in CANDIDATES[i][1]:
				map[part] = Palette.TRI_PREFIX + cls
		Palette.apply_class_materials(holder, map)


func _report() -> void:
	var world := Palette.world_material()
	var mats := {}
	var atlas_nodes := 0
	var stack: Array[Node] = [_t]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		var mat: Material = null
		var mesh: Mesh = null
		if n is MeshInstance3D:
			mat = (n as MeshInstance3D).material_override
			mesh = (n as MeshInstance3D).mesh
		elif n is MultiMeshInstance3D:
			var mm := (n as MultiMeshInstance3D).multimesh
			if mm == null:
				continue
			mat = (n as MultiMeshInstance3D).material_override
			mesh = mm.mesh
		else:
			continue
		if mat == null and mesh != null and mesh.get_surface_count() > 0:
			mat = mesh.surface_get_material(0)
		var id: int = mat.get_instance_id() if mat != null else 0
		if mat == world:
			atlas_nodes += 1
		if not mats.has(id):
			var nm := ""
			if mat != null:
				nm = mat.resource_name
			mats[id] = {"n": 0, "atlas": mat == world, "nume": nm,
				"ex": str(_t.get_path_to(n)).substr(0, 60)}
		mats[id].n += 1
	print("=== COST DE CLASE, Track15 + ", PIECES.size(), " piese, clase-extra=", _n_classes, " ===")
	print("materiale UNICE: ", mats.size(), "   noduri pe atlas: ", atlas_nodes)
	for id in mats:
		if not mats[id].atlas:
			print("  [", mats[id].nume, "] noduri=", mats[id].n, "  ex=", mats[id].ex)
