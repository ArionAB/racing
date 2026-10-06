extends Node
## GARDA DE FOTOSENSIBILITATE pentru tunelul de torii (Kyoto, brief §3 / §6 / §7.1c).
##
## [b]Problema.[/b] 125 de porti la 1,2 m, parcurse la ~30 m/s, inseamna ~25 de treceri
## pe secunda in benzile laterale ale cadrului. Ghidurile (WCAG 2.3.1, testul Harding)
## pun pragul la 3 flash-uri pe secunda. Aceasta sonda MASOARA, nu ghiceste: ruleaza
## masina REALA, cu ChaseCamera reala si CameraZone coborata, citeste imaginea
## viewport-ului in fiecare cadru si socoteste flash-urile pe luminanta relativa.
##
## [b]Ruleaza CU FEREASTRA[/b] (randarea nu merge headless — memoria
## `snapshot-nu-merge-headless`), la 60 fps fix:
##   Godot --path . --fixed-fps 60 --resolution 960x540 res://tools/ProbeFlicker.tscn \
##     -- --variant=dense_dark
##   ... -- --variant=sparse_sky      (MARTORUL: trebuie sa PICE, altfel garda e moarta)
## Argumente de reglaj (pargiile din brief): --spacing= --depth= --bg=<slot>
##   --ground=<slot> --sun=<energie> --amb=<energie> --shots (salveaza cadre in snapshots/).
##
## [b]Definitia[/b] (WCAG 2.3.1 simplificat): luminanta relativa liniara (0..1) pe regiune;
## un "flash" = pereche de schimbari OPUSE de >= 0.10 (10% din maximul 1.0). Se numara pe
## fereastra glisanta de 1 s: n schimbari = n/2 flash-uri. Contract: <= 3 pe regiune.
## Se raporteaza si pragul strans de 0.05 (marja), nu doar cel normativ.
## ROSU SATURAT (WCAG 2.3.1, a doua regula): se raporteaza SEPARAT, in doua feluri.
## (a) pe MEDIA regiunii: starea e "rosu saturat" cand R/(R+G+B) >= 0.8 pe media
## liniara a regiunii, valoarea e max(0, (R-G-B)*320), o pereche de tranzitii opuse
## de >= 20 intr-o fereastra de 1 s e un flash. (b) pe SUPRAFATA: fractia de pixeli
## (dupa medierea 4x4) cu R/(R+G+B) >= 0.8, flash = pereche de variatii opuse ale
## fractiei de >= 0.25 din regiune (pragul de 25% al ghidurilor), plus 0.10 strans.
## Contract: <= 3 pe regiune, ca la luminanta.
## NEMASURAT: conditia "luminanta celei mai intunecate imagini < 0.8" (ignorata:
## ar scadea doar numarul de flash-uri) si unghiul solid real (10 grade) al ochiului.
##
## [b]MOD REAL[/b] (`--track=11`, brief §7 pasul 6): in loc de culoarul sintetic ruleaza
## PE PISTA (Track18, banda E' = ruta 1): masina condusa pe axa benzii la viteza maxima,
## ChaseCamera + CameraZone-ul tunelului, portile/peretii/padurea din `ToriiTunnel`.
##   ... -- --track=11                       (tinta: trebuie sa treaca)
##   ... -- --track=11 --sabotage=forest_off (padurea stinsa: cer prin goluri, trebuie sa pice)
##   ... -- --track=11 --sabotage=gap24      (pas 2,4 m, cer in goluri; de la decizia de raritate 50% e chiar pasul tintei, deci nu mai pica pe E' real)
##   ... -- --track=11 --sabotage=both       (ambele)
##   ... -- --track=11 --sabotage=bright     (perete luminos in locul padurii: trebuie sa pice)
##   ... -- --track=11 --sabotage=red_flash  (porti la 6 m pe fundal negru: arma regula rosului saturat)
##
## Iese cu 1 daca pica un verdict (CI), cu 2 daca sonda e moarta.

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const LENGTH: float = 150.0
const HALF_GAP: float = 3.2          # culoar liber 6,4 m
const BEAM_Y: float = 5.2            # sub grinzi
const POST_W: float = 0.6
const KASAGI_H: float = 0.4
const KASAGI_HALF: float = 4.5
const FLASH_THR: float = 0.10
const FLASH_THR_STRICT: float = 0.05
const CONTRACT: float = 3.0
const REDUCE_W: int = 240
const SPEED: float = 32.0
const RED_RATIO: float = 0.8

