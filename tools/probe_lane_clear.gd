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
	# Tabliera lui LiftBridgeHazard (`_span.name = "LiftSpan"`, `lift_bridge_
	# hazard.gd`): pod mobil (Okinawa) SAU podet fix (`static_deck`, Chasm).
	# Numele exact nu se potrivea cu "Span" de mai sus (`has()` e potrivire
	# EXACTA, nu substring) — pe Okinawa n-a fost prins pana acum fiindca
	# traveea sta jos doar cateva secunde din ciclu, iar `static_deck` (nou,
	# Fiordland) o tine jos permanent, deci orice sonda statica o prinde
	# de fiecare data. Fara asta: 17 blocaje false la fiecare esantion pe
	# podetul Chasm (0.405-0.425), tabliera insasi raportata ca obstacol.
	"LiftSpan",
	# Panele de coliziune ale rampelor de la cele doua capete ale podului
	# (`_build_ramps`, `RampNear`/`RampFar` — inainte "Ramp", dar Godot nu
	# uniformizeaza in "Ramp2" un nume dat INAINTE de add_child() cand exista
	# deja un frate cu acelasi nume, revine tacut la formatul automat
	# nenumit). Fara ele: rampa e citita ca zid chiar acolo unde masina
	# trebuie sa urce pe tabliera.
	"RampNear", "RampFar",
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
## [b]Serengeti: linie de baza pusa la integrare, 8 sep 2026.[/b] Masurat de
## 3 ori pe starea de dupa merge-ul celor 8 POI-uri, identic: **7** raportari,
## toate cu numele lor in log si toate gimmick-uri intentionate —
## 1 la frac 0.145 (`Hipopotam2`, spinarea care iese din vad, brief §4),
## 3 la 0.765 (elefantul care traverseaza fundul craterului, `G_Elefant`:
## corpul lui e AnimatableBody3D creat la runtime, deci apare cu nume generat)
## si 3 la 0.870 (`FlyoffRamp`, kickerul din POI H).
## Baza e 9, adica 7 + marja 2: sub 7 nu se poate coborî fara sa scoti un
## gimmick, iar marja lasa loc unei singure piese noi pe margine fara alarma
## falsa. Pana acum pista NU avea linie de baza, deci sonda nu putea distinge
## un hazard voit de un corp ratacit in banda (memoria `garda-existenta-nerulata`).
## Verificat prin sabotaj (`--sabotaj`) in acelasi commit.
## [b]Machu Picchu: linie de baza pusa pe fundatie, 16 sep 2026.[/b] Masurat de
## 3 ori pe starea finala a fundatiei, identic: **18** raportari. Toate sunt
## atribuite unei piese intentionate:
##   - 11 la frac 0.940/0.945, sub `Hazarduri/BarnePodIncas` (podul basculant):
##     cele doua buze (`@StaticBody3D@34`, `@StaticBody3D@37`) si tablierul
##     `LiftSpan`. Sunt gimmickul insusi, raportat cu podul JOS.
##   - 7 la frac 0.500/0.505: [b]LAMELE[/b] (`Hazarduri/Lama1..4`, corpuri
##     `SlidingHazard`), nu podul de franghie. Prima redactare le atribuia
##     gresit lui `PodFranghie`; podul e la frac 0.549-0.565 si nu apare deloc
##     in raportare. Atribuirea gresita a fost prinsa de revizia adversariala
##     (memoria `justificarea-din-comentariu-se-verifica`) — cifra era buna,
##     explicatia nu, si exact explicatia e ce citeste urmatorul.
## [b]De ce 18 si nu 14:[/b] prima masuratoare s-a facut cand lamele aveau
## 53 cm (scala Blender neaplicata, vezi commit-ul de fix). Cu lamele la
## marimea reala de 1.66 m, sondele de la h=1.0 si h=1.6 le vad si ele — deci
## cresterea de la 14 la 18 e [b]corectitudine castigata, nu regresie[/b]:
## inainte garda nu vedea un obstacol care oricum nu exista mecanic.
## Baza e 20, adica 18 + marja 2, conventia de mai sus.
## [b]Atentie la cifra lead-ului: 15.[/b] A fost masurata pe main INAINTE de
## fundatie; alt set de corpuri, nu o regresie fata de ea.
## Verificat prin sabotaj (`--sabotaj`): stalpul de 6x12x6 pe axa la frac 0.55
## duce cifra peste baza, verdict REGRESIE, cod de iesire 1.
const BASELINE := {
	"Dunele (Track01)": 30,
	"Okinawa manual (Track08)": 18,
	"Alpii (Track09)": 21,
	"Baikal (Track10)": 70,
	"Stromboli (Track11)": 190,
	"Chongqing (Track12)": 146,
	"Cappadocia (Track13)": 11,
	"Serengeti (Track14)": 9,
	"Machu Picchu (Track15)": 20,
	# Fiordland (Track16), masurat dupa fundatia de decor (DecorManual +
	# 8 zone, orizont, bus_model, avalansa) — 8 raportari, toate atribuite
	# geometriei INTENTIONATE a pistei: 3x TunnelPortal (tubul Homer,
	# frac 0.700), 3x ChannelKicker (kickerul Bowen, frac 0.850-0.855) si
	# 2x RoadTop pe scurtatura ("drumul vechi din padure", frac 0.895-0.900,
	# treapta scurtaturii). Niciuna dintre piesele plasate in acest val
	# (stirling_ledge, torrent_chute, chasm_bridge_rail,
	# traffic_light_pole) nu apare in raportare. Baza = 8, CIFRA MASURATA,
	# fara marja: o marja ascunde exact prima piesa pusa pe banda (memoria
	# garda-fara-linie-de-baza-iese-zero). Sabotaj verificat: 9 > 8 = REGRESIE.
	#
	# RIDICATA la 11 (podetul Chasm, TrackChannel + LiftBridgeHazard.
	# static_deck, frac ~0.406-0.424): +3 raportari noi, toate pe verificarea
	# INAINTE (coridorul din fata, care NU se filtreaza dupa DRIVABLE — "un
	# carosabil perpendicular pe directia de mers e tot un zid, oricum l-ar
	# chema", comentariul de mai jos), niciuna pe lateral (`lat=`), care ar
	# fi insemnat coliziune REALA in banda: RampNear la 0.400 (4.42 m),
	# RampFar la 0.420 (3.33 m si 2.99 m, doua inaltimi de raycast pe aceeasi
	# rampa). Exact clasa deja acceptata la Okinawa (Track08, baza 18):
	# rampele podurilor sunt geometrie ascendenta intentionata, nu zid — se
	# vad in fata razei fiindca sunt sosea, nu fiindca blocheaza. Masurat de
	# 3 ori, identic la bit (fara fizica implicata, doar geometrie statica).
	# Sabotaj (stalp pe banda, --sabotaj): 14 > 11 = REGRESIE, verificat.
	#
	# RIDICATA din nou la 13 (runda 3, podetul Chasm remutat pe portiunea
	# DREAPTA a soselei — frac 0.4007, sageata 0,018 m — ca sa nu mai poarte
	# masinile in banda in curba, cauza reala a repunerilor BridgeFall
	# gasita cu AI_UNSTICK_TRACE=1). Golul e acum mai scurt (19 m fata de
	# 37 m), deci rampele cad pe alte fractii si RampFar ajunge sa fie
	# vizibil la INCA o inaltime de raycast (0.4/1.0/1.6 in loc de 0.4/1.0):
	# +2 fata de runda precedenta, tot pe INAINTE, tot RampNear/RampFar, zero
	# pe lateral. Masurat de 3 ori, identic la bit. Sabotaj: 16 > 13 =
	# REGRESIE, verificat.
	"Fiordland (Track16)": 13,
	# Jodhpur (Track17), armat la fundatia gauntlet-ului de POI (ramura
	# jodhpur/poi-fundatie): 28 raportari, masurat de 5 ori la rand pe stari
	# succesive ale fundatiei (curat, DecorManual + 8 zone goale, CityFill),
	# identic de fiecare data. TOATE pe `AlleyGatePostA/B` (14 + 14) — stalpii
	# portii de 4 m din gura ulicioarei (`AlleyGate`, half_opening 2,0 pe banda
	# de 3,2): ingustarea e gimmick-ul scurtaturii, deci contact legitim, ca
	# oalele de pe Cappadocia. Nimic pe bucla principala. Baza = cifra
	# masurata, fara marja (vezi Fiordland mai sus): prima piesa pusa pe banda
	# de un constructor de POI trebuie sa pice garda. Sabotaj verificat.
	# +3 la integrarea reliefului (jodhpur/poi-integrare): `ChannelKicker`
	# pe INAINTE la 0.875-0.880 — rampa sariturii Devkund (G2), obstacolul
	# intentionat pe care se sare, ca RampNear/RampFar la Fiordland.
	"Jodhpur (Track17)": 31,
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
