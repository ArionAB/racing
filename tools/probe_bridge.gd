extends SceneTree
## Podul mobil, masurat: golul obtinut, viteza de care ai nevoie ca sa-l treci,
## adancimea canalului si degajarea sub travee.
##
## De ce exista: fiecare cifra de aici e o consecinta, nu o setare. Golul cerut
## e 12 m, dar capetele lui cad pe puncte coapte, deci cel OBTINUT e altul.
## Pragul de viteza iese din gol, din panta rampei si din gravitatie. Degajarea
## sub travee iese din cursa ei, din pescajul corabiei si din nivelul marii.
## Scrise de mana, toate patru ar fi ramas in urma la prima ajustare.
##
##   godot --headless --path . --script res://tools/probe_bridge.gd -- --track=8
##
## Ce trebuie sa fie adevarat (si de ce):
##   - golul intre 10 si 16 m — sub 10 nu e o saritura, peste 16 pragul de
##     viteza urca peste ce poate o masina fara turbo;
##   - pragul sub 0.85 din viteza de varf de baza, ca podul sa pedepseasca
##     ezitarea, nu viteza;
##   - adancime peste 3 m, ca sa se vada apa si nu fundul;
##   - degajare pozitiva sub travee, altfel catargele intra in tabliera.
##
## Ce NU verifica sonda asta: daca se POATE TRECE. O raza trasa in jos spune ca
## exista asfalt, nu ca o masina il atinge — au fost doua defecte, unul dupa
## altul, in care podul era intreg pe verticala si oprea plutonul in loc. Pentru
## intrebarea aia exista tools/probe_bridge_drive.gd, care chiar trimite o
## masina peste el. (Am incercat si aici, cu raze ORIZONTALE de-a lungul axei:
## nu merge, fiindca axa podului e dreapta si soseaua nu — dupa 30 m orice raza
## paralela intra in parapetul din exteriorul curbei si raporteaza „blocat".)

var _path: String = ""
var _track: Node = null
var _frames: int = 0
var _fail: int = 0
## Etapa de masurare cu RAZE si cate cadre mai are de asteptat.
##
## Nu se poate face totul intr-un singur cadru: traveea e un AnimatableBody3D cu
## `sync_to_physics`, deci pozitia ei ajunge la serverul de fizica abia la
## urmatorul pas. Masurata imediat dupa ce i-am schimbat faza, o raza ar gasi
## structura acolo unde era, nu unde e — adica exact starea gresita, tacut.
var _stage: int = 0
var _settle: int = 0


func _initialize() -> void:
	var idx := 8
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = int(arg.trim_prefix("--track="))
	_path = "res://scenes/tracks/Track%02d.tscn" % idx
	if not ResourceLoader.exists(_path):
		push_error("probe_bridge: nu exista %s" % _path)
		quit(1)


func _process(_delta: float) -> bool:
	if _track == null:
		_track = (load(_path) as PackedScene).instantiate()
		root.add_child(_track)
		_frames = 0
		return false
	_frames += 1
	if _frames < 3:
		return false # lasam rebuild() sa termine
	if _stage == 0:
		_report()
		if _fail > 0 or _bridges().is_empty():
			quit(1 if _fail > 0 else 0)
			return true
		_stage = 1
		_settle = 0
	return _ray_stage()


func _bridges() -> Array:
	var out: Array = []
	if _track == null:
		return out
	for child in _track.get_children():
		if child is LiftBridgeHazard:
			out.append(child)
	return out


## Etapele cu raze: intai cu traveea jos, apoi cu ea sus. Faza se REIMPUNE la
## fiecare cadru fiindca `_physics_process` isi avanseaza singur ceasul.
const _STAGES := [
	{"name": "INCHIS", "t": 0.0},
	{"name": "DESCHIS", "t": 2.4},
]


func _ray_stage() -> bool:
	var stage: Dictionary = _STAGES[_stage - 1]
	for bridge in _bridges():
		bridge.set("_time", float(stage["t"]))
		bridge.call("_apply_cycle", float(stage["t"]))
	_settle += 1
	if _settle < 5:
		return false # lasam serverul de fizica sa mute traveea
	_measure_hole(String(stage["name"]))
	_stage += 1
	_settle = 0
	if _stage > _STAGES.size():
		print("")
		print("REZULTAT: %s" % ("toate verificarile trec" if _fail == 0
			else "%d verificari picate" % _fail))
		quit(1 if _fail > 0 else 0)
		return true
	return false


