@tool
class_name TrackFromPath
extends Track
## Pista custom editabila VIZUAL in editorul Godot:
##  1. deschide scena (ex. Track01.tscn)
##  2. selecteaza nodul copil "Path" — apar gizmo-urile curbei in viewport
##  3. trage punctele / adauga puncte noi (toolbar-ul Path3D de sus)
##  4. bifeaza "Regenerate" in Inspector pe nodul radacina -> pista se
##     reconstruieste pe loc (asfalt, pereti, borduri, decor, tot)
##  5. salveaza scena — doar curba se salveaza; restul se genereaza mereu
##
## MUNTI SI DEALURI: adauga noduri [TerrainPeak] oriunde sub radacina si
## trage-le in viewport — X/Z = unde sta masivul, Y = cota varfului, raza in
## Inspector. La Regenerate terenul se ridica spre ele; asfaltul ramane mereu
## la cota curbei (banda de protectie din TrackSideSampler._lift_peaks).
##
## SCURTATURI: adauga noduri [TrackBranch] (tot Path3D) si deseneaza doar
## MIJLOCUL benzii — capetele se lipesc singure de bucla principala. Latimea si
## `wet` sunt in Inspector; vezi antetul lui TrackBranch pentru de ce o
## scurtatura fara contragreutate nu e o decizie, ci un cadou.
##
## Nota: generatorul isi face propriile tangente netede (Catmull-Rom) din
## POZITIILE punctelor — manerele bezier ale curbei sunt ignorate.

@export var custom_name: String = "Pista noua"
@export_enum("forest", "desert", "island", "baikal", "stromboli", "chongqing",
	"cappadocia") var custom_theme: String = "forest"
@export var custom_half_width: float = 7.0
## Unghiul soarelui pentru pista asta, cand tema nu-l nimereste.
##
## (0,0,0) = lasa tema in pace, deci pistele care nu-l ating nu se schimba.
## x = elevatia (negativ), y = azimutul. Sta AICI, ca nod editabil, si nu doar
## in tema, fiindca e reglaj de PISTA: depinde de directia in care merge chiar
## traseul asta, si traseul se muta din editor. Cand s-a mutat ultima data,
## azimutul din tema a ramas pe traseul vechi si umbrele au iesit din cadru.
## Se masoara cu tools/ProbeCappAzimut (baleiaza cercul pe tot turul) si cu
## tools/ProbeCappUmbraCadru (duce varful umbrei si il cauta pe banda).
##
## Pe Cappadocia (-17, 25) compromisul e masurat pe POZA, ca abatere de
## luminanta pe carosabil, si NU e curat pe toate fractiile:
##                  frac 0.06   frac 0.10
##   azimut vechi      34.52       23.99
##   azimut nou        24.32       25.05
## 0.06 pierde mai mult decat castiga 0.10. Se accepta fiindca benzile de la
## 0.06 erau facute de un soare de VEST care raka in lungul drumului — adica de
## chiar greseala care muta rasaritul din vale. Izolat prin rulare cu azimutul
## nou si elevatia veche: la 0.06 cifra e 24.15 la orice elevatie, deci
## pierderea vine din azimut, nu din inaltarea soarelui. Elevatia (13 -> 17)
## aduce singurul castig real: la 0.10, 20.34 -> 25.05, fiindca scurteaza
## umbrele cat sa cada PE banda in loc sa treaca pe langa ea.
@export var custom_sun_rotation_deg: Vector3 = Vector3.ZERO
## Stratul de culoare de SUB drum (Valea Rosie pe Cappadocia).
##
## Alpha 0 = stins, deci restul pistelor nu se schimba. Tinteaza terenul de sub
## `custom_strata_line`, cu `custom_strata_fade` metri de cota pentru degrade.
## E oglinda lui rock_band_tint din teme, care tinteaza PESTE o cota.
## Cotele se aleg din histograma terenului, nu din ochi: tools/ProbeCappStrat.
@export var custom_strata_tint: Color = Color(0, 0, 0, 0)
@export var custom_strata_line: float = 0.0
@export var custom_strata_fade: float = 12.0
## Din ce e facut drumul — schimba materialul, marcajele si urmele lasate de
## masini. Vezi Track.road_surface (e o alegere a PISTEI, nu a temei).
@export_enum("asphalt", "dirt", "snow") var custom_road_surface: String = "asphalt"
## Poarta de start a pistei — GLB-ul ales cu butonul de fisier.
##
## Gol = ce cere tema, si daca nici tema nu cere nimic, poarta implicita.
## Scrie "none" de mana ca sa NU ai poarta deloc.
##
## Modelul se scaleaza singur pe latimea soselei si isi ia coliziunea pe
## picioare din bbox, deci orice arcada merge fara cifre de potrivit. Atlasul
## comun se aplica automat, asa ca GLB-ul are nevoie de UV-uri spre sloturi
## de paleta ca restul assetelor — vezi docs/style_bible.md §4.
@export_file("*.glb") var custom_gate_model: String = ""
## Cota marii, RELATIV la media cotelor soselei (doar tema "island").
## Vezi Track.sea_level_offset — nu e o cota absoluta in lume.
@export var custom_sea_level_offset: float = -7.0
@export var custom_ramp_fracs: Array[float] = []
@export var custom_hazard_fracs: Array[float] = []
## Conducta sparta care pulseaza apa peste drum (fractii 0..1).
@export var custom_hose_fracs: Array[float] = []
## Situl cu schelet de dinozaur: fiecare Vector2 = (fractie, parte ±1).
@export var custom_dino_spots: Array[Vector2] = []
## Arcade de stanca prin care trece soseaua (fractii 0..1).
@export var custom_arch_fracs: Array[float] = []
## Defilee: intervale (frac_start, frac_end) unde falezele strang drumul de
## ambele parti — inalte, apropiate, fara ferestre. Momentul-semnatura (#28).
@export var custom_gorge_ranges: Array[Vector2] = []
## Valuri care spala soseaua: fractii pe tur (#247).
##
## Cere o tema cu MARE (`water`) — valul isi ia linia apei de acolo. Pe o pista
## fara mare, se sare cu un avertisment in Output, in loc sa iasa o creasta de
## apa plutind peste desert.
@export var custom_wave_fracs: Array[float] = []
## Portiuni UDE de sosea: intervale (frac_start, frac_end) unde grip-ul lateral
## scade si asfaltul se vede mai inchis la culoare (#246).
##
## Spre deosebire de `wet` de pe o scurtatura, astea sunt pe traseul PRINCIPAL:
## nu-ti dau o ruta alternativa, iti schimba linia pe drumul pe care oricum
## mergi. Un interval poate trece peste linia de start (ex. 0.95 -> 0.05).
@export var custom_wet_ranges: Array[Vector2] = []
## Portiuni de GHEATA pe traseul principal: intervale (frac_start, frac_end).
## Alta suprafata, nu asfalt ud: grip mult mai jos (drift-ul devine modul de
## condus), banda proprie fara borduri/linie/umeri, culoar marcat cu bete cu
## stegulete, si vantul temei sufla doar aici. Vezi Track._ice_ranges.
@export var custom_ice_ranges: Array[Vector2] = []

