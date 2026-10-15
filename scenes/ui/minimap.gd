class_name Minimap
extends Control
## Minimapa din coltul HUD-ului: conturul pistei + puncte pentru masini.
## Proiectie simpla XZ -> 2D, nord in sus (aceeasi orientare ca snapshot-ul).

const MAP_SIZE: float = 150.0
const PADDING: float = 10.0

var _points: PackedVector2Array = PackedVector2Array()
## Linia de start/sosire pe minimapa: primul punct al traseului, acolo unde
## `Track` incepe bucla. Jucatorul vede astfel cat mai are pana la tur, nu
## doar unde e.
var _finish: Vector2 = Vector2.ZERO
var _cars: Array[Car] = []
var _scale: float = 1.0
var _offset: Vector2 = Vector2.ZERO

func setup(track: Track, cars: Array[Car]) -> void:
	_cars = cars
	var bmin := Vector2(track.baked[0].x, track.baked[0].z)
	var bmax := bmin
	for p in track.baked:
		bmin = bmin.min(Vector2(p.x, p.z))
		bmax = bmax.max(Vector2(p.x, p.z))
	var extent := bmax - bmin
	_scale = (MAP_SIZE - PADDING * 2.0) / maxf(extent.x, extent.y)
	# centram forma in patratul minimapa
	_offset = Vector2(MAP_SIZE, MAP_SIZE) * 0.5 - (bmin + extent * 0.5) * _scale
	_points.clear()
	for i in range(0, track.baked.size(), 3):
		_points.append(_to_map(track.baked[i]))
	if not _points.is_empty():
		_finish = _points[0]
		_points.append(_points[0]) # inchidem bucla
	custom_minimum_size = Vector2(MAP_SIZE, MAP_SIZE)
	set_process(true)

func _to_map(world: Vector3) -> Vector2:
	return Vector2(world.x, world.z) * _scale + _offset

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _points.is_empty():
		return
	# Cutia rotunjita si rama subtire: aceeasi forma ca panoul de telemetrie si
	# butoanele, ca minimapa sa faca parte din acelasi strat de HUD.
	var box := Rect2(0, 0, MAP_SIZE, MAP_SIZE)
	draw_style_box(RaceHUD._panel_style(14), box)
	# Traseul se deseneaza de doua ori: un contur gros si intunecat dedesubt,
	# linia alba peste el. Fara conturul de dedesubt, linia dispare cand trece
	# peste zapada sau nisip — fundalul minimapei e translucid.
	draw_polyline(_points, Color(0, 0, 0, 0.55), 5.0)
	draw_polyline(_points, Color(1, 1, 1, 0.85), 3.0)
	_draw_finish_flag()
	for car in _cars:
		if not is_instance_valid(car):
			continue
		var pos := _to_map(car.global_position)
		# Acelasi motiv ca la traseu: punctul primeste un inel intunecat, ca o
		# masina de culoare deschisa sa nu se piarda peste minimapa translucida.
		var radius := 6.0 if car.is_player else 4.5
		draw_circle(pos, radius + 1.5, Color(0, 0, 0, 0.6))
		draw_circle(pos, radius,
			Color(1.0, 0.85, 0.2) if car.is_player else car.body_color)


## Steguletul de sosire: patratele alb-negru de 3 px, doua randuri. Desenat
## cu patratele, nu cu o textura — o imagine de 12x8 px ar fi insemnat un
## import, un .import si un material in plus pentru ceva ce codul deseneaza
## in sase linii.
const FLAG_CELL: float = 3.0

func _draw_finish_flag() -> void:
	var origin := _finish - Vector2(FLAG_CELL * 2.0, FLAG_CELL * 3.0)
	# Fundal negru sub tot steguletul: pe o pista deschisa la culoare,
	# patratele albe ar disparea si ar ramane doar jumatate din sah.
	draw_rect(Rect2(origin - Vector2.ONE,
		Vector2(FLAG_CELL * 4.0 + 2.0, FLAG_CELL * 2.0 + 2.0)),
		Color(0, 0, 0, 0.85))
	for row in 2:
		for col in 4:
			if (row + col) % 2 == 1:
				continue
			draw_rect(Rect2(origin + Vector2(col, row) * FLAG_CELL,
				Vector2(FLAG_CELL, FLAG_CELL)), Color(1, 1, 1, 0.95))
