extends Node
## PODEAUA VAII (Track15, Machu Picchu) - stratul care lipsea pe axa VERTICALA.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenPodeaVale.tscn -- \
##       --out=C:/cale/podea.part [--survey]
##
## DE CE EXISTA.
##
## Critica dezvoltatorului (19 sep 2026): "cand conduci la inaltime si vezi
## podeaua la multi metri sub tine nu ar trebui sa fie verde gol, ar trebui sa
## para o lume plina si jos - o padure de copaci + stanci".
##
## E acelasi defect ca #147 (banda `far`), dar pe axa VERTICALA. Comentariul de
## la banda aia spune: "benzile se opreau la 26 m, siluetele de orizont incep la
## 150 m, intre ele nu era NIMIC, si banda aia goala umple jumatate din cadru".
## Vazut de sus, podeaua goala umple la fel de mult cadru.
##
## DOUA MECANISME O GARANTEAZA GOALA, si de-asta nu se repara pe POI:
##
## 1. `BANDS` din track_decor.gd masoara `off_min`/`off_max` LATERAL fata de
##    marginea asfaltului, iar ultima banda (`far`) se opreste la 58 m. O podea
##    de rapa la -50 m COTA nu intra in nicio banda, oricat de late.
## 2. `_allowed()` respinge explicit orice prop cu `spec.is_ravine` - comentariul
##    zice "un cactus plutind peste prapastie ar strica exact efectul". Corect
##    pentru benzile de langa drum, dar exact regula care tine fundul gol.
##
## Si pe Machu Picchu mai e un al treilea: tema are `"decor": "none"`, deci
## benzile sunt STINSE complet. De-aia podeaua e un generator propriu si nu o
## banda noua - nu atinge nimic din ce folosesc celelalte 8 piste.
## Varianta ceruta de dezvoltator: (a) fara ceata, doar pe Machu Picchu, ca sa
## se izoleze o singura variabila.
##
## UNDE - masurat cu SvMpPodea/SvMpProfil, nu presupus. Cota solului fata de
## drum, din 10 in 10 m lateral, medie pe POI:
##
##   POI pt |   10    20    30    40    50    60    70    80    90   100   120
##   B  dr | -47.7 -49.3 -50.0 -50.2 -50.8 -51.3 -51.9 -52.6 -53.3 -54.2 -55.1
##   C  dr | -44.4 -45.9 -46.1 -46.5 -47.0 -48.2 -49.1 -50.4 -51.2 -51.9 -52.9
##   C  st | -14.3 -14.0 -13.4 -13.1 -14.4 -13.3 -11.3  -8.0 -11.3 -15.4 -23.2
##   E  dr | -12.4 -12.7 -12.7 -12.6 -10.9  -4.7  -3.0  -2.0   2.6  14.2  17.9
##   G  dr |  -9.5  -1.4   1.9  -0.0   3.2   2.6  -1.9  -0.6  -0.0   1.0   0.9
##   H  dr |   0.6   3.2   7.0   7.5   5.8   3.4   1.0  -0.6  -1.1  -1.2  -1.5
##
## B dreapta si C dreapta sunt PODELE ADEVARATE: -50 m, plate pe 140 m. Alea
## primesc padure. C stanga si E sunt intermediare (-13 m).
##
## G NU primeste nimic: cade 9,5 m la 10 m si URCA inapoi la -1,4 - e un sant
## de drenaj, nu o vale. (Masuratoarea asta a corectat o concluzie anterioara a
## lead-ului, care citise doar SvMpSapa - care se opreste la +10 m - si dedusese
## ca G are prapastie.) H la fel: pe dreapta URCA.
##
## CE SE ASEAZA. Piese ieftine, fiindca sunt multe si departe:
##   polylepis_a   598 tri   - copacul de baza al padurii
##   polylepis_b  1098 tri   - accent, rar
##   moss_boulder_a/b/c      - stanci, in pilcuri
## Toate FARA coliziune: la -50 m sub drum nu ajunge nicio masina, iar un
## colizor acolo ar fi doar cost. `metadata/coliziune = "none"`.
##
## CUM SE CITESTE de sus: nu conteaza piesa individuala, conteaza MASA si
## variatia de inaltime (memoria `aranjamentul-bate-numarul`). De-aia gruparea
## e mare (pilcuri de padure, nu copaci echidistanti) si scara variaza mult - o
## padure vazuta de la 50 m trebuie sa aiba textura, nu sa fie un gazon de
## conuri.

