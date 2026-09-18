# POI B (Drumul Incas) — ce s-a construit si ce a ramas deschis

> Constatare de constructor, 18 sep 2026, branch `feat/mp-poi-b`, 6 commit-uri.
> Zona plecase de la **0 noduri**; are acum **291 de piese de decor** plus
> **3 noduri [CliffFace]** care fac peretele ca teren construit (sectiunea 7).

## 1. Premisa din prompt era gresita, si masuratoarea o arata

Prompt-ul spunea, citand `SvMpBuza`: „pe dreapta prima cadere de 3 m e la
17,5 m dincolo de asfalt". Survey-ul pe intervalul real spune altceva. Cotele
fata de drum, la +2 / +4 / +8 m lateral **de muchie**:

```
0.075   -0.9   -1.5   -2.9      <- aici chiar e platou
0.080   -5.2   -6.8  -13.6
0.085  -15.1  -21.4  -34.4
0.100  -26.1  -40.3  -59.3
0.140  -40.2  -55.8  -65.6
0.190  -38.7  -51.9  -64.1
```

Unghiul sub orizontala **din ochiul camerei** (10 m peste drum), la 4/8/15 m:

```
0.040    3.7    1.7    0.7      <- platou
0.080   59.7   59.6   47.6
0.100   84.3   82.3   75.9
0.190   85.6   82.9   78.8
```

