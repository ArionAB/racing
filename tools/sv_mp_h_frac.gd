extends Node
## Unde cad in frac piesele masaPiatra, si unde e camera la 0.95/0.97/0.99.
func _ready() -> void:
	var ps := load("res://scenes/tracks/Track15.tscn") as PackedScene
	var t := ps.instantiate()
	add_child(t)
	await get_tree().process_frame
	var tr := t as Track
	var n := tr.baked.size()
	var targets := {
		"masaPiatra267": Vector3(-164.16, -19.00, 31.86),
		"masaPiatra268": Vector3(-164.16, -19.00, 65.98),
		"masaPiatra269": Vector3(-162.75, -19.00, 94.00),
		"masaPiatra270": Vector3(-164.89, -19.00, 118.85),
	}
	for k in targets:
		var q: Vector3 = targets[k]
		var best := -1
		var bd := 1e18
		for i in n:
			var d: float = (tr.baked[i] - q).length()
			if d < bd:
				bd = d
				best = i
		var p: Vector3 = tr.baked[best]
		var half: float = tr.width_at_index(best)
		print("%s frac=%.4f dist_ax=%.1f half=%.2f sosea_y=%.2f varf=%.1f m peste sosea" % [
			k, float(best) / float(n), bd, half, p.y, (q.y + 33.0) - p.y])
	for f in [0.95, 0.97, 0.99]:
		var i := int(f * float(n)) % n
		print("cam frac %.2f -> poz=(%.1f,%.1f,%.1f) half=%.2f" % [
			f, tr.baked[i].x, tr.baked[i].y, tr.baked[i].z, tr.width_at_index(i)])
	get_tree().quit()
