extends RefCounted
## Constructor de mesh VIZUAL pentru rampele de saritura (issue #610).
##
## Coliziunea rampei NU trece pe aici: ramane exact prisma veche (profilul de
## rulare, deci airtime-ul, e neschimbat). Aici se construieste doar ce se vede:
## un volum INCHIS — laterale, spate si buza coborate SUB cota drumului, ca din
## nicio vedere de joc sa nu se zareasca un gol intre rampa si asfalt (sau, la
## trambulina de peste canal, sub ea).
##
## Doua suprafete, doua materiale: `body` (corpul, clasa temei) si `cap` (banda
## de buza, o clasa a temei in contrast, ca rampa sa se citeasca de departe).
## Culoarea de vertex doar INTUNECA (SurfaceTool taie la [0,1]): o folosim ca AO
## fals — fusta mai inchisa spre sol, scandurile mai inchise la rost.
##
## Infasurarea: Godot tine ca fata din fata triunghiul in sens ORAR, iar
## `generate_normals` o presupune. In loc sa ne bazam pe ordinea in care scriem
## varfurile, fiecare triunghi primeste directia in care trebuie sa priveasca
## (`out`) si se intoarce singur daca e invers.

## Cat coboara fustele sub cota drumului (m). Acopera caderea de camber si
## panta pe cei ~14 m ai rampei fara sa se vada ca rampa „sta pe stalpi”.
const SKIRT: float = 0.45
## Latimea benzii de buza, masurata pe rampa (m).
const CAP_RUN: float = 1.5
## Cat se ridica banda fata de suprafata de dedesubt, ca sa nu faca z-fighting.
## Doar vizual (coliziunea e pe corp): 2.5 cm nu se simte la volan.
const CAP_LIFT: float = 0.025
## Culoarea de vertex la baza fustei si la rostul dintre scanduri.
const AO: float = 0.55
## Celulele „stinse” ale benzii de buza.
const STRIPE_DARK: float = 0.42

var body := SurfaceTool.new()
var cap := SurfaceTool.new()
## UV planar optional (puntea de lemn din Kyoto: scandurile din `_wood_deck_material`
## se intind dupa UV, nu dupa proiectie triplanara).
var uv_on: bool = false
var uv_base: Vector3 = Vector3.ZERO
var uv_side: Vector3 = Vector3.RIGHT
var uv_dir: Vector3 = Vector3.FORWARD


func _init() -> void:
	body.begin(Mesh.PRIMITIVE_TRIANGLES)
	cap.begin(Mesh.PRIMITIVE_TRIANGLES)


static func shade(v: float) -> Color:
	return Color(v, v, v)


func _vertex(st: SurfaceTool, p: Vector3, c: Color) -> void:
	st.set_color(c)
	if uv_on:
		var rel := p - uv_base
		st.set_uv(Vector2(rel.dot(uv_side), rel.dot(uv_dir) + rel.y) / 3.5)
	st.add_vertex(p)


## Triunghi cu fata spre `out`.
func tri(st: SurfaceTool, out: Vector3, a: Vector3, b: Vector3, c: Vector3,
		ca: Color = Color.WHITE, cb: Color = Color.WHITE, cc: Color = Color.WHITE) -> void:
	# (b-a) x (c-a) arata SPRE interior pentru un triunghi orar vazut din afara.
	if (b - a).cross(c - a).dot(out) > 0.0:
		var tp := b
		b = c
		c = tp
		var tc := cb
		cb = cc
		cc = tc
	_vertex(st, a, ca)
	_vertex(st, b, cb)
	_vertex(st, c, cc)


## Patrulater a-b-c-d (in ordine pe contur), fata spre `out`.
func quad(st: SurfaceTool, out: Vector3, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		ca: Color = Color.WHITE, cb: Color = Color.WHITE,
		cc: Color = Color.WHITE, cd: Color = Color.WHITE) -> void:
	tri(st, out, a, b, c, ca, cb, cc)
	tri(st, out, a, c, d, ca, cc, cd)


## Banda de buza, in celule alternante de-a latul drumului (`cells` celule, ca
## dungile unui marcaj de santier): un marcaj in paleta lumii (clasa de buza a temei,
## alternand cu varianta ei intunecata), nu galbenul de jucarie. Culoarea de
## vertex doar intuneca, deci „aprins” = alb, „stins” = [constant STRIPE_DARK].
## `a0`/`b0` = capetele randului dinspre drum, `a1`/`b1` = dinspre buza.
func stripes(st: SurfaceTool, out: Vector3, a0: Vector3, b0: Vector3,
		a1: Vector3, b1: Vector3, cells: int = 8) -> void:
	for k in cells:
		var t0 := float(k) / float(cells)
		var t1 := float(k + 1) / float(cells)
		var c := Color.WHITE if k % 2 == 0 else shade(STRIPE_DARK)
		quad(st, out, a0.lerp(b0, t0), a0.lerp(b0, t1), a1.lerp(b1, t1), a1.lerp(b1, t0),
			c, c, c, c)


## Un mesh gol (sau fara suprafete) intoarce null.
static func commit(st: SurfaceTool) -> ArrayMesh:
	var m := st.commit()
	if m == null or m.get_surface_count() == 0:
		return null
	return m


## Cota la care se opresc fustele sub un punct de rampa: sub drumul din
## apropiere (centrul coapt — fizica merge pe fasia plata de la cota asta) si
## sub propria cota a punctului, minus [constant SKIRT]. Cautarea e locala (±`reach`
## puncte coapte in jurul indexului rampei): pe un pasaj, cel mai apropiat punct
## in plan de pe TOATA bucla ar putea fi drumul de deasupra.
static func floor_y(baked: PackedVector3Array, hint: int, p: Vector3, reach: int = 60) -> float:
	var n := baked.size()
	var best := p.y
	var best_d := INF
	for k in range(-reach, reach + 1):
		var q := baked[((hint + k) % n + n) % n]
		var d := Vector2(p.x - q.x, p.z - q.z).length_squared()
		if d < best_d:
			best_d = d
			best = q.y
	return minf(p.y, best) - SKIRT
