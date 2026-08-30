@tool
class_name CliffFace
extends Marker3D
## FALEZA ca GEOMETRIE REALA, nu ca versant de camp de inaltime.
##
## Verdictul care a cerut nodul asta (critica oarba, runda 2 pe POI C): „nu e o
## problema de culoare, e ca NU EXISTA nicio fata de stanca — partea dreapta a
## cadrului e un camp forfecat cu lespezi sprijinite de el". Masurat, avea
## dreptate, si cauza e structurala:
##
##   grila de teren are celula de 7.92 m ([constant Track.TERRAIN_CELL]).
##
## O rapa ceruta VERTICALA chiar iese verticala IN CAMP — masurat pe Track13 la
## fractia 0.28, `ground_y` cade de la 38.80 la 13.70 in 2 m de rulaj lateral.
## Dar suprafata care se RANDEAZA si de care se lovesc rotile e mesh-ul, iar el
## poate doar sa interpoleze liniar intre noduri aflate la 7.92 m unul de altul:
## acolo unde campul spune 13.70, mesh-ul spune 27.51 — o eroare de 13.8 m, si
## un perete de 25 m intins pe o panta de 6 m. De aceea capturile rundei 1
## aratau o dună bej: nu se ceruse gresit, pur si simplu campul nu are rezolutie
## de faleza si nici nu poate capata (o celula mai mica inseamna toata harta mai
## deasa, adica alt buget).
##
## Concluzia care da forma nodului: o faleza nu se poate CERE campului, trebuie
## CONSTRUITA. Nodul asta genereaza o panza de triunghiuri lipita de buza rapei,
## cu benzi orizontale de culoare din atlas (Valea Rosie), cu polite reale, si
## isi coase talpa in teren ca sa nu ramana fanta.
##
## [b]De ce nu piese de kit.[/b] `cliff_band_module.glb` exista si a fost
## incercat in runda 1: lespezi de 15 m sprijinite de versant. Doua motive au
## picat masurat — (1) versantul se APLEACA peste ele, deci fata rosie ramane in
## spatele tufului crem si din masina vezi tot crem; (2) o piesa dreapta pe o
## buza care se curbeaza lasa fisuri sau intra in drum. Panza generata urmeaza
## curba benzii punct cu punct, deci nici nu se ingroapa, nici nu iese in sosea.
##
## [b]Materiale: zero in plus.[/b] Toata faleza e UN mesh cu
## [method Palette.world_material] — materialul partajat al lumii. Benzile sunt
## UV-uri pe sloturi diferite din acelasi atlas, plus vertex color pentru AO.
## Bugetul pistei nu se misca cu o unitate.
##
## Ca [TerrainPeak] / [TerrainHollow], nodul e o DECLARATIE editabila: sta in
## .tscn, il tragi in viewport, apesi Regenerate pe radacina pistei.

## Fractia de traseu la care incepe faleza (0..1).
@export_range(0.0, 1.0, 0.001) var frac_start: float = 0.185
## Fractia la care se termina.
@export_range(0.0, 1.0, 0.001) var frac_end: float = 0.38
## Latura pe care cade golul: +1 dreapta (sensul de mers), -1 stanga.
@export_range(-1.0, 1.0, 2.0) var side: float = 1.0

## Cat de departe de marginea asfaltului incepe BUZA falezei.
##
## Mic intentionat: POI C e „cornisa fara parapet", deci buza trebuie sa fie la
## marginea benzii. Sub 0.5 m panza ar musca din umarul drumului.
@export var lip_offset_m: float = 0.2
## Cati metri coboara fata, de la buza in jos.
@export var depth_m: float = 30.0
## Pasul de esantionare pe lungimea benzii. 4 m tine curba fara sa umple grila:
## pe 200 m de cornisa ies ~50 de coloane.
@export var step_m: float = 4.0
## Cate benzi orizontale de culoare are fata.
@export var bands: int = 9
## Cat iese in afara peretele, ca fata sa nu fie un plan perfect. Fiecare banda
## primeste retragerea ei, deci stratele ies in relief ca la o roca sedimentara.
@export var band_relief_m: float = 0.9
## Evazarea fetei: metri de rulaj lateral pentru fiecare METRU de cadere.
##
## Zero ar insemna perete perfect vertical — si perfect ascuns de marginea
## drumului din camera de joc, care e chiar modul in care s-a pierdut runda 2.
##
## Valoarea nu e de gust, e citita din ProbeReach: frontiera dintre „se vede" si
## „nu se vede", masurata cu raze din ochiul real, cere ~4 m de rulaj la fiecare
## ~6 m de adancime, adica 0.66. Se merge putin peste, la 0.72, ca banda sa fie
## vizibila cu marja si pe fractiile unde drumul se inclina spre vale.
@export var batter_m: float = 0.72

## Cat de adanc intra talpa panzei in teren, ca sa nu ramana fanta la contact.
##
## Grila de teren are 7.92 m, deci intre doi vertecsi ai ei suprafata reala se
## poate abate cu metri de la camp (masurat pe cornisa: pana la 13.8 m). Talpa
## se coase pe SUPRAFATA mesh-ului, nu pe camp, si mai coboara atat pe deasupra.
@export var foot_bite_m: float = 2.5

