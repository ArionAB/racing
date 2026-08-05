extends SceneTree
## Sonda de MARGINE: de ce nu are pista faleza acolo unde n-are.
##
## Exista fiindca issue-ul #164 a fost diagnosticat gresit, si nu din neatentie —
## pur si simplu nimeni nu putea vedea cifra. Se vedea rezultatul (70 de sectiuni
## de `cliff_wall` pe 1175 m, cu nisip intre ele) si se dedusese cauza: „regula
## exterior / interior inaltat lasa restul marginii descoperit". Masurat, regula
## aia taia 13 sloturi din 168. Degajarile de landmark taiau 44 — de trei ori mai
## mult — si jumatate din ele erau pe latura OPUSA landmark-ului, unde nu
## ascundeau nimic.
##
## Morala pentru data viitoare: `probe_midground` spune CAT de plin e cadrul,
## `probe_decor` spune CAT costa, dar niciuna nu spune CINE a respins piesa. Cand
## raspunsul la „de ce e gol aici" e o insiruire de filtre, filtrele trebuie
## numarate, nu ghicite.
##
##   godot --headless --path . --script res://tools/probe_edge_cover.gd -- --track=1

var _track: Node = null
var _frames := 0


func _process(_delta: float) -> bool:
	if _track == null:
		var idx := 1
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--track="):
				idx = int(a.trim_prefix("--track="))
		var path := "res://scenes/tracks/Track%02d.tscn" % idx
		if not ResourceLoader.exists(path):
			push_error("probe_edge_cover: nu exista %s" % path)
			quit(1)
			return true
		print("=== %s ===" % path)
		_track = (load(path) as PackedScene).instantiate()
		root.add_child(_track)
		return false
	_frames += 1
	if _frames < 3:
		return false
	_measure()
	quit(0)
	return true


func _measure() -> void:
	var sampler: TrackSideSampler = _track._sampler
	var total := sampler.total_length()
	print("lungime tur: %.0f m" % total)
	for side_sign: float in [-1.0, 1.0]:
		var seg := sampler.wall_segments(side_sign)
		var covered := 0.0
		for s in seg:
			covered += s.y - s.x
		print("latura %+d: %d intervale inchise, %.0f m din %.0f (%.0f%%)"
			% [int(side_sign), seg.size(), covered, total, covered / total * 100.0])

	# Filtrele din TrackCliffs.build, in aceeasi ordine si cu aceleasi constante:
	# daca unul se schimba acolo, cifra de aici se schimba odata cu el.
	var clear_at: Array[Vector2] = []
	for lm in _track._cliff_clearings():
		clear_at.append(Vector2(lm.x * total, lm.y))
	print("degajari (landmark-uri + situri + arcade): %d" % clear_at.size())

	var kill := {"degajare landmark": 0, "rapa": 0, "margine deschisa": 0,
		"fereastra respiro": 0, "PERETE": 0, "creasta joasa": 0}
	for spec in sampler.sample_edge(TrackCliffs.SPACING, TrackCliffs.OFFSET_OUTER):
		var d := spec.frac * total
		var seg := sampler.wall_segments(spec.side_sign)
		if TrackCliffs._near_landmark(d, spec.side_sign, total, clear_at):
			kill["degajare landmark"] += 1
		elif spec.is_ravine:
			kill["rapa"] += 1
		elif not TrackSideSampler.in_segments(d, seg):
			if TrackCliffs._skip_fill(spec):
				kill["margine deschisa"] += 1
			else:
				kill["creasta joasa"] += 1
		elif TrackCliffs._skip_slot(spec):
			kill["fereastra respiro"] += 1
		elif TrackCliffs._near_landmark(d, spec.side_sign, total, clear_at,
				TrackCliffs.LANDMARK_LOW_AHEAD, 0.0):
			kill["creasta joasa"] += 1
		else:
			kill["PERETE"] += 1
	var tot := 0
	for k in kill:
		tot += int(kill[k])
	print("sloturi de margine: %d" % tot)
	for k in kill:
		print("   %-20s %d" % [k, kill[k]])

	print("sectiuni de faleza in scena: %d" % _count(_track))


func _count(node: Node) -> int:
	var n := 0
	for c in node.get_children():
		if c is MeshInstance3D and String(c.name).begins_with("Cliff_"):
			n += 1
		n += _count(c)
	return n
