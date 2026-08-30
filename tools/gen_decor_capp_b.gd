extends Node
## Generator de decor MANUAL pentru POI B — PADUREA DE HORNURI (Track13,
## frac 0.04-0.18). Ca la Chongqing: nu e sonda, e unealta care CALCULEAZA
## transformarile ce se lipesc in Track13.tscn sub `DecorManual`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorCappB.tscn
##
## Ce decide compozitia, si de ce cifrele sunt astea:
##
## 1. DRUMUL TRECE PRINTRE HORNURI, nu pe langa. Referinta v3 greseste aici
##    (brief §9 v0.1b o spune explicit), deci hornurile se aseaza ALTERNATIV
##    pe cele doua parti, la pas mic, ca banda sa se stranga si sa se largeasca
##    intre ele. Masurat: half_width e 6.5 m in S-uri, deci muchia asfaltului
##    e la 6.5 m de ax; "2-4 m de banda" = piatra la 8.5-10.5 m de ax.
##
## 2. UMBRELE TAIE DRUMUL. Soarele temei: elevatie 13 grade, azimut 60.
##    Umbra se intinde pe XZ catre (+0.866, +0.5) — derivat din
##    `sun_rotation_deg` (-13, -120, 0), nu ales. Un horn de 14 m arunca 60.6 m
##    de umbra. Ca sa TAIE banda, hornul trebuie pe partea din care umbra intra
##    pe drum: masurat pe tot POI B, dot(side, umbra) > 0 peste tot, deci
##    partea MINUS a lui `_side_at` e cea insorita.
##    De aceea hornurile INALTE (c=17.4, triple=18.6, b=14.6) stau pe -side.
##
## 3. INALTIMEA E DERIVATA. Frustumul vede 10 + 0.093*d; la 11 m de ax vezi
##    ~11 m, la 20 m vezi ~12 m. Hornurile de 10-18 m de langa banda sunt
##    exact plafonul — palaria se vede cand te apropii. Nimic peste 18.6 m
##    langa drum; siluetele de 30 m sunt treaba altui POI.
##
## 4. POARTA. `twin_chimney_gate` masurat pe vertecsi: gol liber 13.2 m latime
##    pana la y=12.4, apoi arcul care leaga cele doua palarii. Adica exact
##    "12 m tavan" din brief. Primeste `coliziune = "mesh"` (hull-ul unui arc
##    e un bloc plin, adica zid invizibil peste sosea) plus `camera_blocker`
##    (lectia Liziba: fara el camera trece prin arc ca prin aer).

const TRACK := "res://scenes/tracks/Track13.tscn"

## id-urile ext_resource asa cum trebuie sa apara in Track13.tscn.
const RES := {
	"rocks/chimney_a": "10_ch_a",
	"rocks/chimney_b": "11_ch_b",
	"rocks/chimney_c": "12_ch_c",
	"rocks/chimney_d": "13_ch_d",
	"rocks/chimney_mushroom": "14_ch_mush",
	"rocks/chimney_triple": "15_ch_tri",
	"structures/twin_chimney_gate": "16_gate",
	"buildings/dovecote": "17_dovecote",
	"buildings/cave_house_a": "18_house_a",
	"buildings/cave_house_b": "19_house_b",
	"rocks/rock_church_facade": "20_church",
	"plants/pigeon": "21_pigeon",
	"plants/shrub_dry": "22_shrub",
}