## Sloturile de paleta ale benzilor, de SUS in jos.
##
## Nu sunt alese din ochi: masurat pe referinta (`img/v3_crops/C_cornice.png`,
## trei coloane prin fata mare de stanca), stratele stau la nuanta 5-30°,
## saturatie 0.47-0.65, valoare 0.44-0.75. Sloturile de mai jos sunt exact cele
## din atlas care cad in fereastra aia, plus cremul de coama:
##   19 CORAL_SAND  #E9DCC0  coama de tuf (aceeasi culoare ca platoul)
##   23 TILE_TERRACOTTA #C4784F  H21 S.60 V.77  roz-caramiziu
##   27 LARCH_RUST  #A8683A  H25 S.65 V.66  ocru-rosu
##   10             #91461E  H21 S.79 V.57  rosu de caramida (banda TARE)
##    3 ROCK_LIGHT  #C18446  H30 S.64 V.76  reprize deschise intre rosuri
##    4 ROCK_DARK   #67421F  strat umbrit
##    2 SAND_SHADOW #915D27  adancul de la picior
##
## Ordinea alterneaza deschis/inchis pe scop: benzile se citesc ca STRATE doar
## daca vecinele difera in VALOARE, nu doar in nuanta.
## Compozitia e ROSU-DOMINANTA, si asta e o corectie masurata, nu o preferinta.
## Prima versiune alterna crem/ocru/rosu in parti egale; masurat pe captura
## rezultata, fata iesea la nuanta 30-33 grade cu saturatie 0.55, adica OCRU —
## exact culoarea terenului de alaturi, deci faleza nu se citea ca alt material.
## Referinta sta la nuanta 5-25 si saturatie 0.47-0.65 pe TOATA fata, cu cremul
## doar ca o cusatura subtire de coama.
##
## Deci cremul (19) ramane un singur rand, sus, iar corpul falezei e rosu:
## 23 roz-caramiziu, 10 rosu de caramida, 27 ocru-rosu, cu 3 ca repriza deschisa.
@export var band_slots: Array[int] = [23, 10, 27, 23, 10, 27, 4, 2, 2]

## POLITELE din perete: fractiile la care faleza are un prag pe care se poate
## ancora ceva (metri de la ax se deriva, vezi `ledge_offset_m`).
##
## Exista fiindca `docs/track_briefs/cappadocia_geometrie.md` cere exact asta si
## masoara de ce nu se poate altfel: un balon ancorat pe fundul vaii urca DREPT
## si intra in peretele inclinat — pe colturile cosului de 4.8 m se infunda dupa
## 1 m din cei 30 de cursa. Peretele nu poate fi facut vertical din campul de
## inaltime (celula grilei e de 7.92 m, deci o taietura de 1.2 m se intinde pe o
## celula intreaga si mesh-ul greseste cu pana la 10 m sub roata). Dar POATE fi
## facut vertical in GEOMETRIE ASEZATA — si asta e chiar nodul de fata.
##
## Polita e o treapta reala in panza: fata coboara vertical pana la ea, iese pe
## orizontala `ledge_depth_m`, apoi isi continua caderea. Cu tarusul pe ea,
## coloana de 30 m de deasupra e libera prin constructie.
@export var ledge_fracs: Array[float] = []
## Cat de departe de AXUL benzii sta buza politei.
##
## Implicitul nu e rotund din intamplare: cosul are 4.8 m, semilatimea benzii pe
## cornisa e 7.0 m, deci ca marginea dinspre drum a cosului sa treaca de
## marginea asfaltului tarusul trebuie la cel mult 7.0 + 2.4 = 9.4 m. Sub atat,
## cosul chiar intra in banda; peste, ramane gol intre el si drum.
@export var ledge_offset_m: float = 9.2
## Cat de jos sub buza sta polita. 12 m e „vizibil de pe drum ca prag, si destul
## de jos cat cursa sa fie o urcare, nu o ridicare de doi metri".
@export var ledge_drop_m: float = 12.0
## Cat de adanca (spre vale) e treapta, si cat de lunga pe traseu.
@export var ledge_depth_m: float = 3.2
@export var ledge_len_m: float = 9.0


## ############################################################################
## PERETELE DE DINCOLO — partea care se VEDE de fapt.
## ############################################################################
##
## Masurat cu ProbeFacing: fata de langa banda e vazuta la 83 de grade fata de
## normala, adica pe muchie, 0% in plin. Asta nu e un reglaj gresit, e
## geometrie: mergi PARALEL cu ea. Si nu o salveaza niciun viraj, fiindca pe
## toata cornisa drumul coteste doar spre dreapta (ProbeCurve), deci exact in
## sensul care duce peretele exterior in spate.
##
## Masurat cu ProbeWhere2, jumatatea dreapta a cadrului cade in doua zone:
## soseaua (0-10 m rulaj, ~35% din raze) si o banda larga la +25..+70 m (~50%).
## Fasia in care statea panza (10-25 m) primeste 2-4%.
##
## Deci stanca rosie se muta acolo unde se UITA camera: versantul DE DINCOLO de
## vale, care sta cu fata spre drum si se vede in plin. E si compozitia
## referintei (`img/v3_crops/C_cornice.png`): masa roz-rosie de acolo e peretele
## din fata, cu drumul si buza in prim-plan — nu marginea de sub roata.
##
## Buza de langa banda RAMANE (mai scunda): ea da senzatia de cadere si
## marginea de care ti-e frica. Dar culoarea si stratele le duce peretele opus.

