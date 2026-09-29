class_name StreetLights
extends Node3D
## Felinare pe stalpi si sfori de becuri calde pe o portiune de bucla (Jodhpur,
## dreapta H: „sfori de becuri peste strada", brief §2 / contractul H).
##
## Kitul nu are nici stalp de felinar indian, nici sfoara de becuri (contractul
## zice „sforile de becuri (cod, MultiMesh pe catenara)"), deci le face codul:
## TREI MultiMesh-uri pentru toata portiunea — stalpii (materialul lumii, deja
## numarat), capetele de felinar si becurile (UN material emisiv partajat,
## `Palette.glow_material_slots`, +1 la garda de materiale).
##
## Geometria e scrisa de mana, cu UV COLAPSAT pe centrul slotului (contractul
## atlasului, vezi nota din world_prop.gd): un SphereMesh ar matura atlasul si
## ar avea 4 224 de triunghiuri pe bec. Becul e un octaedru de 8 triunghiuri.
##
## Fara coliziune: stalpii stau in afara asfaltului (`lateral_m` > semilatimea),
## iar dreapta H e dreapta de turbo — un stalp cu corp la 2 m de margine ar fi
## o capcana, nu decor (contractul H: nimic cu coliziune pe banda).
##
## Se construieste AMANAT: nodul sta in DecorManual, copil al pistei, iar
## `_ready` al copiilor ruleaza inaintea `Track._ready` — traseul copt (`baked`)
## nu exista inca atunci.

## Portiunea din bucla (fractii pe index, ca `--frac` si `custom_width_segments`).
@export var frac_from: float = 0.915
@export var frac_to: float = 0.99
## Departarea stalpilor fata de axa (m), pe ambele parti: pe marginea
## trotuarului (asfaltul se termina la 7 m).
@export var lateral_m: float = 8.3
## Pasul stalpilor in lungul drumului (m). Runda 2: 18 -> 7 (criticul: „felinare
## cu glob, la pas mic, pe ambele laturi").
@export var step_m: float = 7.0
## Inaltimea stalpului (m, de la teren).
@export var post_height_m: float = 4.4
## Ghirlanda atarnata intre felinare: inaltimea de prindere si lasarea.
@export var along_height_m: float = 3.9
@export var along_sag_m: float = 0.9
## Sfoara PESTE strada: la fiecare al cate-lea stalp (0 = niciuna), inaltimea
## de prindere si lasarea. Contract: sub +9 m, altfel iese din cadru la 50 m.
@export var cross_every: int = 6
@export var cross_height_m: float = 7.0
@export var cross_sag_m: float = 1.3
## Festoanele de pe FATADE (runda 2: masa sforilor se muta de pe traversari pe
## cornisele primului rand de case). Linii continue la departarea fatadei,
## prinse la fiecare `facade_span_m` si lasate in arc intre prinderi.
@export var facade_lateral_m: float = 9.6
@export var facade_heights_m: PackedFloat32Array = PackedFloat32Array([3.2, 5.5])
@export var facade_span_m: float = 3.5
@export var facade_sag_m: float = 0.55
## Portiuni FARA fatada (si deci fara festoane): (latura, frac_de_la, frac_pana_la),
## latura +1 = dreapta sensului de mers, -1 = stanga.
@export var facade_gaps: Array[Vector3] = []
## Becurile: pasul pe sfoara si raza. Runda 2: raza x3, pasul /2 (cu de doua
## ori mai multe sfori, ~4x becuri) — globuri aproape lipite.
@export var bulb_step_m: float = 0.34
@export var bulb_radius_m: float = 0.16
## Capul felinarului (raza octaedrului emisiv din varful stalpului).
@export var lamp_radius_m: float = 0.36
## Slotul si lumina becurilor: portocaliu-chihlimbar, nu galben pal. Slotul
## 30 (LAVA_ORANGE) si nu 16: emisia se ADUNA peste albedo, iar peste galbenul
## slotului 16 orice tenta portocalie iesea galben-alb (masurat pe captura r2).
## Tot UN material (cheia e slot+energie+tenta), nu unul in plus.
@export var bulb_slot: int = 30
@export var glow_energy: float = 1.3
@export var glow_tint: Color = Color(1.0, 0.33, 0.04)
## Slotul stalpilor (fier inchis).
@export var post_slot: int = 20
## Coborarea bazei stalpului sub cota drumului (terenul de langa asfalt e
## ~0,3 m mai jos; inca putin ca sa nu ramana gol sub baza).
@export var base_drop_m: float = 0.5

