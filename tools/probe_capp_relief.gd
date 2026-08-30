extends Node
## Sonda de RELIEF pe padurea de hornuri: cat de SAPAT e pamantul, in cifre.
##
## [b]De ce exista.[/b] Sase runde de nota 4/10 s-au inchis cu acelasi verdict,
## dat independent de doi critici: „terenul nostru e un PLAN cu conuri asezate
## pe el". Rundele dinainte au mutat culoarea, silueta si lumina — si nota n-a
## urcat, fiindca niciuna nu atingea forma pamantului.
##
## Problema cu „pare plat" e ca nu se poate actiona pe ea. Sonda asta o
## transforma in trei numere masurate pe COLIZIUNE (deci pe ce calca masina, nu
## pe ce cred eu ca am scris):
##
##   (i)   AMPLITUDINEA laterala. Pe o taietura perpendiculara pe sosea, cat e
##         diferenta dintre cel mai inalt si cel mai jos punct de teren. Pe un
##         plan e ~0. Referinta are polita: perete pe deal, cadere spre vale.
##   (ii)  ASIMETRIA. Cat urca stanga fata de cat coboara dreapta. Un drum care
##         taie o polita are semnul clar; unul pictat pe camp are 0.
##   (iii) RUGOZITATEA dintre grupuri de conuri: cate treceri sus-jos are
##         profilul lateral. Un plan da 0 treceri, un teren erodat da mai multe.
##
## Si, fiindca sapatul e exact operatia care poate ingropa carosabilul sau
## deschide o treapta-zid, raporteaza in acelasi timp garda de siguranta:
## treapta laterala maxima pe polita (memoria `suprafete-cu-goluri-si-praguri`:
## peste 0.3 m roata nu urca, se izbeste) si latimea politei conducibile.
##
## [b]Citeste campul de inaltime, nu raze.[/b] Prima versiune trimitea raze in
## jos si masura COLIZIUNEA — dar hornurile au si ele corp fizic, pe acelasi
## layer ca terenul, deci raza se oprea in varful unui con si raporta o
## „treapta" de 18 m la 2.5 m de axa. Aia e un horn, nu un prag de teren.
## `ground_y` e chiar campul din care se coace panza de teren, deci raspunde
## exact la intrebarea pusa: ce forma are PAMANTUL.
##
## Ruleaza CA SCENA (pista cere autoload-urile):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappRelief.tscn

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

## Padurea de hornuri, ca interval de fractii (masurat din pozitiile
## nodurilor din ZoneB_PadureaHornurilor pe curba coapta).
const F0: float = 0.020
const F1: float = 0.165
const F_STEP: float = 0.005

const LAT_STEP: float = 0.5
## Pana unde se citeste profilul lateral, de fiecare parte.
const LAT_MAX: float = 60.0

## Cat de mult poate cobori solidul fata de cota axei si sa mai fie POLITA.
const SHELF_DROP_M: float = 1.0
## Treapta laterala maxima admisa PE polita (rulabil, nu zid).
##
## Idealul e 0.30 m (memoria `suprafete-cu-goluri-si-praguri`). Masurat INAINTE
## de orice sapatura, terenul livrat avea deja 0.364 m la frac 0.120, pe flancul
## lui `MasivulDeTuf` — datorie mostenita, nu ceva adus de taietura. Pragul e
## pus la 0.45 ca sa prinda o INRAUTATIRE aduse de sapat; pus la 0.30 ar fi rosu
## din prima rulare si n-ar spune nimic (vezi discutia despre plafoane care se
## muta din CLAUDE.md). Cand se plateste datoria, coboara la 0.30.
const STEP_MAX: float = 0.45
## Polita conducibila minima de la axa, in metri.
const SHELF_MIN_M: float = 6.0

var _track: Track
var _sampler: TrackSideSampler
var _fails: int = 0


