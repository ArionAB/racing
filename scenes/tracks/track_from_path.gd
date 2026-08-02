@tool
class_name TrackFromPath
extends Track
## Pista custom editabila VIZUAL in editorul Godot:
##  1. deschide scena (ex. Track04.tscn)
##  2. selecteaza nodul copil "Path" — apar gizmo-urile curbei in viewport
##  3. trage punctele / adauga puncte noi (toolbar-ul Path3D de sus)
##  4. bifeaza "Regenerate" in Inspector pe nodul radacina -> pista se
##     reconstruieste pe loc (asfalt, pereti, borduri, decor, tot)
##  5. salveaza scena — doar curba se salveaza; restul se genereaza mereu
##
## Nota: generatorul isi face propriile tangente netede (Catmull-Rom) din
## POZITIILE punctelor — manerele bezier ale curbei sunt ignorate.

@export var custom_name: String = "Atelier"
@export_enum("forest", "desert", "island") var custom_theme: String = "forest"
@export var custom_half_width: float = 7.0
## Cota marii, RELATIV la media cotelor soselei (doar tema "island").
## Vezi Track.sea_level_offset — nu e o cota absoluta in lume.
@export var custom_sea_level_offset: float = -7.0
@export var custom_ramp_fracs: Array[float] = []
@export var custom_hazard_fracs: Array[float] = []
## Conducta sparta care pulseaza apa peste drum (fractii 0..1).
@export var custom_hose_fracs: Array[float] = []
## Situl cu schelet de dinozaur: fiecare Vector2 = (fractie, parte ±1).
@export var custom_dino_spots: Array[Vector2] = []
## Arcade de stanca prin care trece soseaua (fractii 0..1).
@export var custom_arch_fracs: Array[float] = []
## Intrari de mina lipite de perete: fiecare Vector2 = (fractie, parte ±1).
@export var custom_mine_spots: Array[Vector2] = []
## Caruselul: morisca cu vane care matura soseaua (gimmick de timing).
@export var custom_carousel_fracs: Array[float] = []
## Deviatorul: bariera oblica care iti schimba traiectoria (gimmick de linie).
@export var custom_deflector_fracs: Array[float] = []
## Creasta de fly-off: te arunca in aer, cu plasa de respawn dedesubt.
@export var custom_flyoff_fracs: Array[float] = []
## Landmark-uri hero: fiecare Vector3 = (fractie, parte ±1, id-model din
## _LANDMARKS: 0=turn apa, 1=benzinarie, 2=moara, 3=semn Route 66,
## 4=ecran drive-in, 5=stalp GAS).
@export var custom_landmarks: Array[Vector3] = []
## Rapele: (frac_start, frac_end, adancime_m, latura ±1 sau 0 = ambele).
## Terenul urmareste soseaua peste tot; aici il sapam inapoi, ca sa existe unde
## sa cazi. Fara o rapa sub un fly-off, zbori si aterizezi linistit pe nisip.
@export var custom_ravines: Array[Vector4] = []
## Bolovani care cad de pe faleza.
@export var custom_rockfall_fracs: Array[float] = []
## Treceri de cale ferata. Trenul ucide la contact si te repune.
@export var custom_train_fracs: Array[float] = []
## Bifeaza ca sa reconstruiesti pista din curba (doar in editor).
@export var regenerate: bool = false:
	set(_value):
		regenerate = false
		if Engine.is_editor_hint() and is_inside_tree():
			_apply_custom()
			_ensure_starter_curve()
			rebuild()

func _ready() -> void:
	_apply_custom()
	_ensure_starter_curve()
	super._ready()

func _apply_custom() -> void:
	track_name = custom_name
	half_width = custom_half_width
	sea_level_offset = custom_sea_level_offset
	apply_theme(custom_theme)

func _points() -> Array[Vector3]:
	var path := get_node_or_null("Path") as Path3D
	var pts: Array[Vector3] = []
	if path != null and path.curve != null:
		for i in path.curve.point_count:
			pts.append(path.curve.get_point_position(i))
	return pts

func _ramp_fracs() -> Array[float]:
	return custom_ramp_fracs

func _hazard_fracs() -> Array[float]:
	return custom_hazard_fracs

func _hose_fracs() -> Array[float]:
	return custom_hose_fracs

func _dino_spots() -> Array[Vector2]:
	return custom_dino_spots

func _arch_fracs() -> Array[float]:
	return custom_arch_fracs

func _mine_spots() -> Array[Vector2]:
	return custom_mine_spots

func _carousel_fracs() -> Array[float]:
	return custom_carousel_fracs

func _deflector_fracs() -> Array[float]:
	return custom_deflector_fracs

func _flyoff_fracs() -> Array[float]:
	return custom_flyoff_fracs

func _landmark_spots() -> Array[Vector3]:
	return custom_landmarks

func _ravines() -> Array[Vector4]:
	return custom_ravines

func _rockfall_fracs() -> Array[float]:
	return custom_rockfall_fracs

func _train_fracs() -> Array[float]:
	return custom_train_fracs

## Daca curba lipseste sau are prea putine puncte, o umplem cu un circuit
## de pornire decent — ai de unde sa incepi sa tragi de puncte.
func _ensure_starter_curve() -> void:
	var path := get_node_or_null("Path") as Path3D
	if path == null:
		path = Path3D.new()
		path.name = "Path"
		add_child(path)
		if Engine.is_editor_hint():
			path.owner = get_tree().edited_scene_root
	if path.curve != null and path.curve.point_count >= 3:
		return
	var starter := Curve3D.new()
	for p in [Vector3(0, 0, 0), Vector3(70, 0, 0), Vector3(110, 2, -35),
			Vector3(105, 5, -85), Vector3(60, 2, -115), Vector3(-10, 0, -110),
			Vector3(-50, 3, -75), Vector3(-45, 1, -30)]:
		starter.add_point(p)
	path.curve = starter
