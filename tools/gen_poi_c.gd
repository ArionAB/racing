extends Node
## Generatorul POI-ului C (cornisa Vaii Rosii): calculeaza pe geometria REALA a
## lui Track13 pozitiile baloanelor, ale falezei in benzi si ale multimii din
## vale, si scrie fragmentul de .tscn cu NODURI EDITABILE (memoria
## `decor-manual-sursa-de-adevar`: pe toata dezvoltarea decorul sta ca noduri in
## scena, nu in cod; promovarea in cod se face O DATA, la delivery).
##
## Nu deseneaza nimic din ochi. Politele celor trei baloane ancorate sunt
## CAUTATE — cea mai apropiata de ax cu coloana verticala libera pana peste
## banda — fiindca exact asta a picat la ProbeBalloon (vi)/(viii): un tarus pe
## fundul vaii urca in peretele inclinat. Cotele din vale vin din `ground_y`,
## nu dintr-o presupunere despre "fundul vaii".
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenPoiC.tscn

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"
const OUT: String = "res://tools/poi_c_nodes.txt"
const BASKET_HALF: float = 2.4
const F0: float = 0.185
const F1: float = 0.38
const SIDE: float = 1.0
## Cele trei baloane ancorate, defazate cu 1/3 (brief §2 POI C).
const TETHERED: Array[float] = [0.225, 0.285, 0.325]
## Hairpinul de la capatul cornisei: acolo sta balonul arzatorului.
const HAIRPIN: float = 0.352
## Cat de mult intra cosul peste marginea asfaltului. Cu 1.2 m, un cos de 4.8 m
## acopera un sfert din latimea lui peste banda: destul cat sa te oblige sa-l
## ocolesti, prea putin cat sa inchida drumul (banda are 7 m semilatime).
const LANE_BITE: float = 1.2
## Inaltimea piesei `cliff_band_module.glb`, masurata pe GLB (bounds y 0..12.4).
## Originea ei e la BAZA, deci cota scrisa in .tscn e a talpii.
const BAND_H: float = 12.4
## Cat de mult trebuie sa fi coborat terenul fata de banda ca sa spunem ca
## acolo incepe faleza (si nu umarul drumului).
const BAND_DROP: float = 4.0
## Cat se impinge piesa in afara buzei, ca fata ei sa fie suprafata vazuta si nu
## versantul de tuf din spatele ei. Vezi nota din `_gen_cliff_bands`.
const BAND_FACE: float = 2.6
## Grupul-parinte, o singura data scris.
const GROUP: String = "DecorManual/C) Cornisa Vaii Rosii"

var _track: Track
var _sampler: TrackSideSampler
var _n: int = 0
var _lines: Array[String] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 13
	_track = (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	_sampler = _track.get("_sampler")
	_n = _track.baked.size()
	# Generatorul masoara pista GOALA: daca isi vede propriul decor din rulajul
	# anterior, politele s-ar cauta peste baloanele deja puse si a doua rulare
	# ar da alt rezultat decat prima. Se scoate grupul inainte de orice raza.
	var old := _track.get_node_or_null("DecorManual")
	if old != null:
		_track.remove_child(old)
		old.queue_free()
		await get_tree().physics_frame
		await get_tree().physics_frame
	_head()
	_gen_tethered()
	_gen_burner()
	_gen_cliff_bands()
	_gen_valley_crowd()
	_gen_far_crowd()
	FileAccess.open(OUT, FileAccess.WRITE).store_string("\n".join(_lines) + "\n")
	print("scris ", OUT)
	_track.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)


func _lane(f: float) -> Dictionary:
	var i := int(f * float(_n)) % _n
	var p: Vector3 = _track.baked[i]
	var sd: Vector3 = _sampler.side_at(i) * SIDE
	return {"i": i, "p": p, "sd": sd}


## Transformarea .tscn: rotatie pe Y (radiani) plus scara uniforma.
func _xf(pos: Vector3, ry: float = 0.0, sc: float = 1.0) -> String:
	var c := cos(ry) * sc
	var s := sin(ry) * sc
	return "Transform3D(%.4f, 0, %.4f, 0, %.4f, 0, %.4f, 0, %.4f, %.3f, %.3f, %.3f)" \
		% [c, -s, sc, s, c, pos.x, pos.y, pos.z]


func _add(s: String) -> void:
	_lines.append(s)


func _node(name: String, parent: String, res: String) -> void:
	_add("")
	_add("[node name=\"%s\" parent=\"%s\" instance=ExtResource(\"%s\")]"
		% [name, parent, res])