## Intervalele de suprafata AFANATA (cenusa, nisip negru adanc). Vezi
## Track._loose_ranges. Pe Stromboli: plaja de la B si buza+coborarea D-E.
@export var custom_loose_ranges: Array[Vector2] = []
## Intrari de mina lipite de perete: fiecare Vector2 = (fractie, parte ±1).
@export var custom_mine_spots: Array[Vector2] = []
## Caruselul: morisca cu vane care matura soseaua (gimmick de timing).
@export var custom_carousel_fracs: Array[float] = []
## Deviatorul: bariera oblica care iti schimba traiectoria (gimmick de linie).
@export var custom_deflector_fracs: Array[float] = []
## Creasta de fly-off: te arunca in aer, cu plasa de respawn dedesubt.
@export var custom_flyoff_fracs: Array[float] = []
## Landmark-uri hero: fiecare Vector3 = (fractie, parte ±1, id-model din
## _LANDMARKS). Desert: 0=turn apa, 1=benzinarie, 2=moara, 3=semn Route 66,
## 4=ecran drive-in, 5=stalp GAS, 12=baraca minerului.
## Okinawa: 6=casa de sat, 7=far, 8=poarta torii, 9/10=shisa (gura deschisa /
## inchisa), 11=zid gusuku.
@export var custom_landmarks: Array[Vector3] = []
## Rapele: (frac_start, frac_end, adancime_m, latura ±1 sau 0 = ambele).
## Terenul urmareste soseaua peste tot; aici il sapam inapoi, ca sa existe unde
## sa cazi. Fara o rapa sub un fly-off, zbori si aterizezi linistit pe nisip.
@export var custom_ravines: Array[Vector4] = []
## Care dintre rapele de mai sus sunt CORNISE (indici in `custom_ravines`):
## buza cade la jumatate de metru de asfalt, ca pe un drum de munte sau pe un
## viaduct — nu valea lina de sub un fly-off. Vezi Track._cornice_ravines.
@export var custom_cornice_ravines: Array[int] = []
## Care dintre rapele de mai sus sunt VIADUCTE (indici in `custom_ravines`):
## terenul coboara si SUB sosea, tablierul ramane in aer, iar pilele/arcadele
## din kit se pun sub el (Baikal, viaductul Circum-Baikal). Se combina cu
## `custom_cornice_ravines` (cazi de pe margine). Vezi Track._viaduct_ravines.
@export var custom_viaduct_ravines: Array[int] = []
## Care dintre CORNISE sunt taiate VERTICAL (indici in `custom_ravines`):
## peretele de sub buza cade drept, nu in panta. Se cere doar unde ceva urca pe
## langa faleza — baloanele ancorate de sub cornisa Vaii Rosii. Vezi
## Track._scarp_ravines.
@export var custom_scarp_ravines: Array[int] = []
## PODELE de rapa: (indice in `custom_ravines`, cota ABSOLUTA y). Sapatura nu
## coboara sub cota — o cornisa cu podea e o faleza cu un chei uscat la picior
## (Chongqing D: Hongya Dong sta pe el, apa incepe dincolo). Vezi
## Track._ravine_floors.
@export var custom_ravine_floors: Array[Vector2] = []

