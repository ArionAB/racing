extends Node
## Testul care conteaza, fara geometrie analitica: trag raze IN JOS prin
## amprenta fiecarui turn si intreb daca lovesc SUPRAFATA DE CURSE. Daca da,
## turnul e peste carosabil, indiferent ce spun distantele laterale.
## Foloseste is_on_road-ul pistei, aceeasi definitie ca jocul.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var root := track.get_node("DecorManual/1) Piata Kuixinglou")
	var bad := 0
	var seen := 0
	for ch in root.get_children():
		if not str(ch.name).begins_with("turn_piata"): continue
		var n := ch as Node3D
		var mi: MeshInstance3D = _f(n)
		if mi == null: continue
		seen += 1
		var lab := mi.mesh.get_aabb()
		var xf := mi.global_transform
		var hits := 0
		var tot := 0
		# grila deasa peste amprenta piesei
		for gx in 9:
			for gz in 9:
				var loc := Vector3(
					lab.position.x + lab.size.x * (float(gx) / 8.0),
					0.0,
					lab.position.z + lab.size.z * (float(gz) / 8.0))
				var w: Vector3 = xf * loc
				tot += 1
				var idx := track.closest_index_global(w)
				if track.is_on_road(idx, w):
					hits += 1
		if hits > 0:
			bad += 1
		print("%s  puncte_peste_carosabil=%d/%d %s" % [n.name, hits, tot,
			("!!PESTE CAROSABIL" if hits > 0 else "ok")])
	if seen == 0:
		print("VERDICT SONDA INVALIDA: 0 turnuri examinate")
	elif bad > 0:
		print("VERDICT RESPINS: %d din %d turnuri peste carosabil" % [bad, seen])
	else:
		print("VERDICT OK: %d turnuri, niciunul peste carosabil" % seen)
	get_tree().quit()
func _f(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for ch in n.get_children():
		var r := _f(ch)
		if r: return r
	return null