## Cati metri de axa a soselei n-au nimic sub ei, prin dreptul podului.
##
## Cu RAZE, nu din `_road_gap`: aia ar fi codul verificandu-se pe el insusi.
## Raza vede exact ce simte roata — asfalt, travee, rampa sau nimic.
func _measure_hole(state: String) -> void:
	var track := _track as Track
	var channels: Array = track.get("_channels")
	var space := track.get_world_3d().direct_space_state
	for ch: Dictionary in channels:
		var origin: Vector3 = ch["origin"]
		var across: Vector3 = ch["across"]
		var gap: float = ch["gap"]
		var hole := 0.0
		var probe := -30.0
		while probe <= 30.0:
			var q := origin - across * probe
			# Pornire de la 3 m peste asfalt, nu de mai sus: traveea RIDICATA sta
			# la 5.5 m deasupra lui, fix peste gol. O raza pornita de deasupra ei
			# ar raporta „nu e gaura" tocmai cand e — si asta a si facut prima
			# versiune, cu 8 m.
			var from := Vector3(q.x, origin.y + 3.0, q.z)
			# Raza e SCURTA (pana la 4 m sub asfalt) dinadins. Una lunga ajunge
			# la fundul dragat al canalului si raporteaza „nu e gaura" peste tot,
			# fiindca sub gol chiar e ceva: apa are pat. Ce ne intereseaza e daca
			# roata gaseste ceva la nivelul drumului, nu daca lumea are podea.
			var params := PhysicsRayQueryParameters3D.create(
				from, from + Vector3.DOWN * 7.0)
			if space.intersect_ray(params).is_empty():
				hole += 0.5
			probe += 0.5
		print("  gaura pe axa soselei, travee %-7s %.1f m" % [state + ":", hole])
		if state == "INCHIS":
			_check(hole < 1.0, "cu traveea jos se trece pe roti")
		else:
			_check(absf(hole - gap) < 3.5,
				"cu traveea sus gaura e cat golul (%.2f m)" % gap)


func _check(ok: bool, text: String) -> void:
	if not ok:
		_fail += 1
	print("  %s %s" % ["OK  " if ok else "FAIL", text])


func _report() -> void:
	var track := _track as Track
	var sampler: TrackSideSampler = track.get("_sampler")
	var channels: Array = track.get("_channels")
	print("=== POD MOBIL: %s ===" % track.track_name)
	if channels.is_empty():
		print("  pista nu declara niciun canal")
		quit(0)
		return
	var sea_y: float = sampler.mean_road_y() + track.sea_level_offset
	for ch: Dictionary in channels:
		_report_channel(track, sampler, ch, sea_y)


