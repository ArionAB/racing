extends Node
## Sonda masinii de fir (kit Carrara §1.2, grupa crr-d): volantul `Blades` din
## `carrara/vehicles/wire_saw.glb` se roteste cu windmill.gd in jurul BUTUCULUI,
## pe axa X, cand piesa sta ca decor manual (sub un WorldProp, ca DecorManual
## din Track23).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeWireSaw.tscn
##
## Calea verificata (fara nicio schimbare in world_prop.gd):
##   * instanta GLB-ului primeste in scena `script = windmill.gd` si
##     `axis = Vector3(1, 0, 0)`; windmill.gd cauta copilul `Blades` dupa nume
##     si il roteste pe axa lui LOCALA (Node3D.rotate in spatiul parintelui;
##     `Blades` are rotatia identitate, deci axa locala = X-ul modelului);
##   * parintele e un WorldProp: `prop_classes()` (care aduna si clasele din
##     `Track._LANDMARKS`) pune pe `Blades` clasa `rust_metal` PE UV, la fel ca
##     la moara. De aceea volantul are UV-uri reale (cube_uvs), nu triplanar.
##
## Ce masoara, dupa 20 de cadre la 30 rpm (60 de grade):
##   1. volantul s-a rotit (unghiul din baza);
##   2. pivotul n-a plecat (originea e in butuc: pozitia globala a lui `Blades`
##      e fixa) si coincide cu centrul geometric al jantei in planul YZ (+-2 cm);
##   3. axa de rotatie e X: coloana X a bazei ramane (1,0,0), iar cutia
##      volantului in lume ramane aceeasi (roata simetrica in planul YZ);
##   4. SABOTAJ: aceeasi piesa cu axa implicita a morii (0,0,1) -- volantul se
##      da peste cap, cutia lui pe X creste de la ~0,4 la ~1,6 m. Sonda trebuie
##      sa PICE pe configuratia asta, altfel nu masoara nimic.
##   5. ce material primeste `Blades` sub WorldProp, si ca WorldProp face corpul
##      de coliziune.

const MODEL := "res://assets/models/carrara/vehicles/wire_saw.glb"
const MILL := "res://scenes/props/windmill.gd"
const PROP := "res://scenes/props/world_prop.gd"
const FRAMES := 20
const RPM := 30.0


func _ready() -> void:
	await get_tree().process_frame
	print("")
	print("=== Sonda masina de fir (Blades / windmill.gd) ===")
	var good := await _run(Vector3(1, 0, 0), "axa X (contractul)")
	var sab := await _run(Vector3(0, 0, 1), "axa Z (implicitul morii, SABOTAJ)")
	print("")
	var ok: bool = good["ok"] and not sab["ok"]
	print("configuratia corecta: %s; sabotajul: %s" % [
		"OK" if good["ok"] else "PICA",
		"PICA, cum trebuie" if not sab["ok"] else "TRECE (sonda nu masoara!)"])
	print("VERDICT: ", "OK" if ok else "PROBLEME")
	get_tree().quit(0 if ok else 1)


func _run(axis: Vector3, label: String) -> Dictionary:
	print("\n-- %s --" % label)
	var root := Node3D.new()
	root.set_script(load(PROP))
	root.name = "DecorManual"
	var inst := (load(MODEL) as PackedScene).instantiate() as Node3D
	inst.set_script(load(MILL))
	inst.set("axis", axis)
	inst.set("rpm", RPM)
	inst.name = "MasinaDeFir"
	root.add_child(inst)
	add_child(root)
	await get_tree().process_frame
	var blades := inst.find_child("Blades", true, false) as Node3D
	if blades == null:
		print("  !! nu exista nodul Blades")
		root.queue_free()
		return {"ok": false}
	var mi := blades as MeshInstance3D
	if mi == null:
		for c in blades.get_children():
			if c is MeshInstance3D:
				mi = c
	var p0 := blades.global_position
	var b0 := blades.global_basis
	var box0 := _world_box(mi)
	for i in FRAMES:
		await get_tree().process_frame
	var p1 := blades.global_position
	var b1 := blades.global_basis
	var box1 := _world_box(mi)
	var ang := rad_to_deg(b0.y.angle_to(b1.y))
	var moved := p1.distance_to(p0)
	# Centrul jantei se compara in PLANUL ROTII (YZ): pe X capacul butucului sta
	# doar pe fata +X, deci centrul cutiei e decalat 2,5 cm fara ca pivotul sa fie.
	var center := box1.get_center()
	var off_yz := Vector2(center.y - p1.y, center.z - p1.z).length()
	var xaxis := b1.x.normalized()
	var dsize := (box1.size - box0.size).abs()
	print("  pivot      (%.3f, %.3f, %.3f), deplasare dupa %d cadre: %.5f m"
			% [p0.x, p0.y, p0.z, FRAMES, moved])
	print("  rotatie    %.1f grade (cerut ~%.0f)" % [ang, RPM * 6.0 * FRAMES / 60.0])
	print("  axa X dupa (%.3f, %.3f, %.3f)" % [xaxis.x, xaxis.y, xaxis.z])
	print("  cutia lume inainte %s, dupa %s" % [_v(box0.size), _v(box1.size)])
	print("  centrul jantei fata de pivot, in planul YZ: %.3f m" % off_yz)
	var checks := {
		"s-a rotit": ang > 10.0,
		"pivotul fix": moved < 1e-4,
		"pivot = centrul jantei (YZ)": off_yz < 0.02,
		"axa ramane X": xaxis.distance_to(Vector3(1, 0, 0)) < 1e-3,
		"cutia volantului neschimbata": dsize.x < 0.03 and dsize.y < 0.03 and dsize.z < 0.03,
	}
	var ok := true
	for k: String in checks:
		print("  %-30s %s" % [k, "OK" if checks[k] else "PICA"])
		ok = ok and bool(checks[k])
	var mat := mi.material_override
	var is_world := mat == Palette.world_material()
	print("  material Blades: %s (%s)" % [
		mat.resource_name if mat and mat.resource_name != "" else str(mat),
		"atlasul lumii" if is_world else "clasa pe UV (prop_classes: Blades -> rust_metal)"])
	var bodies := 0
	for c in root.get_children():
		if c is StaticBody3D:
			bodies += 1
	print("  corpuri de coliziune facute de WorldProp: %d" % bodies)
	root.queue_free()
	await get_tree().process_frame
	return {"ok": ok}


func _world_box(mi: MeshInstance3D) -> AABB:
	var xf := mi.global_transform
	var faces := mi.mesh.get_faces()
	var box := AABB(xf * faces[0], Vector3.ZERO)
	for p in faces:
		box = box.expand(xf * p)
	return box


func _v(v: Vector3) -> String:
	return "(%.3f, %.3f, %.3f)" % [v.x, v.y, v.z]
