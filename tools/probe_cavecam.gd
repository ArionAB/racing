extends Node
## PRESETUL DE CAMERA IN CAVERN (Cappadocia §2.0, §7.1a): se vede tavanul?
##
## Ruleaza headless. Construieste o sala-test de 15 m inaltime cu un put de
## lumina in tavan, plimba masina prin ea si masoara, in ordine:
##
##  (i)   GEOMETRIA, A/B: marginea de sus a frustumului (grade) si distanta de
##        la care intra un tavan de 15/16 m in cadru, cu presetul stins si
##        pornit. Aici se verifica cifrele din brief.
##  (ii)  PRESETUL AJUNGE VIU la camera: cu masina in sala, valorile efective
##        (height/look_height/fov) sunt cele cerute.
##  (iii) TRANZITIA dureaza `blend_time`, si e monotona (fara pocnet).
##  (iv)  TAVANUL E CHIAR IN CADRU: testul direct, nu trigonometric — se ia
##        camera vie si se intreaba `is_position_in_frustum` pe punctul din
##        tavan aflat la 25 m in fata masinii. Si putul de lumina la fel.
##  (v)   `_unclip` nu prabuseste camera in masina: sala de 15 m e destul de
##        inalta ca bratul de 12.5 m sa incapa.
##
## Rulare:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCavecam.tscn
##   ... -- --no-preset      (martorul: aceeasi sala, fara CameraZone)
##
## Iese cu 1 daca pica un verdict, ca sa poata fi garda in CI.

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"

## Sala de test: tavan la 15 m (minimul cerut de brief pentru sali).
const HALL_HEIGHT: float = 15.0
const HALL_LENGTH: float = 120.0
const HALL_HALF_WIDTH: float = 9.0
## Al doilea tavan verificat pe hartie: sala 1 din brief are 16 m.
const CEILING_B: float = 16.0
## Distanta la care briefu cere sa se vada tavanul.
const TARGET_DIST: float = 25.0
## Putul de lumina: cade pe drum, la distanta asta fata de centrul salii.
const SHAFT_Z: float = -25.0
const SHAFT_RADIUS: float = 2.5

var _fails: int = 0
var _no_preset: bool = false
var _shot: bool = false
var _cam: ChaseCamera
var _car: Car
var _zone: CameraZone


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_no_preset = "--no-preset" in args
	_shot = "--shot" in args
	print("=== PRESET CAMERA IN CAVERN (%s) ==="
		% ("MARTOR, fara preset" if _no_preset else "cu preset"))
	if _shot:
		await _capture()
		return
	_report_geometry()
	await _build_world()
	await _check_live()
	await _check_frustum()
	print("=== %s ===" % ("PICAT: %d verdicte" % _fails if _fails > 0
		else "TOATE OK"))
	get_tree().quit(1 if _fails > 0 else 0)


## Captura din sala, prin CHIAR camera jocului (nu MEASURE_* din snapshot.gd,
## care sunt inghetate si n-ar arata presetul).
##
## Ruleaza CU FEREASTRA — randarea nu merge headless (vezi antetul lui
## tools/snapshot.gd). Masina e pusa la 25 m de peretele din fund, adica exact
## distanta despre care intreaba briefu.
func _capture() -> void:
	await _build_world()
	# La 25 m de putul de lumina, cu botul spre el: exact intrebarea din brief
	# (§7.1a) — de la 25 m se vad si tavanul, si putul? Botul spre -Z inseamna
	# rotatie 0, fiindca -Z e inainte in Godot.
	_car.global_transform = Transform3D(Basis.IDENTITY,
		Vector3(0.0, 0.5, SHAFT_Z + TARGET_DIST))
	_cam.snap_behind()
	await _frames(90)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var dir := ProjectSettings.globalize_path("res://snapshots")
	DirAccess.make_dir_recursive_absolute(dir)
	var out := "%s/cavecam_%s.png" % [dir,
		"fara_preset" if _no_preset else "cu_preset"]
	img.save_png(out)
	print("  camera la y=%.2f, fov=%.1f, panta %.2f°"
		% [_cam.global_position.y, _cam.eff_fov(), _cam.pitch_degrees()])
	print("SNAPSHOT: ", out)
	get_tree().quit(0)


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


