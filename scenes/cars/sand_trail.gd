class_name SandTrail
extends MultiMeshInstance3D
## Urma pe care o lasa o masina care RULEAZA pe teren afanat: drum de pamant,
## nisip de plaja, umarul de pietris. Nu are legatura cu drift-ul.
##
## ############################################################################
## DE CE NU NODURI, CA LA URMELE DE DRIFT
##
## Urmele de cauciuc din drift (Car._drop_skid_marks) sunt cate un
## MeshInstance3D per pata, cu tween de stingere. Acolo e alegerea corecta: se
## depun rar (doar cat tii handbrake-ul) si TREBUIE sa dispara, ca turul urmator
## sa gaseasca asfalt curat.
##
## Aici se depun cat timp masina merge. La 35 m/s si un pas de 2.2 m ies ~16
## depuneri pe secunda, adica 32 de noduri cu cate un tween fiecare, per masina,
## ori cinci masini in cursa. Acelasi tipar ar fi facut din urme cel mai scump
## efect din joc — si ar fi lovit fix bugetul care conteaza pe mobil.
##
## Un MultiMesh cu INEL de instante costa un singur desen, zero alocari in timpul
## cursei si zero tween-uri: cand se umple, se rescrie slotul cel mai vechi.
## Stingerea nici nu e nevoie — pe pamant urmele NU dispar de la sine, iar inelul
## e dimensionat (CAPACITY / 2 depuneri x TRAIL_SPACING) sa tina o dara mai lunga
## decat vede camera in urma, deci reciclarea se intampla afara din cadru.
## ############################################################################

## Cate instante are inelul. 160 = 80 de depuneri x 2 roti; la pasul de 2.2 m din
## [code]Car.TRAIL_SPACING[/code] inseamna ~176 m de dara. Camera de urmarire
## vede in urma zeci de metri, nu sute, deci capatul care se rescrie e mereu in
## spatele privirii.
const CAPACITY: int = 160

## Latimea urmei (anvelopa) si lungimea unei placute, in metri.
##
## Lungimea e mai MARE decat pasul de depunere (2.2 m), si trebuie sa fie:
## placutele se suprapun putin, altfel dara ar fi un sir de dungi cu pauze intre
## ele — exact artefactul care spune "particule", nu "urma".
const MARK_SIZE: Vector2 = Vector2(0.34, 2.6)

## Cat de opaca e urma, peste alfa texturii (max 0.55). 0.8 x 0.55 = 0.44 in
## varf: se citeste clar pe pamantul rosu, dar ramane sant, nu vopsea.
const MARK_ALPHA: float = 0.8

# Partajate de toate masinile: o textura, un material, un mesh — deci si un
# singur desen per masina, nu unul per urma.
static var _mesh: PlaneMesh
static var _mat: StandardMaterial3D

var _next: int = 0


func _ready() -> void:
	# Instantele se scriu in coordonate de LUME, deci nodul nu are voie sa
	# meara odata cu masina: fara asta, toata dara ar aluneca dupa ea.
	top_level = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# AABB fix, generos cat toata lumea: altfel Godot recalculeaza anvelopa la
	# fiecare instanta scrisa, de 16 ori pe secunda, degeaba.
	custom_aabb = AABB(Vector3(-2000, -500, -2000), Vector3(4000, 1000, 4000))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _shared_mesh()
	mm.instance_count = CAPACITY
	multimesh = mm
	material_override = _shared_material()
	# Sloturile nefolosite: scala zero, deci triunghiuri degenerate, deci nimic
	# pe ecran. instance_count nu se poate creste ieftin pe parcurs, asa ca
	# inelul e plin de la inceput si doar arata gol.
	var hidden := Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO)
	for i in CAPACITY:
		mm.set_instance_transform(i, hidden)


## Depune o urma. [param basis] trebuie sa aiba Y pe normala solului — asa
## placuta sta LIPITA de panta, nu orizontala prin ea (Okinawa are pante de 15%,
## unde o placuta de 2.6 m orizontala si-ar ingropa un capat).
func stamp(origin: Vector3, orientation: Basis) -> void:
	if multimesh == null:
		return
	multimesh.set_instance_transform(_next, Transform3D(orientation, origin))
	_next = (_next + 1) % CAPACITY


static func _shared_mesh() -> PlaneMesh:
	if _mesh == null:
		_mesh = PlaneMesh.new()
		_mesh.size = MARK_SIZE
	return _mesh


static func _shared_material() -> StandardMaterial3D:
	if _mat != null:
		return _mat
	_mat = StandardMaterial3D.new()
	# Aceeasi textura ca urmele coapte in pista (Track._build_tire_marks):
	# profil de anvelopa cu alfa real, tileabil pe lungime. Un al doilea desen
	# de urma ar fi cerut si a doua textura cu transparenta — costul pe care
	# garda de materiale nu-l vede si de-aia il tinem numarat de mana.
	_mat.albedo_texture = load("res://assets/textures/decal_tracks.png")
	_mat.albedo_color = Color(1.0, 1.0, 1.0, MARK_ALPHA)
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.cull_mode = BaseMaterial3D.CULL_BACK
	# Urmele proaspete se deseneaza DUPA poteca coapta a pistei, care sta si ea
	# in transparenta, la 2.5 cm. Fara prioritate, sortarea celor doua straturi
	# depinde de distanta la camera si palpaie cand treci peste ele.
	_mat.render_priority = 1
	return _mat
