@tool
class_name ChimneyShape
extends Node3D
## Rupe SIMETRIA DE REVOLUTIE a unui horn de tuf, per instanta.
##
## De ce exista. Kitul are sase hornuri (chimney_a..d, _mushroom, _triple), si
## toate sunt generate cu `Builder.revolve`: un profil rotit in jurul lui Y. Pe
## pista erau asezate cu scara UNIFORMA si rotatie doar pe Y — iar rotatia pe Y
## a unei suprafete de revolutie nu schimba NIMIC din silueta. Rezultatul,
## numit de critica oarba de doua runde la rand: "o singura instanta repetata la
## N scari", "conuri radial simetrice". Se vede si de la volan, in captura de la
## fractia 0.10: aceeasi silueta de sase ori, doar mai mare sau mai mica.
##
## Ce NU repara asta: mai multe GLB-uri. Al saptelea con de revolutie e tot un
## con de revolutie. Deficitul nu e in numarul de modele, e in FAMILIA de forme
## — o revolutie n-are decat un singur grad de libertate (profilul), si acela e
## acelasi pe toate azimuturile.
##
## Ce face: deformeaza vertecsii mesh-ului instantiat, in spatiul LOCAL al
## modelului, cu patru operatii care nu se pot exprima ca revolutie:
##
##   1. `ovality` — raza depinde de AZIMUT. Un con ovalizat vazut din doua
##      unghiuri diferite da doua siluete diferite; asta singur sparge "aceeasi
##      instanta la alta scara", fiindca rotatia pe Y a devenit brusc vizibila.
##   2. `lean_deg` / `lean_dir_deg` — axa se INCLINA cu inaltimea. Hornurile
##      reale se apleaca: baza se erodeaza asimetric, palaria le tine in
##      dezechilibru. O revolutie e verticala prin definitie.
##   3. `bulge` / `bulge_height` — umflatura la o inaltime data, cu semn: pozitiv
##      = burta la mijloc (hornul indesat), negativ = gat strangulat sub palarie.
##      Modifica PROFILUL per instanta, deci doi `chimney_b` nu mai sunt acelasi
##      obiect.
##   4. `flute_depth` / `flute_count` — caneluri VERTICALE de eroziune, sapate in
##      raza ca functie de azimut. Vezi si `detail_tuff.png`: acolo e textura,
##      aici e GEOMETRIE, adica silueta capata zimti pe contur. Explicit
##      verticale — critica a cerut de doua ori sa dispara liniile de contur
##      ORIZONTALE, care citesc a strung.
##
## Toate patru sunt functii de (y, azimut), deci nu pot fi obtinute rotind un
## profil. Asta e definitia lui "nu mai e suprafata de revolutie".
##
## De ce deformare la asezare si nu GLB-uri noi: hornurile trebuie sa ramana
## NODURI EDITABILE in Track13.tscn (regula pistei — vezi
## `decor-manual-sursa-de-adevar`). Parametrii de mai jos sunt @export, deci se
## trag din Inspector cu previzualizare in editor (`@tool`), iar ce se vede in
## editor e ce se vede in joc. Un GLB per varianta ar fi mutat forma intr-un
## binar pe care nu-l poti regla fara Blender.
##
## Cost: ZERO materiale noi (se schimba doar pozitiile vertecsilor, materialul
## ramane al modelului) si zero triunghiuri noi. Mesh-ul se duplica pe instanta
## — de aceea rezolutia hornurilor din kit conteaza, nu se subdivideaza aici.

## Raportul dintre razele celor doua axe orizontale. 1.0 = cerc (revolutie);
## 0.62 = elipsa vizibil turtita. Peste ~0.5 incepe sa citeasca a perete, nu a
## horn.
@export_range(0.35, 1.0, 0.01) var ovality: float = 1.0

## Pe ce azimut sta axa lunga a elipsei, in grade. Conteaza fiindca perechea
## (ovality, oval_dir_deg) e ce face ca rotatia pe Y sa schimbe silueta.
@export_range(0.0, 180.0, 1.0) var oval_dir_deg: float = 0.0

## Cat se apleaca varful fata de verticala, in grade, masurat pe inaltimea
## totala a mesh-ului.
@export_range(-18.0, 18.0, 0.5) var lean_deg: float = 0.0

