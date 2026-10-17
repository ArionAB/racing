extends Node
## Garda pasului 5 al carierei: fantoma din contratimp. Headless.
##
## Rulare: godot --headless --fixed-fps 60 --path . res://tools/ProbeGhost.tscn
##
## Memoriile `garda-verde-pe-zero-masuratori` si `efecte-invizibile-nu-se-numara`:
## fiecare sectiune NUMARA (esantioane, mesh-uri, corpuri fizice, bytes), iar
## sub MIN_CHECKS verdictul pica — o sonda care sare sectiuni nu e verde.
##
## Traiectorie sintetica cunoscuta: cerc de raza 50 m, 3 "ture" a 20 s, caroseria
## rotita pe tangenta. Cu ea se vede (1) ca acumulatorul da 20 Hz, (2) ca
## serializarea nu pierde nimic, (3) ca interpolarea nu taie colturi.

const TMP_DIR := "user://probe_ghosts_tmp/"
const MIN_CHECKS := 60
const RADIUS := 50.0
const LAP_S := 20.0
const RUN_S := 60.0
const TRACK := &"probe_track"

var _fails: Array[String] = []
var _checks: int = 0
var _real_dir: String


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(what)
		print("  FAIL: ", what)


## Pozitia/rotatia adevarata la t secunde.
func _truth(t: float) -> Transform3D:
	var a := TAU * t / LAP_S
	var pos := Vector3(RADIUS * cos(a), 0.0, RADIUS * sin(a))
	return Transform3D(Basis(Vector3.UP, -a), pos)


func _ready() -> void:
	_real_dir = Career.ghost_dir
	Career.ghost_dir = TMP_DIR
	_clean()

	var data := await _record()
	_check_roundtrip(data)
	_check_files(data)
	await _check_ghost_car(data)

	_clean()
	Career.ghost_dir = _real_dir
	_check(_checks >= MIN_CHECKS, "au rulat doar %d verificari (< %d)" % [_checks, MIN_CHECKS])
	print("verificari: %d, esecuri: %d" % [_checks, _fails.size()])
	print("VERDICT: ", "OK" if _fails.is_empty() else "PROBLEMA (%d)" % _fails.size())
	get_tree().quit(0 if _fails.is_empty() else 1)


func _record() -> GhostData:
	print("=== INREGISTRARE ===")
	var mover := Node3D.new()
	add_child(mover)
	var rec := GhostRecorder.new()
	rec.target = mover
	add_child(rec)
	mover.global_transform = _truth(0.0)
	rec.start()
	var ticks := int(RUN_S * 60.0)
	for i in range(1, ticks + 1):
		mover.global_transform = _truth(float(i) / 60.0)
		await get_tree().physics_frame
	rec.stop()
	var n := rec.sample_count()
	print("  esantioane: %d (asteptat ~1201)" % n)
	_check(n >= 1190 and n <= 1210, "20 Hz x 60 s => 1190..1210 esantioane, sunt %d" % n)
	for i in 10:
		await get_tree().physics_frame
	_check(rec.sample_count() == n, "dupa stop() nu mai apar esantioane")
	var data := rec.build_data(TRACK, 2, 3, int(RUN_S * 1000.0))
	_check(data.samples.size() == n * 7, "7 float-uri per esantion")
	# Timpul esantioanelor: abatere de cel mult ~1 tick (acumulatorul prinde
	# pragul la urmatorul tick), nu mai mult.
	var max_pos_err := 0.0
	for k in range(0, n, 7):
		var truth := _truth(float(k) * 0.05)
		max_pos_err = maxf(max_pos_err,
			data.transform_at(float(k) * 50.0).origin.distance_to(truth.origin))
	print("  abatere de ceas max: %.3f m" % max_pos_err)
	_check(max_pos_err < 0.45,
		"esantioanele cad la ~k*50 ms (max %.3f m, un tick = 0.26 m)" % max_pos_err)
	mover.queue_free()
	rec.queue_free()
	return data


