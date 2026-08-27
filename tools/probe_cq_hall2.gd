extends Node
## Ce anume din bloc atinge cutia masinii: raycast vertical prin hol.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var blk := track.get_node_or_null("DecorManual/7) Liziba/bloc_liziba158")
	if blk == null: print("fara bloc"); get_tree().quit(1); return
	var gt: Transform3D = (blk as Node3D).global_transform
	print("bloc global origin %s" % gt.origin)
	print("bloc basis X %s (len %.3f)" % [gt.basis.x, gt.basis.x.length()])
	print("bloc basis Y %s (len %.3f)" % [gt.basis.y, gt.basis.y.length()])
	print("bloc basis Z %s (len %.3f)" % [gt.basis.z, gt.basis.z.length()])
	var inv := gt.affine_inverse()
	var r := track.routes[0]
	var n := r.count()
	print("frac    | pozitia axei in coordonate LOCALE blocului (x, y, z)")
	var f := 0.870
	while f <= 0.902:
		var i := int(round(f * float(n))) % n
		var p := r.baked[i]
		var side := track._side_at(i)
		for t: float in [-5.75, 0.0, 5.75]:
			var q := p + side * t
			var l := inv * q
			print("%.4f b%+5.1f  local (%7.2f, %6.2f, %7.2f)" % [r.frac_at(i), t, l.x, l.y, l.z])
		f += 0.002
	get_tree().quit()
