extends SceneTree
## GARDA: numar de noduri DecorManual/ZoneB_* al caror AABB intra in volumul
## real construit de CliffFace (nodul "CliffFaces" din track.gd, mesh-urile
## "Taietura *"). Tinta: 0.
##
## De ce pe geometria REALA construita, nu pe o reimplementare a formulei din
## `_cut_column`: o a doua copie a matematicii (offset + batter + facet +
## taper) ar putea diverge tacut de codul real la urmatoarea reglare a
## peretelui, si atunci garda ar masura o forma care nu mai exista. Se traduc
## ambele parti (decor si perete) in coordonate (frac-pe-curba, lateral,
## inaltime) — acelasi sistem in care se declara si CliffFace insusi — si se
## testeaza suprapunerea pe cele trei axe, nu doar distanta euclidiana intr-un
## punct.
##
##   godot --headless --path . --script res://tools/probe_wall_overlap.gd -- --track=16
##
## Cod de iesire: 1 daca vreun nod intra in volum, 0 altfel (verde = 0).

## Cat de aproape (in indici de curba) trebuie sa fie un vertex de perete de
## un nod de decor ca sa intre in acelasi "bin" de comparat. Wall step_m e
## 4.0 m; la 1078 puncte pe ~2162 m, un pas de curba e ~2 m — 4 indici ~ 8 m,
## suficient sa prinda vertecsii coloanei celei mai apropiate fara sa amestece
## coloane vecine prea larg.
const BIN_RADIUS_IDX: int = 4

func _initialize() -> void:
	var track_arg := 16
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--track="):
			track_arg = int(a.substr(8))
	var path := "res://scenes/tracks/Track%02d.tscn" % track_arg
	var scene := load(path) as PackedScene
	var track := scene.instantiate() as Track
	root.add_child(track)
	await process_frame
	await process_frame
	var sampler = track.get("_sampler")
	var n: int = sampler.point_count()

	var faces_root := track.find_child("CliffFaces", true, false)
	if faces_root == null:
		print("LIPSA nod CliffFaces — nimic de verificat (peretele nu s-a construit)")
		quit(0)
		return

	# Colecteaza TOATE vertecsii tuturor mesh-urilor "Taietura *" (peretii de
	# tip cut_wall), proiectati pe (index_curba, lateral, y).
	var wall_pts: Array = [] # fiecare: {i:int, lat:float, y:float}
	for child in faces_root.get_children():
		if not (child is MeshInstance3D):
			continue
		if not String(child.name).begins_with("Taietura"):
			continue
		var mesh: Mesh = (child as MeshInstance3D).mesh
		if mesh == null:
			continue
		var xform: Transform3D = (child as MeshInstance3D).global_transform
		for surf in mesh.get_surface_count():
			var arrays := mesh.surface_get_arrays(surf)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for v in verts:
				var wp: Vector3 = xform * v
				var bi := _nearest_index(sampler, n, wp)
				var bp: Vector3 = sampler.baked_point(bi)
				var sd: Vector3 = sampler.side_at(bi)
				var lat := sd.x * (wp.x - bp.x) + sd.z * (wp.z - bp.z)
				wall_pts.append({"i": bi, "lat": lat, "y": wp.y})
	print("Perete: %d vertecsi colectati din %d mesh-uri 'Taietura *'" % [
		wall_pts.size(), faces_root.get_children().size()])
	if wall_pts.is_empty():
		print("Peretele nu are geometrie (rise peste tot < 2m?) — nimic de verificat")
		quit(0)
		return

	# index -> lista de (lat, y) pentru lookup rapid pe bin
	var by_idx: Dictionary = {}
	for wp in wall_pts:
		var i: int = wp["i"]
		if not by_idx.has(i):
			by_idx[i] = []
		by_idx[i].append(wp)

	var zone := track.get_node_or_null("DecorManual")
	if zone == null:
		print("LIPSA DecorManual")
		quit(1)
		return

	var bad: Array[String] = []
	var checked := 0
	for zchild in zone.get_children():
		if not String(zchild.name).begins_with("ZoneB_"):
			continue
		for node in zchild.get_children():
			if not (node is Node3D):
				continue
			checked += 1
			var n3 := node as Node3D
			var gt: Transform3D = n3.global_transform
			var wp: Vector3 = gt.origin
			var bi := _nearest_index(sampler, n, wp)
			var bp: Vector3 = sampler.baked_point(bi)
			var sd: Vector3 = sampler.side_at(bi)
			var lat := sd.x * (wp.x - bp.x) + sd.z * (wp.z - bp.z)
			# inaltimea aproximativa a piesei: AABB local scalat, plus originea.
			var aabb := _approx_world_aabb(n3)
			var y_lo: float = aabb.position.y
			var y_hi: float = aabb.position.y + aabb.size.y
			# aduna vertecsii de perete din binul apropiat de indexul decorului
			var near_wall: Array = []
			for d in range(-BIN_RADIUS_IDX, BIN_RADIUS_IDX + 1):
				var idx := ((bi + d) % n + n) % n
				if by_idx.has(idx):
					near_wall.append_array(by_idx[idx])
			if near_wall.is_empty():
				continue # peretele nu exista in dreptul acestui decor (taper la capete)
			# volumul peretelui langa acest decor: [lat_min..lat_max] x [y_min..y_max]
			var wlat_min := INF
			var wlat_max := -INF
			var wy_min := INF
			var wy_max := -INF
			for wpnt in near_wall:
				wlat_min = minf(wlat_min, wpnt["lat"])
				wlat_max = maxf(wlat_max, wpnt["lat"])
				wy_min = minf(wy_min, wpnt["y"])
				wy_max = maxf(wy_max, wpnt["y"])
			# suprapunere pe LATERAL si pe INALTIME (nu doar un punct — AABB-ul
			# intreg al decorului fata de infasuratoarea peretelui local).
			# Lateralul decorului se extinde cu raza orizontala reala a AABB-ului
			# (nu doar originea), altfel o piesa lata dar centrata langa perete
			# ar trece nedetectata.
			var horiz_r: float = maxf(aabb.size.x, aabb.size.z) * 0.5
			var lat_overlap: bool = aabb_overlap_1d(
				lat - horiz_r, lat + horiz_r, wlat_min, wlat_max)
			var y_overlap: bool = aabb_overlap_1d(y_lo, y_hi, wy_min, wy_max)
			if lat_overlap and y_overlap:
				bad.append("%s/%s  lat=%.2f (perete %.2f..%.2f)  y=%.2f..%.2f (perete %.2f..%.2f)" % [
					zchild.name, node.name, lat, wlat_min, wlat_max, y_lo, y_hi, wy_min, wy_max])

	print("Verificate %d noduri ZoneB_*, %d in interiorul peretelui" % [checked, bad.size()])
	for b in bad:
		print("  IN PERETE: %s" % b)
	print("VERDICT: %s" % ("OK — 0 noduri in perete" if bad.is_empty() else "PROBLEMA — %d noduri" % bad.size()))
	quit(1 if not bad.is_empty() else 0)


