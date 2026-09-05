extends Node
## E LIBERA BANDA? Plimba gabaritul unei masini pe axul fiecarei benzi si
## raporteaza CE corp solid il atinge, pe nume.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeLaneClear.tscn -- --track=6
##   ... -- --track=6 --sabotaj   (autotest: pune un zid pe axa benzii si cere sa pice)
##
## De ce exista. Pe Cappadocia toate masinile se ingramadeau la frac ~0.80 si
## cursa nu se termina. Cauza: un corp solid pe AXA benzii, in elice. Toate
## corpurile generate erau anonime (`@StaticBody3D@34`), deci a fost nevoie de o
## ora ca sa afli care din 10. Sonda asta raspunde direct, cu numele corpului —
## `_add_mesh_with_collision` le boteaza acum pe toate.
##
## Regula: un corp de SOSEA (carosabil, umeri, tablier, kicker) e legitim sub
## roti si se ignora dupa nume; orice ALTCEVA care intersecteaza cutia caroseriei
## ridicata peste asfalt e un zid in mijlocul drumului.
##
## Sonda are DOUA intrebari, si a doua e cea care a prins blocajul real:
##
##   (a) e ceva solid IN gabaritul masinii, pe axa si pe doua fire laterale;
##   (b) e ceva solid INAINTEA masinii, pe directia de mers, la cotele
##       caroseriei — chiar daca in punctul curent e loc.
##
## (b) exista fiindca pe Cappadocia perdeaua de umeri statea DE-A CURMEZISUL
## drumului: in punctul masurat era aer, iar zidul la 2 m in fata. Cu numai (a),
## sonda iesea verde peste un drum inchis. Vezi memoria `masoara-inainte-nu-langa`.
##
## Limite: se testeaza axa si doua fire laterale la +-1/3 din semilatime, nu
## toata banda. Nu judeca pantele — o rampa cinstita pe care o urci nu apare
## fiindca e in lista de suprafete de rulare.

## Gabaritul masinii (X lateral, Y inaltime, Z lungime) — vezi CarData.
const CAR_SIZE := Vector3(2.2, 1.4, 4.2)
## Cat se ridica centrul cutiei peste asfalt. Jumatate din inaltime plus garda
## la sol: sub atat cutia freaca insusi carosabilul si totul iese "blocat".
const LIFT: float = 1.0
## Pasul pe fractie. 0.005 pe un tur de ~2 km inseamna o proba la ~10 m.
const STEP: float = 0.005
## Corpurile pe care se RULEAZA: contactul cu ele e normal, nu blocaj.
## Cat de departe in fata se intreaba. 6 m: mai mult decat lungimea masinii,
## destul cat un zid sa fie vazut inainte sa fie atins, si destul de putin cat
## un viraj normal sa nu iasa raportat ca obstacol.
const AHEAD_M: float = 6.0
## Sabotajul: un stalp solid PE AXA benzii, la fractia asta. Nu e decor — e
## martorul care arata ca garda chiar poate sa pice. O linie de baza care nu
## poate fi depasita nu masoara nimic, iar bazele de aici au fost coborate de
## doua ori (Cappadocia 15 -> 11 pe 5 sep 2026); fiecare coborare cere dovada
## ca pragul nou tot musca. Handoff §6: „un horn pe axa duce Cappadocia la 41,
## verdict REGRESIE, cod de iesire 1" — asta e mecanismul, scris in sonda.
const SABOTAGE_FRAC: float = 0.55
const SABOTAGE_SIZE := Vector3(6.0, 12.0, 6.0)