func _ready() -> void:
	_track = (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_sampler = _track.get("_sampler") as TrackSideSampler
	print("=== RELIEF padurea hornurilor, frac %.3f-%.3f ===" % [F0, F1])
	_check()
	print("=== %s ===" % ("PICAT: %d verdicte" % _fails if _fails > 0 else "TOATE OK"))
	get_tree().quit(1 if _fails > 0 else 0)


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


func _ground_at(p: Vector3) -> float:
	return _sampler.ground_y(p.x, p.z)


## Profilul lateral la o fractie: cote de teren de la -LAT_MAX la +LAT_MAX.
func _profile(axis: Vector3, side: Vector3) -> Array:
	var out := []
	var d := -LAT_MAX
	while d <= LAT_MAX:
		out.append([d, _ground_at(axis + side * d)])
		d += LAT_STEP
	return out


func _check() -> void:
	var route := _track.route_at(0)
	var n := route.count()
	var amp_sum := 0.0
	var amp_max := 0.0
	var amp_max_f := 0.0
	var asym_sum := 0.0
	var cross_sum := 0.0
	var worst_step := 0.0
	var worst_step_f := 0.0
	var min_shelf := INF
	var min_shelf_f := 0.0
	var samples := 0
	var f := F0
	while f <= F1:
		var idx := int(round(f * float(n))) % n
		var axis: Vector3 = route.baked[idx]
		var side := route.side_at(idx)
		var road_y := _ground_at(axis)
		if is_inf(road_y):
			f += F_STEP
			continue
		samples += 1
		var prof := _profile(axis, side)
		# (i) amplitudine: max - min pe toata taietura.
		var lo := INF
		var hi := -INF
		for e in prof:
			var y: float = e[1]
			if is_inf(y):
				continue
			lo = minf(lo, y)
			hi = maxf(hi, y)
		if not is_inf(lo):
			var amp := hi - lo
			amp_sum += amp
			if amp > amp_max:
				amp_max = amp
				amp_max_f = f
		# (ii) asimetrie: media pe stanga minus media pe dreapta, fata de axa.
		var l_sum := 0.0
		var l_n := 0
		var r_sum := 0.0
		var r_n := 0
		for e in prof:
			var d: float = e[0]
			var y: float = e[1]
			if is_inf(y) or absf(d) < 12.0:
				continue
			if d < 0.0:
				l_sum += y - road_y
				l_n += 1
			else:
				r_sum += y - road_y
				r_n += 1
		if l_n > 0 and r_n > 0:
			asym_sum += (l_sum / float(l_n)) - (r_sum / float(r_n))
		# (iii) rugozitate: cate schimbari de semn are panta, dincolo de umeri.
		var crossings := 0
		var prev_slope := 0.0
		for i in range(1, prof.size()):
			var y0: float = prof[i - 1][1]
			var y1: float = prof[i][1]
			if is_inf(y0) or is_inf(y1):
				continue
			var s := y1 - y0
			if absf(s) < 0.05:
				continue
			if prev_slope != 0.0 and signf(s) != signf(prev_slope):
				crossings += 1
			prev_slope = s
		cross_sum += float(crossings)
		# GARDA: treapta laterala pe polita + latimea politei, ambele parti.
		for sgn: float in [-1.0, 1.0]:
			var prev_y := road_y
			var shelf := LAT_MAX
			var d2 := LAT_STEP
			while d2 <= LAT_MAX:
				var y := _ground_at(axis + side * sgn * d2)
				if is_inf(y) or road_y - y > SHELF_DROP_M:
					shelf = d2 - LAT_STEP
					break
				var st := absf(y - prev_y)
				if st > worst_step:
					worst_step = st
					worst_step_f = f
				prev_y = y
				d2 += LAT_STEP
			if shelf < min_shelf:
				min_shelf = shelf
				min_shelf_f = f
		f += F_STEP
	_verdict(samples > 0, "taieturi masurate: %d" % samples)
	if samples == 0:
		return
	var inv := 1.0 / float(samples)
	print("  [info] amplitudine laterala medie: %.2f m (maxim %.2f m @frac %.3f)"
		% [amp_sum * inv, amp_max, amp_max_f])
	print("  [info] asimetrie medie (stanga sus / dreapta jos): %+.2f m"
		% (asym_sum * inv))
	print("  [info] rugozitate: %.1f schimbari de panta per taietura"
		% (cross_sum * inv))
	_verdict(worst_step <= STEP_MAX,
		"treapta laterala maxima pe polita: %.3f m @frac %.3f (plafon %.2f)"
		% [worst_step, worst_step_f, STEP_MAX])
	_verdict(min_shelf >= SHELF_MIN_M,
		"polita cea mai ingusta: %.2f m de la axa @frac %.3f (minim %.1f)"
		% [min_shelf, min_shelf_f, SHELF_MIN_M])
