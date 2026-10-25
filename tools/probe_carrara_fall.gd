extends Node
## Plasele de repunere ale teraselor Carrara: o masina asezata pe platoul de SUB o fata (unde ar
## ateriza dupa o cadere peste muchie) trebuie sa fie REPUSA de RespawnZone, iar una de pe bancul plat
## dintre berma si muchie nu. Masina e inghetata (pe grila de start), deci probeaza ACOPERIREA plaselor
## si lipsa declansarilor false, nu dinamica caderii (aceea se vede in ProbeRace: 0 repuneri din cadere).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCarraraFall.tscn
##
## Pozitiile sunt in coordonate de HARTA (x est, y nord; gz = -y), cota = suprafata terenului acolo
## + 0.6. Fiecare caz: masina statica, 5 s de fizica; `repusa` = a tras semnalul `respawned`.

## (nume, x, y, asteptat). Lateralele se socotesc de la axa drumului; E sta pe y = -112, T1 pe 105,
## T2 pe 67, T3 pe 29. Muchiile fetelor: T-uri la 12.5 m de axa, E la 11.5 m.
const CASES := [
	["E: banc plat (9 m de axa)", 0.0, -103.0, false],
	["E: treapta 1 (15 m de axa)", 0.0, -97.0, true],
	["E: treapta 3 (31 m de axa)", 0.0, -81.0, true],
	["T1: banc plat (9 m de axa)", -40.0, 96.0, false],
	["T1: platoul de sub fata (16 m de axa)", -40.0, 89.0, true],
	["T2: banc plat (9 m de axa, spre sud)", -40.0, 58.0, false],
	["T2: platoul de sub fata (16 m de axa)", -40.0, 51.0, true],
	["T3: banc plat (9 m de axa, spre sud)", -10.0, 20.0, false],
	["T3: fundul carierei (16 m de axa)", -10.0, 13.0, true],
]

var _track: Track
var _bad := 0


func _ready() -> void:
	await get_tree().process_frame
	_track = (load("res://scenes/tracks/Track23.tscn") as PackedScene).instantiate() as Track
	add_child(_track)
	for _i in 10:
		await get_tree().process_frame
	var data := load("res://scenes/cars/data/muscle.tres") as CarData
	for c in CASES:
		var res := await _drop(data, float(c[1]), float(c[2]))
		var expected: bool = c[3]
		var ok: bool = res["respawned"] == expected
		if not ok:
			_bad += 1
		print("  %-44s teren %6.2f  masina ajunge la y %6.2f  repusa: %-5s asteptat: %-5s %s" % [
			c[0], res["ground"], res["end_y"], str(res["respawned"]), str(expected),
			"OK" if ok else "PICA"])
	print("VERDICT: %s" % ("OK" if _bad == 0 else "PROBLEMA (%d cazuri)" % _bad))
	get_tree().quit(1 if _bad > 0 else 0)


func _drop(data: CarData, mx: float, my: float) -> Dictionary:
	var gz := -my
	var ground: float = _track._terrain_mesh_y(mx, gz)
	var car := (load("res://scenes/cars/Car.tscn") as PackedScene).instantiate() as Car
	car.track = _track
	add_child(car)
	car.apply_data(data)
	car.is_player = false
	var tr := Transform3D(Basis.looking_at(Vector3(-1, 0, 0), Vector3.UP), Vector3(mx, ground + 0.6, gz))
	car.global_transform = tr
	# cel mai apropiat punct de sosea, ca `respawn` sa stie unde il repune
	var best := 0
	var bd := 1e18
	for i in _track.baked.size():
		var p: Vector3 = _track.baked[i]
		var d := (p.x - mx) * (p.x - mx) + (p.z - gz) * (p.z - gz)
		if d < bd:
			bd = d
			best = i
	car.road_index = best
	car.on_start_grid = true
	var flag := [false]
	car.respawned.connect(func(_c: Car) -> void: flag[0] = true)
	for _f in 300:
		await get_tree().physics_frame
	var end_y := car.global_position.y
	car.queue_free()
	await get_tree().physics_frame
	return {"respawned": flag[0], "ground": ground, "end_y": end_y}
