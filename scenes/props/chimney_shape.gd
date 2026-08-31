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

## Slotul de paleta pentru grohotis: ACELASI tuf ca hornul, nu un brun mai
## saturat.
##
## Prima incercare a folosit slotul 9 (835C34, luminanta 97, saturatie 0.60)
## alaturi de corpul hornului, care e slotul 8 (C8BDA9, luminanta 190, saturatie
## 0.15). In captura, poalele au iesit portocalii: nu citeau a moloz cazut din
## stanca, ci a inel de alt material pus la baza — adica exact greseala pe care
## trebuiau s-o repare, cu inca o piesa de decor in plus.
##
## Grohotisul e stanca sfaramata, deci are CULOAREA stancii. Se citeste din
## forma si din umbra proprie a pantei, nu dintr-o tenta. Slotul 8 e chiar
## corpul hornului; diferenta de valoare o face unghiul, gratis.
const TALUS_SLOT: int = 8

## Slotul pentru interiorul nisei.
##
## 4 (67421F, luminanta 71) parea destul de inchis pe hartie, dar in cadru usile
## au iesit ca niste dreptunghiuri maro LIPITE pe perete, nu ca deschideri:
## materialul lumii e aproape neumbrit, deci o nisa nu-si face singura umbra, iar
## 71 pe langa 190 (corpul hornului) inca citeste a suprafata luminata.
##
## 26 (1A2A33, luminanta 39) e cel mai inchis din atlas. Nu e maro, e albastru
## foarte inchis — si tocmai de aia merge: o gura de pestera nu are culoarea
## rocii, are culoarea umbrei, iar umbra sub cer senin bate in albastru. Acelasi
## motiv pentru care umbrele din referinta nu sunt gri-maro.
const DOOR_DARK_SLOT: int = 26


## Raportul dintre razele celor doua axe orizontale. 1.0 = cerc (revolutie);
## 0.62 = elipsa vizibil turtita. Peste ~0.5 incepe sa citeasca a perete, nu a
## horn.
## Shading FATETAT pe corpul hornului: fiecare triunghi cu normala lui, in
## loc de normale mediate pe vertecsi. Roca sculptata are muchii care prind
## lumina; un con low-poly smooth-shaded citeste a blob. Vezi `_deform_mesh`.
@export var faceted: bool = true

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


## --- Straturi ORIZONTALE, in trepte ----------------------------------------

## Cat de mult iese stratul DUR in afara, ca fractiune din raza. 0 = stins.
##
## De ce exista. Critica oarba, runda 9: benzile noastre "wrap the form
## diagonally like fabric" — se infasoara pe forma ca o tesatura. Un strat
## geologic real e depus ORIZONTAL: cand peretele coteste, banda coteste cu el
## si RAMANE LA NIVEL. Iar straturile nu sunt egale — cele dure ies in afara,
## cele moi se retrag, si treapta aia e ce face o faleza sa citeasca a stanca
## SAPATA si nu a tapiterie.
##
## Se aplica pe raza ca functie DOAR de inaltime (nu de azimut), deci treapta e
## un inel perfect orizontal oricat de strambat ar fi hornul de ovality/lean.
## Asta e chiar definitia lui "nivel": deformarile de silueta lucreaza pe
## azimut, straturile lucreaza pe cota, si nu se amesteca.
@export_range(0.0, 0.14, 0.005) var strata_step: float = 0.0

## Cate straturi pe inaltimea hornului. Grosimile nu sunt egale — un depozit
## real alterneaza bancuri groase cu foi subtiri.
@export_range(2, 14, 1) var strata_count: int = 5

## Cat de brusca e treapta: 0 = degrade neted (nu se vede treapta), 1 = prag
## taiat. Se tine sus, fiindca tot rostul e sa se VADA muchia.
@export_range(0.05, 1.0, 0.05) var strata_sharp: float = 0.75

## Cat de tare se inclina straturile fata de orizontala, in grade. Aproape mereu
## 0 — exista doar fiindca in Cappadocia chiar sunt zone cu depozite basculate,
## si un horn-doua inclinate cu 3-4° rup regularitatea fara sa strice citirea.
@export_range(-8.0, 8.0, 0.5) var strata_tilt_deg: float = 0.0


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

## Cati BOLOVANI se presara pe si in jurul poalei. 0 = niciunul.
##
## De ce exista. Critica oarba, runda 9, despre poala construita in runda
## anterioara: "a single smooth lobed cone with no boulder at any size, so
## there is no fragment to say 'this fell off that'" — si, in acelasi loc,
## "the chimney and its skirt look moulded in a single pour". Amandoua
## observatiile arata acelasi lucru: o panta neteda nu e grohotis, e o DUNA.
## Grohotisul se recunoaste dupa FRAGMENTE de marimi diferite, nu dupa panta.
##
## Se pun blocuri unghiulare (nu sfere: sfera citeste a bila, iar tuful se
## rupe in colturi) pe o gama larga de dimensiuni — de la bolovani cat un om
## la sfaramaturi de zeci de centimetri. Gama larga e chiar poanta: ea da si
## cheia de scara, si dovada ca materialul a cazut si s-a spart.
@export_range(0, 40, 1) var talus_rocks: int = 0

## Cat de mare e cel mai MARE bolovan, ca fractiune din raza hornului la sol.
## Restul coboara de aici pe o lege de putere, ca distributia sa aiba cateva
## blocuri mari si multe aschii — asa arata un con de grohotis real.
@export_range(0.04, 0.70, 0.01) var talus_rock_max: float = 0.16


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


## --- Umarul de sub palarie ---------------------------------------------------

