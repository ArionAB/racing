extends Node
## RULAJUL LATERAL AL BALOANELOR ANCORATE: la ce distanta de axul benzii sta
## fiecare balon din valea POI C, si intra vreunul in banda.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeBaloane.tscn -- --track=6
##   ... -- --track=6 --sabotaj   (autotest: muta un balon pe axa si cere sa pice)
##
## [b]De ce exista.[/b] Criticul orb a numit „un balon care intersecteaza drumul
## la scara 4x, cu corzile iesind din cadru". Aici se masoara, pentru fiecare
## balon ancorat, rulajul fata de axul benzii si cat de mare e anvelopa — ca sa
## se stie daca e asezat gresit, prea mare, sau amandoua.
##
## [b]CONTRACTUL E VIU (verificat 5 sep 2026).[/b] Intre 4 si 5 sep valea a fost
## umpluta (podea la 10 m) si ~35 de noduri din POI C au fost mutate din editor
## de dezvoltator, deci se punea intrebarea daca sonda mai masoara ceva.
## Masoara: grupul `DecorManual/C) Cornisa Vaii Rosii/Multimea din vale` exista
## in continuare, cu 16 noduri `balon*` la frac 0.264-0.345 si rulaj +18.7 …
## +62.1 m fata de o semilatime de 6 m. Sonda NU e retrasa. (Contrast:
## `tools/probe_balloon.gd` masura contractul de PLATFORMA al cosului care urca
## si ACELA a fost retras, fiindca hazardul a fost reproiectat pe maturare.)
##
## [b]Doua capcane reparate pe 5 sep, amandoua faceau cifrele sa minta.[/b]
##
## (1) CORPURILE `*_col` NU SUNT BALOANE. `WorldProp._build_collision` creeaza
##     pentru fiecare model un `StaticBody3D` numit `<model>_col`, adaugat ca
##     FRATE al modelului cu transform IDENTITATE — deci pozitia lui globala e
##     originea lui `DecorManual`, adica (0,0,0), nu pozitia balonului. Filtrul
##     pe prefixul „balon" le prindea pe toate 16 si tiparea pentru fiecare
##     acelasi rand fals: „frac 0.122, rulaj -63.6 m". Adica jumatate din
##     raportul sondei masura originea scenei. Se sar acum dupa sufix.
## (2) NU EXISTA VERDICT. Sonda tiparea o lista si iesea 0 orice ar fi gasit —
##     „INTRA IN BANDA" era un cuvant intr-un log pe care nu-l citea nimeni.
##     Acum numarul de baloane in banda e verdictul, si cade build-ul.
##
## [b]Ce NU acopera.[/b] Grupul `Baloane departate` (12 noduri `departe*`) e
## silueta de fundal la 100-200 m; nu e in filtru fiindca nu e ancorat de drum.
## Plutirea si ingroparea lor sunt treaba lui `ProbePlutire` / `ProbeBuried`.

## Cate baloane au voie sa intre in banda. Zero: un balon in banda e fie decor
## prost asezat, fie hazard nedeclarat — si hazardul (cosul care matura) e alt
## nod, `Balon ancorat N`, cu alt contract si alta sonda.
const MAX_IN_LANE: int = 0
## Anvelopa GLB e ~4.8 m in diametru la scara 1.
const ENVELOPE_DIAM_M: float = 4.8
## Sabotajul: primul balon gasit e mutat PE AXA benzii, la fractia asta.
const SABOTAGE_FRAC: float = 0.30


func _ready() -> void:
	await get_tree().process_frame
	var only := -1
	var sabotage := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = GameState.resolve_track_index(
				int(arg.trim_prefix("--track=")))
		elif arg == "--sabotaj":
			sabotage = true
	if only < 0:
		push_error("ProbeBaloane: cere --track=N")
		get_tree().quit(1)
		return

	var scene := load(GameState.TRACK_SCENES[only]) as PackedScene
	var t := scene.instantiate() as Track
	get_tree().root.add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame

	var s: TrackSideSampler = t.get("_sampler")
	var n := s.point_count()
	var nodes: Array[Node3D] = []
	_walk(t, nodes)

	print("=== BALOANE ANCORATE FATA DE BANDA — %s%s ==="
		% [GameState.track_label(only), " [SABOTAJ]" if sabotage else ""])
	# GARDA IMPOTRIVA VERDELUI GOL: zero baloane gasite ar iesi „OK" fara sa fi
	# masurat nimic — exact felul de verde care a costat sesiunea asta de mai
	# multe ori (vezi handoff §5.7, „garda existenta, nerulata, nu e garda").
	if nodes.is_empty():
		print("PICAT: niciun nod `balon*` in scena; sonda n-a masurat nimic.")
		print("       Daca baloanele ancorate au fost scoase din pista,")
		print("       RETRAGE sonda cu nota in antet (model: probe_balloon.gd).")
		get_tree().quit(1)
		return

	if sabotage:
		_plant(nodes[0], s, n)

	var in_lane := 0
	for n3 in nodes:
		var g := n3.global_position
		var bi := 0
		var bd := INF
		for i in n:
			var p := s.baked_point(i)
			var d := Vector2(p.x - g.x, p.z - g.z).length_squared()
			if d < bd:
				bd = d
				bi = i
		var p := s.baked_point(bi)
		var sd := s.side_at(bi)
		var off := (g - p).dot(sd)
		var hw := s.half_width_at(bi)
		var frac := float(bi) / float(n)
		var sv: Variant = n3.get("model_scale")
		var scale_v: float = float(sv) if sv != null else 1.0
		var radius := ENVELOPE_DIAM_M * scale_v * 0.5
		var verdict := "ok"
		if absf(off) - radius < hw:
			verdict = "INTRA IN BANDA (rulaj %.1f, semilatime %.1f, raza %.1f)" \
				% [off, hw, radius]
			in_lane += 1
		print("  %-28s frac %.3f  rulaj %+6.1f m  scara %.2f  diametru ~%.1f m  %s"
			% [n3.name, frac, off, scale_v, ENVELOPE_DIAM_M * scale_v, verdict])

	print("")
	print("  %d baloane ancorate masurate, %d in banda (prag %d)"
		% [nodes.size(), in_lane, MAX_IN_LANE])
	if in_lane > MAX_IN_LANE:
		print("VERDICT: PROBLEMA — %d balon(e) in banda." % in_lane)
		get_tree().quit(1)
		return
	print("VERDICT: OK — niciun balon ancorat nu intra in banda.")
	get_tree().quit(0)


## Muta un balon PE AXA benzii — martorul care arata ca sonda poate sa pice.
func _plant(n3: Node3D, s: TrackSideSampler, n: int) -> void:
	var i := int(SABOTAGE_FRAC * float(n)) % n
	var p := s.baked_point(i)
	n3.global_position = p + Vector3.UP * 4.0
	print("  [sabotaj] %s mutat pe axa la frac %.3f, %s"
		% [n3.name, SABOTAGE_FRAC, str(n3.global_position)])


## Nodurile-balon din decorul manual. Corpurile de coliziune generate de
## `WorldProp` poarta acelasi nume cu sufixul `_col` si stau la originea
## parintelui, nu la pozitia modelului — se sar, altfel jumatate din raport e
## originea scenei masurata de 16 ori. Vezi antetul.
func _walk(n: Node, out: Array[Node3D]) -> void:
	for c in n.get_children():
		var nm := String(c.name)
		if nm.begins_with("balon") and not nm.ends_with("_col"):
			var n3 := c as Node3D
			if n3 != null:
				out.append(n3)
		_walk(c, out)
