extends Node
## Tufele care franeaza si arunca frunze (feel_checklist: soft-hazards).
##
## Verifica:
##   1. registrul: `depth_at` e > 0 in tufa si 0 in afara ei, respecta inaltimea
##      (o tufa de pe alt nivel nu conteaza) si trece peste marginea celulei de
##      6 m; numele de chunk: tufele da, iarba densa nu, smocurile `Tuft` da;
##   2. o masina care strabate un rand de 12 tufe la 20 m/s: sar frunze
##      (`leaf_bursts` creste), pierde ceva viteza fata de aceeasi alergare FARA
##      tufe (0.5-8 m/s: frana usoara, nu zid) si nu e deviata lateral;
##   3. sub 6 m/s nu sar frunze; cu `bush_drag = 0` nu se pierde viteza;
##   4. in --headless chunk-urile de MultiMesh citesc pozitii zero: registrul
##      le sare (masuratoare moarta), deci ramane gol si nu schimba nimic.
## Citirea REALA a chunk-urilor de pe o pista se vede doar cu fereastra: vezi
## tools/CaptureFeelVfx.tscn (stagiul `veg`).
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSoftVeg.tscn

const STEP: float = 1.0 / 60.0
const SoftVeg := preload("res://scenes/props/soft_vegetation.gd")
const PropDebris := preload("res://scenes/props/prop_debris.gd")

var _failed: bool = false


func _ready() -> void:
	var g := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1200, 1, 1200)
	cs.shape = sh
	g.add_child(cs)
	g.position = Vector3(0, -0.5, 0)
	add_child(g)
	await get_tree().physics_frame
	print("")
	print("=== Tufe: frunze si franare usoara ===")
	_test_registry()
	await _test_drive()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _test_registry() -> void:
	print("")
	print("-- 1. registrul --")
	var root := Node3D.new()
	add_child(root)
	SoftVeg.add_bush(root, Vector3(5.9, 0, 0), 1.0, 1.2) # langa marginea celulei x=6
	SoftVeg.add_bush(root, Vector3(40, 3.0, 0), 1.0, 1.2) # alt nivel
	_check(SoftVeg.count(root) == 2, "doua tufe inregistrate")
	_check(SoftVeg.depth_at(root, Vector3(5.9, 0.1, 0)) > 0.9, "in centrul tufei: adancime ~1")
	var edge := SoftVeg.depth_at(root, Vector3(7.0, 0.1, 0)) # peste marginea celulei
	print("  adancime la 1.1 m de centru, in celula vecina: %.2f" % edge)
	_check(edge > 0.0 and edge < 0.7, "peste marginea celulei de 6 m tot o gaseste, mai putin adanc")
	_check(SoftVeg.depth_at(root, Vector3(9.0, 0.1, 0)) == 0.0, "la 3.1 m: in afara")
	_check(SoftVeg.depth_at(root, Vector3(40, 0.1, 0)) == 0.0, "tufa de pe alt nivel (+3 m) nu conteaza")
	_check(SoftVeg.depth_at(root, Vector3(40, 3.2, 0)) > 0.5, "...dar la nivelul ei da")
	_check(SoftVeg.is_bush_name("Bush_A_0_-") and SoftVeg.is_bush_name("Veg_Fern_Cluster_-1_-")
		and SoftVeg.is_bush_name("Sagebrush_Foliage") and SoftVeg.is_bush_name("Grass_Tuft_0_-"),
		"nume de tufa: Bush_A, Fern_Cluster, Sagebrush, Grass_Tuft")
	_check(not SoftVeg.is_bush_name("Grass_6_-") and not SoftVeg.is_bush_name("Grass")
		and not SoftVeg.is_bush_name("Rock_A_0_-"), "iarba densa (Grass*) si stancile nu")
	# Chunk de MultiMesh scris de mana: in headless pozitiile citite sunt zero.
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Bush_A_0_-"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = BoxMesh.new()
	mm.instance_count = 6
	for i in 6:
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(100 + i * 3, 0, 0)))
	mmi.multimesh = mm
	var root2 := Node3D.new()
	add_child(root2)
	root2.add_child(mmi)
	var found := SoftVeg.scan(root2)
	var headless := DisplayServer.get_name() == "headless"
	print("  scan pe un chunk de 6 tufe: %d (headless=%s)" % [found, headless])
	_check(found == (0 if headless else 6),
		"scan: %s" % ("headless citeste zero -> chunk sarit, registru gol" if headless else "6 tufe citite"))
	root.queue_free()
	root2.queue_free()


func _drive(with_bushes: bool, drag: float, speed: float) -> Dictionary:
	var root := Node3D.new()
	add_child(root)
	var car := Car.new()
	add_child(car)
	car.global_position = Vector3(-200, 0.7, 0)
	car.rotation.y = -PI * 0.5
	car.race_active = true
	car.soft_veg_root = root
	car.bush_drag = drag
	if with_bushes:
		for i in 12:
			SoftVeg.add_bush(root, Vector3(-170 + i * 3.0, 0, (i % 3 - 1) * 0.3), 1.2, 1.4)
	for _f in int(0.8 / STEP):
		await get_tree().physics_frame
	car.linear_velocity = Vector3.ZERO
	var m: Variant = PropDebris.instance()
	var before := int(m.leaf_bursts) if m != null else 0
	car.linear_velocity = Vector3(speed, 0, 0)
	for _f in int(2.5 / STEP):
		await get_tree().physics_frame
		# Tinem viteza de croaziera pana la tufe: fara motor, drag-ul rularii
		# ar amesteca cele doua alergari.
		if car.global_position.x < -172.0:
			car.linear_velocity.x = speed
	var m2: Variant = PropDebris.instance()
	var out := {
		"v_end": car.linear_velocity.x, "lat": absf(car.linear_velocity.z),
		"x_end": car.global_position.x,
		"leaves": (int(m2.leaf_bursts) if m2 != null else 0) - before}
	car.queue_free()
	root.queue_free()
	await get_tree().physics_frame
	return out


func _test_drive() -> void:
	print("")
	print("-- 2+3. strabaterea unui rand de 12 tufe --")
	var control := await _drive(false, 6.0, 20.0)
	var bush := await _drive(true, 6.0, 20.0)
	var no_drag := await _drive(true, 0.0, 20.0)
	var slow := await _drive(true, 6.0, 4.0)
	print("  fara tufe: v %.2f, x %.1f; cu tufe: v %.2f, x %.1f, lat %.2f, frunze %d" % [
		control.v_end, control.x_end, bush.v_end, bush.x_end, bush.lat, bush.leaves])
	print("  drag 0: v %.2f, frunze %d; la 4 m/s: v %.2f, frunze %d" % [
		no_drag.v_end, no_drag.leaves, slow.v_end, slow.leaves])
	var loss: float = control.v_end - bush.v_end
	print("  pierdere de viteza in tufe: %.2f m/s" % loss)
	_check(bush.leaves >= 3, "frunze la tufele trecute (>= 3 rafale)")
	_check(loss > 0.5 and loss < 8.0, "franare usoara: pierde %.2f m/s (0.5..8)" % loss)
	_check(bush.lat < 1.0, "nu e deviata lateral (%.2f m/s)" % bush.lat)
	_check(absf(control.v_end - no_drag.v_end) < 0.4, "cu bush_drag = 0 nu se pierde viteza")
	_check(no_drag.leaves >= 3, "...dar frunzele sar si fara drag")
	_check(slow.leaves == 0, "sub 6 m/s nu sar frunze")
