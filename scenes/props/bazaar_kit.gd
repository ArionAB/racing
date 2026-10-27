@tool
class_name BazaarKit
extends Node3D
## TEXTILELE SI MARFA BAZARULUI SARDAR (Jodhpur, Track17, POI B), generate din
## cod pe atlasul lumii: copertine de panza saturate peste tarabe, gramezi de
## condimente si cosuri de marfa, oameni pe trotuar si fasii de textile PESTE
## strada. Tiparul `RoofKit` (POI D): un singur material (`Palette.world_material()`),
## doar alt UV per slot, totul unit intr-un mesh pe celula de CELL_M.
##
## De ce din cod: kitul are `stall_canopy_a/b/c` cu acoperisul pe slotul 0
## (nisip pal) si tejgheaua goala — verdictul criticului pe A („mese de picnic
## goale"). Cererile de asset (copertine colorate, figuranti) nu exista in kit;
## coordonatorul a permis sa fie facute din cod pe materialul lumii.
##
## Fara coliziune: copertinele stau peste tarabele GLB (care au corpul `hull`),
## marfa sta pe/langa tejghea, oamenii sunt teatru (ca procesiunea din D), iar
## fasiile sunt la 7-9 m, peste masini. Nimic nu arunca umbra de pe fasii
## (memoria `caster-departat-fura-umbra` nu se aplica: sunt aproape, dar trec
## peste camera — umbra lor pe drum ar citi ca pete, deci sunt fara umbra).
##
## Construit in `_ready` (pozitiile sunt deja in coordonate de LUME, scrise de
## `tools/gen_decor_jod_b.gd`), ca sa apara in capturi (memoria
## `decorul-amanat-nu-e-in-captura`); materialul se pune amanat, dupa WorldProp.

## Copertinele: cate TREI puncte per copertina — spate-stanga, spate-dreapta
## (pe muchia din spate, la cota de sus) si vectorul spre drum (lungimea
## copertinei + caderea ei pe verticala, in y).
@export var awnings: PackedVector3Array = PackedVector3Array()
@export var awning_slots: PackedInt32Array = PackedInt32Array()
## Gramezile de marfa: pozitia bazei (lume), marimea (1 = cos de 0,5 m) si
## slotul gramezii.
@export var goods: PackedVector3Array = PackedVector3Array()
@export var goods_sizes: PackedFloat32Array = PackedFloat32Array()
@export var goods_slots: PackedInt32Array = PackedInt32Array()
## Oamenii: pozitia la picioare (lume), inaltimea, slotul hainei si al
## capului acoperit (turban / val; -1 = par negru).
@export var people: PackedVector3Array = PackedVector3Array()
@export var people_heights: PackedFloat32Array = PackedFloat32Array()
@export var people_slots: PackedInt32Array = PackedInt32Array()
@export var people_head_slots: PackedInt32Array = PackedInt32Array()
## Directia fetei fiecarui om (yaw, rad). Runda 2: siluete cu umeri si brate,
## deci conteaza incotro privesc (grupurile se intorc unul spre altul).
@export var people_yaws: PackedFloat32Array = PackedFloat32Array()
## Stivele de marfa (runda 2, criticul: „tarabele incarcate cu STIVE continue
## de marfa: cosuri, saci, textile stivuite"): cutii orientate. Baza (lume),
## semi-latime x / inaltime / semi-adancime z, yaw, slot, ingustarea capului
## (1 = cutie, <1 = sac strans la gura).
@export var boxes: PackedVector3Array = PackedVector3Array()
@export var box_dims: PackedVector3Array = PackedVector3Array()
@export var box_yaws: PackedFloat32Array = PackedFloat32Array()
@export var box_slots: PackedInt32Array = PackedInt32Array()
@export var box_tapers: PackedFloat32Array = PackedFloat32Array()
## Stativele felinarelor de la sol (baza, lume; inaltimea in y a vectorului
## din `stand_heights`). Lampa insasi e in nodul `FortLamps` vecin.
@export var stands: PackedVector3Array = PackedVector3Array()
@export var stand_heights: PackedFloat32Array = PackedFloat32Array()
## Fasiile peste strada: perechi de capete (lume, la cota franghiei); panzele
## atarna de franghie, lipite una de alta, in culori alternate.
@export var strips: PackedVector3Array = PackedVector3Array()
@export var strip_sag_m: float = 0.7
@export var strip_cloth_h: Vector2 = Vector2(0.9, 1.35)
## Latimea panzelor si golul dintre ele (m). Cu goluri, fasia din prim-plan
## e un sir de steaguri prin care se vede drumul, nu un zid de panza.
@export var strip_cloth_w: Vector2 = Vector2(0.9, 1.4)
@export var strip_gap: Vector2 = Vector2(0.0, 0.08)

