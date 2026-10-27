extends Node
## Aschii si praf la decorul lovit + butoiul knockable (feel_checklist:
## things-fly).
##
## Verifica, pe corpuri reale:
##   1. `Barrel` (butoiul de mana, inainte StaticBody) devine un BumpProp in
##      joc: masa in limitele BumpProp, doarme, e IMPRASTIAT de o masina la
##      15 m/s (se muta > 2 m) fara sa o opreasca (masina pastreaza > 60% din
##      viteza), si nu mai are colizor static propriu;
##   2. o piesa lovita aprinde o rafala (`PropDebris.bursts` creste), una
##      care doarme sau e atinsa sub prag nu;
##   3. rafala creste cu viteza: densitatea aschiilor si forta masurata mai
##      mari la 18 m/s decat la 6 m/s;
##   4. plafonul: o izbitura in gramada de 48 de piese nu pornestemai mult de
##      o rafala pe cadru si cel mult cateva zeci, iar numarul total de
##      particule din lume ramane cel fix al managerului (SLOTS x 10), cu zero
##      noduri de particule pe piese;
##   5. un RoadMarker lovit scoate si el aschii.
## Un emitator care porneste nu dovedeste ca se vede ceva: vezi captura din
## raport (tools/CaptureFeelVfx.tscn, stagiul `props`).
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbePropDebris.tscn

const STEP: float = 1.0 / 60.0
const PropDebris := preload("res://scenes/props/prop_debris.gd")

var _failed: bool = false


func _ready() -> void:
	add_child(_ground())
	await get_tree().physics_frame
	print("")
	print("=== Aschii la decorul lovit ===")
	await _test_barrel()
	await _test_scaling()
	await _test_pile_cap()
	await _test_marker()
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _ground() -> StaticBody3D:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1200, 1, 1200)
	cs.shape = sh
	b.add_child(cs)
	b.position = Vector3(0, -0.5, 0)
	return b


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _spawn_car(pos: Vector3) -> Car:
	var car := Car.new()
	add_child(car)
	car.global_position = pos
	car.rotation.y = -PI * 0.5 # botul spre +X
	car.race_active = true
	return car


func _settle(car: Car) -> void:
	for _f in int(0.8 / STEP):
		await get_tree().physics_frame
	car.linear_velocity = Vector3.ZERO
	car.angular_velocity = Vector3.ZERO


func _bursts() -> int:
	var m: Variant = PropDebris.instance()
	return int(m.bursts) if m != null else 0


## Butoi de mana, ca sub ManualDecor. Intoarce nodul Barrel.
func _barrel(pos: Vector3) -> Barrel:
	var holder := Node3D.new()
	add_child(holder)
	var b := Barrel.new()
	holder.add_child(b)
	b.global_position = pos
	return b


func _bump_of(b: Barrel) -> BumpProp:
	for c in b.get_children():
		if c is BumpProp:
			return c
	return null


func _test_barrel() -> void:
	print("")
	print("-- 1. butoiul de mana devine knockable --")
	var car := _spawn_car(Vector3(-300, 0.7, 0))
	var barrel := _barrel(Vector3(-292, 0, 0))
	await _settle(car)
	var bump := _bump_of(barrel)
	_check(bump != null, "Barrel are un BumpProp copil (nu mai e perete)")
	if bump == null:
		return
	var statics := 0
	for c in barrel.get_children():
		if c is CollisionShape3D:
			statics += 1
	print("  masa %.2f kg, colizoare statice pe Barrel: %d, doarme: %s" % [bump.mass, statics, bump.sleeping])
	_check(bump.mass >= BumpProp.MIN_MASS and bump.mass <= BumpProp.MAX_MASS, "masa in limitele BumpProp")
	_check(statics == 0, "fara colizor static pe Barrel")
	_check(bump.sleeping, "doarme pana il atinge cineva")
	var start := bump.global_position
	var before := _bursts()
	for _f in 60:
		await get_tree().physics_frame
	_check(_bursts() == before, "adormit, nu scoate aschii")
	car.linear_velocity = Vector3(15, 0, 0)
	var v_after := -1.0
	var hit_f := -1
	for f in int(2.0 / STEP):
		await get_tree().physics_frame
		if hit_f < 0 and bump.global_position.distance_to(start) > 0.3:
			hit_f = f
		if hit_f >= 0 and f == hit_f + 15:
			v_after = car.horizontal_speed()
	var moved := bump.global_position.distance_to(start)
	print("  butoiul s-a mutat %.1f m; masina a pastrat %.1f din 15 m/s; rafale +%d" % [moved, v_after, _bursts() - before])
	_check(moved > 2.0, "butoiul e imprastiat (> 2 m)")
	_check(v_after > 9.0, "masina nu e oprita (> 60% din viteza)")
	_check(_bursts() > before, "izbitura a scos aschii")
	car.queue_free()
	barrel.get_parent().queue_free()
	await get_tree().physics_frame


func _lone_prop(pos: Vector3) -> BumpProp:
	var holder := Node3D.new()
	add_child(holder)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.9, 0.6)
	mi.mesh = box
	holder.add_child(mi)
	mi.position = Vector3(0, 0.45, 0)
	holder.global_position = pos
	return BumpProp.wrap(mi)