## Cat de tare se STRANGE gatul sub palarie, ca fractiune din raza de acolo.
##
## De ce exista. Critica oarba, runda 10, singurul ei punct: "the cones are
## smooth surfaces of revolution whose dark cap sits FLUSH on the taper, so the
## outline is one unbroken curve from tip to base". Si e adevarat MASURAT, nu
## impresionist — profilul mesh-urilor din kit, citit pe 20 de felii:
##
##   chimney_b:        gat 1.59 -> palarie 1.93   = depasire 1.21x
##   chimney_mushroom: gat 1.81 -> palarie 2.29   = depasire 1.27x
##   chimney_a:        gat 1.80 -> palarie 1.24   = palaria e mai INGUSTA
##   chimney_c:        gat 1.33 -> palarie 1.04   = idem
##
## Adica jumatate din kit n-are deloc palarie iesita in afara, iar cealalta
## jumatate are 21-27% — sub pragul la care ochiul vede o TREAPTA si nu o
## simpla curbura. In referinta (B_chimneys.png) depasirea e pe la 1.6-2.0x:
## palaria e o farfurie lata pe un gat vizibil mai subtire, si tocmai umbra
## aruncata de buza ei pe gat e ce rupe silueta in doua.
##
## Ce face: strange raza pe o banda de sub palarie. Nu latim palaria (ar fi
## crescut si AABB-ul, si palaria e chiar geometria care da forma de ciuperca);
## SUBTIEM gatul, ceea ce da acelasi contrast de silueta pe gratis.
##
## Margine de citire, calculata: hornul tipic are gat de ~1.7 unitati de mesh la
## scara ~1.0, deci ~1.7 m raza. La 0.30 strangere, buza iese cu ~0.5 m peste
## gat. La 60 m distanta si FOV 75 pe 1280 px, un metru subintinde ~14 px, deci
## depasirea are ~7 px de fiecare parte. Se vede. La valoarea veche (0.21x din
## geometrie, adica ~0.35 m) erau ~5 px, dar FARA muchie orizontala care sa-i
## dea contur — de-aia critica a citit "one unbroken curve".
@export_range(0.0, 0.45, 0.01) var collar_pinch: float = 0.0

## Unde incepe gatul, ca fractiune din inaltime. Sub palarie, deci sus.
@export_range(0.40, 0.95, 0.01) var collar_at: float = 0.72

## Cat de inalta e banda de strangere, ca fractiune din inaltime. Ingusta =
## treapta brusca; lata = gat lung de clepsidra.
@export_range(0.05, 0.40, 0.01) var collar_span: float = 0.14

## Cat se LATESTE palaria peste gat, ca fractiune din raza ei.
##
## De ce nu ajunge doar strangerea gatului. Masuratoarea de profil a aratat ca
## jumatate din kit are palaria mai INGUSTA decat gatul (chimney_a: gat 1.80,
## palarie 1.24; chimney_c: 1.33 -> 1.04). Pe alea, oricat ai strange gatul,
## palaria ramane un varf ascutit — si asta s-a si vazut in prima captura de
## verificare: conurile capatasera gat, dar deasupra lui statea un cui, nu o
## farfurie. Un cui nu proiecteaza umbra pe gat, deci silueta tot nu se rupe.
##
## Palaria trebuie sa fie o CONSOLA. Se lateste banda de deasupra gatului,
## descrescator spre varf, ca sa iasa o palarie de ciuperca si nu un cilindru.
@export_range(0.0, 1.20, 0.05) var cap_flare: float = 0.0

## De la ce fractiune din inaltime in sus se lateste palaria. Implicit imediat
## deasupra gatului.
@export_range(0.50, 0.98, 0.01) var cap_from: float = 0.80


## --- Modul ARCADA -------------------------------------------------------------

## Cat de tare se erodeaza o arcada ca sa nu mai citeasca a poarta construita.
## 0 = stins (implicit: hornurile obisnuite nu-l folosesc).
##
## De ce exista. Critica oarba, runda 10, ultimul punct: arcada e "a plain
## rectangular lintel on two rectangular posts" si "reads as architecture and
## fights the geology". Are dreptate literal — mesh-ul `twin_chimney_gate` are
## 354 de triunghiuri pe un gabarit de 26 x 21.6 x 6 m, adica fete mari si
## plane cu muchii drepte. Langa hornuri erodate, un dreptunghi citeste ca facut
## de mana omului, si atunci intreaga zona devine ruina, nu relief.
##
## Ce face, si de ce NU e `_deform_mesh` obisnuit: deformarile de horn sunt
## RADIALE fata de o axa, iar arcada n-are axa — are doi stalpi si o grinda.
## Aplicata pe ea, ovalizarea ar fi tras cei doi stalpi unul in altul.
##
## Trei operatii, toate functie de pozitie si niciuna radiala:
##   - stalpii se INGROASA la baza si se subtiaza spre grinda (o stanca ramasa
##     in picioare e mai lata jos, un stalp construit e paralel);
##   - grinda se LASA la mijloc (o grinda de piatra care si-a pierdut sprijinul
##     se incovoaie; o buiandruga taiata e dreapta);
##   - toata suprafata primeste un zgomot de eroziune pe trei axe, ca fetele
##     plane sa nu mai fie plane si muchiile drepte sa nu mai fie drepte.
@export_range(0.0, 1.0, 0.05) var arch_erode: float = 0.0

## La ce cota se termina stalpii si incepe grinda, ca fractiune din inaltime.
## Se citeste din geometrie daca ramane 0.
@export_range(0.0, 0.95, 0.01) var arch_span_at: float = 0.62


## --- Randuri de ferestre ------------------------------------------------------

## Cate RANDURI de deschideri mai mici se sapa peste inaltimea hornului, deasupra
## usilor de la baza. 0 = niciunul.
##
## De ce exista. Aceeasi critica: deschiderile trebuie sa fie "WIDER THAN THEY
## ARE TALL — square-ish windows and 1:2 doors distributed over the height, not
## single full-height slits". Sistemul de usi vechi punea `door_count` niste
## deschideri pe UN singur rand, la baza, cu `door_aspect` sub 1 (mai inalte
## decat late). Doua consecinte, amandoua vizibile in captura de la 0.10:
## deschiderile citeau a CRAPATURI verticale (adica a eroziune, nu a locuinta),
## si toate stateau pe acelasi nivel, deci nu spuneau nimic despre INALTIMEA
## hornului — doar despre a lor.
##
## Un rand de ferestre patrate la trei sferturi din inaltime spune, singur, cat
## de inalt e hornul: ochiul stie cat e o fereastra, numara etajele si obtine
## metrii. Asta e cheia de scara pe care usa de la baza n-o poate da, fiindca
## usa e mereu jos si nu masoara decat primii doi metri.
@export_range(0, 5, 1) var window_rows: int = 0

## Cate ferestre pe rand.
@export_range(1, 6, 1) var window_per_row: int = 3

## Inaltimea unei ferestre in metri de lume.
@export_range(0.6, 2.0, 0.1) var window_height_m: float = 1.1

