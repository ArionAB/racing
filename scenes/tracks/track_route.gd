class_name TrackRoute
extends RefCounted
## O banda de asfalt pe care se poate conduce: bucla principala sau o scurtatura.
##
## Pana la Okinawa, "traseul" era o singura [Curve3D] inchisa, iar TOT progresul
## din joc — tururi, pozitii, checkpoint-uri, tinta AI-ului, penalizarea de
## offroad — se calcula ca index in punctele ei coapte. Un al doilea petec de
## asfalt nu era pur si simplu ignorat: era tratat activ ca teren de langa drum,
## deci masina de pe el mergea la 45% viteza, isi pierdea checkpoint-ul, iar
## AI-ul se credea blocat si dadea cu spatele.
##
## O ruta e acelasi lucru pentru codul de progres, dar declarat explicit.
##
## [b]Cheia care face totul sa functioneze[/b] e [method frac_at]. O masina de la
## jumatatea scurtaturii raporteaza aceeasi fractie de tur ca una de la jumatatea
## portiunii ocolite. Adica: scurtatura iti da TIMP, nu progres — ceea ce e si
## corect ca design, si motivul pentru care numaratoarea de tururi si clasamentul
## din [code]race.gd[/code] raman NEATINSE, inclusiv clamp-ul anti-cut de ±0.5.

## Punctele coapte ale axei, la ~[code]bake_interval[/code] metri unul de altul.
var baked: PackedVector3Array
## Distanta cumulata pana la fiecare punct copt. Are un element in plus fata de
## [member baked]: ultimul e lungimea totala.
var dists: PackedFloat32Array
## Jumatatea latimii benzii. Scurtatura poate fi mai lata sau mai ingusta decat
## bucla principala.
var half_width: float = 7.0
## Bucla principala se inchide; o scurtatura are capete.
var closed: bool = true
## Unde se desprinde si unde revine, ca fractii din bucla PRINCIPALA. Ignorate
## pentru ruta 0.
var entry_frac: float = 0.0
var exit_frac: float = 0.0
## Banda e permanent uda: cine merge pe ea are grip lateral taiat.
##
## Asta e CONTRAGREUTATEA scurtaturii, nu decor. Fara ea, bancul de nisip e 83 m
## cadou pe tur — masurat de tools/probe_layout.gd — si nu mai exista nicio
## decizie de luat: il iei mereu. Cu grip-ul taiat, il iei cand ai linia curata
## si il eviti cand esti in trafic sau cu masina grea.
var wet: bool = false
## Numele afisat in sonde si in mesaje de eroare.
var label: String = "principal"

## ---------------------------------------------------------------- suprafata
## Ce fel de suprafata are banda: "sand" (bancul de nisip din Okinawa, banda
## plata de pana acum), "dirt_road" (drum de tara: fagase, brazda de iarba,
## margini care se topesc in pajiste) sau "gravel" (pietris batatorit, fara
## fagase). Ruta 0 nu citeste campul asta — soseaua isi are generatorul ei.
##
## Cheile de mai jos sunt PARAMETRII retetei "dirt_road"; celelalte retete le
## ignora. Vezi Track._build_branch_surfaces pentru ce face fiecare.
var surface: String = "sand"
## Adancimea fagaselor (m). 0 = fara fagase.
var rut_depth: float = 0.04
## Cat de inierbata e brazda dintre fagase (0 = pamant, 1 = iarba plina).
var grass_center: float = 0.6
## Amplitudinea zdrentuirii marginilor (m). 0 = margini taiate cu rigla.
var edge_noise: float = 0.8
## Amplitudinea denivelarilor de rulare (m). 0 = neted; peste 0 intra SI in
## coliziune, deci suspensia le simte.
var bumpiness: float = 0.0
## Plafonul de viteza pe banda, ca fractie din viteza maxima (1 = neatins).
## A treia contragreutate, dupa `wet` si latime: un drum de tara e mai LENT.
var speed_factor: float = 1.0
## Banda sta IN AER (telecabina, pasarela): terenul nu o urmareste — nici nu
## se ridica sub ea, nici nu se sapa. Vezi Track._branch_corridor_points.
var elevated: bool = false
## Culoarea pamantului. Alfa 0 = se ia din tema (`branch_tint`).
var tint: Color = Color(0.0, 0.0, 0.0, 0.0)
## Smocuri de iarba pe margini si pe brazda (doar "dirt_road").
var tufts: bool = true
## Banda isi aduce singura carosabilul: pista NU ii mai construieste o
## suprafata.
##
## Exista pentru rampa de serviciu a pasajului rotativ (Chongqing): geometria
## ei — asfalt, marcaje, parapeti, pana pavata dinspre pasaj — o emite chiar
## nodul de hazard, fiindca ea se muleaza pe golul din carosabil pe care tot
## el il cere. Ce ii lipsea era doar sa fie CUNOSCUTA ca drum. O a doua foaie
## pusa de `Track._build_branch_surfaces` peste cea existenta ar fi z-fighting
## pe toata lungimea si un al doilea rand de parapeti.
var no_surface: bool = false
## Banda e o PEDEAPSA, nu o scurtatura: pilotul nu are voie sa fie atras spre
## ea de la sine ([code]Track.branch_lure[/code]).
##
## Toate benzile secundare de pana acum au fost scurtaturi — le iei ca sa
## castigi — deci momeala era mereu corecta. Ocolul pasajului rotativ e pe dos:
## il iei doar cand banda directa e inchisa, si costa +3 s cand o faci. Un AI
## momit pe el cu pasajul deschis ar plati pedeapsa degeaba, iar cine decide
## chiar e `AiController._span_line`, care citeste CEASUL hazardului.
##
## Ce ramane neschimbat e [code]Track.resolve_route[/code]: cine ajunge fizic
## pe banda (imbrancit de poarta, sau mutat acolo de pilot) primeste progres pe
## ea. Fara asta, exact masina care a facut ce trebuia ar fi fost pedepsita ca
## si cum ar fi iesit de pe sosea.
var detour: bool = false