# ---------------------------------------------------------------- (i) hartie

## Cifrele pe hartie, ca sa se poata compara cu briefu inainte de orice fizica.
func _report_geometry() -> void:
	print("\n--- (i) geometria frustumului (A/B, derivat) ---")
	var d := ChaseCamera.DEFAULT_DISTANCE
	var la := ChaseCamera.LOOK_AHEAD
	var rows := [
		["implicit", ChaseCamera.DEFAULT_HEIGHT, ChaseCamera.LOOK_HEIGHT,
			ChaseCamera.BASE_FOV],
		["preset", 6.5, 1.4, ChaseCamera.BASE_FOV + 6.0],
	]
	print("  %-9s %6s %7s %6s %9s %10s %11s"
		% ["camera", "h", "look_h", "fov", "panta", "sus", "tavan 15"])
	for r in rows:
		var h := float(r[1])
		var lh := float(r[2])
		var fov := float(r[3])
		var pitch := rad_to_deg(atan((h - lh) / (d + la)))
		var top := ChaseCamera.top_edge_deg(h, lh, d, la, fov)
		var e15 := ChaseCamera.ceiling_entry_distance(HALL_HEIGHT, h, top)
		print("  %-9s %6.2f %7.2f %6.1f %8.2f° %+9.2f° %11s"
			% [r[0], h, lh, fov, pitch, top,
				("nu intra" if is_inf(e15) else "%.1f m" % e15)])
	print("  distanta de la care intra tavanul in cadru:")
	for ceil: float in [HALL_HEIGHT, CEILING_B]:
		var line := "    tavan %4.1f m: " % ceil
		for r in rows:
			var h := float(r[1])
			var top := ChaseCamera.top_edge_deg(h, float(r[2]), d, la,
				float(r[3]))
			var e := ChaseCamera.ceiling_entry_distance(ceil, h, top)
			line += " %s %-9s" % [r[0],
				("nu intra" if is_inf(e) else "%.1f m" % e)]
		print(line)
	var top_preset := ChaseCamera.top_edge_deg(6.5, 1.4, d, la,
		ChaseCamera.BASE_FOV + 6.0)
	var entry := ChaseCamera.ceiling_entry_distance(HALL_HEIGHT, 6.5,
		top_preset)
	_verdict(entry <= TARGET_DIST,
		"cu presetul, tavanul de %.0f m intra de la %.1f m (cerut <= %.0f m)"
			% [HALL_HEIGHT, entry, TARGET_DIST])
	var top_def := ChaseCamera.top_edge_deg(ChaseCamera.DEFAULT_HEIGHT,
		ChaseCamera.LOOK_HEIGHT, d, la, ChaseCamera.BASE_FOV)
	var entry_def := ChaseCamera.ceiling_entry_distance(HALL_HEIGHT,
		ChaseCamera.DEFAULT_HEIGHT, top_def)
	_verdict(entry_def > TARGET_DIST * 1.5,
		("fara preset tavanul intra abia la %.1f m, mult peste %.0f m — deci "
			+ "presetul chiar e necesar") % [entry_def, TARGET_DIST])


# ------------------------------------------------------------------ lumea

