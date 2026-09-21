extends Node
## Sonda ad-hoc (Fiordland, scurtatura Chasm): profilul lateral ground_y intre
## axa principala si axa benzii ScurtaturaChasm, la AMBELE bifurcatii
## (desprindere si revenire — fereastra derivata din entry_frac/exit_frac ale
## rutei, nu o fractie fixa), din 3 in 3 m longitudinal si din 0.5 in 0.5 m
## lateral. Scrie orice treapta > 0.3 m (zid, memoria
## suprafete-cu-goluri-si-praguri) si orice panta transversala > 25% intre
## benzi (sant).
## Doar citire din pista.
##   godot --headless --path . res://tools/SvScurtaturaProfil.tscn -- [--track=16]
const TRACK_FMT := "res://scenes/tracks/Track%02d.tscn"

var _worst_step := 0.0
var _worst_step_at := ""
var _worst_slope := 0.0
var _worst_slope_at := ""


func _ready() -> void:
	await get_tree().process_frame
	var track_no := 16
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--track="):
			track_no = int(a.trim_prefix("--track="))
	var t := (load(TRACK_FMT % track_no) as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4:
		await get_tree().process_frame

	var main_route := t.route_at(0)
	if t.routes.size() < 2:
		print("nicio ruta secundara gasita pe Track%02d (routes.size()=%d)" % [track_no, t.routes.size()])
		get_tree().quit(1)
		return
	var branch_route: TrackRoute = t.routes[1]

	print("main.half_width=%.2f branch.half_width=%.2f branch.entry_frac=%.4f branch.exit_frac=%.4f"
		% [main_route.half_width, branch_route.half_width, branch_route.entry_frac, branch_route.exit_frac])

	var total_len: float = main_route.dists[main_route.dists.size() - 1]

	# Scaneaza AMBELE bifurcatii (desprindere + revenire), nu doar una fixa:
	# fereastra se deriva din entry_frac/exit_frac ale rutei, deci geometria
	# noua (redesenata) e prinsa automat — o fereastra veche fixa (0.33..0.41)
	# ar rata revenirea daca exit_frac s-a mutat in afara ei.
	print("\n=== desprindere (entry_frac=%.4f) ===" % branch_route.entry_frac)
	_scan_window(t, main_route, branch_route.entry_frac - 0.02,
		branch_route.entry_frac + 0.06, total_len)
	print("\n=== revenire (exit_frac=%.4f) ===" % branch_route.exit_frac)
	_scan_window(t, main_route, branch_route.exit_frac - 0.06,
		branch_route.exit_frac + 0.02, total_len)

	print("\n--- rezumat ---")
	print("cea mai mare treapta (0.5 m lateral): %.3f m la %s (prag zid: 0.3 m)"
		% [_worst_step, _worst_step_at])
	print("cea mai mare panta transversala: %.1f%% la %s (prag sant: 25%%)"
		% [_worst_slope * 100.0, _worst_slope_at])
	if _worst_step > 0.3:
		print("VERDICT: treapta peste prag — zid intre benzi")
	elif _worst_slope > 0.25:
		print("VERDICT: panta peste prag — sant intre benzi")
	else:
		print("VERDICT: profil curat, sub ambele praguri")
	get_tree().quit(0)


func _scan_window(t: Track, main_route: TrackRoute, f0: float, f1: float,
		total_len: float) -> void:
	var s0 := f0 * total_len
	var s1 := f1 * total_len
	var s := s0
	while s <= s1:
		var frac: float = s / total_len
		# gaseste indexul copt cel mai apropiat de distanta `s` pe bucla principala
		var idx := _index_at_dist(main_route, s)
		var p: Vector3 = main_route.baked[idx]
		var side: Vector3 = _side_at(main_route, idx)
		var line := "s=%.1f frac=%.4f drum=(%.1f,%.1f,%.1f) y_drum=%.2f: " % [s, frac, p.x, p.y, p.z, p.y]
		# Lateralul incepe DUPA marginea asfaltului principal: sub asfalt
		# ground_y are un artefact cunoscut (_smin(a,a,k) scade k/4 chiar cand
		# rapa e inerta, lat=0) care nu se vede niciodata din masina — pavajul
		# il acopera. Pragurile de zid/sant conteaza doar pe teren descoperit.
		var lat := main_route.half_width + 0.5
		var prev_y := t._sampler.ground_y(p.x + side.x * lat, p.z + side.z * lat)
		var max_lat := 14.0
		while lat <= max_lat:
			var wx := p.x + side.x * lat
			var wz := p.z + side.z * lat
			var y := t._sampler.ground_y(wx, wz)
			var step := absf(y - prev_y)
			if step > _worst_step:
				_worst_step = step
				_worst_step_at = "s=%.1f lat=%.1f (%.2f -> %.2f)" % [s, lat, prev_y, y]
			var slope := step / 0.5
			if slope > _worst_slope:
				_worst_slope = slope
				_worst_slope_at = "s=%.1f lat=%.1f slope=%.2f" % [s, lat, slope]
			prev_y = y
			line += "%.1f:%.2f " % [lat, y]
			lat += 0.5
		print(line)
		s += 3.0


func _index_at_dist(route: TrackRoute, s: float) -> int:
	var dists := route.dists
	var n := dists.size()
	# cautare liniara e suficienta (rulare unica, cateva zeci de pasi)
	for i in range(n - 1):
		if dists[i] <= s and dists[i + 1] >= s:
			return i
	return n - 2 if n > 1 else 0


func _side_at(route: TrackRoute, idx: int) -> Vector3:
	var n := route.baked.size()
	var i0 := maxi(idx - 1, 0)
	var i1 := mini(idx + 1, n - 1)
	var fwd: Vector3 = (route.baked[i1] - route.baked[i0])
	fwd.y = 0.0
	if fwd.length_squared() < 0.0001:
		return Vector3(1, 0, 0)
	fwd = fwd.normalized()
	# perpendicular pe orizontala (dreapta soferului): rotatie -90 grade in jurul Y
	return Vector3(fwd.z, 0.0, -fwd.x)
