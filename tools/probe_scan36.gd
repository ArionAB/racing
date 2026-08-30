extends Node
## Ce vede cautarea de fund din _column la frac 0.36: profilul CAMPULUI
## (surface_y), nu al mesh-ului, si unde s-ar opri conditia actuala.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4: await get_tree().process_frame
	var smp = t._sampler
	var r = t.routes[0]
	var n: int = r.baked.size()
	for f in [0.36, 0.28]:
		var i := int(round(f * float(n))) % n
		var p: Vector3 = smp.baked_point(i)
		var sd: Vector3 = smp.side_at(i) * 1.0
		var hw: float = smp.half_width_at(i)
		print("--- frac %.2f lip_y=%.1f hw=%.1f" % [f, p.y, hw])
		var lip: Vector3 = p + sd * (hw + 0.2)
		var far := hw + 4.0
		var prev := p.y
		var stopped := -1.0
		while far < hw + 200.0:
			var q: Vector3 = lip + sd * (far - hw - 0.2)
			var gy: float = smp.height_at(q.x, q.z)
			var flag := ""
			if gy > prev - 0.15 and far > hw + 8.0 and stopped < 0.0:
				stopped = far; flag = "  <== conditia opreste AICI"
			if true:
				print("   far=%6.1f  gy=%7.1f (dy %6.1f)%s" % [far, gy, gy - p.y, flag])
			prev = gy
			far += 6.0
		print("   oprire la far=%.1f" % stopped)
	get_tree().quit(0)
