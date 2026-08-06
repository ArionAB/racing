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
## ele — exact artefactul care spune "particule", nu "urma". Suprapunerea e mica
## (0.2 m) DINADINS: acolo unde doua placute se acopera, alfa se aplica de doua
## ori, deci banda iese mai inchisa. La 0.4 m suprapunere ritmul asta se citea ca
## dungi din 2.2 in 2.2 m.
##
## Latimea e MAI MARE decat anvelopa (0.34), fiindca marginile urmei se sting
## (vezi EDGE_FRAC): miezul plin ramane cat o roata, iar restul e trecerea spre
## nisipul nederanjat.
const MARK_SIZE: Vector2 = Vector2(0.46, 2.4)

## Unde incepe stingerea laterala, in fractii din jumatatea de latime. 0.62 din
## 0.23 m = miez plin de 0.28 m (cat anvelopa) si 0.09 m de trecere pe fiecare
## parte.
const EDGE_FRAC: float = 0.62

## Cat de opaca e urma in miez.
const MARK_ALPHA: float = 0.6

## Cat de INCHISA e urma fata de suprafata pe care e lasata.
##
## Tinta e o brazda, nu vopsea: nisipul rascolit isi pierde din lumina fiindca
## boabele stau altfel si pentru ca sub crusta uscata e material mai umed. 0.42
## e cat s-a masurat pe drumul de nisip (#D3A855 curat -> #9E7A45 pe brazda) —
## se citeste din masina, dar nu face din urma o dara de pacura.
const MARK_DARKEN: float = 0.42

## Anvelopa (AABB) declarata a darei: toata lumea, cu mult peste orice pista.
##
## Instantele se scriu in coordonate de LUME, imprastiate pe toata pista, deci
## anvelopa reala a darei creste oricum cat toata harta. Declarata din start,
## Godot nu mai are ce recalcula la fiecare depunere (de ~16 ori pe secunda, per
## masina). E o economie, nu o reparatie: fara ea urmele se vad la fel — masurat,
## nu presupus.
const WORLD_AABB: AABB = AABB(
	Vector3(-2000, -500, -2000), Vector3(4000, 1000, 4000))

# Partajate de toate masinile: un material, un mesh — deci un singur desen per
# masina, nu unul per urma.
static var _mesh: Mesh
static var _mat: StandardMaterial3D

var _next: int = 0


func _ready() -> void:
	# Instantele se scriu in coordonate de LUME, deci nodul nu are voie sa
	# meara odata cu masina: fara asta, toata dara ar aluneca dupa ea.
	#
	# ############################################################################
	# RESETAREA DE DEDESUBT NU E DE PRISOS.
	#
	# `top_level = true` pus pe un nod care e DEJA in arbore nu-l muta: Godot ii
	# PASTREAZA transformul global de atunci, mutandu-l in cel local. Iar nodul
	# asta se naste in momentul primei urme, ca fiu al masinii — deci mostenea
	# pozitia si rotatia masinii din secunda aia si le pastra toata cursa.
	# Instantele, scrise in coordonate de lume, mai treceau o data prin
	# transformul ala.
	#
	# Masurat pe ProbeFx inainte de reparatie: transformul nodului era
	# [O: (30.4, 0.10, 220.3)], rotit cu ~67° — adica pozitia masinii la prima
	# urma. Urmele plecau in larg, si nimic nu se plangea: instantele erau scrise,
	# cu coordonate corecte, nodul vizibil, materialul legat.
	# ############################################################################
	top_level = true
	global_transform = Transform3D.IDENTITY
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _shared_mesh()
	mm.instance_count = CAPACITY
	# Anvelopa MultiMesh-ului, nu doar a nodului: culling-ul se uita la amandoua.
	mm.custom_aabb = WORLD_AABB
	multimesh = mm
	material_override = _shared_material()
	custom_aabb = WORLD_AABB
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


