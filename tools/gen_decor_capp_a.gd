extends Node
## Generator de decor MANUAL pentru POI A — PIATA DIN GOREME (Track13,
## frac 0.965-0.045, linia de start la 0.00). Ca la POI B: nu e sonda, e
## unealta care CALCULEAZA transformarile ce se lipesc in Track13.tscn sub
## `DecorManual/ZoneA_PiataGoreme`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorCappA.tscn -- --track=6
##
## Ce decide compozitia, si de ce cifrele sunt astea:
##
## 1. PIATA E LATA, PADUREA E STRAMTA. Masurat (ProbeCappA): half_width e 9.0 m
##    pe tot 0.965-0.040, adica 18 m de drum — cel mai lat loc din pista, si
##    exact asta o face piata. Terenul e plat la 49.3-49.6 m pe +/-24 m, deci
##    piesele stau pe cota lor fara sa se ingroape. Degajarile se masoara de la
##    MUCHIA asfaltului (9 m de ax), nu de la ax.
##
## 2. PRIMUL HORN E LA 6 M DE BANDA, cerinta explicita a briefului §2 A: ca
##    sa-i vezi PALARIA. Verificare cu frustumul (10 + 0.093*d): la 6 m de
##    muchie centrul conului e la 9 + 6 + 2.19 = 17.2 m de ax, deci camera vede
##    pana la 11.6 m — un chimney_a de 11.41 m intra INTREG in cadru. Un
##    chimney_c de 17.45 m la aceeasi distanta si-ar pierde varful, deci
##    conurile inalte stau mai DEPARTE, unde plafonul creste.
##
## 3. UMBRELE. Masurat din lumina scenei (nu dedus din euler — lectia POI B):
##    umbra merge pe XZ catre (0.866, 0.500), iar dot(side, umbra) e POZITIV pe
##    toata piata, deci partea insorita e `-side`. Piesele inalte care trebuie
##    sa taie piata cu umbra stau pe -side.
##
## 3b. PIATA INCEPE LA 0.993, NU LA 0.965 — si asta a fost o masuratoare, nu o
##    preferinta. Prima runda a intins decorul de la 0.965; generatorul a
##    raportat „teren cu 37,88 m sub sosea" pe TOATE piesele de dinainte de
##    0.99. Cauza: pana acolo drumul e inca IESIREA din stanca goala (POI G),
##    care traverseaza pe DEASUPRA hornului scobit — `TerrainHollow` tine
##    podeaua la 11 m, iar soseaua e la 48-49 m. Terenul de sub ea nu e platou,
##    e GOL. O casa asezata pe `ground_y` acolo ar fi stat pe podeaua cavernei,
##    la 37 m sub drum: invizibila din masina si absurda de sus.
##    Masurat pe iesirea din gol: la 0.9900 terenul e inca la 32.5 m pe -side,
##    la 0.9950 e 49.2 m pe toata latimea. Deci piata incepe la 0.993.
##
## 4. CARUTA CU OALE, si de ce fanta e de 4 m. Brief §2 A: decor static cu
##    coliziune, o fanta de 4 m pe langa ea. Caruta masoara 4.96 x 2.26 m, deci
##    lunga pe X local. Se aseaza cu X local PE LATERALA benzii (yaw = atan2 pe
##    side), adica de-a curmezisul drumului, ca sa blocheze pe latime — altfel
##    ar sta paralel cu banda si n-ar bloca nimic.
##
##    Aritmetica fantei, pe drumul de 18 m: blocajul incepe pe muchia din
##    stanga (-9.0) si se opreste la `half - 4.0` = +5.0, deci golul liber e
##    +5.0 .. +9.0 = exact 4 m, pe partea dinspre exteriorul curbei care
##    urmeaza. Decizia pentru jucator e „strange-te pe dreapta".
##
## 6. CE RAMANE DIFERIT FATA DE REFERINTA, si de ce nu se repara de aici.
##    Dupa runda de compozitie, comparat cot la cot cu `A_village.png`:
##
##    a) LATIMEA DRUMULUI. Referinta e o panglica ingusta prin sat; piata are
##       18 m si umple jumatatea de jos a fiecarui cadru, deci impinge tot
##       decorul spre orizont. Nu se schimba de aici: latimea E poanta POI-ului
##       (nota 1) si pe ea se sprijina aritmetica fantei de 4 m (nota 4). Daca
##       cineva decide vreodata ca satul bate piata, se schimba `half_width`,
##       si atunci se refac notele 1 si 4 — nu invers.
##
##    b) CONURILE NU SE SUBTIAZA CAT ALE LOR. Masurat (ProbeCappTaper), cea mai
##       conica piesa din kit are 0.48; referinta e pe la 0.2. Asta e in MESH,
##       nu in asezare, deci se repara la un re-export al kitului, nu aici.
##       Ce s-a putut face din generator s-a facut: umplutura a trecut pe
##       piesele cu conicitate mica, si ciuperca (1.11, mai lata sus decat jos)
##       a coborat de la 37 de bucati la 12.
##
## 5. CE NU TRAPEAZA O MASINA. Caruta si oalele au coliziune (`hull`), deci un
##    contact la viteza trebuie sa te RESPINGA, nu sa te agate. De aceea toate
##    piesele blocajului stau pe o SINGURA linie perpendiculara pe banda:
##    obstacolul e convex si continuu, iar masina care il atinge aluneca de-a
##    lungul lui spre fanta. Un U cu deschiderea spre drum ar fi fost un
##    buzunar din care nu iesi (lectia `coliziune-contact-si-platforma`).

