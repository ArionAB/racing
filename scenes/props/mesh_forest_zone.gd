class_name MeshForestZone
extends Resource
## O ZONA de padure in masa pentru [MeshForest]: unde se pun arborii, din ce
## specii, cat de dens. Resursa (nu dictionar) ca sa se poata edita in Inspector
## si ca generatorul pistei sa scrie doar date, zero cod.

enum Kind {
	## Fasie de-a lungul soselei principale, intre doua fractii de tur, la
	## `lat_min`..`lat_max` metri de AXA, pe una sau pe ambele parti.
	RING,
	## Disc in coordonate de lume (versant, deal, pata de ginkgo).
	DISC,
}
## Partea fasiei: 0 = ambele, 1 = dreapta fata de sensul de mers, -1 = stanga.
enum Flank { BOTH = 0, RIGHT = 1, LEFT = -1 }

@export var label: String = "zona"
@export var kind: Kind = Kind.RING

@export_group("Fasie (RING)")
@export_range(0.0, 1.0, 0.001) var frac_from: float = 0.0
@export_range(0.0, 1.0, 0.001) var frac_to: float = 1.0
@export var side: Flank = Flank.BOTH
@export_range(0.0, 200.0, 0.5, "suffix:m") var lat_min: float = 9.0
@export_range(0.0, 200.0, 0.5, "suffix:m") var lat_max: float = 60.0

@export_group("Disc (DISC)")
## Centrul in coordonate de lume; Y ramane neutilizat (cota vine din teren).
@export var center: Vector3 = Vector3.ZERO
@export_range(1.0, 300.0, 0.5, "suffix:m") var radius: float = 40.0

@export_group("Specii")
## Numele speciilor din [constant MeshForest.SPECIES]; ponderile merg paralel.
@export var species: PackedStringArray = PackedStringArray()
@export var weights: PackedFloat32Array = PackedFloat32Array()

@export_group("Densitate si reguli")
## Pasul grilei cu zgomot (m): un arbore la ~spacing^2 m2.
@export_range(0.5, 40.0, 0.1, "suffix:m") var spacing: float = 4.0
## Cat de aproape de MARGINEA soselei are voie sa stea un arbore (primul rand
## de langa drum e al DecorManual-ului, cu coliziune).
@export_range(0.0, 60.0, 0.5, "suffix:m") var edge_clear_m: float = 9.0
## Pana la cate metri de margine arborii arunca umbra; dincolo, `cast_shadow`
## OFF (brief §6). 0 = niciun arbore din zona nu arunca umbra.
@export_range(0.0, 80.0, 0.5, "suffix:m") var shadow_m: float = 25.0
## Cat de jos SUB cota soselei are voie sa fie solul (m). Pune-l mic pe
## zonele cu iaz/rau (F, G, H), ca sa nu urce arbori in apa; mare = fara limita.
@export_range(0.0, 200.0, 0.5, "suffix:m") var max_below_road_m: float = 200.0
## Zona isi REZERVA suprafata: zonele de dupa ea nu mai pun nimic in interior
## (petele de ginkgo se pun INAINTEA artarilor si ii scot din pata).
@export var claim: bool = false
## Scara minima / maxima per instanta (se inmulteste cu cea a speciei).
@export_range(0.3, 3.0, 0.01) var scale_min: float = 0.85
@export_range(0.3, 3.0, 0.01) var scale_max: float = 1.2
## Distanta peste care feliile zonei nu se mai randeaza (0 = nelimitat).
## Se masoara de la centrul AABB al feliei, deci tine-o larg (peste ceata).
@export_range(0.0, 600.0, 1.0, "suffix:m") var view_m: float = 0.0
## Semanta zonei (aceeasi pista = aceeasi padure).
@export var seed_value: int = 1
