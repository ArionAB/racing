class_name ShishiOdoshiHazard
extends WaterHazard
## Shishi-odoshi (Kyoto, Track18, POI F): tubul de bambus pe pivot din gradinile
## japoneze, la scara de jucarie — 16 m, Ø 1,8, peste jumatate de drum.
##
## [b]Ceasul e UNGHIUL[/b]. Tubul se umple 14 s si coboara CONTINUU de la +35° la
## +8° (gura la 12,9 m -> 7,7 m, mult peste masini); apoi loveste: 0,5 s pana la
## -30°, unde gura atinge drumul; sta jos 1,5 s (golire), si revine 0,6 s la +35°
## cu „TOC" de coada pe piatra. Jucatorul citeste cat timp mai are din cat de
## aplecat e tubul, nu doar daca vine.
##
## [b]Geometrie[/b] (radacina sta PE AXA soselei, cu fata pe sensul de mers -Z,
## ca `WaterHose` si `CraneHazard`): pivotul e pe marginea dinspre EXTERIORUL
## curbei (`side` = +1 pe dreapta, -1 pe stanga), tubul se intinde peste drum cu
## gura spre axa. Banda de langa pivot ramane mereu libera: acolo tubul nu
## coboara sub inaltimea masinilor. Interiorul (linia rapida) se inchide.
##
## [b]Doua corpuri, o decizie[/b]. `AnimatableBody3D`-ul tubului e solid doar cand
## tubul e coborat (tiparul `ExcavatorHazard`). Dar un corp cinematic care apare
## brusc intr-o masina o scoate din lume (memoria `corp-cinematic-aparut-in-
## masina`), deci aruncarea NU o face solverul: o zona (`_hit_zone`), pornita cu
## cateva zeci de centimetri INAINTE ca tubul sa fie solid, prinde masina si o
## arunca spre exterior prin [HazardThrow] (orizontala se scrie, verticala prin
## `Car.launch`, exceptie de coliziune cat tine zborul).
##
## [b]Masa conteaza[/b]: `ratio = masa_de_referinta / masa_masinii` taie impinsul si
## inaltimea (Autobuzul zboara putin), iar masa grea PASTREAZA mai mult din
## viteza inainte (`keep_speed`) — deci pierderile difera intre masini.
##
## [b]AI onest[/b]: AI-ul nu franeaza pentru tub, doar trece pe linia exterioara
## cand tubul va bate in FEREASTRA lui de sosire `[rapid, lent]` (`blocks_between`,
## memoria `eta-cu-viteza-curenta-minte-pe-banda-cu-viraje`). Vezi
## `ai_controller.gd::_shishi_line`.
##
## [b]Model[/b]: `model` cu nodurile `Frame`, `Tube` (originea pe axa pivotului,
## gura pe -Z), `Kakei`, `StrikeStone`. Fara el, un placeholder de cutii din
## atlasul de paleta (zero materiale noi) cu aceleasi nume de noduri.

## Grupul pe care il citeste `AIController` (tipar `TorrentCycle.AI_GROUP`).
const AI_GROUP: StringName = &"shishi_odoshi"

signal car_thrown(car: Car, on_strike: bool)

@export_group("Ciclul")
## Umplerea: unghiul scade continuu de la `fill_start_deg` la `fill_end_deg`.
@export_range(2.0, 40.0, 0.5) var fill_seconds: float = 14.0
## Lovitura: de la `fill_end_deg` la `strike_deg`.
@export_range(0.1, 2.0, 0.05) var strike_seconds: float = 0.5
## Golirea: tubul sta jos.
@export_range(0.1, 5.0, 0.1) var drain_seconds: float = 1.5
## Revenirea la `fill_start_deg` („TOC").
@export_range(0.1, 3.0, 0.05) var return_seconds: float = 0.6
## Cat dupa ce tubul se ridica mai ramane petecul ud.
@export_range(0.0, 8.0, 0.5) var dry_seconds: float = 3.0
## Ceasul de la care porneste (s) — decaleaza hazardele intre ele.
@export_range(0.0, 60.0, 0.1) var start_clock: float = 0.0