const TRACK := "res://scenes/tracks/Track13.tscn"

## id-urile ext_resource asa cum trebuie sa apara in Track13.tscn.
const RES := {
	"buildings/cave_house_a": "18_house_a",
	"buildings/cave_house_b": "19_house_b",
	"buildings/cave_house_c": "30_house_c",
	"buildings/dovecote": "17_dovecote",
	"props/carpet_terrace": "31_carpet",
	"props/pottery_cart": "32_cart",
	"props/pot_stack": "33_pots",
	"plants/poplar_a": "34_poplar_a",
	"plants/poplar_b": "35_poplar_b",
	"plants/shrub_dry": "22_shrub",
	"plants/pigeon": "21_pigeon",
	"rocks/chimney_a": "10_ch_a",
	"rocks/chimney_b": "11_ch_b",
	"rocks/chimney_c": "12_ch_c",
	"rocks/chimney_d": "13_ch_d",
	"rocks/chimney_mushroom": "14_ch_mush",
	# Piesele de STRAT UMAN, cerute de comparatia cu referinta: satul sarea de
	# la tufe (0.9 m) direct la conuri de 12 m, adica exact peste inaltimea
	# ochiului soferului. Toate erau deja in kit, doar nu fusesera asezate.
	"buildings/farmhouse": "36_farmhouse",
	"structures/church_arch": "37_arch",
	"structures/cave_entrance": "38_cave_entr",
	"plants/vine_row": "39_vine",
	"props/torch": "40_torch",
	"rocks/cracked_chimney_b": "41_crack_b",
	"rocks/cracked_chimney_c": "42_crack_c",
	"rocks/chimney_triple": "43_ch_triple",
}

## Raza la baza, din AABB-ul masurat de ProbeCappA (jumatate din latura mare).
const BASE_R := {
	"buildings/cave_house_a": 3.15, "buildings/cave_house_b": 3.96,
	"buildings/cave_house_c": 4.04, "buildings/dovecote": 2.34,
	"props/carpet_terrace": 3.00, "props/pottery_cart": 2.48,
	"props/pot_stack": 0.74, "plants/poplar_a": 1.00,
	"plants/poplar_b": 1.24, "plants/shrub_dry": 0.52, "plants/pigeon": 0.24,
	"rocks/chimney_a": 2.19, "rocks/chimney_b": 2.03, "rocks/chimney_c": 2.70,
	"rocks/chimney_d": 2.43, "rocks/chimney_mushroom": 2.04,
	"buildings/farmhouse": 4.38, "structures/church_arch": 4.70,
	"structures/cave_entrance": 7.50, "plants/vine_row": 5.04,
	"props/torch": 0.42, "rocks/cracked_chimney_b": 10.45,
	"rocks/cracked_chimney_c": 4.95, "rocks/chimney_triple": 3.80,
}

