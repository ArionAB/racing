extends Node
## Cat de mult e intoarsa fata cu ferestre (Z) spre camera de joc, pe fiecare
## bloc. Un unghi mare = fatada aprinsa se vede in muchie si ferestrele dispar.
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
		# camera de joc la fractia din dreptul blocului
		var bs := 0.0; var bd := 1e9
		for k in 600:
			var ss: float = float(k)/600.0*0.06*L
			var d := c.sample_baked(ss).distance_to(gp)
			if d < bd: bd = d; bs = ss
		var p := c.sample_baked(bs)
		var p2 := c.sample_baked(minf(bs+3.0,L))
		var fwd := (p2-p).normalized()
		var cam: Vector3 = p - fwd*12.5 + Vector3.UP*10.0
		var to_cam := (cam - gp).normalized()
		# fata cu ferestre: +Z si -Z ale piesei
		var zpos := n.global_transform.basis.z.normalized()
		var best := maxf(zpos.dot(to_cam), (-zpos).dot(to_cam))
		print("%s unghi_fata_ferestre=%.0f grade (0=drept spre camera, 90=muchie)"
			% [n.name, rad_to_deg(acos(clampf(best, -1.0, 1.0)))])
	get_tree().quit()
