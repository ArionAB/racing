extends Node
## Generator de decor MANUAL pentru POI B - DRUMUL INCAS (Track15,
## Machu Picchu, frac 0.04-0.20). Nu e sonda: calculeaza transformarile care
## se lipesc in Track15.tscn sub `DecorManual/ZoneB_DrumulIncas`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMpB.tscn -- \
##       --out=C:/cale/zoneB.part [--survey]
##
## Cu `--survey` scrie doar profilul terenului masurat si nu genereaza nimic.
##
## CE SE VEDE IN BARA (bara_poi_B.png, deschisa inainte de asezare):
## drum de pamant tan taiat intr-o CREASTA DE STANCA - fete cenusii plane,
## fatetate, care cad de AMANDOUA partile imediat de langa asfalt; pe fete
## stau smocuri de copaci verde-inchis, agatati; o gura de tunel cu arc de
## piatra si un parapet de blocuri deasupra; trepte de piatra langa portal;
## nori albi in vale dedesubt. Materia dominanta e PIATRA, nu iarba: drumul e
## o panglica pe o coama de roca, nu o poteca pe pajiste.
##
## CIFRELE DE SURVEY (runda 1, B_r1_survey.txt) - compozitia se decide pe ele:
##
## 1. DREAPTA E O PRAPASTIE ADEVARATA, de la frac 0.080 in sus. Cotele fata de
##    drum la +2 / +4 / +8 m lateral de MUCHIE:
##      0.075   -0.9   -1.5   -2.9     (buza incepe)
##      0.080   -5.2   -6.8  -13.6
##      0.085  -15.1  -21.4  -34.4
##      0.100  -26.1  -40.3  -59.3
##      0.140  -40.2  -55.8  -65.6
##      0.190  -38.7  -51.9  -64.1
##    Unghiul sub orizontala din OCHIUL CAMEREI (10 m peste drum), la 4/8/15 m:
##      0.040    3.7    1.7    0.7   <- inca platou, nu e inca POI-ul
##      0.080   59.7   59.6   47.6
##      0.100   84.3   82.3   75.9
##      0.190   85.6   82.9   78.8
##    Deci FORMA EXISTA si e verticala. Nu se cere teren. Capcana 3 din brief
##    ("peretii verticali apar la 28-35 grade, limita de rezolutie a grilei")
##    NU se aplica aici: unghiul real e 59-86 grade, cu mult peste
##    `scarp_slope_deg` 28, deci tenta de stanca se aplica si SE VEDE (verificat
##    pe captura B_r0_gol_f0.08.png: fata cenusie e acolo).
##
## 2. STANGA E PLATOU pe aproape tot intervalul (-0,3 m pana la 40 m lateral).
##    Doua exceptii masurate: flancul muntelui urca la 0.110-0.145 (+1,7 m la
##    -15 m pe 0.115; +12,2 m la -15 m si +51,5 m la -40 m pe 0.130), si un gol
##    pe DEPARTE la 0.120-0.140 (-6,1 m la -8 m, -26,2 m la -15 m pe 0.120).
##
## 3. CE LIPSESTE, MASURAT PE PIXELI - si e opusul a ce cerea brief-ul.
##    Clasificare HSV (roca = satur < 0,14 si valoare 0,25-0,75; iarba = nuanta
##    0,15-0,35 cu satur > 0,15; drum = satur > 0,08 si valoare > 0,70):
##
##      sursa            roca    iarba   drum
##      BARA            17,8 %   10,6 %  58,5 %
##      noi la 0.08      3,6 %   42,6 %  42,9 %
##      noi la 0.18      0,1 %   24,0 %  67,9 %
##
##    Bara are de 5-170 de ori mai multa PIATRA si un sfert din iarba. Deci
##    deficitul e de ROCA, nu de vegetatie - invers fata de lista de piese din
##    contract, care incepe cu bromelii si ferigi.
##    Confirmat pe captura, nu doar pe cifra (regula zero din bara_vizuala):
##    la 0.18 nu se vede NICIO piatra in cadru, drumul pal ocupa doua treimi,
##    iar dincolo de banda maro de muchie e fasie verde si ceata.
##
## 4. DE CE NU SE VEDE PRAPASTIA DE LA 0.18, desi masoara -38 m la +2 m.
##    Drumul e in viraj si bombat: propria lui muchie (banda maro) o ascunde.
##    Din masina, la 0.18, ochiul nu ajunge peste buza. Reparatia care e A MEA
##    e sa pun PIATRA VIZIBILA pe buza, care iese deasupra liniei muchiei si
##    rupe silueta - nu sa cobor un prag de panta si nu sa ating terenul.
##    CU CE anume, vezi nota de la `_buza_de_stanca`: runda 1 a incercat cu
##    `moss_boulder_*` marit si a esuat masurat.
##
## 5. NU EXISTA PIESA DE TUNEL in kit (39 GLB-uri verificate: nicio gura de
##    tunel, niciun arc). Contractul cere "gura de tunel cu arc de piatra".
##    Nu o fabric din `inca_wall_*` - un arc din trei lespezi nu citeste a
##    tunel, citeste a poarta prabusita, si POI C are deja poarta. Se
##    raporteaza ca lipsa de kit, nu se mascheaza.

