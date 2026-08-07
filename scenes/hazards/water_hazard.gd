@tool # vizibil si in preview-ul din editor
class_name WaterHazard
extends Node3D
## Baza comuna a hazardelor de APA: portiunea de sosea pe care apa taie grip-ul.
##
## [b]De ce exista[/b]. Jocul are doua feluri de apa pe drum, si amandoua sunt
## aceeasi mecanica: conducta sparta de pe Dunele care stropeste soseaua, si
## marea care spala digul pe Okinawa. Difera SURSA — o teava care pulseaza pe
## loc, sau un val care trece peste asfalt — nu efectul: banda uda, aquaplanare,
## cronometreaza-ti trecerea. Scris de doua ori, efectul s-ar fi tunat de doua
## ori si ar fi divergat, exact capcana pe care o descrie car.gd cand refoloseste
## acelasi `slip_time` pentru banda uda si pentru hazard.
##
## [b]Ce da baza[/b]: petecul ud (zona care prinde masinile + balta care il face
## vizibil) si bucla care aplica `apply_slip` cat timp e activ. Petecul e COPIL
## al hazardului, deci daca sursa se misca, apa merge cu ea fara nicio linie in
## plus — de-aia valul nu are cod propriu de udat.
##
## [b]Ce datoreaza o varianta[/b]:
##   `_wet_patch_size()` — cat de mare e apa (implicit: latimea soselei)
##   `_build_source()`   — cum arata (model, particule)
##   `_advance(delta)`   — ceasul: curge apa ACUM? Aici isi misca sursa nodul,
##                         daca se misca.
##
## O varianta noua = un fisier care raspunde la cele trei, si o fractie pe pista.

## Latimea soselei in punctul in care e asezat hazardul. Petecul si sursa se
## dimensioneaza din ea — o pista mai lata nu cere alt hazard.
var road_width: float = 14.0

## Materialul peliculei de apa. Daca pista da unul — pe temele cu mare, chiar
## MATERIALUL MARII — apa de pe drum arata ca marea si nu costa niciun material
## in plus: garda numara materialele per pista (vezi CLAUDE.md), iar un albastru
## propriu per hazard e exact felul in care bugetul creste pe nesimtite. Fara el
## (Dunele, desert), ramane un albastru simplu.
##
## Se pune INAINTE de add_child, ca `model` la conducta.
var film_material: Material = null

## Adancimea coapta in vertex colors pentru shaderul marii: 0 = chiar linia
## apei, adica nisip ud cu spuma animata peste el. O foaie de apa care spala un
## drum e, prin definitie, cea mai mica adancime din lume — si tot de acolo vine
## si faptul ca shaderul n-o clatina: anvelopa de valuri e zero la tarm.
const FILM_DEPTH: float = 0.02

var _zone: Area3D
var _puddle: MeshInstance3D
var _wet: bool = false


func _ready() -> void:
	add_to_group("water_hazards")
	_build_wet_patch()
	_build_source()


## Cat de mare e apa, in spatiul LOCAL al hazardului (latime, inaltime, lungime).
## Semantica axelor tine de varianta: conducta o intinde de-a latul soselei,
## valul de-a lungul crestei — nodului nu-i pasa, el doar o asaza.
func _wet_patch_size() -> Vector3:
	return Vector3(road_width + 2.0, 3.0, 4.5)


## La ce inaltime, in spatiul local, sta pelicula de apa. Implicit chiar peste
## asfalt, fiindca hazardul e asezat pe cota soselei.
##
## Exista ca virtuala fiindca o sursa are voie sa stea la ALTA cota decat drumul
## pe care il uda: valul isi ingroapa creasta cu `ride_height` sub asfalt, ca sa
## arate a foaie de apa si nu a caramida plutitoare — iar fara corectia asta
## balta se ingropa odata cu el si nu se mai vedea deloc (prima captura din
## masina arata o pana alba pe nisip uscat).
func _wet_patch_offset() -> float:
	return 0.06