func _head() -> void:
	_add("")
	_add("[node name=\"DecorManual\" type=\"Node3D\" parent=\".\"]")
	_add("script = ExtResource(\"4_wprop\")")
	_add("")
	_add("[node name=\"C) Cornisa Vaii Rosii\" type=\"Node3D\" parent=\"DecorManual\"]")


## Cauta polita: cea mai apropiata de ax pe care coloana verticala e libera
## pana peste cota benzii. Intoarce (offset, cota) sau (-1, 0).
func _find_ledge(p: Vector3, sd: Vector3) -> Vector2:
	var o := 7.0
	while o <= 16.0:
		var q := p + sd * o
		var y := 13.7
		while y < p.y - 6.0:
			if _clear(q, sd, y + 1.0, p.y + 2.0):
				return Vector2(o, y)
			y += 0.5
		o += 0.2
	return Vector2(-1.0, 0.0)


## Cele TREI baloane ancorate care urca la banda.
func _gen_tethered() -> void:
	print("=== cele trei baloane ancorate ===")
	var envs := ["8_env_a", "9_env_b", "10_env_c"]
	var k := 0
	for f in TETHERED:
		var L := _lane(f)
		var p: Vector3 = L["p"]
		var sd: Vector3 = L["sd"]
		var hit := _find_ledge(p, sd)
		if hit.x < 0.0:
			push_warning("POI C: fara polita la frac %.3f" % f)
			continue
		# Tras spre drum cu `LANE_BITE`: cautarea intoarce cel mai apropiat
		# punct cu coloana LIBERA, adica exact buza — acolo cosul doar atinge
		# marginea asfaltului. Brief-ul §2 POI C cere ca „cosul iti intra in
		# banda" 4 s, deci marginea lui dinspre drum trebuie sa treaca DINCOLO
		# de marginea asfaltului. Muscatura e verificata de ProbeCorniceC.
		var off: float = maxf(hit.x - LANE_BITE, _sampler.half_width_at(L["i"]))
		var gy := hit.y
		var q2 := p + sd * off
		# Cursa: podeaua cosului ajunge cu 0.8 m PESTE cota benzii, ca sa fie
		# chiar IN banda, nu la marginea ei (ProbeBalloon foloseste acelasi
		# LANE_OVERSHOOT pentru balonul care intra in drum).
		var rise := p.y + 0.8 - gy
		var yaw := atan2(sd.x, sd.z)
		print("  frac %.3f -> polita %.1f m de ax, y=%.2f, cursa %.2f (banda %.2f)"
			% [f, off, gy, rise, p.y])
		_add("")
		_add("[node name=\"Balon ancorat %d\" type=\"Node3D\" parent=\"%s\"]"
			% [k + 1, GROUP])
		_add("transform = %s" % _xf(Vector3(q2.x, gy, q2.z), yaw))
		_add("script = ExtResource(\"5_balloon\")")
		_add("period = 28.0")
		_add("ground_hold = 8.0")
		_add("rise_time = 8.0")
		_add("hold = 4.0")
		# Defazare cu 1/3 de ciclu: mereu cel mult unul in banda (ProbeBalloon (v)).
		_add("phase = %.4f" % (float(k) / 3.0))
		_add("height = %.2f" % rise)
		_add("basket_model = ExtResource(\"7_basket\")")
		_add("envelope_model = ExtResource(\"%s\")" % envs[k % envs.size()])
		# Cosul GLB are 2.16 m latime; colizorul hazardului are 4.8 m (dat de
		# ampatamentul autobuzului). Modelul se scaleaza ca sa arate cat e solid.
		_add("model_scale = 2.2")
		# Panza ramane la scara ei din kit (12 m inalta): vezi nota din
		# BalloonHazard._build_envelope pentru de ce nu urmeaza cosul.
		_add("envelope_scale = 1.0")
		# Tarusul cu cablul, langa balon: piesa din kit, pur decor.
		_node("Tarus %d" % (k + 1), GROUP, "12_tether")
		_add("transform = %s" % _xf(
			Vector3(q2.x + sd.x * 2.6, gy, q2.z + sd.z * 2.6), yaw))
		k += 1


