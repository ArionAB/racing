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

## Cat de lata e BUZA fata de jumatatea de latime a fagasului. Buza e materialul
## impins in lateral care se aduna si prinde lumina — vezi Track.trail_lip_color.
const LIP_FRAC: float = 0.26

## Cat de opaca e urma in miez. Valoarea implicita; pista o suprascrie prin
## `Track.trail_profile()`, fiindca adancimea urmei tine de suprafata.
const MARK_ALPHA: float = 0.6

## Latimea efectiva a fagasului, pusa de pista inainte de construirea plasei.
## Nisipul afanat da brazda cea mai lata, pamantul tare cea mai ingusta.
static var _width: float = MARK_SIZE.x


## Anvelopa (AABB) declarata a darei: toata lumea, cu mult peste orice pista.
##
## Instantele se scriu in coordonate de LUME, imprastiate pe toata pista, deci
## anvelopa reala a darei creste oricum cat toata harta. Declarata din start,
## Godot nu mai are ce recalcula la fiecare depunere (de ~16 ori pe secunda, per
## masina). E o economie, nu o reparatie: fara ea urmele se vad la fel — masurat,
## nu presupus.
const SHADER_PATH: String = "res://assets/shaders/sand_trail.gdshader"

const WORLD_AABB: AABB = AABB(
	Vector3(-2000, -500, -2000), Vector3(4000, 1000, 4000))

# Partajate de toate masinile: un material, un mesh — deci un singur desen per
# masina, nu unul per urma.
static var _mesh: Mesh
static var _mat: ShaderMaterial

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
	var hw := _width * 0.5
	var hl := MARK_SIZE.y * 0.5
	# Buza: o fasie in AFARA fagasului, cat 26% din jumatatea de latime.
	var lip := hw * LIP_FRAC
	# Sase coloane, nu patru: intre solul nederanjat si fagasul inchis se
	# interpune BUZA — materialul impins in lateral, care e mai DESCHIS decat
	# imprejurimile. Fara ea profilul e o treapta simpla si ochiul citeste
	# vopsea; cu ea citeste adancitura. Canalul R marcheaza fagasul, G buza;
	# shaderul (assets/shaders/sand_trail.gdshader) alege culoarea dupa ele.
	# (x, alfa, cat de "buza" e). Buza are VARFUL la marginea fagasului si se
	# stinge in afara lui — nu e o fasie plina.
	#
	# Greseala din prima versiune: vertexul de la x = ±hw avea alfa 1.0 SI buza
	# 1.0, adica placuta iesea plina pe toata latimea de dinainte si abia apoi
	# se stingea. Pe nisip trecea neobservat; pe zapada, unde culoarea buzei e
	# aproape alba, dara acoperea soseaua ca un strat de vopsea.
	var cols := [
		[-hw - lip, 0.0, 1.0], # marginea de afara: stinsa complet
		[-hw, 0.55, 1.0], # varful buzei, la marginea fagasului
		[-hw * EDGE_FRAC, 1.0, 0.0], # intra in fagas: plin, fara buza
		[hw * EDGE_FRAC, 1.0, 0.0],
		[hw, 0.55, 1.0],
		[hw + lip, 0.0, 1.0],
	]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for k in cols.size() - 1:
		var xa: float = cols[k][0]
		var xb: float = cols[k + 1][0]
		# RGB poarta CINE e vertexul (rosu = fagas, verde = buza), alfa poarta
		# cat de tare. Materialul le combina — vezi _shared_material.
		var ca := Color(1.0 - cols[k][2], cols[k][2], 0.0, cols[k][1])
		var cb := Color(1.0 - cols[k + 1][2], cols[k + 1][2], 0.0,
			cols[k + 1][1])
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


## Nuanta brazdei, FINALA — o decide pista (Track.trail_mark_color), fiindca
## e o proprietate a suprafetei, nu a placutei: pe nisip e suprafata intunecata
## cu 42% (masurat), pe zapada e "zapada presata" — mai inchisa DAR mai
## albastra, nu doar stinsa.
##
## Se cheama o data per cursa, de prima masina care lasa urme: materialul e
## partajat de toate, iar toate sunt pe aceeasi pista. Culoarea nu poate fi o
## constanta — aceeasi placuta cade si pe drumul de nisip al Okinawei, si pe
## nisipul coraligen de langa el, si pe zapada Baikalului.
## Pune pe material profilul brazdei asa cum il vrea PISTA: cele doua culori
## (fagas si buza) si cele doua opacitati.
##
## Se cheama o data per cursa, inainte ca vreo masina sa depuna ceva — trebuie
## sa fie inainte, fiindca latimea intra in plasa, iar plasa se coace o singura
## data si e partajata de toate masinile.
static func set_surface(mark: Color, lip: Color, profile: Dictionary) -> void:
	_width = profile.get("width", MARK_SIZE.x)
	var m := _shared_material()
	m.set_shader_parameter("core_color", Color(mark.r, mark.g, mark.b))
	m.set_shader_parameter("lip_color", Color(lip.r, lip.g, lip.b))
	m.set_shader_parameter("core_alpha", profile.get("core", MARK_ALPHA))
	m.set_shader_parameter("lip_alpha", profile.get("lip", 0.28))


static func _shared_material() -> ShaderMaterial:
	if _mat != null:
		return _mat
	# FARA textura: alfa ei nu supravietuieste mipmap-ului (vezi _shared_mesh).
	# Forma vine din vertecsi, culorile din set_surface.
	#
	# Shader propriu, nu StandardMaterial3D: placuta poarta DOUA culori (fagas
	# si buza), iar un material standard poate inmulti vertex color-ul cu una
	# singura. Restul setarilor (nelit, alpha, fara depth write, cull back)
	# traiesc acum in render_mode-ul shaderului.
	_mat = ShaderMaterial.new()
	_mat.shader = load(SHADER_PATH) as Shader
	# Urmele proaspete se deseneaza DUPA celelalte straturi transparente de pe
	# sol (urme de drift, decal-uri de pista). Fara prioritate, sortarea depinde
	# de distanta la camera si palpaie cand treci peste ele.
	_mat.render_priority = 1
	return _mat
