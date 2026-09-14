extends Node
## Crusta de soda (POI G, tema serengeti) se citeste PLATA la volan — raport
## dezvoltator, 13 sep. Ipoteza INITIALA (respinsa cu cifre, vezi mai jos):
## tenta `lagoon_crust_tint` (FOAM_WHITE, V 0.94) fiind aproape alba ar
## "satura" ALBEDO = COLOR.rgb * micro * macro (terrain_splat.gdshader) si ar
## coborî sigma de luminanta a texturii.
##
## MASURAT: sigma texturii pe podeaua crustei (16.6) era mai MARE decat pe
## savana din jur (10.5) — ipoteza pe luminanta e falsa. Ce s-a confirmat in
## schimb e SATURATIA: FOAM_WHITE are S=0.037 (aproape gri); un multiplicator
## aproape-gri sterge variatia de NUANTA pe care textura o poarta chiar daca
## luminanta tot variaza normal — saturatie simulata 0.0385 pe crusta fata de
## 0.524 pe savana (podea vs podea, aceeasi cota). Asta citeste "panza
## alb-gri", nu "sol cu grauntisi". Vezi comentariul de la `lagoon_crust_tint`
## in track.gd pentru fix si cifrele complete.
##
## GASIT PE PARCURS (nu era in ipoteza): `lagoon_signed_dist` e distanta PLANA
## (XZ), deci crusta urca si pe PERETELE craterului oriunde XZ-ul cade in
## banda — 37% din nucleul benzii (crust_w~1.0) statea la cota 6-42 m, nu pe
## podeaua joasa. Track.gd are acum o garda de cota (`crust_rise_start`/
## `crust_rise_fade`) care stinge crust_w peste +8..+16 m fata de nivelul
## lacului.
##
## Masoara DIRECT pe mesh-ul terenului (headless, fara Snapshot):
##  1. clasifica vertecsii dupa `lagoon_signed_dist` in crust_core / crust_fade
##     / savana_apropiata / savana_departe (aceleasi praguri ca in
##     _build_terrain: `lagoon_crust_width`, `lagoon_crust_fade`);
##  2. pentru fiecare clasa, statistica pe COLOR.rgb baked (V median, p5/p95);
##  3. simuleaza ALBEDO-ul de iesire (COLOR.rgb * micro(u,v) * macro(u,v)),
##     esantionand PIXELI REALI din surface_sand/grass +macro la UV-ul
##     vertexului (acelasi tiling SURFACE_TILING ca in shader), apoi calculeaza
##     sigma locala (fereastra de 8 vertecsi adiacenti pe grila) pe luminanta
##     SI saturatia HSV rezultate — proxy headless pentru "cat de texturata/
##     colorata arata suprafata", comparabil ca metoda cu tools/measure_surface.gd
##     dar fara randare;
##  4. separa podea (<6m cota) de perete (>=6m) ca sa nu amestece relieful cu
##     tenta in comparatie, si verifica garda de cota (crust_w cu/fara rise).
##
## Rulare:
##   godot --headless --path . --script res://tools/probe_ser_crust.gd

const SURFACE_TILING := 0.32 # track.gd SURFACE_TILING — acelasi factor la UV1
const MACRO_TILING := 0.022 # track.gd SURFACE_TILING_MACRO — UV2

var _sand_micro: Image
var _grass_micro: Image
var _sand_macro: Image
var _grass_macro: Image


