@tool
extends Node3D
## Moara de vant — prop "hero" animat, pe pipeline-ul "diorama".
##
## GLB-ul (assets/models/windmill.glb) vine din Blender cu DOUA noduri: turnul
## static si roata de pale, numita exact [b]Blades[/b]. Roata e nod separat tocmai
## ca sa nu avem nevoie de animatie bake: o rotim din script, ceea ce pe mobil e
## mai ieftin si ne lasa sa controlam viteza. Pivotul ei e in centrul butucului,
## iar geometria sta in planul local XY -> se invarte curat pe axa locala +Z.
##
## Ca la orice prop de atlas: materialul propriu e inlocuit cu cel UNIC al lumii,
## altfel iese alb si pierdem gruparea in draw call-uri (vezi docs/blender_export.md).
##
## Asezare de mana: pune noduri Windmill sub containerul "ManualDecor" al pistei.

const BLADES_NODE: StringName = &"Blades"

## Rotatii pe minut. Lent, de fundal — o moara reala de ferma se invarte calm, iar
## viteza mare ar atrage ochiul in apexul virajelor (style_bible §7).
@export var rpm: float = 8.0
## Axa locala a rotii. +Z e ce garanteaza brief-ul si scriptul de build.
@export var axis: Vector3 = Vector3(0, 0, 1)
## Decalaj de faza, ca doua mori asezate langa acelasi viraj sa nu fie sincronizate.
@export_range(0.0, 360.0, 1.0) var phase_offset_deg: float = 0.0

var _blades: Node3D


func _ready() -> void:
	Palette.apply_world_material(self)
	_blades = find_child(String(BLADES_NODE), true, false) as Node3D
	if _blades == null:
		push_warning("Windmill: nu am gasit nodul '%s' in GLB — roata ramane statica."
			% BLADES_NODE)
		set_process(false)
		return
	if not is_zero_approx(phase_offset_deg):
		_blades.rotate(axis.normalized(), deg_to_rad(phase_offset_deg))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return # nu murdarim scena salvata din editor; se roteste doar la runtime
	_blades.rotate(axis.normalized(), deg_to_rad(rpm * 6.0) * delta) # rpm*6 = grade/s
