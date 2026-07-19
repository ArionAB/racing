class_name Minimap
extends Control
## Minimapa din coltul HUD-ului: conturul pistei + puncte pentru masini.
## Proiectie simpla XZ -> 2D, nord in sus (aceeasi orientare ca snapshot-ul).

const MAP_SIZE: float = 150.0
const PADDING: float = 10.0

var _points: PackedVector2Array = PackedVector2Array()
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
	draw_rect(Rect2(0, 0, MAP_SIZE, MAP_SIZE), Color(0, 0, 0, 0.25))
	draw_polyline(_points, Color(1, 1, 1, 0.75), 3.0)
	for car in _cars:
		if not is_instance_valid(car):
			continue
		var pos := _to_map(car.global_position)
		if car.is_player:
			draw_circle(pos, 6.0, Color(1.0, 0.85, 0.2))
		else:
			draw_circle(pos, 4.5, car.body_color)
