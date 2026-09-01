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

@export_group("Intuneric")
## Cat de mult se stinge lumina lumii inauntru: 0 = nimic, 1 = bezna cu torte.
##
## [b]De ce zona asta si nu un nod separat.[/b] Prima constructie a POI-ului F
## a pus tavan, pereti si coloane, si captura de sofer de la frac 0.68 a iesit
## tot o hala portocalie, luminata uniform: soarele de zori (energie 0.85,
## expunere 1.15) intra pe la capete si ambientul pistei lumina la fel de tare
## sub pamant ca pe platou. Referinta (`img/v3_crops/F_underground.png`) e
## exact pe dos — un spatiu aproape negru in care singurele pete calde sunt
## tortele. Adica INCHIDEREA se face din lumina, nu doar din geometrie: cu
## ambientul pistei aprins, orice sala ramane o pergola, oricat perete i-ai pune.
##
## Se pune AICI fiindca zona asta e deja fix conturul cavernei — e nodul care
## stie ca esti sub pamant, si care are deja lerp-ul de intrare/iesire. Un al
## doilea nod pe aceleasi coordonate ar fi trebuit tinut sincron de mana, iar
## la prima mutare a gurii unul din doua ar fi ramas in urma.
##
## Tiparul (citit `Environment` o data, pus la loc de fiecare data) e cel din
## [FogCorridorHazard]: mediul e UNUL pe scena, deci se uita numai dupa masina
## jucatorului si isi reface valorile la iesire — altfel prima trecere prin
## caverna ar schimba definitiv atmosfera pistei.
@export_range(0.0, 1.0, 0.01) var darkness: float = 0.0
## Culoarea ambientului dinauntru.
##
## SLAB SATURATA, si asta e o corectie masurata, nu o preferinta. Prima varianta
## era portocaliul de torta din brief §4 (1.0, 0.62, 0.34) — dar el se INMULTESTE
## peste sloturi care sunt deja brune calde (ROCK_DARK #67421F sat 0.54,
## SAND_SHADOW #915D27 sat 0.58), iar captura de la frac 0.68 a iesit o mocirla
## rosie uniforma. Referinta (`v3_crops/F_underground.png`) are piatra
## GRI-BEJ RECE, si tot ce e cald in cadru vine din flacari. Portocaliul apartine
## deci tortelor (care il au in emisie), nu aerului.
@export var cave_ambient: Color = Color(0.72, 0.70, 0.72)
## Cat de departe se mai vede in caverna (m). Ceata inchisa e ce ascunde
## capetele salilor si opreste cerul sa se vada prin gura de la celalalt capat.
@export_range(10.0, 400.0, 1.0) var cave_fog_end: float = 95.0
## Cata lumina ambientala ramane inauntru.
##
## Nu zero, si nu din blandete: la 0.10 captura de la frac 0.672 a iesit cu
## peretii aproape negri, iar coloanele si alcovele — adica tot ce s-a construit
## — dispareau. Referinta (`v3_crops/F_underground.png`) are piatra CITIBILA
## peste tot si tortele ca accente peste ea; o pestera in care nu se vede nimic
## nu e mai apropiata de referinta decat una luminata ca ziua, doar gresita in
## cealalta directie. 0.30 lasa relieful si AO-ul copt sa se citeasca.
@export_range(0.0, 2.0, 0.01) var cave_ambient_energy: float = 0.30

## Culoarea cetei din caverna — adica CE CULOARE AU DEPARTARILE.
##
## Era `(0.10, 0.07, 0.06)`, un brun cald, si asta a fost chiar defectul pe care
## l-au numit independent toti cei patru critici ai rundei 2: „o singura nuanta
## pe toata adancimea cadrului". Ceata e ce vopseste tot ce e departe, iar in
## familia pietrei ea sterge tocmai separarea de plan. Perspectiva aeriana merge
## invers: departarile se RACESC.
##
## Masurat pe capturile de baza (`R4base_*`): peretele apropiat avea luminanta
## 23.5 si capatul salii 38.4 — adica departarea era mai LUMINOASA si la fel de
## calda, exact pe dos fata de referinta. Cu ceata rece si mai inchisa,
## adancimea se citeste din nuanta, nu doar din marime.
##
## Se declara O SINGURA data fiindca `_darken` si `force_dark` o foloseau
## amandoua, copiata — doua locuri din care se putea schimba doar unul.
const CAVE_FOG := Color(0.055, 0.062, 0.085)