@export_group("Unghiuri (grade, + = gura in sus)")
@export_range(0.0, 60.0, 0.5) var fill_start_deg: float = 35.0
@export_range(-10.0, 30.0, 0.5) var fill_end_deg: float = 8.0
@export_range(-60.0, 0.0, 0.5) var strike_deg: float = -30.0

@export_group("Geometrie")
## +1 = pivotul pe dreapta sensului de mers (+X local), -1 = stanga.
@export_range(-1, 1, 2) var side: int = 1
## Distanta pivotului fata de axa soselei (m). Negativ = jumatatea latimii.
@export var pivot_offset: float = -1.0
## 6,6 m, nu 6,0 din brief: cu 6,0 golul exterior MASURAT e 6,22 m (tubul are raza
## 0,9, deci sub 1,1 m coboara mai devreme decat axa sub 1,8). Vezi sonda.
@export_range(2.0, 12.0, 0.1) var pivot_height: float = 6.6
@export_range(8.0, 30.0, 0.5) var tube_length: float = 16.0
@export_range(1.0, 8.0, 0.5) var tail_length: float = 4.0
@export_range(0.5, 3.0, 0.1) var tube_diameter: float = 1.8
## Latimea (pe sensul de mers) a zonei de ghiont, in plus fata de tub. Fereastra
## de cateva cadre: la 30 m/s masina face 0,5 m pe cadru.
@export_range(0.0, 4.0, 0.1) var hit_margin_along: float = 1.2
## Inaltimea (m) sub care tubul e „coborat": corpul devine solid.
@export_range(0.5, 4.0, 0.05) var solid_height: float = 1.1
## Cu cat INAINTE de solid porneste zona de ghiont (m de inaltime). Tubul coboara
## pe ultimii metri cu ~25 m/s (0,4 m pe cadru), deci 2 m = cateva cadre.
@export_range(0.0, 4.0, 0.05) var hit_lead: float = 2.0
## Cat iese zona de ghiont sub tub (m) cat tubul COBOARA: o fereastra de cadre
## in care masina e prinsa si aruncata inainte sa existe un solid peste ea.
@export_range(0.0, 3.0, 0.05) var strike_reach: float = 1.0
## Cat iese sub tub dupa lovitura, cand sta culcat: doar o marja, fiindca masina
## vine atunci pe orizontala si fereastra de cadre e `hit_margin_along`.
@export_range(0.0, 1.0, 0.05) var rest_reach: float = 0.25
## Un model de la Blender; gol = placeholder.
@export var model: PackedScene

@export_group("Aruncarea")
## Masa de referinta (Buggy = 100): raportul ei la masa masinii scaleaza efectul.
@export var reference_mass: float = 100.0
## Impinsul spre exterior pentru masa de referinta (m/s).
@export_range(0.0, 30.0, 0.5) var push_speed: float = 9.0
## Inaltimea zborului pentru masa de referinta (m).
@export_range(0.0, 4.0, 0.1) var throw_rise: float = 1.2
## Din viteza inainte, cat ramane la masa de referinta; masa mai mare tine mai mult.
@export_range(0.0, 1.0, 0.05) var keep_speed: float = 0.1
## Cat creste `keep_speed` pe fiecare unitate de (masa/referinta - 1).
@export_range(0.0, 1.0, 0.05) var keep_per_mass: float = 0.2
## Ricoseul in tubul CULCAT: fractie din viteza inainte, cu semn (negativ = inapoi).
@export_range(-1.0, 1.0, 0.05) var ricochet_keep: float = -0.05
@export_range(0.0, 8.0, 0.1) var spin_rate: float = 4.0
@export_range(0.0, 2.0, 0.05) var spin_seconds: float = 0.6
## Strivirea de dupa lovitura: masina e latita si se tarie (vezi `Car.crush`).
@export_range(0.0, 2.0, 0.05) var crush_seconds: float = 0.4
@export_range(0.3, 1.0, 0.05) var crush_factor: float = 0.7
@export_range(0.2, 3.0, 0.1) var clear_seconds: float = 1.2
@export_range(0.1, 3.0, 0.1) var hit_cooldown: float = 1.0
## Marja pe fereastra de pericol pentru AI (s), de fiecare parte.
@export_range(0.0, 1.5, 0.05) var ai_margin: float = 0.3
## Latimea benzii exterioare in care AI-ul se simte in siguranta (m), din care
## se scade o marja de gabarit.
@export_range(0.0, 3.0, 0.1) var ai_lane_trim: float = 1.2

