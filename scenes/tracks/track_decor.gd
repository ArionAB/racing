class_name TrackDecor
extends RefCounted
## Decorul din jurul soselei: pietre, cactusi, tufe, mese, copaci.
##
## DOUA STRATEGII, dupa tema:
##
## [b]desert[/b] — BENZI paralele cu drumul, esantionate in arc-length. Fiecare
## banda are propriul offset, pas si continut, iar prop-urile se aseaza in
## grupuri cu goluri intre ele. Asa se obtine senzatia de canion: decorul
## URMEAZA drumul si il strange, in loc sa fie presarat prin peisaj.
##
## [b]forest[/b] — esantionare prin respingere intr-un dreptunghi, codul vechi.
## Padurea nu are nevoie sa stranga drumul, iar schimbarea ar fi rescris doua
## piste care arata bine.
##
## De ce s-a schimbat: metoda veche respingea orice pozitie mai apropiata de 15m
## de axa, deci nu PUTEA produce "lipit de drum" — de asta decorul parea rar desi
## erau 80 de prop-uri.
##
## Materialele NU se creeaza aici: `mat_provider` e cache-ul de culoare din
## [code]track.gd[/code] ([code]_flat_material[/code]). Daca decorul si-ar face
## materiale proprii, garda de draw call-uri din [code]tools/probe_decor.gd[/code]
## ar deveni oarba exact acolo unde conteaza cel mai mult.

## --- Tema forest: esantionare prin respingere (cod vechi) ---
const MAX_PLACED: int = 80
const MAX_ATTEMPTS: int = 400
const NEAR_MARGIN: float = 8.0
const FAR_LIMIT: float = 90.0

## --- Tema desert: benzi paralele cu drumul ---
##
## Tinta e 18-25 prop-uri / 100 m (style_bible §7), adica ~210-290 pe un tur de
## Dunele (1175 m) — fata de 80 cat producea metoda veche pe toata suprafata.
##
## ATENTIE la pas: numarul final NU e lungimea / pas. Fiecare slot se produce pe
## AMBELE laturi, gruparea adauga 2-5 sateliti, iar jitterul longitudinal mai
## strecoara sloturi. Prima incercare (pas 9/7/14) a scos 882 de prop-uri, de
## patru ori peste tinta, si a spart pragul de triunghiuri din garda. Pasii de
## mai jos sunt calibrati pe numaratoarea reala, nu pe calculul naiv.
##
## `off_min`/`off_max` sunt distante fata de MARGINEA asfaltului, nu fata de axa.
## `collide` fals inseamna mesh fara corp fizic: treci prin el.
const BANDS := [
	# Lipita de drum. Da ingustimea canionului, dar NU exista fizic — style_bible
	# §2 cere prop-uri la 2-4m, iar la distanta aia coliziunea ar face cursa
	# nejucabila (is_on_road taie viteza deja de la 7.5m de axa).
	{"name": "hug", "off_min": 1.5, "off_max": 4.0, "spacing": 9.0,
		"collide": false, "cluster": 0.30},
	# Prima banda cu coliziune. La 4m de margine, primul contact posibil e la 11m
	# de axa — adica 3.5m DUPA ce ai incasat deja penalizarea de offroad.
	{"name": "mid", "off_min": 4.0, "off_max": 11.0, "spacing": 17.0,
		"collide": true, "cluster": 0.50},
	# Fundal apropiat: piese mari, dese.
	{"name": "back", "off_min": 11.0, "off_max": 26.0, "spacing": 24.0,
		"collide": true, "cluster": 0.45},
	# Fundal DEPARTAT — stratul care lipsea (#147).
	#
	# Masurat in vederea soferului: benzile se opreau la 26 m, iar siluetele de
	# orizont incep la 150 m de centroid cu 95 m degajare fata de sosea. Intre
	# ele nu era NIMIC, si banda aia goala umple jumatate din cadru pe portiunile
	# unde falezele stau doar pe o parte (dreapta pistei Dunele: 85% acoperire
	# fata de 97% pe stanga, cu felii intregi sub 30%). Exact diferenta dintre
	# panourile BEFORE si AFTER din conceptul de referinta: nu lipseau obiecte
	# langa drum, lipsea un PLAN INTERMEDIAR.
	#
	# Rara si fara coliziune intentionat: la 26-58 m esti demult in afara
	# soselei, iar un colizor acolo nu e gameplay, e o capcana in care te
	# opresti dupa un fly-off ratat.
	#
	# `props_only`: pe insula banda asta ar cadea in MARE. Poarta e pe setul de
	# prop-uri, nu pe numele temei — aceeasi separare "ce" / "unde" ca la `build`.
	#
	# Pas 52 -> 32 si grupare 0.25 -> 0.40: la 52 iesea o piesa la ~30 m de
	# traseu, adica exact cat sa se vada ca sunt puse cu pipeta. Referinta are
	# formatiuni CONTINUE, nu jaloane — drumul trebuie sa arate sapat intr-un
	# masiv, nu pus pe o campie cu pietre presarate.
	{"name": "far", "off_min": 26.0, "off_max": 58.0, "spacing": 32.0,
		"collide": false, "cluster": 0.40, "props_only": "desert"},
]
## Pasii din `BANDS` sunt calibrati pe DESERT, unde tinta e masa continua de
## canion: drumul trebuie sa arate sapat intr-un masiv, nu pus pe o campie cu
## pietre presarate. Alte seturi de prop-uri cer alta densitate si o declara aici.
##
## Insula ramane la pasii dinaintea indesirii, din doua motive care nu tin de
## estetica: un palmier costa de cateva ori cat o stanca de canion (banyan 4852
## de triunghiuri fata de ~230), iar Okinawa e deja pista cea mai grea din
## proiect. Aceeasi densitate ca pe desert ar duce-o direct in plafon.
## Cheile suprascrise sunt aceleasi ca in `BANDS` (`spacing`, `cluster`).
## Gruparea conteaza la fel de mult ca pasul: prima incercare suprascria doar
## pasul si Okinawa tot a crescut cu 26.000 de triunghiuri, fiindca `cluster`
## ramasese cel de desert si fiecare prop principal trage dupa el 2-5 sateliti.
const BAND_OVERRIDES := {
	"island": {
		"mid": {"spacing": 25.0, "cluster": 0.45},
		"back": {"spacing": 42.0, "cluster": 0.35},
	},
}

## Cati sateliti primeste un prop cand pica zarul de grupare, si in ce raza.
const CLUSTER_MIN: int = 2
const CLUSTER_MAX: int = 5
const CLUSTER_RADIUS: float = 3.5
## In zonele de franare banda lipita se goleste si cea de mijloc se retrage.
const BRAKING_MIN_OFFSET: float = 8.0


## Construieste tot decorul si il intoarce sub un singur nod.
##
## `mode` vine din tema pistei (Track.themes(), cheia "decor"), nu din numele
## temei. Inainte era chiar numele — `if theme == "desert"` — ceea ce lega
## strategia de asezare de o pista anume: o tema noua care voia benzi trebuia
## sa se prefaca ca e desert sau sa adauge inca un `or`.
##   "bands"   — benzi paralele cu drumul, densitatea din style_bible §7
##   "scatter" — esantionare prin respingere in dreptunghi (metoda veche)
##
## `mat_provider` = Callable(Color) -> StandardMaterial3D.
## `props` alege CE se aseaza; `mode` alege UNDE. Sunt doua decizii separate,
## si trebuiau sa fie: insula foloseste aceeasi strategie de benzi ca desertul
## (densitatea din style_bible §7 e cea corecta), dar cu palmieri in loc de
## cactusi. Cat timp ambele veneau din acelasi sir "desert", nu se putea una
## fara cealalta.
static func build(sampler: TrackSideSampler, mode: String, seed_value: int,
		mat_provider: Callable, props: String = "desert") -> Node3D:
	var root := Node3D.new()
	root.name = "Decor"
	# Un singur nod misca toata vegetatia. Se pune primul, ca _add_scatter sa-l
	# gaseasca dupa nume fara sa-l caram prin sase semnaturi de functie.
	var sway := SwayDriver.new()
	sway.name = "Sway"
	root.add_child(sway)
	if sampler.point_count() == 0:
		return root
	if mode == "bands":
		_build_bands(root, sampler, seed_value, mat_provider, props)
	else:
		_build_scattered(root, sampler, seed_value, mat_provider)
	return root