## Inaltimea reala a fiecarei piese (masurata, ProbeCappA). E aici fiindca
## SCARA SE DERIVA DIN METRI, nu se alege din burta: `_scale_for` primeste
## inaltimea dorita si intoarce factorul. Lectia de pe POI B — acolo s-a cerut
## "moloz la scara 0.45-1.40" si a iesit un coridor de coloane de 16,84 m,
## fiindca exact atat are `cracked_chimney_a` in .glb.
const HEIGHT := {
	"buildings/cave_house_a": 10.95, "buildings/cave_house_b": 13.45,
	"buildings/cave_house_c": 12.15, "buildings/dovecote": 7.08,
	"buildings/farmhouse": 4.36, "structures/church_arch": 8.04,
	"structures/cave_entrance": 12.50, "plants/vine_row": 1.50,
	"props/torch": 2.22, "rocks/cracked_chimney_b": 6.54,
	"rocks/cracked_chimney_c": 0.98, "rocks/chimney_triple": 18.62,
	"rocks/chimney_a": 11.41, "rocks/chimney_b": 14.63, "rocks/chimney_c": 17.45,
	"rocks/chimney_d": 13.47, "rocks/chimney_mushroom": 12.32,
	"plants/poplar_a": 12.23, "plants/poplar_b": 15.23,
	"props/carpet_terrace": 0.99, "props/pottery_cart": 1.72,
	"props/pot_stack": 1.63, "plants/shrub_dry": 0.90, "plants/pigeon": 0.37,
}


## Scara care aduce piesa la `meters` inaltime. Se cere in METRI peste tot in
## generator; nicio scara nu se scrie de mana.
func _scale_for(model: String, meters: float) -> float:
	var h: float = HEIGHT.get(model, 1.0)
	return meters / h if h > 0.001 else 1.0


## Plafonul de cadru la `d` metri de ax: ce inaltime mai incape in frustumul
## lui ChaseCamera. Peste el, varful piesei iese din poza — acceptabil pentru
## fundal, gresit pentru o piesa care trebuie CITITA (o casa cu usa).
func _ceiling(d: float) -> float:
	return 10.0 + 0.093 * d

## Lungimea carutei pe X local (masurata, ProbeCappA).
const CART_LEN: float = 4.96
## Latimea unui teanc de oale pe X local (masurata).
const POT_W: float = 1.49

## Fractia unde sta caruta: dupa linia de start, la iesirea din piata, unde
## banda inca e lata (9.0 m) dar drumul deja s-a indreptat.
const CART_FRAC: float = 0.0300

## Cat gol trebuie sa ramana langa caruta, dupa brief §2 A.
const GAP_TARGET: float = 4.0

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
	_rng.seed = 100301
	_houses()
	_human_layer()
	_terrace_and_life()
	_chimneys()
	_rubble()
	_cart()
	print("")
	for line in _out:
		print(line)
	print("; asezate %d piese, %d avertismente de degajare" % [_n, _warn])
	get_tree().quit(0)


# ------------------------------------------------------------------ compozitia

