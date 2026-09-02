extends Node
## Decorul RUTEI A DOUA prin gatul cu piatra (POI F, brief par. 2): culoarul
## lung care ocoleste piatra pe la vest. Emite nodurile pentru grupul
## `DecorManual/F5_Ocol`: tavan la 9 m, pereti pe ambele flancuri, poala,
## grohotis cu marja derivata (memoria talusului reparat in 312e1b9), usa
## transversala a pietrei pe ruta principala si torte la gura ocolului.
##
## Reteta e cea din `gen_capp_f_gat.gd` (aceleasi piese, aceleasi sloturi);
## diferenta e ca axul e RUTA 1 (`track.routes[1]`), nu bucla principala, iar
## fiecare piesa e verificata contra rutei PRINCIPALE inainte sa fie emisa: ce
## ar cadea in banda ei nu se emite deloc. Asa se deschid singure cele doua
## guri (despartirea si revenirea).
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenCappRuta2.tscn
const OUT := "res://tools/_capp_ruta2_nodes.txt"

const CEIL_H: float = 9.0
const CEIL_TILE: float = 12.0
const WALL_SCALE: float = 2.6
const COL_OUT: float = 2.6
## Fractia (index) a pietrei pe bucla, masurata cu ProbeRuta2.
const STONE_FRAC: float = 0.7228
## Usa sta putin DUPA planul pietrei, ca piatra sa se rostogoleasca peste fata
## ei, nu prin ea (grosimea piesei e 1.5 * 2.6 = 3.9 m).
const DOOR_ALONG: float = 2.8
## ProbeLaneClear masoara si benzile secundare, dar cu LATIMEA PROFILULUI
## PRINCIPAL la indexul brut (width_at_index(i) cu i = indexul benzii, care
## pe ocol cade in fractiile 0.00-0.055 ale buclei, unde semilatimea e 6.5-9).
## Firele laterale ajung deci la 9/3 + 1.1 = 4.1 m de axa ocolului, nu la
## 2.75/3 + 1.1. ORICE corp al ocolului sta dincolo de 4.3 m de axa —
## de-asta adancimea peretilor porneste de la 6.7, nu de la 2.75 (piesa de
## perete are semidiagonala 4.6 m; prima emisie, cu adancimea derivata din
## 2.75, a numarat 1800+ contacte).
const WALL_HW: float = 6.7
## Podeaua oricarui corp fata de axa ocolului (vezi mai sus).
const LANE_KEEP: float = 4.3

## Gabaritul piesei de talus (semidiagonala hall_alcove la scara 1) si capatul
## jitterului de scara — derivate din piesa, vezi gen_capp_f_gat.gd.
const TALUS_HALF_DIAG: float = 1.767
const TALUS_SC_MAX: float = 1.28
const TALUS := [
	{"back": 0.0, "sc": 0.58, "dy": -0.80},
	{"back": -0.9, "sc": 0.34, "dy": -1.00},
]

var lines := PackedStringArray()
var counter: int = 1200