var stats := {}


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_build.call_deferred()


func _find_track() -> Track:
	var p := get_parent()
	while p != null:
		if p is Track:
			return p as Track
		p = p.get_parent()
	return null


func _build() -> void:
	var track := _find_track()
	if track == null or track.baked.size() < 4:
		push_warning("StreetLights %s: fara pista coapta" % name)
		return
	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var i0 := int(frac_from * float(n))
	var i1 := int(frac_to * float(n))
	var stations := _stations(route, i0, i1, step_m)
	var post_xf: Array[Transform3D] = []
	var lamp_xf: Array[Transform3D] = []
	var bulb_pos: Array[Vector3] = []
	var tops := [[], []] # [dreapta, stanga] — punctele de prindere in lungul strazii
	for k in stations.size():
		var st: Dictionary = stations[k]
		var c: Vector3 = st["p"]
		var s: Vector3 = st["s"]
		for side_i in 2:
			var sgn := 1.0 if side_i == 0 else -1.0
			var base := c + s * (lateral_m * sgn) + Vector3.DOWN * base_drop_m
			post_xf.append(Transform3D(Basis.IDENTITY, base))
			var top := base + Vector3.UP * (post_height_m + base_drop_m)
			lamp_xf.append(Transform3D(Basis.IDENTITY, top + Vector3.UP * lamp_radius_m))
			(tops[side_i] as Array).append(base + Vector3.UP * (along_height_m + base_drop_m))
		if cross_every > 0 and k % cross_every == 0:
			var ra := c + s * lateral_m + Vector3.UP * cross_height_m
			var la := c - s * lateral_m + Vector3.UP * cross_height_m
			_catenary(ra, la, cross_sag_m, bulb_pos)
	var n_cross := bulb_pos.size()
	for side_i in 2:
		var arr: Array = tops[side_i]
		for k in range(arr.size() - 1):
			_catenary(arr[k], arr[k + 1], along_sag_m, bulb_pos)
	var n_lamp_strings := bulb_pos.size() - n_cross
	# Festoanele de pe fatade.
	var fst := _stations(route, i0, i1, facade_span_m)
	for side_i in 2:
		var sgn := 1.0 if side_i == 0 else -1.0
		for h in facade_heights_m:
			for k in range(fst.size() - 1):
				var fa: float = fst[k]["f"]
				var fb: float = fst[k + 1]["f"]
				if _in_gap(sgn, fa) or _in_gap(sgn, fb):
					continue
				var pa: Vector3 = fst[k]["p"] + (fst[k]["s"] as Vector3) * (facade_lateral_m * sgn)
				var pb: Vector3 = fst[k + 1]["p"] + (fst[k + 1]["s"] as Vector3) * (facade_lateral_m * sgn)
				_catenary(pa + Vector3.UP * h, pb + Vector3.UP * h, facade_sag_m, bulb_pos, true)
	var glow := Palette.glow_material_slots([bulb_slot], glow_energy, glow_tint)
	_add_multimesh("Stalpi", _prism(0.09, post_height_m + base_drop_m, 6, post_slot),
		Palette.world_material(), post_xf, true)
	_add_multimesh("Felinare", _octa(lamp_radius_m, bulb_slot), glow, lamp_xf, false)
	var bulb_xf: Array[Transform3D] = []
	for p in bulb_pos:
		bulb_xf.append(Transform3D(Basis.IDENTITY, p))
	_add_multimesh("Becuri", _octa(bulb_radius_m, bulb_slot), glow, bulb_xf, false)
	stats = {"posts": post_xf.size(), "lamps": lamp_xf.size(),
		"bulbs": bulb_xf.size(), "bulbs_cross": n_cross,
		"bulbs_lamp_strings": n_lamp_strings,
		"bulbs_facade": bulb_xf.size() - n_cross - n_lamp_strings}
	print("StreetLights %s: %s" % [name, stats])


