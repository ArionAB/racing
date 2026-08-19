extends Node
## Exporta geometria unei piste ca JSON, pentru desenarea hartii 2D de lucru.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ExportTrackMap.tscn -- --track=3
##
## Trebuie rulata ca SCENA, nu cu --script: are nevoie de autoload-uri.
##
## De ce exista: brief-ul de pista descrie POI-urile in cuvinte si fractii
## ORIENTATIVE ("B la 0.10, viaduct la 0.74"). Traseul real din Curve3D e
## desenat de mana si nu respecta automat fractiile alea. Harta desenata din
## acest export arata unde CHIAR cade fiecare fractie, deci unde traseul se
## abate de la brief — lucru pe care nicio vedere din editor nu il spune.


func _ready() -> void:
	await get_tree().process_frame
	var only := 3
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = int(arg.trim_prefix("--track="))

	var scene := load(GameState.TRACK_SCENES[only]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var out := {}
	out["name"] = GameState.TRACK_NAMES[only]
	out["half_width"] = track.half_width

	# Linia mediana, ca (x, y, z, frac, half_width) la fiecare punct copt.
	var n := track.baked.size()
	var center := []
	for i in n:
		var p: Vector3 = track.baked[i]
		var f := track.frac_at(i)
		center.append({
			"x": snappedf(p.x, 0.01), "y": snappedf(p.y, 0.01),
			"z": snappedf(p.z, 0.01),
			"f": snappedf(f, 0.0001),
			"w": snappedf(track.width_at(f), 0.01),
		})
	out["center"] = center
	out["length_m"] = snappedf(_length(track.baked), 0.1)

	# Scurtaturile: routes[1..] sunt benzi separate.
	var branches := []
	for r in range(1, track.routes.size()):
		var route: TrackRoute = track.routes[r]
		var pts := []
		for p in route.baked:
			pts.append({"x": snappedf(p.x, 0.01), "z": snappedf(p.z, 0.01)})
		branches.append({"half_width": route.half_width, "points": pts})
	out["branches"] = branches

	# Nodurile puse de mana in scena: varfuri, hazarde, path movere.
	out["markers"] = _markers(track)

	var path := "user://track_map_%d.json" % only
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	print("scris: %s" % ProjectSettings.globalize_path(path))
	print("puncte: %d, lungime: %.1f m, scurtaturi: %d"
		% [n, out["length_m"], branches.size()])
	get_tree().quit(0)


func _length(pts: PackedVector3Array) -> float:
	var d := 0.0
	for i in pts.size():
		d += pts[i].distance_to(pts[(i + 1) % pts.size()])
	return d


## Tot ce sta ca nod in .tscn si are o pozitie: varfuri de teren, hazarde,
## trasee de mobile. Astea sunt lucrurile pe care dezvoltatorul le-a plasat
## de mana, deci exact ce trebuie sa se vada pe harta.
func _markers(track: Track) -> Array:
	var out := []
	for child in track.get_children():
		_collect(child, child.name, out, track)
	return out


func _collect(node: Node, group: String, out: Array, track: Track) -> void:
	if node is Node3D and node.get_parent() != track:
		var p: Vector3 = (node as Node3D).global_position
		var entry := {
			"group": group, "name": node.name,
			"x": snappedf(p.x, 0.1), "z": snappedf(p.z, 0.1),
			"y": snappedf(p.y, 0.1),
		}
		if "radius_m" in node:
			entry["radius"] = node.radius_m
		out.append(entry)
	for c in node.get_children():
		_collect(c, group, out, track)
