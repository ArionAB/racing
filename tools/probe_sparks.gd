extends Node
## #500: feedback la ciocnirea intre masini. Pe o cursa reala, dupa GO, o
## masina AI e pusa langa jucator si aruncata lateral in el (T-bone) cu
## `--speed` m/s. Raporteaza: delta-v-ul incasat, daca scanteile au pornit si
## unde (fata de cele doua masini), ce sunete a cerut AudioManager si cu ce
## volum, si trauma camerei. Cu FEREASTRA (fara --headless) salveaza si
## capturi la 0,05 / 0,12 / 0,22 s dupa contact in --out.
##   godot --fixed-fps 60 --path . res://tools/ProbeSparks.tscn -- --track=0 --speed=12 --out=C:/tmp

const RACE_SCENE := "res://scenes/race/Race.tscn"

var _race: Race
var _speed := 12.0
var _out := ""
var _t := 0.0
var _phase := ""
var _hit_t := -1.0
var _dv := 0.0
var _shots := [0.05, 0.12, 0.22]
var _shot_i := 0
var _other: Car
var _go_t := -1.0


func _ready() -> void:
	var idx := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--speed="):
			_speed = float(arg.trim_prefix("--speed="))
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	GameState.selected_track = idx
	GameState.champ_active = false
	GameState.total_laps = 99
	_race = (load(RACE_SCENE) as PackedScene).instantiate() as Race
	add_child(_race)
	_race.player.bumped.connect(func(_c: Car, _o: Car, dv: float) -> void:
		# Doar izbitura lansata de sonda: la GO plutonul se imbrancea pe grila.
		if _hit_t < 0.0 and _phase == "lansez":
			_hit_t = _t
			_dv = dv)


func _physics_process(delta: float) -> void:
	_t += delta
	if _race.state != Race.State.RUNNING:
		return
	var p := _race.player
	match _phase:
		"":
			# Plutonul pleaca intai; jucatorul (fara taste) ramane singur.
			if _go_t < 0.0:
				_go_t = _t
			if _t - _go_t > 6.0:
				_phase = "asez"
				_other = _race.cars[1]
				# Cu BOTUL spre jucator: aruncata lateral, aderenta laterala a
				# masinii ii stingea viteza inainte de contact.
				var side := p.global_transform.basis.x
				var from := p.global_position + side * 7.0
				_other.global_transform = Transform3D(
					Basis.looking_at(-side, Vector3.UP), from)
				_other.velocity = Vector3.ZERO
				p.velocity = Vector3.ZERO
		"asez":
			_phase = "lansez"
			# Fara sofer: AI-ul ar frana vazand masina din fata.
			_other.race_active = false
			_other.velocity = -_other.global_transform.basis.z * _speed
		"lansez":
			if _hit_t >= 0.0:
				_phase = "dupa"
				_report_hit()
			elif _t > 30.0:
				print("[sparks] nicio ciocnire")
				print("VERDICT: PROBLEMA")
				get_tree().quit(0)
		"dupa":
			var since := _t - _hit_t
			if _out != "" and _shot_i < _shots.size() and since >= float(_shots[_shot_i]):
				var img := get_viewport().get_texture().get_image()
				var path := "%s/sparks_%d_%02d.png" % [_out, int(_speed), int(float(_shots[_shot_i]) * 100.0)]
				img.save_png(path)
				print("[sparks] captura %s" % path)
				_shot_i += 1
			if since > 0.4:
				get_tree().quit(0)


func _report_hit() -> void:
	var p := _race.player
	var sp := p.get_node_or_null("Sparks") as CPUParticles3D
	var sp2 := _other.get_node_or_null("Sparks") as CPUParticles3D
	var mid := (p.global_position + _other.global_position) * 0.5
	print("[sparks] dv incasat de jucator %.1f m/s" % _dv)
	for pair in [["jucator", sp], ["AI", sp2]]:
		var e := pair[1] as CPUParticles3D
		if e == null:
			print("[sparks] %s: fara emitator" % pair[0])
			continue
		print("[sparks] %s: emite %s, %d scantei, la %.1f m de mijlocul dintre masini, h %.2f"
			% [pair[0], e.emitting, e.amount,
				Vector2(e.global_position.x - mid.x, e.global_position.z - mid.z).length(),
				e.global_position.y - mid.y])
	for pl: AudioStreamPlayer in AudioManager._pool:
		if pl.playing and pl.stream != null:
			print("[sparks] sunet %s, volum %.1f dB, pitch %.2f"
				% [pl.stream.resource_path.get_file(), pl.volume_db, pl.pitch_scale])
	print("[sparks] trauma camerei %.2f" % _race.camera.trauma)
