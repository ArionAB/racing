extends Node
## Cuburi de marmura in lumina REALA a temei carrara pe Track23, ca sa se masoare fata la soare si
## fata in umbra (H/S/V) fara sa existe inca decor: asa s-au calibrat ambientul si tenta clasei
## `carrara_marble` (commit "umbra gri-albastrui"). Ruleaza CU FEREASTRA. Scoate CameraZone-urile
## tunelurilor inainte de a suprascrie ambientul (ele rescriu ambientul in fiecare cadru).
##
##   godot --path . res://tools/ProbeCarraraSwatch.tscn -- --out=<png> [--amb=RRGGBB] [--amb-e=0.38]
##        [--tints=r,g,b;r,g,b;...] [--sun-e=1.25] [--sun-c=RRGGBB]
##
## Cate un cub pentru fiecare tenta (implicit: tenta clasei carrara_marble din palette). Fata de
## SUD (lume +Z) e la soare, fata de VEST (-X) in umbra (soarele din SE). Camera: SV -> NE.

var _out := ""
var _tints: Array = []

func _ready() -> void:
	var amb := ""
	var amb_e := -1.0
	var sun_e := -1.0
	var sun_c := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.trim_prefix("--out=")
		elif a.begins_with("--amb="):
			amb = a.trim_prefix("--amb=")
		elif a.begins_with("--amb-e="):
			amb_e = float(a.trim_prefix("--amb-e="))
		elif a.begins_with("--sun-e="):
			sun_e = float(a.trim_prefix("--sun-e="))
		elif a.begins_with("--sun-c="):
			sun_c = a.trim_prefix("--sun-c=")
		elif a.begins_with("--tints="):
			for t in a.trim_prefix("--tints=").split(";"):
				var p := t.split(",")
				_tints.append(Color(float(p[0]), float(p[1]), float(p[2])))
	if _tints.is_empty():
		_tints.append(Palette.CLASS_TINT["carrara_marble"])
	var scene := load("res://scenes/tracks/Track23.tscn") as PackedScene
	var track := scene.instantiate() as Track
	add_child(track)
	for i in 12:
		await get_tree().process_frame
	# CameraZone-urile tunelurilor rescriu ambientul in fiecare cadru (base cache) -> le scoatem.
	for cz in track.find_children("*", "CameraZone", true, false):
		cz.queue_free()
	await get_tree().process_frame
	# Mediul: suprascrieri A/B fara sa se editeze tema.
	for we in track.find_children("*", "WorldEnvironment", true, false):
		var env := (we as WorldEnvironment).environment
		if "--exp" in OS.get_cmdline_user_args():
			env.tonemap_exposure = 3.0
			print("expunere 3.0 pusa")
		if amb != "":
			env.ambient_light_color = Color.html(amb)
		if amb_e >= 0.0:
			env.ambient_light_energy = amb_e
		print("ambient[%s]: %s x %.3f  fog=%s src=%d" % [we.get_path(), env.ambient_light_color.to_html(), env.ambient_light_energy, env.fog_enabled, env.ambient_light_source])
	for ln in track.find_children("*", "Light3D", true, false):
		var lt := ln as Light3D
		print("LUMINA %s tip=%s col=%s e=%.2f rot=%s" % [lt.get_path(), lt.get_class(), lt.light_color.to_html(), lt.light_energy, (lt as Node3D).rotation_degrees])
	for dl in track.find_children("*", "DirectionalLight3D", true, false):
		var l := dl as DirectionalLight3D
		if sun_e >= 0.0:
			l.light_energy = sun_e
		if sun_c != "":
			l.light_color = Color.html(sun_c)
		print("soare: %s x %.3f  rot=%s" % [l.light_color.to_html(), l.light_energy, l.rotation_degrees])
	var base := Palette.triplanar_class_material("carrara_marble")
	# Cuburi pe bancul de la nord de A (cota ~24.7), in linie pe X, la 14 m unul de altul.
	var ox := -90.0
	var oz := -128.0
	var gy := track._sampler.ground_y(ox, oz)
	print("sol la cuburi: %.2f" % gy)
	for i in _tints.size():
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(8, 8, 8)
		mi.mesh = bm
		var m := base.duplicate() as StandardMaterial3D
		m.albedo_color = _tints[i]
		mi.material_override = m
		mi.position = Vector3(ox + 14.0 * i, gy + 4.0, oz)
		track.add_child(mi)
	var cam := Camera3D.new()
	cam.fov = 68.0
	cam.current = true
	track.add_child(cam)
	var cx := ox + 14.0 * (_tints.size() - 1) * 0.5
	cam.position = Vector3(cx - 26.0, gy + 10.0, oz + 30.0)
	cam.look_at(Vector3(cx, gy + 3.0, oz))
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(_out)
	# Mostre: centrul fetei de SUD (z = oz+4) si al fetei de VEST (x = ox-4 + 14 i) ale fiecarui cub,
	# proiectate pe ecran; 7x7 pixeli. Plus o bucata de sol plat in fata.
	for i in _tints.size():
		var cxw := ox + 14.0 * i
		for face in [["S(soare)", Vector3(cxw, gy + 4.0, oz + 4.0)], ["V(umbra)", Vector3(cxw - 4.0, gy + 4.0, oz)],
				["sus", Vector3(cxw, gy + 8.0, oz)]]:
			var sp := cam.unproject_position(face[1])
			print("  cub %d tenta=(%.2f,%.2f,%.2f) %-9s %s" % [i, _tints[i].r, _tints[i].g, _tints[i].b,
				face[0], _stats(img, sp)])
	var gp := cam.unproject_position(Vector3(cx - 8.0, gy, oz + 12.0))
	print("  sol plat (aproape) %s" % _stats(img, gp))
	get_tree().quit()


func _stats(img: Image, sp: Vector2) -> String:
	var x0 := int(sp.x) - 3
	var y0 := int(sp.y) - 3
	var sr := 0.0
	var sg := 0.0
	var sb := 0.0
	var n := 0
	for y in range(y0, y0 + 7):
		for x in range(x0, x0 + 7):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var c := img.get_pixel(x, y)
			sr += c.r
			sg += c.g
			sb += c.b
			n += 1
	if n == 0:
		return "(in afara cadrului %s)" % sp
	var c := Color(sr / n, sg / n, sb / n)
	return "RGB(%3d,%3d,%3d) H=%5.1f S=%.3f V=%.3f" % [c.r8, c.g8, c.b8, c.h * 360.0, c.s, c.v]