## Benzi paralele cu drumul. Continutul lor vine din `props`, nu de aici.
static func _build_bands(root: Node3D, sampler: TrackSideSampler,
		seed_value: int, mat_provider: Callable, props: String) -> void:
	for band in BANDS:
		# Benzile cerute de un anumit set de prop-uri (vezi `far`) nu apar pe
		# celelalte teme.
		if band.has("props_only") and String(band["props_only"]) != props:
			continue
		# Un rng PER BANDA: asa poti itera pe densitatea benzii de mijloc fara sa
		# se mute si pietricelele de langa drum.
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value + hash(band["name"])

		var container := Node3D.new()
		container.name = "Band_%s" % band["name"]
		root.add_child(container)

		var step: float = float(band["spacing"])
		var clump: float = float(band["cluster"])
		var over: Dictionary = BAND_OVERRIDES.get(props, {})
		if over.has(band["name"]):
			var b: Dictionary = over[band["name"]]
			step = float(b.get("spacing", step))
			clump = float(b.get("cluster", clump))

		var skip := 0
		for spec in sampler.sample_band(step, band["off_min"],
				band["off_max"], rng):
			# Golurile sunt la fel de importante ca prop-urile: fara ele iese un
			# covor uniform, nu ritmul "ingramadit / gol" din referinta.
			if skip > 0:
				skip -= 1
				continue
			if not _allowed(spec, band):
				continue
			_place_band_prop(container, spec, band, rng, mat_provider, props)
			if rng.randf() < clump:
				_place_satellites(container, sampler, spec, band, rng, mat_provider,
					props)
				skip = 2


## Regulile de siguranta, citite din steagurile pe care le-a calculat samplerul.
static func _allowed(spec: TrackDecorSpec, band: Dictionary) -> bool:
	# Rapa declarata: acolo terenul e sapat intentionat, ca sa existe unde sa cazi.
	# Un cactus plutind peste prapastie ar strica exact efectul.
	if spec.is_ravine:
		return false
	if spec.is_braking:
		# 8m liberi in zonele de franare (style_bible §7).
		if band["name"] == "hug":
			return false
		if spec.offset < BRAKING_MIN_OFFSET:
			return false
	# Nimic inalt in apex pe partea interioara: acolo se citeste iesirea din viraj.
	if spec.is_apex and not spec.is_exterior and band["name"] != "hug":
		return false
	return true


static func _place_satellites(parent: Node3D, sampler: TrackSideSampler,
		spec: TrackDecorSpec, band: Dictionary, rng: RandomNumberGenerator,
		mat_provider: Callable, props: String) -> void:
	var count := rng.randi_range(CLUSTER_MIN, CLUSTER_MAX)
	for i in count:
		var sat := TrackDecorSpec.new()
		var angle := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(1.0, CLUSTER_RADIUS)
		sat.position = spec.position + Vector3(cos(angle), 0.0, sin(angle)) * dist
		# Satelitul s-a imprastiat pana la CLUSTER_RADIUS fata de propul principal,
		# deci cota lui nu mai e cea masurata acolo.
		sat.position.y = sampler.ground_y(sat.position.x, sat.position.z)
		sat.normal_out = spec.normal_out
		sat.along = spec.along
		sat.index = spec.index
		sat.frac = spec.frac
		sat.side_sign = spec.side_sign
		sat.offset = spec.offset + dist * 0.5
		sat.is_exterior = spec.is_exterior
		sat.is_elevated = spec.is_elevated
		sat.is_apex = spec.is_apex
		sat.is_braking = spec.is_braking
		_place_band_prop(parent, sat, band, rng, mat_provider, props, true)


## Ce se aseaza intr-o banda. Sateliti = piese mai mici decat propul principal.
static func _place_band_prop(parent: Node3D, spec: TrackDecorSpec,
		band: Dictionary, rng: RandomNumberGenerator, mat_provider: Callable,
		props: String, satellite: bool = false) -> void:
	if props == "island":
		# Fractia se transmite fiindca UN prop insular depinde de sector
		# (trestia de zahar). Restul o ignora — vezi CANE_FRAC_MIN.
		_place_island_prop(parent, spec.position, band, rng, mat_provider,
			satellite, spec.frac)
		return
	var pos := spec.position
	match band["name"]:
		"hug":
			# Banda lipita de drum avea DOAR scatter — tufe si pietricele de sub
			# 1 m, care la 30 m in fata masinii dispar in nisip. O treime din ea
			# primeste acum stanci mici de canion: singurele obiecte de langa
			# asfalt care au silueta peste linia orizontului si strang cadrul.
			# Fara coliziune, ca toata banda (vezi nota de la BANDS).
			if rng.randf() < 0.34 and _add_canyon_rock(
					parent, pos, rng, "S", false, 0.75, 1.35):
				return
			# Jumatate din rest primeste frunzis din kit in locul scatter-ului,
			# din exact acelasi motiv pentru care s-au adaugat stancile mici:
			# piesele din desert_scatter stau sub 60 cm si nu urca peste linia
			# solului. Un smoc de 1 m o rupe. Scatter-ul ramane in amestec —
			# e de zece ori mai ieftin si tine media de triunghiuri jos pe
			# banda cea mai numeroasa de pe pista.
			if rng.randf() < 0.40 and _add_kit_plant(
					parent, pos, rng, KIT_SMALL_PLANTS, 0.70, 1.10):
				return
			_add_scatter(parent, pos, rng, mat_provider)
		"mid":
			var roll := rng.randf()
			if satellite or roll < 0.30:
				if not _add_canyon_rock(parent, pos, rng, "S", false):
					_add_cluster(parent, pos, rng, ["Cluster_S1", "Cluster_S2"],
						false, mat_provider)
			elif roll < 0.44:
				_add_cactus(parent, pos, rng, mat_provider)
			elif roll < 0.58:
				# Vegetatia din kit imparte cu cactusul felia care era numai a
				# lui. Cactusul ramane semnatura pistei, dar un desert in care
				# SINGURA planta e saguaro citeste ca desen animat: foaia de
				# referinta are tufe si evantaie intre ei.
				if not _add_kit_plant(parent, pos, rng, KIT_BIG_PLANTS,
						0.90, 1.35):
					_add_cactus(parent, pos, rng, mat_provider)
			elif roll < 0.80:
				if not _add_canyon_rock(parent, pos, rng, "M", true):
					_add_cluster(parent, pos, rng, ["Cluster_M1", "Cluster_M2"],
						true, mat_provider)
			elif roll < 0.836:
				# Accentul vertical. Cifrele astea (3.6% aici, 5.5% pe banda
				# indepartata) sunt CALIBRATE PE NUMARATOARE, nu alese din ochi:
				# la 6%/12% ieseau 10 copaci pe Dunele si 12 pe Stramtoarea,
				# adica ~35% din tot bugetul de vegetatie pentru piesa cea mai
				# scumpa din biblioteca (3.278 si 2.851 de triunghiuri, fata de
				# ~260 media unei plante). Sase-sapte pe tur raman un reper;
				# zece incep sa fie tapet, si tapetul asta costa cat 130 de
				# smocuri de iarba.
				if not _add_dead_tree(parent, pos, rng):
					_add_cluster(parent, pos, rng, ["Cluster_M1", "Cluster_M2"],
						true, mat_provider)
			else:
				# Bolovanii netezi raman in amestec, in minoritate: doua limbaje
				# de forma pe aceeasi pista citesc ca geologie, unul singur ca
				# tipar.
				_add_cluster(parent, pos, rng, ["Cluster_M1", "Cluster_M2"],
					true, mat_provider)
		"far":
			# Plan intermediar: mase MARI si rare, nimic marunt. Un cactus sau o
			# pietricica la 40 m nu se vede — ar fi triunghiuri platite degeaba.
			# Amprenta si inaltimea urca amandoua: la distanta aia o stanca de
			# marimea celor de langa drum citeste ca o pietricica, si tocmai
			# scara e ce da adancimea (formatiunile stratificate din referinta).
			#
			# Exceptia de la "nimic marunt": copacul mort. La 26-58 m nu e
			# marunt — 8 m de silueta neagra pe cer, exact ce sparge sirul de
			# mase orizontale din foaia de referinta. Fara coliziune, ca toata
			# banda.
			if rng.randf() < 0.055 and _add_dead_tree(parent, pos, rng, false):
				return
			if not _add_canyon_rock(parent, pos, rng, "L", false,
					1.05, 1.85, 1.35, 2.10):
				_add_cluster(parent, pos, rng, ["Cluster_L1"], false, mat_provider)
		_:
			var roll2 := rng.randf()
			if satellite or roll2 < 0.30:
				if not _add_canyon_rock(parent, pos, rng, "M", true):
					_add_cluster(parent, pos, rng, ["Cluster_M1", "Cluster_M2"],
						true, mat_provider)
			elif roll2 < 0.72:
				# Aici statea mesa procedurala din cutii. Stancile mari de
				# canion ii iau locul cu aceeasi intentie (silueta dominanta in
				# fundalul apropiat), dar pe textura de roca si cu trepte reale.
				if not _add_canyon_rock(parent, pos, rng, "L", true,
						0.85, 1.25):
					_add_cluster(parent, pos, rng, ["Cluster_L1"], true,
						mat_provider)
			elif roll2 < 0.86:
				_add_cluster(parent, pos, rng, ["Cluster_L1"], true, mat_provider)
			elif roll2 < 0.94:
				_add_cactus(parent, pos, rng, mat_provider)
			else:
				if not _add_kit_plant(parent, pos, rng, KIT_BIG_PLANTS,
						1.00, 1.45):
					_add_cactus(parent, pos, rng, mat_provider)