func _ram(x0: float, speed: float) -> Dictionary:
	var car := _spawn_car(Vector3(x0, 0.7, 100))
	var prop := _lone_prop(Vector3(x0 + 9.0, 0, 100))
	await _settle(car)
	await get_tree().physics_frame
	var m: Variant = PropDebris.instance()
	var before := int(m.bursts)
	var strongest := 0.0
	var dens := 0.0
	var seen := before
	car.linear_velocity = Vector3(speed, 0, 0)
	for _f in int(1.5 / STEP):
		await get_tree().physics_frame
		if int(m.bursts) > seen:
			seen = int(m.bursts)
			if float(m.last_strength) > strongest:
				strongest = float(m.last_strength)
				dens = float(m.last_density)
	var out := {"bursts": int(m.bursts) - before, "strength": strongest, "density": dens}
	car.queue_free()
	prop.get_parent().queue_free()
	await get_tree().physics_frame
	return out


func _test_scaling() -> void:
	print("")
	print("-- 2+3. rafala creste cu viteza; sub prag nu --")
	var slow := await _ram(-500.0, 3.0)
	var mid := await _ram(-400.0, 7.0)
	var fast := await _ram(-300.0, 18.0)
	print("  3 m/s: rafale %d forta %.1f; 7 m/s: %d / %.1f; 18 m/s: %d / %.1f" % [
		slow.bursts, slow.strength, mid.bursts, mid.strength, fast.bursts, fast.strength])
	print("  densitate aschii dupa fiecare: %.2f / %.2f / %.2f" % [slow.density, mid.density, fast.density])
	_check(fast.bursts >= 1 and mid.bursts >= 1, "lovitura la 7 si 18 m/s scoate aschii")
	_check(fast.strength > mid.strength + 1.0, "forta masurata creste cu viteza (%.1f > %.1f)" % [fast.strength, mid.strength])
	_check(fast.density > mid.density, "mai multe aschii la 18 m/s decat la 7 (%.2f > %.2f)" % [fast.density, mid.density])


func _test_pile_cap() -> void:
	print("")
	print("-- 4. gramada de 48 de piese: plafon --")
	var car := _spawn_car(Vector3(-300, 0.7, -200))
	var props: Array[BumpProp] = []
	for i in 48:
		var p := _lone_prop(Vector3(-292 + (i % 6) * 0.9, 0, -200 + (i / 6 - 3.5) * 0.9))
		if p != null:
			props.append(p)
	await _settle(car)
	var m: Variant = PropDebris.instance()
	var before := int(m.bursts)
	car.linear_velocity = Vector3(20, 0, 0)
	var frames := 0
	var max_per_frame := 0
	var last := before
	for _f in int(1.2 / STEP):
		await get_tree().physics_frame
		frames += 1
		max_per_frame = maxi(max_per_frame, int(m.bursts) - last)
		last = int(m.bursts)
	var total := int(m.bursts) - before
	var particles := 0
	for c in m.get_children():
		particles += (c as CPUParticles3D).amount
	var on_props := 0
	for p in props:
		if is_instance_valid(p):
			for c in p.get_children():
				if c is CPUParticles3D:
					on_props += 1
	print("  %d piese, %d rafale in 1.2 s (max %d pe cadru), %d particule in manager, %d emitatoare pe piese" % [
		props.size(), total, max_per_frame, particles, on_props])
	_check(props.size() >= 40, "(control) gramada exista (%d piese)" % props.size())
	_check(total >= 1, "izbitura in gramada scoate aschii")
	_check(max_per_frame <= 1, "cel mult o rafala pe cadru")
	_check(total <= int(1.2 / PropDebris.COOLDOWN_S) + 1, "rata limitata de pauza globala (<= %d)" % (int(1.2 / PropDebris.COOLDOWN_S) + 1))
	var fixed := PropDebris.SLOTS * (PropDebris.CHUNKS + PropDebris.PUFFS) + PropDebris.LEAF_SLOTS * PropDebris.LEAVES
	_check(particles == fixed, "particulele totale raman cele fixe ale managerului (%d = %d)" % [particles, fixed])
	_check(on_props == 0, "zero noduri de particule pe piese")
	car.queue_free()


func _test_marker() -> void:
	print("")
	print("-- 5. RoadMarker lovit --")
	var car := _spawn_car(Vector3(-300, 0.7, 300))
	var holder := Node3D.new()
	add_child(holder)
	var marker := RoadMarker.new()
	holder.add_child(marker)
	marker.global_position = Vector3(-291, 0.0, 300)
	await _settle(car)
	var m: Variant = PropDebris.instance()
	var before := int(m.bursts)
	car.linear_velocity = Vector3(18, 0, 0)
	for _f in int(1.5 / STEP):
		await get_tree().physics_frame
	print("  rafale dupa lovitura stalpului: +%d" % (int(m.bursts) - before))
	_check(int(m.bursts) > before, "stalpul de marcaj lovit scoate aschii")
	car.queue_free()