## Raza la baza pentru fiecare model, ca sa se poata calcula degajarea fata de
## muchia asfaltului. Din AABB-ul masurat (ProbeCappB), jumatate din latime.
## Razele sunt CITITE din AABB-ul .glb-urilor (max pe X si Z), nu estimate.
## Dupa trecerea hornurilor de la fus la con (build_cappadocia_tuff.py) bazele
## s-au latit cu 1-2 m, si tabelul vechi le-ar fi asezat ca si cum ar fi
## ramas subtiri: piesele intrau in carosabil, iar camera de captura ajungea in
## spatele lor. Cine mai atinge proportiile in Blender REGENEREAZA si cifrele
## astea — garda de mai jos se bazeaza pe ele.
const BASE_R := {
	"rocks/chimney_a": 3.24, "rocks/chimney_b": 3.61, "rocks/chimney_c": 4.35,
	"rocks/chimney_d": 3.71, "rocks/chimney_mushroom": 3.09,
	"rocks/chimney_triple": 5.79, "buildings/dovecote": 2.34,
	"buildings/cave_house_a": 3.15, "buildings/cave_house_b": 3.96,
	"rocks/rock_church_facade": 4.73,
}

## Cat spatiu ramane intre muchia asfaltului si piatra. Briefull cere 2-4 m.
const CLEAR_MIN: float = 2.0

## Fractia pe care sta poarta. Aleasa pe o portiune DREAPTA (0.145-0.160 are
## lateralele constante (0.20, 0.98), deci banda merge drept): pe o curba, cele
## doua picioare la 13.2 m gol ar fi taiat coarda si unul ar fi intrat in asfalt.
const GATE_FRAC: float = 0.152

var _track: Track
var _sampler: TrackSideSampler
var _out: Array[String] = []
var _n := 0
var _rng := RandomNumberGenerator.new()
var _warn := 0


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_sampler = _track._sampler
	_rng.seed = 130804
	_forest()
	_gate()
	_dovecote_and_life()
	print("")
	for line in _out:
		print(line)
	print("; asezate %d piese, %d avertismente de degajare" % [_n, _warn])
	get_tree().quit(0)


# ------------------------------------------------------------------ compozitia

## Padurea propriu-zisa. Un sir ALTERNANT de-a lungul benzii: la fiecare pas
## se pune un horn pe o parte, la pasul urmator pe cealalta, cu decalaj — asa
## drumul chiar se strecoara PRINTRE ele, in loc sa treaca pe langa un gard.
##
## Pasul e mic (0.006 din tur, ~12 m) fiindca densitatea e subiectul: Pasabag
## are hornurile lipite. La pasul asta si banda de 13 m sunt mereu 3-4 conuri
## in cadru, doua dintre ele mai aproape de 12 m.
func _forest() -> void:
	# Modelele INALTE stau pe partea insorita (-side): umbra lor traverseaza
	# banda. Pe +side stau cele mai scunde, ca sa incadreze fara sa fure lumina.
	var tall: Array[String] = [
		"rocks/chimney_c", "rocks/chimney_triple", "rocks/chimney_b",
		"rocks/chimney_d", "rocks/chimney_c", "rocks/chimney_b",
	]
	var short: Array[String] = [
		"rocks/chimney_a", "rocks/chimney_mushroom", "rocks/chimney_d",
		"rocks/chimney_a", "rocks/chimney_mushroom", "rocks/chimney_b",
	]
	var f := 0.043
	var k := 0
	while f < 0.176:
		# Poarta isi are propria fractie; se lasa liber in jurul ei.
		if absf(f - GATE_FRAC) < 0.0055:
			f += 0.0060
			k += 1
			continue
		# Palcuri, nu sir: conurile stau in grupuri, iar intre grupuri ramane o
		# fereastra prin care se vede adancimea. Un pas constant citeste ca
		# alee de stalpi (referinta v3 le are in palcuri).
		var in_cluster := (k % 8) < 6
		# PARTEA INSORITA PRIMESTE UN HORN LA FIECARE PAS, nu la doi.
		#
		# Prima runda alterna partile, deci pe partea care arunca umbra ramanea
		# un con la ~24 m. Masurat pe captura de la 0.10: umbrele existau, dar
		# cadeau rar si citeau ca pete in textura drumului, nu ca dungi. Umbra
		# unui horn de 14 m mătură 18,9 m din latimea benzii (calcul din
		# proiectia masurata de ProbeCappShadow), deci la un pas de 12 m
		# dungile se ating si banda chiar iese VARGATA — care e identitatea
		# ceruta, nu un bonus.
		if in_cluster:
			_place(tall[k % tall.size()], "hornSoare", f, -1.0,
				CLEAR_MIN + _rng.randf_range(0.0, 1.6),
				_rng.randf_range(0.0, TAU), _rng.randf_range(0.92, 1.12))
		# Partea umbrita ramane alternanta: acolo conurile incadreaza cadrul si
		# strang banda, dar nu au ce umbra sa dea peste drum.
		if in_cluster and k % 2 == 1:
			_place(short[(k / 2) % short.size()], "hornUmbra", f + 0.0016, 1.0,
				CLEAR_MIN + _rng.randf_range(0.0, 2.2),
				_rng.randf_range(0.0, TAU), _rng.randf_range(0.92, 1.12))
		var sunny := k % 2 == 0
		var pool: Array[String] = tall if sunny else short
		var gap := CLEAR_MIN + _rng.randf_range(0.0, 2.0)
		# Al doilea rand, mai departe si mai rar: padurea trebuie sa aiba
		# ADANCIME, altfel e o alee cu doi stalpi. Ce se vede INTRE conurile
		# din fata e tot ce desparte o padure de un gard.
		if k % 3 == 1:
			_place(pool[(k + 3) % pool.size()], "hornSpate", f + 0.0022,
				-1.0 if sunny else 1.0, gap + _rng.randf_range(9.0, 16.0),
				_rng.randf_range(0.0, TAU), _rng.randf_range(0.85, 1.05))
		if k % 4 == 2:
			_place(short[(k + 1) % short.size()], "hornFund", f - 0.0030,
				1.0 if sunny else -1.0, gap + _rng.randf_range(14.0, 24.0),
				_rng.randf_range(0.0, TAU), _rng.randf_range(0.8, 1.0))
		f += 0.0060
		k += 1