## --- Set de prop-uri: insula de recif ---------------------------------------
##
## Aceleasi trei benzi, alt continut. Cat timp island_scatter.glb si
## coral_rock.glb nu exista (etapa de assets), fiecare piesa cade pe o primitiva
## colorata din sloturile insulare — NU pe cele de desert. Un cactus pe un recif
## e mai rau decat o tufa provizorie, si ar fi trecut nesanctionat de orice
## sonda: garda numara triunghiuri, nu bunul-simt botanic.
##
## Cand GLB-urile apar, pick_from_glb le gaseste singur si primitivele dispar.
const ISLAND_SCATTER: String = "res://assets/models/island_scatter.glb"
const ISLAND_ROCKS: String = "res://assets/models/coral_rock.glb"
const ISLAND_CLUTTER: String = "res://assets/models/beach_clutter.glb"
const ISLAND_CANE: String = "res://assets/models/sugar_cane_clump.glb"

## Arborii insulei.
##
## Densitatea (ferestrele de probabilitate din `_place_island_prop`) e reglata pe
## BUGET, nu pe cat de plina arata banda. Un arbore real costa 1400-4900 de
## triunghiuri fata de ~60 cat costa cilindrul + sfera pe care le inlocuieste,
## deci trecerea la assets adevarate a urcat pista de la 270k la 474k — peste
## pragul de alarma din `probe_decor`. Coborata la 24%/34%, banda arata la fel de
## locuita si intra in buget. Cifra se re-verifica la orice model nou de arbore.
##
## Ponderile dintre specii NU sunt egale: cocotierul e silueta implicita a
## coastei, banyanul e rar tocmai ca sa ramana un reper ("langa copacul mare"),
## iar pandanusul si palmierul aplecat dau varietatea de la nivelul ochiului.
##
## `collide` = raza cilindrului de coliziune in jurul trunchiului, 0.0 pentru
## piesele prin care treci. Pandanusul e o tufa, deci n-are; banyanul e singurul
## destul de gros cat sa opreasca o masina fara sa para nedrept.
const ISLAND_TREES := [
	{"path": "res://assets/models/coconut_palm.glb", "weight": 0.42,
		"scale_min": 0.85, "scale_max": 1.15, "collide": 0.45},
	{"path": "res://assets/models/beach_palm_bent.glb", "weight": 0.22,
		"scale_min": 0.90, "scale_max": 1.25, "collide": 0.40},
	{"path": "res://assets/models/pandanus.glb", "weight": 0.26,
		"scale_min": 0.85, "scale_max": 1.30, "collide": 0.0},
	{"path": "res://assets/models/banyan.glb", "weight": 0.10,
		"scale_min": 0.90, "scale_max": 1.20, "collide": 1.10},
]

## Maparea de clase pentru TOT decorul insular, intr-un singur loc.
##
## `apply_class_materials` potriveste pe PREFIX de nume, deci "Coral_Rock"
## acopera toate cele opt variante si "Tetrapod" pe toate trei. Ce nu e aici
## (frunzis, scatter, accente) cade pe materialul lumii, si asa trebuie: are
## UV-uri colapsate pe sloturi de paleta.
const ISLAND_CLASSES := {
	"Palm_Bark": "bark",
	"BentPalm_Bark": "bark",
	"Pandanus_Bark": "bark",
	"Banyan_Bark": "bark",
	"Coral_Rock": Palette.TRI_PREFIX + "coral_rock",
	"Tetrapod": "concrete",
	"Sea_Wall": "concrete",
	"Sabani_Hull": "wood",
}

## Fractiile pe care creste trestia de zahar (sectorul 7, `Track05.SECTORS`).
##
## Ratele de aparitie (0.32/0.38/0.34 pe cele trei benzi) sunt reglate pe
## BUGETUL de triunghiuri, nu pe cat de des arata bine: la 0.45/0.55/0.50 lanul
## punea 39 de smocuri, adica 46 000 de triunghiuri pentru un decor prin care
## treci. Cu ~27 de smocuri sectorul citeste la fel si costa cu o treime mai
## putin.
##
## Trestia e singurul prop legat de un SECTOR anume, nu imprastiat pe tot turul:
## un lan care apare si langa far, si in port, nu mai spune nimic despre unde
## esti — adica pierde exact rolul pentru care exista sectorul. De-aia
## `_place_island_prop` primeste fractia; restul prop-urilor o ignora.
const CANE_FRAC_MIN: float = 0.68
const CANE_FRAC_MAX: float = 0.88

static func _place_island_prop(parent: Node3D, pos: Vector3, band: Dictionary,
		rng: RandomNumberGenerator, mat: Callable, satellite: bool,
		frac: float = -1.0) -> void:
	var in_cane := frac >= CANE_FRAC_MIN and frac <= CANE_FRAC_MAX
	match band["name"]:
		"hug":
			# Lipit de drum: iarba de plaja, lemn adus de apa, pietre de corali.
			# In sectorul trestiei, marginea drumului e chiar lanul.
			if in_cane and not satellite and rng.randf() < 0.32 \
					and _add_sugar_cane(parent, pos, rng):
				return
			_add_island_scatter(parent, pos, rng, mat)
		"mid":
			var roll := rng.randf()
			if in_cane and not satellite and roll < 0.38 \
					and _add_sugar_cane(parent, pos, rng):
				return
			if satellite or roll < 0.30:
				_add_island_scatter(parent, pos, rng, mat)
			elif roll < 0.42:
				# Viata de plaja: lazi, plute, oale. Rara si doar pe banda din
				# mijloc — langa asfalt ar fi citit ca gunoi aruncat pe sosea.
				if not _add_beach_clutter(parent, pos, rng):
					_add_island_scatter(parent, pos, rng, mat)
			elif roll < 0.66:
				_add_island_tree(parent, pos, rng, mat)
			else:
				_add_coral_rock(parent, pos, rng, mat, true)
		_:
			var roll2 := rng.randf()
			if in_cane and not satellite and roll2 < 0.34 \
					and _add_sugar_cane(parent, pos, rng):
				return
			if satellite or roll2 < 0.38:
				_add_coral_rock(parent, pos, rng, mat, true)
			elif roll2 < 0.72:
				_add_island_tree(parent, pos, rng, mat)
			else:
				_add_coral_rock(parent, pos, rng, mat, true)


