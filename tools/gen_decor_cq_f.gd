extends Node
## Generator pentru decorul din POI F. Asaza piesele pe geometria REALA a
## motorului (routes[0].baked + raze de fizica), nu pe o reconstructie a
## curbei in Python: reconstructia mea diverja de traseul motorului si toate
## cele 125 de piese ieseau in aer.
##
## Regula: o piesa se pune DOAR unde raza gaseste podea la maxim 2.5 m sub
## cota ei. Restul se sare, si se scrie cate au fost sarite.
const OUT := "res://tools/_cq_f_nodes.txt"
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var r := track.routes[0]
	var n := r.count()
	var lines := PackedStringArray()
	var counter := [600]
	var skipped := 0
	var shops := ["49_shopa", "50_shopb", "51_shopc", "52_restaurant"]

	# suportul: cota podelei sub un punct, sau NAN
	var floor_at := func(p: Vector3) -> float:
		# de sus de tot in jos de tot: razele scurte ratau podeaua
		# Pornim de SUB cota drumului: deasupra trece etajul superior al
		# nodului (pista peste pista) si razele lungi il loveau pe el.
		var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 1.2, p + Vector3.DOWN * 8.0)
		var h := space.intersect_ray(q)
		return NAN if h.is_empty() else float(h.position.y)

	var emit := func(nm: String, res: String, pos: Vector3, yaw: float) -> void:
		var b := Basis(Vector3.UP, yaw)
		lines.append('[node name="%s%d" parent="DecorManual/6) Nodul Huangjuewan" instance=ExtResource("%s")]' % [nm, counter[0], res])
		# Cele 12 numere sunt pe LINII: `basis.x = (a0, a3, a6)`. Scrise pe
		# coloane iese transpusa, adica rotatia inversa (vezi
		# `tools/fix_cq_fatade.gd`) — exact ce a intors casele nodului cu
		# spatele la drum.
		lines.append('transform = Transform3D(%.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f)' % [
			b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z, pos.x, pos.y, pos.z])
		lines.append('metadata/coliziune = "none"')
		lines.append("")
		counter[0] += 1

	var k := 0
	var step := -1
	var f := 0.598
	while f < 0.830:
		step += 1
		var i := int(round(f * float(n))) % n
		var c: Vector3 = r.baked[i]
		var fw := (r.baked[(i + 1) % n] - r.baked[(i - 1 + n) % n]).normalized()
		var yaw := atan2(fw.x, fw.z)
		var side := Vector3(fw.z, 0.0, -fw.x).normalized()
		# --- case: doar unde exista mal la cota drumului
		if step % 3 == 0:
			for sgn: float in [-1.0, 1.0]:
				var p := c + side * 12.5 * sgn
				var g: float = floor_at.call(p)
				if is_nan(g) or absf(g - c.y) > 2.5:
					skipped += 1
					continue
				# YAW-UL SE IA DIN DIRECTIA SPRE SOSEA, nu din tangenta.
				# `yaw ± PI/2` presupune ca piesa sta exact pe normala; in nod
				# (care e un viraj) diverge cu zeci de grade, si criticul a
				# numarat 33 de pravalii cu spatele la drum.
				var out_dir := (p - c)
				out_dir.y = 0.0
				out_dir = out_dir.normalized()
				emit.call("casaFmal", shops[k % 4], Vector3(p.x, g, p.z),
					atan2(out_dir.x, out_dir.z))
				k += 1
		# --- felinare pe buza: au deck sub ele si pe viaduct
		if step % 4 == 0:
			for sgn: float in [-1.0, 1.0]:
				var p := c + side * 8.0 * sgn
				var g: float = floor_at.call(p)
				if is_nan(g) or absf(g - c.y) > 1.2:
					skipped += 1
					continue
				emit.call("felinarF", "21_lamp", Vector3(p.x, g, p.z), yaw)
		# --- reclame la inaltimea privirii, pe stalpul felinarului
		if step % 7 == 0:
			var sgn2 := -1.0 if (counter[0] % 2 == 0) else 1.0
			var p2 := c + side * 8.4 * sgn2
			var g2: float = floor_at.call(p2)
			if not is_nan(g2) and absf(g2 - c.y) <= 1.2:
				emit.call("neonF", "40_neona" if counter[0] % 4 < 2 else "41_neonc",
					Vector3(p2.x, g2 + 3.0, p2.z), yaw + (PI * 0.5 if sgn2 > 0.0 else -PI * 0.5))
			else:
				skipped += 1
		f += 0.003
	var fa := FileAccess.open(OUT, FileAccess.WRITE)
	fa.store_string("\n".join(lines))
	fa.close()
	print("scrise %d noduri, sarite %d (fara sprijin)" % [counter[0] - 600, skipped])
	# diagnostic: ce gaseste raza la cateva fractii
	for ff: float in [0.60, 0.62, 0.65, 0.68, 0.70, 0.75, 0.80]:
		var ii := int(round(ff * float(n))) % n
		var cc: Vector3 = r.baked[ii]
		var fww := (r.baked[(ii + 1) % n] - r.baked[(ii - 1 + n) % n]).normalized()
		var sd := Vector3(fww.z, 0.0, -fww.x).normalized()
		var row := "frac %.2f road_y %6.2f :" % [ff, cc.y]
		for dd: float in [0.0, 8.0, 12.5, -8.0, -12.5]:
			var pp := cc + sd * dd
			var gg: float = floor_at.call(pp)
			row += ("  %+6.2f" % (gg - cc.y)) if not is_nan(gg) else "    ----"
		print(row)
	get_tree().quit()
