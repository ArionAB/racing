extends Node
## Unde anume, in FRACTII, cade tablierul podului de franghie — si ce cota are
## solul exact acolo. Podul e un nod cu transform absolut (13.71, -20, -154.99)
## si capete locale +/-17.12 pe X; fractia se afla proiectand pe traseu.
const TRACK := "res://scenes/tracks/Track15.tscn"
func _ready() -> void:
	await get_tree().process_frame
	var t := (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4: await get_tree().process_frame
	var pod := t.find_child("PodFranghie", true, false) as Node3D
	if pod == null:
		print("nu gasesc PodFranghie"); get_tree().quit(1); return
	var n := t.baked.size()
	var sus := -INF
	for bp in t.baked: sus = maxf(sus, bp.y)
	sus += 200.0
	var sp := t.get_world_3d().direct_space_state
	var sol := func(x: float, z: float) -> float:
		var q := PhysicsRayQueryParameters3D.create(Vector3(x, sus, z), Vector3(x, -400.0, z))
		q.collide_with_areas = false
		var r := sp.intersect_ray(q)
		return float((r["position"] as Vector3).y) if not r.is_empty() else -999.0
	print("pod la %s" % str(pod.global_transform.origin))
	for nume: String in ["near_end", "far_end"]:
		var loc: Vector3 = pod.get(nume)
		var w: Vector3 = pod.global_transform * loc
		var best := -1
		var bd := 1e9
		for j in n:
			var dd: float = Vector2(t.baked[j].x - w.x, t.baked[j].z - w.z).length()
			if dd < bd: bd = dd; best = j
		print("  %-9s lume %s  frac %.4f  ax_y %+.1f  SOL %+.1f  =>  gol sub tablier %.1f m"
			% [nume, str(w.round()), float(best)/float(n), t.baked[best].y,
			   sol.call(w.x, w.z), w.y - sol.call(w.x, w.z)])
	# si la mijlocul tablierului
	var mid: Vector3 = pod.global_transform * ((pod.get("near_end") as Vector3 + pod.get("far_end") as Vector3) * 0.5)
	print("  mijloc    lume %s  SOL %+.1f  =>  gol sub tablier %.1f m"
		% [str(mid.round()), sol.call(mid.x, mid.z), mid.y - sol.call(mid.x, mid.z)])
	get_tree().quit(0)
