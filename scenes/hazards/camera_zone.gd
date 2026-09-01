@tool
class_name CameraZone
extends Area3D
## Zona care schimba PRESETUL CAMEREI cat esti inauntru (Cappadocia §2.0, §3):
## in cavern, camera coboara si se uita mai sus, ca sa se vada tavanul.
##
## [b]De ce exista.[/b] `ChaseCamera` sta la 10 m si priveste in jos cu 28.7°.
## Marginea de sus a frustumului iese la doar ~+5° peste orizontala, deci un
## tavan de 15 m intra in cadru abia de la ~54 m: intr-o sala subterana n-ai
## vedea niciodata bolta, doar podeaua venind spre tine. Presetul coboara
## camera la 6.5 m si ridica tinta la 1.4 m (panta scade la 16.2°) si largeste
## FOV-ul cu 6°, iar marginea de sus urca la ~+21° — tavanul intra de la ~22 m.
## Cifrele sunt masurate in `tools/ProbeCavecam.tscn`, nu presupuse.
##
## [b]Nu scrie in `@export`-urile camerei.[/b] Capcana e `apply_settings_for`:
## panoul de setari recalculeaza `distance`/`height`/`base_fov` din factorii
## jucatorului ORI DE CATE ORI misca un slider, inclusiv in timpul cursei. Un
## preset care ar scrie `height = 6.5` ar fi sters tacut la prima atingere de
## slider. De aia zona trimite camerei un preset ca DATE
## (`ChaseCamera.push_preset`), iar camera il aplica peste rezultatul setarilor,
## in fiecare cadru. Setarile raman ale jucatorului, presetul ramane al lumii.
##
## [b]Lerp pe TIMP, nu pe adancime[/b] — si e o abatere deliberata de la
## [FogCorridorHazard], care masoara adancimea in culoar tocmai ca doi soferi
## cu viteze diferite sa vada aceeasi ceata in acelasi loc. Aici invers: gura
## cavernei e un PRAG, iar tranzitia e un moment in sine (brief §2.0). Legata
## de adancime, o masina cu 30 m/s ar termina tranzitia in 3 m si ar citi ca un
## pocnet; legata de timp, orice viteza primeste aceeasi jumatate de secunda.
##
## [b]Presetul e o CERINTA, nu trei numere.[/b] Cotele 6.5 / 1.4 / +6 sunt
## solutia pe camera implicita; ce cere briefu e insa geometric ("tavanul de
## 15 m se vede de la 25 m"), iar cele doua coincid doar cu sliderele pe 1.0.
## Prima versiune trimitea doar numerele, si atunci presetul se aduna peste
## preferinta jucatorului: cu `cam_fov_scale` la minimul legal (0.7) tavanul
## intra abia de la 45.6 m in loc de 22.4, iar cu camera trasa la 0.5 nici FOV-ul
## implicit nu ajungea. Pe grila legala a sliderelor pica aproape jumatate din
## spatiu — adica pentru o buna parte din reglajele permise POI-ul subteran era
## un tavan negru. Acum zona trimite si CERINTA (`ceiling`, `ceiling_dist`), iar
## [ChaseCamera.solve_preset] rezolva cotele pentru sliderele reale.
##
## [b]Cost zero.[/b] Fara masca de coliziune si fara `monitorable`: zona
## raporteaza cine e inauntru, nu opreste si nu imbranceste pe nimeni. Se uita
## doar dupa masina jucatorului (`is_player`) — camera e una singura, deci un
## AI care intra in cavern n-are de ce sa miste cadrul cuiva de pe platou.

## Semi-dimensiunile zonei (m). Cutia e centrata pe nod, ridicata cu jumatate
## din inaltime, ca originea sa se aseze pe drum.
@export var size: Vector3 = Vector3(10.0, 8.0, 12.0):
	set(value):
		size = value
		_rebuild()

@export_group("Preset")
## Inaltimea camerei inauntru (m). Implicit 10.0 afara.
@export_range(2.0, 20.0, 0.1) var height: float = 6.5
## Inaltimea TINTEI pe masina (m). Implicit 0.40 afara. Ridicarea ei e ce
## inclina efectiv privirea in sus — vezi `ChaseCamera._aim_point`.
@export_range(0.0, 5.0, 0.05) var look_height: float = 1.4
## Cat se adauga la FOV (grade). E o PREFERINTA, nu o garantie: cerinta de mai
## jos poate cere mai mult, si atunci castiga ea (vezi `ChaseCamera.solve_preset`).
@export_range(-20.0, 20.0, 0.5) var fov_bonus: float = 6.0
## Durata tranzitiei, la intrare si la iesire (s).
@export_range(0.05, 3.0, 0.05) var blend_time: float = 0.5

@export_group("Cerinta geometrica")
## Inaltimea tavanului care TREBUIE sa se vada (m). 0 = fara garantie, presetul
## ramane pur aditiv.
##
## Asta e diferenta intre un preset si o garantie. Cotele de mai sus (6.5 / 1.4
## / +6) sunt solutia gasita pe camera IMPLICITA; cerinta din brief (§2.0) e
## insa geometrica — "tavanul de 15 m se vede de la 25 m" — si cele doua se
## suprapun doar cand sliderele jucatorului sunt pe 1.0. Cu ele declarate aici,
## camera REZOLVA cotele pentru sliderele reale, in loc sa le copieze.
@export_range(0.0, 40.0, 0.5) var ceiling: float = 15.0
## De la ce distanta trebuie sa se vada tavanul (m).
@export_range(0.0, 200.0, 1.0) var ceiling_dist: float = 25.0

var _shape: CollisionShape3D


func _ready() -> void:
	# Vezi antetul: zona doar RAPORTEAZA. Fara masca proprie nu opreste nimic.
	monitorable = false
	_rebuild()


func _rebuild() -> void:
	if _shape == null:
		_shape = CollisionShape3D.new()
		_shape.name = "Zone"
		add_child(_shape)
	var box := _shape.shape as BoxShape3D
	if box == null:
		box = BoxShape3D.new()
		_shape.shape = box
	box.size = size
	_shape.position = Vector3.UP * (size.y * 0.5)


func preset() -> Dictionary:
	return {
		"height": height,
		"look_height": look_height,
		"fov_bonus": fov_bonus,
		"ceiling": ceiling,
		"ceiling_dist": ceiling_dist,
	}


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_push(_player_inside())


func _player_inside() -> bool:
	for body in get_overlapping_bodies():
		var car := body as Car
		if car != null and car.is_player:
			return true
	return false


## Presetul ajunge la camera prin GRUP, nu prin referinta: zona e pusa in
## `.tscn`-ul pistei, iar camera se naste in `race.gd` abia la start si nu e
## copilul nimanui din pista. Aceeasi cale pe care o foloseste si panoul de
## setari (`refresh_from_settings`).
func _push(inside: bool) -> void:
	get_tree().call_group(ChaseCamera.GROUP, &"set_zone_preset",
		preset() if inside else {}, blend_time, get_instance_id())
