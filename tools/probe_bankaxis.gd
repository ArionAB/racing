extends Node
## Unde ar trebui sa stea malul opus: punctul de pe raza exterioara la distanta
## ceruta, pentru fiecare frac de cornisa. Ca sa mut masivele pe cifre, nu din ochi.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	for f in [0.20, 0.24, 0.28, 0.32, 0.36, 0.40]:
		var i := int(f * n)
		var p: Vector3 = r.baked[i]
		var a: Vector3 = r.baked[(i + 4) % n]
		var side: Vector3 = (a - p).normalized().cross(Vector3.UP).normalized()
		var s: String = "frac %.2f drum(%.0f,%.0f) y=%.1f  side=(%.2f,%.2f) |" % [f, p.x, p.z, p.y, side.x, side.z]
		for d in [200.0, 260.0, 320.0]:
			var q: Vector3 = p + side * d
			s += "  +%dm=(%.0f,%.0f)" % [int(d), q.x, q.z]
		print(s)
	get_tree().quit(0)
