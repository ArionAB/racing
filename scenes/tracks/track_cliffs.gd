class_name TrackCliffs
extends RefCounted
## Peretii de canion de pe marginea soselei.
##
## Inlocuiesc gardul rosu de 1.3m: pe tema desert, falezele fac SI vizualul, SI
## coliziunea. Se aseaza pe aceleasi segmente pe care vechea regula de perete
## cerea gard — exterior mereu, interior doar unde soseaua e inaltata — citite
## din [method TrackSideSampler.wall_segments], ca sa nu existe doua definitii
## care pot diverge.
##
## Coliziunea e o cutie convexa per sectiune, nu un trimesh: vezi _add_collision.

const MODEL_PATH: String = "res://assets/models/rocks/cliff_wall.glb"

## Cheia sub care falezele isi publica amprentele pe nodul-radacina.
const FOOTPRINT_META: StringName = &"cliff_footprints"

## Pasul de asezare. Sectiunile au 15m latime, deci se suprapun 1m. Suprapunerea
## nu e cosmetica: doua cutii de coliziune care se ating exact la muchie lasa o
## fisura in care Jolt agata masina.
const SPACING: float = 14.0
## Distanta de la marginea asfaltului pana la fata falezei, pe portiunile drepte.
const OFFSET_OUTER: float = 1.2
## Cat se retrag falezele pe EXTERIORUL virajelor.
##
## Masurat: cu 1.2m peste tot, ecartul dintre prima si ultima masina cadea de la
## 0.42 tururi la 0.03 — nimeni nu mai putea depasi. Cauza nu era coliziunea (zero
## blocaje, zero repuneri), ci ca linia larga de depasire dispare: masina rapida
## ramanea prinsa in pluton, cu de doua ori mai multe imbranceli si de patru ori
## mai putine atingeri de perete decat inainte.
##
## Exteriorul virajului e exact locul unde se depaseste, deci acolo peretele se
## trage inapoi. Vizual nu se pierde nimic: la viteza, un perete la 5m si unul la
## 1.2m arata la fel de aproape.
const OFFSET_CORNER: float = 5.0
## Pe interior, unde soseaua e inaltata, falezele stau mai retrase: acolo trec
## masinile care taie viraful, si un perete la 1.2m ar transforma scurtatura in
## capcana.
const OFFSET_INNER: float = 4.5
## Cat se ingroapa fiecare sectiune in nisip. Fara asta se vede linia de contact
## si se rupe iluzia de stanca iesita din sol.
const SINK: float = 0.6
## Cat trebuie sa respire COLTURILE fetei fata de marginea asfaltului.
##
## Mult mai putin decat OFFSET_OUTER, si intentionat: asta nu e o retragere
## estetica, e ultima plasa de siguranta impotriva unui perete peste sosea.
## Pusa la 1.2 m ar impinge in afara jumatate din canion pe fiecare viraj, adica
## ar strica exact senzatia de defileu pentru o problema care apare la cinci
## sectiuni din o suta treizeci.
const FACE_CLEAR: float = 0.3
## Cat se poate deplasa un colt de sectiune din inclinarea de "asezat de mana"
## (yaw +-0.10 rad pe un colt aflat la ~8 m de centru).
const YAW_SWING: float = 0.85
## Degajarea in jurul unui landmark hero. Style_bible §7 cere teren gol IN FATA
## landmark-urilor majore, iar „in fata" e o directie, nu o raza: silueta se
## vede de catre soferul care SE APROPIE. Ce sta dupa el, in oglinda, nu ascunde
## nimic.
##
## Pana la #164 degajarea era o raza simetrica de 25 m aplicata pe AMANDOUA
## laturile. Amandoua greselile trageau in aceeasi directie — gauri in canion
## unde nu foloseau nimanui (44 de sloturi din 168 pe Dunele) — dar se anulau
## partial: turnul de apa de la fractia 0.2 era vizibil doar fiindca landmark-ul
## VECIN, de pe latura cealalta, stergea din intamplare peretele de pe axa lui de
## vizare. Corectata doar latura, turnul isi pierdea picioarele.
const LANDMARK_CLEAR_AHEAD: float = 22.0
const LANDMARK_CLEAR_BEHIND: float = 22.0
## Culoarul de APROPIERE, dincolo de degajarea stricta: aici peretele nu se
## sterge, ci COBOARA la clasa de creasta. Un perete de pana la 11.5 m lipit de
## asfalt chiar taie picioarele unui turn de 9.5 m asezat la 19 m lateral; o
## creasta de 4 m ramane sub linia siluetei si tot tine masa in cadru.
##
## Prima incercare a fost sa se STEARGA si culoarul (degajare de 55 m in fata).
## Turnul iesea corect, dar sonda de compozitie a aratat pretul imediat: felia
## 0.800 pica de la acoperire plina la 26% pe dreapta, adica exact campia de
## nisip pe care issue-ul o reclama, reintrodusa ca sa protejam o silueta.
## Nu trebuia ales intre ele.
const LANDMARK_LOW_AHEAD: float = 65.0

## Cele trei clase de faleza. `MAIN` e peretele de canion dintotdeauna; celelalte
## doua sunt raspunsul la #164 — „drumul sapat intr-un masiv", nu asezat pe o
## campie cu stanci pe langa.
##
## FILL: creasta JOASA pe portiunile de margine pe care regula
## „exterior / interior inaltat" le lasa descoperite prin constructie. Rupe linia
## orizontului fara sa inchida drumul.
##
## TERRACE: al doilea rand, retras in banda `far` (26-34 m). Panoul DEPTH AND
## LAYERS din referinta are TREI planuri; noi aveam doua (marginea si siluetele
## de orizont de la 150 m). Asta e planul din mijloc, si e cel care face
## diferenta intre „stanci pe langa drum" si „trepte de canion".
enum Kind { MAIN, FILL, TERRACE }

