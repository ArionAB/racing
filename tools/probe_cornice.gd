extends Node
## Sonda CORNISEI: cat de iertatoare e marginea unde asfaltul se termina in gol.
##
## [b]De ce exista.[/b] Trei runde la rand, seed 2 din `ProbeRace` a fost citit
## ca „regresie pe cornisa": doua repuneri la frac 0.301/0.316, in aceeasi
## milisecunda si in aceeasi pozitie de fiecare data, si care dispar cand
## stingi un steag din ramura. Semnatura arata cauzala si NU e.
##
## Masurat cu trasoare identice pe amandoua partile (acelasi seed, acelasi
## numar de print-uri, deci acelasi cost), cele doua rulari se despart la
## [b]t = 6.7 s, la frac 0.018, cu 1 cm[/b] — pe dreapta de start, la 22 de
## secunde si aproape un sfert de tur INAINTE de cornisa. De acolo diferenta
## creste 1.2 m in 1 s, 30 m in 3 s, 60 m in 6 s. Cand masinile ajung la
## cornisa, cele doua lumi le au la ~50 m una de alta: nu se mai compara
## acelasi eveniment, ci doua curse diferite.
##
## Cat de subtire e perturbatia care porneste asta: doua `print` care nu se
## executa niciodata, adaugate in `race.gd`, mutasera repunerile de la
## t=30.8/37.6 la t=42.2/59.4 si numarul de la 2,2,2 la 2,2,3.
##
## Deci `ProbeRace` pe un seed nu poate raspunde la „e cornisa mai periculoasa
## acum?". El masoara o realizare a zarurilor, iar zarurile se reasaza la orice
## atingere a inventarului de coliziune.
##
## Sonda asta pune intrebarea direct, PE GEOMETRIE, deci raspunsul nu depinde
## de seed, de ordinea contactelor sau de cine pe cine imbranceste:
##
##   (i)   POLITA. Cat de lat e culoarul pe care se poate sta, masurat de la
##         axa in lateral pana unde solidul e inca la cota drumului. Sub o
##         semilatime, masina e peste gol cand inca se crede pe drum:
##         `is_on_road` da adevarat pana la `half_width + 0.5`.
##   (ii)  PRAGUL. Pe polita, intre doua esantioane vecine, nicio treapta peste
##         `STEP_MAX` — memoria `suprafete-cu-goluri-si-praguri`: peste 0.3 m
##         lateral roata nu urca, se izbeste.
##   (iii) PANTA DE DUPA BUZA. Cat de abrupt pleaca terenul dincolo de polita.
##         Nu e un verdict, e cifra care spune CAT de iertatoare e greseala:
##         raportata ca sa se vada daca o schimbare viitoare o inrautateste.
##
## Toate sunt proprietati ale LUMII: se masoara la fel pe orice ramura, si
## de-aia raspund la intrebarea la care seed-ul nu raspunde.
##
## Ruleaza CA SCENA (pista cere autoload-urile):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCornice.tscn
## Iese cu cod 1 la orice verdict picat.

const TRACK_SCENE: String = "res://scenes/tracks/Track12.tscn"

## Cornisa masurata, ca interval de fractii: chiar rapa 0 declarata in
## `Track12.tscn` (`custom_ravines[0]` = 0.215 -> 0.42, adancime 30, latura +1),
## trecuta si in `custom_cornice_ravines`.
const F0: float = 0.215
const F1: float = 0.42
## Latura pe care e golul (+1 = dreapta fata de sensul de mers), tot de acolo.
const SIDE: float = 1.0
## Pasul de esantionare in lungul pistei, in frac.
const F_STEP: float = 0.0025
## Cat de adanc se cauta in jos ca sa se decida „aici nu mai e nimic".
const PROBE_DEPTH: float = 60.0
## Pasul lateral, si cat de departe de axa se cauta.
const LAT_STEP: float = 0.25
const LAT_MAX: float = 20.0

