extends Node
## GARDA: e carosabilul INGROPAT sub teren, pe oricare pista?
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeBuried.tscn
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeBuried.tscn -- --track=6
##
## Fara `--track` baleiaza TOATE pistele din GameState.TRACK_SCENES si
## raporteaza; iese cu 0 orice ar gasi, ca sa poata fi rulata ca inventar.
## Cu `--track=N` verifica o singura pista si iese cu 1 daca e ingropata —
## forma in care se pune in CI.
##
## [b]De ce exista.[/b] Pe Cappadocia elicea — chiar gimmick-ul pistei — a stat
## ingropata sub 38 m de tuf, si a trecut prin TOATE sondele existente:
## `probe_layout` citeste doar curba (lungime, raza, panta, separare), deci nu
## stie ca exista teren; `probe_capp_peaks` verifica doar ca masivele URCA, nu si
## ca urca PE LANGA drum in loc de PRIN el; `probe_helix` masoara panta, care
## ramane exact aceeasi si cand drumul e sapat in piatra plina. Niciuna nu punea
## intrebarea "e pamant peste asfalt?", fiindca fiecare masura altceva. Vezi
## docs/carosabil_ingropat.md.
##
## ------------------------------------------------------------------ REGULA
##
## Intrebarea e mai subtila decat "e ceva deasupra masinii?", fiindca raspunsul
## corect e uneori DA: un tunel are tavan, un pasaj are tablier, iar orasul
## subteran din brieful Cappadociei e o caverna intreaga peste care sta stanca.
## O garda care tipa la tunel n-ar fi folosita de nimeni, deci ar fi inutila.
##
## Regula are DOUA conditii, si amandoua au fost platite cu masuratori:
##
##   (a) se intreaba doar TERENUL (nodul `TerrainBody`), nu orice solid;
##   (b) se intreaba daca spatiul in care sta CAROSERIA (1 m peste asfalt) e
##       ocupat de teren — `intersect_point`, nu numaratoare de fete. Daca da,
##       masina e in piatra. Daca nu, dar exista teren deasupra, e bolta si pe
##       sub bolta se conduce.
##
## [b]De ce (a).[/b] Prima versiune intreba orice corp fizic, si a raportat
## „ingropare" pe TOATE cele 7 piste. Verificate una cate una, niciuna nu era
## teren: poarta de start de pe Dunele, tablierul mobil LiftSpan de pe Okinawa,
## trenul PathMover de pe Baikal, poarta pasajului rotativ de pe Chongqing, iar
## pe Cappadocia chiar fusta spiralei de deasupra. Alea sunt obstacole si
## suprafete de drum — le ocolesti, treci pe sub ele, sau te lovesti de ele ca
## de un obstacol cinstit. Niciunul nu e „masina intra intr-un perete de tuf".
## O garda care le numara pe toate ar fi fost rosie din prima zi si stinsa in a
## doua.
##
## [b]De ce (b) e un test de INTERIOR, nu de fete.[/b] A doua versiune aduna
## fetele de teren dintr-un raycast de sus in jos si lua cea mai de jos. A fost
## masurata gresit chiar pe cazul pentru care exista: pe elicea ingropata dadea
## 6 puncte la +4.04 m, cand campul (`probe_capp_bury`) vedea 150 la +35.61 m.
## Motivul e ca acolo unde drumul e in piatra PLINA nu mai exista nicio fata
## intre stanca si asfalt — raza se opreste sus, si punctul iese „curat". Adica
## exact ingroparea grava scapa, iar garda ar fi fost verde pe bug-ul ei.
## Cu `intersect_point`, A/B-ul iese cum trebuie: fara `TerrainHollow`
## 153 de puncte la +35.49 m si cod 1, cu el 0 puncte si cod 0.
##
## [b]Limitele, cinstit.[/b]
##
## 1. Un tunel de teren mai scund decat `CLEAR_M` iese raportat ca ingropare.
##    Deliberat: masina are ~1.5 m, deci la 4.5 m trece lejer, iar o bolta pe
##    care o freci cu capul e oricum un bug de pista, doar cu alt nume.
## 2. Consecinta lui (a): o stanca sculptata ca PROP (un GLB, nu campul de
##    inaltime) care ar ingropa drumul trece pe langa garda. Am ales asa in
##    cunostinta de cauza — accidentul de clasa e campul de inaltime care umple
##    un volum, fiindca terenul e singurul lucru care se genereaza singur si
##    poate creste peste drum fara ca cineva sa fi pus ceva acolo. Un prop e
##    intotdeauna asezat de mana, si se vede pe snapshot.
## 3. Se testeaza AXA benzii, nu toata latimea. O limba de teren care intra doar
##    peste banda din dreapta trece nedetectata.
## 4. Masoara MESH-ul cu coliziune, nu campul `ground_y`. Aia e si ideea: campul
##    e sursa, dar cu roata intri in triunghiuri. `probe_capp_bury` ramane
##    pentru sursa; asta e pentru rezultat.
## 5. Ramura de „bolta" (`tavane`) e scrisa, dar azi nu o exercita nicio pista:
##    pe toate cele 7 numaratoarea iese 0, fiindca niciuna n-are inca TEREN
##    deasupra drumului — stanca goala chiar e goala, iar tablierele Chongqingului
##    sunt corpuri de sosea, nu teren. Exista pentru orasul subteran din brief,
##    si pana atunci nu e verificata pe date reale. Cine il construieste sa se
##    uite intai la cifra asta: daca sare pe zero, regula tine.
## 6. Se bazeaza pe faptul ca trimesh-ul terenului raspunde la `intersect_point`
##    pentru puncte din interiorul lui (masurat: da, cu `backface_collision`).
##    Daca vreodata se schimba motorul de fizica sau se stinge backface-ul,
##    testul poate deveni tacut — atunci A/B-ul din antet e reteta de reverificat.