## Creasta de umplere: destul cat sa rupa orizontul, nu cat sa faca al doilea
## perete. Se obtine turtind pe Y o sectiune normala, NU alegand o varianta mai
## mica: amprenta la sol trebuie sa ramana de 15 m, altfel sectiunile nu se mai
## ating si iese exact ce reclama issue-ul — piese discrete cu nisip intre ele.
const FILL_HEIGHT_MIN: float = 3.2
const FILL_HEIGHT_MAX: float = 5.2
## Cat de retrasa sta creasta de umplere. Mai mult decat OFFSET_INNER: aici
## marginea era complet libera pana acum, deci orice zid ingusteaza o linie care
## exista. 6 m pastreaza scurtatura si tot da masa in cadru.
const OFFSET_FILL: float = 6.0

## Al doilea plan: pas mai mare (sectiunile pot respira, sunt la 30 m) si
## inaltime peste randul de la drum, ca sa se citeasca drept TREAPTA urmatoare,
## nu drept al doilea gard paralel.
const TERRACE_SPACING: float = 22.0
const TERRACE_OFFSET_MIN: float = 26.0
const TERRACE_OFFSET_MAX: float = 34.0
const TERRACE_HEIGHT_MIN: float = 9.5
const TERRACE_HEIGHT_MAX: float = 14.5
## Cat de aproape de sosea (ORICE bucla a ei) mai are voie sa cada o treapta.
## Dunele se auto-intersecteaza la ~40 m, deci un rand la 30 m de o bucla poate
## ateriza fix pe cealalta — singurul lucru care prinde cazul e clearance_at.
const TERRACE_MIN_CLEARANCE: float = 9.0
## Degajarea treptei, mai lunga decat a peretelui de la drum. Treapta sta la
## 30 m lateral, adica taman pe cerul pe care se decupeaza silueta unui landmark
## asezat la 10-19 m — deci intra in cadru de mai departe decat un perete lipit
## de asfalt, care ramane sub linia lui.
const TERRACE_CLEAR_AHEAD: float = 60.0
const TERRACE_CLEAR_BEHIND: float = 25.0

## Variantele din GLB, cu inaltimea lor nominala. Godot alege varianta cea mai
## apropiata de inaltimea ceruta si scaleaza cel mult ±SCALE_LIMIT.
##
## 12 din august 2026 (upgrade-ul grafic): 6 mesa clasice + 6 siluete distincte
## (sa, treapta dubla, surplomba, varf tesit, crestatura, coama dubla joasa).
## Cu oglindirea de mai jos ies 24 de siluete — repetitia era sursa #1 a
## aspectului "pătrățos" pe Dunele (~130 de instante din 6 mesh-uri).
const VARIANTS := [
	{"node": "Cliff_A", "height": 6.5},
	{"node": "Cliff_B", "height": 8.0},
	{"node": "Cliff_C", "height": 9.5},
	{"node": "Cliff_D", "height": 11.0},
	{"node": "Cliff_E", "height": 7.5},
	{"node": "Cliff_F", "height": 10.0},
	{"node": "Cliff_G", "height": 9.0},
	{"node": "Cliff_H", "height": 12.5},
	{"node": "Cliff_I", "height": 7.0},
	{"node": "Cliff_J", "height": 10.5},
	{"node": "Cliff_K", "height": 8.5},
	{"node": "Cliff_L", "height": 6.0},
]
## Peste atat se vede intinderea straturilor de roca.
const SCALE_LIMIT: float = 0.18
## Cat de departe de inaltimea ceruta mai intra o varianta in bazinul de alegere.
## 0.22 -> 0.18: bazinul e oricum de doua ori mai bogat cu 12 variante, deci
## putem fi mai stricti cu intinderea si tot pastram varietatea.
const VARIANT_TOLERANCE: float = 0.18