## Sursa vizuala. Implicit nu exista: un hazard fara sursa e apa care apare din
## senin, si e o alegere valida (pe Okinawa banda uda vine din mare, nu dintr-o
## teava — vezi `hose_model: ""` in tema `island`).
func _build_source() -> void:
	pass


## Ceasul variantei. Intoarce `true` cat timp apa e pe drum; tot aici isi misca
## sursa nodul, daca se misca.
func _advance(_delta: float) -> bool:
	return false


func _physics_process(delta: float) -> void:
	var wet := _advance(delta)
	if wet != _wet:
		_wet = wet
		_puddle.visible = wet
	if not wet:
		return
	for body in _zone.get_overlapping_bodies():
		var car := body as Car
		if car != null:
			_touch_car(car, delta)


## Ce pateste o masina care e in apa ACUM. Implicit: aquaplanare.
##
## Virtuala fiindca „ce face apa" difera intre surse, chiar daca „unde e apa" nu:
## o balta de la o teava sparta iti ia doar aderenta, un val care traverseaza
## drumul te si imbranceste si te franeaza. Vezi `WaveSurge._touch_car`.
func _touch_car(car: Car, _delta: float) -> void:
	car.apply_slip()


func _build_wet_patch() -> void:
	var size := _wet_patch_size()
	var lift := _wet_patch_offset()

	_zone = Area3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	# Cutia incepe cu o jumatate de metru sub pelicula: masina sta PE drum, deci
	# colizorul ei incepe la cota apei, iar o zona care ar porni exact de acolo
	# s-ar rata cu un fir de par pe pantele in urcare.
	shape.position = Vector3.UP * (lift + size.y * 0.5 - 0.5)
	_zone.add_child(shape)
	add_child(_zone)

	# Pelicula de apa, vizibila doar cat curge. Are EXACT amprenta zonei, nu una
	# decorativa pe langa ea: pe un hazard de timing, ce vezi trebuie sa fie ce
	# te prinde. (Varianta veche de furtun desena o balta cu 2 m mai ingusta
	# decat zona, deci marginile taiau grip-ul din asfalt curat.)
	_puddle = MeshInstance3D.new()
	_puddle.mesh = _film_mesh(size)
	_puddle.position = Vector3.UP * lift
	if film_material != null:
		_puddle.material_override = film_material
	else:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.55, 0.9, 0.4)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_puddle.material_override = mat
	_puddle.visible = false
	add_child(_puddle)


## Foaia de apa: o ELIPSA plata, nu un dreptunghi.
##
## Forma nu e cosmetica. Un dreptunghi cu colturi drepte pe nisip citeste
## instantaneu ca decal de debug — s-a si vazut asa in prima captura din masina.
## O elipsa n-are colturi de agatat privirea, iar spuma animata a shaderului ii
## rupe si conturul.
##
## Vertex colors: alfa = adancimea (contractul shaderului de apa,
## `assets/shaders/water.gdshader`), rgb = culoarea coapta din v1, folosita doar
## daca pista nu da materialul marii. 14 segmente, adica 28 de triunghiuri —
## primitivele Godot la rezolutia implicita ar fi adus cateva sute pentru o
## balta plata (capcana din CLAUDE.md).
func _film_mesh(size: Vector3) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var col := Color(0.30, 0.55, 0.90, FILM_DEPTH)
	var rx := size.x * 0.5
	var rz := size.z * 0.5
	var segs := 14
	for i in segs:
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		var p0 := Vector3(cos(a0) * rx, 0.0, sin(a0) * rz)
		var p1 := Vector3(cos(a1) * rx, 0.0, sin(a1) * rz)
		# Ordinea (centru, p1, p0) tine fata in sus: shaderul marii e `cull_back`
		# si nu se poate schimba per instanta, deci winding-ul gresit ar fi facut
		# apa invizibila taman din masina.
		for v in [Vector3.ZERO, p0, p1]:
			st.set_color(col)
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	return st.commit()