## Poarta de hornuri gemene. Se aseaza PE AX, cu golul de-a lungul lateralei
## benzii (modelul are deschiderea pe X local, deci X local trebuie sa fie
## lateralul, iar Z local directia de mers).
func _gate() -> void:
	var n := _track.baked.size()
	var i := int(GATE_FRAC * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i)
	var yaw := atan2(s.x, s.z)
	var g := _sampler.ground_y(p.x, p.z)
	print("; poarta la frac %.3f: ax=(%.2f, %.2f) sosea_y=%.2f teren_y=%.2f half_w=%.2f" % [
		GATE_FRAC, p.x, p.z, p.y, g, _track.width_at_index(i)])
	_raw("structures/twin_chimney_gate", "poarta_hornuri_gemene",
		Vector3(p.x, g, p.z), yaw, 1.0, "mesh", true)


## Porumbarul si viata din jurul lui. Brief §2 B: porumbeii tasnesc din
## porumbar cand treci. Porumbarul e o piesa de 7 m — sta la marginea padurii,
## pe partea insorita, ca sa aiba fatada in lumina; porumbeii sunt decor
## fantoma (nimic din ce zboara n-are voie sa opreasca o masina).
func _dovecote_and_life() -> void:
	_place("buildings/dovecote", "porumbar", 0.108, -1.0, 3.0,
		0.0, 1.0, "hull", "toward")
	# Porumbei in aer deasupra porumbarului, in evantai. Nu e un stol animat
	# (aia ar fi un hazard), e silueta care spune "aici e viata".
	for j in 7:
		var a := float(j) * 0.9 + 0.4
		_place("plants/pigeon", "porumbel", 0.108 + 0.0016 * float(j),
			-1.0, 4.0 + 2.2 * float(j % 3),
			a, 1.0, "none", "", 7.6 + 1.4 * float(j % 4))
	# Doua conuri LOCUITE si o fatada de biserica rupestra: stratul "lumea
	# sapata" din brief §0.1 (20% din pondere). Fara ele padurea e geologie
	# curata, si exact asta o desparte de un camp de stanci.
	_place("buildings/cave_house_a", "casa_con", 0.064, 1.0, 4.5,
		0.0, 1.0, "hull", "toward")
	_place("buildings/cave_house_b", "casa_con", 0.128, 1.0, 5.0,
		0.0, 1.05, "hull", "toward")
	_place("rocks/rock_church_facade", "biserica_rupestra", 0.092, -1.0, 8.0,
		0.0, 1.0, "hull", "toward")
	# Tufe uscate la baza conurilor — rup linia de contact dintre piatra si
	# pamant, care altfel e o taietura curata si citeste ca decupaj. In
	# referinta v3 fiecare con are verdeata la picior; imprastiate uniform, ca
	# in prima runda, nu se vedeau deloc de la nivelul soferului.
	#
	# De aceea stau in PERECHI langa aceleasi fractii pe care s-au asezat
	# hornuri, la 1-4 m de muchie: acolo le prinde cadrul, chiar sub piatra.
	for j in 26:
		var f := 0.045 + 0.0050 * float(j)
		var sgn := -1.0 if j % 2 == 0 else 1.0
		_place("plants/shrub_dry", "tufa", f, sgn,
			_rng.randf_range(1.0, 4.0), _rng.randf_range(0.0, TAU),
			_rng.randf_range(0.9, 1.5), "none")
		if j % 3 == 0:
			_place("plants/shrub_dry", "tufa", f + 0.0014, sgn,
				_rng.randf_range(4.0, 11.0), _rng.randf_range(0.0, TAU),
				_rng.randf_range(0.8, 1.4), "none")