const TRACK := "res://scenes/tracks/Track15.tscn"
const ZONE := "DecorManual/ZoneB_DrumulIncas"

const F_IN := 0.040
const F_OUT := 0.210

const RES := {
	"moss_boulder_a": "s_moss_boulder_a",
	"moss_boulder_b": "s_moss_boulder_b",
	"moss_boulder_c": "s_moss_boulder_c",
	"bromeliad": "s_bromeliad",
	"tree_fern": "s_tree_fern",
	"orchid_cluster": "s_orchid_cluster",
	"inca_stair_a": "s_inca_stair_a",
	"inca_stair_b": "s_inca_stair_b",
	"trail_marker": "s_trail_marker",
	"inca_wall_a": "s_inca_wall_a",
	"inca_wall_b": "s_inca_wall_b",
	"inca_wall_c": "s_inca_wall_c",
	"polylepis_a": "s_polylepis_a",
	"polylepis_b": "s_polylepis_b",
}

## Inaltimea AABB masurata (docs/asset_briefs/machu_picchu_masuratori.md §1).
const HEIGHT := {
	"moss_boulder_a": 0.741, "moss_boulder_b": 1.957, "moss_boulder_c": 3.069,
	"bromeliad": 0.377, "tree_fern": 3.306, "orchid_cluster": 0.390,
	"inca_stair_a": 2.500, "inca_stair_b": 5.000,
	"trail_marker": 1.200,
	"inca_wall_a": 2.487, "inca_wall_b": 2.487, "inca_wall_c": 2.432,
	"polylepis_a": 4.190, "polylepis_b": 6.798,
}
## Raza de degajare la baza (m) - coloana "raza baza" din inventar.
const BASE_R := {
	"moss_boulder_a": 0.37, "moss_boulder_b": 0.94, "moss_boulder_c": 1.73,
	"bromeliad": 0.46, "tree_fern": 0.30, "orchid_cluster": 0.17,
	"inca_stair_a": 3.16, "inca_stair_b": 6.08,
	"trail_marker": 0.29,
	"inca_wall_a": 2.03, "inca_wall_b": 3.02, "inca_wall_c": 1.06,
	"polylepis_a": 0.61, "polylepis_b": 1.10,
}
## SEMI-GROSIMEA laterala (m) pentru testul de banda: amprenta reala, nu raza
## pe diagonala (lectia POI D).
const SIDE_R := {
	"inca_wall_a": 0.42, "inca_wall_b": 0.43, "inca_wall_c": 0.43,
	"inca_stair_a": 1.30, "inca_stair_b": 1.30,
}
const TRI := {
	"moss_boulder_a": 200, "moss_boulder_b": 242, "moss_boulder_c": 238,
	"bromeliad": 248, "tree_fern": 768, "orchid_cluster": 410,
	"inca_stair_a": 422, "inca_stair_b": 798,
	"trail_marker": 76,
	"inca_wall_a": 208, "inca_wall_b": 296, "inca_wall_c": 152,
	"polylepis_a": 598, "polylepis_b": 1098,
}

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _n := 0
var _warn := 0
var _lane_reject := 0
var _tri := 0
var _rng := RandomNumberGenerator.new()
var _out_path := ""
var _survey_only := false
var _total_len := 1.0
var _shadow := Vector3.ZERO


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a == "--survey":
			_survey_only = true
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_sampler = _track._sampler
	var nd: int = _track.baked.size()
	if _track._dists.size() > nd:
		_total_len = float(_track._dists[nd])
	print("; lungime traseu %.1f m, %d puncte, %.3f m intre puncte" % [
		_total_len, nd, _total_len / float(nd)])
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 140.0
	_rng.seed = 40205
	_survey()
	if not _survey_only:
		_build()
		_write()
	get_tree().quit(0)


func _find_sun(node: Node) -> DirectionalLight3D:
	if node is DirectionalLight3D:
		return node as DirectionalLight3D
	for c in node.get_children():
		var r := _find_sun(c)
		if r != null:
			return r
	return null


