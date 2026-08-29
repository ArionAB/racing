extends Node
## Genereaza randul de turnuri de sub piata Kuixinglou, din curba reala:
## pozitia laterala si yaw-ul se DERIVA din vectorul `right` al curbei, nu se
## scriu de mana. Fiecare turn e verificat sa nu intre in carosabil INAINTE de
## a fi scris in fisier (half_width 5.0 + garda 1.6 m = 6.6 m minim la fata).
##
## Turnurile (tower_silhouette_*) inlocuiesc liziba_block: liziba are 40.6 m
## latime si acoperisul de 2x aria peretilor -> de la camera (10 m sus, -28.7
## grade) se citeste ca placa palida, si la 12 m lateral fata ii ajunge pe
## asfalt. Turnurile au 9.5-14.5 m latime si ferestre pe TOATE fetele.
## Distanta minima de la orice colt al amprentei rotite pana la AXA drumului.
## half_width e 5.0 pe sectorul pietei, plus 0.5 toleranta in is_on_road, plus
## garda de 4 m: masurata analitic, o valoare mai mica lasa colturi peste
## carosabil (verificat cu probe_cq_onroad, care foloseste is_on_road-ul pistei).
const CLEAR_MIN := 9.5
const ROAD_Y := 65.0

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

	# extentele masurate (probe_tower_ab.gd); pivotul e la baza, centrat
	var sizes := {
		"tower_silhouette_a": Vector3(11.5, 38.1, 10.5),
		"tower_silhouette_b": Vector3(14.5, 48.1, 11.5),
		"tower_silhouette_c": Vector3(9.5, 31.1, 9.5),
	}

	# planul: [frac, lateral_centru, asset, scara, cota_varf_relativa_la_sosea]
	# Randul apropiat sta cu VARFUL sub cota soselei (ca sa nu faca zid) dar
	# suficient de sus cat sa umple cadrul cu fatada, si destul de aproape
	# lateral cat unghiul spre el sa fie mic (brief §8: proximitate = adancime).
	var plan := [
		# Randul apropiat: 26-30 m lateral, varfuri la +2..+8 peste sosea. La
		# 20-22 m umpleau jumatatea dreapta si ascundeau caderea; impinse la
		# 26+ raman inalte cat sa se vada fatada, dar lasa buza si panta libere
		# in prim-plan. Pas mare (~0.009) ca sa existe fante intre ele.
		[0.004, 27.0, "tower_silhouette_b", 1.05, 6.0],
		[0.013, 28.5, "tower_silhouette_a", 1.10, 3.0],
		[0.022, 26.5, "tower_silhouette_b", 1.00, 8.0],
		[0.031, 29.0, "tower_silhouette_a", 1.05, 2.0],
		# Planul doi: varfuri sub cota soselei -> coborare vizibila in gol.
		[0.008, 37.0, "tower_silhouette_c", 1.15, -8.0],
		[0.017, 39.0, "tower_silhouette_b", 1.10, -12.0],
		[0.026, 38.0, "tower_silhouette_a", 1.20, -10.0],
		[0.035, 40.0, "tower_silhouette_c", 1.15, -14.0],
		# Fundal, jos de tot: fundul rapei si scara orasului.
		[0.006, 52.0, "tower_silhouette_b", 1.30, -22.0],
		[0.015, 55.0, "tower_silhouette_a", 1.35, -26.0],
		[0.024, 53.0, "tower_silhouette_c", 1.30, -24.0],
		[0.033, 56.0, "tower_silhouette_b", 1.35, -28.0],
		[0.011, 66.0, "tower_silhouette_a", 1.40, -30.0],
		[0.029, 68.0, "tower_silhouette_c", 1.35, -32.0],
	]

	var out := ""
	var i := 0
	var bad := 0
	for e in plan:
		i += 1
		var f: float = e[0]
		var lat: float = e[1]
		var asset: String = e[2]
		var sc: float = e[3]
		var top_rel: float = e[4]
		var p := c.sample_baked(fmod(f * L, L))
		var p2 := c.sample_baked(fmod(f * L + 3.0, L))
		var fwd := (p2 - p).normalized()
		var right := fwd.cross(Vector3.UP).normalized()
		var ab: Vector3 = sizes[asset]
		var half_w: float = maxf(ab.x, ab.z) * 0.5 * sc
		# cota: varful la top_rel fata de sosea -> baza = varf - inaltime
		var h: float = ab.y * sc
		var top: float = p.y + top_rel
		var base: float = top - h
		var pos: Vector3 = p + right * lat + Vector3.UP * (base - p.y)
		# yaw: fata cu ferestre (Z) intoarsa spre axa drumului
		var yaw := atan2(-right.x, -right.z)
		var b := Basis(Vector3.UP, yaw).scaled(Vector3(sc, sc, sc))
		# Rezolv lateralul, nu-l ghicesc: impinge piesa in afara pana cand
		# amprenta ROTITA reala (4 colturi ai bazei locale prin basis) are cel
		# mai apropiat colt la >= CLEAR_MIN de axa. Semi-latimea aliniata pe axe
		# subestimeaza la yaw ~37 grade; AABB-ul de lume supraestimeaza cu pana
		# la 4 m. Amprenta rotita e singura care descrie cladirea.
		var hx: float = ab.x * 0.5 * sc
		var hz: float = ab.z * 0.5 * sc
		var near := 0.0
		var guard := 0
		while guard < 400:
			guard += 1
			pos = p + right * lat + Vector3.UP * (base - p.y)
			near = 1e9
			for ix in 2:
				for iz in 2:
					var cor: Vector3 = pos + b.x.normalized() * (float(ix) * 2.0 - 1.0) * hx + b.z.normalized() * (float(iz) * 2.0 - 1.0) * hz
					# distanta 3D minima de la colt la axa, pe tot sectorul pietei:
					# nu depinde de alegerea unei fractii, deci nu poate diverge de
					# sonda. Sub half_width inseamna peste carosabil.
					for k in 1200:
						var ss: float = float(k) / 1200.0 * 0.06 * L
						var pp := c.sample_baked(ss)
						near = minf(near, Vector2(cor.x - pp.x, cor.z - pp.z).length())
			if near >= CLEAR_MIN:
				break
			lat += 0.25
		var status := "ok"
		if near < CLEAR_MIN:
			status = "!!CAROSABIL"
			bad += 1
		# terenul sub piesa, ca sa stiu daca pluteste vizibil
		var o := Vector3(pos.x, 120.0, pos.z)
		var q := PhysicsRayQueryParameters3D.create(o, o + Vector3.DOWN * 400.0)
		q.collide_with_areas = false
		var hit := space.intersect_ray(q)
		var g: float = hit.position.y if not hit.is_empty() else -999.0
		print("turn%d frac=%.3f asset=%s lat=%.1f fata=%.1f baza=%.1f varf=%.1f (sosea %.1f) teren=%.1f %s"
			% [i, f, asset, lat, near, base, top, p.y, g, status])
		var res_map := {"tower_silhouette_a": "24_tower",
			"tower_silhouette_b": "37_towerb", "tower_silhouette_c": "38_towerc"}
		var res: String = res_map[asset]
		out += '[node name="turn_piata%d" parent="DecorManual/1) Piata Kuixinglou" instance=ExtResource("%s")]\n' % [i, res]
		out += "transform = Transform3D(%.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.3f, %.3f, %.3f)\n" % [
			b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z, pos.x, pos.y, pos.z]
		out += 'metadata/lumina = "30|3.5|#FFC98A"\n'
		out += 'metadata/coliziune = "none"\n\n'
	if bad > 0:
		print("ABANDON: %d piese in carosabil, nu scriu nimic" % bad)
	else:
		var fh := FileAccess.open("user://turnuri_piata.txt", FileAccess.WRITE)
		fh.store_string(out)
		fh.close()
		print("SCRIS %d turnuri in %s" % [i, ProjectSettings.globalize_path("user://turnuri_piata.txt")])
	get_tree().quit()

func _f(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for ch in n.get_children():
		var r := _f(ch)
		if r: return r
	return null
