class_name RoadsideSet
extends Resource
## Decorul LOVIBIL de pe marginea drumului al unei piste (decor lovibil, valul 3, nov 2026):
## butoaie, conuri, cosuri, baloti — piese usoare asezate cu intentie langa carosabil, pe care
## masina le imprastie (`BumpProp`).
##
## Continut nou = fisier nou: pista `TrackNN.tscn` isi incarca singura
## `res://scenes/tracks/roadside/TrackNN.tres`, daca exista (`RoadsideProps.attach`). Niciun rand
## de cod si nicio scena de pista nu se ating ca sa adaugi, muti sau scoti un grup.
##
## Pozitiile sunt SCRISE (fractie de tur + parte + distanta fata de margine), nu trase la sorti:
## un grup sta la iesirea dintr-un viraj sau la gura unei scurtaturi fiindca acolo iese masina
## larg, nu fiindca a cazut un zar. `tools/SurveyRoadside.tscn` masoara locurile libere si
## propune o prima asezare; fisierul ramane sursa adevarului si se corecteaza de mana.

## Piesele din care se compun grupurile: id -> descriere.
##   "glb"     calea modelului (obligatoriu);
##   "node"    numele nodului-varianta din GLB (gol = tot modelul);
##   "shape"   forma de coliziune `BumpProp`: "box" (implicit) / "cylinder" / "sphere" / "hull";
##   "mass"    masa in kg (fara cheie: densitatea de jucarie a BumpProp, 0,3-4 kg);
##   "bounce"  cat sare (0..1; fara cheie: 0,2) — mingi, geamanduri;
##   "pop"     saltul in sus la lovitura, m/s (fara cheie: `RoadsideProps.POP_SPEED`; 0 = fara);
##   "classes" "junk": piesa poarta texturi de clasa (`Track.PROPS_JUNK_CLASSES`), nu atlasul;
##   "scale"   scara uniforma (implicit 1).
@export var pieces: Dictionary = {}

## Grupurile, in ordinea turului. Fiecare e un dictionar:
##   "frac"    pozitia pe bucla principala, 0..1 (obligatoriu);
##   "side"    1 = dreapta sensului de mers, -1 = stanga (obligatoriu);
##   "gap"     metri de la marginea carosabilului pana la randul cel mai apropiat (implicit 1,2);
##   "pattern" "row" (implicit) / "wall" / "pyramid" / "taper" / "cluster" — vezi RoadsideProps;
##   "piece"   id din `pieces`, sau o lista de id-uri care se alterneaza (obligatoriu);
##   "count"   cate piese pe randul de baza (implicit 3);
##   "rows"    "wall": cate randuri in adancime (implicit 2);
##   "layers"  "pyramid": cate etaje (implicit 2);
##   "spacing" metri intre piese, de la centru la centru (implicit: latimea piesei + 8 cm);
##   "lying"   true: piesele stau CULCATE, cu axa perpendiculara pe drum — lovite din sensul de
##             mers, se rostogolesc inainte pe acostament;
##   "yaw"     rotatia grupului fata de marginea drumului, in grade (implicit 0);
##   "note"    de ce sta acolo (nu se citeste in joc).
@export var groups: Array[Dictionary] = []
