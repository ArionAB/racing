extends Node
## Emite Transform3D-urile finale pentru blocurile de sub piata, derivate din
## curba baked (cadrul REAL) + profilul de teren + linia de vedere.
const MODEL_H := 24.9   # inaltimea liziba_block nescalat
const MODEL_X := 40.6   # latura lunga (fete fara ferestre)
const MODEL_Z := 27.24  # latura cu FERESTRE (slot 30) — normala ei spre drum

func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var c: Curve3D = (track.get_node("Path") as Path3D).curve
	var L := c.get_baked_length()
	# fractie, distanta laterala, scara pe lungime (X), scara pe adancime (Z)
	var plan := [
		{"f": 0.0045, "d": 27.0, "sx": 0.85, "sz": 0.55},
		{"f": 0.0125, "d": 28.0, "sx": 0.85, "sz": 0.55},
		{"f": 0.0205, "d": 29.0, "sx": 0.85, "sz": 0.55},
	]
	var idx := 0
	for e: Dictionary in plan:
		idx += 1
		var f: float = e["f"]
		var d: float = e["d"]
		var sx: float = e["sx"]
		var sz: float = e["sz"]
		var s: float = f * L
		var p := c.sample_baked(s)
		var p2 := c.sample_baked(minf(s + 3.0, L))
		var fwd := (p2 - p).normalized()
		var right := fwd.cross(Vector3.UP).normalized()
		# teren si linie de vedere la distanta d
		var o: Vector3 = p + right * d + Vector3.UP * 60.0
		var q := PhysicsRayQueryParameters3D.create(o, o + Vector3.DOWN * 220.0)
		var h := space.intersect_ray(q)
		var ground: float = h.position.y if not h.is_empty() else 23.0
		# panta care rade buza, ochi pe axa (cazul cel mai strans)
		var eye_y: float = p.y + 10.0
		var best_m := -1e9
		# Ocluzia o face DOAR terenul dintre masina si bloc: buza de dincolo de
		# bloc nu poate ascunde blocul. Cautam pe pasi de 0.5 m pana la d.
		for i in range(6, int(d * 2.0)):
			var dd: float = float(i) * 0.5
			var oo: Vector3 = p + right * dd + Vector3.UP * 60.0
			var qq := PhysicsRayQueryParameters3D.create(oo, oo + Vector3.DOWN * 220.0)
			var hh := space.intersect_ray(qq)
			if hh.is_empty(): continue
			var m: float = (float(hh.position.y) - eye_y) / dd
			if m > best_m: best_m = m
		var see_below: float = eye_y + best_m * d
		# Varful se aseaza FIX pe linia de vedere care rade buza. Sub ea blocul
		# dispare cu totul; peste ea acoperisul (28x12 m de placa orizontala)
		# intra in cadru si citeste ca o rampa palida. Pe ea acoperisul e vazut
		# din muchie (arie de ecran aproape 0) si ramane doar fatada de dedesubt.
		# Blocul STA PE FUNDUL rapei. Peretele de sub piata e vertical si
		# subspalat: razele care trec de buza (d~8) nu revin pe teren decat pe
		# la d~25, deci orice piesa mai apropiata cade in conul de umbra al
		# buzei si nu se vede deloc, oricat de sus ar fi ridicata.
		var base: float = ground
		var top: float = base + MODEL_H

		# baza X spre inainte, Z (fata cu ferestre) spre drum = -right
		var bx := fwd * sx
		var by := Vector3.UP
		var bz := -right * sz
		if bx.cross(by).dot(bz) < 0.0:
			bx = -bx
		var pos: Vector3 = p + right * d
		pos.y = base
		var b := Basis(bx, by, bz)
		var t := Transform3D(b, pos)
		print("bloc%d: frac=%.4f d=%.1f teren=%.1f vezi_sub=%.1f top=%.1f baza=%.1f  lung=%.1f adanc=%.1f"
			% [idx, f, d, ground, see_below, top, base, MODEL_X * sx, MODEL_Z * sz])
		print("transform = Transform3D(%.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.3f, %.3f, %.3f)"
			% [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z, pos.x, pos.y, pos.z])
	get_tree().quit()