func _report_channel(track: Track, sampler: TrackSideSampler, ch: Dictionary,
		sea_y: float) -> void:
	var origin: Vector3 = ch["origin"]
	var across: Vector3 = ch["across"]
	var along: Vector3 = ch["along"]
	var gap: float = ch["gap"]
	print("")
	print("--- %s (frac %.3f) ---" % [String(ch.get("label", "canal")),
		float(ch["frac"])])
	print("  sosea %.2f m · apa %.2f m · deci %.2f m de aer sub tabliera"
		% [origin.y, sea_y, origin.y - sea_y])

	# --- golul obtinut si viteza care il trece -------------------------------
	var rise := LiftBridgeHazard.RAMP_RISE
	var run := LiftBridgeHazard.RAMP_RUN
	var ang := atan2(rise, run)
	var g := 28.0 # Car.gravity
	# Decolezi de pe varful rampei (la +rise) si trebuie sa atingi varful
	# celeilalte, tot la +rise, dupa `gap` metri. Inaltimea la plecare si la
	# sosire e aceeasi, deci se reduce si ramane bataia balistica clasica.
	var v_need := sqrt(gap * g / maxf(sin(2.0 * ang), 0.001))
	print("  gol cerut %.1f m -> OBTINUT %.2f m (%d pasi de curba)"
		% [float(ch.get("gap_requested", 12.0)), gap, int(ch["steps"]) * 2])
	print("  rampa %.2f m pe %.2f m = %.1f° · prag de trecere %.1f m/s (%.0f%%"
		% [rise, run, rad_to_deg(ang), v_need, v_need / 34.0 * 100.0]
		+ " din 34 m/s)")
	_check(gap >= 10.0 and gap <= 16.0, "golul e in 10..16 m")
	_check(v_need < 34.0 * 0.85, "pragul e sub 85%% din viteza de varf")

	# --- profilul canalului --------------------------------------------------
	var deepest := 0.0
	var wet := 0.0
	var d := -float(ch["reach"])
	while d <= float(ch["reach"]):
		var q := origin + along * d
		var y := sampler.ground_y(q.x, q.z)
		if y < sea_y:
			wet += 2.0
			deepest = maxf(deepest, sea_y - y)
		d += 2.0
	print("  senal: %.0f m de apa in lungul canalului, adanc pana la %.1f m"
		% [wet, deepest])
	_check(deepest > 3.0, "canalul are peste 3 m de apa")
	_check(wet > 120.0, "canalul e navigabil pe peste 120 m")

	# Latimea apei, masurata IN LUNGUL soselei prin dreptul podului.
	var width := 0.0
	var s := -80.0
	while s <= 80.0:
		var q := origin + across * s
		if sampler.ground_y(q.x, q.z) < sea_y:
			width += 1.0
		s += 1.0
	print("  latimea apei sub pod: %.0f m" % width)
	_check(width > 30.0, "apa e mai lata de 30 m sub pod")

	# --- degajarea sub travee ------------------------------------------------
	var bridge: LiftBridgeHazard = null
	for child in track.get_children():
		if child is LiftBridgeHazard:
			bridge = child
	if bridge == null:
		_check(false, "hazardul de pod exista in scena")
		return
	var deck := (bridge.near_lip.y + bridge.far_lip.y) * 0.5 + origin.y
	var span_top := deck + LiftBridgeHazard.RAMP_RISE
	var span_open := span_top + LiftBridgeHazard.LIFT_HEIGHT \
		- LiftBridgeHazard.SPAN_THICK
	# Varful catargelor peste apa: modelul are originea la chila, deci inaltimea
	# vizibila e (inaltime * scara) minus pescajul.
	var mast := 9.96 * LiftBridgeHazard.SHIP_SCALE \
		- LiftBridgeHazard.SHIP_DRAFT * LiftBridgeHazard.SHIP_SCALE + sea_y
	print("  travee jos %.2f m · sus %.2f m · varf de catarg %.2f m"
		% [span_top, span_open, mast])
	print("  degajare sub traveea ridicata: %.2f m" % (span_open - mast))
	_check(span_open - mast > 0.5, "catargele trec pe sub traveea ridicata")
	_check(mast > deck, "catargele chiar depasesc asfaltul (podul are rost)")

	# --- ciclul --------------------------------------------------------------
	var open_total := LiftBridgeHazard.LIFT_TIME * 2.0 \
		+ LiftBridgeHazard.OPEN_HOLD
	print("  ciclu %.0f s: %.1f s complet deschis, %.1f s cu gol, %.1f s inchis"
		% [LiftBridgeHazard.PERIOD, LiftBridgeHazard.OPEN_HOLD, open_total,
			LiftBridgeHazard.PERIOD - open_total])
	_check(LiftBridgeHazard.PERIOD - open_total > 3.5,
		"podul e inchis mai mult decat e deschis")

	# --- corabiile: chiar trec prin gol cand traveea e sus? ------------------
	var worst := INF
	var t := LiftBridgeHazard.LIFT_TIME
	while t <= LiftBridgeHazard.LIFT_TIME + LiftBridgeHazard.OPEN_HOLD:
		var best := INF
		for i in LiftBridgeHazard.SHIP_COUNT:
			var phase := fposmod(t + LiftBridgeHazard.SHIP_LEAD
				+ float(i) * LiftBridgeHazard.PERIOD,
				LiftBridgeHazard.SHIP_PERIOD)
			var off := LiftBridgeHazard.SHIP_SPEED \
				* (phase - LiftBridgeHazard.SHIP_PERIOD * 0.5)
			best = minf(best, absf(off))
		worst = minf(worst, best)
		t += 0.1
	print("  cea mai apropiata corabie in fereastra deschisa: %.1f m de gol"
		% worst)
	_check(worst < 4.0, "o corabie chiar trece prin gol la fiecare deschidere")
