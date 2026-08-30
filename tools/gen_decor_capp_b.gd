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
	# --- runda 6 ------------------------------------------------------------
	# Hornurile CAZUTE (masurate: _b e 20.9 x 6.5 m culcat, _c e 9.9 x 0.98 m
	# moloz) si plopii/via, care aduc singura nuanta non-crem din cadru.
	"rocks/cracked_chimney_a": "25_crk_a",
	"rocks/cracked_chimney_b": "26_crk_b",
	"rocks/cracked_chimney_c": "27_crk_c",
	"plants/poplar_a": "28_poplar_a",
	"plants/poplar_b": "29_poplar_b",
	"plants/vine_row": "30_vine",
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
	"rocks/cracked_chimney_a": 3.29, "rocks/cracked_chimney_b": 10.45,
	"rocks/cracked_chimney_c": 4.95,
	"plants/poplar_a": 1.00, "plants/poplar_b": 1.24,
	"plants/vine_row": 5.04,
}

## Cat spatiu ramane intre muchia asfaltului si piatra. Briefull cere 2-4 m.
const CLEAR_MIN: float = 2.0

## Fractia pe care sta poarta. Aleasa pe o portiune DREAPTA (0.145-0.160 are
## lateralele constante (0.20, 0.98), deci banda merge drept): pe o curba, cele
## doua picioare la 13.2 m gol ar fi taiat coarda si unul ar fi intrat in asfalt.
const GATE_FRAC: float = 0.152

## Ciclul de ARHETIPURI de forma. Lungime 5, adica prima fata de pasul palcului
## (8) si fata de lungimea listelor de modele (6): produsul celor trei cicluri
## se inchide abia dupa 120 de pasi, mult peste cei ~22 ai POI-ului. Practic:
## nicio pereche (model, forma) nu se repeta in POI.
##
## "plain" e in lista intentionat. O padure in care TOATE conurile sunt stramb
## deformate e la fel de sistematica ca una in care niciunul nu e — ochiul
## prinde regula, oricare ar fi ea. Referinta are si fuse drepte.
const FOREST_KINDS: Array[String] = ["belly", "lean", "slim", "squat", "plain"]