## Sala: podea, doua ziduri, tavan la 15 m, cu o fanta de put in tavan.
##
## Tot ce e geometrie de sala sta si pe CAMERA_BLOCKER_LAYER: altfel `_unclip`
## n-ar vedea peretii si camera ar sta linistita in stanca (vezi antetul
## Track.CAMERA_BLOCKER_LAYER — layerul se pune pe faleze si pe sol).
func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.02, 0.015, 0.01)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.35, 0.2)
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-75.0, 20.0, 0.0)
	sun.light_energy = 1.2
	add_child(sun)

	_slab("Podea", Vector3(HALL_HALF_WIDTH * 2.0, 1.0, HALL_LENGTH),
		Vector3(0.0, -0.5, 0.0), Color(0.35, 0.28, 0.2))
	# Tavanul: doua placi, cu o fanta intre ele = putul de lumina.
	var half := (HALL_LENGTH - SHAFT_RADIUS * 2.0) * 0.5
	for s: float in [-1.0, 1.0]:
		var z := SHAFT_Z + s * (half * 0.5 + SHAFT_RADIUS)
		_slab("Tavan%s" % ("A" if s < 0.0 else "B"),
			Vector3(HALL_HALF_WIDTH * 2.0, 1.0, half),
			Vector3(0.0, HALL_HEIGHT + 0.5, z), Color(0.3, 0.22, 0.16))
	for s: float in [-1.0, 1.0]:
		_slab("Zid%s" % ("L" if s < 0.0 else "R"),
			Vector3(1.0, HALL_HEIGHT, HALL_LENGTH),
			Vector3(s * (HALL_HALF_WIDTH + 0.5), HALL_HEIGHT * 0.5, 0.0),
			Color(0.32, 0.24, 0.18))
	_light_shaft()

	_car = (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(_car)
	_car.apply_data(GameState.CAR_DATA[0])
	_car.is_player = true
	_car.global_transform = Transform3D(Basis.IDENTITY,
		Vector3(0.0, 0.5, HALL_LENGTH * 0.5 - 10.0))
	_car.race_active = true

	# Setarile jucatorului se pun pe 1.0 INAINTE de `apply_settings_for`:
	# altfel sonda masoara sliderele de pe masina dezvoltatorului, nu designul.
	# (Prima rulare a masurat fov 53.6 in loc de 74 — fisierul de setari avea
	# fov_scale la minimul de 0.7. Vezi verdictul despre interactiunea
	# preset x setari.)
	GameState.cam_distance_scale = 1.0
	GameState.cam_height_scale = 1.0
	GameState.cam_fov_scale = 1.0
	GameState.cam_follow_scale = 1.0
	_cam = ChaseCamera.new()
	add_child(_cam)
	_cam.target = _car
	_cam.apply_settings_for(ChaseCamera.REFERENCE_LENGTH)
	_cam.snap_behind()

	if not _no_preset:
		_zone = CameraZone.new()
		_zone.size = Vector3(HALL_HALF_WIDTH * 2.0, 8.0, HALL_LENGTH)
		add_child(_zone)
		_zone.global_position = Vector3.ZERO
	await get_tree().physics_frame


func _slab(nm: String, size: Vector3, at: Vector3, tint: Color) -> void:
	var body := StaticBody3D.new()
	body.name = nm
	# Layerul implicit (masina calca pe el) + layerul de blocare a camerei.
	body.collision_layer = 1 | Track.CAMERA_BLOCKER_LAYER
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mesh.material = mat
	mi.mesh = mesh
	body.add_child(mi)
	add_child(body)
	body.global_position = at


## Coloana de lumina din put: un con cu alpha (brief §4 — nu volumetrie).
func _light_shaft() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "PutDeLumina"
	var cone := CylinderMesh.new()
	cone.top_radius = SHAFT_RADIUS
	cone.bottom_radius = SHAFT_RADIUS * 1.6
	cone.height = HALL_HEIGHT
	# Primitiva creata in cod: rezolutia se seteaza explicit (CLAUDE.md).
	cone.radial_segments = 12
	cone.rings = 1
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.78, 0.4, 0.28)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.72, 0.35)
	cone.material = mat
	mi.mesh = cone
	add_child(mi)
	mi.global_position = Vector3(0.0, HALL_HEIGHT * 0.5, SHAFT_Z)


# ------------------------------------------------------- (ii)(iii) viu

func _frames(n: int) -> void:
	for _f in n:
		await get_tree().physics_frame


