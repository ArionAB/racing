extends Node
## Sonda de RELEVEU pentru POI C (Vadul Mara, Track14): tipareste campul de
## teren (ground_y) pe o grila in jurul vadului, cota soselei si a marii,
## latimea benzii, directia reala a soarelui si pozitia hipopotamilor fata de
## banda. Nu decide nimic — masoara inainte de asezare.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSerCSurvey.tscn -- [--x0=-130 --x1=-20 --z0=90 --z1=260 --step=6]

const TRACK := "res://scenes/tracks/Track14.tscn"

var _track: Track


func _arg(name: String, fallback: float) -> float:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(name + "="):
			return float(a.substr(name.length() + 1))
	return fallback


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var s: TrackSideSampler = _track._sampler
	var sea_y := s.mean_road_y() + _track.sea_level_offset
	print("mean_road_y %.3f  sea_level_offset %.3f  sea_y %.3f" % [
		s.mean_road_y(), _track.sea_level_offset, sea_y])
	var n := _track.baked.size()
	var total: float = _track._dists[n]
	print("baked %d  lungime %.1f" % [n, total])
	# Soarele: din nodul real, nu din euler.
	var sun := _find_light(_track)
	if sun != null:
		var d := -sun.global_transform.basis.z
		print("SOARE: lumina merge spre (%.3f, %.3f, %.3f); spre soare (%.3f, %.3f, %.3f); umbra XZ (%.3f, %.3f)" % [
			d.x, d.y, d.z, -d.x, -d.y, -d.z, d.x, d.z])
	# Profilul soselei pe interval.
	print("--- sosea (frac, x, y, z, half, side, teren la +/-(half+2), +/-(half+12), +/-(half+24))")
	var f := 0.110
	while f <= 0.180:
		var i := int(f * float(n)) % n
		var p: Vector3 = _track.baked[i]
		var side: Vector3 = _track._side_at(i)
		var half: float = _track.width_at_index(i)
		var vals: Array[String] = []
		for lat in [half + 2.0, half + 12.0, half + 24.0] as Array[float]:
			var a := p + side * lat
			var b := p - side * lat
			vals.append("%.2f/%.2f" % [s.ground_y(a.x, a.z), s.ground_y(b.x, b.z)])
		print("%.3f  x %.1f y %.2f z %.1f  half %.1f side(%.2f,%.2f)  %s" % [
			f, p.x, p.y, p.z, half, side.x, side.z, " ".join(vals)])
		f += 0.004
	# Grila de teren.
	var x0 := _arg("--x0", -130.0)
	var x1 := _arg("--x1", -20.0)
	var z0 := _arg("--z0", 90.0)
	var z1 := _arg("--z1", 260.0)
	var step := _arg("--step", 6.0)
	var head := "   z/x "
	var x := x0
	while x <= x1:
		head += "%6.0f" % x
		x += step
	print(head)
	var z := z0
	while z <= z1:
		var row := "%6.0f " % z
		x = x0
		while x <= x1:
			var y := s.ground_y(x, z)
			row += "%6.1f" % y
			x += step
		print(row)
		z += step
	# Hipopotamii.
	for h in _track.get_node("Hazarduri").get_children():
		if h is HippoHazard:
			var q := _track._closest_baked_index(h.global_position)
			var p2: Vector3 = _track.baked[q]
			var lat: float = (h.global_position - p2).dot(_track._side_at(q))
			print("HIPPO %s pos(%.1f,%.2f,%.1f) frac %.4f lateral %.2f m (half %.1f) sosea y %.2f" % [
				h.name, h.global_position.x, h.global_position.y, h.global_position.z,
				float(q) / float(n), lat, _track.width_at_index(q), p2.y])
	# Apa vadului: exista mesh-ul, si unde sta fata de pat si de asfalt?
	for c in _track.get_children():
		var nm := String(c.name)
		if nm.begins_with("ChannelWater") or nm.begins_with("Sea"):
			var mi := c as MeshInstance3D
			if mi != null:
				print("APA %s  AABB %s  vizibil %s" % [nm, mi.get_aabb(), mi.visible])
	for ch in _track._channels:
		print("CANAL %s ford=%s origin=%s depth=%.2f drop=%s steps=%d gap=%.1f" % [
			ch.get("label"), ch.get("ford"), ch["origin"], ch["depth"],
			ch.get("water_y_drop"), int(ch["steps"]), ch["gap"]])
	# Cota terenului exact sub crocodili si sub bolovanii de mal: apa vadului e
	# la -1.08, deci se vede daca stau pe uscat, la linia apei sau ingropati.
	# Unde e LINIA APEI pe fiecare mal: se cauta z-ul la care terenul trece prin
	# cota apei, pe cateva coloane de x. Acolo se aseaza crocodilii (jumatate in
	# apa), nu pe o cota ghicita.
	var water_y := -1.08
	for cx in [-100.0, -92.0, -84.0, -76.0, -62.0, -55.0, -47.0, -40.0] as Array[float]:
		var hits: Array[String] = []
		var zz := 100.0
		var prev := s.ground_y(cx, zz)
		while zz <= 240.0:
			var cur := s.ground_y(cx, zz)
			if (prev - water_y) * (cur - water_y) < 0.0:
				hits.append("%.1f" % zz)
			prev = cur
			zz += 1.0
		print("LINIA APEI x=%.0f : z = %s" % [cx, ", ".join(hits)])
	for nd in _track.find_children("Crocodil*", "Node3D", true, false):
		var gp: Vector3 = nd.global_position
		var gy := s.ground_y(gp.x, gp.z)
		print("CROC %s pos(%.1f,%.2f,%.1f) teren %.2f  fata de apa(-1.08) %+.2f" % [
			nd.name, gp.x, gp.y, gp.z, gy, gp.y - (-1.08)])
	get_tree().quit(0)


func _find_light(node: Node) -> DirectionalLight3D:
	if node is DirectionalLight3D:
		return node as DirectionalLight3D
	for c in node.get_children():
		var r := _find_light(c)
		if r != null:
			return r
	return null
