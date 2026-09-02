extends Node
## CE VEDE CAMERA? Plimba CAMERA pe traseu si raporteaza unde ea sta INAUNTRUL
## unui corp solid — adica unde jucatorului ii apare un cadru de o singura
## culoare, plat, in loc de lume.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCameraSolid.tscn -- --track=6
##   ... -- --track=6 --sabotaj      (autotest: pune un zid peste traseu si cere sa pice)
##   ... -- --track=6 --verbose      (fiecare punct, nu doar cele picate)
##
## [b]De ce exista.[/b] Primul tur condus de om pe Cappadocia (2 sep 2026) a
## avut SASE cadre dintr-un tur de 94 s in care ecranul era o singura culoare
## plata: 1:03.5, 1:04.2, 1:04.7, 1:05.2, 1:10.5, 1:22.5. Alea nu sunt „arta
## slaba", e camera din interiorul geometriei. Si NICIO sonda nu le-a prins,
## fiindca toate garzile de pana acum masoara volumul MASINII:
##
##   ProbeLaneClear  — cutia caroseriei pe axul benzii
##   ProbeBuried     — punctul de asfalt, la inaltimea caroseriei
##   ProbePlutire    — originea prop-urilor fata de teren
##   ProbeLayout / ProbeHelix — panta si geometria traseului
##
## Camera nu sta insa in banda: sta 12,5 m in SPATE si 10 m SUS (6,5 m in
## presetul de cavern). E un al doilea corp, care se plimba pe alt culoar decat
## masina — un culoar pe care nimeni nu-l masura. O sala cu tavan la 16 m prin
## care masina trece fara sa atinga nimic poate avea camera plantata in bolta;
## un perete lateral la 8 m de ax e liber pentru masina si e fix in ochiul
## camerei la iesirea dintr-un viraj.
##
## [b]De ce nu ajunge `_unclip`.[/b] [ChaseCamera] chiar impinge camera afara
## din pereti — dar numai din corpurile de pe `Track.CAMERA_BLOCKER_LAYER`, si
## acolo intra doar terenul, falezele si prop-urile marcate explicit cu
## `metadata/camera_blocker`. Decorul obisnuit (`world_prop._build_collision`)
## primeste corp fizic pe layerul implicit: opreste MASINA, e invizibil pentru
## camera. Deci un perete de sala prin care masina nu poate trece e un perete
## prin care camera trece fara sa clipeasca. Sonda masoara starea FINALA (dupa
## `_unclip`), deci nu presupune de ce e camera acolo — doar constata ca e.
##
## [b]Ce masoara, in ordine.[/b]
##   (a) CAMERA IN SOLID — `intersect_point` pe pozitia camerei, pe TOATE
##       layerele. Testul primar, cel care raspunde exact la „ecran de o
##       culoare". Se foloseste `intersect_point`, nu raze: o raza pornita
##       dintr-un hull convex nu raporteaza nimic in Godot (vezi antetul lui
##       probe_buried.gd, unde aceeasi capcana a ascuns 150 de puncte).
##   (b) CAMERA IN SPATELE UNUI PERETE — segmentul masina→camera taiat de un
##       corp solid. Nu e o culoare plata, dar e la fel de rau: masina dispare
##       in perete. `_unclip` rezolva cazul asta DOAR pe layerul lui, deci aici
##       se vede exact ce a scapat.
##   (c) PERETE LIPIT DE CAMERA — camera nu e in solid, dar un corp e la mai
##       putin de `NEAR_M` de ea: la 20 cm de un zid cadrul e tot o culoare
##       plata, chiar daca punctul central e tehnic in aer.
##
## Verdictul e (a) + (b); (c) se raporteaza si NU pica, fiindca pe o cornisa
## stramta sau sub o arcada e legitim.
##
## [b]Cum e verificata.[/b] `--sabotaj` ridica un bloc de 30 m peste traseu, la
## inaltimea camerei, si cere sondei sa-l gaseasca: o garda care nu poate fi
## facuta sa pice nu masoara nimic. Vezi verdictul de sabotaj de la final.

## Pasul pe fractie. 0.002 pe un tur de ~2 km = o proba la ~4 m. Camera merge
## cu ~30 m/s, deci un cadru de 1/60 s inseamna ~0.5 m: pasul asta prinde orice
## incident mai lung de ~0.15 s, adica tot ce se vede la volan.
const STEP: float = 0.002
## Cat de aproape de un perete inseamna „cadru plat" chiar fara sa fii inauntru.
const NEAR_M: float = 0.5
## Toate layerele: intrebarea e ce se VEDE, nu cine opreste masina.
const ALL_LAYERS: int = 0xFFFFFFFF
const MAX_HITS: int = 16
## Sabotajul: un bloc peste traseu, la fractia asta.
const SABOTAGE_FRAC: float = 0.30
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"

