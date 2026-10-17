class_name GhostCar
extends Node3D
## Fantoma redata in contratimp: doar MODELUL masinii cu care s-a facut
## recordul, semitransparent, fara nicio coliziune. E Node3D (nu RigidBody3D),
## deci nu poate atinge nimic si nu intra in fizica; AI-ul nu ruleaza oricum in
## contratimp.
##
## Ceasul vine de la Race (`set_clock_ms`), nu din delta proprie: fantoma si
## cronometrul jucatorului sunt acelasi ceas, deci nu pot deriva.

const ALPHA: float = 0.45

var data: GhostData


func setup(ghost: GhostData) -> void:
	data = ghost
	var car_data := GameState.CAR_DATA[clampi(ghost.car_index, 0,
		GameState.CAR_DATA.size() - 1)] as CarData
	var model := Car.build_model(car_data)
	if model == null:
		return
	add_child(model)
	# UN singur material pentru toata fantoma (draw calls). Modelele din
	# pipeline-ul nostru pornesc de la materialul de clasa (atlas + AO);
	# FBX-urile RgsDev n-au atlas, deci primesc culoarea masinii.
	var mat: StandardMaterial3D
	if car_data.palette_model:
		mat = Palette.world_material().duplicate() as StandardMaterial3D
	else:
		mat = StandardMaterial3D.new()
		mat.albedo_color = car_data.color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = ALPHA
	_apply(model, mat)


func _apply(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_apply(child, mat)


## Race il cheama in fiecare tick de cursa (si cu 0 la GO).
func set_clock_ms(ms: float) -> void:
	if data != null and is_inside_tree():
		global_transform = data.transform_at(ms)