# ------------------------------------------------------------------ asezarea

## Aseaza o piesa la `frac`, pe partea `side_sign`, la `gap` metri de MUCHIA
## asfaltului (nu de ax — muchia e ce vede jucatorul). Cota vine din teren.
func _place(model: String, base: String, frac: float, side_sign: float,
		gap: float, yaw: float, scl: float, mode: String = "hull",
		face: String = "", lift: float = 0.0) -> void:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i) * side_sign
	var half := _track.width_at_index(i)
	var r: float = BASE_R.get(model, 0.6)
	var d := half + gap + r
	var q := p + s * d
	var g := _sampler.ground_y(q.x, q.z)
	# Garda: piatra n-are voie sa intre in carosabil. Se masoara distanta de la
	# ax pana la MARGINEA piesei, nu pana la centru — capcana din
	# `decor-manual-coliziune`.
	if d - r < half + 0.5:
		_warn += 1
		print("; ATENTIE %s la frac %.3f: marginea la %.2f m de ax, banda %.2f" % [
			model, frac, d - r, half])
	var y := g + lift
	# Cat de mult sta piesa sub cota soselei? Daca terenul e mult mai jos,
	# hornul se scufunda si palaria coboara din frustum — se raporteaza.
	if lift == 0.0 and p.y - g > 1.2:
		print("; nota %s la frac %.3f: teren cu %.2f m sub sosea" % [model, frac, p.y - g])
	var a := yaw
	if face == "toward":
		# Fatada se uita spre drum: -s este directia catre ax.
		a = atan2(-s.x, -s.z)
	_raw(model, base, Vector3(q.x, y, q.z), a, scl, mode, false)


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String, blocker: bool) -> void:
	_n += 1
	var c := cos(yaw) * scl
	var s := sin(yaw) * scl
	_out.append('[node name="%s%d" parent="DecorManual/ZoneB_PadureaHornurilor" instance=ExtResource("%s")]'
		% [base, _n, RES[model]])
	_out.append("transform = Transform3D(%f, 0, %f, 0, %f, 0, %f, 0, %f, %f, %f, %f)"
		% [c, -s, scl, s, c, pos.x, pos.y, pos.z])
	if mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	if blocker:
		_out.append("metadata/camera_blocker = true")
	_out.append("")
