extends Node
## CE VEDE CAMERA DE JOC, pe NUME DE NOD — nu pe procent de rosu.
##
## Sonda asta exista din cauza rundei 2 de pe POI C. Atunci s-a construit o
## faleza reala (`CliffFace`), sondele au spus OK, si criticul orb a raspuns
## „tot nu exista nicio fata de stanca in cadru". Amandoua erau adevarate:
## panza CHIAR se construia, dar din camera de urmarire nu ajungea niciun pixel
## din ea pe ecran. Metrica de atunci — „rosu in cadru de la 1% la 15-22%" —
## masura `valley_tint`-ul de pe versantul din fund, nu peretele; de-aia putea
## sa iasa verde cu golul vizual neatins. Exact
## `efecte-invizibile-nu-se-numara`, in costum nou.
##
## Deci: trage raze prin frustumul camerei REALE (aceleasi constante ca
## `--gamecam` din snapshot.gd) si raporteaza ce nod e lovit de fiecare,
## impreuna cu procentul de cadru pe care il ocupa. Un procent de CULOARE nu
## poate deosebi un perete cu strate de un deal revopsit. Un nume de nod poate.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"
const COLS: int = 48
const ROWS: int = 27

func _ready() -> void:
	var fracs: Array[float] = [0.20, 0.28, 0.36]
	for a in OS.get_cmdline_user_args():
		if (a as String).begins_with("--frac="):
			fracs = [float((a as String).substr(7))]
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	for f in fracs:
		_shoot(t, f)
	t.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)


func _shoot(t: Track, frac: float) -> void:
	var route := t.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var idx := int(frac * float(n)) % n
	var focus: Vector3 = pts[idx]
	var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
	var dir := (ahead - focus).normalized()
	# Aceeasi camera ca `--gamecam`: constantele lui ChaseCamera, nu MEASURE_*.
	var eye := focus - dir * ChaseCamera.DEFAULT_DISTANCE \
		+ Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
	var target := focus + dir * ChaseCamera.LOOK_AHEAD \
		+ Vector3.UP * ChaseCamera.LOOK_HEIGHT
	var fwd := (target - eye).normalized()
	var right := fwd.cross(Vector3.UP).normalized()
	var up := right.cross(fwd).normalized()
	var aspect := 16.0 / 9.0
	var half_v := tan(deg_to_rad(ChaseCamera.BASE_FOV) * 0.5)
	var half_h := half_v * aspect

	var space := get_viewport().world_3d.direct_space_state
	var tally: Dictionary = {}
	var total := 0
	# Pe ce inaltime de ecran apare faleza: ca sa se stie daca e o dunga la
	# orizont sau chiar peretele de langa banda.
	var rock_rows: Array[int] = []
	var rock_cols: Array[int] = []
	for r in ROWS:
		var sv := (float(r) + 0.5) / float(ROWS) * 2.0 - 1.0
		for c in COLS:
			var sh := (float(c) + 0.5) / float(COLS) * 2.0 - 1.0
			var rd := (fwd + right * (sh * half_h) - up * (sv * half_v)).normalized()
			var q := PhysicsRayQueryParameters3D.create(eye, eye + rd * 400.0)
			var hit := space.intersect_ray(q)
			total += 1
			var nm := "CER"
			if not hit.is_empty():
				nm = _label(hit["collider"] as Node)
			tally[nm] = int(tally.get(nm, 0)) + 1
			if nm.begins_with("FALEZA"):
				rock_rows.append(r)
				rock_cols.append(c)

	print("\n=== frac %.2f — ce vede camera de JOC (%d raze) ===" % [frac, total])
	var keys := tally.keys()
	keys.sort_custom(func(a, b): return int(tally[a]) > int(tally[b]))
	for k in keys:
		var pct := 100.0 * float(tally[k]) / float(total)
		if pct >= 0.4:
			print("  %-28s %5.1f%%" % [k, pct])
	var rock_pct := 100.0 * float(rock_rows.size()) / float(total)
	if rock_rows.is_empty():
		print("  >>> FALEZA: 0.0%% din cadru  [PICAT — peretele nu se vede]")
	else:
		var rmin: int = rock_rows.min()
		var rmax: int = rock_rows.max()
		var cmin: int = rock_cols.min()
		var cmax: int = rock_cols.max()
		# Randul 0 e SUS. Convertit in „inaltime de ecran" ca sa se citeasca uman.
		print("  >>> FALEZA: %.1f%% din cadru, randuri %d-%d din %d (0=sus), coloane %d-%d din %d"
			% [rock_pct, rmin, rmax, ROWS, cmin, cmax, COLS])


## Numele „de compozitie" al unui corp: ce ar numi un om care se uita la cadru.
func _label(n: Node) -> String:
	var cur := n
	while cur != null:
		var nm := String(cur.name)
		if nm.begins_with("Faleza") or nm.begins_with("Polita"):
			return "FALEZA (" + nm + ")"
		if nm == "TerrainBody" or nm.begins_with("Terrain"):
			return "teren (camp de inaltime)"
		if nm.begins_with("Road") or nm.contains("Asfalt") or nm.contains("Banda"):
			return "sosea"
		cur = cur.get_parent()
	return String(n.name)