## Construieste falezele si le intoarce sub un singur nod.
##
## `landmarks` are formatul din [code]Track._landmark_spots()[/code]:
## (fractie 0..1, parte ±1, id-model).
## `enabled` vine din tema pistei (Track.themes(), cheia "cliffs"). Inainte era
## `theme != "desert"` — adica falezele de canion erau legate de numele unei
## piste, nu de o proprietate a lumii. Insula are promontoriu de zid gusuku, nu
## canion, deci ii trebuia un "nu" care sa nu insemne "nu sunt desert".
## `gorges` = intervale (frac_start, frac_end) de defileu: acolo peretii apar pe
## AMBELE laturi (si pe interior neinaltat, unde altfel nu se pun), inalti si
## traşi aproape de asfalt, fara ferestrele de "respiro". Momentul-semnatura al
## pistei (#28) — 80-120 m in care lumea se inchide peste tine.
static func build(sampler: TrackSideSampler, enabled: bool, seed_value: int,
		landmarks: Array[Vector3], gorges: Array[Vector2] = []) -> Node3D:
	var root := Node3D.new()
	root.name = "Cliffs"
	# Amprentele sectiunilor asezate, publicate pe nodul-radacina ca metadata.
	# Decorul se construieste DUPA faleze si le citeste de aici ca sa nu-si
	# planteze tufele in interiorul peretelui — vezi TrackDecor.build.
	#
	# Metadata, si nu inca o valoare de retur: `build` intoarce un nod, iar cine
	# nu are treaba cu amprentele nu trebuie sa afle ca exista.
	var prints: Array[Dictionary] = []
	root.set_meta(FOOTPRINT_META, prints)
	if not enabled or not ResourceLoader.exists(MODEL_PATH):
		return root

	var scene := load(MODEL_PATH) as PackedScene
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 4242
	var total := sampler.total_length()
	if total <= 0.0:
		return root

	# Degajarile, ca (distanta pe traseu, latura). Latura se PASTREAZA — pana la
	# #164 se citea doar `lm.x` si degajarea se aplica pe amandoua laturile, deci
	# un turn de apa asezat pe stanga stergea 50 m de faleza si pe DREAPTA, unde
	# nu ascundea nimic. Pe Dunele asta taia 44 de sloturi din 168; jumatate erau
	# pe latura opusa, adica gauri fara motiv. Ca dovada ca intentia fusese
	# mereu per-latura: `Track._cliff_clearings` adauga arcada de DOUA ori, o data
	# pentru fiecare parte — ceva ce n-are sens daca latura oricum se ignora.
	var clear_at: Array[Vector2] = []
	for lm in landmarks:
		clear_at.append(Vector2(lm.x * total, lm.y))

	for side_sign: float in [-1.0, 1.0]:
		var segments := sampler.wall_segments(side_sign)
		# UN singur corp static per latura, cu multe forme copil. Jolt trateaza
		# asta mult mai bine decat ~70 de corpuri separate.
		var body := StaticBody3D.new()
		body.name = "CliffBody%s" % ("L" if side_sign < 0.0 else "R")
		body.add_to_group("cliffs")
		# Layer 8: "ce n-are voie sa stea intre camera si masina". Camera face
		# raycast DOAR pe layer-ul asta — pe layer-ul implicit ar lovi popice,
		# mingea si celelalte masini, si fiecare depasire ar smuci cadrul.
		body.collision_layer |= Track.CAMERA_BLOCKER_LAYER
		root.add_child(body)

		for spec in sampler.sample_edge(SPACING, OFFSET_OUTER):
			if spec.side_sign != side_sign:
				continue
			var d := spec.frac * total
			var gorge := _gorge_blend(spec.frac, gorges)
			if _near_landmark(d, side_sign, total, clear_at):
				continue
			# Culoarul de apropiere: perete, dar jos. Defileul bate regula —
			# acolo inaltimea E efectul, iar un landmark in defileu ar fi oricum
			# o contradictie de compozitie.
			var low := gorge <= 0.0 and _near_landmark(
				d, side_sign, total, clear_at, LANDMARK_LOW_AHEAD, 0.0)
			# O rapa cu un zid in fata nu se vede, deci nu e nici drama, nici
			# avertisment — e doar o groapa in care cazi fara sa intelegi de ce.
			# Aici peretele se deschide si prapastia devine lizibila de departe.
			if spec.is_ravine:
				continue
			# In defileu, regula "perete doar unde marginea e inchisa" se
			# suspenda: strangerea cere zid pe AMBELE laturi, inclusiv pe
			# interiorul neinaltat.
			if gorge > 0.0 or TrackSideSampler.in_segments(d, segments):
				# Ferestrele de respiro nu au ce cauta in defileu: o gaura in zid
				# exact unde lumea trebuie sa se inchida i-ar rupe tot efectul.
				if gorge <= 0.0 and _skip_slot(spec):
					continue
				_place(root, body, scene, sampler, spec, rng, gorge,
					Kind.FILL if low else Kind.MAIN)
			elif not _skip_fill(spec):
				# Marginea descoperita prin constructie (interior neinaltat).
				# Pana acum nu se punea NIMIC aici; de-aia banda cea mai densa de
				# decor tot citea ca „pietre presarate" — piesele mari lipseau de
				# pe portiuni intregi.
				_place(root, body, scene, sampler, spec, rng, 0.0, Kind.FILL)

		# Al doilea plan, retras. Se sampleaza separat: are pas propriu si nu
		# imparte niciun filtru cu randul de la drum in afara degajarilor.
		for spec in sampler.sample_edge(TERRACE_SPACING, OFFSET_OUTER):
			if spec.side_sign != side_sign:
				continue
			var d := spec.frac * total
			if _near_landmark(d, side_sign, total, clear_at,
					TERRACE_CLEAR_AHEAD, TERRACE_CLEAR_BEHIND):
				continue
			if spec.is_ravine:
				continue
			# Fereastra de respiro din randul de la drum e exact locul unde al
			# doilea plan trebuie sa EXISTE: altfel gaura merge pana la orizont
			# si prin ea se vede campia goala, adica fix ce nega canionul.
			# Golul se muta cu 30 m in spate, nu dispare.
			if not _skip_slot(spec) and _skip_terrace(spec):
				continue
			_place(root, null, scene, sampler, spec, rng, 0.0, Kind.TERRACE)
	return root


## Cat de "in defileu" e fractia asta: 0 in afara, 1 in miez, cu rampe line de
## intrare/iesire pe ~18% din lungimea intervalului la fiecare capat. Fara
## rampe, primul perete de 12 m ar aparea de nicaieri langa unul de 7 —
## defileul trebuie sa se STRANGA in jurul tau, nu sa te teleporteze in el.
## Aritmetica e circulara: un interval poate trece peste linia de start.
static func _gorge_blend(frac: float, gorges: Array[Vector2]) -> float:
	var best := 0.0
	for g in gorges:
		var span := fposmod(g.y - g.x, 1.0)
		if span <= 0.001:
			continue
		var t := fposmod(frac - g.x, 1.0)
		if t > span:
			continue
		var edge := span * 0.18
		var blend := 1.0
		if t < edge:
			blend = t / edge
		elif t > span - edge:
			blend = (span - t) / edge
		best = maxf(best, blend)
	return best