var _track: Track
var _car: Car
var _cam: ChaseCamera
var _verbose: bool = false
var _sabotage: bool = false


func _ready() -> void:
	# Un cadru INAINTE de orice `add_child`: la `_ready`-ul propriu, `root` e
	# inca „busy setting up children", iar adaugarea pistei e refuzata tacut —
	# `Track._ready` nu mai ruleaza, `routes` ramane goala, si sonda ar matura
	# zero puncte iesind verde. (Vezi si garda de mai jos, care prinde cazul
	# chiar daca asta se strica din nou.)
	await get_tree().process_frame
	var only := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = GameState.resolve_track_index(
				int(arg.trim_prefix("--track=")))
		elif arg == "--verbose":
			_verbose = true
		elif arg == "--sabotaj":
			_sabotage = true
	if only < 0:
		push_error("ProbeCameraSolid: cere --track=N")
		get_tree().quit(1)
		return

	# Sliderele jucatorului pe implicit: sonda masoara LUMEA, iar fisierul de
	# setari al dezvoltatorului n-are ce cauta intr-o garda de CI.
	GameState.cam_distance_scale = 1.0
	GameState.cam_height_scale = 1.0
	GameState.cam_fov_scale = 1.0
	GameState.cam_follow_scale = 1.0

	var scene := load(GameState.TRACK_SCENES[only]) as PackedScene
	_track = scene.instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame

	print("=== CAMERA IN SOLID — %s%s ==="
		% [GameState.track_label(only), " [SABOTAJ]" if _sabotage else ""])
	if _sabotage:
		_plant_wall()
		await get_tree().physics_frame

	_build_rig()
	await get_tree().physics_frame

	# GARDA IMPOTRIVA VERDELUI GOL. Fara ea, o lista de rute goala ar face
	# maturarea sa nu ruleze deloc si sonda ar iesi „OK" fara sa fi masurat
	# nimic — exact felul de verde care a costat sesiunea asta de opt ori.
	if _track.routes.is_empty():
		print("PICAT: pista n-are nicio ruta coapta; sonda n-a masurat nimic.")
		get_tree().quit(1)
		return
	var total_pts := 0
	for r0: TrackRoute in _track.routes:
		total_pts += r0.baked.size()
	print("  %d rute, %d puncte coapte in total"
		% [_track.routes.size(), total_pts])

	var incidents := await _sweep()
	print("")
	if _sabotage:
		# AUTOTESTUL. Sonda trebuie sa GASEASCA zidul plantat. Daca trece verde
		# cu un bloc de 30 m peste traseu, nu masoara nimic si orice verde
		# de-al ei, pe orice pista, e fara valoare.
		var found := false
		for inc in incidents:
			if String(inc["names"]).find("ZID_DE_SABOTAJ") >= 0:
				found = true
		if found:
			print("VERDICT SABOTAJ: OK — sonda a gasit zidul plantat la frac %.3f."
				% SABOTAGE_FRAC)
			print("                 Garda poate sa pice, deci verdele ei inseamna ceva.")
			get_tree().quit(0)
		else:
			print("VERDICT SABOTAJ: PICAT — zidul de 30 m de peste traseu N-A FOST GASIT.")
			print("                 Sonda e oarba; nu te baza pe niciun verde de-al ei.")
			get_tree().quit(1)
		return
	# LINIE DE BAZA PER PISTA, nu prag zero — aceeasi decizie ca la
	# ProbeLaneClear, si din acelasi motiv. Sonda NU iese pe zero pe majoritatea
	# pistelor si nici n-ar trebui: rampele si kickerele au prin constructie o
	# buza pe langa care camera trece razant o zecime de secunda, si asta e
	# feeling de saritura, nu defect. Un prag zero ar fi rosu mereu, deci ar fi
	# ignorat in doua saptamani.
	#
	# Ce conteaza e CRESTEREA. Cifrele de mai jos sunt masurate pe main la
	# 2 sep 2026. Cand cobori una legitim, actualizeaz-o AICI, in acelasi commit.
	var base: int = BASELINE.get(GameState.track_label(only), -1)
	var n_inc := incidents.size()
	if base < 0:
		print("VERDICT: %d incidente (pista fara linie de baza)" % n_inc)
		get_tree().quit(0)
		return
	if n_inc > base:
		print("VERDICT: REGRESIE — %d incidente, linia de baza e %d."
			% [n_inc, base])
		print("         Camera intra in geometrie undeva unde nu intra inainte.")
		get_tree().quit(1)
		return
	if n_inc < base:
		print("VERDICT: OK — %d incidente, sub linia de baza (%d)." % [n_inc, base])
		print("         Coboara linia de baza in probe_camera_solid.gd.")
	else:
		print("VERDICT: OK — %d incidente, exact linia de baza" % n_inc)
	get_tree().quit(0)