## Contoare pentru sonde.
var throws: int = 0
var strike_throws: int = 0

var _clock: float = 0.0
var _tube: Node3D # nodul `Tube` (vizual); rotation.x = unghiul
var _pivot: Node3D
var _body: AnimatableBody3D
var _body_shape: CollisionShape3D
var _hit_zone: Area3D
var _hit_shape: CollisionShape3D
var _cooldown: Dictionary = {}
var _win_start: float = 0.0
var _win_end: float = -1.0
var _wet_start: float = 0.0
var _wet_len: float = 0.0
var _placed: bool = false


func _ready() -> void:
	if pivot_offset < 0.0:
		pivot_offset = road_width * 0.5
	_clock = fposmod(start_clock, cycle_seconds())
	add_to_group(AI_GROUP)
	super._ready()
	recompute_windows()
	_apply_state()


# ------------------------------------------------------------------ ciclul

## Durata unui ciclu (s): 14 + 0,5 + 1,5 + 0,6 = 16,6.
func cycle_seconds() -> float:
	return fill_seconds + strike_seconds + drain_seconds + return_seconds


## Unghiul tubului (rad) la momentul `t` din ciclu. Continuu pe tot ciclul.
func angle_at(t: float) -> float:
	t = fposmod(t, cycle_seconds())
	var a0 := deg_to_rad(fill_start_deg)
	var a1 := deg_to_rad(fill_end_deg)
	var a2 := deg_to_rad(strike_deg)
	if t < fill_seconds:
		return lerpf(a0, a1, t / fill_seconds)
	t -= fill_seconds
	if t < strike_seconds:
		# Accelereaza ca un corp care cade, nu liniar.
		return lerpf(a1, a2, pow(t / strike_seconds, 1.7))
	t -= strike_seconds
	if t < drain_seconds:
		return a2
	t -= drain_seconds
	return lerpf(a2, a0, smoothstep(0.0, 1.0, t / return_seconds))


func angle() -> float:
	return angle_at(_clock)


func clock() -> float:
	return _clock


## Cat de plin e tubul: 0 la inceputul umplerii, 1 la sfarsitul ei; ramane 1
## cat dureaza lovitura si golirea nu il goleste instant (se vede pe unghi).
func fill_fraction() -> float:
	if _clock < fill_seconds:
		return _clock / fill_seconds
	return 1.0


## Faza de lovitura (coborare)? Aici aruncarea e „lovitura"; dupa ea e „ricoseu".
func in_strike() -> bool:
	return _clock >= fill_seconds and _clock < fill_seconds + strike_seconds


## Inaltimea (m, deasupra soselei) a celui mai de jos punct al tubului, la
## distanta orizontala `s` de pivot, pentru unghiul `ang`. Doar pe lungimea
## bratului (s <= bratul proiectat).
func underside_at(s: float, ang: float) -> float:
	return pivot_height + s * tan(ang) - 0.5 * tube_diameter / maxf(cos(ang), 0.05)


## Lungimea bratului dinspre drum (gura), m.
func arm_length() -> float:
	return tube_length - tail_length


## Distanta orizontala de la pivot pana la care tubul coboara sub `height`
## (m), la unghiul `ang`; INF daca tubul nu coboara niciodata atat. Peste
## aceasta distanta (pana la gura) banda e inchisa.
func blocked_from(height: float, ang: float) -> float:
	if ang >= 0.0:
		return INF
	var s := (height + 0.5 * tube_diameter / cos(ang) - pivot_height) / tan(ang)
	return maxf(s, 0.0)