## Latimea ca fractiune din inaltime. PESTE 1 — asta e tot rostul: fereastra e
## mai LATA decat inalta, ceea ce o desparte de o crapatura de eroziune, care e
## intotdeauna verticala.
@export_range(0.8, 2.4, 0.05) var window_aspect: float = 1.45

## Intre ce fractiuni din inaltime se distribuie randurile.
@export_range(0.10, 0.90, 0.01) var window_from: float = 0.30
@export_range(0.15, 0.95, 0.01) var window_to: float = 0.68

## Pe ce azimut e centrat peretele cu ferestre, si pe ce arc se raspandesc.
@export_range(0.0, 360.0, 5.0) var window_dir_deg: float = 0.0
@export_range(20.0, 200.0, 5.0) var window_arc_deg: float = 85.0


func _ready() -> void:
	_deform()


func _deform() -> void:
	# Fara munca daca instanta e lasata pe valorile neutre: hornurile care chiar
	# trebuie sa ramana drepte nu platesc duplicarea mesh-ului.
	var shapes_off := is_equal_approx(ovality, 1.0) and is_zero_approx(lean_deg) 			and is_zero_approx(bulge) and is_zero_approx(flute_depth) 			and is_zero_approx(noise_amount) and is_zero_approx(strata_step) 			and is_zero_approx(collar_pinch) 			and is_zero_approx(cap_flare) 			and is_zero_approx(arch_erode)
	var extras_off := is_zero_approx(talus_spread) and door_count == 0 			and window_rows == 0
	if shapes_off and extras_off:
		return
	var meshes: Array[MeshInstance3D] = []
	_collect(self, meshes)
	if meshes.is_empty():
		return
	if not shapes_off:
		for mi in meshes:
			if not is_zero_approx(arch_erode):
				_erode_arch(mi)
			else:
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
				# --- 5. straturi ORIZONTALE, in trepte --------------------
				# Functie DOAR de cota, niciodata de azimut: asa inelul ramane
				# la nivel cand peretele coteste, in loc sa se infasoare pe
				# forma. `floor` da treapta, iar amestecul cu partea fractionara
				# lasa muchia sa fie moale cand strata_sharp scade.
				if not is_zero_approx(strata_step):
					var ys := t
					if not is_zero_approx(strata_tilt_deg):
						# Basculare: cota efectiva depinde putin de pozitia
						# orizontala, deci inelul se inclina ca un plan.
						ys += (dx * cos(ph2) + dz * sin(ph2)) 							* tan(deg_to_rad(strata_tilt_deg)) / h
					var u := ys * float(strata_count)
					var band: float = floor(u)
					var frac: float = u - band
					# Grosimi inegale: bancuri groase alternand cu foi subtiri.
					var hard := 0.5 + 0.5 * sin(band * 2.399963 + ph1)
					# Muchia: prag cand strata_sharp -> 1, degrade cand -> 0.
					var edge := smoothstep(0.5 - strata_sharp * 0.5,
						0.5 + strata_sharp * 0.5, frac)
					var prev := 0.5 + 0.5 * sin((band - 1.0) * 2.399963 + ph1)
					scale *= 1.0 + strata_step * lerpf(prev, hard, edge)

				# --- 6. GATUL de sub palarie ------------------------------
				# Strangere pe o banda de cota, deci ramane orizontala oricat
				# de ovalizat/inclinat ar fi hornul — la fel ca straturile.
				# Gaussiana si nu treapta: o taietura brusca ar fi lasat o
				# muchie de poligon care se vede ca defect de mesh, pe cand
				# ce vrem e o SCOBITURA din care palaria iese in consola.
				if not is_zero_approx(collar_pinch):
					var dc := (t - collar_at) / maxf(collar_span, 0.01)
					scale *= 1.0 - collar_pinch * exp(-dc * dc)

				# --- 7. PALARIA in consola --------------------------------
				# Se lateste doar deasupra lui cap_from, si se stinge spre
				# varf: la t = cap_from latirea e maxima (acolo e BUZA, care
				# arunca umbra pe gat), la t = 1 e zero (varful ramane varf).
				# Fara stingere ar fi iesit o palarie cilindrica, adica o
				# palarie de joben — citeste a obiect fabricat, nu a stanca
				# dura ramasa dupa ce cea moale de sub ea s-a dus.
				if not is_zero_approx(cap_flare) and t > cap_from:
					var ct := (t - cap_from) / maxf(1.0 - cap_from, 0.01)
					scale *= 1.0 + cap_flare * (1.0 - ct) * (1.0 - ct * 0.35)

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
		# FATETE (runda 12). `generate_normals()` pe un mesh INDEXAT mediaza
		# normala pe vertecsii impartiti de mai multe fete, deci iese shading
		# neted - indiferent ce normale aducea GLB-ul, fiindca aici mesh-ul se
		# reface. De-aia regenerarea kitului cu `smooth_angle=None` n-a schimbat
		# nimic in captura: fixul trebuie sa fie AICI, unde se scriu normalele.
		# `deindex()` rupe vertecsii comuni, deci fiecare triunghi isi primeste
		# propria normala si lumina sare in trepte peste muchii. Acelasi truc
		# pe care il foloseste deja `_build_talus` (SurfaceTool fara index).
		# De ce contrazice apply_smooth din dio_lib (netezirea a scos aspectul
		# "Minecraft", #113): acolo e vorba de cladiri si curburi organice. Roca
		# vrea invers - criticul orb, pe cadrul bun de la frac 0.05: conurile
		# smooth-shaded citesc a bloburi moi, iar fatetele vizibile sunt ce face
		# referinta sa arate a DIORAMA STILIZATA, nu a geometrie saraca.
		# Cost: zero materiale, zero triunghiuri. Doar vertecsii se despart.
		if faceted:
			st.deindex()
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
	var base_r := _radius_at(src, cx, cz, y0, h, 0.02)
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
		# Bolovanii merg in ACEEASI suprafata cu poala: acelasi material, deci
		# zero draw call-uri in plus si zero materiale in plus la numaratoare.
		if talus_rocks > 0:
			_build_talus_rocks(st, cx, cz, y0, base_r)
		st.generate_normals()
		var m := st.commit()
		if m != null and m.get_surface_count() > 0:
			out.add_surface_from_arrays(
				Mesh.PRIMITIVE_TRIANGLES, m.surface_get_arrays(0))
			out.surface_set_material(out.get_surface_count() - 1, mat)

	# --- RANDURI DE FERESTRE ------------------------------------------------
	# Se pun INAINTE de usi, pe cotele lor proprii, fiindca fiecare rand isi
	# masoara singur raza peretelui la inaltimea lui: hornul e un con, deci o
	# fereastra pusa la raza bazei ar fi plutit in fata peretelui cu cativa
	# metri la trei sferturi din inaltime. Aceeasi capcana care a lovit usile
	# in runda trecuta, doar ca de sase ori mai sus si deci de sase ori mai
	# vizibila.
	if window_rows > 0:
		var stw := SurfaceTool.new()
		stw.begin(Mesh.PRIMITIVE_TRIANGLES)
		var any_win := false
		for row in window_rows:
			var rf := window_from
			if window_rows > 1:
				rf = lerpf(window_from, window_to,
					float(row) / float(window_rows - 1))
			var rr := _radius_at(src, cx, cz, y0, h, rf)
			if rr <= 0.001:
				continue
			# Randurile de sus au mai putine ferestre: hornul se ingusteaza, si
			# tot atatea deschideri pe o circumferinta mai mica s-ar fi
			# suprapus intr-un gratar continuu. Un gratar citeste a aerisire
			# industriala, exact reprosul din runda trecuta despre usi.
			var per := maxi(1, window_per_row - row)
			_build_windows(stw, cx, cz, y0 + rf * h, rr, world_scale, per, row)
			any_win = true
		if any_win:
			stw.generate_normals()
			var mw := stw.commit()
			if mw != null and mw.get_surface_count() > 0:
				out.add_surface_from_arrays(
					Mesh.PRIMITIVE_TRIANGLES, mw.surface_get_arrays(0))
				out.surface_set_material(out.get_surface_count() - 1, mat)

	if door_count > 0:
		# Pragul urca PESTE creasta poalei. Fara asta, usa e ingropata in
		# grohotis pe doua treimi din inaltime — s-a si vazut in captura de la
		# fractia 0.13: din usi ramaneau doua aschii intunecate la baza, adica
		# tocmai cheia de scara disparea sub cealalta reparatie. Creasta se
		# calculeaza cu ACEEASI formula ca in _build_talus, la varful armonicii
		# (wob maxim = 1.44), plus o palma de degajare.
		var sill := door_sill_m
		if not is_zero_approx(talus_spread):
			# Creasta MAXIMA a poalei: wob la varf (1.44) inmultit cu limba de
			# moloz cea mai inalta (climb la varf = 1 + 0.55 + 0.25 = 1.80).
			# De cand poala urca inegal pe perete, un prag calculat pe creasta
			# MEDIE ar fi lasat usile ingropate exact acolo unde molozul s-a
			# ingramadit — adica pe fata cea mai spectaculoasa, care e si cea
			# dinspre drum.
			var crest := base_r * talus_height * (0.75 + 0.35 * 1.44) * 1.80
			sill = maxf(sill, (crest + base_r * 0.05) * world_scale)
		# Raza SE MASOARA LA COTA PRAGULUI, nu la baza: altfel nisa sta in
		# aer, in fata unui perete care s-a subtiat sub ea.
		var sill_frac := clampf((sill / world_scale) / h, 0.0, 0.95)
		var door_r := _radius_at(src, cx, cz, y0, h, sill_frac)
		if door_r > 0.001:
			var st2 := SurfaceTool.new()
			st2.begin(Mesh.PRIMITIVE_TRIANGLES)
			_build_doors(st2, cx, cz, y0, door_r, world_scale, sill)
			st2.generate_normals()
			var m2 := st2.commit()
			if m2 != null and m2.get_surface_count() > 0:
				out.add_surface_from_arrays(
					Mesh.PRIMITIVE_TRIANGLES, m2.surface_get_arrays(0))
				out.surface_set_material(out.get_surface_count() - 1, mat)

	mi.mesh = out


