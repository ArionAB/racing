extends Node
## Unde e FATA REALA a peretelui, la fiecare fractie si la fiecare cota.
##
## Treptele scrise din datele de rand au aterizat cu 4-8 m INAINTEA sau IN
## SPATELE peretelui (ProbeLedge). Cauza: `canyon_d_rows.txt` da centrul
## fiecarui MODUL, dar modulele au jitter de ±6 m pe normala si se suprapun, iz
## fata vizibila a peretelui la o fractie data e ANVELOPA lor, nu profilul
## modulului de acolo.
##
## Deci treptele nu se pot deriva din randuri. Se deriva din anvelopa masurata
## AICI: pentru un caroiaj (fractie x cota), cel mai apropiat vertex de perete
## fata de axul drumului. Asta e suprafata pe care trebuie lipite.

const F0 := 0.428
const F1 := 0.534

func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[6]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var base := track.get_node_or_null("DecorManual/D) Canionul rosu")
	var faleza := base.get_node_or_null("Faleza")
	# Toti vertecsii peretelui, in lume.
	var verts: PackedVector3Array = PackedVector3Array()
	for mi in faleza.find_children("*", "MeshInstance3D", true, false):
		var mm := (mi as MeshInstance3D).mesh
		if mm == null: continue
		var xf := (mi as MeshInstance3D).global_transform
		for s in mm.get_surface_count():
			var arr := mm.surface_get_arrays(s)
			for v in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				verts.append(xf * v)
	print("verts=", verts.size())
	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var out := ""
	var nrows := 0
	var f := F0
	while f < F1:
		var idx := int(f * float(n)) % n
		var p: Vector3 = pts[idx]
		var ahead: Vector3 = pts[(idx + 10) % n]
		var d := (ahead - p); d.y = 0.0; d = d.normalized()
		var sv := Vector3(d.z, 0.0, -d.x)
		# Vertecsi in felia de ±6 m in lungul drumului, pe partea falezei.
		for lvl in range(0, 9):
			var y0: float = p.y - 2.0 + float(lvl) * 4.0
			var nearest := 1e9
			var got := false
			var cnt_lvl := 0
			for v in verts:
				if absf(v.y - y0) > 2.0:
					continue
				var rel: Vector3 = v - p
				var along: float = rel.dot(d)
				# FEREASTRA STRAMTA (±1.5 m, era ±6). Cu ±6 m, „cel mai
				# apropiat vertex" venea de pe un PINTEN aflat la 6 m in
				# lungul drumului, nu de pe fata din dreptul feliei —
				# modulele au jitter de ±6 m pe normala, deci vecinul din
				# lungul drumului poate sta mult mai in fata. Treptele
				# asezate pe cifra aia intrau FIX IN SPATELE pintenului:
				# masurat cu ProbeLedge2, 76 din 89 aveau perete in fata lor.
				if absf(along) > 1.5:
					continue
				var lat: float = rel.dot(sv)
				if lat < 2.0:
					continue
				cnt_lvl += 1
				if lat < nearest:
					nearest = lat
					got = true
			if got:
				# Se scrie si CATI vertecsi are felia. O cota unde peretele abia
				# exista (cateva varfuri de creasta) da tot un `nearest` valid,
				# iar o treapta pusa acolo pluteste pe cer — asa a aparut placa
				# de langa varf pe zz/r3_step3_048.png. Cifra asta lasa
				# generatorul sa ceara ROCA, nu doar o cota.
				out += "%.4f	%.2f	%.3f	%d
" % [f, y0, nearest, cnt_lvl]
				nrows += 1
		f += 0.0016
	var fo := FileAccess.open("res://canyon_d_face.txt", FileAccess.WRITE)
	fo.store_string(out)
	fo.close()
	print("face rows: ", nrows)
	get_tree().quit(0)