## Cate incidente are fiecare pista pe main. NU sunt zerouri si nu trebuie sa
## fie: aproape toate raportarile ramase sunt buza unei rampe sau a unui kicker
## prin dreptul careia camera trece o zecime de secunda la saritura — geometrie
## intentionata, nu perete. Rostul lor e sa prinda CRESTEREA.
##
## Chongqing e singura pe zero, si nu din intamplare: acolo blocul prin al carui
## parter trece soseaua e marcat cu `metadata/camera_blocker`, deci `_unclip` il
## vede. E dovada ca zero SE POATE atinge cand geometria prin care se conduce e
## declarata camerei.
##
## Masurat 2 sep 2026, dupa zonele de cavern pe interval de fractie.
## Cheia e eticheta intreaga (`GameState.track_label`), cu numarul scenei in ea.
const BASELINE := {
	"Dunele (Track01)": 3,
	"Okinawa manual (Track08)": 4,
	"Alpii (Track09)": 3,
	"Baikal (Track10)": 2,
	"Stromboli (Track11)": 2,
	"Chongqing (Track12)": 0,
	"Cappadocia (Track13)": 1,
}


## Rig-ul: masina reala + `ChaseCamera` reala. Formula camerei NU se
## reimplementeaza aici — daca s-ar reimplementa, sonda ar masura o camera care
## nu exista in joc, si primul reglaj din `chase_camera.gd` ar face-o sa minta.
func _build_rig() -> void:
	# Sub `root`, nu sub `Track`: pista isi genereaza copiii in `_ready`, iar un
	# `add_child` in mijlocul acelei generari e refuzat („parent is busy") si
	# lasa rig-ul in afara lumii — atunci `get_world_3d()` intoarce null si
	# sonda moare tacut la prima interogare de fizica. Lumea e aceeasi.
	_car = (load(CAR_SCENE) as PackedScene).instantiate() as Car
	get_tree().root.add_child(_car)
	_car.apply_data(GameState.CAR_DATA[0])
	_car.is_player = true
	_car.freeze = true
	_cam = ChaseCamera.new()
	get_tree().root.add_child(_cam)
	_cam.target = _car
	_cam.apply_settings_for(ChaseCamera.REFERENCE_LENGTH)


## Un bloc opac peste traseu, la inaltimea camerei — martorul care arata ca
## sonda chiar poate sa pice. Sta pe layerul IMPLICIT, nu pe cel de camera:
## exact ca decorul din `world_prop`, adica exact clasa de defect vanata.
func _plant_wall() -> void:
	var r: TrackRoute = _track.routes[0]
	var n := r.baked.size()
	var i := int(SABOTAGE_FRAC * float(n)) % n
	var p: Vector3 = r.baked[i]
	var body := StaticBody3D.new()
	body.name = "ZID_DE_SABOTAJ"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30.0, 30.0, 30.0)
	shape.shape = box
	body.add_child(shape)
	get_tree().root.add_child(body)
	body.global_position = p + Vector3.UP * 8.0
	print("  [sabotaj] bloc 30x30x30 la frac %.3f, %s"
		% [SABOTAGE_FRAC, str(body.global_position)])


## Cate cadre de fizica se asteapta dupa fiecare mutare, ca zona de camera sa-si
## termine tranzitia.
##
## [b]Nu e o marja de siguranta, e o cerinta.[/b] `CameraZone` urca presetul
## liniar pe `blend_time` (0.5 s = 30 de cadre la 60 Hz), iar `snap_behind`
## aseaza camera pe `height`, adica pe cota de AFARA. Cu un singur cadru pe
## proba, sonda ar masura mereu camera de suprafata si ar raporta ca „intra in
## tavan" chiar si acolo unde presetul o coboara — adica ar fi la fel de oarba
## ca inainte, doar in cealalta directie.
const SETTLE_FRAMES: int = 36


