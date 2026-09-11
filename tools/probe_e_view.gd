extends Node
## Unde cade fundul craterului in cadrul de joc: unghi fata de axa camerei,
## plus daca sightline-ul e LIBER sau blocat de teren.
##
## De ce exista: criticul rundei 4 a cerut "elefanti lizibili in cadru" si
## scena chiar avea 5 noduri elephant. ProbeMasca --group pe cadrul de joc a
## masurat insa ZERO pixeli pentru ei, pentru flamingi si pentru crusta. Sonda
## asta separa cele doua explicatii posibile — "in afara frustumului" vs
## "ascuns de relief" — si raspunsul a fost al doilea: razele lovesc
## TerrainBody la y~1.7 chiar INAINTE de tinta, adica podeaua craterului e
## plata si o privesti tangential de la 53 m inaltime.
##
## ATENTIE la citirea MultiMesh-urilor: `get_instance_transform` intoarce
## identitate pe CPU dupa ce bufferul a plecat la RenderingServer, deci
## pozitiile raportate (0,0,0) pentru E_CrustaSare/E_Flamingi NU inseamna ca
## instantele sunt la origine. Verdictul se ia pe PIXELI (A/B cu --hide), nu
## pe transformurile citite inapoi.

func _ready() -> void:
	await get_tree().process_frame
	var only := GameState.resolve_track_index(7)
	var scene := load(GameState.TRACK_SCENES[only]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var r: TrackRoute = track.routes[0]
	var n := r.baked.size()
	var zone := track.find_child("ZoneE_Buza", true, false)
	for f in [0.40, 0.45]:
		var i := int(f * float(n)) % n
		var p: Vector3 = r.baked[i]
		var p2: Vector3 = r.baked[(i + 6) % n]
		var fwd := (p2 - p).normalized()
		# chase cam: 10 sus, 12.5 in spate, priveste inainte usor in jos
		var eye: Vector3 = p - fwd * 12.5 + Vector3(0, 10, 0)
		var look: Vector3 = p + fwd * 14.0 + Vector3(0, 1.2, 0)
		var axis := (look - eye).normalized()
		print("--- frac=%.3f eye=(%.1f,%.1f,%.1f)" % [f, eye.x, eye.y, eye.z])
		# jumatate verticala a frustumului (FOV 68 vertical) = 34 grade
		for grp in ["E_CrustaSare", "E_Flamingi", "E_Elefant281", "E_Elefant284", "E_Lerai240"]:
			var nd := zone.find_child(grp, false, false)
			if nd == null:
				print("   %s LIPSA" % grp); continue
			var pos: Vector3 = (nd as Node3D).global_position
			if nd is MultiMeshInstance3D and (nd as MultiMeshInstance3D).multimesh != null:
				var mm := (nd as MultiMeshInstance3D).multimesh
				var acc := Vector3.ZERO
				for k in mm.instance_count:
					acc += mm.get_instance_transform(k).origin
				pos = acc / float(max(1, mm.instance_count))
			var d: Vector3 = pos - eye
			var horiz := Vector2(d.x, d.z).length()
			var vert_deg := rad_to_deg(atan2(d.y, horiz))
			var axis_deg := rad_to_deg(atan2(axis.y, Vector2(axis.x, axis.z).length()))
			var space := track.get_world_3d().direct_space_state
			var q := PhysicsRayQueryParameters3D.create(eye, pos)
			var hit := space.intersect_ray(q)
			var occ := "LIBER"
			if not hit.is_empty():
				var hp: Vector3 = hit.position
				occ = "BLOCAT la %.0f m de ochi, y=%.1f, de %s" % [eye.distance_to(hp), hp.y, str(hit.collider.name)]
			print("   %-14s pos=(%.0f,%.1f,%.0f) dist=%.0f m  delta=%.1f  %s"
				% [grp, pos.x, pos.y, pos.z, horiz, vert_deg - axis_deg, occ])
	get_tree().quit(0)