## Maruntisuri de plaja, fara coliziune.
static func _add_island_scatter(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, mat: Callable) -> void:
	# Alegere PONDERATA, nu uniforma, si motivul e bugetul: banda lipita de drum
	# pune ~460 de piese pe tur, iar busteanul costa 50 de triunghiuri fata de
	# 120-160 cat costa celelalte. Cu 40% busteni media coboara de la 127 la
	# ~105, adica 12 000 de triunghiuri pe tur — exact marja care tinea pista
	# peste pragul de alarma. Vizual nu se pierde nimic: pe o plaja chiar e mai
	# mult lemn adus de apa decat tufe.
	const PICKS := ["Driftwood", "Driftwood", "Beach_Grass", "Coral_Pebbles",
		"Hibiscus"]
	var kept := pick_from_glb(ISLAND_SCATTER,
		PICKS[rng.randi_range(0, PICKS.size() - 1)])
	if kept == null:
		_add_tropical_bush(parent, pos, rng, mat)
		return
	parent.add_child(kept)
	kept.position = pos + Vector3.UP * -0.15
	kept.rotation.y = rng.randf_range(0.0, TAU)
	kept.scale = Vector3.ONE * rng.randf_range(1.4, 2.1)
	Palette.apply_world_material(kept)


## Tufa subtropicala: hibiscusul cu flori rosii, sau — daca GLB-ul lipseste —
## sfera provizorie de dinainte.
##
## Hibiscusul e singurul rosu NATURAL din decorul insulei, deci merita sa fie
## tufa implicita si nu doar o piesa de scatter printre altele: pata de culoare
## e ce citeste ochiul la 30 m, nu forma frunzei.
static func _add_tropical_bush(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, mat: Callable) -> void:
	const HIBISCUS := "res://assets/models/hibiscus_bush.glb"
	if ResourceLoader.exists(HIBISCUS):
		var model := (load(HIBISCUS) as PackedScene).instantiate() as Node3D
		parent.add_child(model)
		model.position = pos + Vector3.UP * -0.12
		model.rotation.y = rng.randf_range(0.0, TAU)
		model.scale = Vector3.ONE * rng.randf_range(0.75, 1.15)
		Palette.apply_world_material(model)
		return
	var bush := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	var r := rng.randf_range(0.5, 0.95)
	sphere.radius = r
	sphere.height = r * 1.3 # mai inalta decat lata: tufa de plaja, nu bolovan
	# Rezolutia se seteaza EXPLICIT. Implicit SphereMesh e 64x32 = 4224 de
	# triunghiuri pentru o tufa de 60 cm (CLAUDE.md, constrangeri mobile).
	#
	# 6x2 = ~24 de triunghiuri, nu 8x4 = ~80. Diferenta pare marunta pana o
	# inmultesti cu 461, cati intra pe banda lipita de drum la 1944 m: masurat,
	# 36 880 de triunghiuri, adica 42% din TOATA pista, pentru niste bile care
	# oricum dispar la prima transa de assets. Un placeholder n-are voie sa
	# consume bugetul lucrului pe care il inlocuieste.
	sphere.radial_segments = 6
	sphere.rings = 2
	bush.mesh = sphere
	bush.position = pos + Vector3.UP * (r * 0.35 - 0.3)
	var tint := float(rng.randi_range(0, 2)) / 2.0 * 0.16
	bush.material_override = mat.call(
		Palette.color(Palette.TROPICAL_GREEN).lightened(tint))
	parent.add_child(bush)


## Trestia de zahar. Intoarce false daca GLB-ul lipseste, ca apelantul sa poata
## pune altceva in loc — un lan cu goluri e mai rau decat unul mai rar.
static func _add_sugar_cane(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator) -> bool:
	const PICKS := ["Cane_Clump_A", "Cane_Clump_B", "Cane_Clump_C"]
	var kept := pick_from_glb(ISLAND_CANE,
		PICKS[rng.randi_range(0, PICKS.size() - 1)])
	if kept == null:
		return false
	parent.add_child(kept)
	# Ingropat 20 cm: tulpinile pornesc dintr-un punct, iar la cota exacta a
	# solului se vede rozeta de la baza si smocul pare pus pe jos.
	kept.position = pos + Vector3.UP * -0.20
	kept.rotation.y = rng.randf_range(0.0, TAU)
	kept.scale = Vector3.ONE * rng.randf_range(0.85, 1.20)
	# Fara coliziune, deliberat: treci PRIN lan. Trestia e o perdea vizuala, si
	# un zid invizibil la marginea drumului ar transforma un decor intr-o
	# pedeapsa.
	Palette.apply_world_material(kept)
	return true


## Viata de plaja: lazi, plute de plasa, oale de awamori, rastele, busteni.
static func _add_beach_clutter(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator) -> bool:
	const PICKS := ["Fishing_Crate", "Net_Floats", "Awamori_Pot",
		"Bamboo_Rack", "Driftwood_Log"]
	var kept := pick_from_glb(ISLAND_CLUTTER,
		PICKS[rng.randi_range(0, PICKS.size() - 1)])
	if kept == null:
		return false
	parent.add_child(kept)
	kept.position = pos + Vector3.UP * -0.06
	kept.rotation.y = rng.randf_range(0.0, TAU)
	kept.scale = Vector3.ONE * rng.randf_range(0.95, 1.25)
	Palette.apply_world_material(kept)
	return true


## Arborii insulei: cocotier, palmier aplecat, pandanus, banyan.
##
## Inlocuieste palmierul provizoriu din cilindru + sfera. Fata de scatter,
## arborii se instantiaza INTREGI (nu prin `pick_from_glb`): fiecare fisier e
## un ansamblu de doua piese — scoarta pe clasa `bark` si frunzisul pe atlas —
## iar a pastra doar un nod ar fi lasat un trunchi fara coroana.
##
## Alegerea e ponderata (vezi ISLAND_TREES), nu uniforma: patru specii in
## proportii egale citesc ca o gradina botanica, nu ca o coasta.
static func _add_island_tree(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, mat: Callable) -> void:
	var roll := rng.randf()
	var acc := 0.0
	var spec: Dictionary = ISLAND_TREES[0]
	for entry: Dictionary in ISLAND_TREES:
		acc += float(entry["weight"])
		if roll <= acc:
			spec = entry
			break
	var path: String = spec["path"]
	if ResourceLoader.exists(path):
		var model := (load(path) as PackedScene).instantiate() as Node3D
		var s := rng.randf_range(float(spec["scale_min"]),
			float(spec["scale_max"]))
		var radius := float(spec["collide"]) * s
		var holder: Node3D
		if radius > 0.0:
			# Coliziune doar pe TRUNCHI, nu pe coroana: altfel treci prin
			# frunzele care atarna peste drum si te opresti in aer.
			var body := StaticBody3D.new()
			var shape := CollisionShape3D.new()
			var cyl := CylinderShape3D.new()
			var aabb := Track.model_aabb(model)
			cyl.radius = radius
			cyl.height = maxf(aabb.size.y * 0.55, 1.0) * s
			shape.shape = cyl
			shape.position = Vector3.UP * (cyl.height * 0.5)
			body.add_child(shape)
			holder = body
		else:
			holder = Node3D.new()
		parent.add_child(holder)
		holder.add_child(model)
		holder.position = pos + Vector3.UP * -0.10
		holder.rotation.y = rng.randf_range(0.0, TAU)
		holder.scale = Vector3.ONE * s
		Palette.apply_class_materials(model, ISLAND_CLASSES)
		return
	_add_palm_placeholder(parent, pos, rng, mat)


