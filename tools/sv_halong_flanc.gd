## Unde e FLANCUL turnului `TurnGrota`? Adica: la ce raza din centrul lui
## terenul coboara spre cota drumului, ca portalul sa fie taiat IN perete si
## nu ingropat in dom sau lasat pe camp.
extends Node


func _ready() -> void:
	var scene := load("res://scenes/tracks/Track22.tscn") as PackedScene
	var track := scene.instantiate()
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var sampler = track.get("_sampler")
	# centrul turnului, din marker
	var mk := track.get_node_or_null("Peaks/TurnGrota") as Node3D
	if mk == null:
		print("!! fara Peaks/TurnGrota"); get_tree().quit(1); return
	var c: Vector3 = mk.position
	print("centru TurnGrota: (%.1f, %.1f)" % [c.x, c.z])
	# directia spre drum: o luam din pozitia actuala a portalului
	var dec := track.get_node_or_null("DecorManual")
	var portal: Node3D = null
	for ch in dec.get_children():
		if String(ch.name) == "GuraGrota":
			portal = ch as Node3D
			break
	if portal == null:
		print("!! fara GuraGrota"); get_tree().quit(1); return
	var v := Vector2(portal.position.x - c.x, portal.position.z - c.z)
	if v.length() < 0.01:
		v = Vector2(1, 0)
	v = v.normalized()
	print("directie turn -> drum: (%.2f, %.2f)" % [v.x, v.y])
	print("")
	print("%6s %9s  %s" % ["raza", "teren", "profil"])
	for i in 22:
		var r := 4.0 + i * 4.0
		var px := c.x + v.x * r
		var pz := c.z + v.y * r
		var gy: float = sampler.ground_y(px, pz)
		var bar := ""
		var n := int(maxf(0.0, gy) / 2.0)
		for j in mini(n, 40):
			bar += "#"
		print("%6.1f %+9.2f  %s" % [r, gy, bar])
	get_tree().quit(0)
