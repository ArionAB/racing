extends Node
## PRAGUL BENZII: forme JOASE si APROAPE, in pana de teren pe care o vede
## banda de jos a cadrului de sofer.
##
## De ce exista, cu cifre (sonda `probe_cadru_b`): banda masurata de
## `umbre_silueta` (v 0.55-1.0) ajunge doar la **11.3 m** in fata masinii, si
## inaltimea care mai incape in ea e 1.3 m la 4 m, 0.6 m la 8 m, 0 de la 12 m.
## Deci un horn de 6-15 m NU umple banda — isi duce silueta deasupra ei. Ce o
## umple sunt bolovani cazuti si tufe la 7.5-14 m lateral.
##
## Diferenta fata de `gen_capp_moloz`: acela pune ASCHII (scara 0.10-0.30, adica
## 20-60 cm) imprastiate pe 7.5-15 m. Astea sunt BLOCURI de 1.0-1.7 m, asezate
## dens si cu suprapunere pe ecran ceruta explicit.
##
## Lateralul e 7.6-11/12 m, nu mai mult, si cifra e masurata nu aleasa: ca sa
## cada in fereastra x 0.20-0.80 a metricii, o forma are voie la lat <= 8.25 m
## la 4 m in fata, <= 11.25 m la 8 m, <= 12.75 m la 10 m. Peste atat pica in
## afara cadrului masurat (si prima varianta, cu 13.5/15 m, chiar a picat).
##
## Doua reguli mostenite, si motivul lor:
##  - raza cade NUMAI pe TerrainBody (memoria: o raza care ia prima lovitura
##    ateriza pe hull-ul unui horn si punea piatra la 20 m in aer);
##  - nimic in carosabil si nici pe umar (raza rotii cade in orice denivelare),
##    deci dincolo de half_width + degajare, si coliziune "none".
const HALF_WIDTH := 7.0
const DEGAJARE := 0.6   # palma peste marginea benzii

func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 8:
		await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = 91177
	var space = get_tree().root.world_3d.direct_space_state
	var terrain_rid := RID()
	for c in t.get_children():
		if str(c.name) == "TerrainBody":
			terrain_rid = (c as StaticBody3D).get_rid()
	var sus_y := -INF
	for bp in r.baked:
		sus_y = maxf(sus_y, bp.y)
	sus_y += 120.0

	var blocuri := PackedStringArray()
	var tufe := PackedStringArray()
	blocuri.append('[node name="PragulBenzii" type="Node3D" parent="DecorManual"]\n')
	var kb := 0
	var kt := 0
	# Padurea de hornuri tine intre 0.015 si 0.115 (aceeasi fereastra ca molozul).
	# Pas mic: la 11 m de raza utila, un pas de 0.004 din tur (~3.5 m) lasa
	# goluri intre grupuri exact cat sa nu para gard.
	var f := 0.012
	while f < 0.120:
		var i := int(f * n) % n
		var p: Vector3 = r.baked[i]
		var a: Vector3 = r.baked[(i + 4) % n]
		var dir: Vector3 = (a - p).normalized()
		var right := dir.cross(Vector3.UP).normalized()
		for side in [-1.0, 1.0]:
			# BLOCURI: putine si mari, ca sa aiba silueta, nu pietris
			for c in rng.randi_range(1, 2):
				var off: float = side * rng.randf_range(HALF_WIDTH + DEGAJARE, 11.0)
				var along := rng.randf_range(-4.5, 4.5)
				var xz: Vector3 = p + right * off + dir * along
				var gy := _teren(space, xz, sus_y, terrain_rid)
				if gy == -INF:
					continue
				# chimney_a e 6.94 x 11.26 x 7.01 si costa 574 tri, fata de 1612
				# la cracked_chimney_b si 2528 la cracked_chimney_c. La scara
				# 0.09-0.15 iese un ciot de 1.0-1.7 m: exact bugetul benzii
				# (1.3 m la 4 m, 0.6 m la 8 m), la o treime din pretul blocului.
				var sc := rng.randf_range(0.09, 0.15)
				var yaw := rng.randf() * TAU
				var cs := cos(yaw) * sc
				var sn := sin(yaw) * sc
				blocuri.append('[node name="pragBloc%d" parent="DecorManual/PragulBenzii" instance=ExtResource("10_ch_a")]' % kb)
				blocuri.append('transform = Transform3D(%.6f, 0, %.6f, 0, %.6f, 0, %.6f, 0, %.6f, %.3f, %.3f, %.3f)' % [
					cs, sn, sc, -sn, cs, xz.x, gy - sc * 0.15, xz.z])
				blocuri.append('metadata/coliziune = "none"\n')
				kb += 1
			# TUFE: multe si ieftine (396 tri), rup conturul blocurilor
			for c in rng.randi_range(3, 6):
				var off2: float = side * rng.randf_range(HALF_WIDTH + 0.3, 12.0)
				var along2 := rng.randf_range(-5.0, 5.0)
				var xz2: Vector3 = p + right * off2 + dir * along2
				var gy2 := _teren(space, xz2, sus_y, terrain_rid)
				if gy2 == -INF:
					continue
				var sc2 := rng.randf_range(0.55, 1.25)
				var yaw2 := rng.randf() * TAU
				var cs2 := cos(yaw2) * sc2
				var sn2 := sin(yaw2) * sc2
				tufe.append('[node name="pragTufa%d" parent="DecorManual/PragulBenzii" instance=ExtResource("22_shrub")]' % kt)
				tufe.append('transform = Transform3D(%.6f, 0, %.6f, 0, %.6f, 0, %.6f, 0, %.6f, %.3f, %.3f, %.3f)' % [
					cs2, sn2, sc2, -sn2, cs2, xz2.x, gy2 - 0.05, xz2.z])
				tufe.append('metadata/coliziune = "none"\n')
				kt += 1
		f += 0.004
	var path := "res://.claude/prag_banda.txt"
	var fh := FileAccess.open(path, FileAccess.WRITE)
	fh.store_string("\n".join(blocuri) + "\n" + "\n".join(tufe))
	fh.close()
	print("scrise %d blocuri + %d tufe in %s" % [kb, kt, path])
	get_tree().quit(0)


func _teren(space, xz: Vector3, sus_y: float, terrain_rid: RID) -> float:
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
		return -INF
	return hit["position"].y
