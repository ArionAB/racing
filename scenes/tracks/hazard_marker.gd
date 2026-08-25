@tool
class_name HazardMarker
extends Marker3D
## Un gimmick declarat, editabil VIZUAL: tragi nodul pe sosea, alegi tipul in
## Inspector, bifezi Regenerate pe radacina pistei, si obstacolul apare acolo.
##
## Nodul e o DECLARATIE, nu obstacolul insusi — exact tiparul lui [TerrainPeak],
## [TrackBranch] si [TrackChannel]. [Track] aduna nodurile astea si le trece
## prin ACELEASI `_build_*` pe care le folosesc si pistele scrise in cod, deci
## exista o singura implementare per gimmick, hranita in doua feluri.
##
## Ce se declara si ce se DERIVA — impartirea e tot ce conteaza aici:
##   - declari: tipul, POZITIA (tragi nodul in viewport) si, optional, cu ce
##     model se imbraca obstacolul (vezi grupul "Model")
##   - se deriva: fractia pe traseu, semilatimea soselei acolo, lateralul si
##     directia drumului
##
## Motivul e lectia din #234, scrisa in `Track._node_branches`: un capat de
## banda scris de mana ramane in urma la prima ajustare a traseului si lasa o
## treapta in aer. Aici e la fel — o fractie scrisa de mana (`0.62`) nu spune
## nimic cand muti doua puncte de control, in timp ce un nod tras pe asfalt
## ramane pe asfalt fiindca fractia se recalculeaza la fiecare Regenerate.
##
## De aceea si Marker3D, nu MeshInstance3D: obstacolul adevarat e cel construit
## la Regenerate, cu coliziunea si mecanica lui. Nodul e doar unde-ul.
##
## Un ROCKFALL poate primi un copil Path3D: traseul pe care se rostogoleste
## bolovanul (de unde se desprinde, pe unde coboara, unde iese). Vezi grupul
## „Rostogolire" si `route_curve_in()`. Fara Path3D, pista deduce singura
## versantul si piatra cade pe ciclul vechi.
##
## Y-ul nodului e IGNORAT deliberat. Fiecare gimmick isi asaza singur cota:
## bolovanul cade pe asfalt, trenul sta la cota drumului cu estacada sub el,
## caruselul se planteaza in mijlocul soselei. Un Y luat de la nod ar insemna ca
## un nod tras cu 3 m prea sus lasa un carusel plutind — si nimeni nu s-ar uita
## la Y-ul nodului cand ar cauta de ce.

## Tipurile care se pot planta manual.
##
## Sunt exact gimmickurile care se plaseaza azi PE O FRACTIE din traseu, adica
## alea pentru care nodul e o traducere directa. Lipsesc deliberat:
##   - LiftBridge: se leaga de un canal ([TrackChannel]), nu de o fractie — se
##     declara acolo, cu `jump: false`;
##   - WaterHose: conducta sparta e legata de un obiect de decor (teava), nu de
##     un punct oarecare de pe traseu.
##
## WAVE a fost si el exclus la inceput, cu motivul „portiune de sosea, nu obiect
## punctual" — dar motivul nu s-a sustinut la a doua privire (#247): valul se
## construieste dintr-o SINGURA fractie, exact ca tromba, care e in lista de
## cand exista. Excluderea era mostenita de la furtun, nu castigata pe cont
## propriu.
enum Kind {
	SLIDING,    ## bariera/bolovan care matura soseaua dintr-o parte in alta
	ROCKFALL,   ## bolovan care cade de pe faleza pe o banda
	CAROUSEL,   ## morisca plantata in mijlocul drumului
	TRAIN,      ## trecere de cale ferata cu tren
	TYPHOON,    ## tromba care te ridica si te invarte
	DEFLECTOR,  ## panta care te arunca pe cealalta banda
	FLYOFF,     ## creasta care arunca toata pista in aer
	EXCAVATOR,  ## excavatorul ruginit care matura cu bratul
	AVALANCHE,  ## masa de zapada care se rostogoleste peste sosea
	WAVE,       ## val care spala soseaua (cere o tema cu mare)
	ICE_SLAB,   ## camp de placi crapate centrat pe nod (Baikal); vezi IceFieldHazard
	TRAIN_ALONG, ## tren PE SENS: sina in lungul soselei, vine din fata (Baikal)
	FUMAROLE,   ## gura de abur care sufla in rafale peste drum (Stromboli)
}