## Unde sta ARCADA (doua hornuri legate printr-un pod de roca). Pe fractia asta
## fiindca e a doua portiune dreapta a POI-ului, la ~40 m dupa poarta: se vad
## amandoua in acelasi cadru doar cand esti intre ele, deci nu se citesc ca
## acelasi obiect pus de doua ori.
const ARCH_FRAC: float = 0.1685

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
	_arch()
	_ruins()
	_colour_at_depth()
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
		# ARHETIPUL se roteste pe un ciclu de lungime PRIMA fata de pasul
		# palcului (5 vs 8): asa combinatia (model, arhetip) nu se repeta la
		# fiecare palc, si nu apare al doilea tipar regulat peste primul.
		if in_cluster:
			var kind: String = FOREST_KINDS[k % FOREST_KINDS.size()]
			# Scara pe Y INDEPENDENTA: "squat" e scund si lat, "slim" e inalt si
			# ingust, la aceeasi scara orizontala.
			var sh := _rng.randf_range(0.92, 1.12)
			var sv := sh
			if kind == "squat":
				sv = sh * _rng.randf_range(0.58, 0.74)
			elif kind == "slim":
				sv = sh * _rng.randf_range(1.14, 1.34)
			_place(tall[k % tall.size()], "hornSoare", f, -1.0,
				CLEAR_MIN + _rng.randf_range(0.0, 1.6),
				_rng.randf_range(0.0, TAU), sh, "hull", "", 0.0,
				_shape(kind), sv)
		# Partea umbrita ramane alternanta: acolo conurile incadreaza cadrul si
		# strang banda, dar nu au ce umbra sa dea peste drum.
		if in_cluster and k % 2 == 1:
			var kind2: String = FOREST_KINDS[(k + 3) % FOREST_KINDS.size()]
			var sh2 := _rng.randf_range(0.92, 1.12)
			var sv2 := sh2
			if kind2 == "squat":
				sv2 = sh2 * _rng.randf_range(0.58, 0.74)
			elif kind2 == "slim":
				sv2 = sh2 * _rng.randf_range(1.14, 1.34)
			_place(short[(k / 2) % short.size()], "hornUmbra", f + 0.0016, 1.0,
				CLEAR_MIN + _rng.randf_range(0.0, 2.2),
				_rng.randf_range(0.0, TAU), sh2, "hull", "", 0.0,
				_shape(kind2), sv2)
		var sunny := k % 2 == 0
		var pool: Array[String] = tall if sunny else short
		var gap := CLEAR_MIN + _rng.randf_range(0.0, 2.0)
		# Al doilea rand, mai departe si mai rar: padurea trebuie sa aiba
		# ADANCIME, altfel e o alee cu doi stalpi. Ce se vede INTRE conurile
		# din fata e tot ce desparte o padure de un gard.
		if k % 3 == 1:
			_place(pool[(k + 3) % pool.size()], "hornSpate", f + 0.0022,
				-1.0 if sunny else 1.0, gap + _rng.randf_range(9.0, 16.0),
				_rng.randf_range(0.0, TAU), _rng.randf_range(0.85, 1.05),
				"hull", "", 0.0,
				_shape(FOREST_KINDS[(k + 1) % FOREST_KINDS.size()]))
		if k % 4 == 2:
			_place(short[(k + 1) % short.size()], "hornFund", f - 0.0030,
				1.0 if sunny else -1.0, gap + _rng.randf_range(14.0, 24.0),
				_rng.randf_range(0.0, TAU), _rng.randf_range(0.8, 1.0),
				"hull", "", 0.0,
				_shape(FOREST_KINDS[(k + 4) % FOREST_KINDS.size()]))
		# PERECHI FUZIONATE LA BAZA. Doua conuri la 55-75% din raza bazei unul
		# de altul se intrepatrund, si silueta comuna are DOUA varfuri pe un
		# singur corp — o forma pe care nicio revolutie n-o poate da. Critica a
		# cerut-o pe nume ("lipeste perechi la baza").
		if k % 5 == 3:
			var fuse_side := -1.0 if sunny else 1.0
			var fuse_gap := CLEAR_MIN + _rng.randf_range(0.4, 2.0)
			_place("rocks/chimney_b", "hornGemen", f + 0.0004, fuse_side,
				fuse_gap, _rng.randf_range(0.0, TAU),
				_rng.randf_range(0.90, 1.04), "hull", "", 0.0,
				_shape("belly"), _rng.randf_range(0.86, 1.00))
			# Al doilea, mai mic si DECALAT lateral cu ~2.4 m: intra in primul.
			_place("rocks/chimney_a", "hornGemen", f + 0.0004, fuse_side,
				fuse_gap + 2.4, _rng.randf_range(0.0, TAU),
				_rng.randf_range(0.66, 0.80), "hull", "", 0.0,
				_shape("lean"), _rng.randf_range(0.70, 0.88))
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


## A DOUA ARCADA a POI-ului, pusa LANGA drum, nu peste el.
##
## Critica a cerut-o pe nume: "referinta are un ARC care leaga doua dintre ele".
## Exista deja `twin_chimney_gate` peste sosea la 0.152 — dar aia e o POARTA
## prin care treci, iar din masina se citeste ca poarta de start, nu ca
## geologie. Aceeasi piesa asezata LATERAL, la 9 m de muchie si rotita cu golul
## paralel cu drumul, se vede din profil: doua picioare si un pod de piatra
## intre ele, adica exact silueta ceruta — si de data asta e ceva ce se vede,
## nu ceva prin care se trece.
##
## Scara 0.82 (deschiderea scade de la 13.2 m la ~10.8 m) fiindca la marimea de
## poarta ar fi concurat cu poarta adevarata pentru atentie.
func _arch() -> void:
	var n := _track.baked.size()
	var i := int(ARCH_FRAC * float(n)) % n
	var p := _track.baked[i]
	var sv := _track._side_at(i) * -1.0
	var half := _track.width_at_index(i)
	# Golul ARCADEI e pe X local; ca sa se vada din profil, X local trebuie sa
	# fie DIRECTIA DE MERS, nu lateralul (invers fata de `_gate`).
	var fwd := (_track.baked[(i + 1) % n] - p).normalized()
	var yaw := atan2(fwd.x, fwd.z)
	var d := half + 9.0 + 13.0
	var q := p + sv * d
	var g := _sampler.ground_y(q.x, q.z)
	print("; arcada la frac %.3f: (%.1f, %.1f) teren_y=%.2f" % [
		ARCH_FRAC, q.x, q.z, g])
	_raw("structures/twin_chimney_gate", "arcada_roca",
		Vector3(q.x, g, q.z), yaw, 0.82, "mesh", false)


