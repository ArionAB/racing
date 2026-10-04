extends SceneTree
## GARDA POI F: nicio piesa din DecorManual/ZoneF_Gradina pe traiectoria discului
## daruma (de la turn, slide_distance spre interior) sau in cercul turnului+ciocanului.
##   godot --headless --path . --script res://tools/probe_kyoto_f_disc.gd [-- --sabotage]
## --sabotage muta o piesa pe mijlocul traiectoriei: verdictul trebuie sa pice.
var _t: Track
var _f := 0
func _process(_d: float) -> bool:
	if _t == null:
		_t = (load("res://scenes/tracks/Track18.tscn") as PackedScene).instantiate() as Track
		root.add_child(_t)
		return false
	_f += 1
	if _f < 3:
		return false
	# Din oct 2026 hazardul e carul Gion Matsuri: traiectoria = tot drumul lui de la o
	# odihna la cealalta (capetele caroseriei incluse), nu alunecarea discului daruma.
	var hz := _t.get_node("Hazarduri/GionMatsuri") as GionMatsuriHazard
	var o := hz.outward()
	var reach := hz.rest_x() + hz.cart_length * 0.5
	var a_w := hz.global_position + o * reach
	var b_w := hz.global_position - o * reach
	var tower := hz.global_position + o * hz.rest_x()
	var a := Vector2(a_w.x, a_w.z)
	var b := Vector2(b_w.x, b_w.z)
	var zone := _t.get_node("DecorManual/ZoneF_Gradina")
	if "--sabotage" in OS.get_cmdline_user_args():
		var c := zone.get_child(0) as Node3D
		var m := (a + b) * 0.5
		c.global_position = Vector3(m.x, c.global_position.y, m.y)
	var min_path := INF
	var min_tower := INF
	var worst := ""
	for c in zone.get_children():
		var p := Vector2((c as Node3D).global_position.x, (c as Node3D).global_position.z)
		var q := Geometry2D.get_closest_point_to_segment(p, a, b)
		var d := p.distance_to(q)
		if d < min_path:
			min_path = d
			worst = str(c.name)
		min_tower = minf(min_tower, p.distance_to(Vector2(tower.x, tower.z)))
	var lim := hz.cart_width * 0.5 + 1.5
	var ok := min_path >= lim and min_tower >= 10.0
	print("piese: %d; cea mai apropiata de traiectoria discului: %s la %.1f m (minim %.1f); de turn %.1f m (minim 10)" % [
		zone.get_child_count(), worst, min_path, lim, min_tower])
	print("VERDICT: %s" % ("PASS" if ok else "PICAT"))
	quit(0 if ok else 1)
	return true