## Construieste PINTENUL de stanca de langa banda.
##
## Numele „far" a ramas din prima incercare (un perete dincolo de vale) si a fost
## abandonat cu masuratoarea in fata: la 26 m rulaj si coama sub cota drumului,
## masa cadea sub linia privirii si dadea 1.2% din cadru. Corectia a venit din
## unghiuri, nu din gust — orizontul REAL al ochiului nu e panta terenului
## (-36 gr, cum sugera prima citire) ci MARGINEA soselei, la -59 gr. Peste ea,
## orice stanca tinuta la COTA DRUMULUI e vizibila de la 8 pana la 26 m rulaj,
## la toate cele trei fractii.
##
## Deci masa rosie sta chiar langa banda, la cota drumului: un PINTEN care se
## ridica din vale pana la nivelul soselei si o insoteste. Asta e si compozitia
## referintei — stanca umple dreapta cadrului la inaltimea drumului, cu valea
## dedesubt si dincolo de ea, nu o dunga la orizont.
@export var far_wall: bool = true
## La ce rulaj lateral incepe pintenul (marginea dinspre drum).
##
## MASURAT cu ProbeBrow, nu ales: terenul are deja o BUZA adevarata — caderea
## incepe la 8.0 m de ax (1 m dupa asfalt) si merge la 77-85 grade, la toate
## cele trei fractii. Nu era niciodata un „fileu convex", cum parea din capturi.
##
## De-aia pintenul pus la 9 m facea rau: umplea exact golul in care cadea buza,
## si transforma muchia intr-o rampa continua — adica producea chiar defectul
## reclamat, cu geometria corecta dedesubt. Se muta DINCOLO de cadere (fundul
## vaii e la ~13 m rulaj), ca muchia sa ramana muchie si stanca sa se vada peste
## ea, nu in locul ei.
@export var far_offset_m: float = 15.0
## MALUL DE DINCOLO in loc de pinten langa banda.
##
## Cu el, masa nu mai atarna de cota soselei: se aseaza pe terenul de la
## `far_offset_m` si urca peste creasta LUI. Are sens doar impreuna cu o rapa
## care are latime (Track._ravine_widths) — altfel dincolo de buza nu exista
## teren mai inalt, si masa n-are pe ce sta.
##
## De ce e nevoie de el, cu masuratoarea in fata: pintenul de la 15 m, legat de
## cota drumului, e o DUNGA de stanca de-a lungul benzii. Cum a spus critica
## oarba dupa runda 3, „un perete paralel cu drumul pe care mergi nu poate
## prezenta o fata unei camere indreptate pe drum". Malul opus sta TRANSVERSAL
## pe privire, deci se vede in plin — si e chiar compozitia referintei.
@export var far_bank: bool = false
## Cat de sus sta ochiul soferului fata de asfalt (metri). Nu se alege: e
## inaltimea camerei de urmarire, si serveste la a ridica malul pana la linia
## privirii — vezi `far_over_eye_m`.
@export var far_eye_rise_m: float = 6.0
## Cu cati metri trece coama malului PESTE linia ochiului.
##
## Peste 0 inseamna ca masa taie orizontul, deci se citeste ca perete de vale si
## nu ca dungă la baza cerului. Masurat: cu coama pe creasta terenului (sub ochi
## cu 28 de grade) malul dadea 0.00% din cadru.
@export var far_over_eye_m: float = 12.0
## Cat urca coama pintenului fata de cota soselei.
##
## Pozitiv = peste drum. Se tine mic: peste ~3 m ar face un zid care ascunde
## valea si baloanele care urca din ea, adica exact povestea POI-ului.
@export var far_rise_m: float = 1.2
## Cat de departe pe rulaj se intinde coama pintenului (latimea masei).
## Ingusta deliberat: coama e suprafata pe care camera o vede cel mai bine
## (in unghi mic), deci cu cat e mai lata, cu atat ascunde mai mult din fata
## verticala — adica exact partea cu strate. 9 m ajunge ca masa sa nu fie lama.
@export var far_depth_m: float = 9.0
## Pasul pe lungime pentru peretele opus. Mai mare decat la buza: e departe,
## deci nu are nevoie de aceeasi rezolutie.
@export var far_step_m: float = 7.0
## Cate benzi orizontale are pintenul.
@export var far_bands: int = 7
## Sloturile coamei, dinspre buza spre vale. Masurate cu ProbeSlots:
##   23 #c0754d H21 S.60  rosu de corp
##   27 #9c6131 H27 S.69  ocru-rosu
##    4 #70481b H32 S.76  umbra de strat
## Nu contine 19 (#f1e3c8, saturatie 0.17): pe coama, cremul face lespede palida.
@export var cap_slots: Array[int] = [23, 10, 23, 27]


## TAIETURA DIN INTERIORUL VIRAJULUI: peretele in care e SAPAT drumul.
##
## De ce exista, cu masuratoarea in fata. Verdictul rundei 4: „in referinta
## drumul e TAIAT in stanca — o polita cu o fata taiata in interior si o cadere
## in exterior. La noi drumul e PICTAT pe o duna, lipit in stanga, fara
## taietura, fara bordura." Cauza NU e ca lipseste masa de stanca: ProbeInboard
## masoara pe interior +47 m la fractia 0.28, deci muntele chiar e acolo.
## Cauza e CE E INTRE el si asfalt — terenul ramane PLAT (0..+1 m) pana la 14 m
## de ax, adica o banda goala de 7 m dincolo de marginea benzii.
##
## Banda aia e chiar [constant Track.TERRAIN_CELL] (7.92 m): campul de inaltime
## nu POATE urca in interiorul unei celule lipite de drum, exact motivul pentru
## care faleza de la buza e geometrie construita si nu rapa ceruta campului.
## Deci si taietura din interior trebuie CONSTRUITA, din acelasi motiv si cu
## acelasi pret: zero materiale, e tot [method Palette.world_material].
##
## Forma: invers fata de `_build` — coloana urca de la talpa (in umarul
## drumului) pana la coama, si fata se uita SPRE drum. Cu ea, banda are perete
## intr-o parte si gol in cealalta, adica citeste ca polita, nu ca duna.
@export var cut_wall: bool = false
## La ce rulaj lateral incepe talpa taieturii, fata de axul benzii.
##
## Se pune chiar dupa marginea asfaltului (half_width 7.0 la POI C) plus umarul:
## daca peretele nu e LANGA banda, ramane duna intre el si roata si nu s-a
## rezolvat nimic. Sub half_width ar musca din carosabil.
@export var cut_offset_m: float = 8.2
## Cati metri urca fata, de la talpa in sus.
##
## 18 m taie orizontul din vederea soferului (ochiul e la ~6 m peste asfalt),
## deci peretele se citeste ca masa, nu ca bordura inalta.
@export var cut_height_m: float = 18.0
## Retragerea laterala TOTALA a fetei, de la talpa la coama.
##
## Mica: o taietura de drum e aproape verticala (asa se sapa), spre deosebire de
## un versant natural. 2.5 m pe 18 m inseamna ~8 grade fata de verticala.
@export var cut_batter_m: float = 2.5
## Pasul de esantionare pe lungime.
@export var cut_step_m: float = 4.0
## Cate benzi orizontale de strat are taietura.
@export var cut_bands: int = 7
## Cat de adanc intra talpa in teren, ca sa nu ramana fanta luminoasa pe linia
## in care ochiul cauta contactul dintre perete si umar.
@export var cut_foot_bite_m: float = 1.2
## Sloturile taieturii, de la coama in jos. Aceleasi strate ca faleza, ca sa se
## citeasca drept ACEEASI roca vazuta din partea cealalta a benzii.
@export var cut_slots: Array[int] = [23, 10, 27, 23, 10, 27, 4]