## Profilul real al terenului pe intervalul meu. Cifrele din antet vin de aici.
func _survey() -> void:
	var sun := _find_sun(_track)
	if sun != null:
		var dir: Vector3 = -sun.global_transform.basis.z
		_shadow = Vector3(dir.x, 0.0, dir.z).normalized()
		print("; soare: rot %s, lumina spre (%.2f,%.2f,%.2f), umbra XZ (%.3f,%.3f), elev %.1f deg" % [
			str(sun.rotation_degrees), dir.x, dir.y, dir.z,
			_shadow.x, _shadow.z, rad_to_deg(asin(-dir.y))])
	var n := _track.baked.size()
	print("; --- PROFIL LATERAL (cote fata de drum) ---")
	print("; frac      ax(x,z)          y_drum  half   sol la -40 -25 -15 -8 -4 -2 | +2 +4 +8 +15 +25 +40")
	var f := F_IN - 0.005
	while f <= F_OUT + 0.006:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var cols: Array[String] = []
		for off: float in [-40.0, -25.0, -15.0, -8.0, -4.0, -2.0,
				2.0, 4.0, 8.0, 15.0, 25.0, 40.0]:
			var q := p + s * (half + absf(off)) * signf(off)
			cols.append("%+6.1f" % (_sol_real(q.x, q.z) - p.y))
		print("; %.3f  (%7.1f,%7.1f)  %6.1f  %4.1f  %s" % [
			f, p.x, p.z, p.y, half, " ".join(cols)])
		f += 0.005
	print("; --- UNGHIUL DIN OCHIUL CAMEREI (ochi la 10 m peste drum) ---")
	print("; frac   |  dr: unghi_sub_orizontala la 4/8/15 m  |  st: idem")
	f = F_IN
	while f <= F_OUT + 0.001:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var line := "; %.3f " % f
		for sgn: float in [1.0, -1.0]:
			line += " |"
			for off: float in [4.0, 8.0, 15.0]:
				var q := p + s * sgn * (half + off)
				var dy := _sol_real(q.x, q.z) - p.y
				line += " %5.1f" % rad_to_deg(atan2(-dy, off))
		print(line)
		f += 0.01
	print("; --- PANTA LONGITUDINALA (coama de la 0.186) ---")
	f = 0.16
	while f <= 0.215:
		var i := int(f * float(n)) % n
		var j := int((f + 0.004) * float(n)) % n
		var p := _track.baked[i]
		var q := _track.baked[j]
		var d := Vector2(q.x - p.x, q.z - p.z).length()
		print("; %.3f  y %7.2f  panta %+6.2f %%" % [
			f, p.y, 100.0 * (q.y - p.y) / maxf(d, 0.01)])
		f += 0.004


func _step(meters: float) -> float:
	return meters / _total_len


## Unde incepe caderea reala pe dreapta (nota 1): inainte de asta e platou si
## un pinten de stanca acolo ar fi o piatra pusa pe pajiste.
const F_BUZA := 0.078
## Flancul care urca pe stanga (nota 2).
##
## RUNDA 7: cele doua cifre de mai jos erau fereastra in care TERENUL natural
## urca pe stanga (platou in rest). Nu mai e criteriul potrivit: peretele taiat
## e acum teren construit pe TOT intervalul (nodurile CliffFace, cu talpa la
## 0,2 m de marginea locala), deci exista fata de piatra de la 0.042 la 0.209.
## Vegetatia agatata se muta pe toata lungimea lui, altfel ramane un pluton de
## ferigi pe 4,7 % din zona si perete gol in rest.
const F_FLANC_IN := 0.105
const F_FLANC_OUT := 0.152
## Intervalul pe care exista fata de piatra construita (nodurile CliffFace din
## Track15.tscn). Vegetatia se agata de ea, nu de iarba.
const F_PERETE_IN := 0.046
const F_PERETE_OUT := 0.205
## Cat de aproape de talpa peretelui sta frunzisul.
##
## Talpa e la 0,2 m de marginea asfaltului, iar fata urca aproape vertical
## (73-84 grade din ochiul soferului, masurat cu SvMpBApropiere). Deci banda in
## care o planta pare ca IESE DIN perete, si nu ca sta pe un umar in fata lui,
## e ingusta: peste ~1,4 m de margine planta e deja in fata peretelui, adica
## exact "recuzita pe pajiste" reclamata de criticii rundelor 2-4.
const GAP_PERETE_MIN := 0.35
const GAP_PERETE_MAX := 1.30


func _build() -> void:
	_buza_de_stanca()
	# `_perete_stanga` NU se mai apeleaza: peretele din stanga e acum teren
	# construit (noduri CliffFace in Track15.tscn), nu un sir de piese. Vezi
	# nota lunga de deasupra lui `_perete_stanga_RETRAS`.
	_vegetatie_agatata()
	_trepte_si_semne()


