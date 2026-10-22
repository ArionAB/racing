extends SceneTree
## Genereaza sunetele CONTINUE ale masinii (docs/feel_checklist.md: engine-gears,
## toy-sound-palette, slip-squeal, surface-voice, turbo-event, sense-of-speed)
## in res://assets/audio/. Ruleaza cu:
##   godot --headless --path . --script res://tools/generate_sfx_car.gd
## WAV mono 22050 Hz / 16-bit, ca restul (vezi docs/audio_licente.md).
##
## DE CE UN FISIER SEPARAT de `generate_sfx.gd`: generatorul vechi are un singur
## `rng` semanat o data, deci orice sunet adaugat in el ar muta zgomotul tuturor
## de dupa. Aici `rng` e al nostru (alta samanta), iar sunetele vechi nu sunt
## atinse nici la octet — se poate regenera oricand, in orice ordine fata de
## celalalt generator, fara sa se schimbe un fisier existent. Determinist: doua
## rulari dau fisiere identice bit-pentru-bit.
##
## Identitatea de jucarie: motorul NU e un V8, e un tiuit electric (RC) cu un
## zumzet de angrenaje deasupra, iar contactul cu bordura e plastic care clincheste.
##
## BUCLELE: tonale -> numar INTREG de cicluri in durata (se inchid fara click la
## orice pitch_scale, fiindca bucla se reia identic); cu zgomot -> capetele se
## suprapun in fondu egal-putere (`_xfade`), ca la tromba si la val.

const RATE: int = 22050

var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 20261022
	_save("engine_whine", _engine_whine())
	_save("engine_whirr", _engine_whirr())
	_save("skid_gravel", _skid_gravel())
	_save("roll_grass", _roll_grass())
	_save("roll_gravel", _roll_gravel())
	_save("roll_water", _roll_water())
	_save("kerb_rattle", _kerb_rattle())
	_save("wind_loop", _wind_loop())
	_save("turbo_click", _turbo_click())
	_save("turbo_whoosh", _turbo_whoosh())
	_save("turbo_release", _turbo_release())
	print("SFX masina generate in res://assets/audio/")
	quit()


# ---------------------------------------------------------------- motorul

## Tiuitul electric: 330 Hz + armonici (2x, 3x, 4x, 6x) cu un al doilea
## fundamental usor dezacordat (332 Hz) — bataia de 2 Hz da „unduirea" unui motor
## mic sub sarcina. 165 de cicluri intregi in 0.5 s: bucla se inchide perfect si
## la pitch_scale != 1. Pitch-ul de joc 0.6..2.0 plimba fundamentala intre ~200 si
## ~660 Hz (armonicile ajung la ~4 kHz).
func _engine_whine() -> PackedFloat32Array:
	var n := int(RATE * 0.5)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / float(RATE)
		var s := sin(TAU * 330.0 * t)
		s += 0.45 * sin(TAU * 660.0 * t + 0.6)
		s += 0.28 * sin(TAU * 990.0 * t + 1.3)
		s += 0.16 * sin(TAU * 1320.0 * t + 2.1)
		s += 0.09 * sin(TAU * 1980.0 * t + 0.4)
		s += 0.35 * sin(TAU * 332.0 * t + 0.9)
		# Ondulatia colectorului: 12 Hz = 6 cicluri in 0.5 s.
		s *= 1.0 + 0.08 * sin(TAU * 12.0 * t)
		out[i] = s
	return _peak_norm(out, 0.40)


## Zumzetul angrenajelor: doua piepteni de armonici (140 si 144 Hz — bataia de 4 Hz
## il face sa „toarca"), cu energia strans in jurul a 1.5-2.5 kHz si faze
## aleatoare (altfel suna a puls de generator), plus un strop de zgomot trecut-banda
## pentru asprime. Sta jos cat timp nu dai gaz; sarcina il urca peste tiuit.
func _engine_whirr() -> PackedFloat32Array:
	var n := int(RATE * 0.5)
	var out := PackedFloat32Array()
	out.resize(n)
	var combs := [[140.0, 1.0], [144.0, 0.7]]
	for c in combs:
		var f0: float = c[0]
		var gain: float = c[1]
		for k in range(1, 30):
			var fk := f0 * float(k)
			if fk > 6500.0:
				break
			# Clopot in jurul a 2 kHz (in scara logaritmica) + coada joasa.
			var lg := log(fk / 2000.0)
			var g := exp(-lg * lg / 0.9) + 0.18 / float(k)
			var ph := rng.randf() * TAU
			for i in n:
				out[i] += gain * g * cos(TAU * fk * float(i) / float(RATE) + ph)
	out = _peak_norm(out, 0.32)
	# Asprime: zgomot ingust pe 1.6 kHz, fondu in bucla (zgomotul n-are faza).
	var raw := _bp(_noise(n + 2205), 1600.0, 1.2)
	var rough := _xfade(raw, n, 2205)
	var rp := 0.0001
	for v in rough:
		rp = maxf(rp, absf(v))
	for i in n:
		out[i] += rough[i] * (0.10 / rp)
	return _peak_norm(out, 0.40)