## Cate un punct la fiecare `step` metri de-a lungul traseului (prima statie
## chiar la i0), cu dreapta orizontala si fractia pe index.
func _stations(route: TrackRoute, i0: int, i1: int, step: float) -> Array[Dictionary]:
	var pts := route.baked
	var n := pts.size()
	var out: Array[Dictionary] = []
	var acc := step
	for i in range(i0, i1):
		var a: Vector3 = pts[route.wrap_index(i)]
		var b: Vector3 = pts[route.wrap_index(i + 1)]
		if acc >= step:
			acc = 0.0
			var side := route.side_at(route.wrap_index(i))
			side.y = 0.0
			side = side.normalized()
			out.append({"p": a, "s": side, "f": float(i) / float(n)})
		acc += Vector2(b.x - a.x, b.z - a.z).length()
	return out


func _in_gap(sgn: float, f: float) -> bool:
	for g in facade_gaps:
		if signf(g.x) == sgn and f >= g.y and f <= g.z:
			return true
	return false


## Becurile pe o sfoara intre a si b, lasata cu `sag` la mijloc (parabola:
## la sagetile mici de aici nu se deosebeste de lantisor).
func _catenary(a: Vector3, b: Vector3, sag: float, out: Array[Vector3],
		include_start: bool = false) -> void:
	var length := a.distance_to(b)
	var count := maxi(int(length / bulb_step_m), 1)
	for j in range(0 if include_start else 1, count):
		var t := float(j) / float(count)
		out.append(a.lerp(b, t) + Vector3.DOWN * (4.0 * sag * t * (1.0 - t)))


func _add_multimesh(label: String, mesh: Mesh, mat: Material,
		xfs: Array[Transform3D], shadows: bool) -> void:
	if xfs.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for k in xfs.size():
		mm.set_instance_transform(k, xfs[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = label
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


## Bipiramida hexagonala (12 triunghiuri), UV colapsat pe slot: din camera de
## joc citeste glob, nu romb (octaedrul din runda 1 citea diamant).
static func _octa(r: float, slot: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var uv := Palette.uv(slot)
	var top := Vector3(0, r, 0)
	var bot := Vector3(0, -r, 0)
	for k in 6:
		var a0 := TAU * float(k) / 6.0
		var a1 := TAU * float(k + 1) / 6.0
		var p0 := Vector3(cos(a0) * r, 0, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, 0, sin(a1) * r)
		for tri in [[top, p0, p1], [bot, p1, p0]]:
			var a: Vector3 = tri[0]
			var b: Vector3 = tri[1]
			var c: Vector3 = tri[2]
			var nrm := (b - a).cross(c - a).normalized()
			if nrm.dot(a + b + c) < 0.0:
				var t := b
				b = c
				c = t
				nrm = -nrm
			# fata din fata in Godot: sensul acelor vazut dinspre normala
			for p in [a, c, b]:
				st.set_normal(nrm)
				st.set_uv(uv)
				st.set_color(Color.WHITE)
				st.add_vertex(p)
	return st.commit()


## Prisma cu `sides` fete (fara capace), de la y 0 la y h, UV colapsat pe slot.
static func _prism(r: float, h: float, sides: int, slot: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var uv := Palette.uv(slot)
	for k in sides:
		var a0 := TAU * float(k) / float(sides)
		var a1 := TAU * float(k + 1) / float(sides)
		var p0 := Vector3(cos(a0) * r, 0, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, 0, sin(a1) * r)
		var nrm := Vector3(cos((a0 + a1) * 0.5), 0, sin((a0 + a1) * 0.5))
		# in sensul acelor vazut din afara (fata din fata in Godot)
		var quad := [p0, p1 + Vector3.UP * h, p0 + Vector3.UP * h,
			p0, p1, p1 + Vector3.UP * h]
		for p in quad:
			st.set_normal(nrm)
			st.set_uv(uv)
			st.set_color(Color.WHITE)
			st.add_vertex(p)
	return st.commit()
