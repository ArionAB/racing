extends SceneTree
## VERIFICA fereastra podetului Chasm (POI D, Track16): nicio piesa de decor
## cu coliziune REALA (nu `none`) nu are voie sa stea la <= 10 m LATERAL de
## AXA pistei pe fractia 0.395-0.435 (intrarea si iesirea podetului, unde
## semi-latimea scade la 5,5 m si masinile se inghesuie -- defectul raportat
## in race_dry_2.log: [blocaj] Kai la frac 0.405, lat 7.0/8.1, atinge
## marmita38_col/canionTreapta324_col/Shoulders/RoadSides/RoadTop).
##
## Amprenta REALA (nu raza nominala BASE_R): semi-diagonala AABB * scara
## (CORNER_R, ca in gen_decor_fiord_f.gd / probe_pileup_footprint.gd), pentru
## ca la un yaw arbitrar un COLT al bolovanului poate iesi mai aproape de ax
## decat jumatatea laturii mari.
##
##   godot --headless --path . --script res://tools/probe_bridge_pileup.gd -- \
##       --zone=DecorManual/ZoneD_Chasm [--track=16] [--lo=0.395] [--hi=0.435] [--limit=10.0]

const CORNER_R := {
	"chasm_rock": 3.816,
	"moss_boulder_a": 0.562,
	"moss_boulder_b": 1.710,
	"moss_boulder_c": 2.697,
}
## Copacii/ferigile (trunchi) au coliziune reala doar pe cilindrul trunchiului
## -- acelasi tratament ca probe_pileup_footprint.gd (coroana nu opreste
## masina). `tree_fern` (feriga) rezolva la `trunk` la RUNTIME prin
## world_prop.gd (PROP_COLLISION implicit), desi gen_decor_fiord_d.gd o trateaza
## local ca "hull" -- MODE["tree_fern"]="hull" face ca metadata sa nu se scrie
## niciodata (world_prop.gd:44 scrie meta doar cand m != "hull"), deci
## implicitul din PROP_COLLISION ("trunk") ramane cel activ in joc. Raza:
## BASE_R["tree_fern"] (0.5) din acest fisier, deja mai mare decat masuratorile
## din alte POI (0.15-0.30), deci conservator.
const TRUNK_STEMS := ["beech_a", "beech_b", "beech_c", "beech_dead", "tree_fern"]
const TRUNK_BASE_R := {
	"beech_a": 0.81, "beech_b": 0.77, "beech_c": 1.03, "beech_dead": 0.68,
	"tree_fern": 0.5,
}

var _frames := 0
var _track: Node3D = null
var _track_idx := 16
var _zone_path := "DecorManual/ZoneD_Chasm"
var _lo := 0.395
var _hi := 0.435
var _limit := 10.0


func _process(_delta: float) -> bool:
	if _track == null:
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--track="):
				_track_idx = int(a.trim_prefix("--track="))
			elif a.begins_with("--zone="):
				_zone_path = a.trim_prefix("--zone=")
			elif a.begins_with("--lo="):
				_lo = float(a.trim_prefix("--lo="))
			elif a.begins_with("--hi="):
				_hi = float(a.trim_prefix("--hi="))
			elif a.begins_with("--limit="):
				_limit = float(a.trim_prefix("--limit="))
		var path := "res://scenes/tracks/Track%02d.tscn" % _track_idx
		if not ResourceLoader.exists(path):
			push_error("probe_bridge_pileup: nu exista %s" % path)
			quit(1)
			return true
		print("=== %s :: %s :: frac [%.3f, %.3f] :: limita %.1f m ===" % [path, _zone_path, _lo, _hi, _limit])
		_track = (load(path) as PackedScene).instantiate()
		root.add_child(_track)
		return false
	_frames += 1
	if _frames < 3:
		return false
	quit(0 if _report() else 1)
	return true


static func _stem_of(n3: Node3D) -> String:
	return n3.scene_file_path.get_file().get_basename()


