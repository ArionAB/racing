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


func _ready() -> void:
	_deform()


func _deform() -> void:
	# Fara munca daca instanta e lasata pe valorile neutre: hornurile care chiar
	# trebuie sa ramana drepte nu platesc duplicarea mesh-ului.
	if is_equal_approx(ovality, 1.0) and is_zero_approx(lean_deg) \
			and is_zero_approx(bulge) and is_zero_approx(flute_depth) \
			and is_zero_approx(noise_amount):
		return
	var meshes: Array[MeshInstance3D] = []
	_collect(self, meshes)
	for mi in meshes:
		_deform_mesh(mi)


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