## Toate falezele declarate ca noduri, construite intr-un singur nod-parinte.
## Se cheama din [method Track.rebuild], dupa ce terenul exista: talpa se coase
## pe suprafata LUI.
static func build_all(track: Node3D, sampler: TrackSideSampler,
		surface_y: Callable) -> Node3D:
	var root := Node3D.new()
	root.name = "CliffFaces"
	var faces: Array[CliffFace] = []
	_collect(track, faces)
	for f in faces:
		# Un nod de MAL OPUS nu construieste si panza de buza: buza si-o face
		# nodul cornisei. Fara asta, nodul de mal dubla peretele de langa banda
		# (masurat cu ProbeBankPos: doua panze la 42 si 45 m rulaj, adica in
		# acelasi loc) si nu se vedea nicio schimbare in captura — geometrie
		# noua, aceeasi silueta.
		if not f.far_bank:
			var mesh_node := f._build(sampler, surface_y)
			if mesh_node != null:
				root.add_child(mesh_node)
		if f.far_wall:
			var far_node := f._build_far(sampler, surface_y)
			if far_node != null:
				root.add_child(far_node)
		# TAIETURA e independenta de celelalte doua: un nod poate fi NUMAI
		# taietura (perete pe interior, fara gol pe exterior), fiindca cele doua
		# maluri ale unei polite sunt lucruri diferite si se declara separat.
		if f.cut_wall:
			var cut_node := f._build_cut(sampler, surface_y)
			if cut_node != null:
				root.add_child(cut_node)
	return root


## Peretele in care e SAPAT drumul, pe latura dinspre INTERIORUL virajului.
##
## Vezi `cut_wall` pentru motivul si masuratoarea. Aici doar forma: pentru
## fiecare pas se ridica o coloana de la talpa (infipta in umar) pana la coama,
## fata privind SPRE banda. Ordinea vertecsilor din `_quad` e inversa fata de
## `_build`, fiindca normala trebuie sa bata inspre drum, nu dinspre el.
##
## Coama urmeaza TERENUL de deasupra, nu o cota fixa: acolo unde masivul chiar
## urca (fractiile 0.26-0.30, +47 m masurat) peretele se inalta cu el, iar unde
## platoul se aplatizeaza taietura se stinge singura — asa se opreste sa fie un
## zid continuu care ar ascunde tot ce e dincolo de viraj.
func _build_cut(sampler: TrackSideSampler, surface_y: Callable) -> Node3D:
	var total := sampler.total_length()
	if total <= 0.0 or cut_bands < 1 or cut_slots.is_empty():
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var span := (frac_end - frac_start) * total
	var steps := maxi(int(round(span / maxf(cut_step_m, 0.5))), 2)
	var cols: Array = []
	for si in steps + 1:
		var f := frac_start + (frac_end - frac_start) * (float(si) / float(steps))
		cols.append(_cut_column(sampler, f, surface_y))
	var built := 0
	for si in steps:
		var a: Array = cols[si]
		var b: Array = cols[si + 1]
		if a.is_empty() or b.is_empty():
			continue
		built += 1
		var rows: int = mini(a.size(), b.size())
		for r in rows - 1:
			var slot: int = cut_slots[mini(r, cut_slots.size() - 1)]
			var uvv := Palette.uv(slot)
			# AO invers fata de faleza: la o taietura, talpa sta in umbra
			# peretelui si coama prinde soarele. Randul 0 e COAMA.
			var t0 := float(r) / float(rows - 1)
			var t1 := float(r + 1) / float(rows - 1)
			var c0 := _shade(t0)
			var c1 := _shade(t1)
			# Ordine inversa fata de `_build`: fata priveste spre banda.
			_quad(st, b[r], a[r], a[r + 1], b[r + 1], uvv, c0, c0, c1, c1)
	if built == 0:
		return null
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Taietura " + name
	mi.mesh = st.commit()
	mi.material_override = Palette.world_material()
	# Peretele sta LANGA banda si la est de ea pe portiunea cornisei: la soare de
	# zori umbra lui cade chiar pe carosabil, si e cel mai ieftin semn ca drumul
	# e sapat in ceva solid.
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi


## O coloana din taietura: de la coama in jos pana in talpa, infipta in umar.
##
## Intoarce lista goala cand nu e in ce sapa — vezi mai jos.
func _cut_column(sampler: TrackSideSampler, f: float, surface_y: Callable) -> Array:
	var n := sampler.point_count()
	var i := clampi(int(round(f * float(n))) % n, 0, n - 1)
	var p := sampler.baked_point(i)
	# Interiorul e latura OPUSA golului: nodul declara `side` pentru cadere.
	var sd := sampler.side_at(i) * -signf(side)
	var foot: Vector3 = p + sd * cut_offset_m
	var foot_y: float = surface_y.call(foot.x, foot.z)
	# Talpa se infige sub suprafata umarului, ca sa nu ramana fanta.
	foot_y = minf(foot_y, p.y) - cut_foot_bite_m
	# CAT DE SUS: se cere terenului de dincolo, nu unei cote fixe.
	#
	# Se ia cea mai inalta cota pe o fereastra scurta dincolo de talpa. Unde
	# masivul urca, peretele urca cu el; unde platoul e plat, `rise` iese ~0 si
	# coloana se intoarce goala — taietura se stinge in loc sa devina zid.
	var crest := -1e9
	var probe := 4.0
	while probe <= 22.0:
		var q := foot + sd * probe
		crest = maxf(crest, surface_y.call(q.x, q.z))
		probe += 6.0
	var rise: float = minf(crest - foot_y, cut_height_m)
	# Sub 2 m nu e taietura, e prag: acolo nu exista masiv de taiat.
	if rise < 2.0:
		return []
	var out: Array = []
	for r in cut_bands + 1:
		var t := float(r) / float(cut_bands)
		# r = 0 e COAMA (sus), deci inaltimea scade cu t.
		var y := foot_y + rise * (1.0 - t)
		# Retragerea: coama sta mai in spate decat talpa (taietura e batuta usor
		# in spate, ca orice sapatura care nu se surpa).
		var back := cut_batter_m * (1.0 - t)
		var q: Vector3 = p + sd * (cut_offset_m + back)
		out.append(Vector3(q.x, y, q.z))
	return out


