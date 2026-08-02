extends Node
## Amprenta temei fiecarei piste, ca text stabil — mediu, cer, ceata, soare si
## un recensamant de noduri. Se compara cu `diff`, nu cu ochiul.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeTheme.tscn \
##       > /tmp/dupa.txt
##   diff /tmp/inainte.txt /tmp/dupa.txt
##
## Trebuie rulata ca SCENA, nu cu --script: are nevoie de autoload-uri
## (GameState). Acelasi motiv ca la ProbeRace.tscn.
##
## De ce exista: [code]tools/probe_decor.gd[/code] numara mesh-uri, materiale si
## triunghiuri, deci prinde regresii de GEOMETRIE — dar e complet orb la culoarea
## cerului, la modul de ceata, la ambient si la expunere. Cand tema a devenit
## dictionar de date (Track.themes()) si cele noua intrebari `== "desert"` s-au
## transformat in flag-uri, exact partea aia era in joc: un `if` tradus gresit
## n-ar fi schimbat niciun triunghi, dar ar fi facut o pista sa arate altfel.
##
## Amprenta include si recensamantul de noduri per tip, fiindca acolo se vede
## "peretii au disparut" sau "hazardul tematic s-a schimbat" — lucruri care nu
## trec prin culori.

func _ready() -> void:
	# Un cadru inainte de orice add_child: root e ocupat cu propriul _ready.
	await get_tree().process_frame
	for i in GameState.TRACK_SCENES.size():
		var scene := load(GameState.TRACK_SCENES[i]) as PackedScene
		var track := scene.instantiate() as Track
		get_tree().root.add_child(track)
		# Doua cadre: rebuild() ruleaza in _ready, iar copiii intra in arbore dupa.
		await get_tree().process_frame
		await get_tree().process_frame
		_dump(i, track)
		track.queue_free()
		await get_tree().process_frame
	get_tree().quit()


func _dump(idx: int, track: Track) -> void:
	print("=== Track%02d  %s  tema=%s ===" % [idx + 1, track.track_name,
		track.theme_decor])
	print("  ground_tint  %s" % track.theme_ground_tint.to_html(false))
	print("  sky_top      %s" % track.theme_sky_top.to_html(false))
	print("  sky_horizon  %s" % track.theme_sky_horizon.to_html(false))
	print("  fog          %s" % track.theme_fog.to_html(false))
	print("  hill_color   %s" % track.theme_hill_color.to_html(false))
	print("  sun_color    %s" % track.theme_sun_color.to_html(false))
	print("  sun_energy   %.4f" % track.theme_sun_energy)
	print("  exposure     %.4f" % track.theme_exposure)
	print("  shadows      %s" % track.theme_shadows)
	var env: Environment = null
	var sun: DirectionalLight3D = null
	for c in track.get_children():
		if c is WorldEnvironment:
			env = (c as WorldEnvironment).environment
		elif c is DirectionalLight3D:
			sun = c as DirectionalLight3D
	if env != null:
		print("  env.ambient_source   %d" % env.ambient_light_source)
		print("  env.ambient_color    %s" % env.ambient_light_color.to_html(false))
		print("  env.ambient_energy   %.4f" % env.ambient_light_energy)
		print("  env.ambient_sky      %.4f" % env.ambient_light_sky_contribution)
		print("  env.fog_enabled      %s" % env.fog_enabled)
		print("  env.fog_mode         %d" % env.fog_mode)
		print("  env.fog_light_color  %s" % env.fog_light_color.to_html(false))
		print("  env.fog_density      %.6f" % env.fog_density)
		print("  env.fog_depth        %.2f -> %.2f  curve %.2f"
			% [env.fog_depth_begin, env.fog_depth_end, env.fog_depth_curve])
		print("  env.tonemap          %d  exposure %.4f"
			% [env.tonemap_mode, env.tonemap_exposure])
		print("  env.adjust           sat %.3f  contrast %.3f"
			% [env.adjustment_saturation, env.adjustment_contrast])
		var sky_mat := env.sky.sky_material as ProceduralSkyMaterial
		if sky_mat != null:
			print("  sky.top              %s" % sky_mat.sky_top_color.to_html(false))
			print("  sky.horizon          %s" % sky_mat.sky_horizon_color.to_html(false))
			print("  sky.ground_bottom    %s"
				% sky_mat.ground_bottom_color.to_html(false))
	if sun != null:
		print("  sun.rotation         %s" % str(sun.rotation_degrees.round()))
		print("  sun.color            %s" % sun.light_color.to_html(false))
		print("  sun.energy           %.4f" % sun.light_energy)
		print("  sun.shadow           %s  max_dist %.1f"
			% [sun.shadow_enabled, sun.directional_shadow_max_distance])
	# Numaratori de noduri per tip: prind "peretii au disparut" fara pixeli.
	var counts := {}
	_count(track, counts)
	var keys := counts.keys()
	keys.sort()
	var parts: Array[String] = []
	for k in keys:
		parts.append("%s=%d" % [k, counts[k]])
	print("  noduri  %s" % ", ".join(parts))


func _count(node: Node, acc: Dictionary) -> void:
	var key := node.get_class()
	if node.get_script() != null:
		var path: String = node.get_script().resource_path
		key = path.get_file().get_basename()
	acc[key] = acc.get(key, 0) + 1
	for c in node.get_children():
		_count(c, acc)
