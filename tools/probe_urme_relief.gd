extends Node
## Garda de RELIEF pentru URMELE DE ROTI.
##
## (Nu confunda cu tools/probe_relief.gd, care masoara stratele de roca de pe
## POI C — nume asemanator, subiect complet diferit.)
##
## ############################################################################
## DE CE EXISTA, SI DE CE NU E INCA O SONDA DE "SE VEDE URMA"
##
## Sondele de pana acum masurau cat de INCHISA e brazda (media fata de sol) si
## daca gradientul are semnul bun (procent de pixeli mai inchisi). Amandoua au
## dat verde pe o dara care, de la volan, nu avea nicio adancime — fiindca
## masurau intunericul, nu relieful.
##
## O adancitura se citeste fiindca are DOUA lucruri: umbra in fund SI lumina pe
## buza dinspre soare. Ochiul deduce forma din perechea asta. O pata inchisa,
## oricat de bine modelata, ramane o pata.
##
## Masurat pe ghidul vizual al proiectului (panoul TRACKS CLOSE-UP):
##   30.7% pixeli mai inchisi decat fundalul, 20.8% mai deschisi
##   => raport lumina/umbra ~0.68
## Masurat pe varianta fara buza (ce era pe main inainte de sonda asta):
##   95.9% inchisi, 4.1% deschisi => raport 0.04
##
## De-aia garda masoara RAPORTUL, nu intunericul.
## ############################################################################

const RACE_SCENE: String = "res://scenes/race/Race.tscn"

## Cate cadre se masoara si se mediaza.
##
## O singura captura NU e un verdict: pe Okinawa, cinci rulari consecutive fara
## nicio schimbare de cod au dat 0.34 / 0.24 / 0.24 / 0.23 / 0.39. Cadrul cade
## in alt loc de pe pista de fiecare data (Jolt e nedeterminist intre rulari),
## iar unghiul soarelui fata de dara conteaza direct in ce masuram. Media pe mai
## multe cadre e stabila; un singur cadru a trimis deja aceasta sonda pe piste
## false de doua ori.
const SAMPLES: int = 5

## Sub raportul asta, dara nu se mai citeste ca adancitura. Nu e 0.68 (tinta din
## ghid) fiindca o garda trebuie sa prinda regresia, nu sa ceara perfectiunea:
## intre 0.25 si 0.68 mai e loc de reglaj artistic, sub 0.25 nu mai e relief.
const MIN_RATIO: float = 0.25

## Peste raportul asta, buza domina si dara devine o dunga DESCHISA — tot o pata,
## doar in cealalta directie. Prins pe Stromboli: pe soseaua vulcanica inchisa,
## aceeasi buza care pe nisip dadea 0.36 sarea la 3.44, fiindca orice luminare
## se vede tare pe un sol inchis. O garda cu un singur capat n-ar fi prins-o.
const MAX_RATIO: float = 1.30

var _race: Node = null
var _car: Car = null
var _frames: int = 0
var _taken: bool = false
var _next_shot: int = 0
var _done: bool = false


func _ready() -> void:
	GameState.selected_track = 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			GameState.selected_track = GameState.resolve_track_index(
				int(arg.trim_prefix("--track=")))
	GameState.selected_car = 0
	GameState.champ_active = false
	GameState.total_laps = 99
	_race = (load(RACE_SCENE) as PackedScene).instantiate()
	add_child(_race)


func _physics_process(_d: float) -> void:
	_frames += 1
	if _frames == 5:
		# Filmam o masina AI: jucatorul fara input sta pe loc.
		for c: Car in (_race.get("cars") as Array):
			if c != _race.player:
				_car = c
		return
	if _car == null or _taken:
		return
	var t := _race.track as Track
	if _frames < 900:
		return
	if _car.horizontal_speed() < 20.0:
		return
	if not t.is_on_road(_car.road_index, _car.global_position):
		return
	# Doar pistele cu sosea AFANATA: pe asfalt urmele apar numai in afara
	# drumului, deci un cadru de pe sosea n-are ce masura. Fara verificarea
	# asta, garda raporta "dara aproape ca nu exista" pe Dunele/Alpi/Baikal —
	# un fals pozitiv care ar fi ascuns regresiile reale de pe celelalte.
	if not t.road_is_loose():
		print("=== ProbeUrmeRelief — pista %d ===" % GameState.selected_track)
		print("  sosea tare (%s): urmele apar doar in afara drumului, se sare."
			% t.road_surface)
		print("VERDICT: OK (nu se aplica)")
		get_tree().quit(0)
		return
	if _frames < _next_shot:
		return
	_next_shot = _frames + 40
	_shoot()