static func _collect(node: Node, out: Array[CliffFace]) -> void:
	for child in node.get_children():
		if child is CliffFace:
			out.append(child as CliffFace)
		_collect(child, out)


## Panza de faleza pentru ACEST nod.
##
## Forma, pe scurt: pentru fiecare pas pe lungimea cornisei se ridica o COLOANA
## de vertecsi, de la buza (langa asfalt) pana la talpa (in teren). Coloanele
## vecine se unesc in quad-uri. Fiecare banda isi are retragerea ei laterala,
## deci peretele iese in trepte de strat, nu ca un plan.
##
## Ce NU face: nu atinge terenul si nu atinge campul. E geometrie asezata PESTE
## ele, exact ca un prop — de aceea nu poate strica nici ProbeBuried (care
## intreaba campul despre drum), nici ProbeLayout (care masoara traseul).
func _build(sampler: TrackSideSampler, surface_y: Callable) -> Node3D:
	var total := sampler.total_length()
	if total <= 0.0 or bands < 1 or band_slots.is_empty():
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var span := (frac_end - frac_start) * total
	var steps := maxi(int(round(span / maxf(step_m, 0.5))), 2)
	# Coloanele, calculate o data: fiecare e lista de puncte de sus in jos.
	var cols: Array = []
	for s in steps + 1:
		var f := frac_start + (frac_end - frac_start) * (float(s) / float(steps))
		cols.append(_column(sampler, f, surface_y))

	for s in steps:
		var a: Array = cols[s]
		var b: Array = cols[s + 1]
		var rows: int = mini(a.size(), b.size())
		for r in rows - 1:
			# Slotul benzii: randul 0 e coama. Culoarea vine din UV (atlas), nu
			# dintr-un material — de asta faleza costa zero materiale.
			var slot: int = band_slots[mini(r, band_slots.size() - 1)]
			var uvv := Palette.uv(slot)
			# AO copt in vertex color: fata se intuneca in jos, fiindca vertex
			# color poate DOAR sa intunece (memoria
			# `surfacetool-clamp-vertex-color`). Coama ramane la 1.0.
			var t0 := float(r) / float(rows - 1)
			var t1 := float(r + 1) / float(rows - 1)
			var c0 := _shade(t0)
			var c1 := _shade(t1)
			_quad(st, a[r], b[r], b[r + 1], a[r + 1], uvv, c0, c0, c1, c1)

	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Faleza " + name
	mi.mesh = st.commit()
	mi.material_override = Palette.world_material()
	# POLITELE primesc CORP FIZIC. Fara el ar fi un desen: tarusul n-ar avea pe
	# ce sta, iar razele sondei ar trece prin ele si verdictul ar ramane rosu cu
	# dreptate. O cutie per polita, nu un trimesh pe toata panza — faleza n-are
	# nevoie de coliziune (peste buza se cade in gol, aia e mecanica POI-ului C),
	# doar pragul are.
	for lf in ledge_fracs:
		var body := _ledge_body(sampler, lf)
		if body != null:
			mi.add_child(body)
	# Umbrele lungi de zori sunt identitatea Cappadociei (tema `shadows: true`),
	# iar o faleza de 30 m e cel mai mare obiect care arunca pe vale.
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi


## Peretele DE DINCOLO de vale: masa de stanca pe care o vede efectiv soferul.
##
## Forma: pentru fiecare pas pe lungimea cornisei se ridica o coloana la rulajul
## `far_offset_m`, de la fundul vaii in sus pana la `far_height_m`. Fata se uita
## INAPOI spre drum (de aici semnul din `_quad`), deci normala ei bate in
## privire — opusul panzei de la buza, care sta pe muchie.
##
## Se citeste fundul vaii cu `surface_y` in loc sa fie presupus: valea are cota
## proprie (~13.7 m masurat) si se schimba pe lungime.
##
## Talpa intra in teren cu `foot_bite_m`, ca la panza de buza: fara asta ramane
## o fanta luminoasa exact pe linia in care ochiul cauta contactul.
func _build_far(sampler: TrackSideSampler, surface_y: Callable) -> Node3D:
	var total := sampler.total_length()
	if total <= 0.0 or far_bands < 1 or band_slots.is_empty():
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var span := (frac_end - frac_start) * total
	var steps := maxi(int(round(span / maxf(far_step_m, 1.0))), 2)
	var cols: Array = []
	var caps: Array = []
	for si in steps + 1:
		var f := frac_start + (frac_end - frac_start) * (float(si) / float(steps))
		cols.append(_far_column(sampler, f, surface_y))
		caps.append(_far_cap(sampler, f, surface_y))
	var built := 0
	for si in steps:
		var a: Array = cols[si]
		var b: Array = cols[si + 1]
		# Coloanele goale sunt pasii unde nu exista vale de sprijinit (vezi
		# `_far_column`): acolo pintenul se intrerupe, si asta e corect — o masa
		# continua ar traversa si portiunile in care drumul merge pe platou.
		if a.is_empty() or b.is_empty():
			continue
		built += 1
		var rows: int = mini(a.size(), b.size())
		for r in rows - 1:
			var slot: int = band_slots[mini(r, band_slots.size() - 1)]
			var uvv := Palette.uv(slot)
			# AO: coama prinde soarele razant de zori, talpa intra in umbra ei.
			var t0 := float(r) / float(rows - 1)
			var t1 := float(r + 1) / float(rows - 1)
			var c0 := _shade(t0)
			var c1 := _shade(t1)
			_quad(st, b[r], a[r], a[r + 1], b[r + 1], uvv, c0, c0, c1, c1)
		# COAMA, in continuarea buzei: acelasi slot ca banda de sus, ca sa se
		# citeasca drept acelasi bloc de roca vazut de deasupra.
		var ca: Array = caps[si]
		var cb: Array = caps[si + 1]
		if not ca.is_empty() and not cb.is_empty():
			# Coama NU ia band_slots[0].
			#
			# Slotul 0 e cremul de coama (19 CORAL_SAND) si masurat cu ProbeSlots
			# sta la saturatie 0.17, adica practic alb. Pe fata verticala e o
			# cusatura subtire si e corect acolo; pe COAMA insa acopera cea mai
			# mare suprafata din silueta, si exact asta facea ca pintenul sa iasa
			# o creasta de nisip palid in loc de stanca — captura arata pale, cu
			# numarul de pixeli deja urcat. Coama ia rosul de corp.
			var crows: int = mini(ca.size(), cb.size())
			for r in crows - 1:
				# Coama primeste si ea STRATE, nu o singura culoare.
				#
				# Cu un singur slot, din camera de joc (care o vede in unghi mic,
				# deci pe suprafata mare) iesea o lespede portocalie plata si
				# stergea benzile de pe fata verticala de sub ea. Fasiile de coama
				# merg de la rosul de corp spre umbra, dinspre buza spre vale.
				var cs: int = cap_slots[mini(r, cap_slots.size() - 1)]
				var cuv := Palette.uv(cs)
				var s0 := _shade(0.10 + 0.5 * float(r) / float(crows - 1))
				var s1 := _shade(0.10 + 0.5 * float(r + 1) / float(crows - 1))
				_quad(st, cb[r], ca[r], ca[r + 1], cb[r + 1], cuv, s0, s0, s1, s1)
	if built == 0:
		return null
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Faleza pinten " + name
	mi.mesh = st.commit()
	mi.material_override = Palette.world_material()
	# Pintenul e langa drum si la cota lui: umbra lui de zori cade CHIAR PE BANDA
	# si e cel mai ieftin semn ca acolo e o masa solida, nu o textura.
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi


