extends Node
## SONDA TEMPORARA — geometria craterului de pe Track11 (Stromboli).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCraterFit.tscn
##
## Tipareste: canalul rezolvat (unde taie drumul, cota, axele), centrul cuvei
## crater_bowl in lume si in coordonatele canalului, cotele drumului pe buza,
## si terenul pe o grila radiala in jurul cuvei fata de suprafata cuvei —
## adica exact ce trebuie ca sapatura sa se ascunda COMPLET sub asset.

const SCALE := 1.1937588
# (raza, z) din tools/blender/build_crater_bowl.py — profilul teraselor.
const PROFILE := [
	[9.0, -13.0], [9.68, -11.27], [12.39, -10.95], [13.23, -8.55],
	[16.26, -8.19], [16.99, -6.10], [20.23, -5.73], [21.11, -3.11],
	[24.87, -2.67], [25.66, -0.40], [29.0, 0.0], [37.0, -9.0],
]


func _bowl_z(r_world: float) -> float:
	# Cota suprafetei cuvei (relativ la originea ei = coronament) la raza data,
	# liniar pe portiuni. In afara fustei nu exista suprafata -> INF.
	var r := r_world / SCALE
	if r <= 9.0:
		return -13.0 * SCALE
	for i in PROFILE.size() - 1:
		var a: Array = PROFILE[i]
		var b: Array = PROFILE[i + 1]
		if r >= float(a[0]) and r <= float(b[0]):
			var t := (r - float(a[0])) / (float(b[0]) - float(a[0]))
			return lerpf(float(a[1]), float(b[1]), t) * SCALE
	return INF


func _ready() -> void:
	await get_tree().process_frame
	var scene := load("res://scenes/tracks/Track11.tscn") as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var r := track.routes[0]
	var n := r.count()

	print("")
	print("=== canalele rezolvate ===")
	for ch in track._channels:
		var o: Vector3 = ch["origin"]
		print("%s: origin (%.1f, %.2f, %.1f)  frac %.3f  gap %.1f (cerut %.1f)" % [
			ch.get("label", "?"), o.x, o.y, o.z,
			r.frac_at(int(ch["index"])), float(ch["gap"]), float(ch["gap_requested"])])
		print("   along (perp. drum) (%.2f, %.2f)  across (pe drum) (%.2f, %.2f)" % [
			(ch["along2"] as Vector2).x, (ch["along2"] as Vector2).y,
			(ch["across2"] as Vector2).x, (ch["across2"] as Vector2).y])

	var bowl := track.get_node_or_null("DecorManual/4)Crater/crater_bowl") as Node3D
	if bowl == null:
		print("NU gasesc crater_bowl!")
		get_tree().quit()
		return
	var bc := bowl.global_position
	print("")
	print("=== crater_bowl ===")
	print("centru lume: (%.2f, %.2f, %.2f)  raza coronament %.1f  fusta %.1f  adancime %.1f" % [
		bc.x, bc.y, bc.z, 29.0 * SCALE, 37.0 * SCALE, 13.0 * SCALE])

	for ch in track._channels:
		var o: Vector3 = ch["origin"]
		var d := Vector2(bc.x - o.x, bc.z - o.z)
		var t := d.dot(ch["along2"] as Vector2)
		var s := d.dot(ch["across2"] as Vector2)
		print("fata de canalul '%s': s (pe drum) %.1f m, t (perp.) %.1f m; buza vs drum: %+.2f m" % [
			ch.get("label", "?"), s, t, bc.y - o.y])

	print("")
	print("=== drumul pe buza (frac 0.42..0.58) ===")
	var step := maxi(n / 100, 1)
	for i in range(0, n, step):
		var f := r.frac_at(i)
		if f < 0.42 or f > 0.58:
			continue
		var p: Vector3 = r.baked[i]
		var dist := Vector2(p.x - bc.x, p.z - bc.z).length()
		print("frac %.3f  (%7.1f, %5.1f, %7.1f)  pana la centrul cuvei %5.1f m" % [
			f, p.x, p.y, p.z, dist])

	print("")
	print("=== teren radial in jurul cuvei (teren - suprafata cuvei; negativ = ASCUNS sub asset) ===")
	var radii := [4.0, 12.0, 20.0, 28.0, 34.0, 38.0, 44.0, 55.0, 70.0]
	var header := "raza:  "
	for rad: float in radii:
		header += "%7.0f" % rad
	print(header + "   (m)")
	for k in 12:
		var ang := TAU * float(k) / 12.0
		var line := "a%3d°  " % int(rad_to_deg(ang))
		for rad: float in radii:
			var wx := bc.x + cos(ang) * rad
			var wz := bc.z + sin(ang) * rad
			var gy: float = track._sampler.ground_y(wx, wz)
			var bz := _bowl_z(rad)
			if bz == INF:
				line += " %6.1f" % (gy - bc.y)  # teren fata de coronament
			else:
				var diff := gy - (bc.y + bz)
				line += " %6.1f" % diff
		print(line)
	print("(pe razele <= %.0f cifra e teren-MINUS-cuva: vrem NEGATIV peste tot;" % (32.0 * SCALE))
	print(" pe razele mai mari e teren-minus-coronament: vrem ~0 pentru platou plat)")

	var sg: float = track._sampler.ground_y(-172.01807, 291.48688)
	print("")
	print("teren sub scoria_rock (-172.0, 291.5): y = %.2f" % sg)

	print("")
	print("=== varful: teren pe grila larga (fata de cota buzei %.1f) ===" % bc.y)
	for dz in [-80, -40, 0, 40, 80]:
		var line := ""
		for dx in [-80, -40, 0, 40, 80]:
			var gy: float = track._sampler.ground_y(bc.x + dx, bc.z + dz)
			line += " %6.1f" % (gy - bc.y)
		print("dz %+4d: %s" % [dz, line])

	# Proba de CADERE: hull-ul convex al cuvei era un capac invizibil peste gura
	# (masina "plutea"). Cu modul `mesh` bila trebuie sa ajunga pe fund (~-15 m
	# sub coronament), nu sa se opreasca la nivelul buzei.
	print("")
	print("=== proba de cadere (bila aruncata in gura craterului) ===")
	var ball := RigidBody3D.new()
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.5
	cs.shape = sph
	ball.add_child(cs)
	ball.position = Vector3(bc.x + 6.0, bc.y + 12.0, bc.z + 6.0)
	get_tree().root.add_child(ball)
	for i in 240:
		await get_tree().physics_frame
		if i % 60 == 59:
			print("t=%.0fs  y=%.2f (fata de coronament %+.2f)" % [
				(i + 1) / 60.0, ball.position.y, ball.position.y - bc.y])
	get_tree().quit()