## Raza hornului LA O COTA DATA. Se ia mediana razelor dintr-o felie subtire in
## jurul cotei cerute, ca sa n-o strice nici palaria, nici un vertex ratacit.
##
## Parametrizata pe inaltime, si nu doar "la baza", fiindca hornul e un CON:
## la 3 m deasupra solului e vizibil mai subtire decat la sol. Prima versiune
## aseza nisele la raza de la baza, dupa ce pragul fusese urcat peste poala —
## si usile au iesit plutind in fata peretelui, ca niste lespezi sprijinite de
## el. Se vede in captura de la 0.13: una dintre ele nu mai atingea deloc hornul.
func _radius_at(src: Mesh, cx: float, cz: float, y0: float, h: float,
		frac: float) -> float:
	var radii: PackedFloat32Array = []
	# Fereastra creste daca felia iese goala (hornurile n-au inele de vertecsi
	# la orice cota), ca sa returnam mereu o raza reala.
	for win in [0.06, 0.12, 0.25, 0.5]:
		radii.clear()
		for sfc in src.get_surface_count():
			var arrays := src.surface_get_arrays(sfc)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for v in verts:
				if absf((v.y - y0) / h - frac) < win:
					radii.append(Vector2(v.x - cx, v.z - cz).length())
		if radii.size() >= 6:
			break
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
	var ph := _talus_phase(shape_seed)
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
		# Lobi de grohotis: fiecare a doua latura iese mai mult, ca poala sa aiba
		# limbi si scobituri in loc de un con neted. Un trunchi de con perfect
		# citea a DUNA — nisip suflat, nu piatra sfaramata; muchia dintre lobi e
		# ce da senzatia de material unghiular.
		var lobe := 1.0 + 0.22 * (1.0 if i % 2 == 0 else -1.0) 			* (0.6 + 0.4 * sin(float(i) * 1.7 + ph))
		var r_out := base_r * (1.0 + talus_spread * wob * lobe)
		# BUZA DE SUS URCA PE PERETE, si urca INEGAL.
		#
		# De ce. Critica oarba, runda 10: poala e "a ring of flat faceted plates
		# (...) meeting the cone at a hard line — the cones do not emerge from
		# the ground, they are placed on it and the skirt is a rug". Avea
		# dreptate din geometrie: buza interioara statea la raza 0.98*base_r,
		# adica LIPITA de perete pe un cerc de cota aproape constanta. Un cerc
		# de cota constanta pe un con e o LINIE — si o linie inchisa la
		# intersectia a doua suprafete e chiar definitia unui obiect asezat
		# peste altul.
		#
		# Un con de grohotis real n-are linie de contact: molozul se ingramadeste
		# in limbi care urca pe perete acolo unde a cazut mai mult si coboara
		# intre ele. Buza devine ondulata pe VERTICALA, deci nu mai exista nicio
		# cota unica la care sa se vada muchia — si atunci hornul iese din
		# gramada in loc sa stea pe ea.
		#
		# Amplitudinea (pana la 0.55 din inaltimea poalei) e aleasa ca urcarea sa
		# fie de ordinul metrilor pe hornurile mari: sub asta, ondulatia exista
		# in geometrie dar se pierde in latimea unui poligon.
		var r_in := base_r * (0.99 + 0.02 * wob)
		var y_top := y0 + base_r * talus_height * _talus_lift(a, ph)
		inner.append(Vector3(cx + cos(a) * r_in, y_top, cz + sin(a) * r_in))
		outer.append(Vector3(cx + cos(a) * r_out, y_foot, cz + sin(a) * r_out))
	var uv := Palette.uv(TALUS_SLOT)
	for i in n:
		var j := (i + 1) % n
		# Fusta: de la buza de sus (lipita de perete) la poalele de jos.
		# Triunghiurile NU se impart cu vecinii (SurfaceTool fara index), deci
		# generate_normals() da normale PE FATA: fiecare lob isi primeste propria
		# valoare de lumina si muchia dintre ei se vede. Cu normale netezite,
		# lobii ar fi existat in geometrie dar ar fi disparut la iluminare —
		# exact tipul de efect care trece o sonda si nu se vede in cadru.
		st.set_uv(uv); st.add_vertex(inner[i])
		st.set_uv(uv); st.add_vertex(outer[i])
		st.set_uv(uv); st.add_vertex(outer[j])
		st.set_uv(uv); st.add_vertex(inner[i])
		st.set_uv(uv); st.add_vertex(outer[j])
		st.set_uv(uv); st.add_vertex(inner[j])