## Camera asezata ca in joc pentru punctul `i` de pe ruta `r`, dupa `_unclip`.
##
## Se foloseste `snap_behind` (repunerea din joc) plus asteptarea de mai sus:
## asa camera trece prin exact acelasi `_unclip` si prin acelasi preset de zona
## ca in cursa, deci ce raporteaza sonda e pozitia FINALA a camerei, nu una
## teoretica.
func _place(r: TrackRoute, i: int) -> void:
	var n := r.baked.size()
	var p: Vector3 = r.baked[i]
	var fwd := (r.baked[(i + 1) % n] - p)
	if fwd.length() < 0.001:
		fwd = Vector3.FORWARD
	fwd = fwd.normalized()
	_car.global_transform = Transform3D(
		Basis.looking_at(fwd, Vector3.UP), p + Vector3.UP * 0.5)
	_car.linear_velocity = Vector3.ZERO
	# `road_index` se pune EXPLICIT: masina e teleportata, nu condusa, deci
	# integrarea care il tine la zi in cursa nu ruleaza. Fara el, zonele de
	# camera care lucreaza pe interval de fractie (`CameraZone.frac_from`) ar
	# crede ca masina e mereu la start, iar sonda ar masura o lume in care
	# presetul de cavern nu se aplica NICAIERI — adica ar raporta defecte pe
	# care jocul nu le are, si ar ascunde ce se intampla cu presetul pornit.
	_car.route = 0
	_car.road_index = i
	_cam.snap_behind()


func _sweep() -> Array:
	var space := _car.get_world_3d().direct_space_state
	var incidents: Array = []
	for ri in _track.routes.size():
		var r: TrackRoute = _track.routes[ri]
		var n := r.baked.size()
		print("")
		print("  [%s] %d puncte coapte" % [r.label, n])
		var f := 0.0
		var run: Dictionary = {}
		var near_count := 0
		while f < 1.0:
			var i := int(f * float(n)) % n
			_place(r, i)
			for _k in SETTLE_FRAMES:
				await get_tree().physics_frame
			var cam_p := _cam.global_position
			var look := _car.global_position \
				+ Vector3.UP * _cam.eff_look_height()

			# (a) camera INAUNTRUL unui corp
			var pq := PhysicsPointQueryParameters3D.new()
			pq.position = cam_p
			pq.collision_mask = ALL_LAYERS
			pq.collide_with_bodies = true
			pq.collide_with_areas = false
			var inside: Array[String] = []
			for res in space.intersect_point(pq, MAX_HITS):
				var b := res.get("collider") as Node
				if b == null:
					continue
				# SUPRAFETELE DESCHISE NU AU „INAUNTRU", si `intersect_point`
				# nu stie asta. Carosabilul si terenul sunt trimesh-uri cu
				# `backface_collision = true` (winding-ul nostru e arbitrar,
				# altfel masina ar cadea prin asfalt) — iar o suprafata
				# dublu-fatetata inchide un pseudo-volum, deci punctul aflat in
				# AER intre doua ture de elice iese raportat „in RoadTop".
				#
				# Masurat pe Cappadocia, cu raspunsul stiut dinainte:
				#   cer curat, +30 m peste start .......... NIMIC   (corect)
				#   elice, intre ture, 6,9 m peste asfalt . RoadTop (FALS)
				#   elice, sub carosabilul de jos ......... NIMIC   (corect)
				# Adica exact incidentul 0.790–0.880 din prima rulare a sondei
				# era al sondei, nu al pistei. Vezi memoria
				# `daca-doua-reglaje-dau-aceeasi-cifra` si antetul lui
				# ProbeLaneClear, unde aceeasi capcana raporta 393 blocaje
				# din 414 pe Alpi.
				#
				# Pentru ele intrebarea corecta e alta si se pune cu o raza:
				# camera e SUB suprafata? Restul corpurilor (hull-uri convexe,
				# cutii, trimesh-uri unilaterale de decor) sunt volume reale si
				# `intersect_point` spune adevarul despre ele.
				if _is_open_surface(b):
					continue
				inside.append(String(b.name))

			# (b) camera in spatele unui perete (masina nu se vede)
			var blocked := ""
			var rq := PhysicsRayQueryParameters3D.create(look, cam_p)
			rq.collision_mask = ALL_LAYERS
			var hit := space.intersect_ray(rq)
			if not hit.is_empty():
				var b := hit.get("collider") as Node
				# Terenul e scutit AICI, si numai aici: raza porneste din masina,
				# adica de pe teren, si o foaie dublu-fatetata raspunde din
				# primul centimetru. Nu e o scuza gratuita — terenul e pe
				# `CAMERA_BLOCKER_LAYER`, deci `_unclip` chiar il rezolva, si
				# camera ingropata in sol ar iesi oricum la testul (a).
				if b != null and String(b.name) != "TerrainBody":
					blocked = "%s intre masina si camera (la %.1f m)" % [
						String(b.name),
						(hit["position"] as Vector3).distance_to(look)]

			# (c) perete lipit de camera — se raporteaza, nu pica
			var near := ""
			if inside.is_empty() and blocked == "":
				var nq := PhysicsShapeQueryParameters3D.new()
				var sph := SphereShape3D.new()
				sph.radius = NEAR_M
				nq.shape = sph
				nq.collision_mask = ALL_LAYERS
				nq.transform = Transform3D(Basis.IDENTITY, cam_p)
				for res in space.intersect_shape(nq, 4):
					var b := res.get("collider") as Node
					if b != null and String(b.name) != "TerrainBody":
						near = String(b.name)
						break

			var bad := not inside.is_empty() or blocked != ""
			if near != "":
				near_count += 1
			if _verbose:
				var tail := ""
				if not inside.is_empty():
					tail += " | IN: %s" % ", ".join(inside)
				if blocked != "":
					tail += " | DUPA: %s" % blocked
				if near != "":
					tail += " | langa: %s" % near
				print("    %.3f cam=(%.1f, %.1f, %.1f)%s"
					% [f, cam_p.x, cam_p.y, cam_p.z, tail])
			if bad:
				var label := ", ".join(inside) if not inside.is_empty() \
					else blocked
				if run.is_empty():
					run = {"from": f, "to": f, "names": label,
						"where": cam_p, "route": r.label}
				else:
					run["to"] = f
					if String(run["names"]).find(label) < 0:
						run["names"] = "%s + %s" % [run["names"], label]
			elif not run.is_empty():
				incidents.append(run)
				_print_incident(run)
				run = {}
			f += STEP
		if not run.is_empty():
			incidents.append(run)
			_print_incident(run)
		if near_count > 0:
			print("    (informativ) %d probe cu un corp la sub %.1f m de camera"
				% [near_count, NEAR_M])
	return incidents


