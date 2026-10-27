extends Node
## Decor DecorManual INGROPAT: piese asezate pe solul de la momentul
## generarii, peste care terenul a crescut ulterior. Pe Serengeti padurea Lerai
## (`gen_decor_ser_e.gd`, „fundul craterului, intre sea+0,5 si sea+9") a ramas
## la 2-12 m, iar terenul de deasupra e acum la ~32 m: copaci si elefanti
## nevazuti, platiti la desen si la coliziune.
##
## Pe fiecare piesa (nod cu scena GLB sub DecorManual) se trage o raza pe
## TerrainBody si se compara cu originea:
##   ingropata    — terenul e cu peste MAX_DEPTH deasupra originii
##   disparuta    — chiar si varful cutiei e sub teren (nu se vede deloc)
## Stancile (`/rocks/`) se ingroapa DINADINS pe panta (altfel plutesc pe partea
## din vale), deci pentru ele conteaza doar „disparuta".
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeDecorBuried.tscn -- --track=7
##
## Cu `--fix`, tipareste linii pentru patch-ul .tscn:
##   - piesa disparuta: `DELETE` (implicit). E nevazuta de cand a crescut
##     terenul, iar zona a fost judecata si acceptata fara ea — stearsa, nu se
##     schimba nimic din ce se vede. Cu `--relocate` in loc se muta la cel mai apropiat loc (inele de 2 m, pana la
##     80 m) unde terenul e la ±BAND m de cota ei de generare si peste `--min-y`
##     (pe Serengeti 2,2 = lacul + 0,5, regula generatorului), fara sosea sau
##     decor pe amprenta trunchiului, la MIN_SPACING de alte piese mutate si la
##     ANIMAL_CLEAR de animale (elefantii de decor n-au coliziune);
##   - piesa doar ingropata (copac cu trunchiul sub pamant) se ridica pe teren.
## `--prefix=` restrange la nodurile cu numele asa.

const MAX_DEPTH := 1.5
const BAND := 2.0
const TRUNK_RADIUS := 1.2
const MIN_SPACING := 4.0
const ANIMAL_CLEAR := 7.0

var _space: PhysicsDirectSpaceState3D
var _min_y := -INF
var _relocate := false
var _animals: Array[Vector3] = []


func _ready() -> void:
	var wanted := 7
	var fix := false
	var prefix := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			wanted = int(arg.trim_prefix("--track="))
		elif arg == "--fix":
			fix = true
		elif arg.begins_with("--prefix="):
			prefix = arg.trim_prefix("--prefix=")
		elif arg == "--relocate":
			_relocate = true
		elif arg.begins_with("--min-y="):
			_min_y = float(arg.trim_prefix("--min-y="))
	var idx := GameState.resolve_track_index(wanted)
	if idx < 0:
		push_error("ProbeDecorBuried: pista invalida %d" % wanted)
		get_tree().quit(2)
		return
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	add_child(track)
	for i in 12:
		await get_tree().physics_frame
	_space = track.get_world_3d().direct_space_state
	var dm := track.get_node_or_null(^"DecorManual")
	if dm == null:
		print("PICAT: pista n-are DecorManual")
		get_tree().quit(1)
		return

	var pieces := 0
	var no_ground := 0
	var buried: Array[Dictionary] = []
	for n in dm.find_children("*", "Node3D", true, false):
		var node := n as Node3D
		if node.scene_file_path.is_empty():
			continue
		if node.scene_file_path.contains("/animals/"):
			_animals.append(node.global_position)
		pieces += 1
		var o := node.global_position
		var g := _terrain_y(o)
		if is_nan(g):
			no_ground += 1
			continue
		var depth := g - o.y
		if depth <= MAX_DEPTH:
			continue
		var top := o.y + _local_top(node) * node.global_transform.basis.get_scale().y
		var gone_now := top < g - 0.2
		if node.scene_file_path.contains("/rocks/") and not gone_now:
			continue
		buried.append({"node": node, "depth": depth, "gone": gone_now, "ground": g})
	var gone := 0
	var by_prefix: Dictionary = {}
	for b in buried:
		if b["gone"]:
			gone += 1
		var key := String((b["node"] as Node).name).rstrip("0123456789")
		by_prefix[key] = int(by_prefix.get(key, 0)) + 1
	print("=== PROBE DECOR BURIED — %s: %d piese, %d ingropate (%d disparute), %d fara teren ===" % [
		GameState.track_label(idx), pieces, buried.size(), gone, no_ground])
	if pieces == 0:
		print("PICAT: zero piese — sonda n-a masurat nimic")
		get_tree().quit(1)
		return
	for b in buried.slice(0, 80):
		var n := b["node"] as Node3D
		print("  %-36s la %s  teren %+.2f m deasupra%s" % [
			String(n.get_parent().name) + "/" + String(n.name),
			n.global_position.snapped(Vector3.ONE * 0.01), float(b["depth"]),
			"  (DISPARUTA)" if b["gone"] else ""])
	for k in by_prefix:
		print("  total %-30s %d" % [k, by_prefix[k]])
	if fix:
		_fix(buried, prefix, track)
	print("VERDICT: %s (%d piese ingropate din %d)" % [
		"TRECUT" if buried.is_empty() else "PICAT", buried.size(), pieces])
	get_tree().quit(0 if buried.is_empty() else 1)