var variant: String = "dense_dark"
var spacing: float = 1.2
var depth: float = 0.7
var bg_slot: int = Palette.TROPICAL_GREEN
var ground_slot: int = Palette.TROPICAL_GREEN
var sun_energy: float = 1.7
var amb_energy: float = 0.55
var forest: bool = true
var shots: bool = false
## Mod real: indexul pistei (>= 0) si sabotajul cerut pe ea.
var real_idx: int = -1
var sabotage: String = ""
var _track: Track = null
var _tunnel: ToriiTunnel = null

var _car: Car
var _cam: ChaseCamera
var _mat: StandardMaterial3D
## Ultimele valori de rosu pe regiune [stanga, tot, dreapta]: [valoare, raport, fractie].
var _last_red: Array = [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]


class SteerBot extends CarController:
	func get_steer() -> float:
		var fwd := -car.global_basis.z
		return clampf(1.6 * fwd.x + 0.25 * car.global_position.x, -1.0, 1.0)


## Sofer de sonda pentru modul REAL: tine axa benzii (ruta 1) cu un punct-tinta la 14 m.
class LaneBot extends CarController:
	var route: TrackRoute
	var idx: int = 0
	func get_steer() -> float:
		idx = route.closest_index(idx, car.global_position)
		var d: float = route.dists[idx] + 14.0
		var j := idx
		while j < route.baked.size() - 1 and route.dists[j] < d:
			j += 1
		var to := route.baked[j] - car.global_position
		to.y = 0.0
		var fwd := -car.global_basis.z
		fwd.y = 0.0
		if to.length_squared() < 1e-4 or fwd.length_squared() < 1e-4:
			return 0.0
		var c := fwd.normalized().cross(to.normalized()).y
		return clampf(c * 2.5, -1.0, 1.0)


func _ready() -> void:
	_parse()
	await _run()


func _parse() -> void:
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--variant="):
			variant = a.get_slice("=", 1)
		elif a.begins_with("--track="):
			real_idx = GameState.resolve_track_index(int(a.get_slice("=", 1)))
			if real_idx < 0:
				push_error("ProbeFlicker: --track necunoscut")
				get_tree().quit(2)
		elif a.begins_with("--sabotage="):
			sabotage = a.get_slice("=", 1)
	if variant == "sparse_sky":
		# Martorul: porti rare, subtiri, cer si soare in goluri, fara padure.
		spacing = 6.0
		depth = 0.35
		forest = false
		ground_slot = Palette.SAND_LIGHT
	# Reglajele explicite ruleaza DUPA preseturile de varianta.
	for a in args:
		if a.begins_with("--spacing="):
			spacing = float(a.get_slice("=", 1))
		elif a.begins_with("--depth="):
			depth = float(a.get_slice("=", 1))
		elif a.begins_with("--bg="):
			bg_slot = int(a.get_slice("=", 1))
		elif a.begins_with("--ground="):
			ground_slot = int(a.get_slice("=", 1))
		elif a.begins_with("--sun="):
			sun_energy = float(a.get_slice("=", 1))
		elif a.begins_with("--amb="):
			amb_energy = float(a.get_slice("=", 1))
		elif a == "--shots":
			shots = true