## SATUL, si de ce compozitia s-a rescris dupa comparatia cu referinta.
##
## Prima runda a asezat 71 de hornuri si 8 case, si a iesit o padure de piatra
## cu satul ascuns in spate. Comparatia cu `img/v3_crops/A_village.png` a
## aratat ca diagnosticul "prea multe hornuri" era doar jumatate adevarat, si
## ca partea cealalta conta mai mult:
##
## 1. IN REFERINTA, CONUL *E* CASA. Conurile mari au usi, ferestre si arcade
##    sapate in ele — nu sunt decor intre case, sunt locuintele. Ale noastre
##    erau conuri OARBE, deci oricat de multe, nu citeau ca sat. De aceea
##    conurile de langa drum se amesteca acum cu `cave_house_*` (aceleasi
##    conuri, dar cu fatada sapata) in loc sa stea pe randuri separate.
##
## 2. IERARHIE DE MARIME, nu un singur calibru. Referinta are cateva conuri
##    EROU cat o casa, si sub ele un covor DES de conuri MICI, de 2-5 m, care
##    umple primul plan. Ale noastre erau toate 11-17 m: masurat, `chimney_a`
##    are 11,41 m, adica mai inalt decat `cave_house_a` (10,95 m). Cu totul la
##    acelasi calibru nu exista nici prim-plan, nici fundal, doar un gard.
##    Acum conurile mici se cer IN METRI (2,5-5 m) prin `_scale_for`.
##
## 3. STRATUL UMAN LIPSEA CU DESAVARSIRE. Intre tufa de 0,9 m si conul de 12 m
##    nu era nimic — exact la inaltimea ochiului. Kitul avea deja piesele si
##    nu fusesera folosite niciodata: `farmhouse` (4,36 m), `church_arch`
##    (8,04 m), `cave_entrance` (12,50 m dar LATA de 15 m, deci se citeste ca
##    poarta, nu ca turn), `vine_row` (1,50 m), `torch` (2,22 m).
##
## 4. DENSITATEA E INVERSA. In referinta primul plan e plin si fundalul se
##    rareste in ceata. La noi fundalul avea doua conuri pe pas si primul plan
##    era gol pe lungimi intregi.
func _houses() -> void:
	# CASELE VIN LA DRUM. Masurat pe versiunea anterioara: cea mai apropiata
	# statea la 15,2 m de ax, adica dincolo de linia de hornuri, si in captura
	# de la 0,00 nu se vedea niciuna intreaga. Fereastra utila e 1,5-3,5 m de
	# MUCHIE (10,5-13 m de ax), unde plafonul de cadru e 11,0-11,2 m: o casa de
	# 10,95 m intra intreaga, una de 13,45 isi pierde varful — corect, la o
	# casa de langa drum vrei usa si balconul, nu acoperisul.
	#
	# Ce ramane in picioare din runda trecuta: pe ultimele doua sutimi
	# dinaintea liniei NU se pune nimic sub 3 m de muchie, fiindca acolo sta
	# camera la pornire (zboara 12,5 m in spatele masinii). Aia n-a fost o
	# preferinta, a fost o captura cu o fatada maro peste jumatate de cadru.
	_place("buildings/cave_house_b", "casaCon", 0.9945, -1.0, 3.2,
		0.0, 1.0, "hull", "toward")
	_place("buildings/cave_house_a", "casaCon", 0.0075, -1.0, 1.8,
		0.0, 1.0, "hull", "toward")
	_place("buildings/cave_house_c", "casaCon", 0.0042, 1.0, 2.2,
		0.0, 1.0, "hull", "toward")
	_place("buildings/cave_house_a", "casaCon", 0.0195, 1.0, 2.0,
		0.0, 0.95, "hull", "toward")
	_place("buildings/cave_house_c", "casaCon", 0.0142, -1.0, 2.4,
		0.0, 0.9, "hull", "toward")
	_place("buildings/cave_house_b", "casaCon", 0.0265, -1.0, 2.6,
		0.0, 0.92, "hull", "toward")
	# Al doilea rand: satul urca in trepte in spate, ca in referinta. Mai rar
	# si mai inalt, ca sa se vada PESTE primul rand, nu prin golurile lui.
	_place("buildings/cave_house_a", "casaSpate", 0.0225, -1.0, 11.0,
		0.5, 1.05, "hull", "toward")
	_place("buildings/cave_house_c", "casaSpate", 0.0165, -1.0, 13.0,
		-0.4, 0.95, "hull", "toward")
	_place("buildings/cave_house_b", "casaSpate", 0.0105, 1.0, 12.0,
		0.3, 0.95, "hull", "toward")
	_place("buildings/cave_house_a", "casaSpate", 0.9975, 1.0, 10.0,
		0.2, 1.0, "hull", "toward")


