extends Node
## Cine arunca umbra pe pista, si cu ce reglaje o arunca lumina.
##
## EXISTA FIINDCA "umbrele sunt pornite" nu inseamna "se vede o umbra". Sonda
## raspunde la trei intrebari separate, si le tine separate anume:
##   1. lumina: unghi, cascada, bias — si CAT de departe impinge biasul umbra
##      lateral, care e cifra ce conteaza la soare razant;
##   2. casterii: cate vizuale au voie sa arunce si cate au SHADOW_OFF;
##   3. geometria: ce umbra arunca cel mai inalt caster de langa drum.
##
## ATENTIE la ce NU dovedeste: ca umbra se VEDE pe ecran. Aia se judeca doar pe
## captura --driver. Sonda spune doar daca sunt conditiile ca ea sa existe.
func _ready() -> void:
	var idx := 6
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--track="):
			idx = GameState.resolve_track_index(int(a.trim_prefix("--track=")))
	var packed: PackedScene = load(GameState.TRACK_SCENES[idx])
	var track: Track = packed.instantiate() as Track
	add_child(track)
	await get_tree().process_frame

	var sun: DirectionalLight3D = null
	for c in track.get_children():
		if c is DirectionalLight3D:
			sun = c as DirectionalLight3D
	if sun == null:
		print("VERDICT: FAIL — nicio lumina directionala")
		get_tree().quit(1)
		return

	var elev: float = absf(sun.rotation_degrees.x)
	print("=== %s — umbre ===" % track.track_name)
	print("  soare        elevatie %.1f grade" % elev)
	print("  cascada      %.1f m" % sun.directional_shadow_max_distance)
	print("  bias         %.3f  normal_bias %.3f  blur %.2f"
		% [sun.shadow_bias, sun.shadow_normal_bias, sun.shadow_blur])

	# Caseta ortografica: Godot o potriveste pe o sfera in jurul feliei de
	# frustum [near, max_dist]. De aici iese marimea texelului, si ea NU depinde
	# de unghiul soarelui — vezi comentariul din _build_environment.
	var far: float = sun.directional_shadow_max_distance
	var near := 0.05
	var t: float = tan(deg_to_rad(68.0) * 0.5)
	var aspect := 16.0 / 9.0
	var a: float = pow(near * t * aspect, 2.0) + pow(near * t, 2.0)
	var b: float = pow(far * t * aspect, 2.0) + pow(far * t, 2.0)
	var zc: float = (b + far * far - a - near * near) / (2.0 * (far - near))
	var radius: float = sqrt(a + pow(near - zc, 2.0))
	var texel: float = (2.0 * radius) / 2048.0
	# Cat impinge normal_bias umbra LATERAL pe teren orizontal.
	var lateral: float = sun.shadow_normal_bias * texel \
		/ maxf(sin(deg_to_rad(elev)), 0.001)
	print("  caseta       %.1f m latime -> texel %.3f m (atlas 2048)"
		% [2.0 * radius, texel])
	print("  decalaj      %.2f m umbra impinsa lateral de normal_bias" % lateral)

	var on := 0
	var off := 0
	var tallest := 0.0
	var road := track.baked
	for n in _all(track):
		var gi := n as GeometryInstance3D
		if gi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			off += 1
			continue
		on += 1
		var aabb := gi.global_transform * (gi as VisualInstance3D).get_aabb()
		# Doar ce sta langa banda: un munte de fundal la 300 m nu e casterul
		# care lipseste din cadru.
		var c := aabb.get_center()
		var best := INF
		for p in road:
			best = minf(best, Vector2(p.x, p.z).distance_to(Vector2(c.x, c.z)))
		if best < 60.0:
			tallest = maxf(tallest, aabb.size.y)
	print("  casteri      %d arunca, %d cu SHADOW_OFF" % [on, off])
	print("  cel mai inalt caster la <60 m de banda: %.1f m" % tallest)
	if tallest > 0.0:
		print("  umbra lui    %.1f m pe teren orizontal"
			% (tallest / maxf(tan(deg_to_rad(elev)), 0.001)))

	# Pragul: decalajul lateral trebuie sa stea sub jumatate de metru, altfel
	# umbra se vede dezlipita de obiect din masina.
	var ok: bool = lateral <= 0.5 and on > 0
	print("VERDICT: %s" % ("OK" if ok else "FAIL"))
	get_tree().quit(0 if ok else 1)


func _all(n: Node) -> Array[GeometryInstance3D]:
	var out: Array[GeometryInstance3D] = []
	if n is GeometryInstance3D and (n is MeshInstance3D or n is MultiMeshInstance3D):
		out.append(n as GeometryInstance3D)
	for c in n.get_children():
		out.append_array(_all(c))
	return out
