extends Node
## Profilul FIN al buzei la fractiile candidate pentru pinten: unde anume,
## masurat in offset fata de muchie, mai e teren care tine o stanca.

var _track: Node
var _rid: RID

func _ready() -> void:
	var ps := load("res://scenes/tracks/Track15.tscn") as PackedScene
	_track = ps.instantiate()
	add_child(_track)
	await get_tree().process_frame
	for c in _track.get_children():
		if str(c.name) == "TerrainBody":
			_rid = (c as StaticBody3D).get_rid()
	var n: int = _track.baked.size()
	for f: float in [0.2400, 0.2448, 0.2500, 0.2550, 0.2605, 0.2650]:
		var i := int(f * float(n)) % n
		var p: Vector3 = _track.baked[i]
		var s: Vector3 = _track._side_at(i)
		var half: float = _track.width_at_index(i)
		for sg: float in [-1.0, 1.0]:
			var row := "; frac %.4f parte %+2.0f  ORICE |" % [f, sg]
			var rowt := ";                     TEREN |"
			for off: float in [-3.0, -2.0, -1.0, -0.5, 0.0, 0.5, 1.0, 2.0, 3.0, 5.0]:
				var q: Vector3 = p + s * sg * (half + off)
				row += " %+7.2f" % (_sol(q.x, q.z) - p.y)
				rowt += " %+7.2f" % (_sol_teren(q.x, q.z) - p.y)
			print(row)
			print(rowt)
	print("; coloane offset: -3 -2 -1 -0.5 0 +0.5 +1 +2 +3 +5 (cote fata de sosea)")
	get_tree().quit(0)

## DOUA cote: prima coliziune (orice corp) si TERENUL propriu-zis. Diferenta
## dintre ele e chiar capcana care a refuzat pintenul: "banca" de la +1 m
## dincolo de muchie e umarul DALEI DE DRUM, nu teren.
func _sol(x: float, z: float) -> float:
	return _ray(x, z, false)

func _sol_teren(x: float, z: float) -> float:
	return _ray(x, z, true)

func _ray(x: float, z: float, doar_teren: bool) -> float:
	var space := (_track as Node3D).get_world_3d().direct_space_state
	var par := PhysicsRayQueryParameters3D.create(Vector3(x, 400.0, z), Vector3(x, -600.0, z))
	par.collide_with_areas = false
	par.exclude = []
	var hit := space.intersect_ray(par)
	if not doar_teren:
		return -999.0 if hit.is_empty() else (hit["position"] as Vector3).y
	var g := 0
	while not hit.is_empty() and hit["rid"] != _rid and g < 24:
		par.exclude = par.exclude + [hit["rid"]]
		hit = space.intersect_ray(par)
		g += 1
	return -999.0 if hit.is_empty() else (hit["position"] as Vector3).y