## Distanta `d` cade in degajarea unui landmark de pe ACEEASI latura?
##
## Doua asimetrii, amandoua din acelasi motiv — degajarea serveste o PRIVIRE, nu
## un obiect:
##   - latura: peretele de vizavi nu sta niciodata intre sofer si landmark;
##   - sensul: `ahead` acopera portiunea DINAINTEA landmark-ului, de unde te
##     apropii si de unde se citeste silueta; `behind` e scurt, fiindca ce ramane
##     in urma nu mai ascunde nimic.
##
## Aritmetica e circulara: un landmark la fractia 0.02 trebuie sa-si protejeze
## si sfarsitul turului.
static func _near_landmark(d: float, side_sign: float, total: float,
		clear_at: Array[Vector2], ahead: float = LANDMARK_CLEAR_AHEAD,
		behind: float = LANDMARK_CLEAR_BEHIND) -> bool:
	for c in clear_at:
		if not is_equal_approx(c.y, side_sign):
			continue
		# Negativ = slotul e INAINTEA landmark-ului pe sensul de mers.
		var delta := fposmod(d - c.x + total * 0.5, total) - total * 0.5
		if delta <= 0.0 and -delta < ahead:
			return true
		if delta > 0.0 and delta < behind:
			return true
	return false


static func _place(root: Node3D, body: StaticBody3D, scene: PackedScene,
		sampler: TrackSideSampler,
		spec: TrackDecorSpec, rng: RandomNumberGenerator,
		gorge: float = 0.0, kind: Kind = Kind.MAIN) -> void:
	var wanted := _wanted_height(spec, rng)
	if kind == Kind.TERRACE:
		wanted = _terrace_height(spec, rng)
	# Defileul forteaza inaltimea spre 12 m, PESTE plafonul de apex din
	# _wanted_height: acolo plafonul exista ca sa vezi iesirea din viraj, dar
	# intr-un defileu tocmai ca NU vezi iesirea e tot efectul. Lerp-ul cu
	# blend-ul de intrare face trecerea de la un perete normal la unul de 12 m
	# in 2-3 sectiuni, nu dintr-un foc.
	if gorge > 0.0:
		wanted = lerpf(wanted, 12.2, gorge)
	var pick := _variant_for(wanted, rng)
	var model := _extract(scene, pick["node"])
	if model == null:
		return

	# Scara CONTINUA. Cuantizarea de dinainte se justifica prin "altfel fiecare
	# sectiune ar fi un mesh unic", ceea ce e fals: scara uniforma a unui nod nu
	# duplica niciodata o resursa Mesh. Gruparea in draw call-uri vine din
	# materialul partajat, nu din scara. Deci trepte in plus, gratis.
	var scale_factor: float = clampf(wanted / float(pick["height"]),
		1.0 - SCALE_LIMIT, 1.0 + SCALE_LIMIT)

	# Originea modelului e centrata pe adancime, deci jumatate din faleza sta in
	# fata originii. Fara corectia asta, o sectiune adanca de 6m aterizeaza cu
	# 3m PESTE asfalt. Se citeste din AABB, nu dintr-un tabel: regenerezi GLB-ul
	# cu alte cote si asezarea le urmeaza singura.
	var half_depth := _half_depth(model) * scale_factor
	# Cat de departe sta peretele. Retragerea se aplica DOAR unde se depaseste —
	# aplicata peste tot (prima incercare), lasa un camp gol de nisip intre drum
	# si stanca pe portiunile drepte, si canionul se pierde. Vazut in vederea
	# soferului la frac=0.20; la frac=0.55, in viraj, retragerea e exact potrivita.
	var extra := 0.0
	if not spec.is_exterior:
		extra = OFFSET_INNER - OFFSET_OUTER
	elif spec.is_apex or spec.is_braking:
		# Viraj strans sau zona de franare: aici chiar se depaseste, deci cel mai
		# mult loc (style_bible §7 cere 8m liberi la franare).
		extra = OFFSET_CORNER + 2.0 - OFFSET_OUTER
	# In defileu peretele vine la 0.8 m de asfalt, peste TOATE retragerile de
	# mai sus — inclusiv cea de depasire. E un risc asumat si masurat: retragerea
	# de pe exterioare exista fiindca 1.2 m PESTE TOT omora depasirile (ecartul
	# cadea la 0.03 tururi); aici sunt ~110 m din ~1140, iar sonda de cursa
	# verifica ecartul dupa. Daca scade, se scurteaza defileul, nu se largeste.
	if gorge > 0.0:
		extra = lerpf(extra, 0.8 - OFFSET_OUTER, gorge)
	# Clasele noi isi impun propria retragere, peste toata logica de mai sus:
	# creasta de umplere sta pe o margine care pana acum era complet libera, iar
	# treapta e prin definitie al doilea plan.
	var sink := SINK
	if kind == Kind.FILL:
		# maxf, nu atribuire: pe exteriorul unui viraj regula de depasire cere
		# 7 m, iar o creasta pusa la 6 m ar STRANGE o linie pe care alta decizie,
		# masurata pe ecartul din cursa, o largise deliberat.
		extra = maxf(extra, OFFSET_FILL - OFFSET_OUTER)
	elif kind == Kind.TERRACE:
		extra = rng.randf_range(TERRACE_OFFSET_MIN, TERRACE_OFFSET_MAX) \
			- OFFSET_OUTER
		# Mai ingropata: la 30 m se vede doar creasta, iar baza trebuie sa iasa
		# din duna, nu sa stea pe ea.
		sink = SINK * 2.2
	var pos := spec.position + spec.normal_out * (extra + half_depth)
	# CORECTIA DE COARDA. Toata asezarea de pana aici lucreaza cu MIJLOCUL fetei
	# sectiunii. O sectiune are insa 15 m latime si e dreapta, iar marginea
	# drumului e curba: pe interiorul unui viraj, capetele fetei taie coltul si
	# ajung peste asfalt chiar daca mijlocul sta cuminte la 1.2 m. Sagitta unei
	# coarde de 15 m pe o raza de 25 m e ~1.1 m — masurat pe Dunele, cinci
	# sectiuni intrau peste sosea, una cu 4.26 m.
	#
	# Se verifica deci COLTURILE fetei, nu centrul, si se impinge sectiunea in
	# afara pana cand si ele respira. Iterativ, fiindca impingerea muta coltul si
	# raspunsul se schimba; trei pasi ajung, iar peste ei renuntam si lasam cum e
	# (mai bine un colt de 20 cm peste margine decat un perete impins la infinit
	# pe o geometrie pe care n-am prevazut-o).
	# Se testeaza TOATE PATRU colturile amprentei, nu doar cele doua din fata:
	# pistele se auto-intersecteaza (Dunele trece la ~40 m de ea insasi), iar o
	# sectiune adanca de 7 m poate sta cuminte fata de bucla ei si sa ajunga cu
	# SPATELE peste cealalta. `clearance_at` masoara distanta pana la cea mai
	# apropiata bucla, deci prinde ambele cazuri fara sa stie despre ele.
	#
	# `face_half` se umfla cu bataia yaw-ului: inclinarea de "asezat de mana" se
	# aplica mai jos, pe nodul-model, dupa ce pozitia e deja decisa. Un colt la
	# ~8 m de centru se deplaseaza cu pana la 0.8 m la +-0.10 rad, si fara marja
	# asta corectia ar fi masurat o sectiune care nu exista inca.
	var box := Track.model_aabb(model)
	var face_half := box.size.x * 0.5 * scale_factor + YAW_SWING
	var basis_now := Basis.looking_at(-spec.normal_out, Vector3.UP)
	# Se PASTREAZA cea mai buna pozitie incercata, nu ultima. Impingerea "in
	# afara" nu e monoton buna: pe portiunile unde pista trece pe langa ea insasi
	# (Dunele, la ~40 m), a te departa de o bucla inseamna a te apropia de
	# cealalta, si trei pasi la rand pot inrautati situatia — masurat, o sectiune
	# a ajuns de la 4.26 m peste asfalt la 6.34 m.
	var best_pos := pos
	var best_clear := _face_clearance(pos, basis_now, face_half, half_depth,
		sampler)
	for _step in 3:
		if best_clear >= sampler.half_width() + FACE_CLEAR:
			break
		pos += spec.normal_out * (sampler.half_width() + FACE_CLEAR - best_clear)
		var got := _face_clearance(pos, basis_now, face_half, half_depth, sampler)
		if got > best_clear:
			best_clear = got
			best_pos = pos
	pos = best_pos
	# Daca nici asa nu incape, sectiunea NU se aseaza. Un gol in perete se vede;
	# un perete peste asfalt se loveste. Din 130 de sectiuni pe Dunele, cazul
	# apare de cateva ori, si mereu acolo unde bucla vecina inchide oricum
	# orizontul.
	if best_clear < sampler.half_width():
		model.queue_free()
		return
	# Dunele se auto-intersecteaza la ~40 m, deci orice piesa impinsa lateral
	# poate ateriza pe cealalta bucla a soselei. Slotul a fost verificat la 1.2 m
	# de margine; dupa retragere e alt punct, deci se verifica din nou. Fara asta,
	# treapta de 12 m de la 30 m distanta cade uneori PE drum.
	if kind != Kind.MAIN \
			and sampler.clearance_at(pos) < sampler.half_width() + TERRACE_MIN_CLEARANCE:
		model.queue_free()
		return
	# Re-esantionam cota: slotul s-a mutat lateral pana la ~7 m fata de unde a
	# fost masurat, iar pe o panta de 12% asta inseamna aproape un metru de
	# diferenta — destul cat sa se vada baza falezei plutind sau ingropata.
	pos.y = sampler.ground_y(pos.x, pos.z) - sink

	# Creasta de umplere se obtine TURTIND pe Y, nu alegand o varianta mai mica:
	# amprenta la sol ramane de 15 m, deci sectiunile vecine se ating in
	# continuare si linia iese continua. O varianta mica scalata uniform ar avea
	# si amprenta mica, adica exact „piese discrete cu nisip intre ele".
	# Materialul de roca e triplanar (proiectie in spatiul lumii), deci turtirea
	# NU intinde textura — straturile raman la scara lor.
	var squash := 1.0
	if kind == Kind.FILL:
		var crest := rng.randf_range(FILL_HEIGHT_MIN, FILL_HEIGHT_MAX)
		squash = clampf(crest / maxf(wanted * scale_factor, 0.01), 0.25, 0.7)

	# Orientarea se calculeaza o data si se aplica AMANDURORA: nodului vizual si
	# formei de coliziune. Asa nu pot ajunge sa se contrazica.
	var basis := Basis.looking_at(-spec.normal_out, Vector3.UP)
	var xform := Transform3D(
		basis.scaled(Vector3(scale_factor, scale_factor * squash, scale_factor)),
		pos)

	# Amprenta, pentru decorul care se aseaza dupa noi. Se publica DUPA ce
	# pozitia s-a stabilizat (corectia de coarda de mai sus o poate fi mutat).
	if root.has_meta(FOOTPRINT_META):
		(root.get_meta(FOOTPRINT_META) as Array).append({
			"pos": pos, "right": basis_now.x, "fwd": basis_now.z,
			"hx": face_half, "hz": half_depth,
		})

	var holder := Node3D.new()
	root.add_child(holder)
	holder.transform = xform
	holder.add_child(model)
	# Oglindirea dubleaza numarul de siluete distincte cu 6 variante de GLB si
	# zero triunghiuri in plus. NU cere niciun material special: Godot inverseaza
	# singur winding-ul dupa determinantul transformarii (verificat pe 4.7 cu
	# tools/MirrorTest.tscn). Versiunea veche punea peste el materialul geaman cu
	# CULL_FRONT — al DOILEA flip — si fetele dinspre camera erau taiate: jumatate
	# din faleze se vedeau pe dinauntru, ca niste coji. De aici bugul "stancile
	# mari sunt goale". Coliziunea NU se oglindeste: e o cutie aproape simetrica,
	# iar oglindirea ei poate doar sa creeze pene intre sectiuni.
	#
	# Compensarea aia e insa a NODULUI, si sectiunile astea nu raman noduri:
	# `Track` le coace in multimesh, unde transformarea nu mai trece prin ea. Tot
	# bugul s-a intors asa, pe jumatate din peretii fiecarei piste — reparatia sta
	# in `TrackDecorBatch._flipped_mesh`, adica in coacere. Aici nu e nimic de
	# schimbat, dar cine muta oglindirea de aici trebuie sa stie ca ea depinde de
	# ce se intampla dupa.
	var mirror := rng.randf() < 0.5
	if mirror:
		model.scale = Vector3(-1.0, 1.0, 1.0)
	# Inclinarea de "asezat de mana" sta DOAR pe model, nu pe holder: un corp de
	# coliziune inclinat creeaza o pana intre sectiuni vecine, exact felul de colt
	# in care se intepeneste o masina.
	#
	# Yaw-ul era hardcodat ZERO, deci fiecare faleza prezenta soferului exact
	# aceeasi fata. Plafon dur la ±0.10 rad: o sectiune de 15 m isi deplaseaza
	# capatul cu 0.75 m la unghiul asta, iar suprapunerea dintre sectiuni e de
	# doar 1 m. Mai mult deschide fisuri — exact ce prinde sonda --mode=cliff.
	# Pe creasta turtita, inclinarea de pe X/Z ar deveni forfecare (rotatie sub un
	# parinte scalat neuniform), deci ramane doar yaw-ul, care e in axa scalarii.
	var tilt := 0.0 if kind == Kind.FILL else 0.07
	# LANGA ASFALT inclinarea X/Z se stinge. Colizorul ramane intentionat drept
	# (unul inclinat deschide pene intre sectiuni — vezi mai sus), deci tot ce
	# se apleaca spre drum e silueta FARA fizica: masina intra vizual in piatra
	# inainte s-o opreasca ceva. probe_rock_fit pica la gauri de >= 0.35 m aflate
	# sub 2.5 m de asfalt — exact ce a produs o sectiune Cliff_J aterizata la
	# 0.77 m dupa ce moara de pe Dunele a redistribuit sloturile. Departe de
	# drum compromisul documentat ramane (gaurile de 0.4 m la 4-6 m nu le simte
	# nimeni). Yaw-ul NU se stinge: el intra si in colizor (_add_collision).
	#
	# Extragerile din rng raman NECONDITIONATE — zero-ul vine din inmultire, nu
	# din sarirea apelurilor, altfel s-ar reamesteca toata pista din urma lor.
	var tilt_room := smoothstep(2.0, 5.0,
		best_clear - sampler.half_width())
	model.rotation = Vector3(
		rng.randf_range(-tilt, tilt) * tilt_room,
		rng.randf_range(-0.10, 0.10),
		rng.randf_range(-tilt, tilt) * tilt_room)
	# Materialul de CLASA al rocii (trim sheet triplanar), nu cel de atlas:
	# falezele sunt suprafata de roca dominanta din cadru — vezi
	# Palette.rock_material() pentru de ce si de ce nu prin UV unwrap.
	Palette.apply_rock_material(holder)

	# Treapta a doua NU primeste coliziune, din acelasi motiv pentru care banda
	# `far` din TrackDecor n-are: la 26-34 m de margine esti demult in afara
	# soselei, iar un colizor acolo nu e gameplay, e o capcana in care te opresti
	# dupa un fly-off ratat. Creasta de umplere primeste, fiindca e la 6 m si
	# acolo exista deja stanci cu corp fizic din banda `mid`.
	if body != null:
		_add_collision(body, pick["node"], scene, xform, mirror)
	# Banda de contact are rost doar unde ochiul chiar ajunge la baza. La 30 m,
	# doua pietricele de 30 cm sunt triunghiuri platite degeaba.
	if kind != Kind.TERRACE:
		_dress_base(root, sampler, spec, rng, extra)


