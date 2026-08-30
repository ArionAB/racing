extends Node
## PROFILUL VAII pe raza spre dreapta, pana departe.
##
## De ce exista: capturile rundei 4 arata faleza ca pe o BORDURA de sant — se
## vede PESTE ea, la dealuri de dincolo. ProbeFacing nu prinde asta: fata poate
## fi perfect orientata spre camera si tot sa aiba 4 m aparenti, daca terenul de
## dincolo urca inapoi la cota drumului. Unghiul e corect, silueta nu.
##
## Aici se masoara ce vede ochiul pe raza: cotele la distante crescande si CEA
## MAI INALTA cota de dincolo de buza. Daca maximul de dincolo trece de cota
## soselei, faleza nu poate citi ca un canion, oricat de adanca ar fi local.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"


func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var s: TrackSideSampler = t.get("_sampler")
	var n := s.point_count()
	var space := get_viewport().world_3d.direct_space_state
	for f: float in [0.20, 0.22, 0.25, 0.28, 0.31, 0.34]:
		var i := int(f * float(n)) % n
		var p := s.baked_point(i)
		var sd := s.side_at(i)
		print("\n=== frac %.2f — sosea y=%.1f ===" % [f, p.y])
		var line := "   "
		var worst := -999.0
		var worst_d := 0.0
		var floor_y := 999.0
		for d: float in [6, 12, 20, 30, 45, 60, 80, 110, 150, 200]:
			var q := p + sd * d
			var pr := PhysicsRayQueryParameters3D.create(
				Vector3(q.x, p.y + 200.0, q.z), Vector3(q.x, p.y - 400.0, q.z))
			var hit := space.intersect_ray(pr)
			if hit.is_empty():
				line += "%d:- " % int(d)
				continue
			var y := (hit["position"] as Vector3).y
			line += "%d:%.0f " % [int(d), y]
			floor_y = minf(floor_y, y)
			if d >= 25.0 and y > worst:
				worst = y
				worst_d = d
		print(line)
		var verdict := "URCA INAPOI — citeste ca bordura" if worst > p.y - 10.0 else "cade — ok"
		print("   fund %.1f · maxim dincolo de 25 m: %.1f (la %dm) · sosea %.1f => %s" % [
			floor_y, worst, int(worst_d), p.y, verdict])
	get_tree().quit()
