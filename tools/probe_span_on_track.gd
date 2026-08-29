extends Node
## Sonda pasajului rotativ PE PISTA ADEVARATA (Track12, nodul Huangjuewan).
##
## [b]De ce nu ajunge `ProbeRotatingSpan`.[/b] Aceea ruleaza pe o sosea-test
## peste care modulul e RIDICAT cu `deck_rise` = 3 m, deci golul de sub tronson
## e gol prin CONSTRUCTIE. Pe Track12 `deck_rise` e 0: modulul sta pe soseaua
## pistei, iar cat timp pista nu si-a taiat gaura in asfalt, sub tronsonul rotit
## ramanea carosabil intreg. Hazardul mergea pe jumatate — deschis se trecea,
## inchis era o INCETINIRE, nu o deviere: masina se strecura prin bariere si
## continua drept, cu +1.7/+2.8 s din frecare, la 5.4 m de axa, in timp ce
## ocolul e la 24 m. Sonda de pe pista-test nu putea sa vada asta niciodata,
## si de-aia exista sonda asta.
##
## Cele doua intrebari la care numai pista reala raspunde:
##
##  (i)  GOLUL EXISTA. Pe amprenta tronsonului, cu el rotit din drum, o raza
##       trasa de sus in jos peste carosabil nu mai da in nimic. Cu el pe
##       pozitie, da in el. Se scaneaza toata LATIMEA, nu doar axa: ce trecea
##       pe dedesubt era chiar carosabilul pistei, si el e lat.
## Ce NU intreaba: cine conduce prin nod si cat costa. Aia o masoara
## `ProbeRace` pe pista reala si `ProbeRotatingSpan` pe pista-test — o sonda
## care isi aduce propriul sofer masoara soferul, nu lumea (prima versiune a
## sondei asteia a raportat „BLOCAT" la toate vitezele, si vinovat era chiar
## soferul ei, oprit intr-un viraj cu 40 m inainte de modul).
##
## Plus controlul de profil: cu pasajul DESCHIS, pe axa, intre frac 0.70 si
## 0.80, niciun prag peste `STEP_MAX` — gaura n-are voie sa introduca o treapta.
##
## Ruleaza CA SCENA (masina cere autoload-urile):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSpanOnTrack.tscn
## Iese cu cod 1 la orice verdict picat.

const SpanScript := preload("res://scenes/hazards/rotating_span_hazard.gd")
const TRACK_SCENE: String = "res://scenes/tracks/Track12.tscn"

## Fereastra de frac pe care se masoara profilul si se conduce masina.
const F0: float = 0.70
const F1: float = 0.80
## Pasul profilului, in frac.
const F_STEP: float = 0.0025
## Cel mai mare prag admis intre doua statii vecine de profil (m).
const STEP_MAX: float = 0.15

var _track: Track
var _hazard: SpanScript
var _fails: int = 0


func _ready() -> void:
	_track = (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	# [b]Comutatorul se apasa INAINTE de intrarea in arbore.[/b] Pe Track12
	# `cut_road_hole` e deocamdata stins (vezi nota lui: pilotul nu poate lua un
	# ocol care nu e ruta), dar mecanismul trebuie sa ramana pazit — altfel se
	# strica in tacere pana in ziua in care se aprinde. Aprins aici, pista isi
	# taie gaura la primul `rebuild()`, iar modulul se construieste o singura
	# data, ca in joc; o reconstructie facuta DUPA `_ready` lasa in urma corpuri
	# duplicate si a fost masurata ca atare (prag fals de 0.244 m).
	_hazard = _find_span(_track)
	if _hazard != null:
		_hazard.cut_road_hole = true
	add_child(_track)
	await get_tree().physics_frame
	await get_tree().physics_frame
	if _hazard == null:
		print("PICAT: nu am gasit pasajul rotativ in %s" % TRACK_SCENE)
		get_tree().quit(1)
		return
	print("=== PASAJ ROTATIV PE PISTA (%s) ===" % TRACK_SCENE)
	print("  nod la %s | gaura ceruta %.2f m | tronson %.2f m"
		% [str(_hazard.global_position.round()), _hazard.road_hole_span(),
		_hazard.span_length])
	_check_hole()
	_check_profile()
	print("=== %s ===" % ("PICAT: %d verdicte" % _fails if _fails > 0 else "TOATE OK"))
	get_tree().quit(1 if _fails > 0 else 0)


func _find_span(n: Node) -> SpanScript:
	for c in n.get_children():
		if c is SpanScript:
			return c as SpanScript
		var r := _find_span(c)
		if r != null:
			return r
	return null


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


# ------------------------------------------------------------------ golul

## Ce e sub un punct: numele corpului si cota, sau gol daca nu e nimic pana la
## `depth` metri mai jos.
func _under(p: Vector3, depth: float) -> Dictionary:
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 6.0,
		p + Vector3.DOWN * depth)
	q.collide_with_areas = false
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return {}
	return {"name": String((hit["collider"] as Node).name),
		"y": (hit["position"] as Vector3).y}


