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
@export var band_slots: Array[int] = [19, 23, 10, 27, 23, 10, 27, 4, 2]

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
		var mesh_node := f._build(sampler, surface_y)
		if mesh_node != null:
			root.add_child(mesh_node)
	return root


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
	var base := lerpf(1.0, 0.62, clampf(t, 0.0, 1.0))
	var seam := absf(sin(t * float(bands) * PI))
	base *= lerpf(0.88, 1.0, seam)
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
