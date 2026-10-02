extends Node
## GARDA: e tubul shishi-odoshi ASEZAT pe axa soselei reale a lui Track18?
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeKyotoTubPos.tscn
##
## De ce exista (memoria hazard-dezaliniat-contamineaza-verdictul): pe
## Fiordland autocarul mergea 8 m in afara drumului si toate verdictele ProbeRace
## de langa el erau contaminate. Pozitia tubului vine din generator (curba
## Python, plata), iar drumul REAL e bake-ul Catmull-Rom din Godot: aici se
## masoara ce a iesit, nu ce s-a calculat.
##
## Contracte: (a) originea hazardului sta pe axa (|lateral| <= 0.6 m);
## (b) -Z local e pe sensul de mers (cos >= 0.99); (c) pivotul sta pe MARGINEA
## soselei, pe partea `side` (lateral = side * semilatimea, +-0.6 m); (d)
## `outward()` arata spre partea pivotului; (e) gura (capatul bratului) ajunge
## peste axa soselei; (f) semilatimea locala = cea declarata (5.5 m).

func _ready() -> void:
	await get_tree().process_frame
	var idx := GameState.resolve_track_index(18)
	var scene := load(GameState.TRACK_SCENES[idx]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	var hz: ShishiOdoshiHazard = null
	for n in get_tree().get_nodes_in_group(ShishiOdoshiHazard.AI_GROUP):
		hz = n as ShishiOdoshiHazard
	if hz == null:
		print("PROBLEMA: niciun ShishiOdoshiHazard in scena")
		get_tree().quit(1)
		return
	var i := track.closest_index_global(hz.global_position)
	var rc := track.road_coords(i, hz.global_position)
	var f := track.frac_at(i)
	var hw := track.width_at_index(i)
	var side_v := track.routes[0].side_at(i)
	var tang := (track.point_at(i + 1) - track.point_at(i)).normalized()
	var fwd := -hz.global_transform.basis.z
	var cos_t := Vector2(fwd.x, fwd.z).normalized().dot(Vector2(tang.x, tang.z).normalized())
	var pv := hz.get_node("Pivot") as Node3D
	var prc := track.road_coords(i, pv.global_position)
	var out_dot := hz.outward().dot(Vector3(side_v.x, 0, side_v.z).normalized())
	var arm := hz.arm_length()
	# gura: de la pivot, `arm` m pe directia -Z a pivotului (spre axa), la rest
	var mouth := pv.global_position + (-pv.global_transform.basis.z).normalized() * arm
	var mrc := track.road_coords(i, mouth)
	var ok := true
	var lines: Array[String] = []
	lines.append("frac %.4f  semilatime locala %.2f m (declarata %.2f)" % [f, hw, hz.road_half_width])
	var a := absf(rc.y) <= 0.6
	lines.append("  [%s] (a) origine pe axa: lateral %+.2f m" % ["OK" if a else "PROBLEMA", rc.y])
	var b := cos_t >= 0.99
	lines.append("  [%s] (b) -Z pe sensul de mers: cos %.4f" % ["OK" if b else "PROBLEMA", cos_t])
	var c := absf(prc.y - float(hz.side) * hw) <= 0.6
	lines.append("  [%s] (c) pivot pe margine, partea %+d: lateral %+.2f (asteptat %+.2f)" % [
		"OK" if c else "PROBLEMA", hz.side, prc.y, float(hz.side) * hw])
	var d := out_dot >= 0.99
	lines.append("  [%s] (d) outward() spre partea pivotului: dot %.3f" % ["OK" if d else "PROBLEMA", out_dot])
	var e := absf(mrc.y) <= hw * 0.5 or (mrc.y * float(hz.side)) < 0.0
	lines.append("  [%s] (e) gura peste drum: lateral %+.2f m (axa 0, pivot %+.2f)" % [
		"OK" if e else "PROBLEMA", mrc.y, prc.y])
	var g := absf(hw - hz.road_half_width) <= 0.3
	lines.append("  [%s] (f) semilatime locala = declarata: %.2f vs %.2f" % [
		"OK" if g else "PROBLEMA", hw, hz.road_half_width])
	for l in lines:
		print(l)
	ok = a and b and c and d and e and g
	# Pozitia lumii: unde cade pivotul si unde cade mareea apei iazului.
	print("pivot lume: (%.1f, %.1f, %.1f)  axa: (%.1f, %.1f, %.1f)" % [
		pv.global_position.x, pv.global_position.y, pv.global_position.z,
		track.point_at(i).x, track.point_at(i).y, track.point_at(i).z])
	print("VERDICT: %s" % ("OK" if ok else "PROBLEMA"))
	get_tree().quit(0 if ok else 1)
