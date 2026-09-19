extends Node
## Sonda de CADRU pentru POI H: ce piesa umple obiectivul la o fractie data.
##
## Captura H_r4_f097 arata o lespede de piatra care ocupa jumatatea de jos a
## ecranului. `probe_manual` nu o poate gasi: el masoara plutirea si distanta la
## AX, iar piesa asta e la distanta corecta — problema e UNGHIUL fata de directia
## in care priveste camera (memoria masoara-inainte-nu-langa).
##
## Deci sonda reproduce camera de joc la fractia ceruta si raporteaza, pentru
## fiecare piesa din ZoneH, cat de aproape de centrul cadrului cade si cat de
## mare e unghiular — adica exact ce se vede, nu unde e.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeMpHCadru.tscn -- \
##       --frac=0.97

const TRACK := "res://scenes/tracks/Track15.tscn"
const ZONE := "DecorManual/ZoneH_Cornisa"
## Inaltimea ochiului peste sosea si cat de departe priveste, ca la ChaseCamera.
const EYE_H := 2.2
const LOOK_AHEAD := 14.0

var _frac := 0.97


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frac="):
			_frac = float(a.trim_prefix("--frac="))
	await get_tree().process_frame
	var track := (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var n := track.baked.size()
	var i := int(_frac * float(n)) % n
	var p: Vector3 = track.baked[i]
	# Camera: in spatele masinii, privind spre punctul din fata.
	var j := (i + int(round(LOOK_AHEAD / 1.8))) % n
	var tgt: Vector3 = track.baked[j]
	var eye := p + Vector3(0.0, EYE_H, 0.0)
	var fwd := (Vector3(tgt.x, tgt.y + 1.0, tgt.z) - eye).normalized()
	print("; frac %.4f: ochi (%.1f, %.1f, %.1f), priveste spre (%.2f, %.2f, %.2f)" % [
		_frac, eye.x, eye.y, eye.z, fwd.x, fwd.y, fwd.z])

	var zone := track.get_node_or_null(ZONE)
	if zone == null:
		print("; zona lipseste")
		get_tree().quit(1)
		return
	# Pentru fiecare piesa: unghiul fata de axa camerei si marimea unghiulara.
	var rows: Array = []
	for c in zone.get_children():
		var n3 := c as Node3D
		if n3 == null:
			continue
		var aabb := _world_aabb(n3)
		if aabb.size == Vector3.ZERO:
			continue
		var ctr := aabb.get_center()
		var v := ctr - eye
		var dist := v.length()
		if dist < 0.01 or dist > 60.0:
			continue
		var ang := rad_to_deg(fwd.angle_to(v.normalized()))
		# marimea unghiulara: raza sferei care cuprinde AABB-ul, vazuta de la eye
		var r := aabb.size.length() * 0.5
		var sz := rad_to_deg(atan2(r, dist))
		# „umple cadrul" = e aproape de axa si e mare unghiular
		rows.append([ang, sz, dist, str(n3.name), ctr])
	rows.sort_custom(func(a, b): return (a[1] - a[0]) > (b[1] - b[0]))
	print("; piesele care ocupa cel mai mult din centrul cadrului (sz-ang mare = in fata si mare):")
	print("; unghi_ax  marime  dist   nume                       centru")
	for k in mini(14, rows.size()):
		var r: Array = rows[k]
		print("; %7.1f  %6.1f  %5.1f   %-24s  (%.1f, %.1f, %.1f)" % [
			r[0], r[1], r[2], r[3], r[4].x, r[4].y, r[4].z])
	get_tree().quit(0)


func _world_aabb(node: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for m in _meshes(node):
		var a: AABB = m.global_transform * m.get_aabb()
		if first:
			out = a
			first = false
		else:
			out = out.merge(a)
	return out


func _meshes(node: Node) -> Array:
	var r: Array = []
	if node is VisualInstance3D:
		r.append(node)
	for c in node.get_children():
		r.append_array(_meshes(c))
	return r
