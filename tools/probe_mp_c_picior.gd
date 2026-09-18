extends Node
## Sub fiecare picior al portii: e teren, sau e aer? Poarta scalata 1,759 are
## 29,55 m latime pe un drum de 13,0, deci usciorii exteriori ies 8,28 m de
## fiecare parte. Captura arata piciorul din dreapta plutind; sonda spune cu cat.

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
	var i := int(0.2250 * float(n)) % n
	var p: Vector3 = _track.baked[i]
	var s: Vector3 = _track._side_at(i)
	var half: float = _track.width_at_index(i)
	print("; poarta la frac 0,2250, drum %.1f m, cota sosea %.2f" % [2.0 * half, p.y])
	print("; pozitiile pe latimea piesei (x local * scara), cota terenului, si cat pluteste")
	# main_gate: usciorii interiori la +-3,70 (golul 7,39), exteriori pana la +-8,40
	var scl := 1.759
	for xl: float in [-8.40, -6.50, -3.70, 0.0, 3.70, 6.50, 8.40]:
		var d := xl * scl
		var q: Vector3 = p + s * d
		var gy := _sol(q.x, q.z)
		var plut := p.y - gy
		var eticheta := "AER" if plut > 1.5 else "teren"
		print("; x_local %+6.2f -> %+7.2f m de ax, cota %8.2f, sub sosea %+7.2f  %s" % [
			xl, d, gy, -plut, eticheta])
	get_tree().quit(0)

func _sol(x: float, z: float) -> float:
	var space := (_track as Node3D).get_world_3d().direct_space_state
	var par := PhysicsRayQueryParameters3D.create(Vector3(x, 400.0, z), Vector3(x, -600.0, z))
	par.collide_with_areas = false
	par.exclude = []
	var hit := space.intersect_ray(par)
	var g := 0
	while not hit.is_empty() and hit["rid"] != _rid and g < 24:
		par.exclude = par.exclude + [hit["rid"]]
		hit = space.intersect_ray(par)
		g += 1
	return -999.0 if hit.is_empty() else (hit["position"] as Vector3).y