## Placuta unei urme: patru coloane pe latime, cu alfa in VERTECSI.
##
## ############################################################################
## DE CE NU E UN PlaneMesh CU TEXTURA DE ANVELOPA
##
## Prima versiune folosea decal_tracks.png, aceeasi textura ca urmele coapte in
## pista. Textura aia isi tine tot desenul in ALFA, iar media alfei ei e ~0.11,
## nu 0.55 cat are in varf — si alfa trece prin mipmap ca orice alt canal. O
## placuta de 0.46 m ocupa cativa pixeli la zece metri in urma masinii, deci
## GPU-ul citeste dintr-un mip mic, adica exact media aia. Aceeasi lectie e
## documentata pe larg la Track.TIRE_TILE, unde a costat o iteratie intreaga.
##
## Alfa dintr-un VERTEX nu are mipmap: se interpoleaza pe suprafata si ramane
## exact cat ai cerut, la orice distanta. Pretul e ca urma nu mai are desen de
## anvelopa — dar un sant in nisip nici n-are: profilul se imprima in noroi, in
## nisip afanat malurile se surpa si ramane o brazda.
## ############################################################################
static func _shared_mesh() -> Mesh:
	if _mesh != null:
		return _mesh
	var hw := MARK_SIZE.x * 0.5
	var hl := MARK_SIZE.y * 0.5
	# (x, alfa) pe latime: stins pe margini, plin pe miez.
	var cols := [
		[-hw, 0.0], [-hw * EDGE_FRAC, 1.0], [hw * EDGE_FRAC, 1.0], [hw, 0.0],
	]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for k in cols.size() - 1:
		var xa: float = cols[k][0]
		var xb: float = cols[k + 1][0]
		var ca := Color(1, 1, 1, cols[k][1])
		var cb := Color(1, 1, 1, cols[k + 1][1])
		# Ordinea conteaza: cu winding-ul intors, placutele exista in scena si sunt
		# invizibile PRIVITE DE SUS — adica din singurul unghi din care se uita
		# cineva la ele — fiindca materialul taie fetele din spate (cull_mode).
		st.set_color(ca); st.add_vertex(Vector3(xa, 0.0, -hl))
		st.set_color(cb); st.add_vertex(Vector3(xb, 0.0, -hl))
		st.set_color(ca); st.add_vertex(Vector3(xa, 0.0, hl))
		st.set_color(cb); st.add_vertex(Vector3(xb, 0.0, -hl))
		st.set_color(cb); st.add_vertex(Vector3(xb, 0.0, hl))
		st.set_color(ca); st.add_vertex(Vector3(xa, 0.0, hl))
	_mesh = st.commit()
	return _mesh


## Nuanta brazdei, pentru suprafata pe care se conduce ACUM.
##
## Se cheama o data per cursa, de prima masina care lasa urme: materialul e
## partajat de toate, iar toate sunt pe aceeasi pista. Culoarea nu poate fi o
## constanta — aceeasi placuta cade si pe drumul de nisip al Okinawei, si pe
## nisipul coraligen de langa el, si pe cel auriu al Dunelor.
static func set_surface_color(surface: Color) -> void:
	_shared_material().albedo_color = Color(
		surface.darkened(MARK_DARKEN), MARK_ALPHA)


static func _shared_material() -> StandardMaterial3D:
	if _mat != null:
		return _mat
	_mat = StandardMaterial3D.new()
	# FARA textura: alfa ei nu supravietuieste mipmap-ului (vezi _shared_mesh).
	# Forma vine din vertecsi, culoarea din set_surface_color.
	_mat.albedo_color = Color(0.35, 0.28, 0.18, MARK_ALPHA)
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# UNSHADED, ca poteca de dinainte (Track._path_material): culoarea scrisa e
	# chiar culoarea de pe ecran. O suprafata luminata proprie s-ar spala in
	# ambianta albastra a cerului tropical exact acolo unde vrem sa se inchida.
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Alfa din vertecsi inmulteste alfa din albedo; RGB-ul lor e alb, deci nu
	# atinge nuanta.
	_mat.vertex_color_use_as_albedo = true
	_mat.cull_mode = BaseMaterial3D.CULL_BACK
	# Urmele proaspete se deseneaza DUPA celelalte straturi transparente de pe
	# sol (urme de drift, decal-uri de pista). Fara prioritate, sortarea depinde
	# de distanta la camera si palpaie cand treci peste ele.
	_mat.render_priority = 1
	return _mat