## RUNDA 2 - DE CE AU DISPARUT BOLOVANII SI CE LE IA LOCUL.
##
## Runda 1 a pus 220 de piese, din care ~200 `moss_boulder_*` mariti la 4-13 m
## pe buza. Masurat pe captura, fata de aceeasi clasificare HSV ca la nota 3:
##
##   captura            roca    iarba   drum
##   0.08 zona GOALA     3,6 %   42,6 %  42,9 %
##   0.08 runda 1        3,7 %   43,6 %  41,8 %
##   0.18 zona GOALA     0,1 %   24,0 %  67,9 %
##   0.18 runda 1        0,1 %   23,9 %  68,0 %
##
## 220 de piese au cumparat 0,1 puncte de roca si au ADAUGAT iarba. Pe captura
## (B_r1_f0.14.png) se vede de ce, fara dubiu: bolovanii citesc ca niste
## CARAPACE VERZI cu o dunga tan la baza - un sir de umbrele tropicale, adica
## fix materia de care aveam deja de patru ori prea multa.
##
## CAUZA E MASURATA, NU PRESUPUSA, si era deja scrisa in inventar (§2, tabelul
## de ACCENT_SPLIT): pe `Moss_Boulder_C` muschiul (slot 12 CACTUS_GREEN) ocupa
## banda de y 0,97-3,07 dintr-o inaltime de 3,069 - adica **68 % din inaltime,
## si tocmai partea de sus**, cea care sta in fata camerei. Pe A e 0,38-0,74
## din 0,741 (49 %), pe B 0,92-1,96 din 1,957 (53 %).
##
## Fractia aia e INVARIANTA LA SCARA. Nu exista marime la care piesa sa citeasca
## a stanca: marind-o de la 3 m la 8 m am marit capacul de muschi in exact
## aceeasi proportie. Asta e capcana din memoria
## `capcana-parametrului-care-doar-aduna` - intrebarea nu era "cat sa maresc",
## ci "de unde vine forma".
##
## CE CITESTE A PIATRA IN KITUL ASTA, masurat in acelasi tabel:
##   `Inca_Wall_A`  3+29 (piatra) **93,7 %**, slot 12 doar 6,3 %, si numai pe
##                  coronament (y 2,31-2,49 din 2,487)
##   `Inca_Wall_C`  3+29 **91,5 %**, slot 12 8,5 %, tot pe coronament
##   `Trail_Marker` doar 3+29, deci piatra curata
## Deci buza se face din ZIDARIE, nu din bolovani. Si asta nu e o abatere de la
## bara: in bara, sub gura de tunel, marginea drumului chiar e sprijinita de un
## parapet de blocuri de piatra - aceeasi materie.
##
## Bolovanii RAMAN, dar in rolul pentru care au fost masurati: accente MICI
## (0,8-1,8 m) la sol, unde un capac de muschi pe o piatra e corect si nu
## ocupa cadrul.
##
## COLIZIUNEA RAMANE `none` pe tot, inclusiv pe zidarie. Contractul cere
## explicit "pe dreapta FARA parapet, defileul" - deci piatra de pe buza e
## semnal vizual, nu bara de protectie. Cu corp, un zid la 0,8 m de muchie ar
## fi exact parapetul pe care brief-ul il interzice, pe o banda de 6 m.
func _buza_de_stanca() -> void:
	var f := F_BUZA
	var k := 0
	while f <= F_OUT:
		# SIRUL DE PE BUZA: zidarie joasa, lipita, care urmeaza muchia.
		# Pasul de 2,8 m pe o piesa de 4,00 m (inca_wall_a) le suprapune cu
		# 1,2 m, deci sirul e CONTINUU chiar si in viraj, unde coarda taie din
		# lungimea utila - un sir cu goluri citeste a lespezi razlete,
		# verdictul care a costat POI D trei runde.
		var a := _at(f)
		var s: Vector3 = a["s"]
		# Zidul se aseaza TANGENT la drum: yaw pe directia de mers.
		var yaw := atan2(s.x, s.z) + PI * 0.5
		var m: String = "inca_wall_a" if k % 3 != 2 else "inca_wall_c"
		# Inaltime mica si variabila: e o buza de sprijin, nu un gard. Scara
		# pe inaltime separata de cea din plan (lectia `_raw_h` de la POI D):
		# un zid mai scund nu e un zid mai SUBTIRE.
		var hz := _coama(f)
		_zid_buza(m, "buzaPiatra", f, 1.0, _retragere(f),
			yaw + _rng.randf_range(-0.035, 0.035), hz)
		# PINTENII care rup linia: tot zidarie, dar rotita si mai inalta,
		# la fiecare al treilea pas. Fara ei sirul e o bordura de gradina.
		if k % 4 == 1:
			_zid_buza("inca_wall_c", "pintenBuza", f + _step(1.8), 1.0,
				_retragere(f + _step(1.8)) + 0.35,
				yaw + _rng.randf_range(0.18, 0.38),
				_coama(f) + _rng.randf_range(0.5, 0.9))
		# FALEZA: relief pe fata prapastiei, sub cota drumului. Aici bolovanul
		# e corect - e departe (6-16 m) si in jos, deci capacul de muschi nu
		# se vede din masina, doar silueta.
		if _rng.randf() < 0.55:
			var m3: String = ["moss_boulder_c", "moss_boulder_b"][k % 2]
			var h3 := _rng.randf_range(6.0, 11.0)
			_place(m3, "falezaB", f + _step(_rng.randf_range(0.0, 4.0)), 1.0,
				_rng.randf_range(6.0, 16.0), _rng.randf_range(0.0, TAU),
				_scale_for(m3, h3), "none", -h3 * 0.55)
		f += _step(2.8)
		k += 1