func _run() -> void:
	if real_idx < 0:
		_mat = Palette.world_material()
	if real_idx >= 0:
		await _build_real()
	else:
		_build_world()
	await get_tree().physics_frame
	var real := real_idx >= 0
	var n_gates := int(floor(LENGTH / spacing))
	if real:
		n_gates = _tunnel.gate_count
		print("=== PROBE FLICKER REAL: %s | %s | %d porti, pas %.2f m, %d cedri, tunel %.0f..%.0f m pe banda ===" %
			[GameState.track_label(real_idx), "sabotaj=" + sabotage if sabotage != "" else "tinta",
			n_gates, _tunnel.spacing, _tunnel.forest_count, _tunnel.tunnel_start_dist, _tunnel.tunnel_end_dist])
	else:
		print("=== PROBE FLICKER: %s | %d porti, pas %.2f m, adancime %.2f m (gol %.2f m) ===" %
			[variant, n_gates, spacing, depth, spacing - depth])
	var zs: Array[float] = []
	var vs: Array[float] = []
	var xs: Array[float] = []
	var lum_l: Array[float] = []
	var lum_r: Array[float] = []
	var lum_a: Array[float] = []
	# [regiune] -> serii: valoare rosu pe medie, raport R/(R+G+B) pe medie, fractie suprafata
	var red_val: Array = [[], [], []]
	var red_ratio: Array = [[], [], []]
	var red_frac: Array = [[], [], []]
	var shot_marks: Array[float] = [-20.0, -50.0, -80.0, -110.0]
	var frame := 0
	var route: TrackRoute = null
	var bidx := 0
	if real:
		route = _track.route_at(1)
	while frame < 2400:
		await RenderingServer.frame_post_draw
		frame += 1
		var z := _car.global_position.z
		var in_run := false
		if real:
			bidx = route.closest_index(bidx, _car.global_position)
			var dd: float = route.dists[bidx]
			if dd > _tunnel.tunnel_end_dist - 6.0:
				break
			in_run = dd >= _tunnel.tunnel_start_dist + 6.0
			z = -dd
		else:
			if z < -(LENGTH - 8.0):
				break
			in_run = z <= -12.0
		if not in_run:
			continue
		var img := get_viewport().get_texture().get_image()
		var l := _regions(img)
		lum_l.append(l[0])
		lum_a.append(l[1])
		lum_r.append(l[2])
		for k in 3:
			red_val[k].append(_last_red[k][0])
			red_ratio[k].append(_last_red[k][1])
			red_frac[k].append(_last_red[k][2])
		zs.append(z)
		vs.append(_car.linear_velocity.length())
		xs.append(_lat_of(route, bidx) if real else _car.global_position.x)
		if shots and not shot_marks.is_empty() and z < shot_marks[0]:
			shot_marks.pop_front()
			var dir := ProjectSettings.globalize_path("res://snapshots")
			DirAccess.make_dir_recursive_absolute(dir)
			img.save_png("%s/flicker_%s_%d.png" % [dir, variant if not real else "real" + sabotage, int(-z)])
	var n := lum_a.size()
	if n < 60:
		print("SONDA MOARTA: doar %d cadre in culoar (frame=%d, z=%.1f)" % [n, frame, _car.global_position.z])
		get_tree().quit(2)
		return
	var fails := 0
	var dead := _dead(lum_l) or _dead(lum_r) or _dead(lum_a)
	print("cadre analizate: %d (%.2f s) | viteza %.1f..%.1f m/s | |lateral| max %.2f m"
		% [n, n / 60.0, _min(vs), _max(vs), maxf(absf(_min(xs)), absf(_max(xs)))])
	print("%-8s %8s %8s %8s %6s | %11s %11s | %9s %8s %8s"
		% ["regiune", "L medie", "L min", "L max", "unice", "flash/s .10", "flash/s .05",
			"ampl med", "swing/s", "f dom Hz"])
	var names := ["stanga", "dreapta", "tot"]
	var series := [lum_l, lum_r, lum_a]
	for i in 3:
		var s: Array[float] = series[i]
		var r10 := _flashes(s, FLASH_THR)
		var r05 := _flashes(s, FLASH_THR_STRICT)
		var ok := (r10[0] as float) <= CONTRACT
		if not ok:
			fails += 1
		print("%-8s %8.4f %8.4f %8.4f %6d | %11.1f %11.1f | %9.3f %8.1f %8.1f  %s"
			% [names[i], _mean(s), _min(s), _max(s), _unique(s), r10[0], r05[0], r10[1],
				float(r10[2]) / (n / 60.0), _dom_freq(s), "OK" if ok else "PICAT"])
	# ROSU SATURAT, raportat separat (vezi antetul).
	print("--- ROSU SATURAT (WCAG): R/(R+G+B) >= %.1f ---" % RED_RATIO)
	print("%-8s %9s %9s %9s | %12s | %10s %10s %10s"
		% ["regiune", "raport med", "raport max", "frac suprf", "flash/s medie", "suprf .25", "suprf .10", "suprf max"])
	var red_fails := 0
	for i in 3:
		var rv: Array[float] = []
		rv.assign(red_val[i])
		var rr: Array[float] = []
		rr.assign(red_ratio[i])
		var rf: Array[float] = []
		rf.assign(red_frac[i])
		# (a) pe medie: tranzitie doar daca una din stari e "rosu saturat" (raport >= 0.8)
		var fl_mean := _red_mean_flashes(rv, rr)
		var f25 := _flashes(rf, 0.25)
		var f10 := _flashes(rf, 0.10)
		var ok_r := fl_mean <= CONTRACT and (f25[0] as float) <= CONTRACT
		if not ok_r:
			red_fails += 1
		print("%-8s %9.3f %9.3f %9.3f | %12.1f | %10.1f %10.1f %10.3f  %s"
			% [names[i], _mean(rr), _max(rr), _mean(rf), fl_mean, f25[0], f10[0], _max(rf),
				"OK" if ok_r else "PICAT"])
	if dead:
		print("SONDA MOARTA: luminanta e constanta pe cadre (imagine goala/neconectata)")
		get_tree().quit(2)
		return
	var tag := variant if not real else "real %s" % (sabotage if sabotage != "" else "tinta")
	print("=== %s: luminanta %s | rosu saturat %s ===" % [tag,
		"PICAT (%d regiuni)" % fails if fails > 0 else "PASS",
		"PICAT (%d regiuni)" % red_fails if red_fails > 0 else "PASS"])
	get_tree().quit(1 if (fails > 0 or red_fails > 0) else 0)