# --------------------------------------------------------------- derapajul

## Sisaitul pe pietris/pamant: zgomot trecut-banda pe ~3 kHz, cu „scrasnituri"
## rare (impulsuri rezonante) — se aude ca un nisip aruncat, nu ca un cauciuc care
## tipa. In locul scrasnetului de asfalt cand derapezi pe sol afanat.
func _skid_gravel() -> PackedFloat32Array:
	var n := int(RATE * 0.6)
	var fade := 2205
	var bed := _bp(_noise(n + fade), 3200.0, 0.7)
	var grit := _grit(n + fade, 140.0, 2200.0, 5200.0, 0.004)
	var raw := PackedFloat32Array()
	raw.resize(n + fade)
	for i in n + fade:
		raw[i] = bed[i] * 0.7 + grit[i] * 0.9
	return _peak_norm(_xfade(raw, n, fade), 0.50)


# ----------------------------------------------------- suprafetele (rulare)

## Iarba: un fosnet jos si moale — zgomot trecut-jos pe ~450 Hz, putin „matura"
## pe 1.2 kHz, si o respiratie lenta ca sa nu fie static.
func _roll_grass() -> PackedFloat32Array:
	var n := RATE
	var fade := 3300
	var low := _lp1(_lp1(_noise(n + fade), 650.0), 650.0)
	var mid := _bp(_noise(n + fade), 1300.0, 0.8)
	var breath := _lp1(_lp1(_noise(n + fade), 6.0), 6.0)
	var bm := 0.0001
	for v in breath:
		bm = maxf(bm, absf(v))
	var raw := PackedFloat32Array()
	raw.resize(n + fade)
	for i in n + fade:
		var env := 0.65 + 0.35 * (breath[i] / bm)
		raw[i] = (low[i] * 1.0 + mid[i] * 0.35) * env
	return _peak_norm(_xfade(raw, n, fade), 0.50)


## Pietris si nisip: granule — impulsuri rezonante dese (~230/s) pe frecvente
## 1.5-4 kHz, peste un strat subtire de zgomot. Mai sec si mai „craunt" decat
## sisaitul de derapaj, care e un spectru continuu.
func _roll_gravel() -> PackedFloat32Array:
	var n := RATE
	var fade := 3300
	var grit := _grit(n + fade, 230.0, 1500.0, 4200.0, 0.006)
	var bed := _bp(_noise(n + fade), 1900.0, 0.6)
	var raw := PackedFloat32Array()
	raw.resize(n + fade)
	for i in n + fade:
		raw[i] = grit[i] * 1.0 + bed[i] * 0.22
	return _peak_norm(_xfade(raw, n, fade), 0.50)


## Apa mica: picaturi (explozii scurte de zgomot inalt, cu frecventa care urca ca la
## o bula) peste un suvoi jos. „Stropit" — mult mai deschis si mai aerisit decat
## iarba. 44 de picaturi/s.
func _roll_water() -> PackedFloat32Array:
	var n := RATE
	var fade := 3300
	var total := n + fade
	var drops := PackedFloat32Array()
	drops.resize(total)
	var count := int(float(total) / float(RATE) * 44.0)
	for d in count:
		var start := rng.randi_range(0, total - 1)
		var amp := rng.randf_range(0.3, 1.0)
		var f := rng.randf_range(1400.0, 3200.0)
		var dur := int(RATE * rng.randf_range(0.008, 0.02))
		var ph := 0.0
		for j in dur:
			var u := float(j) / float(dur)
			# Bula: frecventa urca cat se stinge.
			ph += TAU * f * (1.0 + 1.4 * u) / float(RATE)
			var e := minf(u / 0.08, 1.0) * exp(-u * 4.0)
			var idx := (start + j) % total
			drops[idx] += sin(ph) * e * amp
	var wash := _bp(_noise(total), 1100.0, 0.5)
	var hiss := _hp1(_noise(total), 3500.0)
	var raw := PackedFloat32Array()
	raw.resize(total)
	for i in total:
		raw[i] = drops[i] * 0.85 + wash[i] * 0.45 + hiss[i] * 0.18
	return _peak_norm(_xfade(raw, n, fade), 0.50)