@export var kind: Kind = Kind.SLIDING

## Pentru DEFLECTOR: pe ce parte a soselei sta panta. Ignorat de restul.
##
## Nu se deduce din pozitia nodului fiindca deflectorul se planteaza pe AXA
## drumului si isi ia latura din semn — un nod tras cu 20 cm peste mijloc ar
## intoarce panta fara ca nimeni sa fi cerut asta.
@export_enum("Dreapta:1", "Stanga:-1") var deflector_side: int = 1

@export_group("Model")

## Ce OBIECT traverseaza soseaua aici. Gol = ce alege tema (vezi
## `Track._build_hazard`), adica exact comportamentul dinainte de #240.
##
## Pana aici, un obstacol tras in viewport iesea mereu imbracat de tema — o
## singura haina pe toata pista — desi mecanica accepta de mult un model per
## pozitie. Alpii au patru obstacole, fiecare din alta parte a lumii lor
## (#224), dar toate patru se puteau declara DOAR din cod, in
## `_hazard_kinds()`. Nodul stia unde, nu si ce, si asta lasa jumatate de
## gimmick in editor.
##
## Regula testoasei (track08) spune ca hazardul apartine LOCULUI in care sta.
## Locul se trage cu mana in viewport; de aici incolo si haina lui.
@export var model: PackedScene = null

## Scara modelului. 1.0 = cat l-a construit Blender.
##
## Implicitul temei (0.52) vine de la bolovanul de canion, modelat la 5 m si
## micsorat la 2.6. Un model din kitul alpin e deja la scara reala, deci ar
## fi micsorat pe nedrept — de-aia scara sta langa model, nu langa tema.
@export_range(0.05, 4.0, 0.01) var model_scale: float = 1.0

## Ce PIESA din GLB se pastreaza (celelalte se arunca). Gol = tot fisierul.
##
## Kiturile isi tin mai multe obiecte intr-un singur fisier —
## `scatter/beach_clutter.glb` are cinci, din care pentru un deflector ne
## trebuie doar `Driftwood_Log`.
@export var model_node: String = ""

## Se uita spre directia in care matura.
##
## Fara asta obiectul ramane pe axele LUMII. La o barca targita e o nepasare
## acceptabila (n-are un "inainte"), la un animal e vizibil gresit: o vaca
## care traverseaza cu umarul inainte nu traverseaza, pluteste.
@export var face_travel: bool = false

## Se rostogoleste in timp ce traverseaza (raza reala o ia din model).
##
## Doar bolovanii. Un car cu fan care se da peste cap traversand ulita e exact
## greseala descrisa la barca sabani.
@export var roll: bool = false

## Cum se misca obstacolul: pendulare fara oprire, sau traversare cu sens.
##
## TRAVERSARE e tractorul din Ignition — asteapta pe acostament, trece, se
## opreste pe partea cealalta. Pendularea ramane implicitul, deci nimic din ce
## exista azi nu se schimba. Doar pentru SLIDING.
@export_enum("Pendulare:0", "Traversare:1") var motion: int = 0

## Clasa de material triplanar (ex. "rock", "snow"). Gol = ce da tema.
##
## O CLASA, nu o textura proprie: garda de materiale din `tools/probe_decor.gd`
## numara materialele per pista, iar un asset care isi aduce propriile texturi
## e exact ce urca numarul ala. Vezi CLAUDE.md §texturi.
@export var tri_class: String = ""

@export_group("Rostogolire")

## Doar pentru ROCKFALL, cand nodul are un copil Path3D cu traseul.
##
## Traseul se DESENEAZA, nu se declara in cifre: adaugi un Path3D sub nod, pui
## primul punct sus pe deal (de unde se desprinde piatra), duci curba peste
## sosea si o termini unde vrei sa dispara. Curba e drumul pe care CALCA
## bolovanul — o desenezi pe suprafata terenului, centrul lui sta cu o raza mai
## sus. Bolovanul se rostogoleste continuu pe toata lungimea, dispare la capat,
## sta `rock_pause` secunde si o ia de la inceput.
##
## Fara Path3D, pista masoara singura versantul si piatra cade pe ciclul vechi
## (telegraf, cadere, asezare, retragere) — asa raman pistele care nu si-au
## desenat inca traseul.