## O coloana din PINTEN: fata rosie dinspre drum, plus coama care se intoarce
## spre vale.
##
## Coloana are doua parti, si asta e ce o face sa se citeasca drept stanca si nu
## panou: intai FATA, care urca aproape vertical din vale pana la cota drumului
## (partea pe care o vede soferul, cu stratele in benzi), apoi COAMA, care pleaca
## orizontal spre vale pe `far_depth_m` si se termina cazand inapoi in teren.
## Fara coama, masa ar fi o lama de un triunghi grosime vazuta din masina.
func _far_column(sampler: TrackSideSampler, f: float, surface_y: Callable) -> Array:
	var n := sampler.point_count()
	var i := clampi(int(round(f * float(n))) % n, 0, n - 1)
	var p := sampler.baked_point(i)
	var sd := sampler.side_at(i) * signf(side)
	var base: Vector3 = p + sd * far_offset_m
	var floor_y: float = surface_y.call(base.x, base.z)
	# Coama: la cota soselei plus `far_rise_m`. Peste orizontul marginii (-59 gr)
	# prin constructie, deci vizibila — vezi nota de la `far_wall`.
	var top_y := p.y + far_rise_m
	if far_bank:
		# MALUL DE DINCOLO: masa nu mai e legata de cota soselei, ci sta pe
		# terenul de acolo — rapa are acum latime, deci dincolo de ea terenul
		# chiar urca. Coama se ridica peste creasta LUI, nu peste drum.
		#
		# Diferenta nu e cosmetica: un pinten legat de cota drumului si asezat la
		# 15 m e o dunga langa roata (exact ce a picat in runda 3), pe cand o masa
		# asezata pe malul opus umple partea dreapta a cadrului asa cum o face
		# referinta, cu valea intre ea si privitor.
		#
		# Rulajul e FIX, si asta e o corectie platita cu o incercare.
		#
		# Varianta dinainte cauta creasta terenului la fiecare pas, fiindca
		# ProbeBank aratase ca malul sta la 60 m pe o fractie si la 110 m pe
		# alta. Cautarea gasea insa si zgomotul dunelor: offsetul sarea 37 ->
		# 109 -> 37 -> 49 -> 163 m intre coloane vecine, iar panza iesea o
		# panglica sifonata in zig-zag, nu un perete. Se vede in ansamblul de
		# sus, si explica de ce ridicarea coamei n-a schimbat nimic in pixeli:
		# coloane care se departeaza una de alta nu formeaza suprafata, ci
		# fatete rasucite care se vad pe muchie.
		#
		# Un mal de vale e o LINIE, deci se cere ca linie: rulaj constant, si
		# cota luata din cea mai inalta valoare pe o fereastra scurta in jurul
		# lui, ca sa urmeze relieful fara sa sara dupa fiecare dună.
		var crest_y := -1e9
		var probe := -12.0
		while probe <= 12.0:
			var q := p + sd * (far_offset_m + probe)
			crest_y = maxf(crest_y, surface_y.call(q.x, q.z))
			probe += 6.0
		base = p + sd * far_offset_m
		top_y = crest_y + far_rise_m
		# INALTIMEA nu e de gust, se DERIVA din linia privirii.
		#
		# Masurat cu ProbeBank: cu coama pe creasta terenului, malul sta la -28
		# grade sub ochi la fractia 0.22, si ProbePixBank confirma consecinta —
		# 0.00% din cadru. O masa care nu urca pana la linia ochiului nu intra in
		# poza, oricat de lata ar fi (AABB-ul ei masura 370 m).
		#
		# Deci coama se ridica pana cel putin la cota ochiului, plus marja: asa
		# masa taie orizontul in loc sa stea sub el, si valea ramane intre ea si
		# privitor — compozitia referintei.
		var eye_y := p.y + far_eye_rise_m
		top_y = maxf(top_y, eye_y + far_over_eye_m)
		# Talpa se cauta INSPRE vale, ca fata sa aiba de unde urca din fund.
		var toe := base - sd * far_depth_m
		floor_y = minf(surface_y.call(base.x, base.z),
			surface_y.call(toe.x, toe.z))
	# Daca terenul de sub pinten e deja la cota drumului, nu exista vale aici si
	# pintenul n-are ce sprijini: se sare peste, ca sa nu iasa o lespede plutind
	# pe platou.
	if floor_y > top_y - 3.0:
		return []
	var out: Array = []
	var rows := far_bands + 1
	# FATA: de sus in jos, cu stratele iesind spre drum ca sa prinda lumina.
	for r in rows:
		var t := float(r) / float(far_bands)
		var y := top_y - (top_y - floor_y) * t
		var stepi := float(int(t * float(far_bands)))
		# fata se evazeaza in jos (versant de tuf, nu perete atarnat)
		var flare := batter_m * (top_y - y) * 0.45
		out.append(base + sd * flare + Vector3(0, y - base.y, 0))
	# TALPA in teren, fara fanta la contact.
	var last: Vector3 = out[rows - 1]
	var gy: float = surface_y.call(last.x, last.z)
	out[rows - 1] = Vector3(last.x, minf(last.y, gy) - foot_bite_m, last.z)
	return out


