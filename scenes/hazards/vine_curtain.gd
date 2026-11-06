class_name VineCurtain
extends Node3D
## PERDEAUA DE LIANE (Angkor, Track24, POI G — docs/track_briefs/angkor.md §2 randul G si §3).
## Hazardul FALS al pistei: de la ~60 m pare un zid verde peste drum, dar nu are coliziune si nu
## franeaza. Prima data ridici piciorul; a doua oara treci cu turbo si te simti destept.
##
## [b]De ce nu `SoftVegetation`.[/b] Registrul tufelor pune frana (`Car.bush_drag`) pe orice masina
## din el — exact ce un hazard fals nu are voie (trecerea de contracte, brief §7 pasul 1). Aici
## frana nu exista prin constructie: suvitele n-au corp, iar declansatorul e un `Area3D` care doar
## ARUNCA frunze (`PropDebris.leaf_burst`) si reda un fosnet. Contractul „viteza la iesire >= 98%”
## e deci adevarat prin constructie; ProbeRace il verifica pe felie.
##
## [b]Un mesh, zero materiale noi.[/b] Toate suvitele sunt coapte intr-un singur `ArrayMesh` pe
## atlasul de paleta (`Palette.world_material()`), cu umbrirea in vertex colors (intuneric sus,
## sub coronament; mai deschis spre varf). Fiecare suvita e o panglica cu ambele fete emise, deci
## nu depinde de cull mode. Verdele e `TROPICAL_GREEN`; o parte sunt radacini aeriene argintii
## (`CORAL_SAND`, brief §4: trunchiurile si radacinile pal-argintii spun „Ta Prohm”).
##
## PLACEHOLDER de geometrie pana la suvitele de asset (brief §5.4, pasul 8): legănarea in shader
## vine atunci, cu MultiMesh-ul ei. Mecanica (fara coliziune + declansatorul) ramane.
##
## Coordonate locale: nodul sta pe axa soselei, la cota asfaltului; -Z local = directia de mers
## (`looking_at` spre drum), X local = de-a curmezisul.

const PropDebris := preload("res://scenes/props/prop_debris.gd")

## Latimea perdelei de-a curmezisul drumului (m). Mai lata decat banda, ca marginile sa nu lase
## o fanta prin care se vede ca e decor.
@export var width: float = 13.0
## Cota de sus a suvitelor peste asfalt (m): creanga din care atarna.
@export var top: float = 5.0
## Cel mai jos varf de suvita peste asfalt (m). Sub capota (~1 m), ca masina sa intre in ele.
@export var bottom: float = 0.7
## Cat variaza lungimea suvitelor in sus fata de `bottom` (m): marginea de jos zdrentuita.
@export var bottom_jitter: float = 1.6
## Randuri pe directia de mers si distanta dintre ele (m). Prima captura `--gamecam` (3 randuri,
## suvite de 0,16 m) citea ca un pieptene rar, nu ca zid: camera de joc priveste de sus (10 m),
## deci suvitele verticale se vad scurtate, iar golurile dintre ele raman drum vizibil.
@export_range(1, 6) var rows: int = 4
@export var row_gap: float = 1.1
## Pasul dintre suvite intr-un rand si latimea lor (m). Latimea de 0,30 la pasul de 0,36, in
## 4 randuri decalate cu pas/4, se suprapune (contractul brief §3: >= 60% din
## latimea benzii la 40 m).
@export var spacing: float = 0.36
@export var strand_width: float = 0.30
## Ce fractie din suvite sunt radacini aeriene argintii (restul liane verzi).
@export_range(0.0, 1.0, 0.01) var root_share: float = 0.12
## Grosimea crengii de sus (m) — trunchiul argintiu din care atarna totul.
@export var branch_thick: float = 0.55
@export var seed_salt: int = 70

@export_group("Declansator")
## Culoarea frunzelor aruncate la trecere.
@export var burst_tint: Color = Color(0.20, 0.30, 0.12)
## Sub viteza asta (m/s) nu se arunca frunze (o masina care se taraste nu sfasie perdeaua).
@export var burst_min_speed: float = 4.0
## Pauza minima intre doua rafale ale ACELEIASI masini (s).
@export var cooldown: float = 0.6

## Pentru sonde: cate rafale s-au declansat si cate masini au trecut prin declansator.
var burst_count: int = 0
var pass_count: int = 0

var _last_burst: Dictionary = {}   # instance_id -> timp (s)


func _ready() -> void:
	_build_strands()
	if not Engine.is_editor_hint():
		_build_trigger()