## Cat aer trebuie sa fie peste asfalt ca ce urmeaza sa fie "tavan", nu "piatra".
## Sub atat, punctul se raporteaza ca ingropat.
const CLEAR_M: float = 4.5
## De la ce inaltime peste asfalt se cauta in jos. Trebuie sa fie peste orice
## ingropare plauzibila: pe Cappadocia cea mai adanca masurata a fost 38 m, deci
## 80 m lasa marja si ramane sub cerul oricarei piste.
const PROBE_UP: float = 80.0
## Toleranta la contactul cu carosabilul insusi: racordul teren-asfalt are
## grosime, la fel ca in probe_branch/probe_overpass.
const TOL: float = 0.15
## De la ce adancime un punct se numara ca "ingropat" in verdict. Sub un metru
## sunt cusaturi de racord, nu pereti.
const BURY_M: float = 1.0
## Cate straturi solide se strapung intr-un punct inainte sa se renunte. Stanca,
## tavan de caverna si tablier peste el inseamna deja 3; 12 e marginea care
## opreste o geometrie patologica sa invarta sonda la nesfarsit.
const MAX_LAYERS: int = 12
## Cu cat se coboara pornirea razei sub fiecare contact, ca sa se caute mai jos.
## Trebuie sa fie mai mult decat zero (altfel raza reporneste chiar pe fata si o
## reloveste) si mai putin decat grosimea celei mai subtiri boltii pe care vrem
## sa o vedem ca tavan.
const STEP_DOWN: float = 0.05
## La ce inaltime peste asfalt se intreaba "e teren aici?". Cat caroseria: la
## firul drumului ar raspunde afirmativ orice cusatura de racord.
const PROBE_IN: float = 1.0
## Numele corpului de coliziune al terenului — vezi Track._build_terrain.
## Terenul e UN singur corp per pista, si e singurul lucru pe care garda il
## judeca. Daca se redenumeste vreodata, garda tace in loc sa minta: de-aia
## `_terrain_bodies` avertizeaza cand nu gaseste nimic.
const TERRAIN_BODY: String = "TerrainBody"