func _print_incident(run: Dictionary) -> void:
	var w: Vector3 = run["where"]
	print("    PICAT frac %.3f–%.3f | %s | camera la (%.1f, %.1f, %.1f)"
		% [run["from"], run["to"], run["names"], w.x, w.y, w.z])


## E corpul o SUPRAFATA deschisa (carosabil, teren, umeri) si nu un volum?
##
## Criteriul e FORMA, nu numele: orice `ConcavePolygonShape3D` cu
## `backface_collision` e o foaie dublu-fatetata, iar o foaie n-are interior.
## Pe nume ar fi fost o lista care putrezeste la prima redenumire — si chiar
## asta s-a intamplat de doua ori cu lista de suprafete de rulare din
## ProbeLaneClear (`ChannelDeckSides`, `TunnelShell`).
##
## [b]De ce se renunta cu totul la testul (a) pe ele, in loc sa se rafineze.[/b]
## Prima incercare a fost „e ingropata daca gaseste o fata a corpului deasupra
## SI una dedesubt". Suna corect si e tot gresit: pe elice, tura de deasupra si
## tura de dedesubt sunt ACELASI corp `RoadTop`, deci criteriul iese adevarat
## pentru camera aflata in aer curat intre ele — adica exact falsul pozitiv pe
## care incerca sa-l repare. O foaie n-are „inauntru" indiferent cate teste
## ii pui: intrebarea insasi e prost pusa.
##
## Pe suprafetele deschise raman testele care CHIAR au sens pentru o foaie, si
## amandoua raspund la „ce vede jucatorul":
##   (b) foaia taie linia dintre masina si camera — masina dispare sub ea;
##   (c) foaia e la sub `NEAR_M` de camera — umple cadrul.
## Ambele sunt masurate mai sus, pe toate corpurile, fara exceptie.
func _is_open_surface(body: Node) -> bool:
	for ch in body.get_children():
		var cs := ch as CollisionShape3D
		if cs == null:
			continue
		var con := cs.shape as ConcavePolygonShape3D
		if con != null and con.backface_collision:
			return true
	return false