## Banda de contact: pietricele si smocuri la baza falezei (val 4c).
##
## Trucul #1 de sol al BBR2: cusatura dintre un obiect si teren nu se vede
## NICIODATA — mereu e mascata de murdarie sau vegetatie. La noi linia
## faleza/nisip era o intersectie geometrica curata, si SINK + AO-ul de teren
## o atenuau doar partial. Cateva prop-uri marunte din desert_scatter (care
## exista deja, partajeaza atlasul, zero materiale noi) o rup de tot.
##
## Zero coliziune: sunt sub 40 cm, style_bible-ul le trateaza ca decor pur.
const SCATTER_PATH: String = "res://assets/models/scatter/desert_scatter.glb"
const BASE_PROPS := ["Pebbles_A", "Pebbles_B", "Bush_A", "Grass_Tuft"]

static func _dress_base(root: Node3D, sampler: TrackSideSampler,
		spec: TrackDecorSpec, rng: RandomNumberGenerator,
		extra: float) -> void:
	if rng.randf() > 0.55:
		return
	var count := rng.randi_range(1, 2)
	for k in count:
		var pick: String = BASE_PROPS[rng.randi_range(0, BASE_PROPS.size() - 1)]
		var prop := TrackDecor.pick_from_glb(SCATTER_PATH, pick)
		if prop == null:
			return
		# Intre marginea asfaltului si fata peretelui, imprastiat in lungul
		# sectiunii — la baza, unde ochiul cauta cusatura.
		var along := (rng.randf() - 0.5) * SPACING * 0.8
		var out := extra * 0.4 + rng.randf_range(0.3, 1.4)
		var tangent := spec.normal_out.cross(Vector3.UP)
		var pos := spec.position + spec.normal_out * out + tangent * along
		pos.y = sampler.ground_y(pos.x, pos.z)
		root.add_child(prop)
		prop.position = pos
		prop.rotation.y = rng.randf_range(0.0, TAU)
		prop.scale = Vector3.ONE * rng.randf_range(0.8, 1.25)
		Palette.apply_world_material(prop)


