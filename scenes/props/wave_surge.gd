extends Node3D
class_name WaveSurge
## Valul care matura causeway-ul (sectorul 8 al pistei Okinawa).
##
## Gimmick-ul sectorului: marea trece PESTE drum la intervale regulate. Nu e un
## obstacol care te opreste — treci prin el — ci un ceas: banda uda de dedesubt
## taie grip-ul, iar valul iti spune CAND. Asta e diferenta fata de furtunul de
## gradina care tinea locul pana acum: furtunul uda mereu, deci nu era o decizie,
## era o taxa.
##
## De ce nu `SlidingHazard`: alea maturi lateral si te IMPING. Valul trece peste
## sosea pe toata latimea, nu are coliziune si nu are pozitie de repaus pe
## margine — sunt doua obiecte diferite care se misca amandoua lateral, si a
## forta unul in altul ar fi insemnat trei steaguri noi in SlidingHazard.
##
## TELEGRAFIEREA (style_bible §7, regula "obstacolul se anunta"): valul intra in
## cadru din larg, cu spuma inainte, si abia dupa aia ajunge pe asfalt. Timpul
## dintre momentul in care se vede si momentul in care ajunge e `LEAD_TIME`, si
## e ce transforma hazardul dintr-o pedeapsa intr-o decizie.

## Cat dureaza o traversare completa, dus-intors. Perioada e lunga DELIBERAT:
## la 4-5 s valul ar fi fost un stroboscop, iar sectorul un slalom. La 9 s, un
## tur normal prinde una sau doua treceri, deci fiecare conteaza.
const PERIOD: float = 9.0
## Cat din perioada valul e efectiv pe drum (restul e in larg, invizibil).
const ON_ROAD_FRAC: float = 0.42
## Cu cat timp inainte de a atinge asfaltul devine vizibil valul.
const LEAD_TIME: float = 1.6

## Latimea maturata, in metri de o parte si de alta a axei drumului.
var sweep: float = 22.0
## Defazaj 0..1, ca doua valuri de pe aceeasi pista sa nu bata la unison.
var phase: float = 0.0
## Directia in care merge valul (versor orizontal, perpendicular pe sosea).
var travel_dir: Vector3 = Vector3.RIGHT
## Cat de sus fata de sosea sta creasta cand trece.
var ride_height: float = -0.35

var _time: float = 0.0
var _model: Node3D
var _foam: Node3D

const MODEL_PATH := "res://assets/models/wave_surge.glb"


func _ready() -> void:
	_build_model()


func _build_model() -> void:
	if not ResourceLoader.exists(MODEL_PATH):
		# Fara GLB, un prisma turcoaz. Faza 1 din #106 e explicit independenta
		# de asset: mecanica trebuie sa poata fi jucata si reglata inainte sa
		# existe modelul.
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(6.0, 1.8, 2.6)
		mi.mesh = box
		mi.position = Vector3.UP * 0.9
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Palette.color(Palette.REEF_SHALLOW)
		mat.roughness = 0.35
		mi.material_override = mat
		_model = mi
		add_child(_model)
		return
	_model = (load(MODEL_PATH) as PackedScene).instantiate() as Node3D
	add_child(_model)
	# Nodul `Wave_Foam` se cauta dupa NUME, ca `Blades` la moara. Daca lipseste,
	# valul merge fara pulsul de spuma in loc sa crape.
	for child in _model.get_children():
		if child.name == "Wave_Foam":
			_foam = child as Node3D
	Palette.apply_world_material(_model)


func _physics_process(delta: float) -> void:
	_time += delta
	var t := fposmod(_time / PERIOD + phase, 1.0)
	# Valul e pe drum doar in prima parte a ciclului; in rest asteapta in larg.
	# Se ascunde in loc sa fie mutat departe: un mesh de 500 de triunghiuri
	# randat degeaba la 60 fps, de doua ori pe pista, nu e gratis pe mobil.
	var visible_now := t < ON_ROAD_FRAC + LEAD_TIME / PERIOD
	if _model != null:
		_model.visible = visible_now
	if not visible_now:
		return
	# Traversare liniara: valul nu accelereaza, si asta e intentionat — un val
	# cu viteza constanta se poate ANTICIPA, iar anticiparea e tot gimmick-ul.
	var u := t / (ON_ROAD_FRAC + LEAD_TIME / PERIOD)
	var offset := lerpf(-sweep, sweep, u)
	position = travel_dir * offset + Vector3.UP * ride_height
	# Fata spre directia de mers: modelul e construit cu fata spre -Y in Blender,
	# adica -Z in Godot.
	if travel_dir.length_squared() > 0.001:
		var target := global_position + travel_dir
		look_at(target, Vector3.UP)
	# Pulsul de spuma: creste cat valul e pe asfalt. Nu e decor — e semnalul
	# vizual care spune "ACUM", si de-aia e pe o piesa separata din GLB.
	if _foam != null:
		var pulse := 1.0 + 0.22 * sin(_time * 6.5)
		_foam.scale = Vector3(1.0, pulse, 1.0)