func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(13)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 8:
		await get_tree().process_frame
	if track.routes.size() < 2:
		push_error("GenCappRuta2: ruta 1 nu exista — adauga intai nodul TrackBranch")
		get_tree().quit(1)
		return
	var b: TrackRoute = track.routes[1]
	var main: TrackRoute = track.routes[0]
	var bn := b.count()
	var blen: float = b.dists[bn - 1]

	var at := func(i: int) -> Dictionary:
		var c: Vector3 = b.baked[clampi(i, 0, bn - 1)]
		var i2 := clampi(i + 1, 0, bn - 1)
		var i0 := clampi(i - 1, 0, bn - 1)
		var fw := (b.baked[i2] - b.baked[i0]).normalized()
		return {"c": c, "fw": fw,
			"side": Vector3(fw.z, 0.0, -fw.x).normalized(),
			"yaw": atan2(fw.x, fw.z)}

	var at_len := func(dist: float) -> int:
		for i in bn:
			if b.dists[i] >= dist:
				return i
		return bn - 1

	# Piesa ar intra in banda RUTEI PRINCIPALE? (gurile se deschid cu testul asta)
	var near_main := func(p: Vector3, extra: float) -> bool:
		var i0 := main.closest_index_global(p)
		return main.lateral_distance(i0, p) < track.width_at_index(i0) + extra

	# --- TAVANUL ocolului: 3 lespezi pe rand, ca in gat.
	var rows := int(ceil(blen / CEIL_TILE)) + 1
	for row in rows:
		var d: Dictionary = at.call(at_len.call(blen * (float(row) + 0.5) / float(rows)))
		for k: int in [-1, 0, 1]:
			var pos: Vector3 = (d["c"] as Vector3) \
				+ (d["side"] as Vector3) * (CEIL_TILE * float(k)) \
				+ Vector3.UP * CEIL_H
			if near_main.call(pos, 6.0):
				continue
			_emit("tavanocol", "hall_ceiling_module", pos, d["yaw"] as float,
				"mesh", 1.0)

	# --- PERETII, doua etaje, cu variatia de strat din gat (offset alternant,
	# treapta groasa, skew) — aceleasi formule, ca sa cada in aceleasi sloturi.
	var wall_w := 3.2 * WALL_SCALE
	var wall_h := 3.0 * WALL_SCALE
	var wall_cols := int(ceil(blen / wall_w)) + 1
	for col in wall_cols:
		var d: Dictionary = at.call(at_len.call(blen * (float(col) + 0.5) / float(wall_cols)))
		var c: Vector3 = d["c"]
		var side: Vector3 = d["side"]
		var yaw: float = d["yaw"]
		for sgn: float in [-1.0, 1.0]:
			for lvl in 2:
				var h := float((col * 73 + lvl * 149 + int(sgn) * 37) % 100) / 100.0
				var h2 := float((col * 31 + lvl * 211 + int(sgn) * 17) % 100) / 100.0
				var h3 := float((col * 97 + lvl * 53 + int(sgn) * 61) % 100) / 100.0
				var ws := WALL_SCALE * (0.94 + 0.18 * h)
				var band := 0.5 if lvl % 2 == 0 else -0.5
				var step := float(int(h2 * 3.0)) * 1.6
				var depth := (WALL_HW + COL_OUT + 3.4) - step + band
				var skew := (h3 - 0.5) * 0.40
				var pos := c + side * depth * sgn + Vector3.UP * (wall_h * float(lvl))
				if near_main.call(pos, 3.5):
					continue
				_emit("pereteocol", "hall_alcove", pos,
					yaw + (PI * 0.5 if sgn > 0.0 else -PI * 0.5) + skew, "hull", ws)

	# --- GROHOTISUL: 2 randuri, cu podeaua de marja care tine piesa in afara
	# cutiei sondei de banda (banda are doar 2.75 m semilatime, nu 7 ca gatul).
	var tal_cols := int(ceil(blen / 2.2)) + 1
	for col in tal_cols:
		var d: Dictionary = at.call(at_len.call(blen * (float(col) + 0.5) / float(tal_cols)))
		var c: Vector3 = d["c"]
		var side: Vector3 = d["side"]
		for sgn: float in [-1.0, 1.0]:
			for ri in TALUS.size():
				var row: Dictionary = TALUS[ri]
				var g1 := float((col * 41 + ri * 167 + int(sgn) * 23) % 100) / 100.0
				var g2 := float((col * 89 + ri * 43 + int(sgn) * 71) % 100) / 100.0
				var g3 := float((col * 13 + ri * 197 + int(sgn) * 59) % 100) / 100.0
				var back: float = float(row["back"]) + (g2 - 0.5) * 0.5
				var tsc: float = float(row["sc"]) * (0.72 + 0.56 * g3)
				var lat_margin: float = TALUS_HALF_DIAG * float(row["sc"]) * TALUS_SC_MAX
				# Podeaua: LANE_KEEP plus gabaritul piesei plus aer pentru
				# ruliu (piesa rasucita isi mareste umbra in plan).
				var lat: float = maxf(b.half_width + lat_margin - 0.35 + back,
					LANE_KEEP + lat_margin + 1.1)
				var pos := c + (d["fw"] as Vector3) * ((g1 - 0.5) * 2.2) \
					+ side * lat * sgn + Vector3.UP * float(row["dy"])
				if near_main.call(pos, 2.5):
					continue
				_emit("grohotisocol", "hall_alcove", pos, g1 * TAU, "hull", tsc,
					(g3 - 0.5) * 0.9)

	# --- USA TRANSVERSALA a pietrei, pe ruta principala: zidul in care e taiata
	# fanta de 4 m pe care piatra o inchide. Fara el, strangerea la 2 m
	# semilatime ar fi doar asfalt ingust in mijlocul unui culoar larg.
	var n0 := main.count()
	var si := int(round(STONE_FRAC * float(n0))) % n0
	var sc0: Vector3 = main.baked[si]
	var sfw := (main.baked[(si + 1) % n0] - main.baked[(si - 1 + n0) % n0]).normalized()
	var sside := Vector3(sfw.z, 0.0, -sfw.x).normalized()
	var syaw := atan2(sfw.x, sfw.z)
	var wc := sc0 + sfw * DOOR_ALONG
	for sgn: float in [-1.0, 1.0]:
		for k in 2:
			# nivelul 0: usciorii, de la +-6.6 m in afara (fanta ramane +-2.45)
			_emit("usapinch", "hall_alcove",
				wc + sside * ((6.6 + wall_w * float(k)) * sgn), syaw, "hull",
				WALL_SCALE)
	for k: int in [-2, -1, 0, 1, 2]:
		# nivelul 1: bandoul de deasupra fantei, pana peste tavan
		_emit("usapinch", "hall_alcove",
			wc + sside * (wall_w * float(k)) + Vector3.UP * wall_h, syaw,
			"hull", WALL_SCALE)

	# --- TORTELE: doua la gura ocolului (semnalul "pe aici e mereu liber"),
	# doua pe uscioarele usii. Lumina e cea din gat (30|4.5|#FFB061).
	var m1: Dictionary = at.call(at_len.call(9.0))
	var m2: Dictionary = at.call(at_len.call(14.0))
	_torch((m1["c"] as Vector3) + (m1["side"] as Vector3) * -3.6, m1["yaw"] as float)
	_torch((m2["c"] as Vector3) + (m2["side"] as Vector3) * 3.6, m2["yaw"] as float)
	_torch(wc - sfw * 2.2 + sside * 3.1, syaw)
	_torch(wc - sfw * 2.2 - sside * 3.1, syaw)

	var fa := FileAccess.open(OUT, FileAccess.WRITE)
	fa.store_string("\n".join(lines))
	fa.close()
	print("scrise %d noduri in %s" % [counter - 1200, OUT])
	get_tree().quit()