## Coama pintenului: capacul care il face masa, nu lama. Se construieste ca
## banda separata, de la buza fetei spre vale, cazand in teren la capat.
func _far_cap(sampler: TrackSideSampler, f: float, surface_y: Callable) -> Array:
	var n := sampler.point_count()
	var i := clampi(int(round(f * float(n))) % n, 0, n - 1)
	var p := sampler.baked_point(i)
	var sd := sampler.side_at(i) * signf(side)
	var base: Vector3 = p + sd * far_offset_m
	var floor_y: float = surface_y.call(base.x, base.z)
	var top_y := p.y + far_rise_m
	if far_bank:
		# Aceeasi linie ca in `_far_column`: acelasi rulaj fix, aceeasi fereastra
		# de cota. Coama trebuie sa plece din acelasi punct ca fata, altfel se
		# despart.
		var crest_y := -1e9
		var probe := -12.0
		while probe <= 12.0:
			var q := p + sd * (far_offset_m + probe)
			crest_y = maxf(crest_y, surface_y.call(q.x, q.z))
			probe += 6.0
		base = p + sd * far_offset_m
		top_y = crest_y + far_rise_m
		var eye_y := p.y + far_eye_rise_m
		top_y = maxf(top_y, eye_y + far_over_eye_m)
		floor_y = surface_y.call(base.x, base.z)
	if floor_y > top_y - 3.0:
		return []
	var out: Array = []
	var steps := 4
	for k in steps + 1:
		var u := float(k) / float(steps)
		var q := base + sd * (far_depth_m * u)
		var gy: float = surface_y.call(q.x, q.z)
		# coama coboara lin spre vale si se infige in teren la capat
		var y := lerpf(top_y, maxf(gy, floor_y) - foot_bite_m, u * u)
		out.append(Vector3(q.x, y, q.z))
	return out


## Corpul fizic al unei polite: o cutie la cota si rulajul ei.
func _ledge_body(sampler: TrackSideSampler, lf: float) -> StaticBody3D:
	var n := sampler.point_count()
	var i := clampi(int(round(lf * float(n))) % n, 0, n - 1)
	var p := sampler.baked_point(i)
	var sd := sampler.side_at(i) * signf(side)
	var lip_y := p.y
	var q := p + sd * ledge_offset_m
	var body := StaticBody3D.new()
	body.name = "Polita %.3f" % lf
	# Layer-ul camerei: o polita de 3 m iesita din perete e exact genul de lucru
	# care nu are voie sa stea intre camera si masina fara sa fie vazut.
	body.collision_layer |= Track.CAMERA_BLOCKER_LAYER
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(ledge_depth_m * 2.0, 1.6, ledge_len_m)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(q.x, lip_y - ledge_drop_m - 0.8, q.z)
	body.rotation = Vector3(0.0, atan2(sd.x, sd.z), 0.0)
	return body


## Cat de intunecata e fata la adancimea normalizata `t` (0 = coama, 1 = talpa).
##
## Nu e doar un gradient: la fiecare banda se adauga o cusatura mai inchisa la
## partea ei de sus, ca stratele sa se citeasca ca strate si de la 100 m, unde
## relieful de 0.9 m nu se mai vede.
func _shade(t: float) -> Color:
	# Plaja e ingusta DELIBERAT (1.0 -> 0.78, cusatura 0.92).
	#
	# Vertex color poate doar sa INTUNECE (memoria
	# `surfacetool-clamp-vertex-color`), deci fiecare zecime scoasa aici iese
	# direct din saturatia rosului: cu 0.62 la talpa si 0.88 pe cusatura, cele
	# doua se inmulteau si faceau fata sa cada la ~0.55, adica maro. Referinta
	# tine TOATA fata la saturatie 0.47-0.65 — stratele se citesc din culoare si
	# din relief, nu dintr-un gradient adanc.
	var base := lerpf(1.0, 0.78, clampf(t, 0.0, 1.0))
	var seam := absf(sin(t * float(bands) * PI))
	base *= lerpf(0.92, 1.0, seam)
	return Color(base, base, base)


