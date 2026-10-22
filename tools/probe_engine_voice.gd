extends Node
## Motorul de jucarie cu trepte si sarcina (docs/feel_checklist.md, `engine-gears`
## + `toy-sound-palette`). Citeste STAREA playerelor lui CarAudio (headless nu
## reda sunet): pitch_scale, volume_db, stream, playing.
##
## Contractele:
##   1. Pe loc, fara gaz: tiuitul canta, la pitch de mers in gol si volum jos;
##      zumzetul (stratul de sarcina) e mut.
##   2. Acceleratie plina de la 0 la plafon: cel putin 4 schimbari de treapta;
##      la fiecare, pitch-ul CADE (>= 0.25) in cel mult 0.25 s si apoi URCA iar
##      (>= 0.3 in treapta); nicio treapta mai scurta de 0.3 s (altfel e ciripit,
##      nu schimbare).
##   3. Sarcina: la aceeasi viteza (60% din max, fixata) si aceeasi treapta, gaz
##      = tiuitul cu >= 3 dB mai tare si zumzetul cu >= 12 dB peste cel fara gaz.
##   4. La schimbare cuplul se taie: zumzetul scade >= 6 dB fata de inainte.
##   5. Franand de la plafon, treapta COBOARA si pitch-ul URCA la coborare.
##   6. Adversarul (AI): UN singur strat de motor (tiuitul), fara zumzet, fara
##      vant/suvoi, dar aceeasi logica de trepte (pitch cade la schimbare).
## Sabotaj (trebuie sa PICE): `-- --off` taie treptele (o singura treapta) si
## sarcina (zumzet mut, fara adaos de volum).
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeEngineVoice.tscn
##   (+ `-- --csv=cale.csv` scrie traseul pitch/volum pe cadre, pentru spectrograma)

const U := preload("res://tools/probe_audio_util.gd")

var _failed: bool = false
var _off: bool = false
var _csv_path: String = ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--off":
			_off = true
		elif a.begins_with("--csv="):
			_csv_path = a.substr(6)
	U.ground(self)
	await get_tree().physics_frame
	print("")
	print("=== Motorul cu trepte si sarcina ===")
	if _off:
		print("  (SABOTAJ: o singura treapta, fara sarcina)")
	await _test_idle()
	await _test_gears()
	await _test_load()
	await _test_downshift()
	await _test_ai()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _spawn(player: bool) -> Car:
	var car := U.spawn(self, player)
	if _off:
		car._audio.gear_up_at = PackedFloat32Array()
		car._audio.load_boost_db = 0.0
		car._audio.whirr_full_db = -80.0
	return car


func _wait(seconds: float) -> void:
	for _f in int(seconds / U.STEP):
		await get_tree().physics_frame


func _test_idle() -> void:
	print("")
	print("-- 1. pe loc, fara gaz --")
	var car := _spawn(true)
	await _wait(1.0)
	var au = U.audio(car)
	_check(au.whine != null and au.whine.playing and au.whine.stream != null,
		"tiuitul canta (stream + playing)")
	_check(au.whirr != null and au.whirr.stream != null and au.whirr.stream != au.whine.stream,
		"jucatorul are si zumzetul, alt stream decat tiuitul")
	print("  tiuit pitch %.2f vol %.1f dB, zumzet vol %.1f dB, treapta %d"
		% [au.whine.pitch_scale, au.whine.volume_db, au.whirr.volume_db, au.gear])
	_check(absf(au.whine.pitch_scale - au.whine_pitch.x) < 0.05, "pitch de mers in gol")
	_check(au.whine.volume_db <= -18.0, "volum jos in gol (<= -18 dB)")
	_check(au.whirr.volume_db <= -35.0, "zumzetul e mut fara gaz (<= -35 dB)")
	car.queue_free()
	await get_tree().physics_frame


