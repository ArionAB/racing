extends Node
## Genereaza fragmentul de .tscn pentru falezele in benzi ale canionului (POI D).
##
## Pozitiile NU se ghicesc: ies din `route.baked` si din `ground_y`. Modulul
## masurat cu ProbeCappModule: 20.30 x 12.40 x 6.07 m, baza la y=0, centrat pe X.
##
## Terenul, masurat cu ProbeCappRavine, decide compozitia — nu simetria:
##   side_v = (d.z, 0, -d.x) e STANGA ECRANULUI — masurat cu ProbeCappSide
##   (dot -1.00 fata de camera), nu dedus din semn. Comentariile de mai jos
##   folosesc partea din IMAGINE, fiindca aia se judeca pe captura.
##
##   STANGA   teren la cota soselei pana la 35 m => aici sta faleza adevarata,
##            in doua trepte (a doua retrasa si mai sus, ca stratul de sus sa
##            iasa in consola peste cel de jos si sa-i puna o umbra pe frunte).
##   DREAPTA  rapa: podea la 11.7 m, adica 14 m SUB sosea, plata pe zeci de
##            metri. Un modul asezat acolo ar sta sub bot, nevazut. Deci pe
##            stanga nu se pune un perete, ci o BUZA: module care ies din malul
##            de sub drum si se vad ca stanca taiata, plus stanci pe podea la
##            baza lor.
##
## Straturile: fiecare treapta e un rand de module. Retragerea intre trepte
## (SETBACK) e ce face umbra — un strat tare care iese peste unul moale. O banda
## pictata pe o panta neteda arata a panza; o TREAPTA arata a roca.

const MOD_LEN := 20.30
const MOD_H := 12.40
const F0 := 0.428
const F1 := 0.534

## Retragerea celui de-al doilea etaj fata de primul (metri). Sub 2 m umbra e o
## dunga; peste 5 m al doilea etaj se desprinde si nu mai citeste ca acelasi mal.
const SETBACK := 3.6

## Degajarea minima de la AXUL drumului pana la CENTRUL modulului.
## Modulul are 6.07 m grosime si e centrat, deci fata lui ajunge cu 3.04 m mai
## aproape de sosea decat centrul. In viraj, coarda taie inca ~1.5 m. Prima
## incercare (hw + 5.0) a pus un modul PE carosabil la frac 0.48.
const CLEAR_M := 7.4

func _emit(rows: Array, side: int, tier: int, s: Dictionary, track: Track,
		rng: RandomNumberGenerator, off_base: float, y_off: float,
		scale_rng: Vector2) -> void:
	var p: Vector3 = s["p"]
	var d: Vector3 = s["d"]
	var side_v := Vector3(d.z, 0.0, -d.x) * float(side)
	var off: float = off_base + rng.randf_range(-0.5, 2.2)
	var q: Vector3 = p + side_v * off
	var g: float = track._sampler.ground_y(q.x, q.z)
	var y: float = g - 1.6 + y_off
	var yaw: float = atan2(-side_v.x, -side_v.z) + rng.randf_range(-0.10, 0.10)
	var sc: float = rng.randf_range(scale_rng.x, scale_rng.y)
	rows.append({"side": side, "tier": tier, "f": s["f"], "x": q.x, "y": y,
		"z": q.z, "yaw": yaw, "sc": sc, "g": g})

func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[6]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210

	var samples: Array = []
	var f := F0
	while f < F1:
		var idx := int(f * float(n)) % n
		var p: Vector3 = pts[idx]
		var ahead: Vector3 = pts[(idx + 10) % n]
		var d := (ahead - p); d.y = 0.0; d = d.normalized()
		samples.append({"f": f, "p": p, "d": d})
		f += 0.0016

	var rows: Array = []
	# --- FALEZA (stanga ecranului): trei trepte -----------------------------
	# Terenul e la cota soselei pana la 35 m (ProbeCappRavine), deci aici sta
	# faleza adevarata. Un singur etaj de 12.4 m e un parapet vazut din masina
	# (captura w1_052): camera sta la 10 m si se uita PESTE el. Trei etaje
	# retrase dau 30+ m si umplu cadrul, ca in referinta.
	for tier in [0, 1, 2]:
		var acc := MOD_LEN * 2.0
		var last := Vector3.ZERO
		var first := true
		for s2 in samples:
			var p2: Vector3 = s2["p"]
			if first: first = false
			else: acc += p2.distance_to(last)
			last = p2
			if acc < MOD_LEN * 0.86: continue
			acc = 0.0
			var hw: float = track.width_at(s2["f"])
			# Fiecare etaj e retras cu SETBACK si ridicat cu 0.82 din inaltime:
			# creasta celui de jos ramane vizibila ca o TREAPTA, si arunca umbra
			# pe fata celui de dedesubt. Asta face diferenta intre roca si panza.
			_emit(rows, 1, tier, s2, track, rng,
				hw + CLEAR_M + SETBACK * float(tier),
				MOD_H * 0.82 * float(tier),
				Vector2(1.05, 1.30) if tier == 0 else Vector2(0.90, 1.15))
	# --- BUZA RAPEI (dreapta ecranului) -------------------------------------
	# Rapa are podeaua la 11.7 m, adica 14 m SUB sosea, si e plata pe zeci de
	# metri: nu exista mal in fata pe care sa stea un perete. Deci pe stanga nu
	# se pune un al doilea perete, ci MUCHIA taiata a malului de sub drum —
	# modulul atarna sub buza si i se vede doar coama, ca o cornisa.
	var acc2 := MOD_LEN * 2.0
	var last2 := Vector3.ZERO
	var first2 := true
	for s3 in samples:
		var p3: Vector3 = s3["p"]
		if first2: first2 = false
		else: acc2 += p3.distance_to(last2)
		last2 = p3
		if acc2 < MOD_LEN * 0.95: continue
		acc2 = 0.0
		var hw3: float = track.width_at(s3["f"])
		var side_v := Vector3(s3["d"].z, 0.0, -s3["d"].x) * -1.0
		var off3: float = hw3 + CLEAR_M - 1.2 + rng.randf_range(-0.4, 1.0)
		var q: Vector3 = p3 + side_v * off3
		var sc: float = rng.randf_range(0.90, 1.20)
		# Coama modulului iese 0.8 m peste cota soselei: din masina se vede
		# muchia, nu un zid, si rapa ramane deschisa.
		var y: float = p3.y + 0.8 - MOD_H * sc
		var yaw: float = atan2(-side_v.x, -side_v.z) + rng.randf_range(-0.12, 0.12)
		rows.append({"side": -1, "tier": 0, "f": s3["f"], "x": q.x,
			"y": y, "z": q.z, "yaw": yaw, "sc": sc, "g": p3.y})

	var txt := ""
	for r in rows:
		txt += "%d\t%d\t%.4f\t%.3f\t%.3f\t%.3f\t%.4f\t%.3f\n" % [
			r["side"], r["tier"], r["f"], r["x"], r["y"], r["z"], r["yaw"], r["sc"]]
	var fa := FileAccess.open("res://canyon_d_rows.txt", FileAccess.WRITE)
	fa.store_string(txt)
	fa.close()
	print("rows: ", rows.size())
	get_tree().quit(0)