static func _effective_collision_mode(n3: Node3D) -> String:
	if n3.has_meta(WorldProp.COLLISION_META):
		var m := String(n3.get_meta(WorldProp.COLLISION_META))
		if WorldProp.COLLISION_MODES.has(m):
			return m
	var stem := _stem_of(n3)
	return String(WorldProp.PROP_COLLISION.get(stem, "hull"))


## Puncte de colt (XZ, world) ale amprentei reale a piesei -- cilindru de
## trunchi pentru copaci, AABB de mesh transformat (rotatie+scara reale) pentru
## restul.
func _footprint_points(n3: Node3D) -> Array:
	var stem := _stem_of(n3)
	if TRUNK_STEMS.has(stem):
		var r: float = TRUNK_BASE_R.get(stem, 1.0) * n3.scale.x
		var c := n3.global_position
		var pts := []
		for ang in [0.0, PI * 0.5, PI, PI * 1.5]:
			pts.append(c + Vector3(cos(ang), 0.0, sin(ang)) * r)
		return pts
	var mesh := _find_mesh(n3)
	if mesh == null:
		return []
	var aabb: AABB = mesh.get_aabb()
	var xf: Transform3D = mesh.global_transform
	var pts := []
	for dx in [0.0, aabb.size.x]:
		for dz in [0.0, aabb.size.z]:
			var local := aabb.position + Vector3(dx, 0.0, dz)
			pts.append(xf * local)
	return pts


func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return node as MeshInstance3D
	for c in node.get_children():
		var r := _find_mesh(c)
		if r != null:
			return r
	return null


func _report() -> bool:
	var t: Node3D = _track
	var zone: Node3D = t.get_node_or_null(_zone_path)
	if zone == null:
		push_error("probe_bridge_pileup: zona %s nu exista" % _zone_path)
		return false
	var baked: PackedVector3Array = t.baked
	var bad := 0
	var checked := 0
	print("%-28s %10s %10s %8s   %s" % ["nod", "frac", "lat_min(m)", "mod", "verdict"])
	for c in zone.get_children():
		var n3 := c as Node3D
		if n3 == null:
			continue
		var mode := _effective_collision_mode(n3)
		var center := n3.global_position
		var near_i := 0
		var near_d := 1e18
		for i in baked.size():
			var d := Vector2(center.x - baked[i].x, center.z - baked[i].z).length_squared()
			if d < near_d:
				near_d = d
				near_i = i
		var frac: float = t.frac_at(near_i) if t.has_method("frac_at") else float(near_i) / float(baked.size())
		if frac < _lo or frac > _hi:
			continue
		checked += 1
		var p: Vector3 = baked[near_i]
		var fwd := (baked[(near_i + 1) % baked.size()] - p)
		if fwd.length() < 0.001:
			fwd = Vector3.FORWARD
		fwd = fwd.normalized()
		var side := fwd.cross(Vector3.UP).normalized()
		var pts := _footprint_points(n3)
		var min_abs_lat := INF
		for pt in pts:
			var rel: Vector3 = pt - p
			var lat: float = rel.dot(side)
			min_abs_lat = minf(min_abs_lat, absf(lat))
		if pts.is_empty():
			continue
		var verdict := "ok"
		if mode != "none" and min_abs_lat <= _limit:
			verdict = "PERICOL <= %.1f m (coliziune %s)" % [_limit, mode]
			bad += 1
		elif mode == "none" and min_abs_lat <= _limit:
			verdict = "fantoma ok (coliziune none)"
		print("%-28s %10.4f %10.2f %8s   %s" % [String(n3.name), frac, min_abs_lat, mode, verdict])
	print("")
	print("%d noduri verificate in fereastra [%.3f, %.3f] din %s" % [checked, _lo, _hi, _zone_path])
	if bad > 0:
		print("VERDICT: %d piese cu coliziune REALA la <= %.1f m lateral de ax" % [bad, _limit])
		return false
	print("VERDICT: OK -- nicio piesa cu coliziune reala la <= %.1f m lateral de ax" % _limit)
	return true