const TRACK := "res://scenes/tracks/Track15.tscn"
const ZONE := "DecorManual/ZonePodeaVale"

## Resursele folosite, cu id-ul din Track15.tscn.
const RES := {
	"polylepis_a": "s_polylepis_a",
	"polylepis_b": "s_polylepis_b",
	"moss_boulder_a": "s_moss_boulder_a",
	"moss_boulder_b": "s_moss_boulder_b",
	"moss_boulder_c": "s_moss_boulder_c",
}
const TRI := {
	"polylepis_a": 598, "polylepis_b": 1098,
	"moss_boulder_a": 180, "moss_boulder_b": 180, "moss_boulder_c": 180,
}

## Cat de jos sub cota drumului trebuie sa fie solul ca sa fie "podea de vale".
## 12 m: sub asta e taluz sau sant (G cade 9,5 si urca), nu vale.
const ADANCIME_MIN := 12.0
## Cat de departe lateral se cauta, si cu ce pas.
const LAT_MIN := 16.0
const LAT_MAX := 130.0
const LAT_PAS := 11.0
## Pasul longitudinal, in fractii de tur.
const F_PAS := 0.0035
## Cat de mult poate urca terenul local ca punctul sa mai fie considerat podea
## (si nu perete, pe care copacii ar iesi din fateta).
const PANTA_MAX_DEG := 34.0

var _track: Track
var _out: PackedStringArray = []
var _n := 0
var _tri := 0
var _sus := 0.0
var _out_path := ""
var _survey := false
var _rng := RandomNumberGenerator.new()
var _resp_panta := 0
var _resp_sus := 0
## Piese refuzate fiindca erau prea aproape de cota ORICARUI carosabil.
var _resp_langa_drum := 0
## Fractia feliei care se genereaza acum - o citeste `_raw` ca sa grupeze
## instantele pe segmente de tur (vezi `_buckets`).
var _frac_curent := 0.0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a == "--survey":
			_survey = true
	_rng.seed = 0xB0DEA
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	for i in 6:
		await get_tree().process_frame
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus = hi + 300.0
	if _survey:
		_do_survey()
	else:
		_build()
		_write()
	get_tree().quit(0)


## Scrie, pentru tot turul, cat de adanca e podeaua si cat de lata - ca sa se
## vada unde merita padure si unde nu e vale deloc.
func _do_survey() -> void:
	print("frac  | parte | adancime_max | latime_podea_m | prima_dist_m")
	var f := 0.0
	while f < 1.0:
		for sgn: float in [1.0, -1.0]:
			var r := _felie(f, sgn)
			if float(r["latime"]) > 0.0:
				print("%.4f |  %s   |   %7.1f    |     %6.1f     |   %6.1f" % [
					f, ("dr" if sgn > 0.0 else "st"), r["adanc"], r["latime"],
					r["prima"]])
		f += 0.01


## Pentru o felie (frac, parte): cat de adanc si cat de lat e fundul.
func _felie(frac: float, sgn: float) -> Dictionary:
	var a := _at(frac)
	var p: Vector3 = a["p"]
	var s: Vector3 = (a["s"] as Vector3) * sgn
	var half: float = a["half"]
	var adanc := 0.0
	var latime := 0.0
	var prima := -1.0
	var d := LAT_MIN
	while d <= LAT_MAX:
		var q := p + s * (half + d)
		var g := _sol(q.x, q.z)
		if g < -900.0:
			d += LAT_PAS
			continue
		var dy := p.y - g
		if dy >= ADANCIME_MIN:
			adanc = maxf(adanc, dy)
			latime += LAT_PAS
			if prima < 0.0:
				prima = d
		d += LAT_PAS
	return {"adanc": adanc, "latime": latime, "prima": prima}