## Cat e liber (m, de la pivot spre axa) pe banda exterioara la lovitura:
## distanta orizontala pana unde tubul coboara sub inaltimea masinilor (+ marja
## zonei de ghiont). E numarul brief-ului „7,3 m", dar derivat din cotele reale.
func free_gap_m() -> float:
	return blocked_from(solid_height + rest_reach, deg_to_rad(strike_deg))


## Tubul e coborat (corp solid)?
func is_solid() -> bool:
	return _lowest_over_road() < solid_height


func is_zone_on() -> bool:
	return _lowest_over_road() < solid_height + hit_lead


## Cota gurii (jos) la unghiul curent.
func _lowest_over_road() -> float:
	var a := angle_at(_clock)
	return underside_at(arm_length() * cos(a), a) if a < 0.0 \
		else INF


## Cand (in ciclu) tubul e periculos: de la prima clipa cu zona pornita pana la
## ultima. Se masoara pe pasi, nu se deduce din formula, ca sa urmeze exportul.
func recompute_windows() -> void:
	var cyc := cycle_seconds()
	var step := 0.01
	_win_start = INF
	_win_end = -1.0
	var n := int(cyc / step)
	for i in n:
		var t := float(i) * step
		var a := angle_at(t)
		var low := a < 0.0 and underside_at(arm_length() * cos(a), a) \
			< solid_height + hit_lead
		if low:
			_win_start = minf(_win_start, t)
			_win_end = maxf(_win_end, t)
	_wet_start = fill_seconds + strike_seconds
	_wet_len = drain_seconds + return_seconds + dry_seconds


## Fereastra de pericol [start, end] in timpul ciclului (s), fara marja.
func danger_window() -> Vector2:
	return Vector2(_win_start, _win_end)


## Va fi tubul periculos in vreun moment din [t0, t1] secunde (sosirea masinii
## e o fereastra, nu un moment)? `ai_margin` acopera trecerea prin amprenta.
func blocks_between(t0: float, t1: float) -> bool:
	if _win_end < 0.0:
		return false
	var lo := minf(t0, t1) - ai_margin
	var hi := maxf(t0, t1) + ai_margin
	var cyc := cycle_seconds()
	var steps := maxi(int(ceil((hi - lo) / 0.05)), 1)
	for i in steps + 1:
		var tt := fposmod(_clock + lo + (hi - lo) * float(i) / float(steps), cyc)
		if tt >= _win_start and tt <= _win_end:
			return true
	return false


func blocks_in(seconds: float) -> bool:
	return blocks_between(seconds, seconds)


## Secunde pana la INCEPUTUL urmatoarei ferestre de pericol (0 daca e in ea).
func seconds_to_danger() -> float:
	var cyc := cycle_seconds()
	if _clock >= _win_start and _clock <= _win_end:
		return 0.0
	return fposmod(_win_start - _clock, cyc)


## Punctul de pe axa soselei unde e tubul (pentru indexul de pista al AI-ului).
func ai_decision_point() -> Vector3:
	return global_position


## Lateral (m, + = spre partea pivotului) al CENTRULUI benzii exterioare libere.
func ai_safe_lane_m() -> float:
	var gap := maxf(free_gap_m() - ai_lane_trim, 0.5)
	return pivot_offset - gap * 0.5


## Directia „spre exterior" in lume (orizontala, spre partea pivotului).
func outward() -> Vector3:
	var o := global_transform.basis.x * float(side)
	o.y = 0.0
	return o.normalized()


## Semi-lungimea zonei de pericol pe sensul de mers (m).
func footprint_half() -> float:
	return tube_diameter * 0.5 + hit_margin_along


## Pentru sonde: fixeaza ceasul fara sa opreasca ciclul.
func seek(t: float) -> void:
	_clock = fposmod(t, cycle_seconds())
	_apply_state()


