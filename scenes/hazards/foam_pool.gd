@tool
class_name FoamPool
extends Node3D
## Bazin de spumă albă la baza unei cascade (POI C — Stirling, Fiordland).
##
## De ce există fișierul ăsta și nu încă un GLB. `WaterfallVisual` (cod) are
## deja o placă de spumă + un inel animat la baza perdelei — dar amândouă sunt
## dimensionate pe `size.z` al hazardului (30 m, rază efectivă locală ~15-16 m
## de-a lungul drumului) și centrate STRICT pe axa cascadei. Verdictul runda 5
## ("lipsește bazinul alb, apa dispare în iarbă") a fost verificat pe captură +
## cifre, nu presupus: la frac 0.28 mașina e la 36,7 m de centrul perdelei
## (0.297 × 2159,2 m), la 0.31 la 28,1 m — amândouă DINCOLO de raza plăcii de
## cod (~15-16 m local Z). Perdeaua se vede mică la orizont, dar solul de la
## baza ei e prea departe ca placa/inelul din cod să se citească din unghiul
## camerei de joc la aceste fracții — de-aia „cade în iarbă": nu lipsește
## spuma, lipsește ce se vede DE LA DISTANȚĂ, lateral pe marginea drumului.
##
## Coordonatorul a exclus modificarea shader-ului/`WaterfallVisual` — bazinul
## de-aici e decor STATIC suplimentar, nu o reparație a hazardului. Nu există
## niciun GLB de „bazin/spumă" în kitul Fiordland (`fiordland_masuratori.md`):
## soluția fără GLB nou e geometrie procedurală pe atlas, exact ca reperele
## din `FogCorridorHazard` (`PaletteBox.instance`, ZERO material nou — garda
## de materiale numără doar `probe_decor`, care nu adaugă niciunul aici).
##
## Compozitie (aranjamentul-bate-numarul): 6-10 petice joase, turtite,
## suprapuse cu jitter de poziție/rotație/scară — nu un dreptunghi curat, ca
## să citească drept spumă neregulată, nu placă de beton. Toate pe slotul
## FOAM_WHITE (22), aceeași paletă ca restul lumii.
##
## Coliziune: NICIUNA (`collision_layer/mask = 0`) — memoria
## `suprafete-cu-goluri-si-praguri`: petice de 0.15-0.35 m înălțime lângă
## marginea drumului ar deveni prag/zid dacă ar primi corp fizic. E decor pur,
## la fel ca placa de spumă a `WaterfallVisual` (care nu are nici ea corp).

const FOAM_SLOT: int = 22   # Palette.FOAM_WHITE


## RUNDA 5, a doua iterație (verificat pe captură): petice plate de 0.12-0.30 m
## la 28-37 m de cameră (unghiul camerei de joc, 10 m sus/12,5 m spate) sunt
## sub pragul de vizibilitate — se pierd în perspectivă lângă asfalt, la fel ca
## placa de spumă din `WaterfallVisual` pe care veneau să o completeze (proba
## de sanity la 0.28: covorul abia se distinge, un fir alb mic la orizont).
## Coordonatorul a numit și a doua variantă valabilă: „bolovani uzi cu
## spumă" — geometrie cu RELIEF, nu doar covor pe sol. Movile mai înalte
## (0.5-0.95 m), care ies din siluetă și prind lumină/umbră proprie, se citesc
## de la distanță; petece joase rămân doar ca umplutură între ele.
func build(patch_count: int, radius: float, seed: int) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in patch_count:
		var ang := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(0.0, radius)
		var at := Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
		var tall := rng.randf() < 0.45   # ~45% movile inalte, restul umplutura joasa
		var w := rng.randf_range(1.1, 2.1)
		var d := rng.randf_range(1.0, 1.9)
		var h := rng.randf_range(0.5, 0.95) if tall else rng.randf_range(0.18, 0.35)
		var yaw := rng.randf_range(0.0, TAU)
		var mi := PaletteBox.instance(Vector3(w, h, d), FOAM_SLOT,
			at + Vector3.UP * h * 0.5, Basis(Vector3.UP, yaw))
		mi.name = "Petic%d" % i
		add_child(mi)
	# miez central, mai lat decat inalt, care leaga grupul de sol.
	var core := PaletteBox.instance(Vector3(radius * 1.1, 0.4, radius * 0.9),
		FOAM_SLOT, Vector3.UP * 0.2)
	core.name = "Miez"
	add_child(core)


func _ready() -> void:
	if patch_count > 0 and get_child_count() == 0:
		build(patch_count, radius, rng_seed)


@export var patch_count: int = 8
@export var radius: float = 3.0
@export var rng_seed: int = 0