## LATIMEA rapelor: (indice de rapa, metri de la buza). Vezi
## Track._ravine_widths. Fara ea saparea se intinde lateral la infinit si valea
## n-are mal opus — faleza citeste ca bordura de sant.
@export var custom_ravine_widths: Array[Vector2] = []
## Vezi [method Track._ravine_floor_slopes].
@export var custom_ravine_floor_slopes: Array[Vector2] = []
## PARAPET DECLARAT: (frac_start, frac_end, regim RAIL_*, latura +-1 sau 0).
## Vezi Track._rail_segments — pe o pista fara gard (`walls: false`) singurul
## regim cu efect e RAIL_POSTS: stalpi rari pe buza, fara coliziune.
@export var custom_rail_segments: Array[Vector4] = []
## APA declarata, ca poligon in plan XZ (coordonate de lume): se sapa la
## `lagoon_depth` sub media soselei, cu mal lin (TrackSideSampler.LAGOON_*).
## E singurul fel de a pune apa DOAR pe o parte a lumii: `seabed_drop` inunda
## tot exteriorul buclei (insula), iar un oras la confluenta are apa pe doua
## laturi si dealuri pe celelalte. Gol = fara. Vezi Track._lagoon_points.
@export var custom_lagoon: Array[Vector2] = []
## PASAJE PE PILONI: intervale de tur (fractii x..y) in care soseaua trece in
## aer PESTE un alt tronson al aceleiasi piste. Terenul nu urca dupa tablier,
## tablierul primeste fusta + parapet, pilonii vin din DecorManual. Vezi
## Track._overpass_ranges.
@export var custom_overpass_ranges: Array[Vector2] = []
## Bolovani care cad de pe faleza.
@export var custom_rockfall_fracs: Array[float] = []
## Treceri de cale ferata. Trenul ucide la contact si te repune.
@export var custom_train_fracs: Array[float] = []
## Tren PE SENS: sina in lungul soselei, trenul vine din fata (Baikal, viaduct).
## Cere o portiune dreapta (~100 m) — sina se scurteaza singura la cat e drept.
@export var custom_train_along_fracs: Array[float] = []
## Torosuri (Baikal): creste de gheata peste culoar, kicker-e naturale mici
## (0.75 m). Vezi Track._build_hummock.
@export var custom_hummock_fracs: Array[float] = []
## Campuri de placi crapate (Baikal): intervale (frac_start, frac_end) pe care
## gheata se sparge in placi Voronoi cu fisuri de apa neagra si placi „vii"
## care se inclina si se rup. Au sens doar pe o portiune din
## `custom_ice_ranges`. Vezi IceFieldHazard.
@export var custom_ice_field_ranges: Array[Vector2] = []
## Sectoare cu latime proprie: (frac_start, frac_end, half_width). Restul
## pistei ramane la `custom_half_width`, iar trecerea se face pe o rampa de
## Track.WIDTH_RAMP_M metri de fiecare parte — deci un sector mai scurt decat
## doua rampe nu-si atinge niciodata latimea ceruta. Vezi Track.width_at.
@export var custom_width_segments: Array[Vector3] = []
## Regenerate vine din Track (checkbox-ul e mostenit); aici doar ne aplicam
## intai exporturile custom_* si curba de pornire. Citirea punctelor din
## nodul "Path" traieste tot in Track — orice pista o are, nu doar asta.
func _editor_regenerate() -> void:
	_apply_custom()
	_ensure_starter_curve()
	rebuild()

