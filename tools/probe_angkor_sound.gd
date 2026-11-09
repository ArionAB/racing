extends Node
## SONDA SUNETULUI ANGKORULUI (Track24): tunet, trambita, scartait, ambianta.
## Fiecare verificare compara IDENTITATEA streamului (numele fisierului), nu doar ca
## a sunat ceva: un contor de redari trece si cand se aude sunetul gresit.
##
## Pe pista REALA (Track24.tscn instantiata), plus un RimBoulderHazard nou ca martor
## pentru implicit (Track19 / Monument Valley ramane pe `rock_warn`):
##   1. cablajul din .tscn: tunet (roll + crack), ambianta (jungla + ploaie), cele 3
##      blocuri ale dominoului pe `root_creak`, elefantul pe `elephant_trumpet`;
##   2. un fulger real (RainCycle + LightningFlash cu streamurile pistei) scoate un
##      tunet per fulger, iar streamul e roll sau crack, niciodata altceva; si cu
##      `reduce_flashes` tunetul se aude;
##   3. contactul elefantului: AudioManager primeste `elephant_trumpet`, pozitional;
##   4. telegraful dominoului: playerul 3D al blocului poarta `root_creak`; blocul
##      implicit (si Track19) poarta `rock_warn`;
##   5. ambianta: buclele sunt in bucla si pe bus-ul SFX; stratul de ploaie tace pe
##      uscat si se aude cand ploua.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeAngkorSound.tscn

const RainScript := preload("res://scenes/hazards/rain_cycle.gd")
const FlashScript := preload("res://scenes/hazards/lightning_flash.gd")
const TRACK := "res://scenes/tracks/Track24.tscn"
const OLD_TRACK := "res://scenes/tracks/Track19.tscn"

var _failed: bool = false


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _stem(s: Resource) -> String:
	return "" if s == null else s.resource_path.get_file().get_basename()


func _all(root: Node, out: Array = []) -> Array:
	out.append(root)
	for c in root.get_children():
		_all(c, out)
	return out


func _rain_node(start_clock: float) -> Node:
	var rain := RainScript.new()
	rain.set("period", 60.0)
	rain.set("telegraph", 4.0)
	rain.set("rain_hold", 22.0)
	rain.set("dry_out", 4.0)
	rain.set("start_clock", start_clock)
	rain.set("screen_rain", false)
	return rain


func _ready() -> void:
	print("")
	print("=== Sunetul Angkorului ===")
	var scene := (load(TRACK) as PackedScene).instantiate()
	var nodes := _all(scene)

	print("-- 1. cablaj in Track24.tscn --")
	var flash: Node = null
	var bed: Node = null
	var rims: Array = []
	var eleph: Node = null
	for n in nodes:
		if n.get_script() == FlashScript:
			flash = n
		elif n is AmbienceBed:
			bed = n
		elif n is RimBoulderHazard:
			rims.append(n)
		elif n is HazardMarker and n.name == &"ElefantPoarta":
			eleph = n
	_check(flash != null and _stem(flash.thunder_stream) == "thunder_roll",
		"Fulger.thunder_stream = thunder_roll")
	_check(flash != null and _stem(flash.thunder_close_stream) == "thunder_crack",
		"Fulger.thunder_close_stream = thunder_crack")
	_check(bed != null and _stem(bed.bed_stream) == "jungle_bed"
		and _stem(bed.rain_stream) == "rain_leaves", "Ambianta: jungle_bed + rain_leaves")
	_check(rims.size() == 3, "3 blocuri de domino (%d)" % rims.size())
	_check(rims.all(func(r: RimBoulderHazard) -> bool: return r.warn_sfx == &"root_creak"),
		"toate blocurile: warn_sfx = root_creak")
	_check(eleph != null and eleph.contact_sfx == &"elephant_trumpet",
		"ElefantPoarta.contact_sfx = elephant_trumpet")
	scene.free()

	print("-- 4a. implicitul ramane: Track19 si obiectele noi --")
	var old := (load(OLD_TRACK) as PackedScene).instantiate()
	var old_rims := _all(old).filter(func(n: Node) -> bool: return n is RimBoulderHazard)
	print("  Track19: %d RimBoulderHazard" % old_rims.size())
	_check(not old_rims.is_empty()
		and old_rims.all(func(r: RimBoulderHazard) -> bool: return r.warn_sfx == &"rock_warn"),
		"Track19: warn_sfx = rock_warn")
	old.free()
	var fresh := RimBoulderHazard.new()
	_check(fresh.warn_sfx == &"rock_warn", "RimBoulderHazard.new(): rock_warn")
	fresh.free()

	await _thunder(true)
	await _thunder(false)
	await _trumpet()
	await _creak()
	await _ambience()

	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