func _build() -> void:
	var f := 0.0
	while f < 1.0:
		for sgn: float in [1.0, -1.0]:
			_felie_pune(f, sgn)
		f += F_PAS
	print("; podea: %d piese, ~%d triunghiuri" % [_n, _tri])
	print("; respinse: %d pe panta, %d prea sus, %d langa un drum" % [_resp_panta, _resp_sus, _resp_langa_drum])


func _felie_pune(frac: float, sgn: float) -> void:
	_frac_curent = frac
	var a := _at(frac)
	var p: Vector3 = a["p"]
	var s: Vector3 = (a["s"] as Vector3) * sgn
	var half: float = a["half"]
	var d := LAT_MIN
	while d <= LAT_MAX:
		# jitter lateral, altfel ies siruri
		var dd := d + _rng.randf_range(-LAT_PAS * 0.45, LAT_PAS * 0.45)
		var q := p + s * (half + dd)
		var g := _sol(q.x, q.z)
		if g < -900.0:
			d += LAT_PAS
			continue
		var dy := p.y - g
		if dy < ADANCIME_MIN:
			_resp_sus += 1
			d += LAT_PAS
			continue
		# Panta locala: pe perete copacii ar iesi din fateta.
		if _panta_deg(q.x, q.z) > PANTA_MAX_DEG:
			_resp_panta += 1
			d += LAT_PAS
			continue
		# A DOUA garda, pe cota ABSOLUTA a punctului fata de drumul CEL MAI
		# APROPIAT, nu fata de felia curenta.
		#
		# `dy` de mai sus masoara fata de `p.y`, adica de cota drumului din
		# felia care genereaza. La 100+ m lateral, pe o pista in serpentina,
		# cel mai apropiat carosabil poate fi cu totul altul - o bucla care
		# trece pe dedesubt sau pe deasupra. Fara verificarea asta ieseau 904
		# piese (16%) la cota drumului, 581 dintre ele peste -5 m, iar
		# ProbeRace prindea o ejectare cu piese la 1,4 m de masina, la
		# aceeasi cota. Memoria: pista-peste-pista.
		_pilc(Vector3(q.x, g, q.z), dy)
		d += LAT_PAS


## Punctul e cu ADANCIME_MIN sub ORICE bucata de carosabil din apropiere?
## Cauta pe tot traseul copt, nu doar pe felia curenta.
func _sub_orice_drum(p: Vector3) -> bool:
	var n := _track.baked.size()
	var best_d := INF
	var best_y := 0.0
	for i in n:
		var b: Vector3 = _track.baked[i]
		var dd := (b.x - p.x) * (b.x - p.x) + (b.z - p.z) * (b.z - p.z)
		if dd < best_d:
			best_d = dd
			best_y = b.y
	return (best_y - p.y) >= ADANCIME_MIN


