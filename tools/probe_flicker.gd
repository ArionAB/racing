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
## NEMASURAT: pragul special de rosu saturat al WCAG, si conditia "luminanta celei mai
## intunecate imagini < 0.8" (ignorata: ar scadea doar numarul de flash-uri).
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

var variant: String = "dense_dark"
var spacing: float = 1.2
var depth: float = 0.7
var bg_slot: int = Palette.TROPICAL_GREEN
var ground_slot: int = Palette.TROPICAL_GREEN
var sun_energy: float = 1.7
var amb_energy: float = 0.55
var forest: bool = true
var shots: bool = false

var _car: Car
var _cam: ChaseCamera
var _mat: StandardMaterial3D


class SteerBot extends CarController:
	func get_steer() -> float:
		var fwd := -car.global_basis.z
		return clampf(1.6 * fwd.x + 0.25 * car.global_position.x, -1.0, 1.0)


func _ready() -> void:
	_parse()
	await _run()


func _parse() -> void:
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--variant="):
			variant = a.get_slice("=", 1)
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
	_mat = Palette.world_material()
	_build_world()
	await get_tree().physics_frame
	var n_gates := int(floor(LENGTH / spacing))
	print("=== PROBE FLICKER: %s | %d porti, pas %.2f m, adancime %.2f m (gol %.2f m) ===" %
		[variant, n_gates, spacing, depth, spacing - depth])
	var zs: Array[float] = []
	var vs: Array[float] = []
	var xs: Array[float] = []
	var lum_l: Array[float] = []
	var lum_r: Array[float] = []
	var lum_a: Array[float] = []
	var shot_marks: Array[float] = [-20.0, -50.0, -80.0, -110.0]
	var frame := 0
	while frame < 1500:
		await RenderingServer.frame_post_draw
		frame += 1
		var z := _car.global_position.z
		if z < -(LENGTH - 8.0):
			break
		if z > -12.0:
			continue
		var img := get_viewport().get_texture().get_image()
		var l := _regions(img)
		lum_l.append(l[0])
		lum_a.append(l[1])
		lum_r.append(l[2])
		zs.append(z)
		vs.append(_car.linear_velocity.length())
		xs.append(_car.global_position.x)
		if shots and not shot_marks.is_empty() and z < shot_marks[0]:
			shot_marks.pop_front()
			var dir := ProjectSettings.globalize_path("res://snapshots")
			DirAccess.make_dir_recursive_absolute(dir)
			img.save_png("%s/flicker_%s_%d.png" % [dir, variant, int(-z)])
	var n := lum_a.size()
	if n < 60:
		print("SONDA MOARTA: doar %d cadre in culoar (frame=%d, z=%.1f)" % [n, frame, _car.global_position.z])
		get_tree().quit(2)
		return
	var fails := 0
	var dead := _dead(lum_l) or _dead(lum_r) or _dead(lum_a)
	print("cadre analizate: %d (%.2f s) | viteza %.1f..%.1f m/s | |x| max %.2f m"
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
	if dead:
		print("SONDA MOARTA: luminanta e constanta pe cadre (imagine goala/neconectata)")
		get_tree().quit(2)
		return
	print("=== %s: %s ===" % [variant, "PICAT (%d regiuni)" % fails if fails > 0 else "PASS"])
	get_tree().quit(1 if fails > 0 else 0)


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
	var third := w / 3
	for y in h:
		for x in w:
			var o := (y * w + x) * 3
			var lum := 0.2126 * _LIN[d[o]] + 0.7152 * _LIN[d[o + 1]] + 0.0722 * _LIN[d[o + 2]]
			sums[1] += lum
			cnt[1] += 1
			if x < third:
				sums[0] += lum
				cnt[0] += 1
			elif x >= w - third:
				sums[2] += lum
				cnt[2] += 1
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
