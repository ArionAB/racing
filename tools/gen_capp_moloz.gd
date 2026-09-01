extends Node
## Genereaza MOLOZ PE MARGINEA DRUMULUI in padurea de hornuri (portiunea B).
##
## De ce nu la mana: pozitiile trebuie sa cada pe cota reala a terenului si la o
## distanta constanta de banda, iar banda coteste. Se esantioneaza traseul si se
## scrie un .tscn de lipit — aceeasi reteta ca `gen_decor_climb` (memoria
## `decor-manual-din-cod`).
##
## Nu se pun in carosabil si nici pe umarul lui: raza rotii cade in orice
## denivelare (memoria `suprafete-cu-goluri-si-praguri`), deci pietrele stau
## dincolo de half_width + o palma, si primesc coliziune "none".
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 8:
		await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = 60318
	var space = get_tree().root.world_3d.direct_space_state
	# Panza de teren, singura pe care are voie sa stea o aschie. Scena
	# instantiata AICI contine deja padurea de hornuri, deci o raza care ia
	# prima lovitura poate ateriza pe hull-ul unui horn si aseaza piatra la 20 m
	# in aer (masurat: 8 piese intre 5.3 si 54.8 m in runda 29).
	var terrain_rid := RID()
	for c in t.get_children():
		if str(c.name) == "TerrainBody":
			terrain_rid = (c as StaticBody3D).get_rid()
	var sus_y := -INF
	for bp in r.baked:
		sus_y = maxf(sus_y, bp.y)
	sus_y += 120.0
	var out := PackedStringArray()
	out.append('[node name="MolozDeMargine" type="Node3D" parent="DecorManual"]\n')
	var k := 0
	# Padurea de hornuri: fractiile 0.02 - 0.11 (masurat cu ProbeFramePick:
	# padurea tine intre 0.03 si 0.08, se ia cu o palma de fiecare parte).
	var f := 0.015
	while f < 0.115:
		var i := int(f * n)
		var p: Vector3 = r.baked[i]
		var a: Vector3 = r.baked[(i + 4) % n]
		var dir: Vector3 = (a - p).normalized()
		var right := dir.cross(Vector3.UP).normalized()
		for side in [-1.0, 1.0]:
			var cate := rng.randi_range(2, 5)
			for c in cate:
				# dincolo de banda (half_width 6) plus degajare
				var off: float = side * rng.randf_range(7.5, 15.0)
				var along := rng.randf_range(-6.0, 6.0)
				var xz: Vector3 = p + right * off + dir * along
				# De sus de tot, si numai terenul conteaza: +60 m pornea din
				# INTERIORUL panzei pe portiunile inalte (creasta trece de 100 m).
				var q := PhysicsRayQueryParameters3D.create(
					Vector3(xz.x, sus_y, xz.z), Vector3(xz.x, sus_y - 900.0, xz.z))
				q.collide_with_areas = false
				var hit: Dictionary = space.intersect_ray(q)
				var garda := 0
				while not hit.is_empty() and hit["rid"] != terrain_rid and garda < 24:
					q.exclude = q.exclude + [hit["rid"]]
					hit = space.intersect_ray(q)
					garda += 1
				if hit.is_empty() or hit["rid"] != terrain_rid:
					continue
				var gy: float = hit["position"].y
				# marimi mici: astea sunt aschii de margine, nu bolovani —
				# bolovanii sunt in poalele hornurilor (talus_rocks)
				var sc := rng.randf_range(0.10, 0.30)
				var yaw := rng.randf() * TAU
				var cs := cos(yaw) * sc
				var sn := sin(yaw) * sc
				out.append('[node name="molozMargine%d" parent="DecorManual/MolozDeMargine" instance=ExtResource("27_crk_c")]' % k)
				out.append('transform = Transform3D(%.6f, 0, %.6f, 0, %.6f, 0, %.6f, 0, %.6f, %.3f, %.3f, %.3f)' % [
					cs, sn, sc, -sn, cs, xz.x, gy - sc * 0.6, xz.z])
				out.append('metadata/coliziune = "none"\n')
				k += 1
		f += 0.006
	var path := "res://.claude/moloz_margine.txt"
	var fh := FileAccess.open(path, FileAccess.WRITE)
	fh.store_string("\n".join(out))
	fh.close()
	print("scrise %d pietre in %s" % [k, path])
	get_tree().quit(0)