## Doua feluri de fulger: cu reduce_flashes pornit tunetul tot sunetul.
func _thunder(reduce: bool) -> void:
	print("-- 2. tunet (reduce_flashes=%s) --" % reduce)
	GameState.reduce_flashes = reduce
	var scene := (load(TRACK) as PackedScene).instantiate()
	var src: Node = _all(scene).filter(func(n: Node) -> bool: return n.get_script() == FlashScript)[0]
	var holder := Node.new()
	add_child(holder)
	var we := WorldEnvironment.new()
	we.environment = Environment.new()
	holder.add_child(we)
	holder.add_child(DirectionalLight3D.new())
	holder.add_child(_rain_node(50.0))
	var fl: Node = FlashScript.new()
	fl.thunder_stream = src.thunder_stream
	fl.thunder_close_stream = src.thunder_close_stream
	fl.thunder_db = src.thunder_db
	holder.add_child(fl)
	var db_cfg: float = src.thunder_db
	scene.free()
	var thunders: Array[float] = []
	fl.thunder.connect(func(s: float) -> void: thunders.append(s))
	for _t in 60 * 80:
		await get_tree().process_frame
	var names: Array = fl.play_log.map(func(s: AudioStream) -> String: return _stem(s))
	var rolls := names.count("thunder_roll")
	var cracks := names.count("thunder_crack")
	print("  fulgere %d, semnale tunet %d, redari %d (roll %d, crack %d)"
		% [fl.flash_log.size(), thunders.size(), names.size(), rolls, cracks])
	_check(fl.flash_log.size() >= 3, "au fost fulgere")
	_check(names.size() == thunders.size() and names.size() > 0,
		"cate o redare de tunet per semnal")
	_check(rolls + cracks == names.size(), "streamul e mereu thunder_roll sau thunder_crack")
	if not reduce:
		_check(rolls > 0, "exista cel putin un huruit lung")
	var p: AudioStreamPlayer = fl.get("_player")
	_check(p != null and p.bus == &"SFX", "playerul tunetului e pe bus-ul SFX")
	_check(p != null and p.volume_db <= db_cfg and p.volume_db > -30.0,
		"volum de fundal (%.1f dB)" % (p.volume_db if p else 0.0))
	holder.queue_free()
	await get_tree().process_frame


