extends Node
## CINE OCUPA TREIMEA DE JOS A CADRULUI?
##
## De ce exista. Lead-ul, masurand captura de la 0.05: "drumul ocupa ~45% din
## cadru, gol; in referinta aceeasi banda de cadru e plina de conuri". Sonda
## veche, `probe_frame_pick`, numara conuri INTREGI in frustum si raspundea 115
## la aceeasi fractie — cifra care a lasat problema sa treaca de patru runde.
##
## De ce minte cifra veche: numara obiecte, nu SUPRAFATA DE ECRAN, si nu se uita
## deloc UNDE cade obiectul in cadru. 115 conuri asezate sus si in lateral, la
## 27-40 m, umplu cerul si marginile si lasa treimea de jos asfalt gol — exact
## poza livrata. Aceeasi clasa de esec ca in memoria `masoara-inainte-nu-langa`:
## sonda masoara ce e usor de numarat, nu ce vede ochiul.
##
## Ce masoara asta: proiecteaza gabaritul fiecarui prop de decor in camera
## INGHETATA de masurare (MEASURE_* din snapshot.gd, aceiasi parametri ca
## `--driver`) si aduna cate din pixelii treimii de jos sunt acoperiti de ceva
## care nu e sosea. Plus distanta pana la cel mai apropiat prop care chiar cade
## in treimea de jos — nu doar "in frustum".
##
##   godot --headless --path . res://tools/ProbeCappTreime.tscn -- --frac=0.05
##
## Tinta: peste 25% din treimea de jos acoperita de decor, si ceva la sub 15 m.
## Masurat la inceputul rundei 15: 9.8% la frac 0.05, 13.8% la 0.06.
##
## LIMITA, ca sa nu fie citita gresit: raza vede doar ce are CORP FIZIC. Decorul
## manual capata corp automat (memoria `decor-manual-coliziune`), dar ce e marcat
## `coliziune = "niciuna"` e invizibil pentru sonda desi se vede pe ecran. Deci
## cifra e un PRAG DE JOS — daca urca, sigur s-a umplut cadrul; daca nu urca,
## mai trebuie citita si captura.

const MEASURE_DIST: float = 7.5
const MEASURE_HEIGHT: float = 3.2
const MEASURE_FOV: float = 68.0
const MEASURE_LOOK_AHEAD: float = 14.0
const MEASURE_LOOK_HEIGHT: float = 1.2
const W: int = 1280
const H: int = 720


func _ready() -> void:
	await get_tree().process_frame
	var fracs: Array[float] = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frac="):
			fracs.append(float(a.split("=")[1]))
	if fracs.is_empty():
		fracs = [0.05, 0.06]

	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 5:
		await get_tree().process_frame

	# Prop-urile de decor: tot ce are mesh sub DecorManual, mai putin soseaua.
	var props: Array = []
	var dm: Node = t.get_node_or_null("DecorManual")
	if dm == null:
		print("fara DecorManual")
		get_tree().quit()
		return
	var stack: Array[Node] = [dm]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null or not mi.visible:
			continue
		props.append(mi)

	var cam := Camera3D.new()
	cam.fov = MEASURE_FOV
	cam.near = 0.05
	cam.far = 400.0
	add_child(cam)
	# Viewport-ul headless n-are dimensiunea capturii; proiectia se face de mana
	# din unproject-ul camerei, deci se forteaza raportul de aspect al capturii.
	get_viewport().size = Vector2i(W, H)
	await get_tree().process_frame

	var route: Object = t.route_at(0)
	var pts: PackedVector3Array = route.baked
	var n: int = pts.size()

	for f in fracs:
		var idx: int = int(f * float(n)) % n
		var focus: Vector3 = pts[idx]
		var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
		var dir: Vector3 = (ahead - focus).normalized()
		cam.global_position = focus - dir * MEASURE_DIST + Vector3.UP * MEASURE_HEIGHT
		cam.look_at(focus + dir * MEASURE_LOOK_AHEAD
			+ Vector3.UP * MEASURE_LOOK_HEIGHT, Vector3.UP)
		await get_tree().process_frame

		# ACOPERIRE PRIN RAZE, nu prin gabarite. Prima varianta proiecta AABB-ul
		# fiecarui prop si aduna dreptunghiuri: a raspuns 82%% acoperire pe exact
		# captura in care lead-ul masurase drum gol. Cauza e in geometria
		# problemei, nu in reglaj — un con INALT si DEPARTE are un gabarit care
		# se intinde de sus pana jos in cadru, deci "atinge" treimea de jos fara
		# sa puna un singur pixel acolo. Un dreptunghi nu e o silueta.
		#
		# O raza prin fiecare celula raspunde la intrebarea reala: daca as sta in
		# pixelul asta, ce vad? Coliziunea decorului exista deja (memoria
		# `decor-manual-coliziune`), deci raza loveste chiar corpurile care se
		# desenează.
		const GX := 96
		const GY := 32
		var space := get_viewport().world_3d.direct_space_state
		var y_lo := int(H * 2.0 / 3.0)
		var cov := 0
		var tot := 0
		var nearest := 9999.0
		var nearest_name := ""
		var seen := {}
		for gy in GY:
			for gx in GX:
				var sx := (float(gx) + 0.5) / float(GX) * float(W)
				var sy := float(y_lo) + (float(gy) + 0.5) / float(GY) * float(H - y_lo)
				var from := cam.project_ray_origin(Vector2(sx, sy))
				var dir_r := cam.project_ray_normal(Vector2(sx, sy))
				var q := PhysicsRayQueryParameters3D.create(from, from + dir_r * 260.0)
				q.collide_with_areas = false
				var res := space.intersect_ray(q)
				tot += 1
				if res.is_empty():
					continue
				var col: Object = res["collider"]
				# Soseaua si terenul NU sunt decor: corpurile lor atarna DIRECT de
				# nodul pistei (nume generat, `@StaticBody3D@N`), pe cand fiecare
				# prop isi are corpul sub `DecorManual`. Filtrul pe NUME nu merge —
				# corpurile generate n-au nume vorbitor, si asta a facut prima
				# rulare sa raporteze 98%% acoperire acolo unde erau 13%%.
				var nd: Node = col as Node
				if nd == null:
					continue
				var under_decor := false
				var a: Node = nd
				while a != null:
					if String(a.name) == "DecorManual":
						under_decor = true
						break
					a = a.get_parent()
				if not under_decor:
					continue
				var nm := String(nd.name).to_lower()
				var pn := ""
				var pp: Node = nd.get_parent()
				if pp != null:
					pn = String(pp.name).to_lower()
				cov += 1
				var kk := nm + " < " + pn
				seen[kk] = int(seen.get(kk, 0)) + 1
				var d: float = from.distance_to(res["position"])
				if d < nearest:
					nearest = d
					nearest_name = String((col as Node).name)
		print("frac %.2f  acoperire treime de jos %5.1f%%  cel mai apropiat %.1f m (%s)" % [
			f, float(cov) / float(tot) * 100.0, nearest, nearest_name])
		var ks: Array = seen.keys()
		ks.sort_custom(func(a, b): return seen[a] > seen[b])
		for k in ks.slice(0, 10):
			print("      %5d  %s" % [seen[k], k])
	get_tree().quit()