static func aabb_overlap_1d(a0: float, a1: float, b0: float, b1: float) -> bool:
	return a0 <= b1 and b0 <= a1


static func _nearest_index(sampler, n: int, wp: Vector3) -> int:
	# cautare completa: curbele au ~1-2k puncte, se ruleaza o singura data per
	# nod verificat — cost acceptabil pentru o sonda ad-hoc de CI local.
	var best_d2 := INF
	var best_i := 0
	for k in n:
		var bp: Vector3 = sampler.baked_point(k)
		var dx := bp.x - wp.x
		var dz := bp.z - wp.z
		var d2 := dx * dx + dz * dz
		if d2 < best_d2:
			best_d2 = d2
			best_i = k
	return best_i


## AABB aproximativ in lume: combina AABB-ul local (mesh) cu transformul
## global. Nu e exact (nu roteste cutia), dar e conservator (o supraestimeaza
## usor), ceea ce e alegerea corecta pentru o garda care nu vrea sa rateze un
## fals-negativ.
static func _approx_world_aabb(n3: Node3D) -> AABB:
	var local_aabb := AABB(Vector3(-0.3, 0.0, -0.3), Vector3(0.6, 1.5, 0.6))
	for child in n3.get_children():
		if child is VisualInstance3D:
			local_aabb = local_aabb.merge((child as VisualInstance3D).get_aabb())
	if n3 is VisualInstance3D:
		local_aabb = local_aabb.merge((n3 as VisualInstance3D).get_aabb())
	var gt: Transform3D = n3.global_transform
	# transforma cele 8 colturi si reconstruieste AABB-ul in lume
	var out := AABB()
	var first := true
	for corner in 8:
		var lp := Vector3(
			local_aabb.position.x + (local_aabb.size.x if corner & 1 else 0.0),
			local_aabb.position.y + (local_aabb.size.y if corner & 2 else 0.0),
			local_aabb.position.z + (local_aabb.size.z if corner & 4 else 0.0))
		var wp := gt * lp
		if first:
			out = AABB(wp, Vector3.ZERO)
			first = false
		else:
			out = out.expand(wp)
	return out