## Camera PESTE dara, privind in urma. Camera de joc se uita inainte, deci nu
## vede niciodata urma proaspata — masurarea ei de acolo ar fi masurat drumul gol.
func _shoot() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 70.0
	var back := _car.global_basis.z
	cam.global_position = _car.global_position + back * 5.0 + Vector3.UP * 4.5
	cam.look_at(_car.global_position + back * 22.0, Vector3.UP)
	cam.make_current()
	# Doua cadre de asteptare: unul ca sa se aplice camera, unul ca sa se
	# deseneze cu ea. force_draw() intorcea acelasi cadru si diferenta iesea
	# zero peste tot — o sonda care spune "nu exista dara" fiindca n-a apucat
	# sa se uite.
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var with_trail := get_viewport().get_texture().get_image()
	# Aceeasi randare, fara dara: diferenta e chiar urma, izolata de textura
	# drumului si de umbrele lumii.
	for c: Car in (_race.get("cars") as Array):
		for ch in c.get_children():
			var tr := ch as SandTrail
			if tr != null:
				tr.visible = false
	await RenderingServer.frame_post_draw
	var without := get_viewport().get_texture().get_image()
	_measure(with_trail, without)
	# Camera de masurare a stins darele ca sa ia perechea; le repunem, altfel
	# esantioanele urmatoare masoara un drum gol.
	for c: Car in (_race.get("cars") as Array):
		for ch in c.get_children():
			var tr2 := ch as SandTrail
			if tr2 != null:
				tr2.visible = true
	cam.queue_free()
	if _done:
		return
	if _ratios.size() >= SAMPLES or _frames > 2600:
		_done = true
		_verdict()


var _ratios: Array[float] = []


func _measure(a: Image, b: Image) -> void:
	var lighter := 0
	var darker := 0
	for y in range(0, a.get_height(), 2):
		for x in range(0, a.get_width(), 2):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			var la := ca.r * 0.2126 + ca.g * 0.7152 + ca.b * 0.0722
			var lb := cb.r * 0.2126 + cb.g * 0.7152 + cb.b * 0.0722
			var diff := (la - lb) * 255.0
			if diff > 3.0:
				lighter += 1
			elif diff < -3.0:
				darker += 1
	if darker + lighter < 400:
		return
	_ratios.append(float(lighter) / maxf(float(darker), 1.0))


func _verdict() -> void:
	if _ratios.is_empty():
		# Prea putina dara ca sa se poata masura FORMA ei. Nu e neaparat un
		# defect: pe Baikal masina merge pe banda de gheata, unde nu se depune
		# nimic (Car._on_loose_ground o exclude anume). Garda spune ce a vazut
		# si nu pretinde un verdict pe care nu-l poate da.
		print("=== ProbeUrmeRelief — pista %d ===" % GameState.selected_track)
		print("  nicio dara in cadru — nimic de masurat.")
		print("VERDICT: OK (fara dara in cadru)")
		get_tree().quit(0)
		return
	var ratio := 0.0
	for r in _ratios:
		ratio += r
	ratio /= float(_ratios.size())
	print("=== ProbeUrmeRelief — pista %d ===" % GameState.selected_track)
	print("  esantioane: %s" % str(_ratios))
	print("  raport lumina/umbra : %.2f   (ghid 0.68, prag %.2f)"
		% [ratio, MIN_RATIO])
	print("  (prag maxim %.2f)" % MAX_RATIO)
	if ratio < MIN_RATIO:
		print("VERDICT: PROBLEMA — dara e o pata inchisa, nu o adancitura.")
		print("  O adancitura are si lumina pe buza, nu doar umbra in fund.")
		get_tree().quit(1)
		return
	if ratio > MAX_RATIO:
		print("VERDICT: PROBLEMA — buza domina: dara e o dunga DESCHISA.")
		print("  Pe un sol inchis, aceeasi buza se vede de cateva ori mai tare.")
		get_tree().quit(1)
		return
	print("VERDICT: OK")