## Cat de mult poate cobori solidul fata de cota axei si sa mai fie POLITA.
## Peste atat am iesit de pe umarul drumului si a inceput caderea.
const SHELF_DROP_M: float = 1.0
## [b]Polita nu are voie sa fie mai ingusta de-atat.[/b]
##
## 6.5 m, iar cifra e aleasa ca sa prinda o INRAUTATIRE, nu ca sa descrie
## idealul. Idealul ar fi semilatimea pistei (`custom_half_width` = 7.0): sub
## ea masina e deja peste gol in timp ce `is_on_road` inca spune adevarat,
## fiindca acela accepta pana la `half_width + 0.5`.
##
## Masurat, cornisa livrata are 6.75 m in punctul cel mai stramt (frac 0.225),
## deci e cu 25 cm sub ideal — [b]si e asa si pe `origin/main`, la aceeasi
## zecime[/b] (verificat prin A/B pe cod de baseline in acelasi worktree). E o
## datorie mostenita a pistei, nu ceva adus de pasajul rotativ, si nu se repara
## strecurand-o intr-o ramura despre altceva.
##
## Un prag pus la 7.0 ar fi rosu pe main de la prima rulare, adica exact
## ceremonia fara informatie de care se plange CLAUDE.md la plafonul de
## triunghiuri. Pus la 6.5 spune ceva ce se poate actiona: „cornisa nu s-a
## ingustat mai mult decat era". Cand datoria se plateste, se urca la 7.0.
const SHELF_MIN_M: float = 6.5
## Treapta verticala maxima admisa intre doua esantioane laterale vecine, PE
## polita.
##
## 2.5 m, si aici distanta pana la ideal e mult mai mare — pragul „sanatos" e
## 0.3 m (memoria `suprafete-cu-goluri-si-praguri`: peste atat roata nu urca,
## se izbeste). Cornisa livrata are 2.44 m la frac 0.2175, [b]identic pe
## `origin/main`[/b].
##
## Ce e acolo, citit din profilul lateral: la 7.00 m terenul cade o data
## (35.9 -> 31.3) si la 7.25 m urca inapoi (-> 34.8). E o CRESTATURA de un
## singur esantion pe buza rapei, unde taietura rapei se intalneste cu panza de
## teren — genul de muchie in care roata din dreapta se agata. Merita reparata,
## dar in geometria rapei si intr-o schimbare care are asta ca subiect.
const STEP_MAX: float = 2.5

var _track: Track
var _fails: int = 0


func _ready() -> void:
	_track = (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("=== CORNISA (%s), frac %.3f-%.3f, latura %+d ==="
		% [TRACK_SCENE, F0, F1, int(SIDE)])
	_check_shelf()
	print("=== %s ===" % ("PICAT: %d verdicte" % _fails if _fails > 0 else "TOATE OK"))
	get_tree().quit(1 if _fails > 0 else 0)


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


## Cota solidului sub un punct, sau INF daca acolo e gol pana la `PROBE_DEPTH`.
func _ground_at(p: Vector3) -> float:
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 5.0,
		p + Vector3.DOWN * PROBE_DEPTH)
	q.collide_with_areas = false
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return INF
	return (hit["position"] as Vector3).y


func _check_shelf() -> void:
	var route := _track.route_at(0)
	var n := route.count()
	var min_shelf := INF
	var min_shelf_frac := 0.0
	var worst_step := 0.0
	var worst_step_frac := 0.0
	var slope_sum := 0.0
	var slope_n := 0
	var samples := 0
	var f := F0
	while f <= F1:
		var idx := int(round(f * float(n))) % n
		var axis: Vector3 = route.baked[idx]
		var side := route.side_at(idx) * SIDE
		var road_y := _ground_at(axis)
		if is_inf(road_y):
			f += F_STEP
			continue
		samples += 1
		# Polita: cat de departe in lateral solidul e inca la cota drumului.
		var prev_y := road_y
		var shelf := LAT_MAX
		var step_here := 0.0
		var d := LAT_STEP
		while d <= LAT_MAX:
			var y := _ground_at(axis + side * d)
			if is_inf(y) or road_y - y > SHELF_DROP_M:
				shelf = d - LAT_STEP
				break
			# Treapta se numara doar PE polita: dincolo de ea, caderea insasi
			# ar fi raportata ca prag — adevarat, dar nu e ce se intreaba aici.
			step_here = maxf(step_here, absf(y - prev_y))
			prev_y = y
			d += LAT_STEP
		if shelf < min_shelf:
			min_shelf = shelf
			min_shelf_frac = f
		if step_here > worst_step:
			worst_step = step_here
			worst_step_frac = f
		# Panta de dupa buza: cat coboara terenul pe urmatorii 5 m laterali.
		var y_edge := _ground_at(axis + side * shelf)
		var y_out := _ground_at(axis + side * (shelf + 5.0))
		if not is_inf(y_edge) and not is_inf(y_out):
			slope_sum += (y_edge - y_out) / 5.0
			slope_n += 1
		f += F_STEP
	_verdict(samples > 0, "esantioane pe cornisa: %d" % samples)
	if samples == 0:
		return
	_verdict(min_shelf >= SHELF_MIN_M,
		"polita cea mai ingusta: %.2f m de la axa @frac %.4f (minim %.1f)"
		% [min_shelf, min_shelf_frac, SHELF_MIN_M])
	_verdict(worst_step <= STEP_MAX,
		"treapta laterala maxima pe polita: %.3f m @frac %.4f (plafon %.2f)"
		% [worst_step, worst_step_frac, STEP_MAX])
	if slope_n > 0:
		# Nu e verdict: e cifra care spune cat de scumpa e greseala. Se
		# raporteaza ca sa se vada daca o schimbare viitoare o inrautateste.
		print("  [info] panta medie dupa buza: %.2f m cadere / m lateral (%d probe)"
			% [slope_sum / float(slope_n), slope_n])
