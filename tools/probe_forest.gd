extends Node
## Sonda padurea in masa (Kyoto, MeshForest). Incarca Track18, asteapta semnalul
## `built` si raporta instante / felii / triunghiuri / timp. Cu --window masoara si
## timpul pistei intregi pana la padure. Rulare:
##   godot --headless --path . res://tools/ProbeForest.tscn -- [--off] [--zones]
## --off : stinge padurea (A/B de timp si de materiale).
## MASURATOARE MOARTA: daca nu s-a plasat nicio instanta, sonda spune asta si pica.
func _ready() -> void:
	var off := "--off" in OS.get_cmdline_user_args()
	var t0 := Time.get_ticks_msec()
	var scene := load("res://scenes/tracks/Track18.tscn") as PackedScene
	var track := scene.instantiate()
	var forest := track.get_node_or_null("PadureMasa")
	if forest != null and off:
		forest.set("enabled", false)
	add_child(track)
	if forest == null:
		print("PROBA: nu exista PadureMasa"); get_tree().quit(2); return
	if not off:
		var guard := 0
		while not bool(forest.get("done")) and guard < 3000:
			await get_tree().process_frame
			guard += 1
		if not bool(forest.get("done")):
			print("PROBA: padurea nu s-a terminat"); get_tree().quit(2); return
		if int(forest.get("instance_count")) == 0:
			print("MASURATOARE MOARTA: 0 instante"); get_tree().quit(2); return
	else:
		for i in 30:
			await get_tree().process_frame
	print("TIMP pista+padure: %d ms (de la instantiere)" % (Time.get_ticks_msec() - t0))
	if not off:
		print("instante=%d felii=%d tris_total=%d build_ms=%d" % [forest.get("instance_count"),
			forest.get("slice_count"), forest.get("total_tris"), forest.get("build_ms")])
		print("specii: ", forest.get("counts_by_species"))
		print("tris pe specie: ", forest.get("tris_by_species"))
		print("zone: ", forest.get("counts_by_zone"))
		print("respinse: ", forest.get("rejected"))
		# Control: feliile au transformari nenule.
		var nz := 0
		var tot := 0
		for c in forest.get_children():
			var mmi := c as MultiMeshInstance3D
			if mmi == null:
				continue
			tot += 1
			if mmi.multimesh.instance_count > 0 and mmi.multimesh.get_instance_transform(0).origin != Vector3.ZERO:
				nz += 1
		print("CONTROL felii cu prima instanta nenula: %d / %d" % [nz, tot])
		# Treptele de LOD (oct 2026): cate MultiMesh-uri are fiecare treapta,
		# cate triunghiuri ar desena toate instantele ei si intervalul de
		# vizibilitate — ca sa se vada ca treapta MEDIE exista si sta intre
		# intreg si grosier, nu doar ca cifra totala s-a miscat (memoria
		# `reglajul-ieftin-se-testeaza-pe-cifra`).
		var per_level := {}
		for c in forest.get_children():
			var mmi := c as MultiMeshInstance3D
			if mmi == null:
				continue
			var level := "near"
			if mmi.name.ends_with("_mid"):
				level = "mid"
			elif mmi.name.ends_with("_far"):
				level = "far"
			elif mmi.name.ends_with("_celula"):
				level = "celula"
			elif mmi.name.ends_with("_bulgari"):
				level = "bulgari"
			if not per_level.has(level):
				per_level[level] = {"mmi": 0, "tris": 0, "begin_m": [INF, 0.0], "end_m": [INF, 0.0]}
			var d: Dictionary = per_level[level]
			d["mmi"] = int(d["mmi"]) + 1
			# Pragurile (minim/maxim pe treapta): cu intinderea feliei adunata,
			# pragul pe centru variaza de la felie la felie (vezi `lod_near_m`).
			d["begin_m"] = [minf(d["begin_m"][0], mmi.visibility_range_begin), maxf(d["begin_m"][1], mmi.visibility_range_begin)]
			d["end_m"] = [minf(d["end_m"][0], mmi.visibility_range_end), maxf(d["end_m"][1], mmi.visibility_range_end)]
			var mesh := mmi.multimesh.mesh
			var t := 0
			for s in mesh.get_surface_count():
				var idx: Variant = mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX]
				if idx != null:
					t += (idx as PackedInt32Array).size() / 3
			d["tris"] = int(d["tris"]) + t * mmi.multimesh.instance_count
		print("LOD trepte (mmi, tri daca s-ar desena toate, praguri min/max m): ", per_level)
		if not per_level.has("mid"):
			print("ATENTIE: nicio felie pe treapta MEDIE de LOD")
	get_tree().quit(0)