## Incotro se apleaca, in grade (azimut local).
@export_range(0.0, 360.0, 1.0) var lean_dir_deg: float = 0.0

## Umflatura de profil. Pozitiv = burta (horn indesat), negativ = gat subtiat.
@export_range(-0.45, 0.60, 0.01) var bulge: float = 0.0

## La ce fractiune din inaltime sta umflatura (0 = baza, 1 = varf).
@export_range(0.05, 0.95, 0.01) var bulge_height: float = 0.45

## Cat de late sunt umflatura/gatul pe verticala, ca fractiune din inaltime.
@export_range(0.10, 0.90, 0.01) var bulge_spread: float = 0.35

## Adancimea canelurilor verticale, ca fractiune din raza.
@export_range(0.0, 0.22, 0.005) var flute_depth: float = 0.0

## Cate caneluri de jur imprejur.
@export_range(3, 24, 1) var flute_count: int = 9

## Pana la ce fractiune din inaltime coboara canelurile (siroirea vine de sus,
## dar se stinge inainte de baza ingropata).
@export_range(0.0, 1.0, 0.01) var flute_top: float = 1.0

## Seed-ul zgomotului de contur, ca doua instante cu aceiasi parametri sa nu
## iasa identice.
@export var shape_seed: int = 0

## Cat de tare musca zgomotul de contur din raza (fractiune).
@export_range(0.0, 0.14, 0.005) var noise_amount: float = 0.0


## --- Poalele de moloz (talus) ----------------------------------------------

## Cat de departe de baza se intinde poala de grohotis, ca fractiune din raza
## hornului la sol. 0 = stinsa.
##
## De ce exista. Critica oarba, runda 9, locul 2: "rock that eroded leaves the
## material it shed lying at its foot. Ours sheds nothing, so it never eroded,
## so it isn't rock — it's a flat." Hornurile noastre intalneau pamantul intr-o
## imbinare cap la cap, perfect taiata, "ca un decor de teatru pus pe masa".
## Un con de material cazut la picior e ce transforma imbinarea aia intr-un
## CONTACT: piatra vine de undeva, se sfarama, si sfaramatura sta jos.
##
## 0.55 inseamna ca poala iese cu jumatate de raza dincolo de horn — destul cat
## sa se vada de la volan, prea putin cat sa inece silueta.
@export_range(0.0, 1.4, 0.05) var talus_spread: float = 0.0

## Cat de inalta e poala la perete, ca fractiune din raza de la sol. Panta reala
## a unui grohotis e ~34°, deci raportul inaltime/latime iese pe la 0.45-0.65;
## sub 0.3 poala citeste a pata pe jos, nu a morman.
@export_range(0.05, 1.0, 0.05) var talus_height: float = 0.5

## Cate laturi are inelul de moloz. 14 e destul pentru o silueta neregulata la
## distanta de condus; nu se urca fiindca poala se vede mereu de departe.
@export_range(6, 24, 1) var talus_sides: int = 14


## --- Usi si ferestre sapate in baza -----------------------------------------

## Cate deschideri (usi/ferestre) se sapa in baza hornului. 0 = niciuna.
##
## De ce exista. Aceeasi critica, locul 4: "no object in frame touches the
## ground anywhere, so the wall could be 8 m or 80 m and you cannot tell." O
## dioramă traieste din a sti ca te uiti la un lucru mic randat mare, iar cheia
## cea mai ieftina de scara e o USA: toata lumea stie cat e de inalta o usa.
## Referinta din Cappadocia e plina de ele — hornurile sunt LOCUITE.
##
## Nu se taie gaura (ar cere boolean si ar sparge mesh-ul); se INFUNDA o nisa:
## un chenar in relief cu fundul impins spre interior, care de la volan citeste
## a intrare intunecata fiindca fundul e in umbra proprie.
@export_range(0, 6, 1) var door_count: int = 0

## Inaltimea deschiderii in metri, in spatiul LUMII. Se da in metri si nu ca
## fractiune tocmai fiindca asta e toata poanta: o usa are 2 m indiferent cat de
## mare e hornul din spatele ei, si de-aia spune scara.
@export_range(1.2, 3.0, 0.1) var door_height_m: float = 2.0