## Un pilc: un copac principal plus 2-5 piese mici in jur. Padurea are pilcuri,
## nu distante egale (aceeasi regula ca `cluster` din BANDS).
func _pilc(pos: Vector3, adanc: float) -> void:
	var roll := _rng.randf()
	# Cu cat e mai adanc, cu atat mai multa padure si mai putina stanca: fundul
	# vaii e umed, peretii sunt seci.
	var prag_copac: float = 0.62 if adanc > 30.0 else 0.45
	if roll < prag_copac:
		var mare := _rng.randf() < 0.22
		var m := "polylepis_b" if mare else "polylepis_a"
		_raw(m, "podCopac", pos, _rng.randf() * TAU,
			_rng.randf_range(1.05, 1.95) * (1.15 if mare else 1.0))
		var k := _rng.randi_range(2, 5)
		for i in k:
			var ang := _rng.randf() * TAU
			var rad := _rng.randf_range(1.8, 6.5)
			var sp := pos + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
			var sg := _sol(sp.x, sp.z)
			if sg < -900.0:
				continue
			if _rng.randf() < 0.62:
				_raw("polylepis_a", "podPui", Vector3(sp.x, sg, sp.z),
					_rng.randf() * TAU, _rng.randf_range(0.75, 1.25))
			else:
				_raw(_bolovan(), "podPiatra", Vector3(sp.x, sg, sp.z),
					_rng.randf() * TAU, _rng.randf_range(0.6, 1.5))
	elif roll < prag_copac + 0.26:
		# Pilc de stanci: masa minerala intre pilcurile de padure.
		var k := _rng.randi_range(2, 4)
		for i in k:
			var ang := _rng.randf() * TAU
			var rad := _rng.randf_range(0.0, 5.0)
			var sp := pos + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
			var sg := _sol(sp.x, sp.z)
			if sg < -900.0:
				continue
			_raw(_bolovan(), "podStanca", Vector3(sp.x, sg, sp.z),
				_rng.randf() * TAU, _rng.randf_range(0.9, 2.6))
	# restul: gol intentionat - o padure continua fara poieni citeste ca gazon


func _bolovan() -> String:
	var r := _rng.randf()
	if r < 0.34:
		return "moss_boulder_a"
	if r < 0.67:
		return "moss_boulder_b"
	return "moss_boulder_c"


## Panta terenului in punct, din patru vecini la 3 m. Gradul MAXIM, nu media:
## un perete pe o singura directie trebuie sa respinga.
func _panta_deg(x: float, z: float) -> float:
	var c := _sol(x, z)
	if c < -900.0:
		return 90.0
	var m := 0.0
	for dv: Vector2 in [Vector2(3, 0), Vector2(-3, 0), Vector2(0, 3), Vector2(0, -3)]:
		var h := _sol(x + dv.x, z + dv.y)
		if h < -900.0:
			continue
		m = maxf(m, rad_to_deg(atan(absf(h - c) / 3.0)))
	return m


func _at(frac: float) -> Dictionary:
	var n := _track.baked.size()
	var t := fposmod(frac, 1.0) * float(n)
	var i := int(floor(t)) % n
	var j := (i + 1) % n
	var u: float = t - floor(t)
	var p: Vector3 = _track.baked[i].lerp(_track.baked[j], u)
	var s: Vector3 = _track._side_at(i).lerp(_track._side_at(j), u).normalized()
	var half: float = lerpf(_track.width_at_index(i), _track.width_at_index(j), u)
	return {"p": p, "s": s, "half": half}


## Instantele se STRANG pe (model, felie), si se scriu ca MultiMesh.
##
## Prima versiune emitea un nod de scena per piesa: 5633 de noduri, si Godot
## nu mai termina de incarcat scena in 25 de minute. POI E invatase deja
## lectia (1651 de piese in 15 noduri MultiMesh) - aici se aplica la fel.
## Felia tine culling-ul util: un singur MultiMesh pe toata pista ar avea
## AABB-ul cat harta si s-ar desena mereu, deci se taie pe segmente de tur.
var _buckets: Dictionary = {}

## In cate felii longitudinale se taie pista pentru culling.
const FELII := 12