## HORNURI PRABUSITE. "Cateva prabusite la cioturi" — critica, runda 3 si 6.
##
## De ce conteaza dincolo de varietate: un camp de conuri intacte se citeste ca
## un set de obiecte ASEZATE pe teren. Unul in care doua zac culcate si un al
## treilea s-a facut moloz se citeste ca un PROCES — piatra care se erodeaza si
## cade. Aceeasi diferenta ca intre un decor si un loc.
##
## Piesele erau deja in kit (`cracked_chimney_a/b/c`, PR #364) si n-au fost
## folosite niciodata. `_b` masurat 20.9 x 6.5 m = un trunchi CULCAT; `_c` e
## 9.9 x 0.98 m = dara de moloz. Amandoua se aseaza departe de banda: sunt late,
## si o piatra lata langa asfalt strange drumul mai tare decat un con.
func _ruins() -> void:
	# Ciotul in picioare: acelasi horn, retezat. `cracked_chimney_a` e intreg
	# (16.8 m), deci se ciunteste din scara pe Y — 0.34 lasa un ciot de 5.7 m,
	# sub linia ochiului, adica se vede peste el.
	_place("rocks/cracked_chimney_a", "hornCiot", 0.0625, -1.0, 3.4,
		_rng.randf_range(0.0, TAU), 1.06, "hull", "", 0.0,
		_shape("squat"), 0.34)
	_place("rocks/cracked_chimney_a", "hornCiot", 0.1395, 1.0, 4.2,
		_rng.randf_range(0.0, TAU), 0.92, "hull", "", 0.0,
		_shape("lean"), 0.42)
	# Trunchiurile CAZUTE. Se pun pe partea insorita, unde umbra lor lunga si
	# joasa taie nisipul de-a lungul — o umbra ORIZONTALA intre atatea umbre
	# verticale.
	_place("rocks/cracked_chimney_b", "hornCazut", 0.0785, -1.0, 7.0,
		_rng.randf_range(0.0, TAU), 1.0, "hull")
	_place("rocks/cracked_chimney_b", "hornCazut", 0.1585, 1.0, 9.5,
		_rng.randf_range(0.0, TAU), 0.86, "hull")
	# Molozul: la piciorul cioturilor, ca sa se lege cauza de efect.
	var rubble_f: Array[float] = [0.0640, 0.0800, 0.1180, 0.1410, 0.1600]
	for j in rubble_f.size():
		var fr: float = rubble_f[j]
		var sg := -1.0 if j % 2 == 0 else 1.0
		_place("rocks/cracked_chimney_c", "moloz", fr, sg,
			_rng.randf_range(2.0, 6.5), _rng.randf_range(0.0, TAU),
			_rng.randf_range(0.55, 0.95), "none")


