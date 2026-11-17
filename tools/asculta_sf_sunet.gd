extends Node
## ASCULTA sunetele San Francisco-ului (pasul 8e), unul dupa altul, cu numele in consola. Pentru
## urechea dezvoltatorului: sonda (ProbeSfSunet) verifica doar cablajul si momentele, nu cum suna.
## Ruleaza CU fereastra (headless nu are iesire audio):
##
##   godot --path . res://tools/AscultaSfSunet.tscn [-- --doar=cable_bell_climb]
##
## Ordinea: clopotul urcarii, clopotul gurii (fiecare de doua ori), zumzetul cablului (6 s, cu
## intrare si iesire ca pe strada), scandurile la trei viteze (pitch 0,8 / 1,05 / 1,3, ca in
## CarAudio), pescarusul, leul de mare, papagalul (cate doua, cu pitch diferit), apoi patru
## aterizari la caderile masurate pe lant, la nivelurile pe care le da AudioManager.plan_land.
## Nivelurile sunt cele din joc (dB din scena / din CarAudio), fara atenuarea de distanta.

var _player: AudioStreamPlayer
var _only: String = ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--doar="):
			_only = a.trim_prefix("--doar=")
	_player = AudioStreamPlayer.new()
	_player.bus = &"SFX"
	add_child(_player)
	var label := Label.new()
	label.text = "Sunetul San Francisco — vezi consola"
	add_child(label)
	await _play(&"cable_bell_climb", -3.0, 1.0, 2.0, "clopotul urcarii (Tramvai1)")
	await _play(&"cable_bell_climb", -3.0, 1.0, 2.2, "clopotul urcarii, din nou")
	await _play(&"cable_bell_mouth", 0.0, 1.0, 2.0, "clopotul gurii (Tramvai2)")
	await _play(&"cable_bell_mouth", 0.0, 1.0, 2.2, "clopotul gurii, din nou")
	await _hum()
	for p: float in [0.8, 1.05, 1.3]:
		await _play(&"plank_rattle", -36.0 + 23.0 * (p - 0.8) / 0.5 + 4.0, p, 2.0,
			"scandurile pontonului, pitch %.2f" % p, true)
	var call_db := {&"gull_call": -9.0, &"sea_lion_bark": -6.0, &"parrot_squawk": -10.0}
	for nm: StringName in call_db:
		await _play(nm, float(call_db[nm]), 0.95, 1.6, String(nm))
		await _play(nm, float(call_db[nm]), 1.07, 2.0, String(nm) + " (alt pitch)")
	# caderile masurate pe cele patru muchii ale lantului (ProbeSfSunet, un tur), la ~2 s una de alta
	for fs: float in [17.9, 18.0, 19.0, 18.3]:
		for e: Dictionary in AudioManager.plan_land(fs):
			AudioManager.call(&"_play_2d", e["name"], float(e["pitch"]), float(e["db"]))
		print("aterizare, cadere %.1f m/s" % fs)
		await get_tree().create_timer(2.0).timeout
	print("gata")
	get_tree().quit()


func _play(nm: StringName, db: float, pitch: float, hold: float, what: String,
		loop: bool = false) -> void:
	if _only != "" and _only != String(nm):
		return
	print(what, "  (", nm, ", ", "%.1f dB" % db, ")")
	_player.stream = AudioManager.stream(nm)
	_player.volume_db = db
	_player.pitch_scale = pitch
	_player.play()
	await get_tree().create_timer(hold).timeout
	if loop:
		_player.stop()


## Zumzetul cum il auzi pe strada: intra in 0,8 s, sta, iese in 0,8 s.
func _hum() -> void:
	if _only != "" and _only != "cable_hum":
		return
	print("zumzetul cablului (-14 dB pe strada)")
	_player.stream = AudioManager.stream(&"cable_hum")
	_player.pitch_scale = 1.0
	_player.volume_db = -60.0
	_player.play()
	var t := 0.0
	while t < 6.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		var g := clampf(minf(t / 0.8, (6.0 - t) / 0.8), 0.001, 1.0)
		_player.volume_db = -14.0 + linear_to_db(g)
	_player.stop()
