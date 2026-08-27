extends Node
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track12.tscn") as PackedScene).instantiate() as Track
	add_child(t)
	for i in 8: await get_tree().process_frame
	await get_tree().physics_frame
	var r := t.routes[0]
	var n := r.count()
	var f := 0.7558
	var best := -1; var bd := INF
	for i in n:
		var d := absf(r.frac_at(i) - f)
		if d < bd: bd = d; best = i
	var p: Vector3 = r.baked[best]
	var fwd := (r.baked[r.wrap_index(best+1)] - r.baked[r.wrap_index(best-1)])
	fwd.y = 0.0; fwd = fwd.normalized()
	# devierea soselei fata de linia dreapta prin p, masurata pe indicii vecini
	for half in [40, 34, 30, 26, 22, 18]:
		var maxdev := 0.0; var maxdy := 0.0
		for k in range(best - 30, best + 31):
			var rp: Vector3 = r.baked[r.wrap_index(k)]
			var d3 := rp - p
			var along := d3.x * fwd.x + d3.z * fwd.z
			if absf(along) > float(half): continue
			var lat := Vector2(d3.x - fwd.x*along, d3.z - fwd.z*along).length()
			maxdev = maxf(maxdev, lat); maxdy = maxf(maxdy, absf(d3.y))
		print("+-%d m: dev %.2f  dy %.2f" % [half, maxdev, maxdy])
	var s := Vector3(fwd.z, 0.0, -fwd.x)
	print("side ", s, "  fwd ", fwd, "  yaw ", atan2(fwd.x, fwd.z))
	for off in [10.0, 16.0, 24.0, 32.0]:
		var q := p + s * off
		var q2 := p - s * off
		print("dr +%.0f: teren %.1f drop %.1f   |  st -%.0f: teren %.1f drop %.1f" % [
			off, t._sampler.ground_y(q.x,q.z), p.y - t._sampler.ground_y(q.x,q.z),
			off, t._sampler.ground_y(q2.x,q2.z), p.y - t._sampler.ground_y(q2.x,q2.z)])
	get_tree().quit()