## COAMA SIRULUI - reparatia rundei 3, si e o singura idee.
##
## VERDICTUL PE CAPTURA B_r2_f0.14.png (regula zero: captura bate cifra):
## zidaria e acolo si citeste a piatra - castigul rundei 2 - dar blocurile sar
## in sus si in jos ca un gard de scanduri rupt, fiecare la alta inaltime si la
## alt unghi. Adica exact «segmente scurte, distantate, la unghiuri diferite»,
## verdictul pe care POI D l-a incasat de trei ori.
##
## CAUZA E IN CODUL MEU, o linie: inaltimea era `_rng.randf_range(0.9, 1.7)`
## trasa INDEPENDENT pentru fiecare piesa. Doua piese vecine, la 3,6 m una de
## alta, puteau iesi una de 0,9 si una de 1,7 - o treapta de 0,8 m intre doi
## vecini lipiti. Zgomot alb pe o marime care trebuie sa fie CONTINUA.
##
## Un zid de sprijin real isi schimba inaltimea LENT, pe zeci de metri, fiindca
## urmeaza terenul de sub el. Deci inaltimea nu se trage la zar per piesa, ci se
## citeste dintr-o functie NETEDA de pozitia pe traseu. Variatia ramane (nu e o
## bordura turnata), dar are lungime de unda de ~40 m, nu de 3,6 m.
##
## Doua sinusoide cu perioade incomensurabile, ca sa nu se vada tiparul.
func _coama(frac: float) -> float:
	var d := frac * _total_len
	return 1.15 + 0.38 * sin(d / 41.0) + 0.17 * sin(d / 13.7 + 2.1)


## Idem pentru peretele taiat din stanga, dar mai inalt: acolo drumul e TAIAT
## in versant, deci fata se vede pe toata inaltimea ei.
func _coama_stg(frac: float) -> float:
	var d := frac * _total_len
	return 2.70 + 0.55 * sin(d / 37.0 + 0.7) + 0.22 * sin(d / 11.3)


## RETRAGEREA fata de muchie - a doua jumatate a reparatiei din runda 3.
##
## Dupa ce `_coama` a netezit INALTIMEA, captura B_r3_f0.14.png arata ca sirul
## tot nu citeste a perete: blocurile ies din linie fiecare cu alt cat, deci se
## vede o SCARA DE CUTII, nu o fata continua. Cauza e aceeasi greseala ca la
## inaltime, lasata pe alta marime: `gap` era `_rng.randf_range(0.3, 1.1)`,
## tras independent per piesa. Doi vecini la 2,8 m puteau iesi unul la 0,3 si
## altul la 1,1 - o treapta de 0,8 m in plan, exact cat sa se vada colturile.
##
## Lectia, si merita scrisa o data pentru toate: pe un SIR care trebuie sa
## citeasca drept o singura suprafata, ORICE marime desenata independent per
## piesa (inaltime, retragere, unghi, scara) produce zimti. Zgomotul se pune pe
## o functie neteda de pozitie, nu pe fiecare piesa in parte.
func _retragere(frac: float) -> float:
	var d := frac * _total_len
	return 0.55 + 0.22 * sin(d / 29.0 + 1.3)


func _retragere_stg(frac: float) -> float:
	var d := frac * _total_len
	return 0.42 + 0.18 * sin(d / 23.0 + 0.4)


## Un zid pe buza: pozitia si cota ca la `_place`, dar cu scara pe inaltime
## separata de cea din plan (piesa isi pastreaza lungimea si grosimea
## masurata) si infipt cu 0,35 m sub sol ca sa nu i se vada talpa.
func _zid_buza(model: String, base: String, frac: float, side_sign: float,
		gap: float, yaw: float, inalt: float) -> void:
	var a := _at(frac)
	var p: Vector3 = a["p"]
	var s: Vector3 = (a["s"] as Vector3) * side_sign
	var half: float = a["half"]
	var lr: float = SIDE_R.get(model, 0.45)
	var q := p + s * (half + gap + lr)
	var g := _sol_real(q.x, q.z)
	_raw_h(model, base, Vector3(q.x, g - 0.35, q.z), yaw, 1.0,
		inalt / float(HEIGHT.get(model, 1.0)), "none")