func _ready() -> void:
	_sand_micro = Image.load_from_file(
		ProjectSettings.globalize_path("res://assets/textures/surface_sand.png"))
	_grass_micro = Image.load_from_file(
		ProjectSettings.globalize_path("res://assets/textures/surface_grass.png"))
	_sand_macro = Image.load_from_file(
		ProjectSettings.globalize_path("res://assets/textures/surface_sand_macro.png"))
	_grass_macro = Image.load_from_file(
		ProjectSettings.globalize_path("res://assets/textures/surface_grass_macro.png"))

	var scene: PackedScene = load("res://scenes/tracks/Track14.tscn")
	var track: Node = scene.instantiate()
	add_child(track)
	for i in 8:
		await get_tree().process_frame

	var crust_tint: Variant = track.theme_flag("lagoon_crust_tint", null)
	var crust_width := float(track.theme_flag("lagoon_crust_width", 40.0))
	var crust_fade := maxf(float(track.theme_flag("lagoon_crust_fade", 15.0)), 0.001)
	print("=== CRUSTA DE SODA — Track14/serengeti ===")
	print("lagoon_crust_tint=%s width=%.1f fade=%.1f"
		% [str(crust_tint), crust_width, crust_fade])

	var terrain := _find_terrain(track)
	if terrain == null:
		printerr("PICA: nu gasesc nodul 'Terrain' in Track14")
		get_tree().quit(1)
		return
	var mesh := terrain.mesh
	if mesh == null or mesh.get_surface_count() == 0:
		printerr("PICA: Terrain fara mesh/suprafete")
		get_tree().quit(1)
		return

	var arr := mesh.surface_get_arrays(0)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var cols: PackedColorArray = arr[Mesh.ARRAY_COLOR]
	if cols.is_empty():
		printerr("PICA: mesh-ul terenului nu are ARRAY_COLOR")
		get_tree().quit(1)
		return
	print("vertecsi total: %d" % vs.size())

	# Clasele, dupa aceeasi cifra ca _build_terrain (sd = semnat, m fata de mal):
	#   crust_core  : sd in [-crust_width, +ceva mic]  -> crust_w ~ 1.0 (banda plina)
	#   crust_fade  : sd in (-crust_width-crust_fade, -crust_width) -> tranzitie
	#   savana_apropiata: imediat dupa fade, pana la +25 m in plus (control apropiat)
	#   savana_departe  : 60-150 m dincolo de fade (control neatins de crusta)
	var buckets := {
		"crust_core": PackedFloat32Array(),
		"crust_fade": PackedFloat32Array(),
		"savana_apropiata": PackedFloat32Array(),
		"savana_departe": PackedFloat32Array(),
	}
	var idx_buckets := {
		"crust_core": PackedInt32Array(),
		"crust_fade": PackedInt32Array(),
		"savana_apropiata": PackedInt32Array(),
		"savana_departe": PackedInt32Array(),
	}
	var sampler = track._sampler
	if sampler == null:
		printerr("PICA: track._sampler e null")
		get_tree().quit(1)
		return

	var fade_lo := -crust_width - crust_fade
	var fade_hi := -crust_width
	for i in vs.size():
		var v := vs[i]
		var sd: float = sampler.lagoon_signed_dist(v.x, v.z)
		if sd > 1e8:
			continue
		if sd >= fade_hi - crust_fade * 0.15: # nucleul benzii, plin
			idx_buckets["crust_core"].append(i)
		elif sd >= fade_lo and sd < fade_hi - crust_fade * 0.15:
			idx_buckets["crust_fade"].append(i)
		elif sd < fade_lo and sd >= fade_lo - 25.0:
			idx_buckets["savana_apropiata"].append(i)
		elif sd < fade_lo - 60.0 and sd >= fade_lo - 150.0:
			idx_buckets["savana_departe"].append(i)

	for key: String in idx_buckets.keys():
		var idxs: PackedInt32Array = idx_buckets[key]
		print("\n--- %s: %d vertecsi ---" % [key, idxs.size()])
		if idxs.is_empty():
			continue
		_report_color_stats(idxs, cols)
		_report_albedo_sigma(key, idxs, vs, cols)
		_report_macro_variance(key, idxs, cols)

	# GEOMETRIA: raportul dezvoltatorului e "valuri de relief FARA granulatie
	# de suprafata" — adica exista relief (cote care ondu leaza), dar culoarea/
	# textura nu-l "vinde". Masor variatia de COTA (y) pe fiecare bucket, ca sa
	# stiu daca podeaua crusta chiar e mai valurita decat savana din jur sau la
	# fel de plata (comentariul din cod zice crater "plat la 1.7 m").
	print("\n=== Variatia de COTA (relief geometric) pe bucket ===")
	for key: String in idx_buckets.keys():
		var idxs2: PackedInt32Array = idx_buckets[key]
		if idxs2.is_empty():
			continue
		var ys := PackedFloat32Array()
		for i in idxs2:
			ys.append(vs[i].y)
		ys.sort()
		var ymean := 0.0
		for y in ys:
			ymean += y
		ymean /= float(ys.size())
		var yvar := 0.0
		for y in ys:
			yvar += (y - ymean) * (y - ymean)
		var ysigma := sqrt(yvar / float(ys.size()))
		print("  %-18s cota med=%.2f sigma=%.3f m  min=%.2f max=%.2f  p10=%.2f p90=%.2f"
			% [key, ymean, ysigma, ys[0], ys[ys.size() - 1],
				_pctl(ys, 0.10), _pctl(ys, 0.90)])
	# Cat de mult din "crust_core" e chiar PODEAUA (cota joasa, sub 6 m) fata
	# de PERETE (cota mare, prins doar fiindca e aproape in XZ de contur)?
	var floor_n := 0
	var wall_n := 0
	for i in idx_buckets["crust_core"]:
		if vs[i].y < 6.0:
			floor_n += 1
		else:
			wall_n += 1
	print("  crust_core: podea(<6m)=%d  perete(>=6m)=%d  din %d total"
		% [floor_n, wall_n, idx_buckets["crust_core"].size()])

	# CONTROL CORECT: compara PODEAUA crustei (cota < 6 m) cu PODEAUA de
	# savana din jur la ACEEASI cota joasa (nu cu tot bucket-ul savana, care
	# include si versanti mai sus) — altfel diferenta de sigma s-ar putea
	# datora reliefului, nu tentei.
	var floor_crust := PackedInt32Array()
	for i in idx_buckets["crust_core"]:
		if vs[i].y < 6.0:
			floor_crust.append(i)
	var floor_savana := PackedInt32Array()
	for i in idx_buckets["savana_apropiata"]:
		if vs[i].y < 6.0:
			floor_savana.append(i)
	for i in idx_buckets["savana_departe"]:
		if vs[i].y < 6.0:
			floor_savana.append(i)
	print("\n=== CONTROL: doar PODEAUA (cota < 6 m), crusta vs savana ===")
	print("--- podea_crusta: %d vertecsi ---" % floor_crust.size())
	if not floor_crust.is_empty():
		_report_color_stats(floor_crust, cols)
		_report_albedo_sigma("podea_crusta", floor_crust, vs, cols)
		_report_macro_variance("podea_crusta", floor_crust, cols)
	print("--- podea_savana: %d vertecsi ---" % floor_savana.size())
	if not floor_savana.is_empty():
		_report_color_stats(floor_savana, cols)
		_report_albedo_sigma("podea_savana", floor_savana, vs, cols)
		_report_macro_variance("podea_savana", floor_savana, cols)

	# SATURATIE: un tint aproape-alb e prin definitie DESATURAT (S mic). Chiar
	# daca luminanta texturii inca variaza normal (masurat mai sus), o
	# suprafata cu saturatie foarte mica citeste "sters"/"plat" chiar cu
	# relief real dedesubt — asta ar fi mecanismul real daca sigma nu-l arata.
	print("\n=== SATURATIE HSV a albedo-ului simulat (podea_crusta vs podea_savana) ===")
	_report_saturation("podea_crusta", floor_crust, vs, cols)
	_report_saturation("podea_savana", floor_savana, vs, cols)

	# Diagnostic direct: crust_w REAL (recalculat cu aceeasi formula ca
	# _build_terrain, FARA zgomotul de dirt_noise ca sa izolez trapezul de baza)
	# pe fiecare vertex clasificat "crust_core", ca sa verific daca bucket-ul
	# meu chiar prinde crust_w ~= 1 sau prinde si coada de tranzitie.
	print("\n=== crust_w recalculat pe bucket-ul crust_core (fara zgomot) ===")
	var core_idxs: PackedInt32Array = idx_buckets["crust_core"]
	var cw := PackedFloat32Array()
	for i in core_idxs:
		var v := vs[i]
		var sd: float = sampler.lagoon_signed_dist(v.x, v.z)
		var w := clampf((sd + crust_width + crust_fade) / crust_fade, 0.0, 1.0)
		cw.append(w)
	cw.sort()
	print("  crust_w median=%.3f p5=%.3f p95=%.3f min=%.3f"
		% [_pctl(cw, 0.5), _pctl(cw, 0.05), _pctl(cw, 0.95),
			cw[0] if not cw.is_empty() else -1.0])

	# GARDA DE COTA: cat de mult din crust_w SUPRAVIETUIESTE pe podea (<6 m)
	# fata de perete (>=6 m), cu rise gate inclus (aceeasi formula ca in
	# track.gd: sea_y = mean_road_y() + sea_level_offset, prag +8 m, fade 8 m).
	var sea_y: float = track._sampler.mean_road_y() + track.sea_level_offset
	print("\n=== garda de cota pe crust_core: crust_w CU rise gate ===")
	print("  sea_y=%.2f" % sea_y)
	var cw_floor := PackedFloat32Array()
	var cw_wall := PackedFloat32Array()
	for i in core_idxs:
		var v := vs[i]
		var sd: float = sampler.lagoon_signed_dist(v.x, v.z)
		var w := clampf((sd + crust_width + crust_fade) / crust_fade, 0.0, 1.0)
		var rise := clampf((v.y - sea_y - 8.0) / 8.0, 0.0, 1.0)
		w *= 1.0 - rise
		if v.y < 6.0:
			cw_floor.append(w)
		else:
			cw_wall.append(w)
	cw_floor.sort(); cw_wall.sort()
	print("  podea (<6m, n=%d): crust_w CU gate median=%.3f p5=%.3f"
		% [cw_floor.size(), _pctl(cw_floor, 0.5), _pctl(cw_floor, 0.05)])
	print("  perete (>=6m, n=%d): crust_w CU gate median=%.3f p95=%.3f max=%.3f"
		% [cw_wall.size(), _pctl(cw_wall, 0.5), _pctl(cw_wall, 0.95),
			cw_wall[cw_wall.size() - 1] if not cw_wall.is_empty() else -1.0])

	get_tree().quit(0)