func _check_roundtrip(data: GhostData) -> void:
	print("=== ROUND-TRIP ===")
	var bytes := data.to_bytes()
	var back := GhostData.from_bytes(bytes)
	_check(back != null, "from_bytes intoarce date")
	if back == null:
		return
	print("  fisier: %d bytes" % bytes.size())
	_check(back.version == data.version, "version")
	_check(back.track_id == data.track_id, "track_id")
	_check(back.car_index == data.car_index, "car_index")
	_check(back.laps == data.laps, "laps")
	_check(back.rate_hz == data.rate_hz, "rate_hz")
	_check(back.total_ms == data.total_ms, "total_ms")
	_check(back.samples.size() == data.samples.size(), "samples.size")
	var max_pos := 0.0
	var max_deg := 0.0
	var max_radius_err := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 50:
		var t := rng.randf_range(0.0, RUN_S * 1000.0)
		var a := data.transform_at(t)
		var b := back.transform_at(t)
		var d := a.origin.distance_to(b.origin)
		var deg := rad_to_deg(a.basis.get_rotation_quaternion().angle_to(
			b.basis.get_rotation_quaternion()))
		max_pos = maxf(max_pos, d)
		max_deg = maxf(max_deg, deg)
		_check(d < 0.01, "pozitie dupa round-trip la %.0f ms (%.4f m)" % [t, d])
		_check(deg < 0.5, "rotatie dupa round-trip la %.0f ms (%.3f deg)" % [t, deg])
		# Intre doua esantioane (mijlocul intervalului), pe cerc.
		var mid := (float(rng.randi_range(0, data.sample_count() - 2)) + 0.5) * 50.0
		var p := back.transform_at(mid).origin
		var r := Vector2(p.x, p.z).length()
		max_radius_err = maxf(max_radius_err, absf(r - RADIUS))
		_check(absf(r - RADIUS) < 0.5, "interpolare pe cerc la %.0f ms (raza %.3f)" % [mid, r])
	print("  eroare max round-trip: %.5f m / %.4f deg; abatere raza la interpolare: %.4f m"
		% [max_pos, max_deg, max_radius_err])
	# Limitele: inainte de primul / dupa ultimul.
	_check(data.transform_at(-500.0).origin.is_equal_approx(data.transform_at(0.0).origin),
		"inainte de primul = primul")
	_check(data.transform_at(1.0e9).origin.is_equal_approx(
		data.transform_at(float(data.sample_count() - 1) * 50.0).origin),
		"dupa ultimul = ultimul")
	# Fisier trunchiat / gol / versiune necunoscuta => null.
	_check(GhostData.from_bytes(bytes.slice(0, bytes.size() - 5)) == null, "fisier trunchiat respins")
	_check(GhostData.from_bytes(PackedByteArray()) == null, "fisier gol respins")
	var newer := bytes.duplicate()
	newer.encode_s32(0, 99)
	_check(GhostData.from_bytes(newer) == null, "versiune 99 respinsa")


func _read(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path)


func _check_files(data: GhostData) -> void:
	print("=== FISIER ===")
	var path := Career.ghost_path(TRACK)
	_check(path == TMP_DIR + "probe_track.bin", "ghost_path = ghost_dir/<id>.bin (%s)" % path)
	_check(Career.load_ghost(TRACK) == null, "fara fisier => load_ghost null")
	_check(Career.save_ghost_if_best(TRACK, data, 60000, 0), "prima cursa (best 0) scrie")
	_check(FileAccess.file_exists(path), "fisierul exista")
	var first := _read(path)
	_check(first == data.to_bytes(), "continutul = to_bytes()")
	var loaded := Career.load_ghost(TRACK)
	_check(loaded != null and loaded.samples.size() == data.samples.size(),
		"load_ghost citeste inapoi")

	var other := GhostData.from_bytes(data.to_bytes())
	other.car_index = 1
	_check(not Career.save_ghost_if_best(TRACK, other, 61000, 60000), "timp mai slab NU scrie")
	_check(_read(path) == first, "fisierul ramane neatins dupa timp mai slab")
	_check(not Career.save_ghost_if_best(TRACK, other, 60000, 60000), "timp egal NU scrie")
	_check(Career.save_ghost_if_best(TRACK, other, 59000, 60000), "timp mai bun scrie")
	var second := _read(path)
	_check(second != first, "fisierul s-a schimbat dupa timp mai bun")
	_check(Career.load_ghost(TRACK).car_index == 1, "fantoma noua are car_index 1")

	# Versiune mai noua: ignorata la citire, neatinsa la scriere.
	var future := PackedByteArray(second)
	future.encode_s32(0, 99)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_buffer(future)
	f.close()
	_check(Career.load_ghost(TRACK) == null, "versiune 99 => load_ghost null")
	_check(not Career.save_ghost_if_best(TRACK, data, 1000, 59000), "nu suprascrie versiunea 99")
	_check(_read(path) == future, "fisierul v99 ramane neatins")
	print("  fisier salvat: %d bytes" % first.size())


func _check_ghost_car(data: GhostData) -> void:
	print("=== GHOSTCAR ===")
	var g := GhostCar.new()
	add_child(g)
	g.setup(data)
	await get_tree().physics_frame
	var meshes := 0
	var bodies := 0
	var opaque := 0
	var materials := {}
	var stack: Array[Node] = [g]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			meshes += 1
			var m := mi.material_override as BaseMaterial3D
			if m == null or m.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
				opaque += 1
			else:
				materials[m] = true
			_check(mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
				"mesh %s fara umbra" % mi.name)
		if n is CollisionObject3D or n is CollisionShape3D:
			bodies += 1
		stack.append_array(n.get_children())
	print("  mesh-uri: %d, corpuri fizice: %d, fara transparenta: %d, materiale: %d"
		% [meshes, bodies, opaque, materials.size()])
	_check(meshes >= 1, "cel putin un MeshInstance3D (sunt %d)" % meshes)
	_check(bodies == 0, "zero corpuri/forme de coliziune (sunt %d)" % bodies)
	_check(opaque == 0, "toate mesh-urile au material transparent")
	_check(materials.size() == 1, "un singur material partajat (sunt %d)" % materials.size())
	g.set_clock_ms(10000.0)
	var want := data.transform_at(10000.0).origin
	var err := g.global_transform.origin.distance_to(want)
	print("  la 10 s: eroare %.5f m" % err)
	_check(err < 0.01, "set_clock_ms(10000) => transform_at(10000) (%.4f m)" % err)
	g.queue_free()


func _clean() -> void:
	var dir := DirAccess.open(TMP_DIR)
	if dir != null:
		for file in dir.get_files():
			dir.remove(file)
	DirAccess.remove_absolute(TMP_DIR)
