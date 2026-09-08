extends Node
## Serpentina de la POI F pare o placa PLUTITOARE in captura de la 0.555:
## carosabilul are un intrados intunecat vizibil si nu se vede teren sub bucla.
## Se masoara golul dintre fata de jos a soselei si terenul de dedesubt.
## Un gol real inseamna teren care nu urca la sosea (defect de lume), nu shading.

func _ready() -> void:
	var scene := load(GameState.TRACK_SCENES[7]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var r: TrackRoute = track.routes[0]
	await get_tree().physics_frame
	var space := track.get_world_3d().direct_space_state
	var n := r.baked.size()
	var worst := 0.0
	var worst_at := Vector3.ZERO
	var holes := 0
	for i: int in range(0, 60):
		var f := 0.500 + 0.0035 * float(i)
		var k := int(f * float(n)) % n
		var p: Vector3 = r.baked[k]
		var from := p + Vector3.DOWN * 1.0
		var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 300.0)
		var hit := space.intersect_ray(q)
		var gap := 999.0
		var what := "(nimic sub asfalt)"
		if not hit.is_empty():
			gap = from.y - (hit["position"] as Vector3).y
			what = str((hit["collider"] as Node).name)
		if gap > 3.0:
			holes += 1
		print("  frac %.3f  (%7.1f,%6.1f,%7.1f)  gol=%7.2f m  %s" % [f, p.x, p.y, p.z, gap, what])
		if gap < 900.0 and gap > worst:
			worst = gap
			worst_at = p
	print("-> gol maxim %.2f m la (%.0f, %.1f, %.0f); %d puncte cu gol > 3 m" % [
		worst, worst_at.x, worst_at.y, worst_at.z, holes])
	get_tree().quit()