## Latimea deschiderii ca fractiune din inaltimea ei.
@export_range(0.35, 0.9, 0.05) var door_aspect: float = 0.55

## Cat de adanc intra nisa in perete, in metri.
@export_range(0.15, 1.2, 0.05) var door_depth_m: float = 0.45

## La ce inaltime sta pragul deschiderilor, in metri deasupra bazei mesh-ului.
## 0 = usa la sol. Valori peste ~2.5 citesc a fereastra de porumbar.
@export var door_sill_m: float = 0.0

## Pe ce azimuturi se aseaza deschiderile, in grade. Prima e la `door_dir_deg`,
## restul se distribuie pe `door_arc_deg`.
@export_range(0.0, 360.0, 5.0) var door_dir_deg: float = 0.0

## Pe ce arc se raspandesc deschiderile in jurul hornului. Implicit 90°, adica
## toate pe aceeasi fata — ce se vede de pe drum.
@export_range(0.0, 360.0, 5.0) var door_arc_deg: float = 90.0


func _ready() -> void:
	_deform()


func _deform() -> void:
	# Fara munca daca instanta e lasata pe valorile neutre: hornurile care chiar
	# trebuie sa ramana drepte nu platesc duplicarea mesh-ului.
	var shapes_off := is_equal_approx(ovality, 1.0) and is_zero_approx(lean_deg) 			and is_zero_approx(bulge) and is_zero_approx(flute_depth) 			and is_zero_approx(noise_amount)
	var extras_off := is_zero_approx(talus_spread) and door_count == 0
	if shapes_off and extras_off:
		return
	var meshes: Array[MeshInstance3D] = []
	_collect(self, meshes)
	if meshes.is_empty():
		return
	if not shapes_off:
		for mi in meshes:
			_deform_mesh(mi)
	# Poala si deschiderile se ataseaza O SINGURA DATA, pe mesh-ul cel mai mare:
	# la hornul triplu, trei poale concentrice s-ar fi intersectat intr-o stea,
	# iar trei randuri de usi ar fi spus trei scari diferite.
	if not extras_off:
		var host: MeshInstance3D = meshes[0]
		var best := -1.0
		for mi in meshes:
			var vol: float = mi.mesh.get_aabb().get_volume()
			if vol > best:
				best = vol
				host = mi
		_add_extras(host)


func _collect(node: Node, out: Array[MeshInstance3D]) -> void:
	var mi := node as MeshInstance3D
	if mi != null and mi.mesh != null:
		out.append(mi)
	for c in node.get_children():
		_collect(c, out)


