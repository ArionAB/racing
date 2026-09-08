extends Node
## Cine face umbra pe drum la fractiile care pica: numar, pe fiecare coroana,
## cati pixeli de carosabil umbreste. Ca sa stiu ce sa mut, nu sa ghicesc.
const CROWN_R := {"fig_tree": 5.6, "fever_tree": 4.4, "acacia_umbrella_a": 5.0}
const CROWN_Y := {"fig_tree": 0.72, "fever_tree": 0.78, "acacia_umbrella_a": 0.85}
const MODEL_H := {"fig_tree": 13.0, "fever_tree": 10.12, "acacia_umbrella_a": 7.0}
var _track: Node3D
var _sun: Vector3
var _cr: Array = []

func _ready() -> void:
	await get_tree().process_frame
	var scn := load(GameState.TRACK_SCENES[GameState.resolve_track_index(7)]) as PackedScene
	_track = scn.instantiate()
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	for c in _track.find_children("*", "DirectionalLight3D", true, false):
		_sun = -(c as DirectionalLight3D).global_transform.basis.z
	var zone := _track.find_child("ZoneD_PadureaDeCeata", true, false)
	for c in zone.get_children():
		var n := str(c.name); var mdl := ""
		if n.begins_with("smochin"): mdl = "fig_tree"
		elif n.begins_with("febra"): mdl = "fever_tree"
		elif n.begins_with("acacie"): mdl = "acacia_umbrella_a"
		else: continue
		var t: Transform3D = (c as Node3D).global_transform
		var s: float = t.basis.get_scale().y
		_cr.append([n, t.origin, float(CROWN_R[mdl]) * s,
			t.origin.y + float(MODEL_H[mdl]) * float(CROWN_Y[mdl]) * s])
	var tally := {}
	for f in [0.205, 0.212, 0.220, 0.260, 0.268, 0.275]:
		var n: int = _track.baked.size()
		var i: int = int(f * float(n)) % n
		var p: Vector3 = _track.baked[i]
		var s3: Vector3 = _track._side_at(i)
		var half: float = _track.width_at_index(i)
		for k in 9:
			var lat := -half + (float(k) + 0.5) / 9.0 * 2.0 * half
			var hp := p + s3 * lat + Vector3(0, 0.1, 0)
			for e in _cr:
				var oc: Vector3 = (e[1] as Vector3)
				var c := Vector3(oc.x, e[3], oc.z)
				var v := c - hp
				var tca := v.dot(-_sun)
				if tca <= 0.0: continue
				if v.length_squared() - tca * tca <= float(e[2]) * float(e[2]):
					tally[e[0]] = int(tally.get(e[0], 0)) + 1
	var keys := tally.keys()
	keys.sort_custom(func(a, b): return tally[a] > tally[b])
	print("umbritori (nume: puncte de banda umbrite din 54):")
	for k in keys.slice(0, 25):
		for e in _cr:
			if e[0] == k:
				print("  %s x%d  pos=(%.1f,%.1f,%.1f) raza=%.1f cy=%.1f" % [
					k, tally[k], (e[1] as Vector3).x, (e[1] as Vector3).y,
					(e[1] as Vector3).z, e[2], e[3]])
	get_tree().quit()