## PERETELE DIN STANGA - RETRAS IN RUNDA 5, si motivul merita scris o data
## pentru toate fiindca e acelasi pe care l-au ratat rundele 1-4.
##
## Verdictul criticului orb, dupa runda 4: «drumul nostru nu e taiat in nimic.
## In referinta, o masa continua de piatra se ridica pe stanga [...]. La noi
## stanga e o panta verde moale, iar in locul peretelui sunt ~15 blocuri de
## piatra razlete, la scara de recuzita, stand libere pe iarba - material
## corect, OBIECT GRESIT.»
##
## Avea dreptate, si diagnosticul rundelor 2-4 era incomplet, nu gresit.
## Runda 2 a aflat ca materia trebuie sa fie zidarie, nu muschi (corect).
## Runda 3 a aflat ca inaltimea si retragerea nu se trag la zar per piesa
## (corect). Dar amandoua au raspuns la intrebarea „ce piesa pun?", cand
## intrebarea era „de unde vine FORMA?" - exact memoria
## `capcana-parametrului-care-doar-aduna`.
##
## Cifra care inchide discutia, din survey (nota 2): pe stanga terenul e PLATOU
## la -0,3 m pe tot intervalul, in afara de 0.110-0.145. Un perete de 15-20 m nu
## poate fi facut din piese de 2,5 m asezate pe un platou plat, la NICIO
## densitate: ii lipseste masa de dedesubt. `inca_wall_a` are 2,487 m; ca sa
## acopere o fata de 17 m ar trebui 7 asize suprapuse, adica un zid de cetate,
## nu un versant taiat.
##
## Un perete nu e o piesa de decor, e TEREN - si terenul nu poate fi cerut
## campului de inaltime: celula grilei e 7,92 m (Track.TERRAIN_CELL), deci orice
## taietura lipita de asfalt se intinde pe o celula intreaga si iese rampa.
## Nodul care rezolva exact asta exista deja in proiect, construit pentru un
## verdict aproape identic pe POI C al Cappadociei: [CliffFace] cu `cut_wall`,
## „TAIETURA DIN INTERIORUL VIRAJULUI: peretele in care e SAPAT drumul".
##
## Deci peretele din stanga e acum declarat in Track15.tscn ca trei noduri
## CliffFace (`Faleze/TaieturaDrumIncasA/B/C`, fractiile 0.044-0.207), si
## functia asta nu se mai apeleaza. Costa ZERO materiale in plus (e tot
## Palette.world_material, benzile sunt UV-uri pe sloturi din acelasi atlas),
## si pe platou nu se stinge fiindca `cut_min_rise_m` da o inaltime de podea -
## acelasi mecanism cu care Serengeti si-a facut malul dintre bratele
## serpentinei (Track14.tscn, `PeretePrimaDreapta`).
##
## SLOTURILE, si aici am gresit o data masurat inainte sa ma uit la captura.
## Prima incercare a folosit 3/29/4 (ROCK_LIGHT / MARBLE_GREY / ROCK_DARK),
## fiindca asta scrie palette.gd:723 ca fiind amestecul zidariei incase. Pe
## captura (B_r5_f0.14.png) peretele a iesit PORTOCALIU-CARAMIZIU. Cauza,
## citita din atlas cu PIL:
##   slot  3 #CE8D4A  H30,5 S0,64 V0,81   <- gresie calda de canion
##   slot  4 #774C23  H29   S0,71 V0,47
## Cifrele din palette.gd sunt tinta pe care o atinge clasa `inca_stone` DUPA
## lift+tenta, pe piesele de kit. Panza falezei NU trece prin clasa aia: ia
## slotul brut din atlas. Deci pe ea sloturile se aleg dupa culoarea BRUTA.
##
## Ancora e `scarp_tint` al temei (#4A4844, H40 S0,08 V0,29) - granitul andin
## pe care il are deja rapa de alaturi, si de care peretele nu are voie sa
## difere, altfel taietura citeste ca alt material decat faleza de sub ea.
## Masurat pe aceeasi ancora:
##   slot 29 #B6B2AA  H40,0 S0,07   <- ACEEASI nuanta si saturatie, mai deschis
##   slot  8 #C8BDA9  H38,7 S0,16   <- coama in soare
##   slot  6 #5C5A59  H20,0 S0,03   <- strat neutru inchis
##   slot 20 #56545B  H257  S0,08   <- umbra rece de strat
## Niciunul peste S0,16; slotul 3 sta la S0,64, adica de opt ori mai saturat.
## Ordinea alterneaza deschis/inchis fiindca benzile se citesc drept STRATE doar
## daca vecinele difera in VALOARE (nota din `band_slots`).
func _perete_stanga_RETRAS() -> void:
	var f := F_FLANC_IN
	var k := 0
	while f <= F_FLANC_OUT:
		var a := _at(f)
		var s: Vector3 = a["s"]
		var yaw := atan2(s.x, s.z) + PI * 0.5
		# Doua asize suprapuse: peretele taiat are inaltime, nu e o bordura.
		var m: String = "inca_wall_a" if k % 2 == 0 else "inca_wall_c"
		_zid_buza(m, "pereteStg", f, -1.0, _retragere_stg(f),
			yaw + _rng.randf_range(-0.035, 0.035), _coama_stg(f))
		if _rng.randf() < 0.65:
			_zid_buza("inca_wall_c", "pereteStg", f + _step(1.6), -1.0,
				_retragere_stg(f + _step(1.6)) + 1.25,
				yaw + _rng.randf_range(-0.06, 0.06),
				_coama_stg(f) + _rng.randf_range(0.6, 1.4))
		# Bolovani MICI la piciorul peretelui: aici capacul de muschi e
		# corect si citeste ca bolovan cazut, nu ca umbrela.
		if _rng.randf() < 0.5:
			var b: String = ["moss_boulder_a", "moss_boulder_b"][k % 2]
			var hb := _rng.randf_range(0.8, 1.8)
			_place(b, "bolovanStg", f + _step(2.4), -1.0,
				_rng.randf_range(0.5, 3.0), _rng.randf_range(0.0, TAU),
				_scale_for(b, hb), "none", -hb * 0.25)
		f += _step(3.8)
		k += 1