const CELL_M := 60.0
const KIT_LOD_BIAS := 0.5
const POLE_SLOT := 9
const BASKET_SLOT := 28
const ROPE_SLOT := 28
const SKIN_SLOT := 27
const HAIR_SLOT := 26
const STAND_SLOT := 20
const CLOTH_SLOTS := [16, 31, 21, 14, 30, 15]

var _meshes: Array[MeshInstance3D] = []
var _built := false
var stats := {}


func _ready() -> void:
	if _built:
		return
	_built = true
	global_transform = Transform3D.IDENTITY
	var cells := {}
	var na := 0
	for i in range(0, awnings.size() - 2, 3):
		var slot: int = awning_slots[na] if na < awning_slots.size() else 16
		_awning(_cell(cells, awnings[i]), awnings[i], awnings[i + 1], awnings[i + 2], slot)
		na += 1
	for i in goods.size():
		var s: float = goods_sizes[i] if i < goods_sizes.size() else 1.0
		var sl: int = goods_slots[i] if i < goods_slots.size() else 30
		_heap(_cell(cells, goods[i]), goods[i], s, sl, i)
	for i in people.size():
		var h: float = people_heights[i] if i < people_heights.size() else 1.65
		var sl: int = people_slots[i] if i < people_slots.size() else 14
		var hs: int = people_head_slots[i] if i < people_head_slots.size() else -1
		var yw: float = people_yaws[i] if i < people_yaws.size() else 0.0
		_person(_cell(cells, people[i]), people[i], h, sl, hs, yw, i)
	for i in boxes.size():
		var dm: Vector3 = box_dims[i] if i < box_dims.size() else Vector3(0.25, 0.3, 0.25)
		var yw: float = box_yaws[i] if i < box_yaws.size() else 0.0
		var sl: int = box_slots[i] if i < box_slots.size() else 9
		var tp: float = box_tapers[i] if i < box_tapers.size() else 1.0
		_obox(_cell(cells, boxes[i]), boxes[i], dm.x, dm.z, dm.y, yw, sl,
			Vector2(tp, tp), 0.6)
	for i in stands.size():
		var hh: float = stand_heights[i] if i < stand_heights.size() else 1.1
		_stand(_cell(cells, stands[i]), stands[i], hh)
	var ns := 0
	for i in range(0, strips.size() - 1, 2):
		_strip(_cell(cells, (strips[i] + strips[i + 1]) * 0.5), strips[i], strips[i + 1], i)
		ns += 1
	var tris := 0
	for key: Vector2i in cells:
		var st: SurfaceTool = cells[key]
		var mi := MeshInstance3D.new()
		mi.name = "Bazar_%d_%d" % [key.x, key.y]
		# Cu LOD-uri: mesh-ul unit al unei celule are 4-22k triunghiuri si sta
		# langa drum; fara ele se desena intreg si de la 100 m (ProbePerf, 27 oct 2026).
		mi.mesh = MeshCpu.with_lods(st.commit())
		# Piesele au 20-60 cm: la 30 m detaliul scos de nivelul urmator e sub un
		# pixel, deci LOD-ul poate cobori de doua ori mai devreme decat pe case.
		mi.lod_bias = KIT_LOD_BIAS
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(mi)
		_meshes.append(mi)
		tris += mi.mesh.surface_get_array_len(0) / 3 if mi.mesh.get_surface_count() > 0 else 0
	stats = {"awnings": na, "goods": goods.size(), "people": people.size(),
		"boxes": boxes.size(), "stands": stands.size(),
		"strips": ns, "cells": cells.size(), "tris": tris}
	if not Engine.is_editor_hint():
		print("BazaarKit %s: %s" % [name, stats])
	_apply_materials.call_deferred()


func _apply_materials() -> void:
	for mi in _meshes:
		mi.material_override = Palette.world_material()


