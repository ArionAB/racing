## Unde ajung siluetele de orizont pe o pista JUMATATE PE APA.
##
## `_build_horizon` le ingroapa 4 m in TEREN. Pe uscat e corect. Pe apa,
## terenul e fundul marii (-15,30 pe Track22), deci silueta ajunge la -19,30
## si din ea se vede doar varful — rupt de linia apei, ca o insula care
## pluteste. Cheia `dy` per inel exista exact pentru asemenea corectii.
extends Node


func _ready() -> void:
	var scene := load("res://scenes/tracks/Track22.tscn") as PackedScene
	var track := scene.instantiate()
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var sampler = track.get("_sampler")
	var sea_y: float = 0.0
	if track.has_method("sea_level_y"):
		sea_y = track.sea_level_y()
	print("=== cota marii: %+.2f ===" % sea_y)
	print("%-16s %9s %9s  %s" % ["silueta", "teren", "cota", "stare"])
	var pe_apa := 0
	var pe_uscat := 0
	for ch in track.get_children():
		var nm := String(ch.name)
		# Siluetele de orizont ajung ca `@Node3D@NNN`: `_extract_glb_node`
		# le scoate din GLB fara sa le dea nume, deci se recunosc dupa FORMA
		# (un singur copil mesh, latime peste 100 m), nu dupa nume.
		if not (ch is Node3D):
			continue
		var mi: MeshInstance3D = null
		for c in (ch as Node3D).get_children():
			if c is MeshInstance3D:
				mi = c as MeshInstance3D
				break
		if mi == null or mi.mesh == null:
			continue
		var aabb := mi.mesh.get_aabb()
		if aabb.size.x < 100.0:
			continue
		var p: Vector3 = (ch as Node3D).position
		var gy: float = sampler.ground_y(p.x, p.z)
		var e_apa: bool = gy < sea_y - 1.0
		if e_apa:
			pe_apa += 1
		else:
			pe_uscat += 1
		print("%-16s %+9.2f %+9.2f  %s" % [nm, gy, p.y,
			("PE APA (fund %+.1f) — baza la %+.1f, sub mare" % [gy, p.y]) if e_apa
			else "pe uscat"])
	print("")
	print("=== %d siluete pe apa, %d pe uscat ===" % [pe_apa, pe_uscat])
	if pe_apa + pe_uscat == 0:
		print("(niciun nod gasit — numele copiilor pistei:)")
		for ch2 in track.get_children():
			print("   ", ch2.name)
	get_tree().quit(0)