## VEGETATIA AGATATA - pe PIATRA, nu pe iarba. In bara frunzisul creste din
## fata de stanca; pe pajiste ar adauga tocmai materia de care avem deja de
## patru ori prea multa (nota 3: 42,6 % iarba fata de 10,6 % in bara).
##
## Deci: ferigi si bromelii pe flancul din stanga, unde tocmai am pus roca, si
## pe buza din dreapta intre pinteni. Orhideea e accent RAR (contractul o cere
## la 2-3 m de banda), deci una la ~8 pasi.
func _vegetatie_agatata() -> void:
	var f := F_BUZA
	var k := 0
	while f <= F_OUT:
		# Pe TOATA fata de piatra, nu doar pe fereastra unde urca terenul
		# natural: vezi nota de la F_PERETE_IN. Rulajul e mic si constant, ca
		# planta sa iasa din perete, nu sa stea in fata lui pe un umar.
		var pe_perete := f >= F_PERETE_IN and f <= F_PERETE_OUT
		if pe_perete:
			if _rng.randf() < 0.62:
				var h := _rng.randf_range(1.9, 3.1)
				_place("tree_fern", "ferigaStg", f, -1.0,
					_rng.randf_range(GAP_PERETE_MIN, GAP_PERETE_MAX),
					_rng.randf_range(0.0, TAU),
					_scale_for("tree_fern", h), "none")
			if _rng.randf() < 0.72:
				_place("bromeliad", "bromStg", f + _step(1.8), -1.0,
					_rng.randf_range(GAP_PERETE_MIN, GAP_PERETE_MAX),
					_rng.randf_range(0.0, TAU),
					_rng.randf_range(1.4, 2.8), "none")
		# Pe buza din dreapta, printre pinteni.
		if _rng.randf() < 0.6:
			_place("bromeliad", "bromBuza", f + _step(3.2), 1.0,
				_rng.randf_range(0.5, 2.6), _rng.randf_range(0.0, TAU),
				_rng.randf_range(1.5, 3.0), "none")
		if _rng.randf() < 0.45:
			var hf := _rng.randf_range(2.0, 3.2)
			_place("tree_fern", "ferigaBuza", f + _step(4.6), 1.0,
				_rng.randf_range(1.2, 4.5), _rng.randf_range(0.0, TAU),
				_scale_for("tree_fern", hf), "none")
		# Accentul roz: rar, si aproape de banda ca sa se vada.
		if k % 8 == 3:
			var sgn := 1.0 if k % 16 == 3 else -1.0
			_place("orchid_cluster", "orhidee", f + _step(2.0), sgn,
				_rng.randf_range(2.0, 3.0), _rng.randf_range(0.0, TAU),
				_rng.randf_range(1.8, 2.6), "none")
		f += _step(5.5)
		k += 1


## TREPTELE SI SEMNELE. `custom_step_ranges` (0.0405-0.2034) pune deja treptele
## VIZUALE pe carosabil, si coliziunea ramane panta lina (track.gd:_step_ranges).
## Deci NU pun geometrie de treapta peste drum - ar fi un prag de zid.
## Piesele `inca_stair_*` merg LANGA drum, pe flancul din stanga: in bara
## treptele sunt alaturi de drum, nu pe el.
func _trepte_si_semne() -> void:
	# Ca si vegetatia: pe toata fata de piatra, si LIPITE de talpa ei. Cu
	# rulajul vechi (3,0-6,0 m de margine) scarile stateau pe umarul din fata
	# peretelui — de cand peretele s-a mutat la 0,2 m de asfalt, alea ar fi
	# ingropate in el sau suspendate in fata lui.
	var f := F_PERETE_IN
	var k := 0
	while f <= F_PERETE_OUT:
		if k % 2 == 0:
			var m: String = "inca_stair_b" if k % 4 == 0 else "inca_stair_a"
			# Orientata pe directia drumului (scara urca odata cu el).
			var a := _at(f)
			var s: Vector3 = a["s"]
			var yaw := atan2(s.x, s.z)
			_place(m, "trepteStg", f, -1.0,
				_rng.randf_range(GAP_PERETE_MIN, GAP_PERETE_MAX),
				yaw, 1.0, "none", -0.8)
		k += 1
		f += _step(11.0)
	# Bornele de poteca, pe amandoua partile, rare - punctuatie, nu gard.
	f = F_IN + 0.004
	var j := 0
	while f <= F_OUT:
		var sgn := 1.0 if j % 2 == 0 else -1.0
		_place("trail_marker", "borna", f, sgn, _rng.randf_range(1.4, 3.0),
			_rng.randf_range(0.0, TAU), _rng.randf_range(1.1, 1.5), "none",
			-0.15)
		j += 1
		f += _step(26.0)


