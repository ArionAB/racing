extends Node
## Sonda de GEOMETRIE Kyoto (kogarashi + trenul G2). Ruleaza ca SCENA, headless:
##   godot --headless --path . res://tools/ProbeKyotoFix.tscn
## Optional: PTS="x,z;x,z" (puncte de lume) pentru a le raporta ca distanta pe ruta.
##
## Raporteaza, in METRI pe curba coapta reala (route.dists), nu din fractii
## rotunjite: lungimea totala, capatul podului Tsutenkyo, kogarashi (distanta
## dupa pod, pana la intrarea in arcul E / tunelul de torii) si unghiul dintre
## axa lunga a figurii Lissajous si tangenta soselei (tinta: 90 grade).

const TRACK := "res://scenes/tracks/Track18.tscn"


func _d_of(route: TrackRoute, p: Vector3) -> float:
	return route.dists[route.closest_index_global(p)]


func _ready() -> void:
	var track: Track = (load(TRACK) as PackedScene).instantiate()
	add_child(track)
	for _i in 6:
		await get_tree().process_frame
	var route := track.route_at(0)
	var total: float = route.dists[route.baked.size()]
	print("lungime curba coapta: %.1f m" % total)
	var tsu := track.get_node("Poduri/Tsutenkyo")
	var d_end: float = float(tsu.get("frac_to")) * total
	var d_start: float = float(tsu.get("frac_from")) * total
	print("pod Tsutenkyo: %.1f - %.1f m (frac %.3f-%.3f, %.1f m lung)" % [
		d_start, d_end, float(tsu.get("frac_from")), float(tsu.get("frac_to")), d_end - d_start])
	var kog := track.get_node_or_null("Hazarduri/Kogarashi") as Node3D
	if kog != null:
		var i := route.closest_index_global(kog.global_position)
		var d: float = route.dists[i]
		var tan3: Vector3 = (route.baked[mini(i + 2, route.baked.size() - 1)] - route.baked[maxi(i - 2, 0)])
		var tan2 := Vector2(tan3.x, tan3.z).normalized()
		var yaw := deg_to_rad(float(kog.get("path_yaw_deg")))
		# X local rotit cu yaw in jurul lui Y (conventia Godot): (cos, -sin) in (x, z).
		var ax := Vector2(cos(yaw), -sin(yaw))
		var ang := rad_to_deg(acos(clampf(absf(ax.dot(tan2)), 0.0, 1.0)))
		var lat: float = Vector2(kog.global_position.x - route.baked[i].x, kog.global_position.z - route.baked[i].z).length()
		print("kogarashi: d=%.1f m (frac %.4f) = %.1f m dupa capatul podului; abatere laterala fata de axa %.1f m; unghi axa-Lissajous/tangenta = %.1f grade (tinta 90)" % [
			d, d / total, d - d_end, lat, ang])
		print("  pana la intrarea in arcul E (0.4833): %.1f m" % (0.4833 * total - d))
	# Unde incep tulpinile de bambus pe marginea soselei (POI G): minimul distantei pe
	# ruta (in fractie) peste tulpinile la <= LAT_MAX m lateral de axa. Manual
	# (gTufa*, coroane) si masa (MultiMesh moso_culm din PadureMasa).
	var lat_max := 20.0
	var first_stem := 1.0e9
	var first_crown := 1.0e9
	var n_stems := 0
	var forest := track.get_node_or_null("PadureMasa")
	if forest != null:
		# Pozitiile MultiMesh nu se pot citi headless (renderer dummy: toate (0,0,0),
		# memoria multimesh-masuratoare-moarta), deci se REFAC candidatii zonei de
		# tulpini cu aceeasi semanta si aceleasi reguli de margine (`_check`).
		for z in forest.zones:
			if z == null or not z.species.has("moso_culm"):
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = z.seed_value
			var cands: PackedVector2Array = forest._candidates(z, route, rng)
			for c in cands:
				if forest._edge_dist(c) < z.edge_clear_m:
					continue
				var gi := route.closest_index_global(Vector3(c.x, 0.0, c.y))
				var lat := Vector2(c.x - route.baked[gi].x, c.y - route.baked[gi].z).length()
				if lat <= lat_max:
					n_stems += 1
					first_stem = minf(first_stem, route.dists[gi])
	var zg := track.get_node_or_null("DecorManual/ZoneG_Bambus")
	if zg != null:
		for ch in zg.get_children():
			if String(ch.name).begins_with("gTufa") and ch is Node3D:
				var p2: Vector3 = (ch as Node3D).global_position
				if p2.length() < 0.01:
					continue
				var gi2 := route.closest_index_global(p2)
				var lat2 := Vector2(p2.x - route.baked[gi2].x, p2.z - route.baked[gi2].z).length()
				if lat2 <= lat_max:
					first_crown = minf(first_crown, route.dists[gi2])
	print("bambus G: prima tulpina (masa moso, lat<=%.0f m) la d=%.1f m (frac %.4f), %d tulpini; prima tufa manuala la d=%.1f m (frac %.4f)" % [
		lat_max, first_stem, first_stem / total, n_stems, first_crown, first_crown / total])
	var carpet := track.get_node_or_null("CovorFrunze")
	if carpet != null:
		print("covor: zone %s, spans %s" % [carpet.get("zones"), carpet.get("zone_spans")])
	if carpet != null:
		_carpet_coverage(carpet, route, total)
	var pts := OS.get_environment("PTS")
	if not pts.is_empty():
		for pr in pts.split(";"):
			var xz := pr.split(",")
			var dd := _d_of(route, Vector3(float(xz[0]), 12.0, float(xz[1])))
			print("punct (%s): d=%.1f m (frac %.4f) = %.1f m dupa capatul podului" % [pr, dd, dd / total, dd - d_end])
	get_tree().quit()


