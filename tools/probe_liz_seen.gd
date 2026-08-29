extends Node
## Ce fata a blocului vede camera de joc, si cata arie de FERESTRE (slot 30) e
## intoarsa spre ea. O metadata de lumina corecta pe o fata gresita da exact
## captura de acum: etaje vizibile, ferestre invizibile.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var c: Curve3D = (track.get_node("Path") as Path3D).curve
	var L := c.get_baked_length()
	var root := track.get_node("DecorManual/1) Piata Kuixinglou")
	for ch in root.get_children():
		if not str(ch.name).begins_with("bloc_sub_piata"): continue
		var n := ch as Node3D
		var gp := n.global_position
		# camera aproximativa: pe axa drumului, 10 m mai sus, 12.5 m inapoi
		var best_s := 0.0; var bd := 1e9
		for k in 500:
			var ss: float = float(k)/500.0*0.06*L
			var d := c.sample_baked(ss).distance_to(gp)
			if d < bd: bd = d; best_s = ss
		var p := c.sample_baked(best_s)
		var p2 := c.sample_baked(minf(best_s+3.0,L))
		var fwd := (p2-p).normalized()
		var cam: Vector3 = p - fwd*12.5 + Vector3.UP*10.0
		# aria de slot 30 orientata spre camera
		var mi: MeshInstance3D = _first(n)
		var arr := mi.mesh.surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var xf := mi.global_transform
		var vis30 := 0.0; var vis_tot := 0.0
		for i in range(0, idx.size(), 3):
			var a := xf * v[idx[i]]; var b := xf * v[idx[i+1]]; var cc := xf * v[idx[i+2]]
			var nn := (b-a).cross(cc-a); var ar := nn.length()*0.5
			if ar <= 0.0: continue
			nn = nn.normalized()
			var mid := (a+b+cc)/3.0
			# vizibila = normala intoarsa spre camera
			if nn.dot((cam-mid).normalized()) <= 0.05: continue
			vis_tot += ar
			var s := clampi(int(((uv[idx[i]]+uv[idx[i+1]]+uv[idx[i+2]])/3.0).x*32.0),0,31)
			if s == 30: vis30 += ar
		print("%s  arie_vizibila=%.0f  ferestre_vizibile=%.1f m2 (%.2f%%)"
			% [n.name, vis_tot, vis30, 100.0*vis30/maxf(vis_tot,0.001)])
	get_tree().quit()
func _first(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for ch in n.get_children():
		var r := _first(ch)
		if r: return r
	return null