func _cell(cells: Dictionary, p: Vector3) -> SurfaceTool:
	var key := Vector2i(floori(p.x / CELL_M), floori(p.z / CELL_M))
	if not cells.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		cells[key] = st
	return cells[key]


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, slot: int,
		ao: float = 1.0) -> void:
	var n := (c - a).cross(b - a).normalized()
	var uv := Palette.uv(slot)
	for v: Vector3 in [a, b, c]:
		st.set_normal(n)
		st.set_uv(uv)
		st.set_color(Color(ao, ao, ao))
		st.add_vertex(v)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		slot: int, ao_front: float = 1.0, ao_back: float = -1.0) -> void:
	_tri(st, a, b, c, slot, ao_front)
	_tri(st, a, c, d, slot, ao_front)
	if ao_back >= 0.0:
		_tri(st, a, c, b, slot, ao_back)
		_tri(st, a, d, c, slot, ao_back)


## Prisma verticala cu `seg` laturi (stalpi, trunchiul oamenilor).
func _prism(st: SurfaceTool, base: Vector3, r0: float, r1: float, h: float,
		slot: int, seg: int, ao0: float = 0.7, cap: bool = true) -> void:
	var uv := Palette.uv(slot)
	for k in seg:
		var a0 := TAU * float(k) / float(seg)
		var a1 := TAU * float(k + 1) / float(seg)
		var d0 := Vector3(cos(a0), 0.0, sin(a0))
		var d1 := Vector3(cos(a1), 0.0, sin(a1))
		var b0 := base + d0 * r0
		var b1 := base + d1 * r0
		var t0 := base + d0 * r1 + Vector3.UP * h
		var t1 := base + d1 * r1 + Vector3.UP * h
		for vv: Array in [[b0, d0, ao0], [b1, d1, ao0], [t0, d0, 1.0],
				[b1, d1, ao0], [t1, d1, 1.0], [t0, d0, 1.0]]:
			st.set_normal(vv[1])
			st.set_uv(uv)
			var c: float = vv[2]
			st.set_color(Color(c, c, c))
			st.add_vertex(vv[0])
		if cap:
			_tri(st, t0, t1, base + Vector3.UP * h, slot)


## Copertina de panza: planul inclinat (spate sus -> fata jos, putin lasat pe
## mijloc), falbalaua din fata cu dinti si doi stalpi subtiri la colturile
## dinspre drum. Fata de sus luminata, dedesubtul in umbra (AO in vertex color).
func _awning(st: SurfaceTool, bl: Vector3, br: Vector3, out: Vector3, slot: int) -> void:
	# Fata de sus (AO 1) trebuie sa aiba normala in sus: ordinea capetelor
	# din spate decide sensul, deci se intoarce la nevoie.
	if (br - bl).cross(out).y < 0.0:
		var tmp := bl
		bl = br
		br = tmp
	var fl := bl + out
	var fr := br + out
	var sag := Vector3.DOWN * 0.12
	var ml := (bl + fl) * 0.5 + sag
	var mr := (br + fr) * 0.5 + sag
	# Planul in doua fasii (lasat pe mijloc). Normala in sus pe fata de sus.
	_quad(st, bl, ml, mr, br, slot, 1.0, 0.55)
	_quad(st, ml, fl, fr, mr, slot, 1.0, 0.55)
	# Falbalaua: fasie verticala cu dinti, spre drum.
	var along := fr - fl
	var w := along.length()
	var dir := along / maxf(w, 0.001)
	var drop := 0.32
	var teeth := maxi(3, int(round(w / 0.45)))
	var step := w / float(teeth)
	var alt: int = CLOTH_SLOTS[(CLOTH_SLOTS.find(slot) + 3) % CLOTH_SLOTS.size()] \
		if CLOTH_SLOTS.has(slot) else 22
	for k in teeth:
		var a := fl + dir * (step * float(k))
		var b := fl + dir * (step * float(k + 1))
		var m := (a + b) * 0.5 + Vector3.DOWN * drop
		var bot_a := a + Vector3.DOWN * drop * 0.55
		var bot_b := b + Vector3.DOWN * drop * 0.55
		_quad(st, a, b, bot_b, bot_a, slot, 0.95, 0.6)
		_tri(st, bot_a, bot_b, m, alt, 0.95)
		_tri(st, bot_a, m, bot_b, alt, 0.6)
	# Laturile: triunghiuri de panza intre spate si fata (inchid cortul).
	for e: Array in [[bl, fl], [br, fr]]:
		var p0: Vector3 = e[0]
		var p1: Vector3 = e[1]
		var low := p1 + Vector3.DOWN * drop * 0.55
		_tri(st, p0, p1, low, slot, 0.85)
		_tri(st, p0, low, p1, slot, 0.6)
	# Stalpii din fata, pana la sol (sol ~ baza tarabei: spatele e la cota
	# copertinei, deci solul e la ~2,6 m sub muchia din spate).
	var ground_y := bl.y - 2.65
	for p: Vector3 in [fl, fr]:
		var base := Vector3(p.x, ground_y, p.z)
		_prism(st, base, 0.045, 0.04, p.y - ground_y, POLE_SLOT, 4, 0.6, false)