var _shape: CollisionShape3D
var _env: Environment
## Valorile pistei, luate O DATA si puse la loc de fiecare data.
var _base: Dictionary = {}
var _amount: float = 0.0


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


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var inside := _player_inside()
	_push(inside)
	_darken(inside, delta)


## Stinge lumina lumii cat esti in caverna, si o pune la loc la iesire.
##
## Lerp pe TIMP, cu acelasi `blend_time` ca presetul de camera: intunericul si
## unghiul camerei sunt acelasi eveniment (pragul gurii), deci daca ar merge pe
## ceasuri diferite s-ar vedea ca doua schimbari, nu ca una.
func _darken(inside: bool, delta: float) -> void:
	if darkness <= 0.0:
		return
	if _env == null:
		_env = _find_env()
		if _env == null:
			return
		# O SINGURA data, si de pe pista curata: daca s-ar reciti in timp ce
		# zona e activa, "valorile pistei" ar deveni valorile cavernei si
		# iesirea n-ar mai avea unde sa se intoarca.
		_base = {
			"amb_color": _env.ambient_light_color,
			"amb_energy": _env.ambient_light_energy,
			"amb_sky": _env.ambient_light_sky_contribution,
			"fog_end": _env.fog_depth_end,
			"fog_color": _env.fog_light_color,
			"fog_enabled": _env.fog_enabled,
		}
	var target := 1.0 if inside else 0.0
	var speed := 1.0 / maxf(blend_time, 0.05)
	_amount = move_toward(_amount, target, speed * delta)
	var k := _amount * darkness
	_env.ambient_light_color = (_base["amb_color"] as Color).lerp(cave_ambient, k)
	_env.ambient_light_energy = lerpf(_base["amb_energy"], cave_ambient_energy, k)
	# Cerul nu are ce cauta sub pamant: contributia lui e chiar lumina care
	# facea sala sa arate ca o pergola in soare.
	_env.ambient_light_sky_contribution = lerpf(_base["amb_sky"], 0.0, k)
	_env.fog_enabled = true
	_env.fog_depth_end = lerpf(_base["fog_end"], cave_fog_end, k)
	# Ceata inchisa, in culoarea pietrei: ea inghite capetele salilor si opreste
	# cerul sa se vada prin gura de la celalalt capat.
	_env.fog_light_color = (_base["fog_color"] as Color).lerp(
		CAVE_FOG, k)
	if _amount <= 0.0:
		_env.fog_enabled = _base["fog_enabled"]


## Aduce intunericul direct la plin, fara lerp — pentru capturi (`Snapshot
## --cave`), unde nu exista masina care sa intre in zona si deci nici cadre in
## care sa se stinga lumina treptat. Vezi `cave_view` din tools/snapshot.gd.
func force_dark() -> void:
	if darkness <= 0.0:
		return
	if _env == null:
		_env = _find_env()
		if _env == null:
			return
		_base = {
			"amb_color": _env.ambient_light_color,
			"amb_energy": _env.ambient_light_energy,
			"amb_sky": _env.ambient_light_sky_contribution,
			"fog_end": _env.fog_depth_end,
			"fog_color": _env.fog_light_color,
			"fog_enabled": _env.fog_enabled,
		}
	_amount = 1.0
	var k := darkness
	_env.ambient_light_color = (_base["amb_color"] as Color).lerp(cave_ambient, k)
	_env.ambient_light_energy = lerpf(_base["amb_energy"], cave_ambient_energy, k)
	_env.ambient_light_sky_contribution = lerpf(_base["amb_sky"], 0.0, k)
	_env.fog_enabled = true
	_env.fog_depth_end = lerpf(_base["fog_end"], cave_fog_end, k)
	_env.fog_light_color = (_base["fog_color"] as Color).lerp(
		CAVE_FOG, k)


func _find_env() -> Environment:
	var we := _first_world_env(get_tree().root)
	return we.environment if we != null else null


func _first_world_env(n: Node) -> WorldEnvironment:
	if n == null:
		return null
	if n is WorldEnvironment:
		return n as WorldEnvironment
	for c in n.get_children():
		var found := _first_world_env(c)
		if found != null:
			return found
	return null


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