## STRATUL UMAN: 1,5-8 m inaltime, lipit de banda, cu fatade care se citesc.
##
## Astea sunt piesele care lipseau. Se aseaza APROAPE (1,1-3,5 m de muchie)
## fiindca la inaltimea lor, de la 8 m incolo nu mai citesc nimic — o ferma de
## 4,36 m la 20 m de ax e un cub in fundal, iar rostul ei e sa aiba usa la
## nivelul ochiului cand treci pe langa ea.
func _human_layer() -> void:
	# Ferma joasa: acoperis plat, 4,36 m — exact silueta ORIZONTALA care rupe
	# sirul de verticale. Doua pe partea insorita, ca soarele razant sa-i sape
	# fatada, una pe cealalta.
	_place("buildings/farmhouse", "ferma", 0.0022, -1.0, 1.5, 0.0, 1.0,
		"hull", "toward")
	_place("buildings/farmhouse", "ferma", 0.0128, 1.0, 1.4, 0.0, 1.0,
		"hull", "toward")
	_place("buildings/farmhouse", "ferma", 0.0238, -1.0, 1.6, 0.0, 0.95,
		"hull", "toward")
	# Arcada: semnatura vizuala a referintei (arcade sapate in tuf, la drum).
	# 8,04 m la 1,5 m de muchie -> plafonul e 11,0 m, deci intra intreaga.
	_place("structures/church_arch", "arcada", 0.9962, -1.0, 1.5, 0.0, 1.0,
		"hull", "toward")
	_place("structures/church_arch", "arcada", 0.0172, 1.0, 1.3, 0.0, 0.95,
		"hull", "toward")
	# Intrarea in stanca: LATA de 15 m, deci e un perete cu gura, nu un turn.
	# Se pune ca fundal de piata pe partea umbrita, la 5 m — inchide compozitia
	# in loc s-o lase sa curga in desert.
	_place("structures/cave_entrance", "gura", 0.0058, 1.0, 5.0, 0.0, 1.0,
		"hull", "toward")
	# Randul de vita: 10 m lungime, 1,50 m inaltime — culcat pe langa banda, e
	# singurul element ORIZONTAL de la nivelul solului si leaga piesele intre
	# ele. Yaw pe directia benzii, nu de-a curmezisul.
	for j in 4:
		var f := 0.0035 + 0.0062 * float(j)
		var sgn := 1.0 if j % 2 == 0 else -1.0
		_place("plants/vine_row", "vita", f, sgn, 2.2 + 0.8 * float(j % 2),
			0.0, 1.0, "none", "along")
	# Torte pe marginea piatei: 2,22 m, adica fix la inaltimea ochiului.
	# Punctatie verticala marunta — in referinta rolul asta il fac stalpii si
	# semnele. Fara coliziune: n-au ce cauta in traiectorie.
	for j in 7:
		var f := 0.9968 + 0.0043 * float(j)
		if f > 1.0:
			f -= 1.0
		_place("props/torch", "torta", f, -1.0 if j % 2 == 0 else 1.0,
			1.1, 0.0, 1.0, "none")


## Terasa cu covoare, porumbarul, plopii si viata marunta.
func _terrace_and_life() -> void:
	_place("props/carpet_terrace", "terasaCovoare", 0.0030, 1.0, 1.5,
		0.0, 1.0, "hull", "toward")
	_place("buildings/dovecote", "porumbar", 0.0118, 1.0, 2.2,
		0.0, 1.0, "hull", "toward")
	for j in 6:
		_place("plants/pigeon", "porumbel", 0.0118 + 0.0012 * float(j),
			1.0, 2.0 + 1.6 * float(j % 3), float(j) * 1.1 + 0.3, 1.0,
			"none", "", 7.4 + 1.2 * float(j % 4))
	_place("plants/poplar_b", "plop", 0.0072, 1.0, 1.5, 0.0, 1.0, "trunk")
	_place("plants/poplar_a", "plopSpate", 0.0098, 1.0, 6.0, 0.0, 0.95, "trunk")
	_place("plants/poplar_a", "plopSpate", 0.0165, 1.0, 7.0, 0.0, 1.05, "trunk")
	# Tufe la piciorul pieselor: rup linia de contact dintre piatra si pamant,
	# care altfel e o taietura curata si citeste ca decupaj (lectia POI B).
	for j in 22:
		var f := 0.9930 + 0.0024 * float(j)
		if f > 1.0:
			f -= 1.0
		var sgn := -1.0 if j % 2 == 0 else 1.0
		_place("plants/shrub_dry", "tufa", f, sgn,
			_rng.randf_range(0.5, 3.5), _rng.randf_range(0.0, TAU),
			_rng.randf_range(0.9, 1.5), "none")


