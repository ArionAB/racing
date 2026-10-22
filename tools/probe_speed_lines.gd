extends Node
## Liniile de viteza (feel: sense-of-speed, partea vizuala): ascunse sub prag,
## intensitate monotona cu viteza, vizibile cat arde turbo-ul, ascunse la loc.
##
## Masoara pe masina REALA (Car.horizontal_speed / max_speed / is_boosting), nu pe
## o fractie inventata: curba statica `intensity_for` e doar comparata cu ce
## afiseaza nodul. Aspectul se verifica cu o captura (fereastra), nu de aici.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSpeedLines.tscn

const SpeedLinesScript := preload("res://scenes/ui/speed_lines.gd")

var _failed: bool = false
var _car: Car
var _lines: SpeedLinesScript


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _ready() -> void:
	var ground := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(2000, 1, 2000)
	cs.shape = sh
	ground.add_child(cs)
	ground.position = Vector3(0, -0.5, 0)
	add_child(ground)
	_car = Car.new()
	add_child(_car)
	_car.global_position = Vector3(0, 0.7, 0)
	_car.race_active = true
	_lines = SpeedLinesScript.new()
	_lines.target = _car
	add_child(_lines)
	await get_tree().physics_frame
	print("")
	print("=== Linii de viteza ===")
	_check(not _lines.visible, "fara viteza: stratul ascuns")

	# Curba pe masina reala: tine viteza la fractia dorita si lasa netezirea sa se aseze.
	var fracs: Array[float] = [0.0, 0.5, 0.69, 0.78, 0.86, 0.94, 1.0]
	var got: Array[float] = []
	var vis: Array[bool] = []
	for f in fracs:
		var real_frac := 0.0
		for _i in 50:
			_car.linear_velocity = Vector3(0, 0, -f * _car.max_speed)
			await get_tree().process_frame
			real_frac = _car.horizontal_speed() / _car.max_speed
		got.append(_lines.intensity())
		vis.append(_lines.visible)
		var want := SpeedLinesScript.intensity_for(real_frac, false)
		print("  viteza %.0f%% (real %.0f%%): intensitate %.2f (curba %.2f), vizibil=%s"
			% [f * 100.0, real_frac * 100.0, got.back(), want, str(vis.back())])
	_check(not vis[0] and not vis[1] and not vis[2], "ascunse la 0%, 50%, 69%")
	_check(got[0] == 0.0 and got[1] == 0.0 and got[2] == 0.0, "intensitate 0 sub prag")
	_check(vis[3] and vis[4] and vis[5] and vis[6], "vizibile la 78%..100%")
	var mono := true
	for i in range(3, got.size()):
		if got[i] <= got[i - 1] + 0.01:
			mono = false
	_check(mono, "intensitatea creste strict cu viteza (78% -> 100%)")
	_check(got[6] > 0.9 and got[6] <= 1.0, "aproape de 1 la viteza maxima")

	# Turbo la viteza mica: vizibil, apoi se stinge.
	_car.force_boost(0.6)
	for _i in 30:
		_car.linear_velocity = Vector3(0, 0, -0.3 * _car.max_speed)
		await get_tree().process_frame
	var boosting := _car.is_boosting
	print("  turbo la 30%% viteza: is_boosting=%s, intensitate %.2f, vizibil=%s"
		% [str(boosting), _lines.intensity(), str(_lines.visible)])
	_check(boosting and _lines.visible and _lines.intensity() >= _lines.turbo_floor - 0.02,
		"turbo: vizibile chiar si la viteza mica")
	for _i in 120:
		_car.linear_velocity = Vector3(0, 0, -0.3 * _car.max_speed)
		await get_tree().process_frame
	_check(not _car.is_boosting and not _lines.visible,
		"dupa turbo: ascunse din nou (cost zero)")

	# Fara masina: ascuns.
	_lines.target = null
	await get_tree().process_frame
	_check(not _lines.visible, "fara tinta: ascuns")

	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)