## Viteza de croaziera pe traseu (m/s). Porneste din loc si accelereaza pana
## aici; masina merge cu ~25-30, deci 9 se citeste ca bolovan greu, nu proiectil.
@export_range(1.0, 30.0, 0.5) var rock_speed: float = 9.0

## Cat sta ascuns intre doua treceri (secunde).
@export_range(0.0, 20.0, 0.5) var rock_pause: float = 3.0

## Cota din TEREN, nu din curba: desenezi traseul din vederea de sus si
## bolovanul isi ia inaltimea cu un raycast, urca dealul, coboara pe versant
## si SARE de pe buza falezei in parabola. Stins = urmeaza exact cota curbei
## (cand vrei o traiectorie prin aer desenata de mana). Acelasi contract ca
## `PathMover.stick_to_ground`.
@export var rock_stick_to_ground: bool = true


## Ce a declarat nodul despre INFATISAREA obstacolului, in forma pe care o
## citeste deja `Track._build_hazard`: acelasi dictionar ca o intrare din
## `_hazard_kinds()`.
##
## Forma comuna e intentionata. Alternativa — campuri proprii duse separat
## prin `_build_node_hazard` — ar fi insemnat doua feluri de a imbraca acelasi
## obstacol, care s-ar fi tunat separat si ar fi divergat la prima corectie.
## Asa, o pista scrisa in cod si un nod tras in viewport spun acelasi lucru in
## acelasi vocabular.
##
## Cheile lipsesc cand nu s-a declarat nimic, ca `_build_hazard` sa cada pe
## steagurile temei — un dictionar cu `"model": ""` ar fi STINS tema, nu ar fi
## lasat-o sa vorbeasca.
func model_spec() -> Dictionary:
	var spec := {}
	if model != null:
		spec["model"] = model.resource_path
		spec["scale"] = model_scale
		spec["roll"] = roll
		spec["face_travel"] = face_travel
		if not model_node.is_empty():
			spec["model_node"] = model_node
	if not tri_class.is_empty():
		spec["tri_class"] = tri_class
	# Modul de miscare se trimite DOAR cand nu e implicitul. Cheia lipsa
	# inseamna „ce zice pista", exact ca la model — un `motion: 0` trimis mereu
	# ar fi stins o eventuala declaratie de tema, in loc s-o lase sa vorbeasca.
	if motion != 0:
		spec["motion"] = motion
	if kind == Kind.ROCKFALL:
		spec["rock_speed"] = rock_speed
		spec["rock_pause"] = rock_pause
		spec["rock_stick_to_ground"] = rock_stick_to_ground
	return spec


## Traseul bolovanului (primul copil Path3D), adus in coordonatele lui
## `target` (pista). Null daca nodul n-are Path3D sau curba are sub 2 puncte.
##
## Curba se copiaza cu manerele transformate ca VECTORI (nu ca puncte), altfel
## o rotatie a nodului sau a grupului parinte ar indoi traseul.
func route_curve_in(target: Node3D) -> Curve3D:
	for child in get_children():
		var path := child as Path3D
		if path == null or path.curve == null or path.curve.point_count < 2:
			continue
		var out := Curve3D.new()
		var src := path.curve
		for i in src.point_count:
			var p := src.get_point_position(i)
			var gp := path.to_global(p)
			var lp := target.to_local(gp)
			var lin := target.to_local(path.to_global(p + src.get_point_in(i))) - lp
			var lout := target.to_local(path.to_global(p + src.get_point_out(i))) - lp
			out.add_point(lp, lin, lout)
		return out
	return null


func _ready() -> void:
	# Crucea gizmo-ului cat un obstacol tipic, ca sa vezi amprenta inainte de
	# primul Regenerate. Marker3D vine cu 0.25 m — invizibil pe o sosea de 20 m.
	gizmo_extents = 3.0