func _test_gears() -> void:
	print("")
	print("-- 2. acceleratie plina: trepte, caderi, urcari --")
	var car := _spawn(true)
	await _wait(0.6)
	var au = U.audio(car)
	U.drv(car).throttle = 1.0
	var t := 0.0
	var pitch: Array[float] = []
	var wvol: Array[float] = []
	var gear: Array[int] = []
	var spd: Array[float] = []
	var rows: Array[String] = ["t,speed_frac,gear,whine_pitch,whine_db,whirr_pitch,whirr_db"]
	while t < 14.0:
		await get_tree().physics_frame
		t += U.STEP
		var f := car.horizontal_speed() / car.max_speed
		pitch.append(au.whine.pitch_scale)
		wvol.append(au.whirr.volume_db)
		gear.append(au.gear)
		spd.append(f)
		rows.append("%.3f,%.3f,%d,%.3f,%.2f,%.3f,%.2f" % [t, f, au.gear,
			au.whine.pitch_scale, au.whine.volume_db, au.whirr.pitch_scale, au.whirr.volume_db])
		if f > 0.97 and t > 3.0:
			break
	print("  ajuns la %.0f%% din max in %.1f s, %d schimbari (treapta finala %d)"
		% [spd[-1] * 100.0, t, au.shifts, au.gear])
	_check(spd[-1] > 0.9, "masina ajunge aproape de plafon")
	_check(au.shifts >= 4, "cel putin 4 schimbari de treapta (%d)" % au.shifts)
	# Momentele schimbarilor: cadrele in care treapta creste.
	var shift_frames: Array[int] = []
	for i in range(1, gear.size()):
		if gear[i] > gear[i - 1]:
			shift_frames.append(i)
	var drops_ok := 0
	var rises_ok := 0
	var cut_ok := 0
	var worst_drop := 9.0
	var worst_rise := 9.0
	for n in shift_frames.size():
		var i := shift_frames[n]
		var pre := pitch[maxi(i - 1, 0)]
		var low := pre
		for j in range(i, mini(i + 15, pitch.size())): # 0.25 s
			low = minf(low, pitch[j])
		var drop := pre - low
		worst_drop = minf(worst_drop, drop)
		if drop >= 0.25:
			drops_ok += 1
		# Urcarea: de la minim pana la sfarsitul treptei urmatoare.
		var end_i := shift_frames[n + 1] - 1 if n + 1 < shift_frames.size() else pitch.size() - 1
		var peak := low
		for j in range(i, end_i + 1):
			peak = maxf(peak, pitch[j])
		var rise := peak - low
		worst_rise = minf(worst_rise, rise)
		if rise >= 0.3:
			rises_ok += 1
		var wpre := wvol[maxi(i - 1, 0)]
		var wlow := wpre
		for j in range(i, mini(i + 12, wvol.size())):
			wlow = minf(wlow, wvol[j])
		if wpre - wlow >= 6.0:
			cut_ok += 1
		print("    schimbare %d la t=%.2fs (viteza %.0f%%): pitch %.2f -> %.2f -> %.2f, zumzet %.1f -> %.1f dB"
			% [n + 1, float(i) * U.STEP, spd[i] * 100.0, pre, low, peak, wpre, wlow])
	var total := shift_frames.size()
	_check(total >= 4 and drops_ok == total,
		"pitch-ul cade >= 0.25 la fiecare schimbare (%d/%d, cea mai mica cadere %.2f)"
		% [drops_ok, total, worst_drop])
	_check(total >= 4 and rises_ok == total,
		"si urca iar >= 0.3 in treapta (%d/%d, cea mai mica urcare %.2f)"
		% [rises_ok, total, worst_rise])
	_check(total >= 4 and cut_ok == total,
		"cuplul se taie: zumzetul scade >= 6 dB la fiecare schimbare (%d/%d)" % [cut_ok, total])
	var min_len := 99.0
	for n in range(0, shift_frames.size() - 1):
		min_len = minf(min_len, float(shift_frames[n + 1] - shift_frames[n]) * U.STEP)
	_check(shift_frames.size() >= 2 and min_len >= 0.3,
		"nicio treapta mai scurta de 0.3 s (cea mai scurta %.2f s)" % min_len)
	if _csv_path != "":
		var f := FileAccess.open(_csv_path, FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(rows))
			f.close()
			print("  traseu scris in ", _csv_path)
	car.queue_free()
	await get_tree().physics_frame