## Inaltimea dorita la fractia asta: doua valuri suprapuse, plus o variatie in
## trepte. Canionul respira in loc sa fie un tunel uniform.
##
## Doua frecvente, nu una: cu un singur sinus lent, pereti vecini ies aproape la
## fel de inalti si peisajul citeste ca un zid continuu — verificat din vederea
## soferului. Al doilea val, mai rapid, rupe linia de sus.
static func _wanted_height(spec: TrackDecorSpec,
		rng: RandomNumberGenerator) -> float:
	# Frecventele erau 3.7 si 11.3, cu raportul 3.05 — aproape intreg, deci se
	# sincronizau si aceeasi succesiune de siluete revenea de ~3.7 ori pe tur.
	# 2.3 si 7.9 dau raportul 3.43, care nu se inchide intr-un tur.
	var slow := sin(spec.frac * TAU * 2.3) * 2.2
	var fast := sin(spec.frac * TAU * 7.9) * 1.4
	# Termen defazat PER LATURA: fara el, cei doi pereti respirau la unison.
	var lean := sin(spec.frac * TAU * 1.3 + spec.side_sign * 2.1) * 1.6
	var step := float(rng.randi_range(0, 3)) * 0.75
	var h := 8.0 + slow + fast + lean + step
	# In apexul unui viraj, peretele scade: altfel nu vezi iesirea din curba.
	#
	# Plafonul era fix 7.0, exact la mijloc intre Cliff_A (6.5) si Cliff_E (7.5).
	# Cum alegerea variantei folosea `<` strict, A castiga MEREU — fiecare apex de
	# pe pista primea identic aceeasi stanca.
	if spec.is_apex:
		h = minf(h, rng.randf_range(6.6, 7.9))
	return clampf(h, 6.5, 11.5)


