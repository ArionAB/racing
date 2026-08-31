extends Node
## CAT de mult intra terenul peste banda, in zona 0.74-0.80 de pe Cappadocia?
## Raporteaza, pentru fiecare frac, cea mai mica distanta laterala de la AXA la
## care terenul e deja solid la inaltimea caroseriei — plus cota terenului fata
## de asfalt. Asa se vede daca e nevoie de largit scobitura sau de mutat axa.

const LIFT: float = 1.0
const CAR_H: float = 1.4


func _ready() -> void:
	await get_tree().process_frame
	var idx := GameState.resolve_track_index(6)
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene) \
		.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var space := track.get_world_3d().direct_space_state
	var r: TrackRoute = track.routes[0]
	var n := r.baked.size()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.4, CAR_H, 0.4)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collide_with_areas = false

	print("frac   half   prima_intrare_lat   dy_teren_fata_de_asfalt")
	var f := 0.735
	while f <= 0.805:
		var i := int(f * float(n)) % n
		var p: Vector3 = r.baked[i]
		var fwd := (r.baked[(i + 1) % n] - p).normalized()
		var side := fwd.cross(Vector3.UP).normalized()
		var half: float = track.width_at_index(i)
		# de la marginea dreapta spre axa: unde apare prima data teren solid
		var first := 999.0
		var lat := half
		while lat >= -half:
			q.transform = Transform3D(Basis(), p + Vector3.UP * LIFT + side * lat)
			for hit in space.intersect_shape(q, 8):
				var b := hit.get("collider") as Node
				if b != null and String(b.name) == "TerrainBody":
					first = minf(first, lat)
			lat -= 0.25
		# cota terenului pe axa si pe marginea dreapta
		var ray := PhysicsRayQueryParameters3D.create(
			p + side * half + Vector3.UP * 60.0,
			p + side * half - Vector3.UP * 20.0)
		var hit_r := space.intersect_ray(ray)
		var dy := 0.0
		if not hit_r.is_empty():
			dy = (hit_r["position"] as Vector3).y - p.y
		print("%.3f  %5.2f   %s   %+6.2f" % [f, half,
			("%+6.2f" % first) if first < 900.0 else "  liber", dy])
		f += 0.005
	get_tree().quit(0)
