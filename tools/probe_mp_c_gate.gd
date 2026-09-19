extends Node
## Poate poarta sa stea la o fractie DE UNDE SE VEDE de la 0.24 (fractia
## judecata), pastrand contractul: gol 13,98 m pe un drum de semi-latime 6,5,
## si drum aproape drept (raza > 200 m)?

func _ready() -> void:
	var ps := load("res://scenes/tracks/Track15.tscn") as PackedScene
	var t := ps.instantiate()
	add_child(t)
	await get_tree().process_frame
	var n: int = t.baked.size()
	print("; frac    half   marja_totala  raza_m   abatere_pe_5m")
	var f := 0.220
	while f <= 0.290:
		var i := int(f * float(n)) % n
		var half: float = t.width_at_index(i)
		var a: Vector3 = t.baked[(i - 3 + n) % n]
		var b: Vector3 = t.baked[i]
		var c: Vector3 = t.baked[(i + 3) % n]
		var t0 := Vector3(b.x - a.x, 0.0, b.z - a.z)
		var t1 := Vector3(c.x - b.x, 0.0, c.z - b.z)
		var l := t0.length() + t1.length()
		var curv := 0.0
		if l > 0.01:
			curv = t1.normalized().angle_to(t0.normalized()) / (l * 0.5)
		var raza := 1.0 / maxf(absf(curv), 1e-6)
		print("; %.4f  %5.2f   %+6.2f      %7.0f   %6.3f" % [
			f, half, 13.98 - 2.0 * half, raza, 25.0 / (2.0 * maxf(raza, 1.0))])
		f += 0.0045
	get_tree().quit(0)