## CONURILE, pe trei calibre — asta e schimbarea de fond fata de runda trecuta.
##
## Numarul scade de la 71 la ~46, dar cifra conteaza mai putin decat REPARTITIA
## pe inaltimi. Toate scarile se cer in METRI si trec prin `_scale_for`.
##
##   - covorul de prim-plan (2,5-5 m, la 1,5-7 m de muchie): DES, pe fiecare
##     pas, pe ambele parti. Astea sunt ce trece pe langa geam si ce da
##     senzatia de vale plina. In referinta primul plan e numai din astea.
##   - conurile de mijloc (7-11 m, la 9-20 m): rare, doar la doi pasi.
##   - conurile EROU (14-19 m, la 22-40 m): patru, nu patruzeci. Sunt reperele
##     care se vad de departe; daca sunt multe, nu mai e niciunul.
func _chimneys() -> void:
	# Hornul de la 6 m ramane cerinta explicita a briefului §2 A: chimney_a la
	# 6 m de banda, la scara 1, ca sa i se vada palaria intreaga (plafonul e
	# 11,6 m acolo, iar piesa are 11,41 m).
	_place("rocks/chimney_a", "hornulDeSase", 0.0060, -1.0, 6.0,
		0.6, 1.0, "hull")
	# CE PIESA, si de ce nu la intamplare. Masurat cu ProbeCappTaper
	# (conicitate = raza la 85% din inaltime / raza la 10%):
	#   chimney_c 0.48, chimney_d 0.48, chimney_b 0.54, chimney_a 0.58,
	#   chimney_triple 0.82, chimney_mushroom 1.11.
	# Referinta v3 are conuri care se subtiaza continuu spre varf; sub 0.6 asta
	# se citeste, peste 0.8 arata a stalp. `chimney_mushroom` e mai LAT sus
	# decat jos si are palarie de 17% — o lampa, nu un con — si era a doua
	# piesa ca frecventa in piata (37 din 120). De aici veneau "ciupercile"
	# din captura, nu din numarul de hornuri.
	#
	# Ramane in kit, dar ca EXCEPTIE, nu ca umplutura: cateva bucati adevarate
	# de ciuperca exista si in Cappadocia reala, si turtit face bolovani buni
	# (vezi `_rubble`). Umplutura trece pe conurile care chiar se subtiaza.
	var small: Array[String] = [
		"rocks/chimney_a", "rocks/chimney_d", "rocks/chimney_c",
		"rocks/chimney_b", "rocks/chimney_a", "rocks/chimney_d",
	]
	var mid: Array[String] = [
		"rocks/chimney_d", "rocks/chimney_b", "rocks/chimney_c",
		"rocks/chimney_a",
	]
	var hero: Array[String] = [
		"rocks/chimney_c", "rocks/chimney_triple", "rocks/chimney_b",
		"rocks/chimney_c",
	]
	var k := 0
	# Piata incepe la 0.9930, nu mai devreme: pana acolo drumul e inca iesirea
	# din stanca goala si trece PE DEASUPRA hornului scobit, deci terenul de
	# dedesubt e podeaua cavernei (masurat: 11,44 m sub sosea la 0.9915).
	# Nota 3b din antet, pe care prima varianta a acestei bucle o incalca.
	var f := 0.9930
	while f < 1.0465:
		var fw := f if f < 1.0 else f - 1.0
		# Fereastra libera din jurul carutei era de +/-0.0055 (~22 m), si asta
		# a golit exact CE SE VEDE INAINTE de la frac 0.02: camera priveste in
		# fata, iar blocajul e la 0.03 (lectia `masoara-inainte-nu-langa`).
		# Se strange la +/-0.0022 (~9 m), cat sa se citeasca blocajul si fanta,
		# fara sa se rupa satul pe toata deschiderea din fata soferului.
		var near_cart := absf(fw - CART_FRAC) < 0.0022
		# Culoarul camerei: ea zboara 12,5 m IN SPATELE masinii, deci la
		# pornire sta pe frac ~0.994. Covorul de prim-plan se opreste acolo,
		# altfel prima imagine a cursei e o piatra peste jumatate de cadru.
		var on_line := fw > 0.9930 or fw < 0.0025
		f += 0.0019
		k += 1
		# COVORUL DE PRIM-PLAN. Doua pe pas (cate unul pe fiecare parte), la
		# 2,5-5 m inaltime: la calibrul asta pot sta la 1,5 m de muchie fara
		# sa astupe cadrul, fiindca plafonul la 11 m de ax e 11,0 m si ele au
		# sub 5. Aici se castiga senzatia de "vale plina de conuri".
		if not (near_cart or on_line):
			# DOUA RANDURI, si primul e LIPIT DE UMAR. Cu un singur rand la
			# 1,5-7 m de muchie treimea de jos a cadrului ramanea nisip gol —
			# comparat cot la cot cu referinta, care are conuri si bolovani
			# pana in marginea drumului. Piata are 18 m latime, deci soseaua
			# singura umple jumatate de ecran: orice sta la 5 m de muchie e
			# deja la 14 m de ax si cade sub linia orizontului.
			#
			# Randul de umar sta la 0,6-2,0 m (garda cere marginea piesei la
			# minimum 0,5 m de asfalt, si `gap` se masoara chiar de la muchie)
			# si e MARUNT: 1,8-3,2 m, cat sa umple coltul de jos fara sa urce
			# peste capota.
			for sgn in [-1.0, 1.0]:
				var mdl: String = small[(k + int(sgn)) % small.size()]
				_place(mdl, "conUmar", fw, sgn,
					_rng.randf_range(0.6, 2.0), _rng.randf_range(0.0, TAU),
					_scale_for(mdl, _rng.randf_range(1.8, 3.2)), "hull")
				# O ciuperca adevarata la fiecare al saptelea pas: exista si in
				# Cappadocia reala, dar ca accent, nu ca padure.
				var m2: String = ("rocks/chimney_mushroom" if k % 7 == 3
					else small[(k * 2 + int(sgn) + 3) % small.size()])
				_place(m2, "conMic", fw, sgn,
					_rng.randf_range(2.5, 7.0), _rng.randf_range(0.0, TAU),
					_scale_for(m2, _rng.randf_range(3.0, 5.5)), "hull")
		# Conurile de mijloc: rare, si la o distanta unde inca au volum.
		if k % 2 == 0:
			var mm: String = mid[(k / 2) % mid.size()]
			_place(mm, "conMijloc", fw, 1.0 if k % 4 == 0 else -1.0,
				9.0 + _rng.randf_range(0.0, 11.0), _rng.randf_range(0.0, TAU),
				_scale_for(mm, _rng.randf_range(7.0, 11.0)), "hull")
		# Conurile EROU: unul la cinci pasi, alternand malul. Patru in toata
		# piata. Sunt singurele lasate sa treaca de 14 m.
		if k % 5 == 2:
			var hm: String = hero[(k / 5) % hero.size()]
			_place(hm, "conErou", fw, -1.0 if (k / 5) % 2 == 0 else 1.0,
				22.0 + _rng.randf_range(0.0, 18.0), _rng.randf_range(0.0, TAU),
				_scale_for(hm, _rng.randf_range(14.0, 19.0)), "hull")