## Deformeaza UN mesh. Lucreaza pe ArrayMesh: se citesc array-urile, se mută
## POZITIILE si se rescriu. Normalele se recalculeaza cu
## `generate_normals()` — fara asta, iluminarea ar ramane a formei VECHI, adica
## exact bug-ul de "obiect deformat care se lumineaza ca un con".
func _deform_mesh(mi: MeshInstance3D) -> void:
	var src := mi.mesh
	var aabb := src.get_aabb()
	var h := maxf(aabb.size.y, 0.001)
	var y0 := aabb.position.y
	# Centrul in plan orizontal: deformarile sunt radiale fata de AXA modelului,
	# nu fata de originea scenei. La hornul triplu axa e a grupului, deci cele
	# trei cosuri se inclina ca un buchet, nu fiecare in alta parte — ce si vrem.
	var cx := aabb.position.x + aabb.size.x * 0.5
	var cz := aabb.position.z + aabb.size.z * 0.5

	var rng := RandomNumberGenerator.new()
	rng.seed = shape_seed
	# Doua faze de zgomot, ca directia canelurilor si a conturului sa nu se
	# alinieze pe toate instantele.
	var ph1 := rng.randf() * TAU
	var ph2 := rng.randf() * TAU

	var oval_dir := deg_to_rad(oval_dir_deg)
	var lean_dir := deg_to_rad(lean_dir_deg)
	# Deplasarea laterala a varfului, in metri.
	var lean_amt := tan(deg_to_rad(lean_deg)) * h

	var out := ArrayMesh.new()
	for s in src.get_surface_count():
		var arrays := src.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in verts.size():
			var v := verts[i]
			var dx := v.x - cx
			var dz := v.z - cz
			var r := sqrt(dx * dx + dz * dz)
			# Fractiunea de inaltime, 0 la baza, 1 la varf.
			var t := clampf((v.y - y0) / h, 0.0, 1.0)
			if r > 0.0001:
				var ang := atan2(dz, dx)
				var scale := 1.0
				# --- 1. ovalizare: raza depinde de azimut ------------------
				if not is_equal_approx(ovality, 1.0):
					var a := ang - oval_dir
					# Elipsa: 1 pe axa lunga, `ovality` pe cea scurta.
					scale *= 1.0 / sqrt(
						pow(cos(a), 2.0)
						+ pow(sin(a) / maxf(ovality, 0.01), 2.0))
				# --- 3. umflatura / gat -----------------------------------
				if not is_zero_approx(bulge):
					var d := (t - bulge_height) / maxf(bulge_spread, 0.01)
					scale *= 1.0 + bulge * exp(-d * d)
				# --- 4. caneluri VERTICALE --------------------------------
				# Amplitudinea nu depinde de `t` decat prin stingerea de jos:
				# un sant de siroire coboara pe toata fata, nu se inchide la
				# mijloc — daca ar varia cu inaltimea, ar reaparea exact
				# banding-ul orizontal pe care il inlocuim.
				if not is_zero_approx(flute_depth):
					var fade := smoothstep(0.0, 0.22, t) \
						* (1.0 - smoothstep(flute_top - 0.12, flute_top, t))
					scale *= 1.0 - flute_depth * fade \
						* (0.5 - 0.5 * cos(float(flute_count) * ang + ph1))
				# --- contur neregulat -------------------------------------
				if not is_zero_approx(noise_amount):
					scale *= 1.0 + noise_amount * (
						sin(3.0 * ang + ph2) * 0.6
						+ sin(5.0 * ang + t * 4.0 + ph1) * 0.4)
				v.x = cx + dx * scale
				v.z = cz + dz * scale
			# --- 2. inclinarea axei: creste cu patratul inaltimii ----------
			# Patratul, nu liniar: baza ramane pe loc (hornul e infipt in
			# teren), iar curbura se vede spre varf — o inclinare liniara ar fi
			# aratat ca un con pur si simplu rasucit din radacina.
			if not is_zero_approx(lean_deg):
				var k := t * t * lean_amt
				v.x += cos(lean_dir) * k
				v.z += sin(lean_dir) * k
			verts[i] = v
		arrays[Mesh.ARRAY_VERTEX] = verts
		# Normalele vechi mint dupa deformare; se refac din geometria noua.
		arrays[Mesh.ARRAY_NORMAL] = null
		arrays[Mesh.ARRAY_TANGENT] = null
		out.add_surface_from_arrays(
			Mesh.PRIMITIVE_TRIANGLES, arrays)
		out.surface_set_material(s, src.surface_get_material(s))

	var st := SurfaceTool.new()
	var fixed := ArrayMesh.new()
	for s in out.get_surface_count():
		st.clear()
		st.create_from(out, s)
		st.generate_normals()
		var m := st.commit()
		fixed.add_surface_from_arrays(
			Mesh.PRIMITIVE_TRIANGLES, m.surface_get_arrays(0))
		fixed.surface_set_material(s, out.surface_get_material(s))
	mi.mesh = fixed