## ACOPERIREA EFECTIVA a covorului de frunze pe drum (nu numar de instante, memoria
## efecte-invizibile-nu-se-numara): reface in cod pragul din
## assets/shaders/leaf_carpet.gdshader (dens -> prag pe luminanta dalei) si masoara
## fractia de pixeli de frunza pe latimea drumului, pe felii de 0,01 din tur.
## Valorile sunt ale panoului ca mesh (culoarea de varf), fara uzura masinilor.
func _carpet_coverage(carpet: Node, route: TrackRoute, total: float) -> void:
	var mat: ShaderMaterial = null
	var rows: Array = [] # [d, dens_eff] per varf
	for pn in carpet.find_children("Panou*", "MeshInstance3D", false, false):
		var mi := pn as MeshInstance3D
		if mat == null:
			mat = mi.mesh.surface_get_material(0) as ShaderMaterial
		var arr := mi.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var cols: PackedColorArray = arr[Mesh.ARRAY_COLOR]
		var cc := float(carpet.get("center_cover"))
		for k in verts.size():
			var gi := route.closest_index_global(verts[k] + mi.global_position)
			var edge := smoothstep(0.30, 0.95, cols[k].g)
			rows.append([route.dists[gi], clampf(cols[k].r * lerpf(cc, 1.0, edge), 0.0, 1.0)])
	var img: Image = null
	if mat != null:
		var tex := mat.get_shader_parameter("leaf_tex") as Texture2D
		if tex != null:
			img = tex.get_image()
	if img == null or img.is_empty():
		print("covor: nu pot citi textura frunzei (headless) -> doar densitatea de varf")
	elif img.is_compressed():
		img.decompress()
	# luminanta (R) a dalei, esantionata pe o grila 64x64 (acoperirea nu depinde de pozitie)
	var lum: PackedFloat32Array = PackedFloat32Array()
	if img != null and not img.is_empty():
		for yy in 64:
			for xx in 64:
				lum.append(img.get_pixel(xx * img.get_width() / 64, yy * img.get_height() / 64).r)
	print("covor: acoperire efectiva pe latimea drumului (%% din suprafata cu frunza) pe felii de frac:")
	var f := 0.30
	while f <= 0.701:
		var sum_d := 0.0
		var sum_c := 0.0
		var n := 0
		for r in rows:
			if absf(float(r[0]) / total - f) <= 0.004:
				sum_d += float(r[1])
				sum_c += _leaf_fraction(float(r[1]), lum)
				n += 1
		if n > 0:
			print("  frac %.3f  dens_varf %.2f  acoperire %.0f%%" % [f, sum_d / n, 100.0 * sum_c / n])
		f += 0.01


func _leaf_fraction(dens: float, lum: PackedFloat32Array) -> float:
	if lum.is_empty():
		return dens
	var thr := lerpf(0.97, 0.15, dens)
	var acc := 0.0
	for v in lum:
		acc += smoothstep(thr - 0.07, thr + 0.07, v)
	return (acc / lum.size()) * smoothstep(0.02, 0.12, dens)