## Faza zgomotului de poala. O SINGURA sursa de adevar.
##
## Bug gasit in runda 11: `_build_talus` isi lua faza din seed-ul +7717, iar
## `_build_talus_rocks` din +3391. Adica poala si bolovanii de pe ea foloseau
## acelasi `wob` scris identic, dar cu FAZE DIFERITE — deci bolovanii calculau
## panta unei poale care nu exista. Se vedea putin cat timp singura variatie era
## raza (0.28 amplitudine), dar limbile de moloz care urca acum pe perete au
## amplitudine 0.55 pe VERTICALA, si atunci decalajul ar fi ingropat jumatate
## din bolovani si ar fi lasat cealalta jumatate atarnand in aer.
static func _talus_phase(sd: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = sd + 7717
	return rng.randf() * TAU


## Inaltimea poalei la un azimut, ca multiplu al inaltimii nominale. Aceeasi
## formula folosita si de fusta, si de bolovani — vezi `_talus_phase`.
static func _talus_lift(a: float, ph: float) -> float:
	var wob := 1.0 + 0.28 * sin(3.0 * a + ph) + 0.16 * sin(5.0 * a + ph * 1.7)
	var climb := 1.0 + 0.55 * sin(2.0 * a + ph * 2.3) + 0.25 * sin(5.0 * a + ph)
	return (0.75 + 0.35 * wob) * maxf(climb, 0.25)


## Bolovanii de pe poala: blocuri unghiulare de marimi foarte diferite.
##
## Forma e un octaedru NEREGULAT — opt fete plane, cu fiecare varf impins
## aleator. De ce nu o sfera: o sfera cu putine segmente citeste a bila de
## piatra slefuita, iar tuful crapa in colturi. De ce nu o cutie: o cutie are
## trei perechi de fete paralele si citeste a bloc taiat de om. Octaedrul
## deformat n-are nicio pereche paralela, deci fiecare fata prinde alta valoare
## de lumina si bolovanul se citeste ca fragment rupt.
##
## Marimile urmeaza o lege de putere (t^2.2): cateva blocuri mari si multe
## aschii. Distributia CONTEAZA — daca toate ar fi la fel de mari, ar citi a
## pietriș decorativ imprastiat, nu a stanca sfaramata. Gama larga e ce da
## "there is no fragment to say this fell off that" raspunsul lui.
##
## Asezarea: pe panta poalei (intre buza si poale), plus un inel de fugari
## dincolo de ea — pietrele care s-au rostogolit mai departe. Fara fugari,
## conturul poalei ar fi ramas o linie curata, adica tot un con.
func _build_talus_rocks(st: SurfaceTool, cx: float, cz: float, y0: float,
		base_r: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = shape_seed + 3391
	# Faza poalei, NU o faza proprie: bolovanii stau pe suprafata construita de
	# `_build_talus`, deci trebuie sa citeasca exact acelasi zgomot.
	var ph := _talus_phase(shape_seed)
	var uv := Palette.uv(TALUS_SLOT)
	for k in talus_rocks:
		var a := rng.randf() * TAU
		var wob := 1.0 + 0.28 * sin(3.0 * a + ph) + 0.16 * sin(5.0 * a + ph * 1.7)
		# t = 0 la perete, 1 la poale, >1 = fugar rostogolit dincolo de con.
		var t := rng.randf()
		var runaway := rng.randf() < 0.22
		if runaway:
			t = 1.0 + rng.randf() * 0.55
		var r_here := base_r * (1.0 + talus_spread * wob * t)
		# Cota pe panta poalei: liniara intre creasta si poale, ca bolovanul sa
		# stea PE panta, nu infipt in ea sau plutind peste.
		var crest := y0 + base_r * talus_height * _talus_lift(a, ph)
		var y_foot := y0 - base_r * 0.10
		var y_here := lerpf(crest, y_foot, minf(t, 1.0))
		# Marimea: lege de putere, cu blocurile mari catre POALE (t mare) —
		# grohotisul se sorteaza singur, fragmentele grele se rostogolesc cel
		# mai departe. E si adevarat fizic, si citeste corect: blocul mare de
		# jos e cheia de scara, langa care aschiile de sus par mici.
		# Legea de marime. Prima varianta folosea pow(u, 2.2) pe tot intervalul
		# si a iesit invizibila: MASURAT pe trei hornuri din scena, bolovanul
		# tipic ajungea la 0.1-0.3 m diametru si chiar si cel mai mare la ~1 m.
		# Adica pietricele — de la volan, poala ramanea o duna neteda, exact
		# reprosul care trebuia reparat. Exponentul mare face ca aproape toate
		# esantioanele sa cada langa zero; "cateva mari si multe mici" cere ca
		# ALEA cateva sa fie chiar mari, nu ca toate sa fie mici.
		#
		# Acum: o parte din fragmente sunt BLOCURI declarate (u in 0.75..1.0),
		# restul aschii, si exponentul e mai bland. Un bloc de 1.5-3 m e ce
		# spune "asta a cazut de acolo" — sub un metru nu se citeste nici macar
		# la 20 m.
		var u := rng.randf()
		if k % 4 == 0:
			u = rng.randf_range(0.75, 1.0)
		var size := base_r * talus_rock_max * pow(u, 1.35) * (0.55 + 0.85 * minf(t, 1.0))
		if size < base_r * 0.02:
			continue
		var cxr := cx + cos(a) * r_here
		var czr := cz + sin(a) * r_here
		# Bolovanul sta pe jumatate ingropat: centrul coboara cu jumatate din
		# raza, altfel pietrele plutesc pe panta ca niste baloane.
		_octa_rock(st, Vector3(cxr, y_here + size * 0.35, czr), size, rng, uv)


## Un bloc unghiular: octaedru cu varfurile impinse aleator, deci fara nicio
## pereche de fete paralele.
func _octa_rock(st: SurfaceTool, c: Vector3, r: float,
		rng: RandomNumberGenerator, uv: Vector2) -> void:
	# Cele sase varfuri, fiecare impins pe toate axele. Turtirea pe Y (0.62-0.9)
	# exista fiindca un fragment cazut se aseaza pe fata lui cea mai lata, nu pe
	# varf — pietrele perfect izotrope citesc a bile.
	var flat := rng.randf_range(0.62, 0.90)
	var v: Array[Vector3] = []
	for d: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN,
			Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var jitter := Vector3(rng.randf_range(0.62, 1.35),
			rng.randf_range(0.62, 1.35), rng.randf_range(0.62, 1.35))
		var p := d * r
		p.x *= jitter.x
		p.y *= jitter.y * flat
		p.z *= jitter.z
		v.append(c + p)
	# Cele opt fete ale octaedrului: fiecare combinatie (±x, ±y, ±z).
	var faces := [
		[0, 2, 4], [4, 2, 1], [1, 2, 5], [5, 2, 0],
		[0, 4, 3], [4, 1, 3], [1, 5, 3], [5, 0, 3],
	]
	for f: Array in faces:
		st.set_uv(uv); st.add_vertex(v[f[0]])
		st.set_uv(uv); st.add_vertex(v[f[1]])
		st.set_uv(uv); st.add_vertex(v[f[2]])


## Nisele de usa/fereastra: un chenar impins in perete.
##
## Nu se taie gaura in mesh — un boolean pe geometrie deformata ar fi cerut o
## librarie de CSG si ar fi lasat fatete rupte. Se aseaza in schimb o cutie fara
## capac frontal, cu fundul impins spre AXA hornului: peretii laterali si fundul
## sunt in umbra proprie, deci de la volan gaura citeste ca gaura.
func _build_doors(st: SurfaceTool, cx: float, cz: float, y0: float,
		base_r: float, world_scale: float, sill_m: float) -> void:
	# Din metri de lume in unitati de mesh.
	var dh := door_height_m / world_scale
	var dw := dh * door_aspect
	var dd := door_depth_m / world_scale
	# Nisa nu poate fi mai adanca decat jumatate din raza si nici mai lata decat
	# raza intreaga: altfel fundul ei ar iesi pe partea cealalta a hornului, iar
	# peretii s-ar autointersecta.
	dd = minf(dd, base_r * 0.5)
	dw = minf(dw, base_r * 1.4)
	var sill := sill_m / world_scale
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
		# Fundul nisei, privit dinspre exterior. Slotul cel mai INCHIS din
		# familia de tuf: gura pesterii trebuie sa citeasca a gaura, iar umbra
		# proprie singura nu ajunge cand soarele bate din fata.
		_quad(st, bbl, bbr, btr, btl, Palette.uv(DOOR_DARK_SLOT))
		# Peretele din stanga si cel din dreapta.
		_quad(st, fbl, bbl, btl, ftl, Palette.uv(DOOR_DARK_SLOT))
		_quad(st, bbr, fbr, ftr, btr, Palette.uv(DOOR_DARK_SLOT))
		# Buiandrugul (tavanul nisei).
		_quad(st, btl, btr, ftr, ftl, Palette.uv(DOOR_DARK_SLOT))

		# --- CHENARUL IN RELIEF ------------------------------------------
		#
		# De ce exista. Critica oarba, runda 9: usile sunt "flat black
		# rectangles with no jamb, lintel, threshold or interior, so they read
		# as much like unlit windows or decals as like doors". Nisa CHIAR avea
		# adancime — fund, pereti laterali, buiandrug — dar de la volan nu se
		# vedea niciunul: peretele hornului e aproape neumbrit, deci fata din
		# jurul gaurii si fundul gaurii primesc lumina asemanatoare, iar
		# conturul dintre ele ramane o simpla schimbare de culoare. Exact ce
		# face un decal.
		#
		# Ce repara: un CADRU care iese in AFARA peretelui, cu 6 cm. Muchia lui
		# exterioara prinde lumina razanta (soarele temei e la 13 grade) si
		# arunca o dunga de umbra pe perete, iar muchia interioara pune o linie
		# clara intre piatra si gol. Adancimea nu se mai deduce din interiorul
		# intunecat, se vede pe RELIEFUL din jur — si asta se citeste si cand
		# gaura e prea mica in cadru ca sa i se vada fundul.
		var pr := base_r * 1.01 + 0.06 / world_scale
		var jw := hw + 0.16 / world_scale      # cat iese cadrul lateral
		var jt := 0.20 / world_scale           # cat iese peste buiandrug
		var pbl := Vector3(cx + nx * pr - tx * jw, yb, cz + nz * pr - tz * jw)
		var pbr := Vector3(cx + nx * pr + tx * jw, yb, cz + nz * pr + tz * jw)
		var ptl := Vector3(cx + nx * pr - tx * jw, yt + jt, cz + nz * pr - tz * jw)
		var ptr := Vector3(cx + nx * pr + tx * jw, yt + jt, cz + nz * pr + tz * jw)
		# Fata cadrului, ca patru benzi in jurul golului (nu un dreptunghi
		# plin: golul trebuie sa ramana gol).
		var fbl2 := Vector3(cx + nx * pr - tx * hw, yb, cz + nz * pr - tz * hw)
		var fbr2 := Vector3(cx + nx * pr + tx * hw, yb, cz + nz * pr + tz * hw)
		var ftl2 := Vector3(cx + nx * pr - tx * hw, yt, cz + nz * pr - tz * hw)
		var ftr2 := Vector3(cx + nx * pr + tx * hw, yt, cz + nz * pr + tz * hw)
		var frame_uv := Palette.uv(TALUS_SLOT)
		# Stalpul din stanga, cel din dreapta, si buiandrugul deasupra.
		_quad(st, pbl, fbl2, ftl2, ptl, frame_uv)
		_quad(st, fbr2, pbr, ptr, ftr2, frame_uv)
		_quad(st, ptl, ftl2, ftr2, ptr, frame_uv)
		# Grosimea cadrului catre perete: fara ea cadrul e o foaie fara muchie,
		# si tocmai muchia arunca umbra care spune ca iese in afara.
		_quad(st, ftl, ftl2, ptl, ftl, frame_uv)
		# PRAGUL: o lespede care iese din perete la baza golului. E piesa care
		# spune ca prin gaura aia se INTRA — o fereastra n-are prag iesit.
		var sl := Vector3(cx + nx * pr - tx * hw, yb, cz + nz * pr - tz * hw)
		var sr := Vector3(cx + nx * pr + tx * hw, yb, cz + nz * pr + tz * hw)
		var so := 0.22 / world_scale
		var slo := Vector3(cx + nx * (pr + so) - tx * hw, yb - jt * 0.5,
			cz + nz * (pr + so) - tz * hw)
		var sro := Vector3(cx + nx * (pr + so) + tx * hw, yb - jt * 0.5,
			cz + nz * (pr + so) + tz * hw)
		_quad(st, slo, sro, sr, sl, frame_uv)


## Un rand de ferestre: nise MAI LATE DECAT INALTE, cu buiandrug si solbanc.
##
## De ce sunt o functie separata si nu `_build_doors` cu alti parametri: usa are
## prag iesit in afara (se INTRA prin ea) si sta pe un singur nivel, fereastra
## are solbanc si vine in randuri. Mai ales, usa e verticala si fereastra e
## orizontala — iar critica a cerut explicit forma orizontala, fiindca o
## deschidere verticala intr-o stanca citeste a CRAPATURA, nu a locuinta. O
## crapatura e eroziune; o fereastra e cineva care a sapat acolo. Diferenta asta
## e toata cheia de scara.
##
## Adancimea e mica intentionat (18 cm): o nisa adanca la 40 m nu se mai citeste
## ca adanca, se citeste ca o pata neagra. Ce se vede de departe e UMBRA
## buiandrugului pe pervaz, si aia cere doar cativa centimetri de consola.
func _build_windows(st: SurfaceTool, cx: float, cz: float, ybase: float,
		r: float, world_scale: float, count: int, row: int) -> void:
	var wh := window_height_m / world_scale
	var ww := wh * window_aspect
	var wd := minf(0.18 / world_scale, r * 0.35)
	# Latimea nu poate depasi o fractiune din circumferinta, altfel ferestrele
	# vecine se ating si redevin gratar.
	ww = minf(ww, r * 0.55)
	var rng := RandomNumberGenerator.new()
	rng.seed = shape_seed + 5100 + row * 31
	var arc := deg_to_rad(window_arc_deg)
	var dir0 := deg_to_rad(window_dir_deg)
	# Randurile se decaleaza pe azimut, ca ferestrele sa nu se insiruie pe o
	# coloana verticala — un sir vertical de goluri ar fi refacut exact fanta
	# pe care o inlocuim, doar din bucati.
	dir0 += float(row) * arc * 0.17
	var dark := Palette.uv(DOOR_DARK_SLOT)
	var trim := Palette.uv(TALUS_SLOT)
	for k in count:
		var f := 0.0
		if count > 1:
			f = float(k) / float(count - 1) - 0.5
		var a := dir0 + f * arc + rng.randf_range(-0.05, 0.05)
		var nx := cos(a)
		var nz := sin(a)
		var tx := -sin(a)
		var tz := cos(a)
		var r_face := r * 1.01
		var r_back := r - wd
		# Inaltimile variaza putin de la o fereastra la alta: un rand perfect
		# aliniat citeste a fatada de bloc, nu a stanca locuita.
		var yb := ybase + rng.randf_range(-0.12, 0.12) * wh
		var yt := yb + wh * rng.randf_range(0.88, 1.12)
		var hw := ww * 0.5 * rng.randf_range(0.85, 1.15)
		var fbl := Vector3(cx + nx * r_face - tx * hw, yb, cz + nz * r_face - tz * hw)
		var fbr := Vector3(cx + nx * r_face + tx * hw, yb, cz + nz * r_face + tz * hw)
		var ftl := Vector3(cx + nx * r_face - tx * hw, yt, cz + nz * r_face - tz * hw)
		var ftr := Vector3(cx + nx * r_face + tx * hw, yt, cz + nz * r_face + tz * hw)
		var bbl := Vector3(cx + nx * r_back - tx * hw, yb, cz + nz * r_back - tz * hw)
		var bbr := Vector3(cx + nx * r_back + tx * hw, yb, cz + nz * r_back + tz * hw)
		var btl := Vector3(cx + nx * r_back - tx * hw, yt, cz + nz * r_back - tz * hw)
		var btr := Vector3(cx + nx * r_back + tx * hw, yt, cz + nz * r_back + tz * hw)
		# Golul: fund + obraji + buiandrug, toate pe slotul cel mai inchis.
		_quad(st, bbl, bbr, btr, btl, dark)
		_quad(st, fbl, bbl, btl, ftl, dark)
		_quad(st, bbr, fbr, ftr, btr, dark)
		_quad(st, btl, btr, ftr, ftl, dark)
		# SOLBANCUL: o lespede subtire care iese peste gol. E singura piesa care
		# se vede de la 60 m — arunca o dunga de umbra ORIZONTALA sub fereastra,
		# iar dunga aia e ce spune ochiului ca deschiderea e lata, nu inalta.
		var so := 0.14 / world_scale
		var sy := 0.07 / world_scale
		var sw := hw + 0.10 / world_scale
		var sl := Vector3(cx + nx * r_face - tx * sw, yb, cz + nz * r_face - tz * sw)
		var sr := Vector3(cx + nx * r_face + tx * sw, yb, cz + nz * r_face + tz * sw)
		var slo := Vector3(cx + nx * (r_face + so) - tx * sw, yb - sy,
			cz + nz * (r_face + so) - tz * sw)
		var sro := Vector3(cx + nx * (r_face + so) + tx * sw, yb - sy,
			cz + nz * (r_face + so) + tz * sw)
		_quad(st, slo, sro, sr, sl, trim)
		# Muchia frontala a solbancului, ca sa aiba grosime si deci umbra.
		var sld := Vector3(cx + nx * (r_face + so) - tx * sw, yb - sy * 2.4,
			cz + nz * (r_face + so) - tz * sw)
		var srd := Vector3(cx + nx * (r_face + so) + tx * sw, yb - sy * 2.4,
			cz + nz * (r_face + so) + tz * sw)
		_quad(st, sld, srd, sro, slo, trim)
		# BUIANDRUGUL: aceeasi consola deasupra, care pune golul in umbra
		# proprie chiar cand soarele bate din fata.
		var ll := Vector3(cx + nx * r_face - tx * sw, yt, cz + nz * r_face - tz * sw)
		var lr := Vector3(cx + nx * r_face + tx * sw, yt, cz + nz * r_face + tz * sw)
		var llo := Vector3(cx + nx * (r_face + so) - tx * sw, yt + sy,
			cz + nz * (r_face + so) - tz * sw)
		var lro := Vector3(cx + nx * (r_face + so) + tx * sw, yt + sy,
			cz + nz * (r_face + so) + tz * sw)
		_quad(st, ll, lr, lro, llo, trim)
		_quad(st, llo, lro, lr, ll, trim)


## Erodeaza o ARCADA, ca sa citeasca a stanca ramasa si nu a poarta zidita.
## Vezi `arch_erode` pentru motiv. Nu foloseste nimic radial.
func _erode_arch(mi: MeshInstance3D) -> void:
	var src := mi.mesh
	var ab := src.get_aabb()
	var h := maxf(ab.size.y, 0.001)
	var y0 := ab.position.y
	var cx := ab.position.x + ab.size.x * 0.5
	var cz := ab.position.z + ab.size.z * 0.5
	var half_w := maxf(ab.size.x * 0.5, 0.001)
	var k := arch_erode
	var rng := RandomNumberGenerator.new()
	rng.seed = shape_seed + 991
	var p1 := rng.randf() * TAU
	var p2 := rng.randf() * TAU

	var out := ArrayMesh.new()
	for s in src.get_surface_count():
		var arrays := src.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in verts.size():
			var v := verts[i]
			var t := clampf((v.y - y0) / h, 0.0, 1.0)
			var dx := v.x - cx
			var dz := v.z - cz
			# --- 1. stalpii se ingroasa la baza --------------------------
			# Doar sub nasterea arcului, si doar pe latime/adancime: grinda de
			# deasupra trebuie sa ramana dreapta ca sa se vada lasarea ei.
			if t < arch_span_at:
				var f := 1.0 - t / maxf(arch_span_at, 0.01)
				var swell := 1.0 + k * 0.30 * f * f
				# Departarea de axa proprie a stalpului, nu de centrul arcadei:
				# altfel ingrosarea ar fi impins cei doi stalpi in afara ca un
				# tot, in loc sa-i ingroase pe fiecare.
				var post_c := half_w * 0.62 * signf(dx) if absf(dx) > half_w * 0.25 else 0.0
				v.x = cx + post_c + (dx - post_c) * swell
				v.z = cz + dz * swell
			# --- 2. grinda se lasa la mijloc ------------------------------
			else:
				var span := (t - arch_span_at) / maxf(1.0 - arch_span_at, 0.01)
				# Sageata maxima in ax, zero la stalpi.
				var mid := 1.0 - minf(absf(dx) / (half_w * 0.62), 1.0)
				v.y -= k * h * 0.055 * mid * mid * span
			# --- 3. eroziune pe toata suprafata ---------------------------
			# Trei armonici necorelate: fetele plane capata unduire, muchiile
			# drepte capata zimti. Amplitudinea e in metri de mesh (h * 0.02),
			# deci ~0.4 m pe o arcada de 21 m — se vede la 60 m, nu destrama
			# forma.
			var e := h * 0.02 * k
			v.x += e * sin(v.y * 0.9 + p1) * 0.9
			v.z += e * sin(v.y * 1.3 + p2) * 0.9
			v.y += e * (sin(v.x * 0.7 + p2) + sin(v.z * 1.1 + p1)) * 0.45
			verts[i] = v
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = null
		arrays[Mesh.ARRAY_TANGENT] = null
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		out.surface_set_material(s, src.surface_get_material(s))
	var st := SurfaceTool.new()
	var fixed := ArrayMesh.new()
	for s in out.get_surface_count():
		st.clear()
		st.create_from(out, s)
		# Fatete, ca in `_deform_mesh`: deindexat = normale pe fata.
		if faceted:
			st.deindex()
		st.generate_normals()
		var m := st.commit()
		fixed.add_surface_from_arrays(
			Mesh.PRIMITIVE_TRIANGLES, m.surface_get_arrays(0))
		fixed.surface_set_material(s, out.surface_get_material(s))
	mi.mesh = fixed


## Un patrulater ca doua triunghiuri, cu UV-ul COLAPSAT pe centrul slotului.
##
## UV-ul nu e optional. Contractul atlasului (palette.gd) cere o fata = un texel;
## un vertex fara UV pica pe (0,0), adica pe coltul din stanga-sus al atlasului
## — iar rezerva 24..31 de acolo e MAGENTA intentionat, ca greseala de UV sa sara
## in ochi. A si sarit: prima captura a iesit cu poale roz-neon la fiecare horn.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		uv: Vector2) -> void:
	st.set_uv(uv); st.add_vertex(a)
	st.set_uv(uv); st.add_vertex(b)
	st.set_uv(uv); st.add_vertex(c)
	st.set_uv(uv); st.add_vertex(a)
	st.set_uv(uv); st.add_vertex(c)
	st.set_uv(uv); st.add_vertex(d)
