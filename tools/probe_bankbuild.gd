extends Node
## De ce nu se construiesc coloanele malului: se reface CHIAR cautarea din
## _far_column si se tipareste, pas cu pas, unde cade baza si daca pragul
## `floor_y > top_y - 3` o culege.
##
## Sonda asta exista fiindca ridicarea coamei n-a schimbat nimic in pixeli, deci
## banuiala „masa e prea joasa" era gresita sau incompleta. Numai pasii reali
## spun care.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"


func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	var s: TrackSideSampler = t.get("_sampler")
	var faces: Array[Node] = []
	_walk(t, faces)
	for fnode in faces:
		var cf := fnode as CliffFace
		if not cf.far_bank:
			continue
		print("\n=== nod %s: frac %.3f..%.3f, offset %.0f ===" % [
			cf.name, cf.frac_start, cf.frac_end, cf.far_offset_m])
		var n := s.point_count()
		var total := s.total_length()
		var span := (cf.frac_end - cf.frac_start) * total
		var steps := maxi(int(round(span / maxf(cf.far_step_m, 1.0))), 2)
		var skipped := 0
		for si in steps + 1:
			var f := cf.frac_start + (cf.frac_end - cf.frac_start) \
				* (float(si) / float(steps))
			var i := clampi(int(round(f * float(n))) % n, 0, n - 1)
			var p := s.baked_point(i)
			var sd := s.side_at(i) * signf(cf.side)
			var crest_y := -1e9
			var crest_off := cf.far_offset_m
			var probe := cf.far_offset_m * 0.35
			while probe <= cf.far_offset_m * 1.6:
				var q := p + sd * probe
				var qy := s.ground_y(q.x, q.z)
				if qy > crest_y:
					crest_y = qy
					crest_off = probe
				probe += 6.0
			var base := p + sd * crest_off
			var toe := base - sd * cf.far_depth_m
			var floor_y := minf(s.ground_y(base.x, base.z), s.ground_y(toe.x, toe.z))
			var top_y := maxf(crest_y + cf.far_rise_m,
				p.y + cf.far_eye_rise_m + cf.far_over_eye_m)
			var dead := floor_y > top_y - 3.0
			if dead:
				skipped += 1
			if si % 4 == 0 or dead:
				print("   f=%.3f  creasta %6.1f la %3.0f m · fund %6.1f · coama %6.1f · %s"
					% [f, crest_y, crest_off, floor_y, top_y,
					"SARITA (fund peste coama)" if dead else "ok"])
		print("   coloane sarite: %d din %d" % [skipped, steps + 1])
	get_tree().quit()


func _walk(n: Node, out: Array[Node]) -> void:
	if n is CliffFace:
		out.append(n)
	for c in n.get_children():
		_walk(c, out)