## Balonul ARZATORULUI, la hairpinul din capatul cornisei: sufla spre EXTERIOR,
## adica spre gol. Directia se deriva din latura vaii, nu se scrie de mana.
func _gen_burner() -> void:
	var L := _lane(HAIRPIN)
	var p: Vector3 = L["p"]
	var sd: Vector3 = L["sd"]
	# Ancorat pe umarul de dincolo de asfalt: langa curba, nu in ea. Cota se
	# CAUTA, nu se ia de la primul offset: la 9 m de ax terenul e deja podeaua
	# vaii (masurat: y=13.7 sub o banda la 34 m), deci un balon pus acolo ar
	# atarna 20 m sub drum si flacara n-ar intra niciodata in cadru. Se ia cel
	# mai departat offset la care umarul e inca aproape de cota benzii.
	var off := 5.0
	var q := p + sd * off
	var gy := _sampler.ground_y(q.x, q.z)
	var o := 5.0
	while o <= 11.0:
		var t := p + sd * o
		var ty := _sampler.ground_y(t.x, t.z)
		if ty < p.y - 3.0:
			break
		off = o
		q = t
		gy = ty
		o += 0.5
	# Nodul "priveste" pe -Z local si sufla incotro priveste (vezi
	# BurnerHazard.blow_dir). Suflul trebuie sa impinga masina spre EXTERIOR,
	# adica pe +sd (dinspre drum spre gol), deci -Z trebuie sa fie +sd.
	var yaw := atan2(-sd.x, -sd.z)
	print("=== arzatorul la frac %.3f: off %.1f m, (%.1f, %.2f, %.1f), banda y=%.2f ==="
		% [HAIRPIN, off, q.x, gy, q.z, p.y])
	_add("")
	_add("[node name=\"Balonul arzatorului (hairpin)\" type=\"Node3D\" parent=\"%s\"]" % GROUP)
	_add("transform = %s" % _xf(Vector3(q.x, gy, q.z), yaw))
	_add("script = ExtResource(\"6_burner\")")
	_add("period = 17.0")
	_add("telegraph = 1.0")
	_add("blow = 0.8")
	_add("phase = 0.35")
	_add("accel = 9.0")
	_add("radius = 12.0")
	_add("basket_model = ExtResource(\"7_basket\")")
	_add("envelope_model = ExtResource(\"10_env_c\")")
	_add("model_scale = 2.2")
	_add("envelope_scale = 1.0")


## Faleza in BENZI sub cornisa: `cliff_band_module` asezat pe peretele de sub
## buza, pe toata lungimea POI-ului. Benzile de culoare sunt in TEXTURA piesei
## (brief §5.1), nu in geometrie — deci nu costa niciun material in plus.
func _gen_cliff_bands() -> void:
	_add("")
	_add("[node name=\"Faleza in benzi\" type=\"Node3D\" parent=\"%s\"]" % GROUP)
	var parent := GROUP + "/Faleza in benzi"
	var f := F0 + 0.004
	var k := 0
	while f <= F1 - 0.004:
		var L := _lane(f)
		var p: Vector3 = L["p"]
		var sd: Vector3 = L["sd"]
		# BUZA se CAUTA, nu se presupune la un offset fix. Pe portiunile in urcare
		# terenul de la 10.5 m lateral e mai SUS decat banda, iar o piesa asezata
		# fata de cota benzii ajunge atunci deasupra drumului — masurat pe
		# captura de la frac 0.36, unde o lespede rosie plutea peste sosea.
		# Se ia primul offset la care terenul chiar a plecat sub banda.
		var off := -1.0
		var gy := 0.0
		var o := _sampler.half_width_at(L["i"]) + 0.5
		while o <= 16.0:
			var t := p + sd * o
			var ty := _sampler.ground_y(t.x, t.z)
			if ty < p.y - BAND_DROP:
				off = o
				gy = ty
				break
			o += 0.5
		if off < 0.0:
			f += 0.009
			k += 1
			continue
		# Piesa se aseaza pe FATA VAZUTA a peretelui, nu in spatele ei. Cutia ei
		# are 6 m in adancime (bounds z -3.82..2.25), iar terenul de la `off`
		# incolo coboara: lasata pe linia buzei, piesa ramane INGROPATA in
		# versant si din masina se vede tot tuf crem, adica exact culoarea pe
		# care POI-ul C n-o vrea. Se impinge in afara cu jumatate din adancimea
		# ei plus o palma, ca fata rosie sa fie prima suprafata vazuta.
		var q := p + sd * (off + BAND_FACE)
		# ORIGINEA PIESEI E LA BAZA EI (masurat pe GLB: bounds y 0 .. 12.4), deci
		# cota care se scrie e a TALPII, nu a coamei. Coama primului rand sta
		# chiar sub buza — si niciodata peste ea, oricat ar urca drumul.
		var crest := minf(p.y - 1.2, gy + BAND_DROP)
		# Randuri suprapuse in jos pana la podeaua vaii: faleza e continua, nu
		# o singura felie agatata sub buza.
		var floor_y := _sampler.ground_y(
			p.x + sd.x * 26.0, p.z + sd.z * 26.0)
		var rows := clampi(int(ceil((crest - floor_y) / BAND_H)), 1, 3)
		var yaw := atan2(sd.x, sd.z)
		for r in rows:
			var base := crest - BAND_H * float(r + 1)
			if base < floor_y - BAND_H:
				break
			_node("banda%d_%d" % [k, r], parent, "14_band")
			_add("transform = %s" % _xf(Vector3(q.x, base, q.z), yaw))
		f += 0.009
		k += 1
	print("=== faleza in benzi: %d pozitii ===" % k)