## Inaltimea celui de-al doilea plan. PESTE randul de la drum (6.5-11.5 m), ca
## sa se citeasca drept treapta urmatoare a masivului: daca ar fi la fel de inalt
## si retras cu 30 m, ar arata ca un al doilea gard paralel, nu ca relief.
##
## Frecventa lenta (1.1) si defazata per latura: peretii apropiati respira deja
## pe 2.3 / 7.9 / 1.3, iar o a patra frecventa apropiata de ele ar bate cu ele si
## ar produce, la anumite fractii, un singur bloc masiv de 26 m adancime.
static func _terrace_height(spec: TrackDecorSpec,
		rng: RandomNumberGenerator) -> float:
	var slow := sin(spec.frac * TAU * 1.1 + spec.side_sign * 0.9) * 2.4
	var step := float(rng.randi_range(0, 3)) * 0.9
	return clampf(11.4 + slow + step, TERRACE_HEIGHT_MIN, TERRACE_HEIGHT_MAX)


## Ferestrele crestei de umplere. Mai rare decat cele ale peretelui principal
## (~10% fata de ~18%): creasta e joasa si retrasa, deci un gol in ea nu
## odihneste ochiul, doar reintroduce campia.
static func _skip_fill(spec: TrackDecorSpec) -> bool:
	var f := 4.3 if spec.side_sign < 0.0 else 6.7
	return sin(spec.frac * TAU * f + 2.6) > 0.85


## Ferestrele treptei a doua. Nu se aplica acolo unde randul de la drum e deja
## deschis — vezi apelul din `build`.
static func _skip_terrace(spec: TrackDecorSpec) -> bool:
	var f := 2.9 if spec.side_sign < 0.0 else 4.7
	return sin(spec.frac * TAU * f + 0.8) > 0.55


## Se sare complet peste slotul asta? Un perete neintrerupt de 1200m obose ochiul
## si ascunde reperele de la orizont. Golurile lasa sa se vada butte-urile si dau
## senzatia ca soseaua IESE din canion si intra iar in el.
static func _skip_slot(spec: TrackDecorSpec) -> bool:
	# ~18% din traseu ramane deschis, in ferestre lungi (nu gauri izolate, care
	# ar arata ca sectiuni lipsa).
	# side_sign era doar o defazare a ACELEIASI sinusoide, deci ambele laturi se
	# deschideau in acelasi loc. Frecvente diferite per latura: tiparul nu se mai
	# repeta intr-un tur.
	var f := 5.1 if spec.side_sign < 0.0 else 3.9
	var ph := 1.7 if spec.side_sign < 0.0 else 4.4
	return sin(spec.frac * TAU * f + ph) > 0.72


## Alege o varianta din bazinul celor care incap in inaltimea ceruta.
##
## Era argmin pur: pentru fiecare inaltime iesea MEREU aceeasi stanca, deci cele
## 6 variante se roteau dupa un tipar previzibil. Cu un bazin de toleranta ies
## de obicei 2-4 candidate, si zarul decide — aceeasi silueta de perete, alta
## piatra de fiecare data.
static func _variant_for(height: float, rng: RandomNumberGenerator) -> Dictionary:
	var pool: Array = []
	for v in VARIANTS:
		if absf(float(v["height"]) - height) <= height * VARIANT_TOLERANCE:
			pool.append(v)
	if pool.is_empty():
		# Nimic in toleranta (inaltimi extreme): cade inapoi pe cel mai apropiat.
		var best: Dictionary = VARIANTS[0]
		var best_delta := INF
		for v in VARIANTS:
			var delta: float = absf(float(v["height"]) - height)
			if delta < best_delta:
				best_delta = delta
				best = v
		return best
	return pool[rng.randi_range(0, pool.size() - 1)]


## Cat de departe de cea mai apropiata bucla de sosea sta cel mai expus colt al
## amprentei. Toate patru, fiindca o sectiune poate atinge drumul si cu spatele.
static func _face_clearance(pos: Vector3, basis: Basis, face_half: float,
		depth_half: float, sampler: TrackSideSampler) -> float:
	var worst := 1e12
	for side: float in [-1.0, 1.0]:
		for front: float in [-1.0, 1.0]:
			var corner := pos + basis * Vector3(
				side * face_half, 0.0, front * depth_half)
			worst = minf(worst, sampler.clearance_at(corner))
	return worst


