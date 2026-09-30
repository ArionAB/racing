class_name GateFunnel
extends StaticBody3D
## Tesirea ușciorilor unei porti a fortului (Jodhpur, POI E), pe fata dinspre
## care vii. Copil al instantei de poarta, deci lucreaza in coordonatele ei:
## axa X a portii e tangenta drumului (masina merge spre +X), golul e pe Z,
## +-HALF_GAP.
##
## [b]De ce exista.[/b] ProbeRace pe scena integrata (seed 11, t 47,5-55 s):
## Luna (Pompierii) intra in Jai Pol la 25 m/s umar la umar cu alt AI, e
## impinsa la lat 3,2 si prinde cu coltul fata-dreapta MUCHIA de 90 de grade
## dintre fata turnului si golul portii. Ramane cu botul intors ~35 de grade
## in peretele interior al golului, cu volanul la capat; anti-blocajul da
## marsarier 0,75 s, dar Nyx (Autobuzul) e deja lipit in spate: 6 s de
## `[blocaj]` pentru doua masini. Colizorul portii e trimesh-ul exact al
## pietrei (`mesh`, prin el se TRECE), deci muchia e ascutita.
##
## Tesirea e o prisma triunghiulara in fata fiecarui uscior, cu ipotenuza la
## ~45 de grade: un colt de masina care loveste fata turnului langa gol
## aluneca spre gol in loc sa se agate. Nu ingusteaza golul: varful dinspre
## gol sta exact pe muchia lui (HALF_GAP) si INAUNTRUL pietrei, restul e
## in afara asfaltului (strangerea lasa semilatimea 3,5 < 3,58).
##
## Nu se vede (nu are mesh): stă pe umarul de 0,08..LEG m din fata turnului,
## sub linia caroseriei, unde ochiul vede oricum baza turnului.

## Golul portii (jumatate), masurat ca GOL (jodhpur_masuratori.md §4): 7,16 m.
const HALF_GAP: float = 3.58
## Fata turnurilor pe X (8,64 / 2).
const FACE_X: float = 4.32
## Catetele tesirii (m): cat intra in fata turnului lateral si cat iese in fata
## lui spre masina.
@export var leg: float = 1.4
## Cat intra prisma in piatra, ca sa nu ramana fanta intre ea si turn.
@export var bite: float = 0.25
@export var height: float = 3.2


func _ready() -> void:
	for side: float in [1.0, -1.0]:
		var pts := PackedVector3Array()
		for y: float in [-0.6, height]:
			pts.append(Vector3(-FACE_X + bite, y, side * HALF_GAP))
			pts.append(Vector3(-FACE_X + bite, y, side * (HALF_GAP + leg)))
			pts.append(Vector3(-FACE_X - leg, y, side * (HALF_GAP + leg)))
		var shape := ConvexPolygonShape3D.new()
		shape.points = pts
		var cs := CollisionShape3D.new()
		cs.name = "Tesire%s" % ("St" if side > 0.0 else "Dr")
		cs.shape = shape
		add_child(cs)