## Palmier provizoriu: trunchi inclinat + coroana. Rezerva pentru cand
## coconut_palm.glb & co lipsesc — nu se sterge, e plasa de siguranta care tine
## pista jucabila pe un checkout fara assets.
##
## Inclinarea nu e cosmetica — palmierii de coasta cresc spre lumina, deci un
## pluton de trunchiuri perfect verticale citeste imediat ca geometrie generata.
static func _add_palm_placeholder(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, mat: Callable) -> void:
	var h := rng.randf_range(4.5, 7.0) # style_bible §2: palmieri 4-7 m
	var holder := Node3D.new()
	parent.add_child(holder)
	holder.position = pos
	holder.rotation.y = rng.randf_range(0.0, TAU)

	var trunk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.16
	cyl.bottom_radius = 0.28
	cyl.height = h
	cyl.radial_segments = 5
	cyl.rings = 0
	trunk.mesh = cyl
	trunk.position = Vector3(0, h * 0.5, 0)
	trunk.rotation.z = rng.randf_range(-0.22, 0.22)
	trunk.material_override = mat.call(Palette.color(Palette.WOOD_WEATHERED))
	holder.add_child(trunk)

	var crown := MeshInstance3D.new()
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = rng.randf_range(1.3, 1.9)
	crown_mesh.height = crown_mesh.radius * 1.1
	crown_mesh.radial_segments = 7
	crown_mesh.rings = 2
	crown.mesh = crown_mesh
	# Urmeaza varful trunchiului inclinat, altfel coroana pluteste langa el.
	crown.position = Vector3(sin(trunk.rotation.z) * -h, h, 0)
	crown.material_override = mat.call(Palette.color(Palette.TROPICAL_GREEN))
	holder.add_child(crown)


## Stanca de corali / bazalt. Placi joase si late, nu bolovani.
static func _add_coral_rock(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, mat: Callable, collide: bool) -> void:
	var kept := pick_from_glb(ISLAND_ROCKS,
		"Coral_Rock_%02d" % rng.randi_range(1, 8))
	var h := rng.randf_range(0.8, 2.6)
	var node: Node3D
	if kept != null:
		node = kept
		# Clasa `coral_rock` (triplanar), NU materialul lumii. Cu atlasul,
		# stancile ieseau cu capacele negre si peretii PORTOCALII: `strata_slots`
		# alterneaza sloturi pe inele, iar cel din mijloc era `rock_dark`
		# (#67421F) — gresia canionului, adica exact culoarea de care fugim pe o
		# insula. Prins pe snapshot de joc, nu in Blender: acolo previzualizarea
		# aplica textura de clasa, deci arata corect.
		Palette.apply_class_materials(kept, ISLAND_CLASSES)
		var mi_glb := _first_mesh(kept)
		if mi_glb != null and mi_glb.mesh != null:
			h = mi_glb.mesh.get_aabb().size.y
	else:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		# Late si turtite: raftul de bazalt sapat de mare, nu o piatra rotunda.
		box.size = Vector3(rng.randf_range(1.8, 4.2), h,
			rng.randf_range(1.6, 3.8))
		mi.mesh = box
		mi.position = Vector3.UP * h * 0.5
		mi.material_override = mat.call(
			Palette.color(Palette.VOLCANIC_BLACK).lightened(
				float(rng.randi_range(0, 2)) / 2.0 * 0.14))
		node = mi
	if not collide:
		parent.add_child(node)
		node.position = pos + Vector3.UP * -0.2
		node.rotation.y = rng.randf_range(0.0, TAU)
		return
	var body := StaticBody3D.new()
	parent.add_child(body)
	body.add_child(node)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = maxf(h * 0.6, 0.7)
	shape.shape = sphere
	shape.position = Vector3.UP * h * 0.4
	body.add_child(shape)
	body.rotation.y = rng.randf_range(0.0, TAU)
	body.position = pos + Vector3.UP * -0.2


## Tema forest: esantionare prin respingere in dreptunghi (codul dinainte).
static func _build_scattered(root: Node3D, sampler: TrackSideSampler,
		seed_value: int, mat_provider: Callable) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var n := sampler.point_count()
	var bounds_min := sampler.baked_point(0)
	var bounds_max := bounds_min
	for i in n:
		var p := sampler.baked_point(i)
		bounds_min = bounds_min.min(p)
		bounds_max = bounds_max.max(p)

	var placed := 0
	var attempts := 0
	while placed < MAX_PLACED and attempts < MAX_ATTEMPTS:
		attempts += 1
		var pos := Vector3(
			rng.randf_range(bounds_min.x - 50.0, bounds_max.x + 50.0),
			0.0,
			rng.randf_range(bounds_min.z - 50.0, bounds_max.z + 50.0))
		# Bug latent, nereclamat: cota era hardcodata 0.0, in timp ce terenul de
		# padure statea la -0.3 plus dune de ±5 m. Copacii de pe Serpentina si
		# Muntele pluteau sau erau ingropati de cand exista pistele alea.
		pos.y = sampler.ground_y(pos.x, pos.z)
		var nearest := sampler.clearance_at(pos)
		if nearest < sampler.half_width() + NEAR_MARGIN or nearest > FAR_LIMIT:
			continue
		placed += 1
		if rng.randf() < 0.7:
			_add_tree(root, pos, rng, mat_provider)
		elif rng.randf() < 0.5:
			_add_glb_rock(root, pos, rng, mat_provider)
		else:
			_add_rock(root, pos, rng, mat_provider)


# ------------------------------------------------------------ prop-uri

## Biblioteca de stanci de canion (canyon_rocks.glb), pe trei clase de marime.
##
## Inlocuieste doua surse care faceau tot desertul sa arate la fel: cei cinci
## elipsoizi netezi din rock_cluster.glb si mesa procedurala de mai jos, care
## era trei cutii suprapuse pe materialul de paleta — fara textura de roca si
## cu muchii perfect drepte. Stancile astea au TREPTE cu buza vizibila si moloz
## la baza; buza e ce se citeste de la 100 m, cand granulatia texturii s-a topit
## in mipmap.
const CANYON_PATH: String = "res://assets/models/canyon_rocks.glb"
const CANYON_S: Array[String] = ["Canyon_S1", "Canyon_S2", "Canyon_S3",
	"Canyon_S4", "Canyon_S5", "Canyon_S6", "Canyon_S7", "Canyon_S8"]
const CANYON_M: Array[String] = ["Canyon_M1", "Canyon_M2", "Canyon_M3",
	"Canyon_M4", "Canyon_M5", "Canyon_M6"]
const CANYON_L: Array[String] = ["Canyon_L1", "Canyon_L2", "Canyon_L3",
	"Canyon_L4"]

## A DOUA biblioteca de stanci, pe aceleasi trei clase de marime: formatiuni
## ROTUNJITE compuse din Stylized Nature MegaKit (vezi
## tools/blender/build_megakit_rocks.py).
##
## De ce doua si nu una mai mare: `canyon_rocks.glb` are un singur limbaj de
## forma — lespezi suprapuse cu buza, sedimentar erodat in trepte. Optsprezece
## variante ale aceluiasi limbaj tot ca UN tipar citesc de la 60 km/h, fiindca
## ochiul recunoaste GRAMATICA formei inainte sa numere piesele. Masele de
## gresie rotunjite sunt cealalta gramatica din acelasi peisaj; alternanta lor
## e ce transforma "un mesh reciclat" in geologie.
const KIT_ROCK_PATH: String = "res://assets/models/megakit_rocks.glb"
const KIT_S: Array[String] = ["Kit_S1", "Kit_S2", "Kit_S3", "Kit_S4",
	"Kit_S5", "Kit_S6"]
const KIT_M: Array[String] = ["Kit_M1", "Kit_M2", "Kit_M3", "Kit_M4",
	"Kit_M5", "Kit_M6"]
