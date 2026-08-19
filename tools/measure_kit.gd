extends SceneTree
## Masoara fiecare NOD din GLB-urile unui kit: cota, amprenta la sol, origine.
##
##   godot --headless --path . --script res://tools/measure_kit.gd -- --kit=baikal
##
## De ce per nod si nu per fisier: kiturile multi-piesa (ice_kit,
## forest_kit) tin zece piese intr-un GLB. Un `size` pe fisier masoara cutia
## care le cuprinde pe toate — numar care nu spune nimic despre cat loc ocupa
## o casa. Plasarea are nevoie de amprenta piesei, nu a lotului.
##
## Iese JSON pe stdout intre marcaje, ca sa poata fi citit de un script.

const KITS := {
	"baikal": [
		"res://assets/models/baikal/rocks/shaman_rock.glb",
		"res://assets/models/baikal/props/serge_pole.glb",
		"res://assets/models/baikal/structures/railway_viaduct.glb",
		"res://assets/models/baikal/structures/railway_tunnel_portal.glb",
		"res://assets/models/baikal/structures/ice_grotto_arch.glb",
		"res://assets/models/baikal/buildings/khuzhir_church.glb",
		"res://assets/models/baikal/vehicles/hovercraft_khivus.glb",
		"res://assets/models/baikal/vehicles/train_baikal.glb",
		"res://assets/models/baikal/structures/power_pylon_soviet.glb",
		"res://assets/models/baikal/structures/start_gate_logs.glb",
		# Cladirile de sat au UN FISIER PE PIESA (spre deosebire de ice_kit /
		# forest_kit / shore_kit, care raman multi-nod): sunt asezate una
		# cate una pe ulita, nu imprastiate statistic.
		"res://assets/models/baikal/buildings/log_house_a.glb",
		"res://assets/models/baikal/buildings/log_house_b.glb",
		"res://assets/models/baikal/buildings/log_house_c.glb",
		"res://assets/models/baikal/buildings/banya.glb",
		"res://assets/models/baikal/props/fish_rack.glb",
		"res://assets/models/baikal/props/well_crane.glb",
		"res://assets/models/baikal/props/woodpile.glb",
		"res://assets/models/baikal/props/village_signpost.glb",
		"res://assets/models/baikal/props/village_props.glb",
		"res://assets/models/baikal/vehicles/uaz_bukhanka.glb",
		"res://assets/models/baikal/vehicles/kamaz_truck.glb",
		"res://assets/models/baikal/props/ice_kit.glb",
		"res://assets/models/baikal/trees/forest_kit.glb",
		"res://assets/models/baikal/props/shore_kit.glb",
		"res://assets/models/baikal/props/husky_dog.glb",
		"res://assets/models/baikal/props/nerpa_seal.glb",
	],
}


func _init() -> void:
	var kit := "baikal"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--kit="):
			kit = arg.trim_prefix("--kit=")
	var out := []
	for path: String in KITS.get(kit, []):
		var scene := load(path) as PackedScene
		if scene == null:
			printerr("NU SE INCARCA: ", path)
			continue
		var inst := scene.instantiate()
		for piece in _pieces(inst):
			out.append(piece)
		inst.free()
	print("---JSON---")
	print(JSON.stringify(out))
	print("---END---")
	quit()


## Fiecare copil direct al radacinii e o piesa. Kiturile isi tin piesele exact
## asa; un GLB cu o singura piesa are un singur copil, deci acelasi cod merge
## si acolo fara caz special.
func _pieces(root: Node) -> Array:
	var out := []
	for child in root.get_children():
		var aabb := _merged_aabb(child)
		if aabb.size == Vector3.ZERO:
			continue
		out.append({
			"file": root.scene_file_path.get_file(),
			"node": child.name,
			"w": snappedf(aabb.size.x, 0.01),
			"h": snappedf(aabb.size.y, 0.01),
			"d": snappedf(aabb.size.z, 0.01),
			"base_y": snappedf(aabb.position.y, 0.01),
		})
	return out


func _merged_aabb(node: Node) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		var mesh_inst := current as MeshInstance3D
		if mesh_inst != null:
			var local := mesh_inst.get_aabb()
			var xform: Transform3D = mesh_inst.transform
			var parent := mesh_inst.get_parent()
			while parent != null and parent is Node3D and parent != node:
				xform = (parent as Node3D).transform * xform
				parent = parent.get_parent()
			var transformed := xform * local
			if first:
				result = transformed
				first = false
			else:
				result = result.merge(transformed)
		for c in current.get_children():
			stack.push_back(c)
	return result
