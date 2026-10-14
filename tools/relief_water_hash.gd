extends Node
## Amprenta MATERIALULUI apei al unei piste: dovada ca stilul de apa optional
## (`custom_water_styles`) nu schimba nicio alta pista. Intoarce MD5 peste toti
## uniformii shaderului din `_water_material()`, in ordine alfabetica.
##
##   godot --headless --path . res://tools/ReliefWaterHash.tscn -- --track=16
##
## Se ruleaza pe codul de baza si pe cel nou si se compara cu `diff`; pentru
## geometrie (celulele de apa) exista `ProbeTrackHash.tscn`.


func _ready() -> void:
	var track_arg := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			track_arg = int(arg.trim_prefix("--track="))
	var idx := GameState.resolve_track_index(track_arg)
	var path: String = GameState.TRACK_SCENES[idx]
	var track := (load(path) as PackedScene).instantiate() as Track
	add_child(track)
	var mat: ShaderMaterial = track.call("_water_material")
	var names: Array[String] = []
	for u in mat.shader.get_shader_uniform_list():
		names.append(String(u["name"]))
	names.sort()
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	for n in names:
		var v: Variant = mat.get_shader_parameter(n)
		# Texturile s-ar tipari cu id-ul de instanta (diferit la fiecare rulare).
		var txt := (v as Resource).resource_path if v is Resource else str(v)
		ctx.update(("%s=%s;" % [n, txt]).to_utf8_buffer())
	print("WATERHASH %s %d uniformi %s" % [path.get_file(), names.size(), ctx.finish().hex_encode()])
	get_tree().quit(0)