func _trumpet() -> void:
	print("-- 3. trambita elefantului --")
	var scene := (load(TRACK) as PackedScene).instantiate()
	var marker: HazardMarker = _all(scene).filter(
		func(n: Node) -> bool: return n is HazardMarker and n.name == &"ElefantPoarta")[0]
	var spec := marker.model_spec()
	_check(String(spec.get("contact_sfx", "")) == "elephant_trumpet",
		"spec-ul markerului poarta contact_sfx = elephant_trumpet")
	scene.free()
	var plain := HazardMarker.new()
	_check(not plain.model_spec().has("contact_sfx"), "HazardMarker implicit: fara cheie contact_sfx")
	plain.free()
	# Hazardul real, cu cheia din spec, ca in track.gd.
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	cam.global_position = Vector3(0, 5, 10)
	var hz := SlidingHazard.new()
	hz.contact_sfx = StringName(spec["contact_sfx"])
	add_child(hz)
	var car := Car.new()
	add_child(car)
	car.global_position = Vector3(0, 0.7, 0)
	car.is_player = true
	AudioManager.clock = func() -> float: return 90000.0 + float(Engine.get_physics_frames()) / 60.0
	AudioManager.sfx_log.clear()
	hz.call("_speak", car)
	var hits := AudioManager.sfx_log.filter(
		func(e: Dictionary) -> bool: return e["name"] == &"elephant_trumpet")
	var barrier := AudioManager.sfx_log.filter(
		func(e: Dictionary) -> bool: return e["name"] == &"hazard_barrier_hit")
	_check(hits.size() == 1 and hits[0]["positional"], "contact: elephant_trumpet, pozitional")
	_check(barrier.is_empty(), "contact: nicio hazard_barrier_hit")
	var found := false
	for pl in AudioManager.pool3d():
		if _stem(pl.stream) == "elephant_trumpet":
			found = true
	_check(found, "un player 3D real poarta elephant_trumpet")
	var def := SlidingHazard.new()
	_check(def.contact_sfx == &"hazard_barrier_hit", "SlidingHazard implicit: hazard_barrier_hit")
	def.free()
	AudioManager.clock = func() -> float: return Time.get_ticks_msec() * 0.001
	hz.queue_free()
	car.queue_free()
	cam.queue_free()
	await get_tree().process_frame


func _creak() -> void:
	print("-- 4. telegraful dominoului --")
	for sfx: StringName in [&"root_creak", &"rock_warn"]:
		var rim := RimBoulderHazard.new()
		if sfx != &"rock_warn":
			rim.warn_sfx = sfx
		add_child(rim)
		await get_tree().physics_frame
		rim.force_clock = rim.telegraph_start() + 0.2
		for _i in 3:
			await get_tree().physics_frame
		var a: AudioStreamPlayer3D = rim.get("_audio")
		var stem := _stem(a.stream)
		_check(stem == String(sfx), "telegraf cu warn_sfx=%s -> stream %s" % [sfx, stem])
		rim.queue_free()
		await get_tree().process_frame


func _ambience() -> void:
	print("-- 5. ambianta --")
	var scene := (load(TRACK) as PackedScene).instantiate()
	var src: Node = _all(scene).filter(func(n: Node) -> bool: return n is AmbienceBed)[0]
	var holder := Node.new()
	add_child(holder)
	var we := WorldEnvironment.new()
	we.environment = Environment.new()
	holder.add_child(we)
	holder.add_child(DirectionalLight3D.new())
	var rain := _rain_node(50.0)  # uscat 10 s, apoi telegraf si ploaie
	holder.add_child(rain)
	var b := AmbienceBed.new()
	b.bed_stream = src.bed_stream
	b.rain_stream = src.rain_stream
	holder.add_child(b)
	scene.free()
	for _t in 60 * 4:
		await get_tree().process_frame
	var bed_wav := b.bed_player.stream as AudioStreamWAV
	_check(bed_wav.loop_mode == AudioStreamWAV.LOOP_FORWARD and b.bed_player.bus == &"SFX",
		"jungla: in bucla, pe SFX")
	_check(b.bed_player.playing and b.bed_player.volume_db < -12.0 and b.bed_player.volume_db > -30.0,
		"jungla suna, discret (%.1f dB)" % b.bed_player.volume_db)
	_check(not b.rain_player.playing, "pe uscat: ploaia pe frunze tace")
	for _t in 60 * 14:
		await get_tree().process_frame
	var rf: float = rain.rain_factor
	print("  rain_factor %.2f" % rf)
	_check(rf > 0.5 and b.rain_player.playing and b.rain_player.volume_db > -30.0,
		"cat ploua: ploaia pe frunze suna (%.1f dB)" % b.rain_player.volume_db)
	holder.queue_free()
	await get_tree().process_frame