func _find_terrain(nd: Node) -> MeshInstance3D:
	if nd is MeshInstance3D and str(nd.name) == "Terrain":
		return nd as MeshInstance3D
	for c in nd.get_children():
		var r := _find_terrain(c)
		if r != null:
			return r
	return null


## Luminanta (Rec.601) a vertex color-ului BAKED (tint*shade), inainte de
## multiplicarea cu textura. Asta arata cat de aproape de alb e tenta pe fiecare
## zona — cifra care sustine sau infirma ipoteza "tenta aproape alba".
func _report_color_stats(idxs: PackedInt32Array, cols: PackedColorArray) -> void:
	var lums := PackedFloat32Array()
	var rs := PackedFloat32Array()
	var gs := PackedFloat32Array()
	var bs := PackedFloat32Array()
	for i in idxs:
		var c := cols[i]
		lums.append(0.299 * c.r + 0.587 * c.g + 0.114 * c.b)
		rs.append(c.r); gs.append(c.g); bs.append(c.b)
	lums.sort()
	print("  COLOR.rgb (vertex, inainte de textura): V median=%.3f p5=%.3f p95=%.3f"
		% [_pctl(lums, 0.5), _pctl(lums, 0.05), _pctl(lums, 0.95)])
	print("  COLOR medie R=%.3f G=%.3f B=%.3f" % [_mean(rs), _mean(gs), _mean(bs)])