## O COLOANA de vertecsi la fractia `f`, de la buza in jos pana in teren.
##
## Profilul lateral e ce face diferenta intre „faleza" si „panta": fata cade
## APROAPE vertical (retragere mica per banda), nu in panta de versant. Cifra e
## derivata din constrangerea masurata a baloanelor, nu aleasa estetic — vezi
## `docs/track_briefs/cappadocia_geometrie.md`: un balon ancorat jos urca DREPT,
## deci orice metru cu care peretele se apleaca peste el ii fura din coloana.
## Cu retragerea totala tinuta sub `band_relief_m * bands` (~8 m pe 30 m de
## cadere, adica 15° fata de verticala) coloana de deasupra politei ramane
## libera.
func _column(sampler: TrackSideSampler, f: float, surface_y: Callable) -> Array:
	var n := sampler.point_count()
	var i := clampi(int(round(f * float(n))) % n, 0, n - 1)
	var p := sampler.baked_point(i)
	var sd := sampler.side_at(i) * signf(side)
	var hw := sampler.half_width_at(i)
	var lip := p + sd * (hw + lip_offset_m)
	# Cota BUZEI: la COTA ASFALTULUI, nu sub fusta.
	#
	# Aici a fost pierduta runda 2, si corectia merita scrisa intreaga fiindca
	# rationamentul vechi suna bine si era gresit. Vechea versiune cobora buza
	# cu `ROAD_THICKNESS * 0.72` (2.16 m) ca sa nu se vada fusta de beton intre
	# asfalt si prima banda rosie. Efectul real, masurat cu ProbeOccl: panza
	# intreaga ajungea sub silueta propriului tablier, iar paravanul dominant
	# devenea chiar trimesh-ul soselei (`@StaticBody3D@84`, 336 din 556 de
	# vertecsi in cadru la fractia 0.28, peste TerrainBody). Din camera de
	# urmarire — 10 m deasupra masinii, privind usor in jos — marginea drumului
	# trecea exact peste faleza. De-aia criticul vedea „un fileu convex neted":
	# ala nu era un perete palid, era drumul stand in fata peretelui.
	#
	# Deci buza urca la cota asfaltului. Fusta nu mai e o problema fiindca prima
	# banda o ACOPERA acum, in loc sa inceapa sub ea.
	var lip_y := p.y

	# CAT DE ADANC cade fata. Se CITESTE fundul vaii, nu se presupune.
	var floor_y := lip_y - depth_m
	var far := hw + 4.0
	var prev := lip_y
	while far < hw + 60.0:
		var q := lip + sd * (far - hw - lip_offset_m)
		var gy: float = surface_y.call(q.x, q.z)
		if gy > prev - 0.15 and far > hw + 8.0:
			floor_y = gy
			break
		prev = gy
		far += 1.5
	var drop := maxf(lip_y - floor_y, 6.0)

	# FATA CADE APROAPE VERTICAL, la un rulaj lateral propriu — nu urmareste
	# versantul punct cu punct.
	#
	# A doua incercare chiar il urmarea (`_reach_for`: la ce rulaj are terenul
	# cota randului), si a iesit exact pe dos decat suna: masurat cu terenul
	# stins, panza era o PANGLICA lipita sub marginea drumului, fiindca
	# versantul e de 73-77 grade — la o cadere aproape verticala, TOATE randurile
	# nimeresc practic acelasi rulaj, deci fata are latime zero. Sonda de ecran
	# spunea ca panza acopera 69% din latimea cadrului, si tot nu se vedea rosu:
	# proiectia era mare, suprafata era o ata.
	#
	# Deci fata isi ia rulajul ei si coboara dreapta, cu stratele iesind in
	# trepte. Asta e si forma corecta fizic (o faleza de tuf e un perete, nu o
	# glazura peste panta) si singura care da SUPRAFATA rosie in cadru.
	# POLITA, daca fractia asta cade pe una: peretele iese pe orizontala la cota
	# ei, deci coloana de deasupra ramane libera pe toata cursa balonului.
	var ledge_y := INF
	for lf in ledge_fracs:
		var half_frac := (ledge_len_m * 0.5) / maxf(sampler.total_length(), 1.0)
		if absf(f - lf) <= half_frac:
			ledge_y = lip_y - ledge_drop_m
			break

	var out: Array = []
	var rows := bands + 1
	for r in rows:
		var t := float(r) / float(bands)
		var y := lip_y - drop * t
		# Iesirea in trepte, banda cu banda: muchiile prind lumina razanta de
		# zori si stratele se citesc si de la 100 m.
		var stepi := float(int(t * float(bands)))
		# EVAZAREA: fata se departeaza de drum pe masura ce coboara.
		#
		# Fara ea, o faleza verticala lipita de marginea benzii e ascunsa de
		# propriul tablier pentru un ochi care vine din spate si de sus (vezi
		# nota de la `lip_y`). Cu ea, fiecare banda de mai jos iese cu
		# `batter_m` in lateral fata de cea de deasupra, deci intra in campul
		# vizual pe sub muchia soselei in loc sa stea in umbra ei geometrica.
		#
		# E si forma corecta: un versant de tuf erodat se deschide in jos, nu
		# atarna. Ramane sub limita din brief — evazarea totala
		# (`batter_m * bands`) plus retragerea benzilor nu are voie sa depaseasca
		# `ledge_offset_m`, altfel peretele s-ar apleca peste coloana pe care
		# urca balonul ancorat.
		# `batter_m` e per METRU DE CADERE, nu per banda: masurat cu ProbeReach,
		# frontiera vizibilitatii din camera de joc e o diagonala aproape
		# constanta — la fiecare ~6 m de adancime e nevoie de ~4 m de rulaj ca
		# punctul sa iasa de sub muchia soselei. Deci evazarea trebuie legata de
		# ADANCIME, altfel benzile de jos raman in umbra geometrica a drumului
		# indiferent cate sunt.
		var proud := band_relief_m * stepi + batter_m * (drop * t)
		# Sub cota politei, fata se retrage cu adancimea treptei: asa polita e o
		# treapta reala in perete, nu un raft lipit peste el.
		if ledge_y < INF and y < ledge_y:
			proud += ledge_depth_m
		out.append(lip + sd * proud + Vector3(0, y - lip_y, 0))
	# TALPA intra in teren, ca sa nu ramana fanta la contact.
	var last: Vector3 = out[rows - 1]
	var gy2: float = surface_y.call(last.x, last.z)
	out[rows - 1] = Vector3(last.x, minf(last.y, gy2) - foot_bite_m, last.z)
	return out


## Un quad ca doua triunghiuri, cu UV constant (culoarea slotului) si vertex
## color per colt.
## Ordinea vertecsilor NU e o conventie de gust: cu winding-ul invers, panza
## exista, are 5346 de vertecsi si un AABB corect — dar fiecare fata se uita IN
## stanca. Masurat cu ProbeCliffNormals pe prima versiune: 90 din 90 de fete
## esantionate aveau normala DINSPRE drum, deci culling-ul le stergea pe toate
## exact din locul din care faleza trebuie vazuta. Capturile ieseau identice cu
## cele de dinainte de nod, si e capcana clasica: „nu se vede" arata la fel ca
## „nu s-a construit", dar se repara in alt loc.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		uvv: Vector2, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
	_vert(st, a, uvv, ca)
	_vert(st, c, uvv, cc)
	_vert(st, b, uvv, cb)
	_vert(st, a, uvv, ca)
	_vert(st, d, uvv, cd)
	_vert(st, c, uvv, cc)


func _vert(st: SurfaceTool, v: Vector3, uvv: Vector2, col: Color) -> void:
	st.set_uv(uvv)
	st.set_color(col)
	st.add_vertex(v)