func _lat_of(route: TrackRoute, i: int) -> float:
	var p := route.baked[i]
	var q := _car.global_position - p
	return q.dot(route.side_at(i))


## WCAG, rosu saturat, pe MEDIA regiunii: numara perechile de tranzitii opuse ale
## valorii max(0,(R-G-B)*320) de >= 20, doar cand una din stari are R/(R+G+B) >= 0.8.
## Fereastra glisanta de 1 s; rezultat in flash-uri/s (n tranzitii / 2).
func _red_mean_flashes(val: Array[float], ratio: Array[float]) -> float:
	var times: Array[float] = []
	var pivot := 0
	var dir := 0
	for i in range(1, val.size()):
		var d := val[i] - val[pivot]
		var red_state := ratio[i] >= RED_RATIO or ratio[pivot] >= RED_RATIO
		if absf(d) >= 20.0 and red_state:
			var nd := 1 if d > 0.0 else -1
			if dir != 0 and nd != dir:
				times.append(i / 60.0)
			dir = nd
			pivot = i
	var best := 0
	var j := 0
	for i in times.size():
		while times[i] - times[j] >= 1.0:
			j += 1
		best = maxi(best, i - j + 1)
	return best / 2.0


# ----------------------------------------------------------------- masuratoare

## Luminanta relativa medie [stanga, tot, dreapta] (liniara 0..1, coeficienti Rec.709).
func _regions(img: Image) -> Array[float]:
	var im := img.duplicate() as Image
	if im.get_format() != Image.FORMAT_RGB8:
		im.convert(Image.FORMAT_RGB8)
	# Injumatatiri succesive cu filtru bilinear = medie pe 2x2: mediere pe suprafata,
	# nu esantionare punctuala (altfel muchia unui stalp subtire ar aliasa).
	while im.get_width() > REDUCE_W:
		im.resize(im.get_width() / 2, im.get_height() / 2, Image.INTERPOLATE_BILINEAR)
	var w := im.get_width()
	var h := im.get_height()
	var d := im.get_data()
	var sums := [0.0, 0.0, 0.0]
	var cnt := [0, 0, 0]
	# rosu: sume liniare R,G,B si pixeli cu raport >= RED_RATIO, per regiune (stanga, tot, dreapta)
	var rs := [0.0, 0.0, 0.0]
	var gs := [0.0, 0.0, 0.0]
	var bs := [0.0, 0.0, 0.0]
	var redpx := [0, 0, 0]
	var third := w / 3
	for y in h:
		for x in w:
			var o := (y * w + x) * 3
			var lr: float = _LIN[d[o]]
			var lg: float = _LIN[d[o + 1]]
			var lb: float = _LIN[d[o + 2]]
			var lum := 0.2126 * lr + 0.7152 * lg + 0.0722 * lb
			var tot := lr + lg + lb
			var is_red := tot > 1e-6 and lr / tot >= RED_RATIO and (lr - lg - lb) * 320.0 >= 20.0
			var regs: Array[int] = [1]
			if x < third:
				regs.append(0)
			elif x >= w - third:
				regs.append(2)
			for k in regs:
				sums[k] += lum
				cnt[k] += 1
				rs[k] += lr
				gs[k] += lg
				bs[k] += lb
				if is_red:
					redpx[k] += 1
	# _last_red in ordinea numelor din raport: [stanga, dreapta, tot]
	var order := [0, 2, 1]
	for oi in 3:
		var k: int = order[oi]
		var mr: float = rs[k] / cnt[k]
		var mg: float = gs[k] / cnt[k]
		var mb: float = bs[k] / cnt[k]
		var mt := mr + mg + mb
		_last_red[oi] = [maxf(0.0, (mr - mg - mb) * 320.0), mr / mt if mt > 1e-6 else 0.0,
			float(redpx[k]) / float(cnt[k])]
	var out: Array[float] = [sums[0] / cnt[0], sums[1] / cnt[1], sums[2] / cnt[2]]
	return out