## Pentru sonde: fixeaza ceasul si OPRESTE avansul (ca `TorrentCycle`).
func force_clock(t: float) -> void:
	set_physics_process(false)
	seek(t)


func resume_clock() -> void:
	set_physics_process(true)


func body() -> AnimatableBody3D:
	return _body


func tube_node() -> Node3D:
	return _tube


func hit_zone() -> Area3D:
	return _hit_zone


## Petecul ud e activ acum? (golirea + revenirea + `dry_seconds` dupa).
func is_wet() -> bool:
	var since := fposmod(_clock - _wet_start, cycle_seconds())
	return since < _wet_len


# ------------------------------------------------------------ WaterHazard

## Petecul: jumatatea INTERIOARA a soselei (de la axa spre marginea opusa
## pivotului), 12 m pe sensul de mers.
func _wet_patch_size() -> Vector3:
	return Vector3(road_width * 0.5 + 0.5, 3.0, 12.0)


func _build_source() -> void:
	# Petecul sta pe jumatatea dinspre interior, nu pe axa.
	var shift := -float(side) * road_width * 0.25
	_zone.position.x += shift
	_puddle.position.x += shift
	_build_rig()


func _build_rig() -> void:
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	add_child(_pivot)
	_pivot.position = Vector3(float(side) * pivot_offset, pivot_height, 0.0)
	# Gura (-Z local) se intoarce spre drum.
	_pivot.rotation.y = float(side) * PI * 0.5

	var root: Node3D = null
	if model != null:
		root = model.instantiate() as Node3D
	if root != null:
		# Contractul: originea modelului = axa pivotului, deci modelul sta in
		# pivot, nu pe sol.
		_pivot.add_child(root)
		_tube = root.find_child("Tube", true, false) as Node3D
	if _tube == null:
		if root == null:
			root = _placeholder()
			_pivot.add_child(root)
		_tube = root.find_child("Tube", true, false) as Node3D
	_tube.rotation.x = angle_at(_clock)

	_body = AnimatableBody3D.new()
	_body.name = "TubeBody"
	_body.sync_to_physics = true
	add_child(_body)
	_body_shape = CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = tube_diameter * 0.5
	cyl.height = tube_length
	_body_shape.shape = cyl
	# Cilindrul are axa pe Y; il culcam pe -Z, centrat intre coada si gura.
	_body_shape.rotation.x = PI * 0.5
	_body_shape.position = Vector3(0.0, 0.0, -(arm_length() - tail_length) * 0.5)
	_body_shape.disabled = true
	_body.add_child(_body_shape)

	# Zona de ghiont: mai groasa pe sensul de mers (fereastra de cadre), putin
	# mai groasa pe verticala (`hit_lead` — vine inaintea solidului). monitorable
	# ca sonda de gol s-o poata interoga.
	_hit_zone = Area3D.new()
	_hit_zone.name = "HitZone"
	_hit_zone.monitorable = true
	_hit_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(tube_diameter + hit_margin_along * 2.0,
		tube_diameter + rest_reach * 2.0, tube_length)
	_hit_shape.shape = box
	_hit_shape.position = _body_shape.position
	_hit_shape.disabled = true
	_hit_zone.add_child(_hit_shape)
	_body.add_child(_hit_zone)
	_place_body()