func _raw(model: String, base: String, pos: Vector3, yaw: float,
		scl: float) -> void:
	# POARTA UNICA. Garda sta AICI, nu in `_felie_pune`, fiindca satelitii
	# unui pilc se asaza cu raycast propriu si ocoleau verificarea: dupa ce
	# am pus-o doar pe pilcul principal ramaneau 707 piese peste -12 m si una
	# la +16,1 m. Orice piesa trece pe aici, deci o singura verificare le
	# acopera pe toate.
	if not _sub_orice_drum(pos):
		_resp_langa_drum += 1
		return
	_n += 1
	_tri += int(TRI.get(model, 0))
	var felie := int(_frac_curent * float(FELII)) % FELII
	var key := "%s|%d" % [model, felie]
	if not _buckets.has(key):
		_buckets[key] = {"pos": [], "yaw": [], "scl": []}
	# Array-uri Godot simple, NU Packed*: indexarea unui Packed* dintr-un
	# Dictionary intoarce o COPIE, deci `.append()` pe ea se pierde in tacere
	# si toate nodurile ies cu `positions = PackedVector3Array()`.
	# Memoria: append-pe-copie-in-array-netipizat. Conversia in Packed* se
	# face la scriere, in `_emit_buckets`.
	var b: Dictionary = _buckets[key]
	(b["pos"] as Array).append(pos)
	(b["yaw"] as Array).append(yaw)
	(b["scl"] as Array).append(scl)


func _emit_buckets() -> void:
	var keys := _buckets.keys()
	keys.sort()
	var idx := 0
	for key: String in keys:
		var parts := key.split("|")
		var model: String = parts[0]
		var felie: String = parts[1]
		var b: Dictionary = _buckets[key]
		var pos: Array = b["pos"]
		var yaw: Array = b["yaw"]
		var scl: Array = b["scl"]
		# GARDA: un bucket gol inseamna ca instantele s-au pierdut pe drum
		# (asa s-a manifestat bug-ul de copie). Fara ea, scena primeste 60 de
		# noduri fara nicio pozitie si captura arata IDENTIC cu cea de baza —
		# adica exact tiparul `sonda-masura-alt-obiect`: cifra perfecta din
		# prima nu e succes, e mecanism neconectat.
		if pos.is_empty():
			push_error("bucket gol: %s" % key)
			continue
		idx += 1
		_out.append('[node name="Pod_%s_f%s" type="MultiMeshInstance3D" parent="%s"]'
			% [model, felie, ZONE])
		_out.append('script = ExtResource("flock")')
		_out.append('model = ExtResource("%s")' % RES[model])
		# Clasa de textura: aceeasi ca restul zidariei/rocii de pe pista, deci
		# ZERO materiale noi. Copacii raman pe materialul de lume.
		if model.begins_with("moss_boulder"):
			_out.append('tri_class = "inca_stone"')
		_out.append("seed_value = %d" % (70000 + idx))
		# Cotele vin din raycast pe TerrainBody la generare. `snap_to_ground`
		# ar recalcula la rulare pe sampler-ul NETED, care extrapoleaza
		# (memoria terrain-mesh-y-extrapoleaza) - deci ramane fals.
		_out.append("snap_to_ground = false")
		var sp := PackedStringArray()
		for p in pos:
			sp.append("%f, %f, %f" % [p.x, p.y, p.z])
		_out.append("positions = PackedVector3Array(%s)" % ", ".join(sp))
		var sy := PackedStringArray()
		for y in yaw:
			sy.append("%f" % y)
		_out.append("yaws = PackedFloat32Array(%s)" % ", ".join(sy))
		var ss := PackedStringArray()
		for s in scl:
			ss.append("Vector3(%f, %f, %f)" % [s, s, s])
		_out.append("scale3_list = Array[Vector3]([%s])" % ", ".join(ss))
		_out.append("")
	print("; %d noduri MultiMesh" % idx)


func _write() -> void:
	_emit_buckets()
	if _out_path.is_empty():
		for line in _out:
			print(line)
		return
	var fa := FileAccess.open(_out_path, FileAccess.WRITE)
	if fa == null:
		push_error("nu pot scrie %s" % _out_path)
		return
	for line in _out:
		fa.store_line(line)
	fa.close()
	print("; scris %s" % _out_path)


## Cota solului din coliziunea REALA (TerrainBody), nu din campul neted
## (memoria terrain-mesh-y-extrapoleaza).
func _sol(x: float, z: float) -> float:
	var sp := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus, z), Vector3(x, -500.0, z))
	q.collide_with_areas = false
	var r := sp.intersect_ray(q)
	return float((r["position"] as Vector3).y) if not r.is_empty() else -999.0
