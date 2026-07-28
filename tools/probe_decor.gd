extends SceneTree
## Garda de draw call-uri: numara materialele distincte din fiecare pista si arata
## DE UNDE vin (procedural din track.gd, sau dintr-un GLB anume). Un material =
## (cel putin) un draw call, iar draw call-urile sunt constrangerea pentru 60fps
## pe mid-range (CLAUDE.md, "Constrangeri mobile 3D").
##
## Ce prinde: regresia clasica — cineva pune iar StandardMaterial3D.new() intr-o
## bucla de decor si fiecare instanta isi capata materialul ei. Atunci raportul
## mesh-uri/material cade spre 1.0 si build-ul pica.
##
## Rulare (toate pistele, cod de iesire 1 daca vreuna pica):
##   godot --headless --path . --script res://tools/probe_decor.gd
## O singura pista, doar pentru raport:
##   godot --headless --path . --script res://tools/probe_decor.gd -- --track=2

## Cate mesh-uri procedurale trebuie sa imparta, in medie, un material.
## Masurat la introducerea garzii: Dunele 2.8 · Track02 7.8 · Track03 7.9.
## Dunele e cazul strans — are multe culori distincte legitime (asfalt, borduri,
## linii, gimmick-uri). Coborarea reala sub pragul asta cere atlasul de paleta,
## vezi docs/blender_export.md.
const MIN_MESHES_PER_MATERIAL: float = 2.5

## Cate mesh-uri procedurale sunt necesare ca raportul sa fie semnificativ.
const MIN_SAMPLE: int = 20

var _paths: Array[String] = []
var _index: int = 0
var _frames: int = 0
var _track: Node = null
var _rows: Array[Dictionary] = []


func _initialize() -> void:
	var only := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = int(arg.trim_prefix("--track="))
	for i in range(1, 10):
		var path := "res://scenes/tracks/Track%02d.tscn" % i
		if not ResourceLoader.exists(path):
			continue
		if only < 0 or only == i:
			_paths.append(path)
	if _paths.is_empty():
		push_error("probe_decor: nu am gasit nicio pista")
		quit(1)


func _process(_delta: float) -> bool:
	if _track == null:
		if _index >= _paths.size():
			return _report()
		_track = (load(_paths[_index]) as PackedScene).instantiate()
		root.add_child(_track)
		_frames = 0
		return false

	_frames += 1
	if _frames < 3:
		return false # lasam rebuild() sa termine

	_rows.append(_measure(_paths[_index], _track))
	root.remove_child(_track)
	_track.free()
	_track = null
	_index += 1
	return false


func _measure(path: String, track: Node) -> Dictionary:
	var world_mat := Palette.world_material()
	var by_source := {}
	var all_mats := {}
	var mesh_count := 0
	var on_atlas := 0

	for node in _walk(track):
		if not (node is MeshInstance3D):
			continue
		var mi := node as MeshInstance3D
		mesh_count += 1
		var mat: Material = mi.material_override
		if mat == null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
			mat = mi.mesh.surface_get_material(0)
		if mat == world_mat:
			on_atlas += 1
		var key := mat.get_instance_id() if mat != null else 0
		all_mats[key] = true
		var src := _source_of(mi, track)
		if not by_source.has(src):
			by_source[src] = {"mats": {}, "meshes": 0}
		by_source[src].mats[key] = true
		by_source[src].meshes += 1

	var proc: Dictionary = by_source.get("procedural (track.gd)", {"mats": {}, "meshes": 0})
	var proc_meshes: int = proc.meshes
	var proc_mats: int = proc.mats.size()
	var ratio := float(proc_meshes) / float(maxi(proc_mats, 1))
	return {
		"path": path.get_file().get_basename(),
		"meshes": mesh_count,
		"materials": all_mats.size(),
		"on_atlas": on_atlas,
		"proc_meshes": proc_meshes,
		"proc_materials": proc_mats,
		"ratio": ratio,
		"ok": proc_meshes < MIN_SAMPLE or ratio >= MIN_MESHES_PER_MATERIAL,
		"sources": by_source,
	}


func _report() -> bool:
	var failed := false
	print("=== GARDA DE DRAW CALL-URI (prag: %.1f mesh-uri procedurale / material) ==="
		% MIN_MESHES_PER_MATERIAL)
	print("%-10s %7s %6s %6s %11s %8s %7s"
		% ["pista", "mesh-uri", "mat.", "atlas", "procedural", "raport", "stare"])
	print("-".repeat(64))
	for row in _rows:
		if not row.ok:
			failed = true
		print("%-10s %7d %6d %6d %5d/%-5d %8.2f %7s" % [
			row.path, row.meshes, row.materials, row.on_atlas,
			row.proc_meshes, row.proc_materials, row.ratio,
			"OK" if row.ok else "PICA"])

	for row in _rows:
		print("\n%s — pe surse:" % row.path)
		var keys: Array = row.sources.keys()
		keys.sort_custom(func(a, b): return row.sources[a].mats.size() > row.sources[b].mats.size())
		for src in keys:
			print("  %-26s %4d mesh-uri  %3d materiale"
				% [src, row.sources[src].meshes, row.sources[src].mats.size()])

	print("\nVERDICT: %s" % ("PROBLEMA" if failed else "OK"))
	quit(1 if failed else 0)
	return true


## De unde vine mesh-ul: dintr-un GLB importat (are ca stramos un nod numit dupa
## fisier) sau construit procedural in track.gd.
func _source_of(mi: MeshInstance3D, track: Node) -> String:
	const KNOWN := ["cactus", "rocks", "bucket", "sandcastle", "start_arch", "beach_ball",
		"toy_excavator", "toy_dino", "garden_hose", "bowling_pin", "sandbox_border",
		"water_tower", "windmill", "gas_station", "route66"]
	var n: Node = mi
	while n != null and n != track:
		var lower := String(n.name).to_lower()
		for k in KNOWN:
			if lower.begins_with(k) or lower.begins_with(k.replace("_", "")):
				return "GLB: " + k
		n = n.get_parent()
	if mi.mesh != null and mi.mesh.get_surface_count() > 0:
		return "procedural (track.gd)"
	return "necunoscut"


func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for c in node.get_children():
		out.append_array(_walk(c))
	return out