Deci de la frac 0.080 in sus dreapta e **prapastie verticala**, nu umar.
Cifra de 17,5 m era media pe tot intervalul 0.04-0.20, diluata de prima
treime, care chiar e platou. **Capcana 3 din prompt** („peretii verticali apar
la 28-35 grade, e o limita de rezolutie a grilei") **nu se aplica aici**:
unghiul real e 59-86 grade, cu mult peste `scarp_slope_deg` 28, deci tenta de
stanca se aplica si se vede.

Lectia de proces: `SvMpBuza` da o cifra pe POI, dar POI-ul B are doua regimuri
(platou pana la 0.078, faleza dupa). O medie pe un interval neomogen minte.

## 2. Ce a lipsit de fapt: PIATRA, nu vegetatie

Contractul listeaza piesele incepand cu bromelii, ferigi si orhidee. Masurat
pe pixeli, deficitul e invers. Clasificare pe familii (verde = iarba, luminos
si nesaturat = cer, restul = mineral):

| sursa | mineral | iarba |
|---|---:|---:|
| **BARA** | **84,9 %** | **6,1 %** |
| 0.14 zona goala | 32,5 % | 27,6 % |
| 0.14 dupa runda 3 | **40,8 %** | **19,8 %** |
| 0.08 zona goala | 44,6 % | 41,4 % |
| 0.08 dupa runda 3 | 45,4 % | 40,6 % |

## 3. Trei greseli facute si reparate, toate utile altui POI

**(a) `moss_boulder_*` marit NU citeste a stanca.** Runda 1 a pus ~200 de
bolovani la 4-13 m pe buza si a cumparat **0,1 puncte** de roca, adaugand
iarba. Pe captura se vedeau ca niste carapace verzi — umbrele tropicale.
Cauza era deja in inventar (§2, tabelul ACCENT_SPLIT) si n-am citit-o la timp:
pe `Moss_Boulder_C` muschiul (slot 12) ocupa **68 % din inaltime, partea de
sus**. Fractia e **invarianta la scara** — marind piesa maresti capacul.
Ce citeste a piatra: `Inca_Wall_A` 93,7 % piatra, `Inca_Wall_C` 91,5 %,
`Trail_Marker` piatra curata.

**(b) Orice marime trasa la zar PER PIESA da zimti.** Inaltimea era
`randf_range(0.9, 1.7)` independent per piesa: doi vecini la 2,8 m ieseau la
0,9 si 1,7 — treapta de 0,8 m intre blocuri lipite. Dupa ce am netezit
inaltimea, sirul tot citea „scara de cutii", fiindca **retragerea** fata de
muchie avea aceeasi problema. Reparatia: amandoua din functii netede de
pozitie (doua sinusoide, lungime de unda 25-40 m).

**(c) Clasificatorul meu masura altceva decat vedeam.** Prima versiune numara
drept „roca" doar pixelii **cenusii** (satur < 0,14). Piatra lui `inca_wall` e
tan **calda**, deci cadea in galeata „drum": vedeam zidarie pe captura si
cifra spunea 0,5 %. Reclasificat pe familii. Memoria
`procent-de-culoare-nu-e-dovada`, in ambele sensuri.

## 4. Ce a ramas deschis — nu e mascat cu decor

- **Nu exista piesa de TUNEL in kit.** Contractul cere „gura de tunel cu arc
  de piatra"; cele 39 de GLB-uri n-au nici arc, nici gura. N-am fabricat-o din
  `inca_wall_*` (un arc din trei lespezi citeste a poarta prabusita, si POI C
  are deja poarta). **Cere o piesa noua**, sau contractul se schimba.
- **Sirul de zidarie are aspect de trepte pe rampa.** Piesele sunt orizontale,
  drumul urca cu 11,4 %. O piesa dreapta pe o rampa da o treapta. Ar cere
  inclinarea piesei pe panta longitudinala in generator, nu mai multe piese.
- **La frac 0.18 nu se vede nimic din decorul meu, si e corect.** E un ac
  strans: camera priveste pe INTERIORUL virajului, iar buza (cu 19 piese acolo,
  verificat pe coordonate) e in spate si sub ea. Cifra identica la bit fata de
  zona goala nu inseamna ca lipseste ceva, inseamna ca nu e in cadru.
  Daca se vrea materie in cadrul de la 0.18, ea trebuie pusa pe **interiorul**
  acului, si aia e pajiste reala (platou la -0,3 m), nu faleza.
- **Stanga e platou pe aproape tot intervalul** (-0,3 m pana la 40 m lateral),
  cu exceptia flancului 0.105-0.152. N-am pus stanca pe platou: ar fi fost
  „o piatra pe pajiste", greseala din constatarea valului 2.

## 5. Coama de la frac 0.186 — masurata A/B, neatinsa

Contractul cere ProbeRace `--seed=2` de patru ori, inainte si dupa.

```
la mine (331 piese)   0 / 0 / 0 / 0 repuneri   offroad 2,3 % pe toate patru
pe MAIN, azi          0 / 0 / 0 / 0 repuneri   offroad 0,1 / 2,3 / 0,1 / 2,3 %
```

Cifra **0/1/1/2** din nota de predare **nu se reproduce azi nici pe main**.
Diferenta nu vine din zona mea. N-am atins traseul si n-am incercat sa repar
coama cu decor.

## 6. Garzile, pe scena integrata

```
probe_decor --track=15    19 materiale (neschimbat), 9649 prop, 1 185 548 tri
ProbeBuried --track=8     0 ingropate, 0 tavane
ProbeLaneClear --track=8  18 blocate, linia de baza 20 (neschimbat fata de main)
ProbeRace seed 1 si 3     0 repuneri, 0,0 % offroad
```

**Zero materiale noi.** Toata zidaria intra pe clasa `inca_stone` existenta.
Coliziunea e `none` pe TOT decorul: contractul cere explicit „pe dreapta fara
parapet, defileul", iar un zid cu corp la 0,5 m de muchie, pe o banda de 6 m,
ar fi exact parapetul interzis.

## 7. Verdictul orb, si de ce raspunsul nu era o piesa

Sectiunea asta inlocuieste predictia de la predarea rundei 4 („urmatorul pas
util e o runda de critic orb [...] daca verdictul cere iar «stanca», intrebarea
e daca mai poate da zona ceva sau e o limita de kit"). Criticul a cerut iar
stanca, si **nu era o limita de kit** — era o eroare de categorie.

Verdictul, pe scurt: «drumul nostru nu e taiat in nimic [...] in locul
peretelui sunt ~15 blocuri de piatra razlete, la scara de recuzita, stand libere
pe iarba — material corect, OBIECT GRESIT: citesc ca moloz sau ruine, nu ca o
masa cioplita. Nimic pe stanga nu e mai inalt decat masina.» Si, important,
si-a ordonat singur reprosurile: nepotrivirea de scara, lipsa vegetatiei
agatate si lumina plata sunt **consecinte** ale aceluiasi lucru.

Avea dreptate. Diagnosticele rundelor 2-4 erau corecte dar incomplete:

- runda 2 a aflat ca materia trebuie sa fie zidarie, nu muschi;
- runda 3 a aflat ca inaltimea si retragerea nu se trag la zar per piesa.

Amandoua raspundeau la intrebarea **„ce piesa pun?"**, cand intrebarea era
**„de unde vine FORMA?"** — memoria `capcana-parametrului-care-doar-aduna`,
aplicata la mine insumi peste trei runde.

Cifra care inchide discutia era in propriul meu survey, nota 2, de la inceput:
pe stanga terenul e **platou la -0,3 m** pe tot intervalul, in afara de
0.110-0.145. `inca_wall_a` are **2,487 m**. O fata de 17 m ar cere **7 asize
suprapuse** — adica un zid de cetate, nu un versant taiat. Nu exista densitate
la care piese de recuzita sa devina masa: le lipseste terenul de dedesubt.

**Un perete nu e decor, e TEREN.** Iar terenul nu se poate cere campului de
inaltime: celula grilei e 7,92 m, deci orice taietura lipita de asfalt se
intinde pe o celula intreaga si iese rampa. Exact motivul pentru care exista in
proiect nodul [CliffFace] cu `cut_wall` — construit pentru un verdict aproape
identic pe POI C al Cappadociei („nu e o problema de culoare, e ca NU EXISTA
nicio fata de stanca"). Unealta era deja acolo; eu n-o cautasem.

Trei noduri in `Faleze/` (TaieturaDrumIncasA/B/C, fractiile 0.044-0.207), cu
`cut_min_rise_m` 12,5-15 ca peretele sa nu se stinga pe platou — acelasi
mecanism cu care Serengeti si-a facut malul dintre bratele serpentinei. Cele 40
de noduri `pereteStg` au fost **retrase**: stateau in fata peretelui real,
adica erau chiar recuzita reclamata.

### Sloturile: gresite o data, corectate pe captura

Prima incercare a folosit sloturile 3/29/4, fiindca asta scrie palette.gd:723
ca fiind amestecul zidariei incase. Peretele a iesit **portocaliu-caramiziu**
(`B_r5_f0.14.png`). Cauza, citita din atlas cu PIL:

```
slot  3  #CE8D4A  H 30,5  S 0,64     <- gresie calda de canion
slot  4  #774C23  H 29    S 0,71
```

Cifrele din palette.gd sunt **tinta pe care o atinge clasa `inca_stone` DUPA
lift+tenta**, pe piesele de kit. Panza falezei nu trece prin clasa aia: ia
slotul BRUT din atlas. Deci pe ea sloturile se aleg dupa culoarea bruta, si
ancora e `scarp_tint` al temei (#4A4844, H40 S0,08) — granitul andin pe care il
are deja rapa de alaturi:

```
slot 29  #B6B2AA  H 40,0  S 0,07     <- aceeasi nuanta, mai deschis
slot  8  #C8BDA9  H 38,7  S 0,16     <- coama in soare
slot  6  #5C5A59  H 20,0  S 0,03     <- strat neutru inchis
slot 20  #56545B  H 257   S 0,08     <- umbra rece
```

Niciunul peste S 0,16; slotul 3 sta de **opt ori** mai saturat.

Lectia, generala: **o cifra din palette.gd e tinta de dupa clasa, nu culoarea
slotului.** Cine deseneaza direct pe atlas (faleza, panzele) citeste atlasul.

### Ce a cumparat peretele, masurat

Clasificare HSV identica cu cea din antetul generatorului (cea cu care runda 2
si-a masurat esecul), pe imagini redimensionate 320x180:

| sursa | roca | iarba | drum |
|---|---:|---:|---:|
| **BARA** | **10,1 %** | **5,9 %** | 34,0 % |
| 0.08 zona goala | 3,4 % | 40,4 % | 41,7 % |
| 0.08 runda 4 (piese) | 3,4 % | 39,7 % | 41,5 % |
| **0.08 runda 8 (perete)** | **18,7 %** | **17,3 %** | 42,9 % |
| 0.14 zona goala | 0,2 % | 26,7 % | 33,3 % |
| 0.14 runda 4 (piese) | 0,5 % | 19,1 % | 34,2 % |
| **0.14 runda 8 (perete)** | **19,2 %** | **9,4 %** | 27,7 % |

Rundele 1-4, cu 220+ piese, n-au mutat cifra cu nimic masurabil (3,4 -> 3,4 si
0,2 -> 0,5). Peretele o duce de la ~0 la ~19 % si scade iarba spre valoarea
barei. Depasim usor roca barei, si e asteptat: bara e o diorama larga cu cer si
vale, capturile mele sunt din ochiul soferului, cu peretele pe o latura.

### Ce NU s-a imbunatatit, si o spun cu cifra

Criticul a numit si „lumina plata [...] n-avem nicio suprafata mare care sa
primeasca gradientul". **Intinderea de luminanta pe jumatatea stanga nu s-a
imbunatatit**: 149 la runda 4, 139 la runda 8, fata de 156 in bara. Ce s-a
schimbat decisiv e **mediana**: 183 -> 102, fata de 146 in bara. Stanga rundei
4 era o pajiste spalata, lipita de alb; acum e o masa cu corp in ton mediu.
Reprosul era despre o stanga *uniforma*, si mutarea medianei e dovada onesta —
dar nu revendic un castig de contrast pe care cifra nu-l sustine.

## 8. Ce ramane deschis, nemascat

**(a) Gura de tunel — nu exista piesa in kit.** Contractul o cere („gura de
tunel cu arc de piatra"). Cele 39 de GLB-uri nu contin niciun arc si nicio gura.
Nu o fabric din `inca_wall_*`: un arc din trei lespezi citeste a poarta
prabusita, si POI C are deja poarta.

Important pentru cine judeca urmatoarea runda: **portalul dreptunghiular pe care
criticul l-a vazut „cu cer si deasupra si prin el" NU e al meu.** E `main_gate`
din `ZoneC_PoartaSoarelui` (Track15.tscn, nodul `poartaSoarelui1`), vizibil de
la frac 0.14 fiindca C e mai departe pe aceeasi creasta. Zona B n-are niciun nod
de poarta. Verdictul e corect ca observatie despre cadru, dar reparatia nu e in
zona mea.

**(b) Dunga portocalie de pe marginea drumului** (vizibila in toate capturile,
si pe stanga si pe dreapta) e umarul drumului de pamant din
`custom_road_surface = "dirt"`. Verificat pe captura zonei GOALE
(`B_r0_gol_f0.08.png`): e acolo si fara niciun nod de-al meu. Preexistenta, si
in familia drumului tan din bara.

**(c) Fisuri de cer intre blocurile fatetate**, reduse nu eliminate: 0,69 % ->
0,51 % din caseta peretelui (pixeli cu min(RGB) > 225), dupa ce `cut_facet_m` a
scazut 1,3 -> 0,85 si saltul de coama 1,0 -> 0,55. Sub atat, fatetarea incepe
sa se piarda.

**(d) Coama de la frac 0.186** — neatinsa, si nu se repara cu decor. ProbeRace
`--seed=2` de patru ori, dupa perete: **0/1/1/1**, in banda documentata
(0/1/1/2). Pe intervalul meu (0.15-0.20): 0,0 % offroad, 0 pereti.

## 9. Garzile, pe scena integrata, dupa perete

```
probe_decor --track=15    19 materiale (NESCHIMBAT), 9611 prop, 1 183 756 tri
                          baza era 19 / 9649 / 1 185 548 — tot SUB baza
ProbeBuried --track=8     0 ingropate, 0 tavane
ProbeLaneClear --track=8  18 blocate, identic cu baza (prag 20)
ProbeRace seed 1 si 3     0 repuneri, 0,0 % offroad, 0 pereti pe 0.00-0.25
ProbeRace seed 2 x4       0/1/1/1 — banda preexistenta
```

**Peretele costa ZERO materiale**: e tot `Palette.world_material`, benzile sunt
UV-uri pe sloturi din acelasi atlas. Triunghiurile au SCAZUT fata de baza,
fiindca cele 40 de piese de zidarie scoase cantaresc mai mult decat panza.

Peretele ARE coliziune (trimesh) — spre deosebire de tot restul decorului, unde
e `none`. E corect si intentionat: contractul cere „pe stanga peretele", si
`cut_offset_m` 7,6 cu semilatime 6,0 lasa banda libera prin constructie
(fatetarea se retrage doar spre interior, niciodata spre drum). ProbeLaneClear
o confirma: 18 blocate, exact ca inainte. Interdictia de parapet e pe DREAPTA,
unde n-am pus nimic cu corp.