## Bordura: zdranganeala de plastic. 17 „tocuri" in 0.4 s (~42 Hz, pitch_scale ii
## muta ritmul odata cu viteza), neuniform intarziate si cu inaltime aleatoare
## 700-1500 Hz, fiecare un clinchet scurt de plastic + un click de zgomot.
## Coada ultimului toc se rastoarce la inceputul buclei (scriere modulo), deci
## bucla e fara cusatura.
func _kerb_rattle() -> PackedFloat32Array:
	var n := int(RATE * 0.4)
	var out := PackedFloat32Array()
	out.resize(n)
	var ticks := 17
	var slot := float(n) / float(ticks)
	for k in ticks:
		var start := int(slot * float(k) + rng.randf_range(-0.18, 0.18) * slot)
		var amp := 1.0 if k % 2 == 0 else 0.7
		amp *= rng.randf_range(0.75, 1.0)
		var f := rng.randf_range(700.0, 1500.0)
		var dur := int(RATE * 0.03)
		for j in dur:
			var t := float(j) / float(RATE)
			var ring := sin(TAU * f * t) * exp(-t * 120.0)
			ring += 0.5 * sin(TAU * f * 2.6 * t) * exp(-t * 200.0)
			var click := (rng.randf() * 2.0 - 1.0) * exp(-t * 900.0) * 0.8
			var idx := posmod(start + j, n)
			out[idx] += (ring + click) * amp
	return _peak_norm(out, 0.55)


# ------------------------------------------------------------------- vantul

## Vantul: zgomot colorat (trece-jos pe ~1.6 kHz cu un umar pe 700 Hz) si o rafala
## lenta. Doar pozitia si volumul ii dau intensitatea — jocul il tine mut sub
## jumatate din viteza.
func _wind_loop() -> PackedFloat32Array:
	var n := int(RATE * 1.2)
	var fade := 4400
	var a := _lp1(_lp1(_noise(n + fade), 1700.0), 1700.0)
	var b := _bp(_noise(n + fade), 700.0, 0.6)
	var gust := _lp1(_lp1(_noise(n + fade), 5.0), 5.0)
	var gm := 0.0001
	for v in gust:
		gm = maxf(gm, absf(v))
	var raw := PackedFloat32Array()
	raw.resize(n + fade)
	for i in n + fade:
		var env := 0.75 + 0.25 * (gust[i] / gm)
		raw[i] = (a[i] * 1.0 + b[i] * 0.5) * env
	return _peak_norm(_xfade(raw, n, fade), 0.50)


# -------------------------------------------------------------------- turbo

## Click-clack-ul butonului de turbo: doua tocuri de plastic (unul ascutit, unul
## mai grav la 28 ms dupa el), ca un intrerupator de jucarie.
func _turbo_click() -> PackedFloat32Array:
	var n := int(RATE * 0.08)
	var out := PackedFloat32Array()
	out.resize(n)
	var hits := [[0.0, 2300.0, 1.0, 110.0], [0.028, 1150.0, 0.8, 90.0]]
	for h in hits:
		var start := int(float(h[0]) * float(RATE))
		for j in n - start:
			var t := float(j) / float(RATE)
			var tone := sin(TAU * float(h[1]) * t) * exp(-t * float(h[3]))
			var click := (rng.randf() * 2.0 - 1.0) * exp(-t * 1200.0) * 0.6
			out[start + j] += (tone + click) * float(h[2])
	return _peak_norm(out, 0.70)


## Suvoiul turbo-ului cat arde: un jet — zgomot trecut-banda pe ~1.4 kHz, un
## tiuit de turbina (600 Hz cu vibrato, 480 de cicluri in 0.8 s) si un huruit de
## 90 Hz. Mai lat si mai „aerat" decat motorul, ca sa se auda PESTE el.
func _turbo_whoosh() -> PackedFloat32Array:
	var n := int(RATE * 0.8)
	var fade := 3300
	var jet := _xfade(_bp(_noise(n + fade), 1400.0, 0.9), n, fade)
	var air := _xfade(_hp1(_noise(n + fade), 2500.0), n, fade)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / float(RATE)
		var tone := sin(TAU * 600.0 * t + 1.5 * sin(TAU * 5.0 * t)) * 0.35
		tone += sin(TAU * 1200.0 * t) * 0.12
		var rumble := sin(TAU * 90.0 * t) * 0.3
		out[i] = jet[i] * 1.0 + air[i] * 0.35 + tone + rumble
	return _peak_norm(out, 0.50)