const KIT_L: Array[String] = ["Kit_L1", "Kit_L2", "Kit_L3", "Kit_L4"]

## Cat din stanci vin din kit. O treime, si cifra are doua justificari care
## trag in aceeasi directie:
##   - estetic: treapta cu buza a canyon_rocks e silueta care se citeste de la
##     100 m, cand granulatia texturii s-a topit in mipmap. Ea ramane familia
##     dominanta; masele rotunjite sunt contrapunctul, nu inlocuitorul.
##   - buget: chiar si dupa colaps, o formatiune din kit costa ~30% peste
##     echivalentul ei de canion (98/601/970 fata de 70/449/748 tris pe clasele
##     S/M/L). Pe Stramtoarea, unde intra ~200 de stanci, fiecare punct de cota
##     in plus se vede in garda.
const KIT_ROCK_SHARE: float = 0.35

## Din ce biblioteca vine o stanca din clasa `cls` ("S", "M" sau "L").
## Intoarce [cale, variante].
static func _rock_source(cls: String, kit: bool) -> Array:
	match cls:
		"S":
			return [KIT_ROCK_PATH, KIT_S] if kit else [CANYON_PATH, CANYON_S]
		"M":
			return [KIT_ROCK_PATH, KIT_M] if kit else [CANYON_PATH, CANYON_M]
		_:
			return [KIT_ROCK_PATH, KIT_L] if kit else [CANYON_PATH, CANYON_L]


## O stanca de canion din clasa de marime `cls` ("S", "M", "L"). Intoarce
## `false` daca AMBELE biblioteci lipsesc, ca apelantul sa cada pe vechiul prop
## in loc sa lase un gol.
##
## Inaltimea se scaleaza SEPARAT de amprenta (`h`), si asta e ce da varietate
## reala: aceeasi silueta la 0.8 si la 1.35 pe verticala citeste ca doua stanci
## diferite, gratis. Textura NU se intinde odata cu ea — clasa de roca e
## triplanara in spatiul LUMII, deci straturile raman la scara lumii indiferent
## cum e scalata instanta. Fara asta, o stanca turtita ar avea straturi turtite
## si s-ar vedea imediat ca e aceeasi piesa reciclata. Din acelasi motiv cele
## doua biblioteci se pot amesteca fara sa se vada cusatura: ambele iau aceeasi
## roca, proiectata in aceeasi lume.
static func _add_canyon_rock(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, cls: String, collide: bool,
		h_min: float = 0.80, h_max: float = 1.30,
		s_min: float = 0.85, s_max: float = 1.25) -> bool:
	# UN SINGUR numar pentru AMBELE decizii (ce biblioteca, ce varianta), si
	# asta nu e microoptimizare — e conditia ca masuratoarea sa insemne ceva.
	#
	# Prima incercare punea un `rng.randf() < KIT_ROCK_SHARE` inaintea alegerii
	# variantei. Sirul rng al benzii decide insa si cand pica gruparea
	# (`_build_bands`), iar fiecare grupare trage dupa ea 2-5 sateliti. Un
	# singur numar consumat in plus a deplasat tot sirul: Dunele a sarit de la
	# 230 la 398 de stanci fara ca nimic din densitatea CERUTA sa se schimbe, si
	# cifra din garda a devenit imposibil de citit (cat e decor nou, cat e sir
	# deplasat?). Cu un `randi()` in locul vechiului `randi_range()` — amandoua
	# scot exact un numar din generator — asezarea ramane bit-identica fata de
	# inainte, deci diferenta raportata e strict ce am adaugat.
	var draw := rng.randi()
	var kit := float(draw % 1000) / 1000.0 < KIT_ROCK_SHARE
	var kept := _pick_rock(cls, kit, draw)
	if kept == null:
		# O biblioteca lipsa nu trebuie sa lase gol slotul cat timp cealalta e
		# acolo: fallback pe familia opusa inainte de a raporta esec.
		kept = _pick_rock(cls, not kit, draw)
	if kept == null:
		return false
	var s := rng.randf_range(s_min, s_max)
	var h := rng.randf_range(h_min, h_max)
	var holder: Node3D
	if collide:
		holder = StaticBody3D.new()
	else:
		holder = Node3D.new()
	parent.add_child(holder)
	holder.add_child(kept)
	kept.scale = Vector3(s, s * h, s)
	Palette.apply_rock_material(kept)
	if collide:
		# Cilindru, nu sfera: o stiva in trepte e mai inalta decat lata, iar o
		# sfera pe amprenta ei ar lasa varful fara coliziune sau ar umfla baza
		# cu metri de aer. Cotele din AABB-ul real, ca la restul decorului.
		var aabb := Track.model_aabb(kept)
		var cyl := CylinderShape3D.new()
		cyl.radius = maxf(maxf(aabb.size.x, aabb.size.z) * 0.40, 0.4)
		cyl.height = maxf(aabb.size.y, 0.5)
		var shape := CollisionShape3D.new()
		shape.shape = cyl
		shape.position = Vector3.UP * (aabb.position.y + aabb.size.y * 0.5)
		holder.add_child(shape)
	holder.rotation.y = rng.randf_range(0.0, TAU)
	# Infipta putin in nisip: fusta de moloz din model ascunde linia de contact
	# doar daca stanca chiar intra in teren.
	holder.position = pos + Vector3.UP * -0.25
	return true


## Varianta se alege din CIFRELE DE SUS ale aceluiasi numar din care s-a ales
## biblioteca (cifrele de jos) — vezi nota de la _add_canyon_rock.
static func _pick_rock(cls: String, kit: bool, draw: int) -> Node3D:
	var src := _rock_source(cls, kit)
	var picks: Array = src[1]
	return pick_from_glb(String(src[0]),
		String(picks[(draw / 1000) % picks.size()]))


## --- Vegetatie din Stylized Nature MegaKit -----------------------------------
##
## Ce rezolva: desert_scatter.glb are cinci piese sub 40 de triunghiuri, toate
## sub 60 cm. Sunt corecte ca filler si costa aproape nimic, dar n-au SILUETA —
## la 30 m in fata masinii dispar in nisip, si banda lipita de drum ramane
## optic goala desi are peste o suta de obiecte in ea. Smocurile din kit au
## 0.85-1.45 m: rup linia solului, adica fac exact treaba pentru care banda
## exista.
##
## Toate se instantiaza cu `Palette.foliage_material()` — acelasi atlas, doar
## fara backface culling, fiindca geometria kitului e din foi deschise. Vezi
## nota de la foliage_material() pentru de ce nu s-a mers pe Solidify.
const KIT_PLANT_PATH: String = "res://assets/models/megakit_plants.glb"
## Langa asfalt: nimic peste ~1 m inaltime reala dupa scalare. Un obiect mai
## inalt la 1.5 m de drum ar acoperi apexul urmator.
const KIT_SMALL_PLANTS: Array[String] = ["Tuft_A", "Tuft_B", "Tuft_C",
	"Tuft_D", "Fan_A", "Fan_C", "Rosette_A"]
## Banda de mijloc si mai departe: mase care se vad de la 20 m.
const KIT_BIG_PLANTS: Array[String] = ["Scrub_A", "Fan_B", "Tuft_B", "Tuft_D"]
## Singurul accent VERTICAL din vegetatie. Rar prin constructie (vezi
## _place_band_prop): un copac mort e memorabil la a treia aparitie pe tur si
## tapet la a douazecea, si costa 3.100-3.600 de triunghiuri bucata.
const KIT_DEAD_TREES: Array[String] = ["Dead_A", "Dead_B"]