func count() -> int:
	return baked.size()


func length() -> float:
	return dists[baked.size()] if dists.size() > baked.size() else 0.0


## Directia laterala (dreapta fata de sensul de mers) la un index.
func side_at(i: int) -> Vector3:
	var n := baked.size()
	if n < 2:
		return Vector3.RIGHT
	var j := (i + 1) % n if closed else mini(i + 1, n - 1)
	var k := i
	if not closed and i == n - 1:
		k = n - 2
		j = n - 1
	var dir := (baked[j] - baked[k]).normalized()
	return dir.cross(Vector3.UP).normalized()


## Indexul valid cel mai apropiat: bucla se inchide, scurtatura se opreste.
##
## NU se poate numi `wrap`: GDScript are deja o functie globala cu numele asta
## (`wrap(value, min, max)`), iar redefinirea ei da eroare de parsare.
func wrap_index(i: int) -> int:
	var n := baked.size()
	if n == 0:
		return 0
	if closed:
		return ((i % n) + n) % n
	return clampi(i, 0, n - 1)


## Fractia de tur raportata de un index de pe ruta asta.
##
## Pentru bucla principala e chiar pozitia pe ea. Pentru o scurtatura e o
## interpolare intre fractia de intrare si cea de iesire — vezi antetul clasei
## pentru de ce asta e piesa care tine clasamentul corect.
##
## Cazul in care scurtatura trece peste linia de start ([code]exit < entry[/code])
## e tratat prin desfasurare peste 1.0 si readucere cu fposmod. Fara asta, o
## scurtatura asezata peste sosire ar raporta fractii care merg INAPOI, iar
## clamp-ul de ±0.5 din race.gd le-ar citi ca tur pierdut.
func frac_at(i: int) -> float:
	var n := baked.size()
	if n == 0:
		return 0.0
	if closed:
		return float(i) / float(n)
	if n == 1:
		return entry_frac
	var t := float(clampi(i, 0, n - 1)) / float(n - 1)
	var span := exit_frac - entry_frac
	if span < 0.0:
		span += 1.0
	return fposmod(entry_frac + span * t, 1.0)


## Distanta 2D (XZ) de la o pozitie la punctul copt dat.
func lateral_distance(i: int, pos: Vector3) -> float:
	var p := baked[wrap_index(i)]
	return Vector2(pos.x - p.x, pos.z - p.z).length()


## Cat de jos SUB cota drumului mai esti „pe el". Masina sta cu originea
## deasupra asfaltului, deci orice cadere sub el inseamna alt etaj sau gol.
const ROAD_BELOW_TOLERANCE: float = 2.5
## Cat de sus DEASUPRA drumului mai esti „pe el": in aer, dupa un kicker, tot
## drumul asta te asteapta jos. Larg, ca sariturile sa nu taie viteza.
## Pe un etaj de deasupra la peste atat nu mai esti pe drumul de jos.
const ROAD_ABOVE_TOLERANCE: float = 12.0


## Pe sosea = in banda LATERAL si la cota ei VERTICAL.
##
## Testul era doar 2D (XZ), si asta ajungea cat timp pista nu trecea peste ea
## insasi. Cu un pasaj la 15 m peste un alt tronson, o masina cazuta pe etajul
## de jos care inca tine indexul etajului de sus era „pe sosea" — isi innoia
## checkpoint-ul pe etajul de SUS si repunerea urmatoare era un cadou.
func is_on_road(i: int, pos: Vector3) -> bool:
	if lateral_distance(i, pos) > half_width + 0.5:
		return false
	return not is_other_level(i, pos)


