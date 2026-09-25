@tool
class_name FoamPoolG
extends Node3D
## Bazin de spumă albă la baza cascadei Bowen (POI G, Fiordland).
##
## Copie locală a tiparului `foam_pool.gd` (POI C — Stirling), pe branch
## `fiord/poi-c`, neintegrat încă (`fiord/poi-integrare` nu-l are la data
## acestei runde — brief-ul §G permite explicit `PaletteBox FOAM_WHITE` direct
## pe acest tipar). Nume de clasă distinct (`FoamPoolG`) ca să nu coliziune
## cu `FoamPool` la integrare, când cele două ramuri se unesc — la promovare/
## curățenie finală cele două pot fi unificate într-o singură clasă.
##
## Compoziție (aranjamentul-bate-numarul): petice joase + movile mai înalte
## suprapuse cu jitter, pe slotul FOAM_WHITE (22) — zero material nou.
## Coliziune NICIUNA (`suprafete-cu-goluri-si-praguri`): decor pur, ca placa
## de spumă a `WaterfallVisual` pe care o completează vizual la distanță.

const FOAM_SLOT: int = 22   # Palette.FOAM_WHITE


func build(patch_count: int, radius: float, seed: int) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in patch_count:
		var ang := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(0.0, radius)
		var at := Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
		var tall := rng.randf() < 0.45
		var w := rng.randf_range(1.1, 2.1)
		var d := rng.randf_range(1.0, 1.9)
		var h := rng.randf_range(0.5, 0.95) if tall else rng.randf_range(0.18, 0.35)
		var yaw := rng.randf_range(0.0, TAU)
		var mi := PaletteBox.instance(Vector3(w, h, d), FOAM_SLOT,
			at + Vector3.UP * h * 0.5, Basis(Vector3.UP, yaw))
		mi.name = "Petic%d" % i
		add_child(mi)
	var core := PaletteBox.instance(Vector3(radius * 1.1, 0.4, radius * 0.9),
		FOAM_SLOT, Vector3.UP * 0.2)
	core.name = "Miez"
	add_child(core)


func _ready() -> void:
	if patch_count > 0 and get_child_count() == 0:
		build(patch_count, radius, rng_seed)


@export var patch_count: int = 8
@export var radius: float = 3.0
@export var rng_seed: int = 0