## O planta din kit, FARA coliziune (ca tot frunzisul: treci prin ea).
## Intoarce `false` daca biblioteca lipseste, ca apelantul sa cada pe vechiul
## prop.
static func _add_kit_plant(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, picks: Array[String],
		s_min: float = 0.85, s_max: float = 1.20) -> bool:
	var name_pick: String = picks[rng.randi_range(0, picks.size() - 1)]
	var kept := pick_from_glb(KIT_PLANT_PATH, name_pick)
	if kept == null:
		return false
	parent.add_child(kept)
	# Infipta 10 cm: modelele au baza plata, iar pe un teren cu panta o baza
	# plata asezata exact pe cota lasa o muchie de aer pe partea din vale.
	kept.position = pos + Vector3.UP * -0.10
	kept.rotation.y = rng.randf_range(0.0, TAU)
	kept.scale = Vector3.ONE * rng.randf_range(s_min, s_max)
	Palette.apply_foliage_material(kept)
	var sway := parent.get_node_or_null(^"Sway") as SwayDriver
	if sway == null:
		sway = parent.get_parent().get_node_or_null(^"Sway") as SwayDriver
	if sway != null:
		sway.add_item(kept)
	return true


## Copac mort: accentul vertical al peisajului de desert.
##
## Spre deosebire de restul vegetatiei, asta e un corp INCHIS (3% muchii de
## contur, doar varfurile de creanga), deci merge pe materialul obisnuit al
## lumii si NU se leagana — un trunchi uscat de 8 m care se indoaie in vant ar
## fi exact detaliul care strica iluzia in loc s-o construiasca.
##
## Primeste coliziune pe trunchi: la 8 m inaltime si langa drum, un copac prin
## care treci citeste ca bug, nu ca decor.
static func _add_dead_tree(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, collide: bool = true) -> bool:
	var name_pick: String = KIT_DEAD_TREES[
		rng.randi_range(0, KIT_DEAD_TREES.size() - 1)]
	var kept := pick_from_glb(KIT_PLANT_PATH, name_pick)
	if kept == null:
		return false
	var s := rng.randf_range(0.72, 1.05)
	var holder: Node3D = StaticBody3D.new() if collide else Node3D.new()
	parent.add_child(holder)
	holder.add_child(kept)
	kept.scale = Vector3.ONE * s
	Palette.apply_world_material(kept)
	if collide:
		# Doar trunchiul, nu si coroana de crengi: un cilindru pe amprenta
		# crengilor ar fi un zid invizibil de 7 m latime in jurul copacului.
		var aabb := Track.model_aabb(kept)
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.38 * s
		cyl.height = maxf(aabb.size.y, 1.0)
		var shape := CollisionShape3D.new()
		shape.shape = cyl
		shape.position = Vector3.UP * (aabb.position.y + aabb.size.y * 0.5)
		holder.add_child(shape)
	holder.rotation.y = rng.randf_range(0.0, TAU)
	holder.position = pos + Vector3.UP * -0.25
	return true


## O piesa marunta din desert_scatter.glb, FARA coliziune.
##
## Astea sunt cele mai numeroase de pe pista (peste 100), asa ca nu primesc corp
## fizic: sunt un MeshInstance3D pus direct sub container. Vizual strang drumul,
## fizic nu exista — vezi comentariul de la banda "hug".
static func _add_scatter(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, mat: Callable) -> void:
	const PICKS := ["Bush_A", "Bush_B", "Pebbles_A", "Pebbles_B", "Grass_Tuft"]
	var name_pick: String = PICKS[rng.randi_range(0, PICKS.size() - 1)]
	var kept := pick_from_glb("res://assets/models/desert_scatter.glb", name_pick)
	if kept == null:
		_add_dry_bush(parent, pos, rng, mat)
		return
	parent.add_child(kept)
	kept.position = pos + Vector3.UP * -0.15
	kept.rotation.y = rng.randf_range(0.0, TAU)
	# Supradimensionate cu ~70%: la scara reala (tufa de 60cm, pietricica de 30cm)
	# pur si simplu nu se vad de la inaltimea camerei, si banda lipita de drum
	# ramane goala. style_bible §2 cere oricum obiectele cu 10-20% peste scara —
	# aici mergem mai departe pentru ca astea sunt piesele care STRANG cadrul.
	kept.scale = Vector3.ONE * rng.randf_range(1.4, 2.1)
	Palette.apply_world_material(kept)
	# Doar ce are frunze se leagana. O pietricica scuturata de vant ar fi exact
	# genul de detaliu care strica iluzia in loc s-o construiasca.
	if name_pick.begins_with("Bush") or name_pick == "Grass_Tuft":
		var sway := parent.get_node_or_null(^"Sway") as SwayDriver
		if sway == null:
			sway = parent.get_parent().get_node_or_null(^"Sway") as SwayDriver
		if sway != null:
			sway.add_item(kept)


## Un grup de bolovani din rock_cluster.glb.
##
## Coliziunea, cand exista, e o SINGURA sfera pe grup — nu una per piatra.
## Falezele aduc deja ~130 de forme; aici nu mai cheltuim.
static func _add_cluster(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, picks: Array, collide: bool,
		mat: Callable) -> void:
	var name_pick: String = picks[rng.randi_range(0, picks.size() - 1)]
	var kept := pick_from_glb("res://assets/models/rock_cluster.glb", name_pick)
	if kept == null:
		_add_glb_rock(parent, pos, rng, mat)
		return
	var s := rng.randf_range(0.9, 1.3)
	if not collide:
		parent.add_child(kept)
		kept.position = pos + Vector3.UP * -0.2
		kept.rotation.y = rng.randf_range(0.0, TAU)
		kept.scale = Vector3.ONE * s
		Palette.apply_rock_material(kept)
		return
	var body := StaticBody3D.new()
	parent.add_child(body)
	body.add_child(kept)
	kept.scale = Vector3.ONE * s
	Palette.apply_rock_material(kept)
	# Raza din AABB-ul real, nu dintr-un tabel: regenerezi GLB-ul cu alte cote si
	# coliziunea le urmeaza singura.
	var mi := _first_mesh(kept)
	var radius := 1.2 * s
	var height := 2.0 * s
	if mi != null and mi.mesh != null:
		var aabb := mi.mesh.get_aabb()
		radius = maxf(aabb.size.x, aabb.size.z) * 0.38 * s
		height = aabb.size.y * s
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = maxf(radius, 0.4)
	shape.shape = sphere
	shape.position = Vector3.UP * height * 0.42
	body.add_child(shape)
	body.rotation.y = rng.randf_range(0.0, TAU)
	body.position = pos + Vector3.UP * -0.2


## Instantiaza un GLB, pastreaza un singur nod si anuleaza offsetul lui din
## fisier (variantele sunt exportate una langa alta pentru vizualizare).
##
## PUBLIC dinadins: il folosesc si TrackCliffs, si TrackScenography. A stat cu
## underscore in timp ce doua clase din afara il chemau oricum — adica era deja
## interfata, doar ca nu scria nicaieri.
static func pick_from_glb(path: String, node_name: String) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var container := (load(path) as PackedScene).instantiate() as Node3D
	var kept: Node3D = null
	for child in container.get_children():
		if child.name == node_name:
			kept = child
		else:
			# remove_child INAINTE de queue_free (tiparul din
			# Track._extract_glb_node): eliberarea e amanata pana la sfarsitul
			# cadrului, iar cine masoara scena in acelasi cadru — cum face
			# Track._collect_obstacles pentru chevron-uri — vedea ~5.000 de
			# variante-fantoma suprapuse peste fiecare piesa plasata.
			container.remove_child(child)
			child.queue_free()
	if kept == null:
		container.queue_free()
		return null
	container.position = -kept.position
	return container


static func _first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return node as MeshInstance3D
	for c in node.get_children():
		var found := _first_mesh(c)
		if found != null:
			return found
	return null