func _scale_for(model: String, meters: float) -> float:
	var h: float = HEIGHT.get(model, 1.0)
	return meters / h if h > 0.001 else 1.0


const LANE_MARGIN := 2.2


func _lane_free(pos: Vector3, r: float, h: float) -> bool:
	var n := _track.baked.size()
	for i in n:
		var p: Vector3 = _track.baked[i]
		var dy := pos.y - p.y
		if dy + h < 0.0:
			continue
		var dx := pos.x - p.x
		var dz := pos.z - p.z
		var need: float = _track.width_at_index(i) + LANE_MARGIN + r
		if dx * dx + dz * dz < need * need:
			return false
	return true


## Pozitia + latura + semi-latimea INTERPOLATE intre punctele coapte - pasul
## sub 1,79 m altfel da grupuri suprapuse (nota 8bis a lui POI D).
func _at(frac: float) -> Dictionary:
	var n := _track.baked.size()
	var t := fposmod(frac, 1.0) * float(n)
	var i := int(t) % n
	var j := (i + 1) % n
	var u := t - float(int(t))
	var p: Vector3 = _track.baked[i].lerp(_track.baked[j], u)
	var s: Vector3 = _track._side_at(i).lerp(_track._side_at(j), u).normalized()
	var half: float = lerpf(_track.width_at_index(i), _track.width_at_index(j), u)
	return {"p": p, "s": s, "half": half}


## Aseaza la `frac`, pe partea `side_sign`, la `gap` metri de MUCHIA drumului
## pana la marginea piesei. Cota din raycast pe TerrainBody-ul real.
func _place(model: String, base: String, frac: float, side_sign: float,
		gap: float, yaw: float, scl: float, mode: String = "",
		dy: float = 0.0) -> void:
	var a := _at(frac)
	var p: Vector3 = a["p"]
	var s: Vector3 = (a["s"] as Vector3) * side_sign
	var half: float = a["half"]
	var r: float = BASE_R.get(model, 0.6) * scl
	var d := half + gap + r
	var q := p + s * d
	var g := _sol_real(q.x, q.z)
	if d - r < half + 0.3:
		_warn += 1
		print("; ATENTIE %s la frac %.4f: marginea la %.2f m de ax, banda %.2f" % [
			model, frac, d - r, half])
	if mode != "none":
		var hh: float = HEIGHT.get(model, 1.0) * scl
		var lr: float = float(SIDE_R.get(model, BASE_R.get(model, 0.6))) * scl
		if not _lane_free(Vector3(q.x, g + dy, q.z), lr, hh):
			_lane_reject += 1
			return
	_raw(model, base, Vector3(q.x, g + dy, q.z), yaw, scl, mode)


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String) -> void:
	_raw_h(model, base, pos, yaw, scl, scl, mode)


func _raw_h(model: String, base: String, pos: Vector3, yaw: float,
		scl_xz: float, scl_y: float, mode: String) -> void:
	_n += 1
	_tri += int(TRI.get(model, 0))
	var c := cos(yaw) * scl_xz
	var s := sin(yaw) * scl_xz
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	_out.append("transform = Transform3D(%f, 0, %f, 0, %f, 0, %f, 0, %f, %f, %f, %f)"
		% [c, s, scl_y, -s, c, pos.x, pos.y, pos.z])
	if mode != "":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


func _write() -> void:
	print("; asezate %d piese, %d refuzate de garda de banda, %d avertismente, ~%d triunghiuri" % [
		_n, _lane_reject, _warn, _tri])
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


## Cota SOLULUI din coliziunea reala (TerrainBody), nu din campul neted
## (memoria terrain-mesh-y-extrapoleaza).
func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 1200.0, z))
	q.collide_with_areas = false
	if _terrain_rid != RID():
		q.collide_with_bodies = true
		q.exclude = []
		var hit: Dictionary = space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 24:
			q.exclude = q.exclude + [hit["rid"]]
			hit = space.intersect_ray(q)
			guard += 1
		if not hit.is_empty() and hit["rid"] == _terrain_rid:
			return float(hit["position"].y)
	print("; ATENTIE fara sol la (%.1f, %.1f): se cade pe camp" % [x, z])
	return _sampler.ground_y(x, z)
