extends SceneTree
## Genereaza SFX-urile placeholder (sinteza retro-arcade) in res://assets/audio/.
## Ruleaza cu:
##   godot --headless --path . --script res://tools/generate_sfx.gd
## WAV mono 22050Hz/16-bit. Adaptat din racing 2D: fara sunete de items,
## plus contact intre masini (bump) si aterizare dupa saritura (land).

const RATE: int = 22050

var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.seed = 20260718
	DirAccess.make_dir_recursive_absolute("res://assets/audio")
	_save("engine_loop", _engine_loop())
	_save("boost", _sweep_whoosh(0.45, 180.0, 850.0, 0.3))
	_save("drift_start", _drift_start())
	_save("drift_level", _drift_level())
	_save("backfire", _backfire())
	_save("wall_hit", _thud(0.13, 80.0, 45.0, 0.8))
	_save("bump", _thud(0.1, 110.0, 70.0, 0.55))
	_save("land", _land())
	_save("count_beep", _tone(0.1, 440.0, 10.0))
	_save("go_beep", _tone(0.3, 880.0, 6.0))
	_save("skid_loop", _skid_loop())
	print("SFX generate in res://assets/audio/")
	quit()

## Saw 110Hz + octava cu tremolo; cicluri intregi in 0.5s -> loop fara click.
func _engine_loop() -> PackedFloat32Array:
	var n := int(RATE * 0.5)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / float(RATE)
		var saw := 2.0 * fposmod(t * 110.0, 1.0) - 1.0
		var saw2 := 2.0 * fposmod(t * 220.0, 1.0) - 1.0
		var tremolo := 0.85 + 0.15 * sin(TAU * 8.0 * t)
		out[i] = (saw * 0.5 + saw2 * 0.22) * tremolo * 0.5
	return out

func _drift_start() -> PackedFloat32Array:
	var n := int(RATE * 0.12)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / float(n)
		lp = lp * 0.7 + (rng.randf() * 2.0 - 1.0) * 0.3
		out[i] = lp * (1.0 - t) * 0.8
	return out

func _drift_level() -> PackedFloat32Array:
	var n := int(RATE * 0.09)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / float(RATE)
		out[i] = signf(sin(TAU * 700.0 * t)) * exp(-t * 18.0) * 0.35
	return out

func _backfire() -> PackedFloat32Array:
	var n := int(RATE * 0.32)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(RATE)
		var freq := lerpf(95.0, 55.0, minf(t / 0.1, 1.0))
		phase += freq / float(RATE)
		var thump := sin(TAU * phase) * exp(-t * 14.0)
		var gate := 1.0 if sin(TAU * 28.0 * t) > 0.2 else 0.0
		var sputter := (rng.randf() * 2.0 - 1.0) * gate * exp(-t * 6.0) * 0.4
		out[i] = thump * 0.7 + sputter
	return out

## Bufnitura cu pitch descendent + click de zgomot la atac.
func _thud(dur: float, f0: float, f1: float, amp: float) -> PackedFloat32Array:
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(RATE)
		var freq := lerpf(f0, f1, minf(t / dur, 1.0))
		phase += freq / float(RATE)
		var thud := sin(TAU * phase) * exp(-t * 22.0)
		var click := (rng.randf() * 2.0 - 1.0) * exp(-t * 90.0) * 0.5
		out[i] = (thud * 0.8 + click) * amp
	return out

## Aterizare: bufnitura joasa + praf (zgomot filtrat scurt).
func _land() -> PackedFloat32Array:
	var out := _thud(0.1, 70.0, 40.0, 0.7)
	var n := int(RATE * 0.15)
	var dust := PackedFloat32Array()
	dust.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / float(n)
		lp = lp * 0.8 + (rng.randf() * 2.0 - 1.0) * 0.2
		dust[i] = lp * (1.0 - t) * 0.4
	out.append_array(dust)
	return out

## Scrasnet de cauciuc in bucla: zgomot filtrat cu un "vaiet" tonal slab.
## Zgomotul nu are faza, deci bucla se inchide fara click.
func _skid_loop() -> PackedFloat32Array:
	var n := int(RATE * 0.4)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / float(RATE)
		lp = lp * 0.6 + (rng.randf() * 2.0 - 1.0) * 0.4
		var whine := sin(TAU * 900.0 * t) * 0.12 # 900*0.4=360 cicluri intregi
		out[i] = (lp * 0.5 + whine) * 0.55
	return out

func _tone(dur: float, freq: float, decay: float) -> PackedFloat32Array:
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / float(RATE)
		var attack := minf(t / 0.005, 1.0)
		out[i] = signf(sin(TAU * freq * t)) * exp(-t * decay) * attack * 0.35
	return out

func _sweep_whoosh(dur: float, f0: float, f1: float, noise_amt: float) -> PackedFloat32Array:
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / float(RATE)
		var frac := t / dur
		phase += lerpf(f0, f1, frac) / float(RATE) # faza acumulata, fara click
		lp = lp * 0.75 + (rng.randf() * 2.0 - 1.0) * 0.25
		out[i] = (sin(TAU * phase) * 0.5 + lp * noise_amt) * sin(PI * frac)
	return out

func _save(name: String, data: PackedFloat32Array) -> void:
	var path := "res://assets/audio/%s.wav" % name
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Nu pot scrie " + path)
		return
	var data_size := data.size() * 2
	f.store_buffer("RIFF".to_ascii_buffer())
	f.store_32(36 + data_size)
	f.store_buffer("WAVE".to_ascii_buffer())
	f.store_buffer("fmt ".to_ascii_buffer())
	f.store_32(16)
	f.store_16(1)
	f.store_16(1)
	f.store_32(RATE)
	f.store_32(RATE * 2)
	f.store_16(2)
	f.store_16(16)
	f.store_buffer("data".to_ascii_buffer())
	f.store_32(data_size)
	for s in data:
		var v := int(clampf(s, -1.0, 1.0) * 32767.0)
		if v < 0:
			v += 65536
		f.store_16(v)
	print("  %s (%d samples)" % [path, data.size()])
