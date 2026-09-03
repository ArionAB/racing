extends Node
## CE E DEASUPRA SOSELEI? Raze in sus din carosabil (axa si doua flancuri),
## pe o ruta, si ce loveste fiecare: tavan (la cati metri), sau CER.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSkyAbove.tscn -- ##       --track=6 [--route=1] [--from=0.0] [--to=1.0] [--step=0.003]
##
## Pasul e in fractie de ruta; sub 0.01 se tiparesc doar liniile cu cer, ca sa
## se vada FANTELE (o fanta de 1.5 m intre doua lespezi de tavan pe ocolul
## pietrei a scapat la 3.5 m intre probe si a iesit la 0.5 m). Punctele se
## interpoleaza intre cele coapte, deci pasul poate fi mai fin decat
## `bake_interval` (3 m). Flancurile la ±2.5 m prind fantele care nu sunt pe axa.
##
## [b]Doar corpuri fizice.[/b] `intersect_ray` nu vede decorul cu
## `metadata/coliziune = "none"`: capacul stancii goale a intrat in cifra abia
## dupa ce coaja a primit coliziune "mesh" (3 sep 2026). Cand o suprafata
## „lipseste" aici dar se vede in captura, verifica intai coliziunea ei
## (memoria `coliziune-none-e-fantoma-nu-stearsa`).
##
## Nu are prag: e instrument de masura, verdictul il da cine citeste (pe elice
## ultima tura TREBUIE sa aiba capac, gura din capac TREBUIE sa aiba cer).

var _track_index: int = 6

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			_track_index = int(arg.trim_prefix("--track="))
	var resolved := GameState.resolve_track_index(_track_index)
	if resolved < 0:
		push_error("probe_sky_above: --track=%d invalid" % _track_index)
		get_tree().quit(2)
		return
	var t := (load(GameState.TRACK_SCENES[resolved]) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var axis := Vector2(-302.02, 6.0) # axa stancii goale (Cappadocia): doar pentru coloana `r`
	var route_i := 0
	var f := 0.82
	var f_end := 0.99
	var step := 0.01
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--route="):
			route_i = int(arg.trim_prefix("--route="))
		elif arg.begins_with("--from="):
			f = float(arg.trim_prefix("--from="))
		elif arg.begins_with("--to="):
			f_end = float(arg.trim_prefix("--to="))
		elif arg.begins_with("--step="):
			step = float(arg.trim_prefix("--step="))
	var r := t.routes[route_i]
	var n := r.baked.size()
	print("ruta %d: n=%d lungime=%.1f" % [route_i, n, t.curve.bake_interval * n])
	var space := get_viewport().world_3d.direct_space_state
	var sky_hits := 0
	var probes := 0
	while f < f_end:
		var fi := f * float(n)
		var i := int(fi) % n
		var p: Vector3 = r.baked[i].lerp(r.baked[(i + 1) % n], fi - floorf(fi))
		var dirv: Vector3 = (r.baked[(i + 1) % n] - r.baked[i]).normalized()
		var sidev := dirv.cross(Vector3.UP).normalized()
		var d := Vector2(p.x - axis.x, p.z - axis.y).length()
		var line := "frac %.3f  y=%.1f  r=%.1f  hw=%.1f  sus:" % [f, p.y, d, t.width_at(f)]
		for lat: float in [-2.5, 0.0, 2.5]:
			var o := p + sidev * lat
			var q := PhysicsRayQueryParameters3D.create(o + Vector3.UP * 1.5, o + Vector3.UP * 200.0)
			q.collision_mask = 0xFFFFFFFF
			var hit := space.intersect_ray(q)
			probes += 1
			if hit.is_empty():
				line += "  [%+.1f] CER la (%.2f, %.2f) dir=(%.3f, %.3f)" % [lat, o.x, o.z, dirv.x, dirv.z]
				sky_hits += 1
			else:
				line += "  [%+.1f] %.1f" % [lat, (hit["position"] as Vector3).y - p.y]
		if "CER" in line or step >= 0.01:
			print(line)
		f += step
	print("total: %d/%d raze cu cer" % [sky_hits, probes])
	get_tree().quit()