## Scoate o singura varianta din GLB si anuleaza offsetul ei din fisier
## (variantele sunt exportate toate in origine, dar importul poate pastra
## pozitii). Restul nodurilor se elibereaza.
##
## `remove_child` INAINTE de `queue_free`, si asta a fost un bug de fond, nu o
## curatenie: eliberarea e AMANATA pana la sfarsitul cadrului, deci pana atunci
## toate cele 24 de variante sunt inca in container. Iar tot ce citeste modelul
## in acelasi cadru foloseste `_first_mesh`, care intoarce primul mesh gasit —
## adica mereu prima varianta din GLB, indiferent ce s-a cerut.
##
## Consecintele, amandoua vizibile in joc si masurate:
##   - `_add_collision` construia forma din primul mesh, deci TOATE sectiunile
##     de faleza aveau coliziunea variantei A. Adancimea raportata era 4.49 m
##     pentru fiecare, desi variantele au intre 5.0 si 7.2 m.
##   - `_half_depth` intorcea tot adancimea variantei A, deci asezarea folosea
##     un offset gresit: o sectiune mai adanca ajungea cu pana la 1.35 m mai
##     aproape de sosea decat s-a cerut, uneori PESTE asfalt.
## Impreuna, astea sunt exact "stanci care se intercaleaza cu drumul si prin
## care putem trece": peretele vazut si peretele simtit nu erau acelasi obiect.
##
## Acelasi tipar e documentat si in TrackDecor.pick_from_glb, unde a fost prins
## prima oara — aici scapase.
static func _extract(scene: PackedScene, node_name: String) -> Node3D:
	var container := scene.instantiate() as Node3D
	var kept: Node3D = null
	for child in container.get_children():
		if child.name == node_name:
			kept = child
		else:
			container.remove_child(child)
			child.queue_free()
	if kept == null:
		container.queue_free()
		return null
	container.position = -kept.position
	return container


## Poliedru convex per sectiune, construit din mesh-ul VIZUAL.
##
## Aici a stat pana acum o cutie construita din nodul `Cliff_X_col` din GLB, cu
## motivarea ca "urmareste doar fata dinspre drum, unde se produce de fapt
## contactul". Masurat (tools/probe_cliff_depth.gd), premisa era falsa: proxy-ul
## `_col` e centrat pe origine ca si vizualul, doar mai subtire. Nu urmarea fata
## dinspre drum, urmarea MIJLOCUL — deci fata lui statea cu 1.35-1.60 m in
## spatele peretelui pe care il vezi, pe toate cele zece variante:
##
##   varianta   fata vizuala   fata _col   diferenta
##   Cliff_H        3.58          2.00       1.58
##   Cliff_J        3.59          1.80       1.79
##   Cliff_I        3.05          1.45       1.60
##
## Adica masina intra un metru si jumatate in stanca inainte sa fie oprita, pe
## fiecare perete de canion din joc. Exact simptomul raportat: "stanci care se
## intercaleaza cu drumul si prin ele putem trece".
##
## Obiectia din nota veche ramane valida si e respectata: un TRIMESH din vizual
## ar fi ~180 de triunghiuri per sectiune si fiecare crapatura din silueta ar
## deveni un colt in care se agata masina. Dar un HULL CONVEX din acelasi mesh
## n-are niciuna dintre probleme — e o singura forma, cu cateva zeci de plane, si
## e convex prin definitie, deci nu are crapaturi. Umple crestaturile dintre
## trepte, ceea ce langa sol chiar e ce vrei: atingi treapta cea mai iesita si
## aluneci pe langa ea. Acelasi rationament ca la stancile de canion
## (TrackDecor.add_hull_collision).
static func _add_collision(body: StaticBody3D, node_name: String,
		scene: PackedScene, xform: Transform3D, mirror: bool = false) -> void:
	var source := _extract(scene, node_name)
	if source == null:
		return
	var mi := _first_mesh(source)
	if mi == null:
		source.queue_free()
		return
	var hull := mi.mesh.create_convex_shape()
	if mirror and hull != null:
		# Coliziunea URMEAZA oglindirea vizualului. Nota veche spunea ca n-o
		# urmeaza fiindca "e o cutie aproape simetrica, iar oglindirea ei poate
		# doar sa creeze pene intre sectiuni" — adevarat pentru cutia `_col`,
		# fals pentru un hull din silueta reala, care e vizibil asimetric.
		# Masurat: fara oglindire ramaneau sectiuni cu 0.40-0.57 m de perete in
		# afara colizorului, exact pe latura intoarsa.
		#
		# Se rastoarna PUNCTELE, nu transformarea nodului: o baza cu determinant
		# negativ pe o forma de coliziune e teren alunecos in orice motor.
		var pts := hull.points
		for i in pts.size():
			pts[i] = Vector3(-pts[i].x, pts[i].y, pts[i].z)
		hull.points = pts
	var shape := CollisionShape3D.new()
	shape.shape = hull
	# Acelasi transform ca nodul vizual — mai putin inclinarea de pe X/Z, care sta
	# pe copilul-model, nu aici.
	body.add_child(shape)
	shape.transform = xform
	source.queue_free()


## Jumatate din adancimea modelului, in metri. Modelele sunt exportate cu fata
## dinspre drum pe -Z (dupa conversia Y-up a lui Godot), centrate pe axa aia.
static func _half_depth(model: Node3D) -> float:
	var mi := _first_mesh(model)
	if mi == null or mi.mesh == null:
		return 3.0
	return mi.mesh.get_aabb().size.z * 0.5


static func _first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return node as MeshInstance3D
	for c in node.get_children():
		var found := _first_mesh(c)
		if found != null:
			return found
	return null