func _ready() -> void:
	await get_tree().process_frame
	var only := -1
	var explicit := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = GameState.resolve_track_index(
				int(arg.trim_prefix("--track=")))
			explicit = true
			if only < 0:
				push_error("ProbeBuried: index de pista invalid")
				get_tree().quit(1)
				return

	var failed: Array[String] = []
	for idx in GameState.TRACK_SCENES.size():
		if explicit and idx != only:
			continue
		var bad := await _check(idx)
		if bad:
			failed.append(GameState.TRACK_NAMES[idx])

	print("")
	if failed.is_empty():
		print("VERDICT: OK — niciun carosabil ingropat")
	else:
		print("VERDICT: PROBLEMA pe %s" % ", ".join(failed))
	# Iese cu 1 doar cand s-a cerut o pista anume: asa `--track=N` e garda de CI,
	# iar rularea fara argument ramane un inventar care raporteaza tot fara sa
	# pice build-ul pe piste vechi cat timp inca sunt de reparat.
	get_tree().quit(1 if (explicit and not failed.is_empty()) else 0)


## Verifica o pista; intoarce true daca vreo banda e ingropata.
func _check(idx: int) -> bool:
	var scene := load(GameState.TRACK_SCENES[idx]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var space := track.get_world_3d().direct_space_state
	print("")
	print("=== %s ===" % GameState.track_label(idx))
	var terrain := _terrain_bodies(track)
	if terrain.is_empty():
		# Nu se raporteaza OK pe tacere: fara teren de interogat, garda n-a
		# verificat nimic, si o pista "curata" fiindca sonda e oarba e chiar
		# accidentul pe care il prevenim.
		print("  ATENTIE: nu s-a gasit niciun %s — nu s-a verificat nimic"
			% TERRAIN_BODY)
		track.queue_free()
		await get_tree().process_frame
		return false

	var any_bad := false
	for ri in track.routes.size():
		var r: TrackRoute = track.routes[ri]
		if r.elevated:
			# Banda in aer (telecabina, pasarela) nu are teren dedesubt prin
			# constructie — vezi TrackRoute.elevated. Nu are ce sa o ingroape.
			print("  [%s] banda in aer — se sare" % r.label)
			continue
		var n := r.baked.size()
		var buried := 0
		var worst := 0.0
		var worst_f := 0.0
		var ceilings := 0
		# Intervalele ingropate, ca perechi de fractii.
		var runs: Array[Vector2] = []
		var run_start := -1.0
		var run_end := -1.0
		for i in n:
			var p: Vector3 = r.baked[i]
			var depth := _depth_at(space, p, terrain)
			if depth < 0.0:
				# -1 = s-a lovit ceva, dar peste plafonul de degajare: tavan.
				ceilings += 1
			if depth > worst:
				worst = depth
				worst_f = r.frac_at(i)
			if depth > BURY_M:
				buried += 1
				var f := r.frac_at(i)
				if run_start < 0.0:
					run_start = f
				run_end = f
			elif run_start >= 0.0:
				runs.append(Vector2(run_start, run_end))
				run_start = -1.0
		if run_start >= 0.0:
			runs.append(Vector2(run_start, run_end))

		print("  [%s] puncte %d | ingropate >%.0f m: %d | tavane: %d"
			% [r.label, n, BURY_M, buried, ceilings])
		print("       cel mai adanc %+.2f m la frac %.3f" % [worst, worst_f])
		if not runs.is_empty():
			var parts: Array[String] = []
			for v in runs:
				parts.append("%.3f-%.3f" % [v.x, v.y])
			print("       intervale ingropate: %s" % ", ".join(parts))
		if buried > 0:
			any_bad = true

	track.queue_free()
	await get_tree().process_frame
	return any_bad


## Corpurile de coliziune ale terenului. Lista, nu unul singur: pistele isi pot
## construi terenul din mai multe felii, si atunci toate sunt teren.
##
## Se tin NODURILE, nu RID-urile lor: `intersect_ray` intoarce in "rid" RID-ul
## din serverul de fizica, care nu e acelasi obiect cu `StaticBody3D.get_rid()`,
## deci o comparatie pe RID nu se potrivea niciodata si garda iesea OK peste tot
## — inclusiv pe elicea despre care stiam sigur ca fusese ingropata. "collider"
## intoarce chiar nodul, si ala se compara fara ambiguitate.
func _terrain_bodies(track: Track) -> Array[Node]:
	var out: Array[Node] = []
	for node in track.find_children("*", "StaticBody3D", true, false):
		if node.name.begins_with(TERRAIN_BODY):
			out.append(node)
	return out


## Cat de ingropat e un punct de asfalt, socotind DOAR terenul.
## > 0 = metri de piatra peste el; 0 = cer liber; -1 = teren deasupra, dar cu
## degajare sub el (bolta pe sub care se conduce).
##
## [b]Testul de baza e „e cineva INAUNTRU?", nu numaratoarea de fete.[/b] Prima
## versiune aduna fetele de teren dintr-un raycast de sus in jos si a fost
## masurata gresit tocmai pe cazul pentru care exista: pe elicea ingropata
## raporta 6 puncte la +4.04 m, cand campul (`probe_capp_bury`) vedea 150 la
## +35.61 m. Motivul: acolo unde drumul e in piatra PLINA, raza care coboara nu
## mai gaseste nicio fata intre stanca si asfalt — se opreste sus si punctul iese
## „curat". Adica exact ingroparea grava era cea care scapa.
##
## `intersect_point` la inaltimea masinii raspunde direct la intrebarea care ne
## intereseaza: e spatiul in care sta caroseria ocupat de teren? Peste el se pune
## raza doar ca sa se afle CAT de groasa e piatra, pentru raportare.
func _depth_at(space: PhysicsDirectSpaceState3D, p: Vector3,
		terrain: Array[Node]) -> float:
	# Se intreaba la inaltimea la care chiar sta caroseria, nu pe asfalt: la
	# firul drumului orice cusatura de racord ar raspunde „inauntru".
	var pq := PhysicsPointQueryParameters3D.new()
	pq.position = p + Vector3(0.0, PROBE_IN, 0.0)
	pq.collide_with_bodies = true
	var inside := false
	for res in space.intersect_point(pq, MAX_LAYERS):
		if res["collider"] in terrain:
			inside = true
			break

	# Fetele de teren de deasupra, pentru cota si pentru cazul boltii.
	var target := p + Vector3(0.0, TOL, 0.0)
	var y := p.y + PROBE_UP
	var faces: Array[float] = []
	for _pass in MAX_LAYERS:
		if y <= target.y:
			break
		var q := PhysicsRayQueryParameters3D.create(
			Vector3(p.x, y, p.z), target)
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			break
		var hy := float(hit["position"].y)
		if hit["collider"] in terrain:
			faces.append(hy)
		# Sub cel mai de jos contact gasit pana acum, ca pasul sa fie mereu in
		# jos chiar daca motorul intoarce fete in alta ordine.
		y = minf(hy, y) - STEP_DOWN

	if not inside:
		if faces.is_empty():
			return 0.0
		faces.sort()
		# Piatra exista deasupra, dar masina nu e in ea: e bolta daca sta peste
		# degajare, si o cusatura de racord daca e sub — si aia se raporteaza cu
		# cota ei, ca sa nu se ascunda o ingropare incipienta.
		var low: float = faces[0]
		if low >= p.y + CLEAR_M:
			return -1.0
		return low - p.y

	# Ingropat: adancimea e pana la cea mai de SUS fata de teren de deasupra,
	# adica grosimea coloanei. Fara nicio fata (piatra care depaseste PROBE_UP)
	# se raporteaza cel putin degajarea, ca punctul sa nu para o zgarietura.
	if faces.is_empty():
		return CLEAR_M
	faces.sort()
	return maxf(faces[faces.size() - 1] - p.y, CLEAR_M)