func _test_load() -> void:
	print("")
	print("-- 3. sarcina: gaz vs rulaj la aceeasi viteza --")
	var car := _spawn(true)
	await _wait(0.5)
	var au = U.audio(car)
	var drv := U.drv(car)
	var res := {}
	for mode in ["gaz", "rulaj"]:
		drv.throttle = 1.0 if mode == "gaz" else 0.0
		for _f in 60:
			U.pin_speed(car, car.max_speed * 0.6)
			await get_tree().physics_frame
		res[mode] = [au.whine.pitch_scale, au.whine.volume_db, au.whirr.volume_db, au.gear]
	var a: Array = res["gaz"]
	var b: Array = res["rulaj"]
	print("  gaz:   pitch %.2f tiuit %.1f dB zumzet %.1f dB (treapta %d)" % [a[0], a[1], a[2], a[3]])
	print("  rulaj: pitch %.2f tiuit %.1f dB zumzet %.1f dB (treapta %d)" % [b[0], b[1], b[2], b[3]])
	_check(a[3] == b[3] and absf(float(a[0]) - float(b[0])) < 0.1,
		"aceeasi treapta si acelasi pitch (turatia vine din viteza)")
	_check(float(a[1]) - float(b[1]) >= 3.0, "tiuitul e cu >= 3 dB mai tare sub gaz")
	_check(float(a[2]) - float(b[2]) >= 12.0, "zumzetul e cu >= 12 dB mai tare sub gaz")
	car.queue_free()
	await get_tree().physics_frame


func _test_downshift() -> void:
	print("")
	print("-- 4. franare de la plafon: treapta coboara, pitch-ul urca --")
	var car := _spawn(true)
	await _wait(0.5)
	var au = U.audio(car)
	var drv := U.drv(car)
	drv.throttle = 0.0
	for _f in 40:
		U.pin_speed(car, car.max_speed * 0.95)
		await get_tree().physics_frame
	var g0: int = au.gear
	var gmin: int = g0
	var up_jump := 0.0
	var prev_pitch: float = au.whine.pitch_scale
	drv.throttle = -1.0
	for _f in 400:
		await get_tree().physics_frame
		if au.gear < gmin:
			gmin = au.gear
		if au.gear < g0:
			up_jump = maxf(up_jump, au.whine.pitch_scale - prev_pitch)
		prev_pitch = au.whine.pitch_scale
		if car.horizontal_speed() < car.max_speed * 0.2:
			break
	print("  treapta de la %d la %d, cel mai mare salt de pitch la coborare %.3f/cadru"
		% [g0, gmin, up_jump])
	_check(g0 >= 4 and gmin <= 2, "treapta coboara pe masura ce incetineste")
	_check(up_jump >= 0.02, "pitch-ul sare in sus la coborarea treptei (%.3f)" % up_jump)
	car.queue_free()
	await get_tree().physics_frame


func _test_ai() -> void:
	print("")
	print("-- 5. adversarul: un singur strat, aceeasi logica --")
	var car := _spawn(false)
	await _wait(0.6)
	var au = U.audio(car)
	U.drv(car).throttle = 1.0
	var prev: float = au.whine.pitch_scale
	var drops := 0
	var t := 0.0
	while t < 10.0:
		await get_tree().physics_frame
		t += U.STEP
		if prev - au.whine.pitch_scale > 0.04:
			drops += 1
		prev = au.whine.pitch_scale
		if car.horizontal_speed() > car.max_speed * 0.9:
			break
	var players := 0
	for c in au.get_children():
		if c is AudioStreamPlayer3D or c is AudioStreamPlayer:
			if c.playing:
				players += 1
	print("  playere pornite: %d, cadre cu cadere de pitch: %d, schimbari: %d"
		% [players, drops, au.shifts])
	_check(au.whirr == null and au.wind == null and au.whoosh == null,
		"fara zumzet, vant sau suvoi")
	_check(players == 1, "exact UN player de bucla pornit (%d)" % players)
	_check(au.shifts >= 3 and drops >= 3, "tot are trepte (pitch cade la schimbare)")
	car.queue_free()
	await get_tree().physics_frame