## Adauga poala de moloz si nisele de usa la mesh-ul gazda, ca SUPRAFETE NOI pe
## acelasi ArrayMesh, cu MATERIALUL suprafetei 0.
##
## De ce pe acelasi mesh si nu ca noduri copil: un MeshInstance3D nou ar fi
## insemnat un draw call nou per horn (si sunt zeci), iar constrangerea reala pe
## mobil sunt draw call-urile, nu triunghiurile — vezi CLAUDE.md. Asa, poala si
## usile calatoresc in acelasi batch cu hornul si costa ZERO materiale.
func _add_extras(mi: MeshInstance3D) -> void:
	var src := mi.mesh
	if src == null or src.get_surface_count() == 0:
		return
	var aabb := src.get_aabb()
	var cx := aabb.position.x + aabb.size.x * 0.5
	var cz := aabb.position.z + aabb.size.z * 0.5
	var y0 := aabb.position.y
	var h := maxf(aabb.size.y, 0.001)
	# Raza LA SOL, masurata din mesh si nu din AABB: AABB-ul unui horn cu palarie
	# e cat palaria, iar poala pusa dupa palarie ar fi plutit in jurul unui gat
	# subtire, la un metru de piatra. Se citesc vertecsii din prima felie de
	# inaltime si se ia raza mediana pe azimut.
	var base_r := _base_radius(src, cx, cz, y0, h)
	if base_r <= 0.001:
		return

	# Scara nodului conteaza: `door_height_m` e in METRI DE LUME, dar geometria
	# se scrie in spatiul local al mesh-ului, care e scalat de transformul
	# instantei (hornurile sunt puse cu scari 0.7..1.2). Fara impartirea asta, o
	# "usa de 2 m" ar fi iesit de 2.4 m pe hornul mare si de 1.4 m pe cel mic —
	# adica exact cheia de scara ar fi mintit.
	var world_scale := maxf(global_basis.get_scale().y, 0.001)

	var out := ArrayMesh.new()
	for sfc in src.get_surface_count():
		out.add_surface_from_arrays(
			Mesh.PRIMITIVE_TRIANGLES, src.surface_get_arrays(sfc))
		out.surface_set_material(sfc, src.surface_get_material(sfc))
	var mat := src.surface_get_material(0)

	if not is_zero_approx(talus_spread):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_build_talus(st, cx, cz, y0, base_r)
		st.generate_normals()
		var m := st.commit()
		if m != null and m.get_surface_count() > 0:
			out.add_surface_from_arrays(
				Mesh.PRIMITIVE_TRIANGLES, m.surface_get_arrays(0))
			out.surface_set_material(out.get_surface_count() - 1, mat)

	if door_count > 0:
		var st2 := SurfaceTool.new()
		st2.begin(Mesh.PRIMITIVE_TRIANGLES)
		_build_doors(st2, cx, cz, y0, base_r, world_scale)
		st2.generate_normals()
		var m2 := st2.commit()
		if m2 != null and m2.get_surface_count() > 0:
			out.add_surface_from_arrays(
				Mesh.PRIMITIVE_TRIANGLES, m2.surface_get_arrays(0))
			out.surface_set_material(out.get_surface_count() - 1, mat)

	mi.mesh = out


## Raza hornului la nivelul solului. Se ia mediana razelor din felia de jos
## (primii 8% din inaltime) ca sa nu o strice nici palaria de deasupra, nici un
## vertex ratacit.
func _base_radius(src: Mesh, cx: float, cz: float, y0: float, h: float) -> float:
	var radii: PackedFloat32Array = []
	for sfc in src.get_surface_count():
		var arrays := src.surface_get_arrays(sfc)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for v in verts:
			if v.y - y0 < h * 0.08:
				radii.append(Vector2(v.x - cx, v.z - cz).length())
	if radii.is_empty():
		return 0.0
	radii.sort()
	return radii[radii.size() / 2]