## MOLOZUL DE PRIM-PLAN: bolovani lati si josi, cum e tot solul in referinta.
##
## `cracked_chimney_b` are 6,54 x 20,90 m — un pinten lat, si el ridica malurile
## palide de pe umeri. Se cere IN METRI (3,6-4,5 m), altfel ies coloanele de pe
## POI B.
##
## DE CE NU MAI E `cracked_chimney_c` AICI, desi e lespedea evidenta (0,98 x
## 9,90 m). Masurat A/B in acelasi worktree, cu si fara cele noua bucati, la
## frac 0.02: diferenta pe ecran e 1,33% din pixeli, pentru 25 976 de
## triunghiuri — 13% din toata geometria pistei, a treia sursa ca marime din
## raportul pe surse. Piesa costa 2528 tri fiindca e un mesh de horn crapat
## intreg; turtita la un metru, nu se vede din ea decat conturul.
##
## Efectul se pastreaza, costul nu: acelasi contur de bolovan iese dintr-un
## `chimney_mushroom` (478 tri) turtit, care oricum e deja in scena si nu aduce
## nici material, nici mesh nou. Lectia POI B nu e "nu folosi molozul", e
## "cere metri si uita-te la ce platesti pentru ei".
func _rubble() -> void:
	# Bolovanii de umar: hornuri TURTITE, nu lespezi scumpe. `_place` ia o
	# singura scara, deci turtirea vine din inaltimea ceruta — un
	# chimney_mushroom de 12,32 m adus la 1,1-1,9 m e un bolovan lat, exact
	# silueta din referinta, la 478 tri in loc de 2528.
	for j in 11:
		var f := 0.9955 + 0.0036 * float(j)
		if f > 1.0:
			f -= 1.0
		var sgn := -1.0 if j % 2 == 0 else 1.0
		var mdl := "rocks/chimney_mushroom" if j % 2 == 0 else "rocks/chimney_a"
		_place(mdl, "bolovan", f, sgn,
			_rng.randf_range(0.6, 4.0), _rng.randf_range(0.0, TAU),
			_scale_for(mdl, _rng.randf_range(1.1, 1.9)), "none")
	# Doi pinteni lati, ca maluri ale piatei — dau fundalului o talpa, ca sa nu
	# para ca toate conurile cresc din nisip gol.
	_place("rocks/cracked_chimney_b", "pinten", 0.0088, -1.0, 16.0,
		0.7, _scale_for("rocks/cracked_chimney_b", 4.5), "hull")
	_place("rocks/cracked_chimney_b", "pinten", 0.0288, 1.0, 14.0,
		2.1, _scale_for("rocks/cracked_chimney_b", 3.6), "hull")