## ALBEDO simulat = COLOR.rgb * micro(UV) * macro(UV2), esantionat din PNG-urile
## reale la coordonatele de lume ale vertexului (acelasi tiling ca shader-ul).
## Grupeaza vertecsii pe celule de teren (grila ~7.9 m) si calculeaza sigma
## luminantei INTRE vertecsii din aceeasi celula mica de lume (fereastra locala,
## nu global) — proxy pentru "cat de texturata arata suprafata la acel nivel de
## tenta", comparabil ca principiu cu tools/measure_surface.gd (dale mici,
## deviatie interna), dar calculat pe semnal, nu pe pixeli randati.
func _report_albedo_sigma(label: String, idxs: PackedInt32Array,
		vs: PackedVector3Array, cols: PackedColorArray) -> void:
	# Esantionez direct: pentru fiecare vertex ales, opt esantioane de textura
	# in jurul UV-ului lui (offset mic, sub-texel) ca sa capturez granulatia
	# `micro` fara sa am nevoie de vertecsii vecini reali (grila terenului e
	# prea rara ca sa prinda variatia de textura intre noduri).
	var lums := PackedFloat32Array()
	const OFFS := [
		Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1),
		Vector2(-1, 0), Vector2(0, -1), Vector2(0.5, 0.5), Vector2(-0.5, -0.5),
	]
	for i in idxs:
		var v := vs[i]
		var c := cols[i]
		var w := c.a # grass_w baked (0 = nisip, 1 = iarba)
		var uv1 := Vector2(v.x, v.z) * SURFACE_TILING
		var uv2 := Vector2(v.x, v.z) * MACRO_TILING
		var group := PackedFloat32Array()
		for o in OFFS:
			var micro := _sample_mix(_sand_micro, _grass_micro,
				uv1 + o * 0.01, w)
			var macro := _sample_mix(_sand_macro, _grass_macro,
				uv2 + o * 0.01, w)
			var albedo := Vector3(c.r, c.g, c.b) * micro * macro
			var lum := 0.299 * albedo.x + 0.587 * albedo.y + 0.114 * albedo.z
			group.append(lum * 255.0)
		# sigma LOCALA (in jurul acestui vertex) — echivalentul unei "dale" din
		# measure_surface.gd, dar calculata analitic pe cateva sub-texele.
		var mean := 0.0
		for g in group:
			mean += g
		mean /= float(group.size())
		var var_sum := 0.0
		for g in group:
			var_sum += (g - mean) * (g - mean)
		lums.append(sqrt(var_sum / float(group.size())))
	lums.sort()
	print("  ALBEDO simulat: sigma texturii LOCALE median=%.2f p25=%.2f p75=%.2f"
		% [_pctl(lums, 0.5), _pctl(lums, 0.25), _pctl(lums, 0.75)])