func _emit(nm: String, res: String, pos: Vector3, yaw: float, col: String,
		scale: float, roll: float = 0.0) -> void:
	var bb := Basis(Vector3.UP, yaw)
	if not is_zero_approx(roll):
		bb = bb * Basis(Vector3.FORWARD, roll)
	bb = bb.scaled(Vector3.ONE * scale)
	lines.append('[node name="%s_%d" parent="DecorManual/F5_Ocol" instance=ExtResource("%s")]'
		% [nm, counter, res])
	lines.append('transform = Transform3D(%.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f)' % [
		bb.x.x, bb.y.x, bb.z.x, bb.x.y, bb.y.y, bb.z.y, bb.x.z, bb.y.z, bb.z.z,
		pos.x, pos.y, pos.z])
	if not col.is_empty():
		lines.append('metadata/coliziune = "%s"' % col)
	lines.append("")
	counter += 1


func _torch(pos: Vector3, yaw: float) -> void:
	var bb := Basis(Vector3.UP, yaw)
	lines.append('[node name="tortaocol_%d" parent="DecorManual/F5_Ocol" instance=ExtResource("40_torch")]'
		% counter)
	lines.append('transform = Transform3D(%.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f)' % [
		bb.x.x, bb.y.x, bb.z.x, bb.x.y, bb.y.y, bb.z.y, bb.x.z, bb.y.z, bb.z.z,
		pos.x, pos.y, pos.z])
	lines.append('metadata/coliziune = "none"')
	lines.append('metadata/lumina = "30|4.5|#FFB061"')
	lines.append("")
	counter += 1
	lines.append('[node name="focOcol_%d" type="OmniLight3D" parent="DecorManual/F5_Ocol"]'
		% counter)
	lines.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.6f, %.6f, %.6f)'
		% [pos.x, pos.y + 2.1, pos.z])
	lines.append("light_color = Color(1, 0.706, 0.42, 1)")
	lines.append("light_energy = 4.20")
	lines.append("omni_range = 13.0")
	lines.append("omni_attenuation = 1.6")
	lines.append("light_specular = 0.20")
	lines.append("shadow_enabled = false")
	lines.append("distance_fade_enabled = true")
	lines.append("distance_fade_begin = 70.0")
	lines.append("distance_fade_length = 25.0")
	lines.append("")
	counter += 1
