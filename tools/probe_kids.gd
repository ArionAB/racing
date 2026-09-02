extends Node
## Materialul REAL al carosabilului. Capcana care m-a costat trei masuratori:
## `RoadTop` e StaticBody3D, iar MeshInstance-ul lui e FRATE, nu copil — deci
## un filtru pe numele parintelui il rateaza, si vezi doar terenul.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 8: await get_tree().process_frame
	var kids := t.get_children()
	for i in kids.size():
		var c = kids[i]
		if not (c is MeshInstance3D):
			continue
		var mi := c as MeshInstance3D
		var vecin := "" if i == 0 else str(kids[i - 1].name)
		var ov = mi.material_override
		var s := "%s (dupa %s): " % [mi.name, vecin]
		if ov is ShaderMaterial:
			s += "Shader %s" % (ov as ShaderMaterial).shader.resource_path
		elif ov is StandardMaterial3D:
			var sm := ov as StandardMaterial3D
			s += "Standard filter=%d (3=linear+mip, 5=ANIZOTROP) albedo=%s tex=%s" % [
				sm.texture_filter, sm.albedo_color.to_html(false),
				sm.albedo_texture.resource_path if sm.albedo_texture else "-"]
		else:
			s += "override=null"
		print("  ", s)
	get_tree().quit(0)