func _local_top(n: Node3D) -> float:
	var top := 0.0
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var xf := n.global_transform.affine_inverse() * m.global_transform
		top = maxf(top, (xf * m.mesh.get_aabb()).end.y)
	return top


func _terrain_y(at: Vector3) -> float:
	var from := Vector3(at.x, at.y + 300.0, at.z)
	var exclude: Array[RID] = []
	for i in 16:
		var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 600.0)
		q.exclude = exclude
		var hit := _space.intersect_ray(q)
		if hit.is_empty():
			return NAN
		if String((hit.collider as Node).name).begins_with("TerrainBody"):
			return (hit.position as Vector3).y
		exclude.append(hit.rid as RID)
	return NAN


## Loc ocupat de un corp care nu e teren (sosea, trunchi, stanca), in afara
## corpului propriu al piesei (`<nume>_col`, vezi WorldProp._build_collision).
func _occupied(at: Vector3, own: String) -> bool:
	var cyl := CylinderShape3D.new()
	cyl.radius = TRUNK_RADIUS
	cyl.height = 2.0
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cyl
	q.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * 1.2)
	for r in _space.intersect_shape(q, 16):
		var col := r["collider"] as Node
		if not col is StaticBody3D:
			continue
		var nm := String(col.name)
		if nm.begins_with("TerrainBody") or nm == own:
			continue
		return true
	return false


func _fix(buried: Array[Dictionary], prefix: String, track: Track) -> void:
	var moved: Array[Vector3] = []
	for b in buried:
		var n := b["node"] as Node3D
		if prefix != "" and not String(n.name).begins_with(prefix):
			continue
		var o := n.global_position
		if not b["gone"]:
			var lp0 := n.get_parent_node_3d().global_transform.affine_inverse() 				* Vector3(o.x, float(b["ground"]), o.z)
			print("MOVE %s/%s %.4f %.4f %.4f   (ridicat %.2f m)" % [
				String(track.get_path_to(n.get_parent())), n.name, lp0.x, lp0.y, lp0.z,
				float(b["depth"])])
			continue
		if not _relocate:
			print("DELETE %s/%s   (teren %.1f m deasupra)" % [
				String(track.get_path_to(n.get_parent())), n.name, float(b["depth"])])
			continue
		var done := false
		for ring in range(1, 41):
			var r := 2.0 * float(ring)
			var steps := maxi(16, int(TAU * r / 3.0))
			for k in steps:
				var ang := TAU * float(k) / float(steps)
				var p := o + Vector3(cos(ang), 0.0, sin(ang)) * r
				var g := _terrain_y(p)
				if is_nan(g) or absf(g - o.y) > BAND or g < _min_y:
					continue
				p.y = g
				var crowded := false
				for m in moved:
					if Vector2(m.x, m.z).distance_to(Vector2(p.x, p.z)) < MIN_SPACING:
						crowded = true
						break
				for a in _animals:
					if Vector2(a.x, a.z).distance_to(Vector2(p.x, p.z)) < ANIMAL_CLEAR:
						crowded = true
						break
				if crowded or _occupied(p, String(n.name) + "_col"):
					continue
				var lp := n.get_parent_node_3d().global_transform.affine_inverse() * p
				print("MOVE %s/%s %.4f %.4f %.4f   (%.0f m)" % [
					String(track.get_path_to(n.get_parent())), n.name, lp.x, lp.y, lp.z, r])
				moved.append(p)
				done = true
				break
			if done:
				break
		if not done:
			print("NOMOVE %s/%s — niciun loc in 80 m" % [
				String(track.get_path_to(n.get_parent())), n.name])