## Duce ceasul hazardului la fractia de rotatie ceruta (0 deschis, 1 inchis).
func _force_state(frac: float) -> void:
	# `_started` INAINTE de `_time`: primul cadru de fizica al hazardului isi
	# rescrie ceasul din `phase` daca inca n-a pornit, si asa starea ceruta aici
	# era stearsa tacut — sonda masura de doua ori aceeasi stare.
	_hazard._started = true
	var hold: float = _hazard.hold_time()
	_hazard._time = (hold * 0.5) if frac < 0.5 \
		else (hold + _hazard.turn_time + hold * 0.5)
	_hazard._apply_cycle(0.0)


## (i) Cu tronsonul rotit din drum, sub el nu mai e nimic; cu el pe pozitie, e.
func _check_hole() -> void:
	# [b]Amprenta se masoara pe GAURA, nu pe tronson.[/b] Gaura e mai scurta cu
	# `HOLE_LIP` de fiecare parte (buza pe care se sprijina tablierul), plus
	# rotunjirea la punctele coapte ale pistei — iar peste buze sta si peretele
	# de la gura golului, care e ACOLO ca sa fie. O amprenta luata pe toata
	# lungimea tronsonului numara deci drept „gaura astupata" chiar reazemul
	# tablierului si chiar bariera care te opreste sa cazi.
	var lip: float = _hazard.road_hole_span() * 0.5 - 1.5
	var hw: float = _hazard.road_half_width
	var stations: Array[Vector2] = []
	for zi in 5:
		var z := lerpf(lip, -lip, float(zi) / 4.0)
		for xi in 7:
			stations.append(Vector2(lerpf(-hw * 0.8, hw * 0.8,
				float(xi) / 6.0), z))
	_hazard.clock_running = false
	_force_state(0.0)
	var missing_open := 0
	for s in stations:
		# `at_dump` raspunde in coordonatele NODULUI; raza se trage in lume.
		if _under(_hazard.to_global(_hazard.at_dump(s.x, s.y)), 4.0).is_empty():
			missing_open += 1
	_verdict(missing_open == 0,
		"deschis: tronsonul acopera golul (%d statii din %d fara suprafata)"
		% [missing_open, stations.size()])
	_force_state(1.0)
	var solid: Array[String] = []
	for s in stations:
		var h := _under(_hazard.to_global(_hazard.at_dump(s.x, s.y)), 4.0)
		if not h.is_empty():
			solid.append("%s@lat%.1f,z%.1f" % [h["name"], s.x, s.y])
	print("    inchis: %d statii din %d au inca suprafata sub ele%s"
		% [solid.size(), stations.size(),
		("  ex: " + ", ".join(solid.slice(0, 4))) if not solid.is_empty() else ""])
	_verdict(solid.is_empty(), "inchis: golul e GOL pe toata amprenta tronsonului")
	_hazard.clock_running = true


# ---------------------------------------------------------------- profilul

func _axis_point(f: float) -> Vector3:
	var route := _track.route_at(0)
	var n := route.count()
	var i := int(fposmod(f, 1.0) * float(n)) % n
	return route.baked[i]


## Control: cu pasajul DESCHIS, profilul pe axa nu are trepte.
func _check_profile() -> void:
	_hazard.clock_running = false
	_force_state(0.0)
	var worst := 0.0
	var worst_f := 0.0
	var gaps := 0
	var prev_dy := INF
	var f := F0
	print("  profil pe axa, stare DESCHISA:")
	while f <= F1 + 0.0001:
		var p := _axis_point(f)
		var h := _under(p, 3.0)
		if h.is_empty():
			gaps += 1
			prev_dy = INF
			f += F_STEP
			continue
		var dy: float = float(h["y"]) - p.y
		if prev_dy < INF:
			var step := absf(dy - prev_dy)
			if step > worst:
				worst = step
				worst_f = f
		prev_dy = dy
		f += F_STEP
	print("    statii fara suprafata: %d" % gaps)
	print("    cel mai mare prag: %.3f m la frac %.4f [prag %.2f]"
		% [worst, worst_f, STEP_MAX])
	_verdict(gaps == 0, "deschis: nicio statie fara suprafata pe %.2f-%.2f" % [F0, F1])
	_verdict(worst <= STEP_MAX,
		"deschis: fara prag peste %.2f m (cel mai mare %.3f m)" % [STEP_MAX, worst])
	_hazard.clock_running = true


