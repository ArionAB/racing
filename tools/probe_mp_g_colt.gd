extends Node
## Cele patru colturi ale fiecarei piese de zid: cat de departe de AX e fiecare,
## fata de semi-latimea locala. Negativ = coltul e PESTE asfalt.
const TRACK := "res://scenes/tracks/Track15.tscn"
const LEN := {"s_inca_wall_a": 4.0, "s_inca_wall_b": 6.0, "s_inca_wall_c": 2.0}
var _track: Track
func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var zone := _track.get_node_or_null("DecorManual/ZoneG_Serpentine")
	var worst: Array[float] = []
	var n_over := 0
	var n_tot := 0
	for c in zone.get_children():
		var nm := str(c.name)
		if not nm.begins_with("zidSprijin") or nm.ends_with("_col"): continue
		var t := c as Node3D
		# lungimea din scena instantiata
		var L := 6.0
		var sc := str((c as Node).scene_file_path).get_file().get_basename()
		for k: String in LEN:
			if sc.contains(k.trim_prefix("s_")): L = LEN[k]
		var b := t.global_transform.basis
		var o := t.global_position
		var ax := Vector3(b.x.x, 0.0, b.x.z).normalized()
		var az := Vector3(b.z.x, 0.0, b.z.z).normalized()
		var wr := 0.43
		var mind := INF
		for su: float in [-1.0, 1.0]:
			for sv: float in [-1.0, 1.0]:
				var p := o + ax * (L * 0.5 * su) + az * (wr * sv)
				var bi := _nearest(p)
				var bp: Vector3 = _track.baked[bi]
				var s := _track._side_at(bi)
				var lat: float = absf(Vector3(p.x - bp.x, 0.0, p.z - bp.z).dot(s))
				var half := _track.width_at_index(bi)
				mind = minf(mind, lat - half)
		n_tot += 1
		worst.append(mind)
		if mind < 0.0: n_over += 1
	worst.sort()
	print("; piese %d" % n_tot)
	print("; coltul cel mai dinauntru fata de MUCHIE: median %+.2f m, p10 %+.2f, min %+.2f" % [
		worst[worst.size()/2], worst[worst.size()/10], worst[0]])
	print("; piese cu un colt PESTE asfalt: %d din %d" % [n_over, n_tot])
	get_tree().quit(0)
func _nearest(p: Vector3) -> int:
	var best := 0; var bd := INF
	for i in _track.baked.size():
		var b: Vector3 = _track.baked[i]
		var d := (b.x-p.x)*(b.x-p.x)+(b.z-p.z)*(b.z-p.z)
		if d < bd: bd = d; best = i
	return best