## CARUTA CU OALE la iesirea din piata, cu fanta de 4 m.
##
## Blocajul se construieste ca o linie CONTINUA perpendiculara pe banda, de la
## muchia din stanga (-half) pana la `half - GAP_TARGET`: caruta intai, apoi
## teancuri de oale cap la cap pana se umple lungimea. Golul ramas e exact
## GAP_TARGET, pe partea dreapta.
func _cart() -> void:
	var n := _track.baked.size()
	var i := int(CART_FRAC * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i)
	var half := _track.width_at_index(i)
	var g := _sampler.ground_y(p.x, p.z)
	# Caruta e lunga pe X local, deci X local trebuie sa fie LATERALA benzii.
	var yaw := atan2(s.x, s.z)
	var left := -half
	var right := half - GAP_TARGET
	print("; caruta la frac %.4f: ax=(%.2f, %.2f) sosea_y=%.2f teren_y=%.2f half_w=%.2f" % [
		CART_FRAC, p.x, p.z, p.y, g, half])
	print(";   blocaj de la %+.2f la %+.2f m fata de ax, fanta %.2f m in dreapta" % [
		left, right, half - right])
	_at(i, left + 0.5 * CART_LEN, "props/pottery_cart", "carutaCuOale", yaw, 1.0, 0.0)
	# Teancurile de oale continua linia pana la `right`, fara sa lase gauri.
	var x := left + CART_LEN
	var j := 0
	while x < right - 0.2:
		var c := x + 0.5 * POT_W
		# Se decaleaza pe LUNGUL benzii alternativ, ca sa nu fie un sir de
		# robot. Decalajul e mic (0.5 m) si de ambele parti, deci blocajul
		# ramane convex — nu se formeaza niciun buzunar.
		var along := 0.5 if j % 2 == 0 else -0.4
		_at(i, c, "props/pot_stack", "teancOale", yaw + 0.35 * float(j % 3), 1.0, along)
		x += POT_W
		j += 1
	print(";   %d teancuri de oale langa caruta, blocaj continuu pe %.2f m" % [
		j, right - left])


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
		print("; ATENTIE %s la frac %.4f: marginea la %.2f m de ax, banda %.2f" % [
			model, frac, d - r, half])
	if lift == 0.0 and p.y - g > 1.2:
		print("; nota %s la frac %.4f: teren cu %.2f m sub sosea" % [model, frac, p.y - g])
	var a := yaw
	if face == "toward":
		a = atan2(-s.x, -s.z)
	elif face == "along":
		# Piesa se aseaza PE LUNGUL benzii (randul de vita), nu cu fata la ea.
		var dir := (_track.baked[(i + 1) % n] - p).normalized()
		a = atan2(dir.x, dir.z)
	_raw(model, base, Vector3(q.x, g + lift, q.z), a, scl, mode, false)


## Aseaza o piesa la un OFFSET LATERAL dat fata de ax (pentru blocajul carutei,
## unde pozitia se calculeaza pe latimea benzii, nu ca degajare fata de muchie).
func _at(idx: int, lateral: float, model: String, base: String, yaw: float,
		scl: float, along: float) -> void:
	var n := _track.baked.size()
	var p := _track.baked[idx]
	var s := _track._side_at(idx)
	var dir := (_track.baked[(idx + 1) % n] - p).normalized()
	var q := p + s * lateral + dir * along
	var g := _sampler.ground_y(q.x, q.z)
	_raw(model, base, Vector3(q.x, g, q.z), yaw, scl, "hull", false)


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String, blocker: bool) -> void:
	_n += 1
	var c := cos(yaw) * scl
	var s := sin(yaw) * scl
	_out.append('[node name="%s%d" parent="DecorManual/ZoneA_PiataGoreme" instance=ExtResource("%s")]'
		% [base, _n, RES[model]])
	_out.append("transform = Transform3D(%f, 0, %f, 0, %f, 0, %f, 0, %f, %f, %f, %f)"
		% [c, -s, scl, s, c, pos.x, pos.y, pos.z])
	if mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	if blocker:
		_out.append("metadata/camera_blocker = true")
	_out.append("")