## CULOARE LA MAI MULTE ADANCIMI — cererea (5) a criticii, textual:
## "referinta pune verde la 5 m si la 100 m, si rosu la 20 m si la orizont...
## vegetatie si prop-uri imprastiate cu nuanta reala, distribuite pe tot
## intervalul de adancime, ar face mai mult decat tenta pe straturi".
##
## Ce lipsea in captura de la 0.10: intre tufele de la 3 m si stratul rosu de la
## 141 m nu exista NICIUN eveniment de culoare. Cadrul era monocrom tan pe toata
## adancimea, si de aceea citea plat — nu din cauza luminii.
##
## Plopii sunt raspunsul corect si nu unul ales din lipsa: in Cappadocia reala
## plopii cresc in fundul vailor, unde e apa, si sunt SINGURUL verde din peisaj.
## Verticali si subtiri (2 x 12-15 m), deci nu blocheaza cadrul, dar taie
## silueta crem cu o dunga verde de la baza pana peste linia conurilor.
##
## Distantele sunt ALESE ca sa acopere intervalul, nu imprastiate la intamplare:
## palcuri la ~8 m (langa banda), ~35 m (planul median, cel gol) si ~85 m
## (fundal), plus via care sta jos si aduce verdele la nivelul solului.
func _colour_at_depth() -> void:
	# --- verde APROAPE (6-11 m de muchie): se vede intreg, de la radacina ---
	var near_f: Array[float] = [0.0575, 0.0985, 0.1305, 0.1655]
	for j in near_f.size():
		var sg := -1.0 if j % 2 == 0 else 1.0
		for m in 3:
			_place("plants/poplar_%s" % ("a" if m % 2 == 0 else "b"),
				"plop", near_f[j] + 0.0011 * float(m), sg,
				6.0 + 2.1 * float(m) + _rng.randf_range(0.0, 1.4),
				_rng.randf_range(0.0, TAU),
				_rng.randf_range(0.88, 1.12), "trunk")
	# --- verde la PLANUL MEDIAN (30-45 m): aici era gaura ------------------
	var mid_f: Array[float] = [0.0490, 0.0870, 0.1140, 0.1470, 0.1700]
	for j in mid_f.size():
		var sg2 := 1.0 if j % 2 == 0 else -1.0
		for m in 4:
			_place("plants/poplar_%s" % ("b" if m % 2 == 0 else "a"),
				"plopMediu", mid_f[j] + 0.0009 * float(m), sg2,
				30.0 + 4.5 * float(m) + _rng.randf_range(0.0, 3.0),
				_rng.randf_range(0.0, TAU),
				_rng.randf_range(0.92, 1.20), "trunk")
	# --- verde DEPARTE (75-100 m): palcuri mari, citite ca pata de culoare --
	# Fractiile de FUNDAL sunt alese pe portiuni unde platoul TINE cota: la
	# 0.123-0.127 si 0.160-0.164 terenul cade cu 10-25 m sub sosea (masurat,
	# notele generatorului la prima rulare), adica plopii ar fi stat in rapa, cu
	# coroana sub linia drumului — verde platit si nevazut. Vezi memoria
	# `platoul-de-coridor-ascunde-marea`: cota se citeste, nu se presupune.
	var far_f: Array[float] = [0.0680, 0.1075, 0.1440]
	for j in far_f.size():
		var sg3 := -1.0 if j % 2 == 0 else 1.0
		for m in 6:
			_place("plants/poplar_%s" % ("a" if m % 3 == 0 else "b"),
				"plopDeparte", far_f[j] + 0.0008 * float(m), sg3,
				62.0 + 4.5 * float(m) + _rng.randf_range(0.0, 5.0),
				_rng.randf_range(0.0, TAU),
				_rng.randf_range(1.0, 1.3), "trunk")
	# --- via: verde JOS, la 4-9 m -----------------------------------------
	# Randurile de vita stau pe terase, adica pe orizontala, si se citesc ca
	# lucrare omeneasca. Verdele lor e la nivelul solului, deci umple exact
	# fasia dintre banda si baza conurilor, care era nisip gol.
	var vine_f: Array[float] = [0.0530, 0.0745, 0.1035, 0.1260, 0.1450, 0.1690]
	for j in vine_f.size():
		var sg4 := 1.0 if j % 2 == 0 else -1.0
		var i := int(vine_f[j] * float(_track.baked.size())) % _track.baked.size()
		var nn := _track.baked.size()
		var fw := (_track.baked[(i + 1) % nn] - _track.baked[i]).normalized()
		# Randul de vie (10 m lung pe X local) se aseaza PARALEL cu drumul.
		for m in 2:
			_place("plants/vine_row", "vie", vine_f[j] + 0.0010 * float(m), sg4,
				4.0 + 5.2 * float(m), atan2(fw.x, fw.z),
				_rng.randf_range(0.9, 1.1), "none")


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
		face: String = "", lift: float = 0.0, shape: Dictionary = {},
		scl_y: float = -1.0) -> void:
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
	_raw(model, base, Vector3(q.x, y, q.z), a, scl, mode, false, shape, scl_y)


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String, blocker: bool, shape: Dictionary = {},
		scl_y: float = -1.0) -> void:
	_n += 1
	var c := cos(yaw) * scl
	var s := sin(yaw) * scl
	# Scara pe Y separata de cea orizontala: un horn INDESAT nu e un horn mic,
	# e unul la fel de lat dar mai scund. Cu scara uniforma (tot ce a existat
	# pana la runda 6) silueta ramane identica si se schimba doar cat loc ocupa
	# in cadru — exact reprosul "o singura instanta repetata la N scari".
	var sy := scl if scl_y < 0.0 else scl_y
	_out.append('[node name="%s%d" parent="DecorManual/ZoneB_PadureaHornurilor" instance=ExtResource("%s")]'
		% [base, _n, RES[model]])
	_out.append("transform = Transform3D(%f, 0, %f, 0, %f, 0, %f, 0, %f, %f, %f, %f)"
		% [c, -s, sy, s, c, pos.x, pos.y, pos.z])
	# Scriptul de deformare se pune PE INSTANTA, cu parametrii ei. Nodul ramane
	# editabil: se selecteaza in editor si se trag valorile in Inspector, cu
	# previzualizare (`@tool`).
	if not shape.is_empty():
		_out.append('script = ExtResource("31_shape")')
		for key: String in shape:
			var v: Variant = shape[key]
			if v is int:
				_out.append("%s = %d" % [key, v])
			else:
				_out.append("%s = %f" % [key, v])
	if mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	if blocker:
		_out.append("metadata/camera_blocker = true")
	_out.append("")


