extends Node
## Petalele hortensiilor din serpentinele Track25 (scenes/props/sf_hydrangea_petals.gd; brief
## san_francisco.md §7 pasul 6). O masina reala pleaca de pe banda scurtaturii, de langa acul 2, si
## intra cu gazul la fund in blocul solid al stratului, apoi RAMANE impinsa in el 4 s (freaca zidul).
## Verifica:
##   1. lovitura arunca petale (cel putin o rafala);
##   2. anti-spam: rafalele raman <= 1 + durata / pauza stratului, oricate impacturi ar raporta
##      masina cat se freaca de zid;
##   3. nicio coliziune noua: nodul petalelor nu are corpuri sau zone sub el.
## Sabotaj (`--sabotaj`): pauza stratului 0 si fara pauza globala nu exista in cod, deci sabotajul
## e pauza 0 -> rafalele trebuie sa depaseasca plafonul (garda pica).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfPetals.tscn [-- --sabotaj]
## CAPTURA (cu FEREASTRA, serial; camera reala de joc, in spatele masinii), la prima rafala:
##   godot --path . res://tools/ProbeSfPetals.tscn -- --capture=res://snapshots/sf_petale.png

const SCENE: String = "res://scenes/tracks/Track25.tscn"
const PUSH_S: float = 4.0

var _impacts: int = 0


func _ready() -> void:
	var capture := ""
	var sabotage := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture = arg.trim_prefix("--capture=")
		elif arg == "--sabotaj":
			sabotage = true
	var track := (load(SCENE) as PackedScene).instantiate() as Track
	add_child(track)
	for _f in 4:
		await get_tree().physics_frame
	var petals: Node = track.get_node_or_null("SerpentineGri/HortensiiPetale")
	if petals == null:
		print("probe_sf_petals: Track25 n-are SerpentineGri/HortensiiPetale")
		get_tree().quit(2)
		return
	if sabotage:
		petals.cooldown_s = 0.0
	var tops: PackedVector3Array = petals.bed_tops
	var bed := tops[1]
	# startul: punctul benzii la ~14 m de centrul stratului, cu fata spre el
	var route := track.route_at(1)
	var start := route.baked[0]
	var best := INF
	for p in route.baked:
		var d := absf(Vector2(p.x - bed.x, p.z - bed.z).length() - 14.0)
		if d < best:
			best = d
			start = p
	var dir := Vector3(bed.x - start.x, 0.0, bed.z - start.z).normalized()
	var car := (load("res://scenes/cars/Car.tscn") as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[2])
	car.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), start + Vector3.UP * 0.6)
	car.velocity = dir * 12.0
	car.linear_velocity = dir * 12.0
	var ctl := PushPilot.new()
	ctl.target = bed
	car.set_controller(ctl)
	car.race_active = true
	# nodul petalelor cauta masinile din 0,5 in 0,5 s; masina sondei apare dupa pista si loveste in
	# ~0,3 s, deci ii cerem o cautare acum (in cursa, masinile exista de la start)
	petals.set("_scan_left", 0.0)
	car.impact.connect(func(_c: Car, kind: StringName, _s: float, _n: Vector3, _p: Vector3, other: Node) -> void:
		if kind == &"wall" and other != null and other.name == &"SerpStraturi":
			_impacts += 1)
	var cam: Camera3D = null
	if capture != "":
		cam = Camera3D.new()
		add_child(cam)
		cam.current = true
		cam.fov = ChaseCamera.BASE_FOV
	var t := 0.0
	var first_burst := -1.0
	var b0: int = petals.bursts
	while t < 2.5 + PUSH_S:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		if cam != null:
			var f := -car.global_transform.basis.z
			f.y = 0.0
			f = f.normalized() if f.length() > 0.01 else dir
			cam.global_position = car.global_position - f * ChaseCamera.DEFAULT_DISTANCE \
				+ Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
			cam.look_at(car.global_position + f * ChaseCamera.LOOK_AHEAD + Vector3.UP * ChaseCamera.LOOK_HEIGHT)
		if first_burst < 0.0 and int(petals.bursts) > b0:
			first_burst = t
		if cam != null and first_burst >= 0.0 and t - first_burst >= 0.15:
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			img.save_png(capture)
			print("SNAPSHOT: ", ProjectSettings.globalize_path(capture))
			get_tree().quit(0)
			return
	var bursts: int = int(petals.bursts) - b0
	# FRECAREA, sintetic: 30 de impacturi in blocul solid in 1,5 s (cate unul la 3 cadre, ca o
	# masina care se freaca de zid si raporteaza peste prag), pe acelasi strat. Plafonul: 1 + 1,5 /
	# pauza stratului. Cu pauza 0 (sabotaj), doar pauza globala a PropDebris (0,12 s) le mai rareste.
	var body: Node = track.get_node("SerpentineGri/SerpStraturi")
	var b1: int = petals.bursts
	for k in 30:
		for _f in 3:
			await get_tree().physics_frame
		petals._on_impact(car, &"wall", 8.0, Vector3.RIGHT, Vector3(bed.x + 8.0, bed.y, bed.z), body)
	var rub: int = int(petals.bursts) - b1
	# plafonul vine din pauza CERUTA (1 s), nu din cea citita de pe nod: altfel sabotajul s-ar ierta singur
	var cap := 1 + int(ceil(1.5 / 1.0))
	var colliders := 0
	for c in petals.get_children():
		if c is CollisionObject3D:
			colliders += 1
	print("")
	print("=== PETALELE HORTENSIILOR (Track25, acul 2)%s ===" % (" — SABOTAJ: pauza 0" if sabotage else ""))
	print("  impacturi in blocul solid: %d, rafale de petale: %d (prima la %.2f s), refuzate de pauza: %d" % [
		_impacts, bursts, first_burst, int(petals.refused)])
	var fail := 0
	fail += _check(bursts >= 1, "lovitura arunca petale: %d rafale" % bursts)
	fail += _check(rub <= cap, "anti-spam: 30 de impacturi in 1,5 s pe acelasi strat -> %d rafale (plafon %d)" % [rub, cap])
	fail += _check(colliders == 0, "nicio coliziune noua sub nodul petalelor (%d)" % colliders)
	print("VERDICT: %s" % ("OK" if fail == 0 else "PICAT (%d)" % fail))
	get_tree().quit(0 if fail == 0 else 1)


func _check(ok: bool, what: String) -> int:
	print("  [%s] %s" % ["OK " if ok else "PICAT", what])
	return 0 if ok else 1


class PushPilot extends CarController:
	var target := Vector3.ZERO
	func get_steer() -> float:
		var p := car.global_position
		var f := -car.global_transform.basis.z
		f.y = 0.0
		var d := target - p
		d.y = 0.0
		if f.length() < 0.01 or d.length() < 0.01:
			return 0.0
		var ang := atan2(f.normalized().cross(d.normalized()).y, f.normalized().dot(d.normalized()))
		return clampf(ang * 2.5, -1.0, 1.0)
	func get_throttle() -> float:
		return 1.0