func _placeholder() -> Node3D:
	var root := Node3D.new()
	root.name = "ShishiPlaceholder"
	var r := tube_diameter * 0.5
	var frame := Node3D.new()
	frame.name = "Frame"
	root.add_child(frame)
	# Doi stalpi de piatra, de-o parte si de alta a tubului, sub pivot.
	for sz in [-1.0, 1.0]:
		frame.add_child(PaletteBox.instance(
			Vector3(0.8, pivot_height + 0.5, 0.8), Palette.ROCK_LIGHT,
			Vector3(0.0, -pivot_height * 0.5 + 0.25, sz * (r + 0.7))))
	var tube := Node3D.new()
	tube.name = "Tube"
	root.add_child(tube)
	tube.add_child(PaletteBox.instance(
		Vector3(tube_diameter, tube_diameter, tube_length), Palette.TROPICAL_GREEN,
		Vector3(0.0, 0.0, -(arm_length() - tail_length) * 0.5)))
	var kakei := Node3D.new()
	kakei.name = "Kakei"
	root.add_child(kakei)
	kakei.add_child(PaletteBox.instance(
		Vector3(0.6, 0.3, 5.0), Palette.WOOD_WEATHERED,
		Vector3(0.0, 2.2, -arm_length() - 1.0)))
	var stone := Node3D.new()
	stone.name = "StrikeStone"
	root.add_child(stone)
	stone.add_child(PaletteBox.instance(
		Vector3(1.6, 0.5, 1.6), Palette.ROCK_DARK,
		Vector3(0.0, -pivot_height + 0.25, tail_length * 0.9)))
	return root


## O SINGURA scriere de transform pe cadru (memoria `jolt-sync-transform-o-
## singura-scriere`); corpul e frate cu pivotul, nu copil.
func _place_body() -> void:
	if _body == null or _tube == null:
		return
	_body.global_transform = _tube.global_transform


func _apply_state() -> void:
	if _tube == null:
		return
	_tube.rotation.x = angle_at(_clock)
	_place_body()
	var solid := is_solid()
	var zone := is_zone_on()
	_body_shape.disabled = not solid
	_hit_shape.disabled = not zone
	var box := _hit_shape.shape as BoxShape3D
	var reach := strike_reach if in_strike() else rest_reach
	box.size.y = tube_diameter + reach * 2.0


func _advance(delta: float) -> bool:
	_clock = fposmod(_clock + delta, cycle_seconds())
	_apply_state()
	_tick_cooldown(delta)
	if _hit_shape != null and not _hit_shape.disabled:
		_hit_cars()
	return is_wet()


func _tick_cooldown(delta: float) -> void:
	for key in _cooldown.keys():
		if not is_instance_valid(key):
			_cooldown.erase(key)
			continue
		var left: float = float(_cooldown[key]) - delta
		if left <= 0.0:
			_cooldown.erase(key)
		else:
			_cooldown[key] = left


func _hit_cars() -> void:
	for b in _hit_zone.get_overlapping_bodies():
		var car := b as Car
		if car == null or _cooldown.has(car):
			continue
		_cooldown[car] = hit_cooldown
		_throw_car(car)


func _throw_car(car: Car) -> void:
	var strike := in_strike()
	var ratio := clampf(reference_mass / maxf(car.mass, 1.0), 0.4, 1.4)
	var keep := clampf(keep_speed + keep_per_mass * (car.mass / reference_mass - 1.0),
		0.1, 0.95)
	var out := outward()
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	# DOAR componenta pe sensul de mers: lateralul din cadrul loviturii e al
	# solverului (un impuls de ejectare), nu al soferului, si nu trebuie sa se
	# adune la impinsul hotarat de hazard.
	var along := car.velocity.dot(fwd)
	var horizontal: Vector3
	if strike:
		horizontal = fwd * along * keep + out * push_speed * ratio
	else:
		# Tubul culcat: ricosezi inapoi si spre exterior, nu te opresti in el.
		horizontal = fwd * along * ricochet_keep + out * push_speed * ratio
	HazardThrow.throw(car, _body, horizontal, throw_rise * ratio, clear_seconds)
	# Si zona de ghiont e exceptata: doar corpul solid conta pentru solver, dar
	# masina aruncata nu trebuie re-prinsa de zona in cadrul urmator (cooldown).
	var sgn := signf(out.cross(Vector3.UP).dot(-car.global_transform.basis.z))
	car.spin_body(spin_rate * ratio * (sgn if absf(sgn) > 0.01 else 1.0),
		spin_seconds)
	car.crush(crush_seconds, crush_factor, Vector3(1.2, 0.62, 1.2), 1.0)
	throws += 1
	if strike:
		strike_throws += 1
	car_thrown.emit(car, strike)