## Un set de parametri de forma pentru UN horn. Aici se decide ca padurea sa nu
## mai fie o familie de revolutii.
##
## `kind` alege ARHETIPUL, si arhetipurile sunt cele cerute de critica explicit:
##   "slim"    fus subtire si inalt, gat strangulat sub palarie
##   "squat"   cort indesat, burta jos, lat
##   "belly"   umflat la mijloc (forma clasica de la Pasabag)
##   "lean"    inclinat vizibil, cu ovalizare mare
##   "plain"   aproape drept — TREBUIE sa existe, altfel "toate stramb" e la
##             fel de sistematic ca "toate drepte"
func _shape(kind: String) -> Dictionary:
	var d := {
		"ovality": _rng.randf_range(0.74, 0.92),
		"oval_dir_deg": _rng.randf_range(0.0, 180.0),
		"lean_deg": _rng.randf_range(-3.0, 3.0),
		"lean_dir_deg": _rng.randf_range(0.0, 360.0),
		"bulge": 0.0,
		"bulge_height": _rng.randf_range(0.3, 0.6),
		"bulge_spread": _rng.randf_range(0.25, 0.45),
		"flute_depth": _rng.randf_range(0.035, 0.075),
		"flute_count": _rng.randi_range(7, 14),
		"flute_top": _rng.randf_range(0.72, 0.95),
		"shape_seed": _rng.randi_range(1, 99999),
		"noise_amount": _rng.randf_range(0.02, 0.055),
	}
	match kind:
		"slim":
			d["ovality"] = _rng.randf_range(0.80, 0.94)
			d["bulge"] = _rng.randf_range(-0.26, -0.14)
			d["bulge_height"] = _rng.randf_range(0.62, 0.80)
			d["flute_depth"] = _rng.randf_range(0.075, 0.13)
			d["flute_count"] = _rng.randi_range(10, 16)
		"squat":
			d["ovality"] = _rng.randf_range(0.62, 0.80)
			d["bulge"] = _rng.randf_range(0.22, 0.42)
			d["bulge_height"] = _rng.randf_range(0.18, 0.34)
			d["bulge_spread"] = _rng.randf_range(0.38, 0.60)
			d["flute_depth"] = _rng.randf_range(0.02, 0.05)
		"belly":
			d["ovality"] = _rng.randf_range(0.68, 0.86)
			d["bulge"] = _rng.randf_range(0.18, 0.34)
			d["bulge_height"] = _rng.randf_range(0.40, 0.56)
			d["flute_depth"] = _rng.randf_range(0.05, 0.10)
		"lean":
			d["ovality"] = _rng.randf_range(0.58, 0.76)
			d["lean_deg"] = _rng.randf_range(6.0, 13.0) 				* (1.0 if _rng.randf() < 0.5 else -1.0)
			d["bulge"] = _rng.randf_range(-0.12, 0.20)
			d["flute_depth"] = _rng.randf_range(0.05, 0.11)
		"plain":
			d["ovality"] = _rng.randf_range(0.88, 0.99)
			d["lean_deg"] = _rng.randf_range(-1.5, 1.5)
			d["flute_depth"] = _rng.randf_range(0.03, 0.06)
			d["noise_amount"] = _rng.randf_range(0.0, 0.02)
	return d
