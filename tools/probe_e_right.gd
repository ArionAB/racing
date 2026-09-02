extends Node3D
## Ce inaltime are terenul in TREIMEA DREAPTA a cadrului de sofer la POI E, si
## la ce distanta. Fara asta, "umple dreapta" ramane ghicit: nu stii daca acolo
## e o panta care urca (si atunci un obiect de 4 m dispare in ea) sau o vale
## care coboara (si atunci trebuie ceva inalt, pus aproape).
const FRACS := [0.56, 0.60, 0.64]

func _ready() -> void:
	var track := get_parent().get_node_or_null("Track13")
	if track == null:
		push_error("nu gasesc Track13")
		get_tree().quit()
		return
	await get_tree().process_frame
	var route = track.get("routes")[0]
	var baked: PackedVector3Array = route.baked
	var n := baked.size()
	var sampler = track.get("_sampler")
	for f in FRACS:
		var i := int(f * n) % n
		var p: Vector3 = baked[i]
		var fw: Vector3 = (baked[(i + 6) % n] - p).normalized()
		# DREAPTA = fw.cross(UP) = (-fw.z, 0, fw.x). Prima versiune avea semnul
		# invers si a asezat toate hornurile pe coama din STANGA — se vedeau
		# lespezi iesind din dealul din stanga pe captura r2k. Se deriva, nu se
		# ghiceste (memoria `rotatii-in-builder-semnul`).
		var rt := Vector3(-fw.z, 0, fw.x)
		print("--- frac %.2f  pos (%.1f, %.1f, %.1f) ---" % [f, p.x, p.y, p.z])
		for dist in [20.0, 40.0, 70.0, 110.0, 160.0]:
			var line := "  la %5.0f m dreapta:" % dist
			for lat in [15.0, 35.0, 60.0]:
				var q: Vector3 = p + fw * dist + rt * lat
				var gy: float = sampler.ground_y(q.x, q.z)
				line += "  lat%3.0f dy %+6.1f" % [lat, gy - p.y]
			print(line)
	get_tree().quit()
