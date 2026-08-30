extends Node
## Masuratori pentru POI A — PIATA DIN GOREME (Track13, frac ~0.97-0.04).
## (a) gabaritul fiecarui GLB folosit in piata (inaltime reala, raza la baza,
##     cota bazei fata de origine — o piesa cu baza la y<0 se ingroapa singura),
## (b) geometria benzii in jurul liniei de start: pozitie, laterala, latime,
##     cota terenului la 6/10/16/24 m in stanga si in dreapta.
##
## Fara (a) caruta pluteste sau intra in asfalt; fara (b) casele-con se aseaza
## pe cota soselei si raman suspendate acolo unde piata coboara.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappA.tscn -- --track=6

const MODELS: Array[String] = [
	"buildings/cave_house_a", "buildings/cave_house_b", "buildings/cave_house_c",
	"buildings/dovecote",
	"props/carpet_terrace", "props/pottery_cart", "props/pot_stack",
	"plants/poplar_a", "plants/poplar_b", "plants/shrub_dry", "plants/pigeon",
	"rocks/chimney_a", "rocks/chimney_b", "rocks/chimney_c", "rocks/chimney_d",
	"rocks/chimney_mushroom",
]


func _ready() -> void:
	await get_tree().process_frame
	print("")
	print("=== gabarite GLB (POI A) ===")
	for m in MODELS:
		var ps := load("res://assets/models/cappadocia/%s.glb" % m) as PackedScene
		if ps == null:
			print("  %-26s LIPSA" % m)
			continue
		var inst := ps.instantiate()
		get_tree().root.add_child(inst)
		var aabb := _aabb(inst, inst.global_transform)
		print("  %-26s h=%6.2f  x=%6.2f  z=%6.2f  baza_y=%+6.2f  cx=%+5.2f cz=%+5.2f  raza=%5.2f" % [
			m, aabb.size.y, aabb.size.x, aabb.size.z, aabb.position.y,
			aabb.get_center().x, aabb.get_center().z,
			0.5 * maxf(aabb.size.x, aabb.size.z)])
		inst.queue_free()

	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var sampler: TrackSideSampler = track._sampler
	var n := track.baked.size()
	print("")
	print("=== banda in piata (n=%d puncte coapte) ===" % n)
	print("  frac      i     x        y        z      w    | sideX  sideZ | g-24  g-16  g-10  g-6  |  g+6  g+10  g+16  g+24")
	# Piata se intinde peste linia de start, deci fractiile se citesc si de
	# dinainte de 0 (0.96..1.0) si de dupa.
	var fr: Array[float] = []
	var f := 0.955
	while f < 1.0:
		fr.append(f)
		f += 0.005
	f = 0.0
	while f <= 0.045:
		fr.append(f)
		f += 0.0025
	for fv in fr:
		var i := int(fv * float(n)) % n
		var p := track.baked[i]
		var s := track._side_at(i)
		var w := track.width_at_index(i)
		var row := "  %.4f %4d  %8.2f %7.2f %8.2f  %4.1f | %5.2f %5.2f |" % [fv, i, p.x, p.y, p.z, w, s.x, s.z]
		for d: float in [-24.0, -16.0, -10.0, -6.0, 6.0, 10.0, 16.0, 24.0]:
			var q: Vector3 = p + s * d
			row += " %6.2f" % sampler.ground_y(q.x, q.z)
		print(row)
	print("")
	# Directia umbrei pe XZ, MASURATA din lumina scenei, nu deriva din euler
	# (lectia POI B: prima derivare iesise pe dos).
	var sun: DirectionalLight3D = null
	for c in _all(track):
		if c is DirectionalLight3D:
			sun = c
			break
	if sun != null:
		var d3 := -sun.global_transform.basis.z # directia in care merge lumina
		var sh := Vector2(d3.x, d3.z).normalized()
		print("=== soare === dir_lumina=(%.3f, %.3f, %.3f)  umbra_pe_XZ=(%.3f, %.3f)" % [
			d3.x, d3.y, d3.z, sh.x, sh.y])
		# Pe ce parte a benzii trebuie sa stea o piesa ca umbra ei sa TAIE drumul?
		for fv: float in [0.99, 0.0, 0.02]:
			var i := int(fv * float(n)) % n
			var s := track._side_at(i)
			var dp := Vector2(s.x, s.z).dot(sh)
			print("  frac %.3f: dot(side, umbra) = %+.3f -> partea insorita e %s" % [
				fv, dp, "-side" if dp > 0.0 else "+side"])
	print("")
	get_tree().quit(0)


func _aabb(node: Node, root_t: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	for c in _all(node):
		if c is MeshInstance3D and c.visible and (c as MeshInstance3D).mesh != null:
			var local := root_t.affine_inverse() * (c as MeshInstance3D).global_transform
			var b := local * (c as MeshInstance3D).mesh.get_aabb()
			if first:
				out = b
				first = false
			else:
				out = out.merge(b)
	return out


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for c in node.get_children():
		out.append_array(_all(c))
	return out