const DRIVABLE := [
	# `ChannelDeckSides` e acelasi tablier ca `RoadOverpassDeck`, redenumit pe
	# feat/capp-poi-b fara ca lista asta sa fie actualizata. Se tin AMANDOUA:
	# lista e citita si de pistele mai vechi, iar un nume scos de aici nu
	# raporteaza un blocaj — raporteaza SOSEAUA ca obstacol.
	"RoadTop", "RoadSides", "RoadOverpassDeck", "ChannelDeckSides", "Shoulders",
	# `TunnelShell` e parapetul de banda (`_build_branch_rails`), redenumit tot
	# pe feat/capp-poi-b. Aceeasi poveste ca `ChannelDeckSides` de mai sus.
	"BranchDeck", "BranchDirt", "BranchSand", "BranchRails", "TunnelShell",
	"Ramp", "ChannelKicker", "FlyoffRamp", "HummockBody",
	"IceSheet",
	# TERENUL. E podeaua de sub tot, deci contactul cu el nu e blocaj — dar
	# aparea la aproape fiecare proba si de aceea sonda iesea rosie pe TOATE
	# pistele: 393 din 414 raportari pe Alpi erau el.
	#
	# Motivul e o decizie deliberata din `track.gd`: forma lui e un trimesh cu
	# `backface_collision = true`, fiindca winding-ul mesh-ului de teren e
	# arbitrar. Un trimesh concav dublu-fatetat raporteaza suprapunere din
	# AMANDOUA partile, deci cutia care sta CALARE pe suprafata se suprapune cu
	# el chiar si cand terenul e exact podeaua pe care calci. O raza trasa de
	# sus in jos nu-l loveste deloc (porneste dinauntru) — confirmarea ca nu e
	# un deal peste drum.
	"TerrainBody",
	# Suprafetele de rulare ale hazardelor: se CALCA pe ele.
	#   `WaterFloor` / `Plates` — campul de gheata de pe Baikal
	#     (`ice_field_hazard.gd`): placile pe care treci si apa de sub ele.
	#   `ServiceRamp` / `Deck` / `Span` / `Gate` / `Load` / `Beam` — travee si
	#     rampe de pe Chongqing (`rotating_span_hazard.gd`). Lista asta era deja
	#     scrisa, corect, in `tools/probe_cq_drive.gd`; sonda de fata n-o stia,
	#     si de aceea raporta 205 blocaje pe o pista care se conduce.
	"WaterFloor", "Plates",
	"ServiceRamp", "Deck", "Span", "Gate", "Load", "Beam",
]


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
		push_error("ProbeLaneClear: cere --track=N")
		get_tree().quit(1)
		return

	var scene := load(GameState.TRACK_SCENES[only]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	print("=== %s%s ===" % [GameState.track_label(only),
		" [SABOTAJ]" if sabotage else ""])
	if sabotage:
		_plant_wall(track)
		await get_tree().physics_frame
	var space := track.get_world_3d().direct_space_state
	var hits := 0
	for ri in track.routes.size():
		var r: TrackRoute = track.routes[ri]
		hits += _sweep(space, track, r)
	print("")
	# LINIE DE BAZA PER PISTA, nu prag zero.
	#
	# Sonda nu iese pe zero pe nicio pista si nu are cum: raporteaza si contacte
	# legitime (parapete la care treci razant, hazarde care CHIAR ingusteaza
	# banda, piese de decor lipite de margine). Un prag zero ar fi rosu mereu,
	# deci ignorat in doua saptamani — exact soarta pe care a avut-o pana acum.
	#
	# Ce conteaza e CRESTEREA: daca o pista raporta 21 si acum raporteaza 60,
	# ceva s-a mutat in banda. Cifrele de mai jos sunt masurate pe main la
	# 2 sep 2026, dupa ce suprafetele de rulare au fost scoase din raportare.
	# Cand cobori una legitim, actualizeaz-o AICI, in acelasi commit.
	var base: int = BASELINE.get(GameState.track_label(only), -1)
	if base < 0:
		print("VERDICT: %d probe blocate (pista fara linie de baza)" % hits)
		get_tree().quit(0)
		return
	if hits > base:
		print("VERDICT: REGRESIE — %d probe blocate, linia de baza e %d"
			% [hits, base])
		get_tree().quit(1)
		return
	if hits < base:
		print("VERDICT: OK — %d probe blocate, sub linia de baza (%d)."
			% [hits, base])
		print("         Coboara linia de baza in probe_lane_clear.gd.")
	else:
		print("VERDICT: OK — %d probe blocate, exact linia de baza" % hits)
	get_tree().quit(0)


## Cate raportari are fiecare pista pe main, dupa ce suprafetele de rulare au
## fost scoase. NU sunt zerouri si nu trebuie sa fie: o parte din ele sunt
## contacte legitime (parapete razante, hazarde care ingusteaza banda dinadins).
## Rostul lor e sa prinda CRESTEREA. Masurat 2 sep 2026.
## Cheia e eticheta intreaga (`GameState.track_label`), cu numarul scenei in ea:
## numele scurt s-ar putea repeta, numarul scenei nu.
##
## [b]Cappadocia: 15 -> 11 pe 5 sep 2026.[/b] Hornul crapat din POI D a fost
## SCOS din scena la turul 2 al dezvoltatorului (handoff §4.7), iar celelalte
## corpuri din banda au fost mutate in aceeasi sesiune. Masurat de 3 ori pe
## 5 sep, identic: **9** raportari — 6 la frac 0.030 (teancurile de oale din
## POI A, gimmick cu fanta de 4 m: `obstacol-pe-drum-poate-fi-gimmick`), 1 la
## 0.030 pe testul INAINTE si 2 la 0.970 pe buza `FlyoffRamp`. Baza e pusa la
## 11, adica 9 + marja 2: sub 9 nu se poate coborî fara sa scoti gimmickul, iar
## marja lasa loc unei singure piese noi pe margine fara alarma falsa.
## Verificat prin sabotaj (`--sabotaj`) pe 5 sep 2026: un stalp de 6x12x6 pe
## axa la frac 0.55 duce cifra de la 9 la 12 (trei fire laterale il vad, pe
## nume), verdict REGRESIE, cod de iesire 1.
const BASELINE := {
	"Dunele (Track01)": 30,
	"Okinawa manual (Track08)": 18,
	"Alpii (Track09)": 21,
	"Baikal (Track10)": 70,
	"Stromboli (Track11)": 190,
	"Chongqing (Track12)": 146,
	"Cappadocia (Track13)": 11,
}


## Un stalp solid FIX PE AXA benzii principale — clasa de defect vanata:
## un corp de decor (layer implicit, nu suprafata de rulare) plantat in drum.
## Numele iese in raportare, deci se vede in log ca sonda l-a gasit pe nume.
func _plant_wall(track: Track) -> void:
	var r: TrackRoute = track.routes[0]
	var n := r.baked.size()
	var i := int(SABOTAGE_FRAC * float(n)) % n
	var p: Vector3 = r.baked[i]
	var body := StaticBody3D.new()
	body.name = "STALP_DE_SABOTAJ"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = SABOTAGE_SIZE
	shape.shape = box
	body.add_child(shape)
	get_tree().root.add_child(body)
	body.global_position = p + Vector3.UP * (SABOTAGE_SIZE.y * 0.5)
	print("  [sabotaj] stalp %s la frac %.3f, %s"
		% [str(SABOTAGE_SIZE), SABOTAGE_FRAC, str(body.global_position)])


func _sweep(space: PhysicsDirectSpaceState3D, track: Track,
		r: TrackRoute) -> int:
	print("")
	print("  [%s]" % r.label)
	var n := r.baked.size()
	var shape := BoxShape3D.new()
	shape.size = CAR_SIZE
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collide_with_areas = false
	var bad := 0
	var f := 0.0
	while f < 1.0:
		var i := int(f * float(n)) % n
		var p: Vector3 = r.baked[i]
		var fwd := (r.baked[(i + 1) % n] - p)
		if fwd.length() < 0.001:
			f += STEP
			continue
		fwd = fwd.normalized()
		var side := fwd.cross(Vector3.UP).normalized()
		var half: float = track.width_at_index(i)
		for lat in [0.0, -half / 3.0, half / 3.0]:
			var basis := Basis(side, Vector3.UP, -fwd)
			q.transform = Transform3D(basis,
				p + Vector3.UP * LIFT + side * lat)
			var res := space.intersect_shape(q, 8)
			for hit in res:
				var body := hit.get("collider") as Node
				if body == null:
					continue
				var nm := String(body.name)
				# Lista de suprafete de rulare scuza numele, NU orice forma cu
				# numele ala. `Shoulders` e chiar corpul care a blocat elicea
				# (o perdea de 38 m atarnata peste gura stancii): daca l-am
				# scuza pe nume, garda ar tace exact la defectul pentru care a
				# fost scrisa. Deci se scuza doar cat timp sta JOS — o suprafata
				# pe care calci, nu un zid. Cutia e ridicata cu LIFT, deci orice
				# atinge peste ~1 m fata de asfalt nu mai e podea.
				if DRIVABLE.has(nm):
					var top: float = -1e9
					var aabb_ok := false
					for ch in body.get_children():
						if ch is CollisionShape3D and ch.shape != null:
							var g: Vector3 = (ch as Node3D).global_position
							top = maxf(top, g.y)
							aabb_ok = true
					if not aabb_ok or top <= p.y + 1.0:
						continue
					nm += " (ridicat la +%.1f m fata de asfalt)" % (top - p.y)
				print("    %.3f lat=%+.1f | %s" % [f, lat, nm])
				bad += 1
		# (b) coridorul din FATA, pe axa. Nu se filtreaza dupa lista de
		# suprafete de rulare: un carosabil perpendicular pe directia de mers
		# e tot un zid, oricum l-ar chema.
		for h in [0.4, 1.0, 1.6]:
			var origin: Vector3 = p + Vector3.UP * h
			var rq := PhysicsRayQueryParameters3D.create(
				origin, origin + fwd * AHEAD_M)
			var hit := space.intersect_ray(rq)
			if hit.is_empty():
				continue
			var body := hit.get("collider") as Node
			if body == null:
				continue
			var d: float = (hit["position"] as Vector3).distance_to(origin)
			print("    %.3f INAINTE h=%.1f | %s la %.2f m"
				% [f, h, String(body.name), d])
			bad += 1
		f += STEP
	return bad