func _build_strands() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_salt)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := width * 0.5
	var n := maxi(2, int(width / spacing))
	for r in rows:
		var z := (float(r) - float(rows - 1) * 0.5) * row_gap
		var shift := spacing * float(r) / float(rows)
		for k in n:
			var x := -half + shift + spacing * float(k) + rng.randf_range(-0.08, 0.08)
			if x > half:
				continue
			var is_root := rng.randf() < root_share
			var slot := Palette.CORAL_SAND if is_root else Palette.TROPICAL_GREEN
			var w := strand_width * (0.7 if is_root else rng.randf_range(0.8, 1.3))
			var tip := bottom + rng.randf() * rng.randf() * bottom_jitter
			var zz := z + rng.randf_range(-0.25, 0.25)
			# Usoara inclinare (vant, crestere): varful se abate cu cativa cm.
			var lean := Vector3(rng.randf_range(-0.12, 0.12), 0.0, rng.randf_range(-0.15, 0.15))
			_ribbon(st, Vector3(x, top, zz), Vector3(x, tip, zz) + lean, w, slot)
	# Creanga de sus: o grinda argintie peste toata latimea, umbrita.
	_beam(st, Vector3(-half - 1.0, top + branch_thick * 0.3, 0.0),
		Vector3(half + 1.0, top + branch_thick * 0.3, 0.0), branch_thick, Palette.CORAL_SAND)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Suvite"
	mi.mesh = st.commit()
	mi.material_override = Palette.world_material()
	# Fara umbra: sute de panglici subtiri ar costa umbra si ar desena pe sosea o pata, nu suvite.
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## O panglica de la `a` (sus) la `b` (varf), ingustata spre varf, cu AMBELE fete.
func _ribbon(st: SurfaceTool, a: Vector3, b: Vector3, w: float, slot: int) -> void:
	var uv := Palette.uv(slot)
	var side := Vector3(w * 0.5, 0.0, 0.0)
	var tip_side := side * 0.35
	var quad: Array[Vector3] = [a - side, a + side, b + tip_side, b - tip_side]
	# Intuneric sus (sub coronament), mai deschis spre varf — SurfaceTool doar intuneca.
	var shade: Array[float] = [0.45, 0.45, 0.95, 0.95]
	for tri: Array in [[0, 1, 2], [0, 2, 3], [0, 2, 1], [0, 3, 2]]:
		for k: int in tri:
			st.set_uv(uv)
			st.set_color(Color(shade[k], shade[k], shade[k]))
			st.add_vertex(quad[k])


## O grinda patrata (creanga) intre `a` si `b`.
func _beam(st: SurfaceTool, a: Vector3, b: Vector3, t: float, slot: int) -> void:
	var uv := Palette.uv(slot)
	var h := t * 0.5
	var c: Array[Vector3] = [
		Vector3(0, -h, -h), Vector3(0, h, -h), Vector3(0, h, h), Vector3(0, -h, h)]
	for f in 4:
		var p0 := a + c[f]
		var p1 := a + c[(f + 1) % 4]
		var p2 := b + c[(f + 1) % 4]
		var p3 := b + c[f]
		var shade := 0.85 if f == 1 else 0.6
		for tri: Array in [[0, 1, 2], [0, 2, 3], [0, 2, 1], [0, 3, 2]]:
			for k: int in tri:
				st.set_uv(uv)
				st.set_color(Color(shade, shade, shade))
				st.add_vertex([p0, p1, p2, p3][k])


func _build_trigger() -> void:
	var area := Area3D.new()
	area.name = "Declansator"
	area.monitorable = false
	# Masinile sunt pe stratul implicit (1); BumpProp e pe stratul 9 si nu ne intereseaza.
	area.collision_mask = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, 3.0, float(rows) * row_gap + 1.0)
	cs.shape = box
	cs.position = Vector3(0.0, 1.5, 0.0)
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not (body is Car):
		return
	pass_count += 1
	var car := body as Car
	var v := car.linear_velocity
	var speed := Vector2(v.x, v.z).length()
	if speed < burst_min_speed:
		return
	var now := Time.get_ticks_msec() / 1000.0
	var id := car.get_instance_id()
	if now - float(_last_burst.get(id, -1000.0)) < cooldown:
		return
	_last_burst[id] = now
	burst_count += 1
	var dir := Vector3(v.x, 0.0, v.z).normalized() * 0.5 + Vector3.UP
	var k := clampf(inverse_lerp(burst_min_speed, 30.0, speed), 0.2, 1.0)
	PropDebris.leaf_burst(get_tree(), car.global_position + Vector3.UP * 1.4, dir, k, burst_tint)
	if car.is_player:
		AudioManager.play_sfx_at(&"roll_grass", car.global_position, 1.3, -8.0, 0)