## Sisaitul de la capat („pssht" cand se inchide supapa): zgomot inalt cu taietura
## care coboara de la ~6 kHz la ~1.5 kHz, atac scurt, stingere in ~0.4 s.
func _turbo_release() -> PackedFloat32Array:
	var n := int(RATE * 0.4)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var hp := 0.0
	var prev := 0.0
	for i in n:
		var u := float(i) / float(n)
		var fc := lerpf(6000.0, 1500.0, u)
		var a := 1.0 - exp(-TAU * fc / float(RATE))
		var x := rng.randf() * 2.0 - 1.0
		lp += (x - lp) * a
		# trece-sus usor ca sa nu ramana huruit
		hp = 0.97 * (hp + lp - prev)
		prev = lp
		var env := minf(u / 0.03, 1.0) * exp(-u * 4.5)
		out[i] = hp * env
	return _peak_norm(out, 0.60)


# ----------------------------------------------------------------- unelte

func _noise(n: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = rng.randf() * 2.0 - 1.0
	return out


## Trece-jos cu un pol.
func _lp1(a: PackedFloat32Array, fc: float) -> PackedFloat32Array:
	var k := 1.0 - exp(-TAU * fc / float(RATE))
	var out := PackedFloat32Array()
	out.resize(a.size())
	var y := 0.0
	for i in a.size():
		y += (a[i] - y) * k
		out[i] = y
	return out


## Trece-sus cu un pol (intrarea minus trece-jos-ul ei).
func _hp1(a: PackedFloat32Array, fc: float) -> PackedFloat32Array:
	var lo := _lp1(a, fc)
	var out := PackedFloat32Array()
	out.resize(a.size())
	for i in a.size():
		out[i] = a[i] - lo[i]
	return out


## Trece-banda biquad (RBJ, castig de varf 0 dB).
func _bp(a: PackedFloat32Array, f0: float, q: float) -> PackedFloat32Array:
	var w0 := TAU * f0 / float(RATE)
	var alpha := sin(w0) / (2.0 * q)
	var a0 := 1.0 + alpha
	var b0 := alpha / a0
	var b2 := -alpha / a0
	var a1 := -2.0 * cos(w0) / a0
	var a2 := (1.0 - alpha) / a0
	var out := PackedFloat32Array()
	out.resize(a.size())
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	for i in a.size():
		var x := a[i]
		var y := b0 * x + b2 * x2 - a1 * y1 - a2 * y2
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y
		out[i] = y
	return out


## Granule: impulsuri Poisson (`rate` pe secunda), fiecare un rezonator scurt pe o
## frecventa aleatoare din [f_lo, f_hi], stins in `decay_s`. Amplitudine aleatoare.
func _grit(n: int, rate: float, f_lo: float, f_hi: float,
		decay_s: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(n)
	var count := int(float(n) / float(RATE) * rate)
	var dur := int(RATE * decay_s * 5.0)
	for k in count:
		var start := rng.randi_range(0, n - 1)
		var amp := rng.randf_range(0.2, 1.0)
		amp *= amp
		var f := rng.randf_range(f_lo, f_hi)
		for j in dur:
			if start + j >= n:
				break
			var t := float(j) / float(RATE)
			out[start + j] += sin(TAU * f * t) * exp(-t / decay_s) * amp
	return out


## Inchide o bucla de zgomot: `raw` are n + fade esantioane; primele `fade` se
## amesteca (egal-putere) cu coada din afara lui n. Rezultatul are n esantioane si
## cap = continuarea cozii.
func _xfade(raw: PackedFloat32Array, n: int, fade: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		if i < fade:
			var k := float(i) / float(fade)
			out[i] = raw[i] * sin(k * PI * 0.5) + raw[n + i] * cos(k * PI * 0.5)
		else:
			out[i] = raw[i]
	return out


func _peak_norm(a: PackedFloat32Array, peak: float) -> PackedFloat32Array:
	var m := 0.0001
	for v in a:
		m = maxf(m, absf(v))
	var out := PackedFloat32Array()
	out.resize(a.size())
	for i in a.size():
		out[i] = a[i] * peak / m
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