func _ready() -> void:
	_apply_custom()
	_ensure_starter_curve()
	super._ready()

func _apply_custom() -> void:
	track_name = custom_name
	half_width = custom_half_width
	road_surface = custom_road_surface
	sea_level_offset = custom_sea_level_offset
	apply_theme(custom_theme)
	# DUPA apply_theme: aici e suprascrierea pistei peste ce cere tema.
	gate_model = custom_gate_model

## Abaterile pistei de la tema ei, din nodurile editabile de mai sus.
##
## Se construieste doar ce e chiar setat: un dictionar gol inseamna "tema
## nemodificata", si `_with_overrides` intoarce atunci baza neatinsa. Asa
## pistele care nu ating cheile astea raman bit-identice.
func _theme_overrides() -> Dictionary:
	var over := {}
	if custom_sun_rotation_deg != Vector3.ZERO:
		over["sun_rotation_deg"] = custom_sun_rotation_deg
	if custom_strata_tint.a > 0.0:
		over["strata_tint"] = custom_strata_tint
		over["strata_line"] = custom_strata_line
		over["strata_fade"] = custom_strata_fade
	return over


func _ramp_fracs() -> Array[float]:
	return custom_ramp_fracs

func _hazard_fracs() -> Array[float]:
	return custom_hazard_fracs

func _hose_fracs() -> Array[float]:
	return custom_hose_fracs

func _dino_spots() -> Array[Vector2]:
	return custom_dino_spots

func _arch_fracs() -> Array[float]:
	return custom_arch_fracs

func _gorge_ranges() -> Array[Vector2]:
	return custom_gorge_ranges

func _wet_ranges() -> Array[Vector2]:
	return custom_wet_ranges

func _ice_ranges() -> Array[Vector2]:
	return custom_ice_ranges

func _loose_ranges() -> Array[Vector2]:
	return custom_loose_ranges


func _wave_fracs() -> Array[float]:
	return custom_wave_fracs

func _mine_spots() -> Array[Vector2]:
	return custom_mine_spots

func _carousel_fracs() -> Array[float]:
	return custom_carousel_fracs

func _deflector_fracs() -> Array[float]:
	return custom_deflector_fracs

func _flyoff_fracs() -> Array[float]:
	return custom_flyoff_fracs

func _landmark_spots() -> Array[Vector3]:
	return custom_landmarks

func _ravines() -> Array[Vector4]:
	return custom_ravines


func _rail_segments() -> Array[Vector4]:
	return custom_rail_segments

func _cornice_ravines() -> Array[int]:
	return custom_cornice_ravines

func _viaduct_ravines() -> Array[int]:
	return custom_viaduct_ravines

func _scarp_ravines() -> Array[int]:
	return custom_scarp_ravines

func _ravine_floors() -> Array[Vector2]:
	return custom_ravine_floors


func _ravine_widths() -> Array[Vector2]:
	return custom_ravine_widths


func _ravine_floor_slopes() -> Array[Vector2]:
	return custom_ravine_floor_slopes


func _lagoon_points() -> Array[Vector2]:
	if custom_lagoon.is_empty():
		return super()
	return custom_lagoon

func _overpass_ranges() -> Array[Vector2]:
	return custom_overpass_ranges

func _rockfall_fracs() -> Array[float]:
	return custom_rockfall_fracs

func _train_fracs() -> Array[float]:
	return custom_train_fracs

func _ice_field_ranges() -> Array[Vector2]:
	return custom_ice_field_ranges

func _train_along_fracs() -> Array[float]:
	return custom_train_along_fracs

func _hummock_fracs() -> Array[float]:
	return custom_hummock_fracs

func _width_segments() -> Array[Vector3]:
	return custom_width_segments

## Daca curba lipseste sau are prea putine puncte, o umplem cu un circuit
## de pornire decent — ai de unde sa incepi sa tragi de puncte.
func _ensure_starter_curve() -> void:
	var path := get_node_or_null("Path") as Path3D
	if path == null:
		path = Path3D.new()
		path.name = "Path"
		add_child(path)
		if Engine.is_editor_hint():
			path.owner = get_tree().edited_scene_root
	if path.curve != null and path.curve.point_count >= 3:
		return
	var starter := Curve3D.new()
	for p in [Vector3(0, 0, 0), Vector3(70, 0, 0), Vector3(110, 2, -35),
			Vector3(105, 5, -85), Vector3(60, 2, -115), Vector3(-10, 0, -110),
			Vector3(-50, 3, -75), Vector3(-45, 1, -30)]:
		starter.add_point(p)
	path.curve = starter