static var _LIN: PackedFloat32Array = _make_lin()

static func _make_lin() -> PackedFloat32Array:
	var t := PackedFloat32Array()
	t.resize(256)
	for i in 256:
		var c := i / 255.0
		t[i] = c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4)
	return t


## [max flash-uri/s in orice fereastra de 1 s, amplitudine medie, nr schimbari]
func _flashes(s: Array[float], thr: float) -> Array:
	var times: Array[float] = []
	var amps: Array[float] = []
	var dir := 0
	var pivot := s[0]
	var ext := s[0]
	for i in s.size():
		var v := s[i]
		if dir == 0:
			if v - pivot >= thr:
				dir = 1
				ext = v
			elif pivot - v >= thr:
				dir = -1
				ext = v
		elif dir == 1:
			if v > ext:
				ext = v
			elif ext - v >= thr:
				times.append(i / 60.0)
				amps.append(absf(ext - pivot))
				pivot = ext
				dir = -1
				ext = v
		else:
			if v < ext:
				ext = v
			elif v - ext >= thr:
				times.append(i / 60.0)
				amps.append(absf(ext - pivot))
				pivot = ext
				dir = 1
				ext = v
	var best := 0
	var j := 0
	for i in times.size():
		while times[i] - times[j] >= 1.0:
			j += 1
		best = maxi(best, i - j + 1)
	var amp := 0.0
	for a in amps:
		amp += a
	if not amps.is_empty():
		amp /= amps.size()
	return [best / 2.0, amp, times.size()]