## Presetul ajunge la camera, si tranzitia are durata ceruta.
func _check_live() -> void:
	print("\n--- (ii) presetul ajunge la camera vie ---")
	await _frames(120)
	var eh := _cam.eff_height()
	var elh := _cam.eff_look_height()
	var efov := _cam.eff_fov()
	print("    inauntru: h=%.2f look_h=%.2f fov=%.1f (panta %.2f°)"
		% [eh, elh, efov, _cam.pitch_degrees()])
	if _no_preset:
		_verdict(is_equal_approx(eh, _cam.height),
			"martor: camera ramane la implicit (h=%.2f)" % eh)
		return
	_verdict(absf(eh - 6.5) < 0.05 and absf(elh - 1.4) < 0.05
			and absf(efov - (ChaseCamera.BASE_FOV + 6.0)) < 0.1,
		"valorile efective sunt cele ale presetului")
	var top := ChaseCamera.top_edge_deg(eh, elh, _cam.distance,
		_cam.look_ahead, efov)
	print("    marginea de sus, pe camera vie: %+.2f°" % top)

	print("\n--- (iii) tranzitia ---")
	# Scoate masina din zona si masoara cate cadre dureaza revenirea.
	_car.global_position = Vector3(0.0, 0.5, HALL_LENGTH * 0.5 + 40.0)
	await get_tree().physics_frame
	var frames := 0
	var prev := 1.0
	var monotone := true
	while frames < 240:
		await get_tree().physics_frame
		frames += 1
		var amt := _amount()
		if amt > prev + 0.001:
			monotone = false
		prev = amt
		if amt <= 0.0001:
			break
	var secs := float(frames) / 60.0
	print("    revenire la implicit in %d cadre (%.2f s), cerut %.2f s"
		% [frames, secs, 0.5])
	_verdict(absf(secs - 0.5) < 0.12, "tranzitia dureaza ~0.5 s")
	_verdict(monotone, "tranzitia e monotona (fara pocnet)")
	# Inapoi in sala pentru testul de frustum.
	_car.global_position = Vector3(0.0, 0.5, HALL_LENGTH * 0.5 - 10.0)
	await _frames(90)


func _amount() -> float:
	return float(_cam.get("_zone_amount"))


# ------------------------------------------------------------ (iv)(v) cadru

## Testul direct: punctul din tavan de la 25 m in fata masinii e in cadru?
##
## Trigonometria de la (i) spune ce ar trebui sa se vada; asta intreaba chiar
## camera. Daca cele doua nu sunt de acord, calculul e gresit, nu motorul.
func _check_frustum() -> void:
	print("\n--- (iv) ce e CHIAR in cadru (camera vie) ---")
	var cam: Camera3D = null
	for c in _cam.get_children():
		cam = c as Camera3D
		if cam != null:
			break
	if cam == null:
		_verdict(false, "n-am gasit Camera3D sub rig")
		return
	print("    camera la y=%.2f, fov=%.1f" % [_cam.global_position.y, cam.fov])
	var fwd := -_car.global_transform.basis.z
	var seen_any := false
	for dist: float in [15.0, 20.0, TARGET_DIST, 35.0, 50.0]:
		var p := _car.global_position + fwd * dist
		p.y = HALL_HEIGHT
		var vis := cam.is_position_in_frustum(p)
		print("    tavan la %5.1f m in fata: %s"
			% [dist, "IN CADRU" if vis else "in afara"])
		if absf(dist - TARGET_DIST) < 0.1:
			seen_any = vis
	if _no_preset:
		_verdict(not seen_any,
			("martor: tavanul NU se vede de la %.0f m — asta e chiar problema "
				+ "pe care o rezolva presetul") % TARGET_DIST)
	else:
		_verdict(seen_any, "tavanul se vede de la %.0f m" % TARGET_DIST)
	var shaft := Vector3(0.0, HALL_HEIGHT - 1.0, SHAFT_Z)
	var dshaft := _car.global_position.distance_to(shaft)
	var vshaft := cam.is_position_in_frustum(shaft)
	print("    gura putului de lumina (la %.0f m): %s"
		% [dshaft, "IN CADRU" if vshaft else "in afara"])
	if not _no_preset:
		_verdict(vshaft, "putul de lumina se vede")

	print("\n--- (v) _unclip nu prabuseste camera ---")
	var arm := _cam.global_position.distance_to(_car.global_position)
	print("    bratul camerei: %.2f m (nominal %.2f), camera la y=%.2f"
		% [arm, _cam.distance, _cam.global_position.y])
	_verdict(arm > 4.0,
		"camera nu e prabusita in masina (brat %.2f m > 4 m)" % arm)