## Cat de mult variaza tenta baked (COLOR.rgb, deci PATICHIUL vizibil de la
## distanta: petele de dirt_noise, marginea zdrentuita) INTRE vertecsii clasei,
## nu textura de aproape. O banda cu grass_w si tint aproape constante pe toata
## intinderea (crust_w satureaza la 1.0 pe majoritatea nucleului) arata ca o
## panza chiar daca sigma de textura e normala — pentru ca lipseste variatia de
## MACRO-nivel (petice, tranzitii) pe care creierul o citeste ca relief de
## suprafata la viteza de masina.
func _report_macro_variance(label: String, idxs: PackedInt32Array,
		cols: PackedColorArray) -> void:
	if idxs.size() < 2:
		return
	var lums := PackedFloat32Array()
	for i in idxs:
		var c := cols[i]
		lums.append((0.299 * c.r + 0.587 * c.g + 0.114 * c.b) * 255.0)
	var mean := 0.0
	for l in lums:
		mean += l
	mean /= float(lums.size())
	var var_sum := 0.0
	for l in lums:
		var_sum += (l - mean) * (l - mean)
	var sigma := sqrt(var_sum / float(lums.size()))
	print("  TENTA baked (macro/patch, INTRE vertecsi): sigma=%.2f (mean V*255=%.1f, coef.var=%.4f)"
		% [sigma, mean, sigma / maxf(mean, 0.001)])


## Saturatia HSV a albedo-ului simulat (COLOR * micro * macro), mediana si
## variatia ei — testeaza ipoteza "tenta aproape-alba = suprafata desaturata,
## si asta citeste plat chiar daca luminanta variaza".
func _report_saturation(label: String, idxs: PackedInt32Array,
		vs: PackedVector3Array, cols: PackedColorArray) -> void:
	if idxs.is_empty():
		return
	var sats := PackedFloat32Array()
	for i in idxs:
		var v := vs[i]
		var c := cols[i]
		var w := c.a
		var uv1 := Vector2(v.x, v.z) * SURFACE_TILING
		var uv2 := Vector2(v.x, v.z) * MACRO_TILING
		var micro := _sample_mix(_sand_micro, _grass_micro, uv1, w)
		var macro := _sample_mix(_sand_macro, _grass_macro, uv2, w)
		var albedo := Vector3(c.r, c.g, c.b) * micro * macro
		var col := Color(clampf(albedo.x, 0, 1), clampf(albedo.y, 0, 1),
			clampf(albedo.z, 0, 1))
		sats.append(col.s)
	sats.sort()
	print("  %-14s saturatie HSV median=%.4f p25=%.4f p75=%.4f (n=%d)"
		% [label, _pctl(sats, 0.5), _pctl(sats, 0.25), _pctl(sats, 0.75), sats.size()])


func _sample_mix(micro_or_macro_a: Image, micro_or_macro_b: Image,
		uv: Vector2, w: float) -> Vector3:
	var a := _sample_wrap(micro_or_macro_a, uv)
	var b := _sample_wrap(micro_or_macro_b, uv)
	return a.lerp(b, w)


func _sample_wrap(img: Image, uv: Vector2) -> Vector3:
	var wgt := img.get_width()
	var hgt := img.get_height()
	var x := int(fposmod(uv.x, 1.0) * float(wgt))
	var y := int(fposmod(uv.y, 1.0) * float(hgt))
	x = clampi(x, 0, wgt - 1)
	y = clampi(y, 0, hgt - 1)
	var c := img.get_pixel(x, y)
	return Vector3(c.r, c.g, c.b)


func _mean(a: PackedFloat32Array) -> float:
	if a.is_empty():
		return 0.0
	var s := 0.0
	for v in a:
		s += v
	return s / float(a.size())


func _pctl(sorted: PackedFloat32Array, q: float) -> float:
	if sorted.is_empty():
		return 0.0
	var idx := clampi(int(q * float(sorted.size())), 0, sorted.size() - 1)
	return sorted[idx]