## Frecventa dominanta (Hz) prin DFT naiva pe 0.5..30 Hz, dupa scaderea mediei.
func _dom_freq(s: Array[float]) -> float:
	var m := _mean(s)
	var best_f := 0.0
	var best_p := 0.0
	var n := s.size()
	var f := 0.5
	while f <= 30.0:
		var re := 0.0
		var im := 0.0
		for i in n:
			var ph := TAU * f * i / 60.0
			re += (s[i] - m) * cos(ph)
			im += (s[i] - m) * sin(ph)
		var p := re * re + im * im
		if p > best_p:
			best_p = p
			best_f = f
		f += 0.5
	return best_f


func _dead(s: Array[float]) -> bool:
	return _max(s) - _min(s) < 1e-4 or _mean(s) < 0.001


func _unique(s: Array[float]) -> int:
	var d := {}
	for v in s:
		d[snappedf(v, 1e-6)] = true
	return d.size()


func _mean(s: Array[float]) -> float:
	var t := 0.0
	for v in s:
		t += v
	return t / s.size()


func _min(s: Array[float]) -> float:
	var m := s[0]
	for v in s:
		m = minf(m, v)
	return m


func _max(s: Array[float]) -> float:
	var m := s[0]
	for v in s:
		m = maxf(m, v)
	return m


# ------------------------------------------------------------------------ lume

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.78, 0.95)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color.html("C9A98A")
	e.ambient_light_energy = amb_energy
	e.fog_enabled = true
	e.fog_light_color = Color(0.72, 0.80, 0.90)
	e.fog_depth_begin = 200.0
	e.fog_depth_end = 340.0
	env.environment = e
	add_child(env)

	# Soare jos (22 grade) din SV, ca in tema Kyoto: umbre pornite, o cascada pe 90 m.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-22.0, 135.0, 0.0)
	sun.light_energy = sun_energy
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)

	var zc := -LENGTH * 0.5
	_box("Culoar", Vector3(HALF_GAP * 2.0, 1.0, LENGTH + 200.0), Vector3(0, -0.5, zc + 100.0),
		Palette.ASPHALT, true)
	for s: float in [-1.0, 1.0]:
		_box("Teren", Vector3(60.0, 1.0, LENGTH + 200.0),
			Vector3(s * (HALF_GAP + 30.0), -0.52, zc + 100.0), ground_slot, false)
		# Perete colizor continuu (frecare mare, ricoseu mic) — invizibil, ca in brief §3:
		# aspectul il dau portile.
		var wall := StaticBody3D.new()
		wall.collision_layer = 1
		var pm := PhysicsMaterial.new()
		pm.friction = 1.0
		pm.bounce = 0.1
		wall.physics_material_override = pm
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(1.0, 8.0, LENGTH)
		cs.shape = bs
		wall.add_child(cs)
		add_child(wall)
		wall.global_position = Vector3(s * (HALF_GAP + 0.5), 4.0, zc)
		if forest:
			# Padure: masa continua dincolo de stalpi, inalta, ca golurile sa dea in umbra.
			_box("Padure", Vector3(14.0, 22.0, LENGTH + 40.0),
				Vector3(s * (HALF_GAP + POST_W + 0.15 + 7.0), 11.0, zc), bg_slot, false)

	_gates()

	_car = (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(_car)
	_car.apply_data(GameState.CAR_DATA[0])
	_car.is_player = true
	_car.set_controller(SteerBot.new())
	_car.global_transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 0.5, 60.0))
	_car.race_active = true
	_car.linear_velocity = Vector3(0, 0, -SPEED)

	GameState.cam_distance_scale = 1.0
	GameState.cam_height_scale = 1.0
	GameState.cam_fov_scale = 1.0
	GameState.cam_follow_scale = 1.0
	_cam = ChaseCamera.new()
	add_child(_cam)
	_cam.target = _car
	_cam.apply_settings_for(ChaseCamera.REFERENCE_LENGTH)
	_cam.snap_behind()

	var zone := CameraZone.new()
	zone.size = Vector3(HALF_GAP * 2.0 + 2.0, 8.0, LENGTH + 30.0)
	zone.height = 2.4
	zone.ceiling = BEAM_Y
	zone.look_height = 1.4
	add_child(zone)
	zone.global_position = Vector3(0, 0, zc)