## Gramada de marfa: cos (prisma joasa) cu con de condiment deasupra.
func _heap(st: SurfaceTool, p: Vector3, s: float, slot: int, idx: int) -> void:
	var r := 0.26 * s
	_prism(st, p, r * 0.85, r, 0.22 * s, BASKET_SLOT, 6, 0.55, false)
	var top := p + Vector3.UP * (0.22 * s)
	var apex := top + Vector3.UP * (0.3 * s)
	var seg := 6
	var yaw := float(idx) * 0.7
	for k in seg:
		var a0 := yaw + TAU * float(k) / float(seg)
		var a1 := yaw + TAU * float(k + 1) / float(seg)
		var q0 := top + Vector3(cos(a0), 0.0, sin(a0)) * r
		var q1 := top + Vector3(cos(a1), 0.0, sin(a1)) * r
		_tri(st, q0, q1, apex, slot, 1.0)


## Triunghi cu normala spre EXTERIORUL unui solid (fata de centrul lui):
## ordinea se intoarce singura, deci solidele nu depind de sensul colturilor.
func _tri_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, slot: int,
		ao: float, center: Vector3) -> void:
	var n := (c - a).cross(b - a)
	if n.dot((a + b + c) / 3.0 - center) < 0.0:
		_tri(st, a, c, b, slot, ao)
	else:
		_tri(st, a, b, c, slot, ao)


## Cutie orientata (yaw), cu capul ingustat pe x/z cu `top`; fara fund.
## Fetele laterale au AO `ao0` jos (vertex color pe triunghi: media).
func _obox(st: SurfaceTool, base: Vector3, hx: float, hz: float, h: float,
		yaw: float, slot: int, top: Vector2 = Vector2.ONE, ao_side: float = 0.8) -> void:
	var ax := Vector3(cos(yaw), 0.0, -sin(yaw))
	var az := Vector3(sin(yaw), 0.0, cos(yaw))
	var center := base + Vector3.UP * (h * 0.5)
	var b: Array[Vector3] = []
	var t: Array[Vector3] = []
	for q: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		b.append(base + ax * (q.x * hx) + az * (q.y * hz))
		t.append(base + Vector3.UP * h + ax * (q.x * hx * top.x) + az * (q.y * hz * top.y))
	for i in 4:
		var j := (i + 1) % 4
		_tri_out(st, b[i], b[j], t[j], slot, ao_side, center)
		_tri_out(st, b[i], t[j], t[i], slot, ao_side, center)
	_tri_out(st, t[0], t[1], t[2], slot, 1.0, center)
	_tri_out(st, t[0], t[2], t[3], slot, 1.0, center)


## Om stilizat, runda 2 (criticul: figurantii „citesc ca stalpisori"): silueta
## de figurina — fusta/dhoti lata, trunchi cu UMERI mai lati decat talia, doua
## brate, cap de piele si turban/val colorat (sau par negru). ~60 de
## triunghiuri, sase cutii orientate dupa `yaw`.
func _person(st: SurfaceTool, p: Vector3, h: float, slot: int, head_slot: int,
		yaw: float, idx: int) -> void:
	var k := h / 1.65
	var top_slot: int = slot if idx % 3 != 0 else CLOTH_SLOTS[(idx * 5) % CLOTH_SLOTS.size()]
	# Fusta / sari: lata jos, stransa la talie.
	_obox(st, p, 0.2 * k, 0.15 * k, 0.82 * k, yaw, slot, Vector2(0.8, 0.8), 0.6)
	# Trunchiul: talia 0,32 m, umerii 0,5 m.
	var waist := p + Vector3.UP * (0.8 * k)
	_obox(st, waist, 0.16 * k, 0.11 * k, 0.56 * k, yaw, top_slot, Vector2(1.5, 1.1), 0.85)
	# Bratele, lipite de umeri, putin departate de trunchi.
	var ax := Vector3(cos(yaw), 0.0, -sin(yaw))
	for sgn in [-1.0, 1.0]:
		var sh := waist + ax * (float(sgn) * 0.29 * k) + Vector3.DOWN * (0.02 * k)
		_obox(st, sh, 0.055 * k, 0.06 * k, 0.56 * k, yaw, top_slot, Vector2(1.2, 1.1), 0.75)
	# Capul (piele) si acoperamantul.
	var head := p + Vector3.UP * (1.38 * k)
	_obox(st, head, 0.1 * k, 0.11 * k, 0.23 * k, yaw, SKIN_SLOT, Vector2(1.0, 1.0), 0.9)
	var cap_slot := head_slot if head_slot >= 0 else HAIR_SLOT
	var cap_h := 0.13 * k if head_slot >= 0 else 0.07 * k
	_obox(st, head + Vector3.UP * (0.2 * k), 0.12 * k, 0.13 * k, cap_h, yaw, cap_slot,
		Vector2(0.75, 0.75), 0.9)


