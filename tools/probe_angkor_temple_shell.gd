extends Node
## Carcasa templului Angkor Wat (Track24, B) pentru modelatorul din Blender:
##   godot --headless --path . res://tools/ProbeAngkorTempleShell.tscn
## scrie `tools/data/angkor_temple_shell.json`.
##
## De ce: soseaua trece PRIN templu printr-un tub construit din cod (`TunelTemplu`, un
## `TunnelSignalHazard` doar-tub cu sala), care da peretii pe marginea soselei, tavanul, fatadele
## si aripile portalurilor — toata coliziunea. Modelul `angkor_wat_drive.glb` e doar vizual si
## trebuie sa IMBRACE exact acel tub: orice perete desenat in fata peretelui de coliziune e un
## zid prin care masina trece, orice perete desenat in spatele lui e un zid invizibil. Asa ca
## geometria tubului se exporta din joc, nu se rescrie de mana in Blender.
##
## Coordonatele din fisier sunt in CADRUL HARTII, in care e modelat GLB-ul (X = est, Y = nord,
## Z = sus): x = X Godot, y = -Z Godot, z = Y Godot. Modelul se pune apoi in origine cu
## transformarea identitate (exportul glTF din Blender face exact conversia inversa).
##
##   road      punctele coapte ale axei intre calea de vest si calea de nord: pozitia, vectorul
##             „dreapta sensului", semilatimea soselei, lungimea de la portalul de vest
##   bore      triunghiurile corpului `TunnelBore` (pereti, tavan, movila, capace)
##   portal    triunghiurile corpului `TunnelPortal` (ramele si aripile celor doua portaluri)
##   tube      parametrii nodului

const OUT := "res://tools/data/angkor_temple_shell.json"


func _map(p: Vector3) -> Array:
	return [snappedf(p.x, 0.001), snappedf(-p.z, 0.001), snappedf(p.y, 0.001)]


func _faces_of(track: Node, body_name: String) -> Array:
	var out: Array = []
	for child in track.get_children():
		if not (child is StaticBody3D) or not String(child.name).begins_with(body_name):
			continue
		for sh in child.get_children():
			var cs := sh as CollisionShape3D
			if cs == null or not (cs.shape is ConcavePolygonShape3D):
				continue
			var faces: PackedVector3Array = (cs.shape as ConcavePolygonShape3D).get_faces()
			for v in faces:
				out.append(_map((child as Node3D).global_transform * v))
	return out


func _ready() -> void:
	await get_tree().process_frame
	var scene := load("res://scenes/tracks/Track24.tscn") as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	var sig := track.get_node_or_null("Hazarduri/TunelTemplu") as TunnelSignalHazard
	if sig == null:
		push_error("ProbeAngkorTempleShell: lipseste Hazarduri/TunelTemplu")
		get_tree().quit(1)
		return
	var i0: int = track.call("_closest_baked_index", track.to_local(sig.global_position))
	# De la 70 m inaintea portalului de vest pana la 70 m dupa cel de nord.
	var road: Array = []
	var back := i0
	var acc := 0.0
	while acc < 70.0:
		acc += r.baked[r.wrap_index(back)].distance_to(r.baked[r.wrap_index(back - 1)])
		back -= 1
	var m := -acc
	var i := back
	while m < sig.tunnel_length + 70.0 and i - back < n:
		var a := r.wrap_index(i)
		road.append({
			"i": a, "m": snappedf(m, 0.001), "p": _map(r.baked[a]),
			"side": [snappedf(r.side_at(a).x, 0.0001), snappedf(-r.side_at(a).z, 0.0001)],
			"hw": snappedf(track.width_at_index(a), 0.001),
		})
		m += r.baked[a].distance_to(r.baked[r.wrap_index(i + 1)])
		i += 1
	var bore := _faces_of(track, "TunnelBore")
	var portal := _faces_of(track, "TunnelPortal")
	var data := {
		"frame": "harta: x est, y nord, z sus (GLB in origine, identitate)",
		"tube": {
			"length": sig.tunnel_length, "half_width": sig.tunnel_half_width,
			"ceiling": sig.tunnel_ceiling, "hall_ceiling": sig.hall_ceiling,
			"portal_w": _map(sig.global_position),
		},
		"road": road, "bore": bore, "portal": portal,
	}
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	print("%s: %d puncte de drum, %d triunghiuri de tub, %d de portal" % [
		OUT, road.size(), bore.size() / 3, portal.size() / 3])
	get_tree().quit()