## MOD REAL: pista Track18 intreaga, masina pe axa benzii E' cu camera de joc.
func _build_real() -> void:
	var packed := load(GameState.TRACK_SCENES[real_idx]) as PackedScene
	_track = packed.instantiate() as Track
	_tunnel = _track.get_node_or_null("ToriiTunel") as ToriiTunnel
	if _tunnel == null:
		push_error("ProbeFlicker: pista nu are ToriiTunel")
		get_tree().quit(2)
		return
	if sabotage == "forest_off" or sabotage == "both" or sabotage == "bright" or sabotage == "red_flash":
		_tunnel.forest_enabled = false
	if sabotage == "red_flash":
		_tunnel.spacing = 6.0
	if sabotage == "gap24" or sabotage == "both":
		_tunnel.spacing = 2.4
	add_child(_track)
	var waited := 0
	while not _tunnel.built and waited < 900:
		await get_tree().process_frame
		waited += 1
	for _i in 10:
		await get_tree().physics_frame
	if not _tunnel.built:
		push_error("ProbeFlicker: ToriiTunnel nu s-a construit")
		get_tree().quit(2)
		return
	var route := _track.route_at(1)
	if sabotage == "bright":
		_add_bright_wall(route, Color(0.92, 0.95, 1.0))
	elif sabotage == "red_flash":
		# fundal negru + porti rare: rosul saturat apare si dispare in benzile laterale
		_add_bright_wall(route, Color(0.0, 0.0, 0.0))
	var start_d := maxf(_tunnel.tunnel_start_dist - 45.0, 1.0)
	var i0 := 0
	while i0 < route.baked.size() - 2 and route.dists[i0] < start_d:
		i0 += 1
	var dir := (route.baked[i0 + 1] - route.baked[i0])
	dir.y = 0.0
	dir = dir.normalized()
	_car = (load(CAR_SCENE) as PackedScene).instantiate() as Car
	_car.track = _track
	add_child(_car)
	_car.apply_data(GameState.CAR_DATA[0])
	_car.is_player = true
	var bot := LaneBot.new()
	bot.route = route
	bot.idx = i0
	_car.set_controller(bot)
	_car.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP),
		route.baked[i0] + Vector3.UP * 0.6)
	_car.route = 1
	_car.road_index = i0
	_car.race_active = true
	_car.linear_velocity = dir * SPEED
	GameState.cam_distance_scale = 1.0
	GameState.cam_height_scale = 1.0
	GameState.cam_fov_scale = 1.0
	GameState.cam_follow_scale = 1.0
	_cam = ChaseCamera.new()
	add_child(_cam)
	_cam.target = _car
	_cam.apply_settings_for(ChaseCamera.REFERENCE_LENGTH)
	_cam.snap_behind()