## Stativul unui felinar de la sol: picior subtire, negru, cu o talpa si o
## cutie de felinar (rama) in varf; lumina e in `FortLamps`.
func _stand(st: SurfaceTool, base: Vector3, h: float) -> void:
	_obox(st, base, 0.14, 0.14, 0.05, 0.0, STAND_SLOT, Vector2.ONE, 0.6)
	_obox(st, base, 0.03, 0.03, h, 0.0, STAND_SLOT, Vector2.ONE, 0.7)
	var top := base + Vector3.UP * h
	# Rama felinarului: capac piramidal peste lampa.
	_obox(st, top + Vector3.UP * 0.28, 0.13, 0.13, 0.1, 0.0, STAND_SLOT, Vector2(0.3, 0.3), 0.8)


## Fasie de textile peste strada: franghia lasata in arc intre fatade si
## panze late, lipite, atarnate de ea (bara B: benzi continue roz, verde,
## galben peste strada).
func _strip(st: SurfaceTool, a: Vector3, b: Vector3, idx: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 6151 * (idx + 7)
	var span := b - a
	var hl := Vector2(span.x, span.z).length()
	if hl < 2.0:
		return
	var dir := Vector3(span.x, 0.0, span.z) / hl
	var side := Vector3.UP.cross(dir).normalized()
	var at := func(t: float) -> Vector3:
		return a.lerp(b, t) + Vector3.DOWN * (strip_sag_m * 4.0 * t * (1.0 - t))
	# Franghia.
	var n_seg := 12
	for i in n_seg:
		var p0: Vector3 = at.call(float(i) / float(n_seg))
		var p1: Vector3 = at.call(float(i + 1) / float(n_seg))
		var t := Vector3.UP * 0.035
		_quad(st, p0 - t, p1 - t, p1 + t, p0 + t, ROPE_SLOT, 0.8, 0.8)
	# Panzele: culori care nu se repeta alaturat.
	var x := 0.2
	var k := rng.randi() % CLOTH_SLOTS.size()
	while x < hl - 0.4:
		var w := rng.randf_range(strip_cloth_w.x, strip_cloth_w.y)
		if x + w > hl - 0.2:
			w = hl - 0.2 - x
			if w < 0.5:
				break
		var t0 := x / hl
		var t1 := (x + w) / hl
		var p0: Vector3 = at.call(t0)
		var p1: Vector3 = at.call(t1)
		var hh := rng.randf_range(strip_cloth_h.x, strip_cloth_h.y)
		var sw := side * rng.randf_range(-0.12, 0.12)
		var slot: int = CLOTH_SLOTS[k % CLOTH_SLOTS.size()]
		# Panza cu marginea de jos in dinti (doua triunghiuri pe latime).
		var q0 := p0 + Vector3.DOWN * hh + sw
		var q1 := p1 + Vector3.DOWN * hh + sw
		var qm := (p0 + p1) * 0.5 + Vector3.DOWN * (hh + 0.25) + sw
		_quad(st, p0, p1, q1, q0, slot, 1.0, 0.8)
		_tri(st, q0, q1, qm, slot, 1.0)
		_tri(st, q0, qm, q1, slot, 0.8)
		k += 1 + (rng.randi() % 2)
		x += w + rng.randf_range(strip_gap.x, strip_gap.y)