static func _add_tree(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator,
		mat: Callable) -> void:
	var tree := StaticBody3D.new()
	parent.add_child(tree)
	tree.position = pos + Vector3.UP * -0.3 # din iarba
	var scale_factor := rng.randf_range(0.8, 1.5)
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.25
	trunk_mesh.bottom_radius = 0.35
	trunk_mesh.height = 1.4 * scale_factor
	# CylinderMesh implicit are 64 de laturi si 4 inele. Un trunchi de copac
	# low-poly n-are nevoie de mai mult de 8 laturi si un inel.
	trunk_mesh.radial_segments = 8
	trunk_mesh.rings = 1
	trunk.mesh = trunk_mesh
	trunk.position = Vector3.UP * 0.7 * scale_factor
	trunk.material_override = mat.call(Color(0.45, 0.3, 0.18))
	tree.add_child(trunk)
	var crown := MeshInstance3D.new()
	var crown_mesh := CylinderMesh.new()
	crown_mesh.top_radius = 0.0 # con
	crown_mesh.bottom_radius = 1.6 * scale_factor
	crown_mesh.height = 3.2 * scale_factor
	crown_mesh.radial_segments = 9 # numar impar: silueta nu iese simetrica
	crown_mesh.rings = 1
	crown.mesh = crown_mesh
	crown.position = Vector3.UP * (1.4 * scale_factor + 1.6 * scale_factor)
	# verde in 4 trepte: padurea are 4 materiale de coroana, nu unul per copac
	var green := 0.45 + float(rng.randi_range(0, 3)) / 3.0 * 0.20
	crown.material_override = mat.call(Color(0.2, green, 0.22))
	tree.add_child(crown)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.4
	cyl.height = 2.5
	shape.shape = cyl
	shape.position = Vector3.UP * 1.25
	tree.add_child(shape)


static func _add_rock(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator,
		mat: Callable) -> void:
	var rock := StaticBody3D.new()
	parent.add_child(rock)
	rock.position = pos + Vector3.UP * -0.2
	rock.rotation.y = rng.randf_range(0.0, TAU)
	var size := rng.randf_range(0.8, 2.2)
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size, size * 0.7, size * 0.8)
	mesh_inst.mesh = box
	mesh_inst.position = Vector3.UP * size * 0.3
	mesh_inst.rotation.z = rng.randf_range(-0.2, 0.2)
	mesh_inst.material_override = mat.call(Color(0.55, 0.55, 0.58))
	rock.add_child(mesh_inst)
	var shape := CollisionShape3D.new()
	var col_box := BoxShape3D.new()
	col_box.size = Vector3(size, size, size * 0.8)
	shape.shape = col_box
	shape.position = Vector3.UP * size * 0.3
	rock.add_child(shape)


## Cactus saguaro din cactus.glb (Blender): trei siluete distincte — fara brate,
## un brat, doua brate — cu coliziune pe trunchi. Modelul aduce UV-uri catre
## slotul de paleta si AO copt in vertex colors; ii inlocuim materialul cu cel
## UNIC al lumii, deci cactusii se grupeaza cu restul decorului in foarte putine
## draw call-uri (vezi docs/blender_export.md).
##
## Variatia NU mai vine din culoare: paleta are un singur verde, prin constructie
## — asta e chiar scopul atlasului. Vine din silueta, rotatie si o scalare mica.
## Inaltimile din model (2.85 / 3.50 / 4.40 m) sunt deja in intervalul cerut de
## style_bible §2, asa ca nu le scalam agresiv — altfel ies din interval.
static func _add_cactus(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator,
		mat: Callable) -> void:
	if not ResourceLoader.exists("res://assets/models/cactus.glb"):
		_add_dry_bush(parent, pos, rng, mat)
		return
	var container := (load("res://assets/models/cactus.glb") as PackedScene) \
		.instantiate() as Node3D
	var picks: Array[String] = ["Cactus_A", "Cactus_B", "Cactus_C"]
	var keep_name: String = picks[rng.randi_range(0, picks.size() - 1)]
	var kept: Node3D = null
	for child in container.get_children():
		if child.name == keep_name:
			kept = child
		else:
			child.queue_free()
	if kept == null:
		container.queue_free()
		_add_dry_bush(parent, pos, rng, mat)
		return
	var body := StaticBody3D.new()
	parent.add_child(body)
	# Banda e ingusta intentionat: variantele acopera deja 2.85-4.40 m, iar
	# style_bible §2 cere 2.8-4.5. O scalare mai generoasa scoate exemplarele
	# extreme din interval — masurat cu tools/probe_decor.gd: 0.92 -> 2.63 m,
	# 0.98 -> 2.79 m (sub prag), 1.03 -> 4.53 m (peste prag).
	# Variatia vine din silueta si rotatie, nu din scara.
	var s := rng.randf_range(0.99, 1.02)
	container.scale = Vector3.ONE * s
	container.position = -kept.position * s # variantele sunt exportate in origine
	body.add_child(container)
	Palette.apply_world_material(container)
	# Inaltimea se citeste din model: regenerezi GLB-ul cu alte cote si coliziunea
	# o urmeaza singura, fara tabel de inaltimi hardcodat.
	var h := 3.2
	var mi := kept as MeshInstance3D
	if mi != null and mi.mesh != null:
		h = mi.mesh.get_aabb().size.y * s
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.34
	cyl.height = h
	shape.shape = cyl
	shape.position = Vector3.UP * h * 0.5
	body.add_child(shape)
	body.rotation.y = rng.randf_range(0.0, TAU)
	body.position = pos + Vector3.UP * -0.3


static func _add_glb_rock(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, mat: Callable) -> void:
	if not ResourceLoader.exists("res://assets/models/rocks.glb"):
		_add_rock(parent, pos, rng, mat)
		return
	var container := (load("res://assets/models/rocks.glb") as PackedScene) \
		.instantiate() as Node3D
	var picks: Array[String] = ["rock_small", "rock_medium", "rock_large"]
	var keep_name: String = picks[rng.randi_range(0, 2)]
	var kept: Node3D = null
	for child in container.get_children():
		if child.name == keep_name:
			kept = child
		else:
			child.queue_free()
	if kept == null:
		container.queue_free()
		_add_rock(parent, pos, rng, mat)
		return
	var body := StaticBody3D.new()
	parent.add_child(body)
	var s := rng.randf_range(0.55, 0.85)
	container.scale = Vector3.ONE * s
	container.position = -kept.position * s # anuleaza asezarea "una langa alta"
	body.add_child(container)
	# Inaltimea din AABB, nu dintr-un tabel. Cele trei cifre scrise de mana
	# (2.0 / 3.5 / 5.0) se nimereau exacte, dar rocks.glb e un asset vechi fara
	# UV pe sloturi si urmeaza sa fie scos — cand se intampla, coliziunea nu
	# trebuie sa ramana potrivita pe geometria care a plecat.
	var h: float = 3.5 * s
	var mi_rock := _first_mesh(kept)
	if mi_rock != null and mi_rock.mesh != null:
		h = mi_rock.mesh.get_aabb().size.y * s
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = h * 0.45
	shape.shape = sphere
	shape.position = Vector3.UP * h * 0.4
	body.add_child(shape)
	body.rotation.y = rng.randf_range(0.0, TAU)
	body.position = pos + Vector3.UP * -0.3


## Tufa uscata: doar vizual, treci prin ea.
static func _add_dry_bush(parent: Node3D, pos: Vector3,
		rng: RandomNumberGenerator, mat: Callable) -> void:
	var bush := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	var r := rng.randf_range(0.4, 0.8)
	sphere.radius = r
	sphere.height = r
	# Implicit SphereMesh e 64x32 = 4224 triunghiuri — pentru o tufa de 40cm,
	# adica geometria unei planete pe ceva cat o roata. La 8x4 ramane rotunda
	# la orice viteza de trecere si costa 64.
	sphere.radial_segments = 8
	sphere.rings = 4
	bush.mesh = sphere
	bush.position = pos + Vector3.UP * (r * 0.3 - 0.3)
	# Slotul de vegetatie uscata din paleta, in 3 trepte de nuanta (nu continuu,
	# altfel fiecare tufa ar cere material propriu).
	var tint := float(rng.randi_range(0, 2)) / 2.0 * 0.18
	bush.material_override = mat.call(
		Palette.color(Palette.DRY_VEGETATION).lightened(tint))
	parent.add_child(bush)