## Inelul de grohotis: un trunchi de con jos si larg, lipit de perete.
##
## Nu e un con neted — raza exterioara si inaltimea variaza pe azimut cu acelasi
## zgomot ca si conturul hornului. Un inel perfect circular la piciorul unei
## stanci neregulate ar fi citit a farfurie, adica tot decor de teatru, doar cu
## inca o piesa.
func _build_talus(st: SurfaceTool, cx: float, cz: float, y0: float,
		base_r: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = shape_seed + 7717
	var ph := rng.randf() * TAU
	var n := talus_sides
	# Poala coboara putin SUB baza mesh-ului, ca sa nu ramana o fanta intre ea
	# si teren pe pantele unde hornul sta oblic.
	var y_foot := y0 - base_r * 0.10
	var inner: Array[Vector3] = []
	var outer: Array[Vector3] = []
	for i in n:
		var a := TAU * float(i) / float(n)
		# Neregularitate pe azimut: doua armonici, ca la conturul hornului.
		var wob := 1.0 + 0.28 * sin(3.0 * a + ph) + 0.16 * sin(5.0 * a + ph * 1.7)
		var r_out := base_r * (1.0 + talus_spread * wob)
		var r_in := base_r * 0.98
		var y_top := y0 + base_r * talus_height * (0.75 + 0.35 * wob)
		inner.append(Vector3(cx + cos(a) * r_in, y_top, cz + sin(a) * r_in))
		outer.append(Vector3(cx + cos(a) * r_out, y_foot, cz + sin(a) * r_out))
	for i in n:
		var j := (i + 1) % n
		# Fusta: de la buza de sus (lipita de perete) la poalele de jos.
		st.add_vertex(inner[i])
		st.add_vertex(outer[i])
		st.add_vertex(outer[j])
		st.add_vertex(inner[i])
		st.add_vertex(outer[j])
		st.add_vertex(inner[j])


## Nisele de usa/fereastra: un chenar impins in perete.
##
## Nu se taie gaura in mesh — un boolean pe geometrie deformata ar fi cerut o
## librarie de CSG si ar fi lasat fatete rupte. Se aseaza in schimb o cutie fara
## capac frontal, cu fundul impins spre AXA hornului: peretii laterali si fundul
## sunt in umbra proprie, deci de la volan gaura citeste ca gaura.
func _build_doors(st: SurfaceTool, cx: float, cz: float, y0: float,
		base_r: float, world_scale: float) -> void:
	# Din metri de lume in unitati de mesh.
	var dh := door_height_m / world_scale
	var dw := dh * door_aspect
	var dd := door_depth_m / world_scale
	# Nisa nu poate fi mai adanca decat jumatate din raza si nici mai lata decat
	# raza intreaga: altfel fundul ei ar iesi pe partea cealalta a hornului, iar
	# peretii s-ar autointersecta.
	dd = minf(dd, base_r * 0.5)
	dw = minf(dw, base_r * 1.4)
	var sill := door_sill_m / world_scale
	var arc := deg_to_rad(door_arc_deg)
	var dir0 := deg_to_rad(door_dir_deg)
	for k in door_count:
		var f := 0.0
		if door_count > 1:
			f = float(k) / float(door_count - 1) - 0.5
		var a := dir0 + f * arc
		var nx := cos(a)
		var nz := sin(a)
		# Tangenta: latimea usii se masoara pe circumferinta.
		var tx := -sin(a)
		var tz := cos(a)
		# Fata nisei sta PUTIN in afara peretelui (ca sa nu faca z-fighting cu
		# el), fundul intra cu `dd`.
		var r_face := base_r * 1.01
		var r_back := base_r - dd
		var yb := y0 + sill
		var yt := yb + dh
		var hw := dw * 0.5
		# Cele opt colturi: 4 pe fata, 4 pe fund.
		var fbl := Vector3(cx + nx * r_face - tx * hw, yb, cz + nz * r_face - tz * hw)
		var fbr := Vector3(cx + nx * r_face + tx * hw, yb, cz + nz * r_face + tz * hw)
		var ftl := Vector3(cx + nx * r_face - tx * hw, yt, cz + nz * r_face - tz * hw)
		var ftr := Vector3(cx + nx * r_face + tx * hw, yt, cz + nz * r_face + tz * hw)
		var bbl := Vector3(cx + nx * r_back - tx * hw, yb, cz + nz * r_back - tz * hw)
		var bbr := Vector3(cx + nx * r_back + tx * hw, yb, cz + nz * r_back + tz * hw)
		var btl := Vector3(cx + nx * r_back - tx * hw, yt, cz + nz * r_back - tz * hw)
		var btr := Vector3(cx + nx * r_back + tx * hw, yt, cz + nz * r_back + tz * hw)
		# Fundul nisei, privit dinspre exterior.
		_quad(st, bbl, bbr, btr, btl)
		# Peretele din stanga si cel din dreapta.
		_quad(st, fbl, bbl, btl, ftl)
		_quad(st, bbr, fbr, ftr, btr)
		# Buiandrugul (tavanul nisei).
		_quad(st, btl, btr, ftr, ftl)


## Un patrulater ca doua triunghiuri, in ordinea data.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(d)