## E pozitia la ALT etaj decat punctul copt dat? Consumat de Car la aterizare,
## ca sa stie cand fereastra locala de index nu mai ajunge.
func is_other_level(i: int, pos: Vector3) -> bool:
	var dy := pos.y - baked[wrap_index(i)].y
	return dy < -ROAD_BELOW_TOLERANCE or dy > ROAD_ABOVE_TOLERANCE


## Cel mai apropiat index, cautat LOCAL in jurul celui precedent.
##
## Fereastra asimetrica (mai mult inainte decat inapoi) e anti-cut-ul real al
## jocului: indexul nu poate teleporta, deci nici fractia de tur.
func closest_index(from_index: int, pos: Vector3) -> int:
	var n := baked.size()
	if n == 0:
		return 0
	var best := wrap_index(from_index)
	var best_d := pos.distance_squared_to(baked[best])
	for off in range(-8, 25):
		var idx := wrap_index(from_index + off)
		var d := pos.distance_squared_to(baked[idx])
		if d < best_d:
			best_d = d
			best = idx
	return best


## Scanare completa. Scumpa — doar la spawn, la repunere si la schimbarea rutei.
func closest_index_global(pos: Vector3) -> int:
	var best := 0
	if baked.is_empty():
		return 0
	var best_d := pos.distance_squared_to(baked[0])
	for i in baked.size():
		var d := pos.distance_squared_to(baked[i])
		if d < best_d:
			best_d = d
			best = i
	return best


## Punct-tinta pentru AI: cu [code]ahead_m[/code] mai in fata, deplasat lateral.
##
## [code]half_width_override[/code] e latimea de la indexul TINTA, cand pista are
## profil pe sectoare. Negativ (implicit) = latimea benzii, ca inainte.
##
## Contează pe cine intreaba: AI-ul isi alege linia cu cateva zeci de metri in
## fata, deci pe o strangere linia calculata cu latimea de ACUM ar tinti langa
## asfaltul de ACOLO — masina ar intra in perete tinand exact linia ceruta.
func lookahead_point(i: int, ahead_m: float, lateral_frac: float,
		bake_interval: float, half_width_override: float = -1.0) -> Vector3:
	var steps := int(ahead_m / maxf(bake_interval, 0.001))
	var idx := wrap_index(i + steps)
	var hw := half_width_override if half_width_override >= 0.0 else half_width
	return baked[idx] + side_at(idx) * lateral_frac * hw


## Punctul de repunere: centrul benzii, cu `backoff_m` INAINTE de index.
func recovery_transform(i: int, backoff_m: float) -> Transform3D:
	var n := baked.size()
	var spacing := length() / float(maxi(n, 1))
	var idx := wrap_index(i - int(backoff_m / maxf(spacing, 0.001)))
	var nxt := wrap_index(idx + 1)
	if nxt == idx:
		nxt = wrap_index(idx - 1)
	var dir := (baked[nxt] - baked[idx]).normalized()
	if dir.length_squared() < 0.5:
		dir = Vector3.FORWARD
	return Transform3D(Basis.looking_at(dir, Vector3.UP),
		baked[idx] + Vector3.UP * 1.2)


## Coace punctele si distantele dintr-o lista de puncte de control.
##
## Aceeasi retea de tangente ca bucla principala (Catmull-Rom cu factor 0.22),
## ca scurtatura sa aiba exact acelasi caracter de curba — altfel s-ar simti ca
## alt joc pentru cateva secunde.
static func from_points(points: Array[Vector3], is_closed: bool,
		bake_interval: float = 3.0) -> TrackRoute:
	var route := TrackRoute.new()
	route.closed = is_closed
	var curve := Curve3D.new()
	curve.bake_interval = bake_interval
	var n := points.size()
	if n < 2:
		route.baked = PackedVector3Array(points)
		route.dists = PackedFloat32Array([0.0, 0.0])
		return route
	var last := n + 1 if is_closed else n
	for i in last:
		var p := points[i % n]
		var prev := points[(i - 1 + n) % n] if is_closed \
			else points[maxi(i - 1, 0)]
		var nxt := points[(i + 1) % n] if is_closed \
			else points[mini(i + 1, n - 1)]
		var tangent := (nxt - prev) * 0.22
		curve.add_point(p, -tangent, tangent)
	route.baked = curve.get_baked_points()
	if is_closed and route.baked.size() > 1 \
			and route.baked[0].distance_to(
				route.baked[route.baked.size() - 1]) < 0.5:
		route.baked.remove_at(route.baked.size() - 1)
	route.dists = PackedFloat32Array()
	route.dists.resize(route.baked.size() + 1)
	route.dists[0] = 0.0
	for i in route.baked.size():
		var j := (i + 1) % route.baked.size() if is_closed \
			else mini(i + 1, route.baked.size() - 1)
		route.dists[i + 1] = route.dists[i] + route.baked[i].distance_to(
			route.baked[j])
	return route
