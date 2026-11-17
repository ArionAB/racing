extends Node
## SCARILE PUBLICE de pe Track25 (brief san_francisco.md §7 pasul 8d): modulul refacut
## (`sf_stair_lane.glb`, rampa plina cu fusta pana la -1,8) asezat de tools/gen_sf_route.py pe
## profilul treptelor. Garda masoara pe TERENUL REAL (raze verticale pe `TerrainBody`):
##   1. nicio fata de calcare (|x| <= 1,0, adancimea 0..5 m a fiecarui modul) sub teren;
##   2. nicio bucata din muchia de jos a fustei (conturul de 2,5 x 5 m, la -1,8 sub fiecare modul)
##      deasupra terenului — altfel se vede golul de sub scara.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfScari.tscn [-- --sabotaj]
##
## `--sabotaj` coboara scarile cu 0,5 m (cum le aseza vechea regula `sink`): garda TREBUIE sa pice.
## Exit 1 daca pica ceva sau daca n-a gasit nicio scara.

const TREAD_IN: float = 1.0
const HALF_W: float = 1.25
const SKIRT: float = 1.8
const TOL: float = 0.02

var _sabotage := false


static func tread(lz: float) -> float:
	if lz < 0.6:
		return 0.15
	var k := mini(15, int((lz - 0.6) / (3.8 / 15.0)))
	return 0.15 + float(k + 1) * 3.0 / 16.0


func _ready() -> void:
	var path := "res://scenes/tracks/Track25.tscn"
	for a in OS.get_cmdline_user_args():
		if a == "--sabotaj":
			_sabotage = true
		elif a.begins_with("--scene="):
			path = a.trim_prefix("--scene=")
	var track := (load(path) as PackedScene).instantiate() as Track
	# transformarile modulelor, citite INAINTE de coacerea decorului (care ascunde nodurile)
	var mods := {}
	var sc := track.get_node_or_null(^"DecorManual/Scari")
	if sc != null:
		for c in sc.get_children():
			var xf := (c as Node3D).transform
			if _sabotage:
				xf.origin.y -= 0.5
			mods[String(c.name)] = xf
	add_child(track)
	for _i in 3:
		await get_tree().process_frame
		await get_tree().physics_frame
	var space := track.get_world_3d().direct_space_state
	print("=== ProbeSfScari: %s, %d module%s ===" % [path.get_file(), mods.size(),
		" [SABOTAJ: scarile coborate 0,5 m]" if _sabotage else ""])
	if mods.is_empty():
		print("VERDICT: PICA (nicio scara)")
		get_tree().quit(1)
		return
	var fails := 0
	var names := mods.keys()
	names.sort()
	for nm: String in names:
		var xf: Transform3D = mods[nm]
		var worst_tread := INF     # treapta - teren (minim; < 0 = ingropata)
		var worst_skirt := -INF    # fundul fustei - teren (maxim; > 0 = in aer)
		var iz := 0
		while iz <= 20:
			var lz := 0.25 * iz
			var ix := 0
			while ix <= 10:
				var lx := -HALF_W + 0.25 * ix
				var p := xf * Vector3(lx, 0.0, lz)
				var g := _terrain(space, p.x, p.z)
				if not is_nan(g):
					if absf(lx) <= TREAD_IN + 0.001:
						worst_tread = minf(worst_tread, xf.origin.y + tread(lz) - g)
					if absf(lx) >= HALF_W - 0.001 or iz == 0 or iz == 20:
						worst_skirt = maxf(worst_skirt, xf.origin.y - SKIRT - g)
				ix += 1
			iz += 1
		var bad := worst_tread < -TOL or worst_skirt > TOL
		if bad:
			fails += 1
		print("  %-9s treapta - teren min %+.2f m | fundul fustei - teren max %+.2f m%s" % [nm, worst_tread,
			worst_skirt, "   PICA" if bad else ""])
	print("VERDICT: %s%s" % ["PICA (%d module)" % fails if fails > 0 else "OK", " [sabotaj]" if _sabotage else ""])
	get_tree().quit(1 if fails > 0 else 0)


func _terrain(space: PhysicsDirectSpaceState3D, x: float, z: float) -> float:
	var excl: Array[RID] = []
	for _k in 8:
		var q := PhysicsRayQueryParameters3D.create(Vector3(x, 160.0, z), Vector3(x, -60.0, z))
		q.exclude = excl
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return NAN
		var col := hit["collider"] as Node
		if col != null and String(col.name) == "TerrainBody":
			return float((hit["position"] as Vector3).y)
		excl.append(hit["rid"])
	return NAN
