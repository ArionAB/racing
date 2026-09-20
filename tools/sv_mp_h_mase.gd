extends Node
## Cota SOLULUI real sub fiecare masa de piatra a lui H, si cat pluteste/erupe
## piesa fata de el. Raycast filtrat pe TerrainBody (memoria
## terrain-mesh-y-extrapoleaza + filtrarea pe numele corpului lovit).
const TRACK := "res://scenes/tracks/Track15.tscn"
const MASE := [
	["masaPiatra267", Vector3(-187.65, 5.52, 41.32)],
	["masaPiatra268", Vector3(-172.74, -12.06, 73.96)],
	["masaPiatra269", Vector3(-162.15, -19.00, 108.02)],
	["masaPiatra270", Vector3(-159.66, -19.00, 154.55)],
]

func _ready() -> void:
	var t: Node = load(TRACK).instantiate()
	add_child(t)
	await get_tree().process_frame
	await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	print("piesa            talpa      sol_real   delta   (delta<0 = ingropata, >0 = pluteste)")
	for m in MASE:
		var nume: String = m[0]
		var p: Vector3 = m[1]
		var sol := _sol(space, p)
		if is_nan(sol):
			print("%-15s %8.2f   NIMIC LOVIT" % [nume, p.y])
		else:
			print("%-15s %8.2f   %8.2f  %+7.2f" % [nume, p.y, sol, p.y - sol])
	get_tree().quit()

func _sol(space: PhysicsDirectSpaceState3D, p: Vector3) -> float:
	var par := PhysicsRayQueryParameters3D.create(
		Vector3(p.x, p.y + 400.0, p.z), Vector3(p.x, p.y - 400.0, p.z))
	par.collide_with_areas = false
	for _i in 12:
		var hit := space.intersect_ray(par)
		if hit.is_empty():
			return NAN
		var col: Object = hit.get("collider")
		var nume := String(col.name) if col != null else ""
		if nume.findn("terrain") >= 0:
			return float(hit["position"].y)
		par.from = Vector3(p.x, float(hit["position"].y) - 0.05, p.z)
	return NAN