## Sabotajul `bright`: in locul padurii, un perete luminos (alb, fara umbrire) la
## 4,6 m de axa pe ambele parti — golurile dintre porti dau intr-o lumina plata,
## ca si cum in spatele tunelului ar fi cer. Sonda trebuie sa PICE: altfel masuratoarea
## pe pista reala e oarba (acelasi rol ca `sparse_sky` pe culoarul sintetic).
func _add_bright_wall(route: TrackRoute, color: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sgn: float in [-1.0, 1.0]:
		for i in route.baked.size() - 1:
			if route.dists[i] < _tunnel.tunnel_start_dist - 10.0 or route.dists[i] > _tunnel.tunnel_end_dist + 10.0:
				continue
			var a := route.baked[i] + route.side_at(i) * 4.6 * sgn
			var b := route.baked[i + 1] + route.side_at(i + 1) * 4.6 * sgn
			var a1 := a + Vector3.UP * 16.0
			var b1 := b + Vector3.UP * 16.0
			for v in [a, a1, b, a1, b1, b]:
				st.add_vertex(v)
	st.generate_normals()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	_track.add_child(mi)


## Portile ca UN MultiMesh (un mesh, un material de paleta): doi stalpi + kasagi.
func _gates() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for s: float in [-1.0, 1.0]:
		_add_box(st, Vector3(s * (HALF_GAP + POST_W * 0.5), BEAM_Y * 0.5, 0.0),
			Vector3(POST_W, BEAM_Y, depth), Palette.LAVA_ORANGE)
	_add_box(st, Vector3(0, BEAM_Y + KASAGI_H * 0.5, 0.0),
		Vector3(KASAGI_HALF * 2.0, KASAGI_H, depth + 0.1), Palette.LOG_DARK)
	var mesh := st.commit()
	mesh.surface_set_material(0, _mat)
	var n := int(floor(LENGTH / spacing))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = n
	for i in n:
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY,
			Vector3(0, 0, -(spacing * 0.5 + i * spacing))))
	var mi := MultiMeshInstance3D.new()
	mi.name = "PortiTorii"
	mi.multimesh = mm
	mi.custom_aabb = AABB(Vector3(-6, 0, -LENGTH - 2), Vector3(12, 8, LENGTH + 4))
	add_child(mi)


func _box(nm: String, size: Vector3, at: Vector3, slot: int, solid: bool) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(st, Vector3.ZERO, size, slot)
	var mesh := st.commit()
	mesh.surface_set_material(0, _mat)
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = 1 | Track.CAMERA_BLOCKER_LAYER
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		body.add_child(cs)
		body.add_child(mi)
		add_child(body)
		body.global_position = at
	else:
		add_child(mi)
		mi.global_position = at


## Cutie cu UV colapsat pe centrul slotului de paleta (ca restul prop-urilor).
func _add_box(st: SurfaceTool, c: Vector3, size: Vector3, slot: int) -> void:
	var h := size * 0.5
	var uv := Palette.uv(slot)
	var faces := [
		[Vector3.UP, Vector3(-1, 1, -1), Vector3(1, 1, -1), Vector3(1, 1, 1), Vector3(-1, 1, 1)],
		[Vector3.DOWN, Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, -1, -1), Vector3(-1, -1, -1)],
		[Vector3.RIGHT, Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(1, 1, -1), Vector3(1, -1, -1)],
		[Vector3.LEFT, Vector3(-1, -1, -1), Vector3(-1, 1, -1), Vector3(-1, 1, 1), Vector3(-1, -1, 1)],
		[Vector3.BACK, Vector3(-1, -1, 1), Vector3(-1, 1, 1), Vector3(1, 1, 1), Vector3(1, -1, 1)],
		[Vector3.FORWARD, Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(-1, 1, -1), Vector3(-1, -1, -1)],
	]
	for f in faces:
		var nrm: Vector3 = f[0]
		var vs: Array[Vector3] = []
		for k in range(1, 5):
			vs.append(c + (f[k] as Vector3) * h)
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_normal(nrm)
			st.set_uv(uv)
			st.set_color(Color.WHITE)
			st.add_vertex(vs[idx])