## MULTIMEA din vale: 20-30 de baloane in toate fazele (pe pamant, umflandu-se,
## in aer). Sunt DECOR: silueta lor spune faza, nu o stare de cod.
func _gen_valley_crowd() -> void:
	_add("")
	_add("[node name=\"Multimea din vale\" type=\"Node3D\" parent=\"%s\"]" % GROUP)
	var parent := GROUP + "/Multimea din vale"
	var envs := ["8_env_a", "9_env_b", "10_env_c"]
	var placed := 0
	var f := F0 + 0.01
	while f <= F1 - 0.01:
		var L := _lane(f)
		var p: Vector3 = L["p"]
		var sd: Vector3 = L["sd"]
		# Trei benzi de departare, ca valea sa aiba adancime, nu un singur rand.
		for off: float in [24.0, 40.0, 58.0]:
			var q := p + sd * (off + _rng.randf_range(-6.0, 6.0))
			var gy := _sampler.ground_y(q.x, q.z)
			var yaw := _rng.randf_range(0.0, TAU)
			var roll := _rng.randf()
			if roll < 0.28:
				# Pe pamant: panza intinsa.
				_node("balon%d_panza" % placed, parent, "11_landed")
				_add("transform = %s" % _xf(Vector3(q.x, gy, q.z), yaw))
			elif roll < 0.58:
				# Se umfla: plicul turtit pe verticala, inca la sol.
				_node("balon%d_umfla" % placed, parent, envs[placed % envs.size()])
				_add("transform = Transform3D(%.4f, 0, %.4f, 0, %.4f, 0, %.4f, 0, %.4f, %.3f, %.3f, %.3f)"
					% [cos(yaw), -sin(yaw), 0.45, sin(yaw), cos(yaw), q.x, gy, q.z])
			else:
				# In aer: plicul intreg, ridicat, cu cosul atarnat sub el.
				var lift := _rng.randf_range(2.0, 18.0)
				_node("balon%d_sus" % placed, parent, envs[placed % envs.size()])
				_add("transform = %s" % _xf(Vector3(q.x, gy + lift + 3.0, q.z), yaw))
				_node("balon%d_cos" % placed, parent, "7_basket")
				_add("transform = %s" % _xf(Vector3(q.x, gy + lift, q.z), yaw))
			placed += 1
		f += 0.028
	print("=== multimea din vale: %d baloane ===" % placed)


## Baloanele DEPARTATE: `balloon_far` (piesa simplificata din kit). NU in
## MultiMesh — memoria `multimesh-oglindire-culling`, si oricum regula sesiunii
## cere noduri EDITABILE.
func _gen_far_crowd() -> void:
	_add("")
	_add("[node name=\"Baloane departate\" type=\"Node3D\" parent=\"%s\"]" % GROUP)
	var parent := GROUP + "/Baloane departate"
	var placed := 0
	var f := F0 + 0.02
	while f <= F1 - 0.02:
		var L := _lane(f)
		var p: Vector3 = L["p"]
		var sd: Vector3 = L["sd"]
		for off: float in [86.0, 120.0, 160.0]:
			var q := p + sd * (off + _rng.randf_range(-14.0, 14.0))
			var gy := _sampler.ground_y(q.x, q.z)
			var lift := _rng.randf_range(6.0, 34.0)
			_node("departe%d" % placed, parent, "13_far")
			_add("transform = %s" % _xf(Vector3(q.x, gy + lift, q.z),
				_rng.randf_range(0.0, TAU)))
			placed += 1
		f += 0.045
	print("=== baloane departate: %d ===" % placed)


func _clear(at: Vector3, sd: Vector3, from_y: float, to_y: float) -> bool:
	var space := get_viewport().world_3d.direct_space_state
	var y := from_y
	while y <= to_y:
		for lat: float in [-BASKET_HALF, 0.0, BASKET_HALF]:
			var c := Vector3(at.x, y, at.z) + sd * lat
			var q := PhysicsRayQueryParameters3D.create(
				c + Vector3.UP * 0.5, c - Vector3.UP * 0.5)
			if not space.intersect_ray(q).is_empty():
				return false
		y += 1.0
	return true
