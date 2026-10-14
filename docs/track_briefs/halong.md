# Track brief — Ha Long Bay (`Track22`, temă `halong`) — v0.4 (fundație construită și condusă)

> **v0.5 (14 oct 2026):** fundația `Track22.tscn` există, se încarcă fără erori
> și **se conduce curat** — ProbeRace pe patru seed-uri: tur minim **59,8 s**,
> mediu **68,6–70,1 s**, **0% offroad**, **zero blocaje**, **zero ieșiri din
> lume**, și doar **1–3 repuneri** per cursă, toate pe joncă (adică pe hazard,
> unde le e locul).
>
> Jonca e **reglată din măsurători**: gabarit 6,49 m pe carosabil de 11,5 m →
> bandă liberă **5,01 m**, `sweep_speed` la implicitul clasei (12,0). Reglajul
> a tăiat repunerile cu **75%** (de la 6/8/6/7 la 1/3/2/1) și a *scăzut* turul
> mediu. Contractul e acum **gardă în generator**, nu doar o cifră în scenă.
>
> **§7.1** e partea de citit dacă reiei lucrul: conține trei ipoteze greșite
> măsurate, două unelte stricate de mine și prinse tot măsurând, și de ce
> fiecare a fost greșită.
>
> **`PontoonRoadHazard` EXISTĂ** (§7.2): trei tronsoane vii pe pistă, cu
> afundare pe masă (autobuz 0,450 m, sport 0,180 m — exact țintele), prag la
> insuliță 0,042 m (contract < 0,3), tangaj și val propriu. Podul de pe Machu
> Picchu e **neatins** și toate contractele lui trec.
>
> **`TideHazard` + banda de jos sunt pe pistă** (§7.3). Scurtătura de maree
> cerea o coardă joasă care nu exista pe traseul inițial, deci **latura de
> coastă s-a redesenat** (decizia dezvoltatorului): drumul ocolește acum un
> golf de 100 m, iar banda taie peste gura lui — **−32,8%**, în ținta Monument
> Valley, pe teren plat. Bucla a crescut la **2 076 m**, toate gărzile trec.
>
> **O problemă deschisă:** redesenarea a adus o regresie pe primul ponton
> (repuneri 0/3/0/4 → 1/13/2/9 pe aceleași seed-uri). Cinci ipoteze eliminate
> prin măsurare, scrise în §7.3 ca să nu fie reluate.
>
> **Următorii pași:** regresia de pe primul ponton, `CameraZone` pe grotă,
> gărzile de layout (`ProbeLayout`, `ProbeBuried`, `ProbeLaneClear` cu linie
> de bază proprie), apoi verdictul dezvoltatorului la volan.

> Concept de pistă, înaintea listei definitive de assets. Scheletul e cel din
> `transfagarasan.md`, `okinawa.md` și `monument_valley.md`. Secțiunile de
> assets (§5) sunt o schiță plus un **audit al kiturilor marine existente**
> (Okinawa, Fiordland). Lista completă se scrie după ce traseul trece de
> ProbeLayout, de ProbeRace și de captura `--gamecam`.
>
> **v0.3 (14 oct 2026):** trecerea de contracte făcută pe cod citit (§5.3) și
> **schița de traseu măsurată** (§2.1), cu `tools/measure_halong_sketch.py`.
> Ce s-a schimbat față de v0.1, tot din măsurători:
> - **sensul buclei: ANTIORAR**, nu orar (afirmația din v0.1 era greșită,
>   geometria e bună);
> - **insula coborâtă la +26** (de la +38), fiindcă `sea_y = mean_road_y() +
>   sea_level_offset`: insula înaltă **ridica marea** peste pontoane (§2);
> - **acele de păr la rază 24 m**, nu 17 (prima schiță dădea 6,1 m măsurat);
> - **turnurile de fundal mutate la est** (430, −150): de pe belvedere drumul
>   merge spre NE, iar la SE se vedeau în **0/7 cadre**;
> - **pontonul e subclasă mică**, nu clasă nouă: `RopeBridgeHazard` duce
>   aproape tot, cu trei schimbări identificate (§5.3);
> - patru iterații de schiță până au trecut toate gărzile; prima avea 1 140 m,
>   rază 6,1 m, pantă 29,7% și apa peste pontoane.
>
> **Prima pistă nouă care NU înlocuiește una existentă** de la Fiordland
> încoace: Monument Valley, Okinawa și Transfăgărășanul au luat locul Dunelor,
> al Okinawei manuale și al Alpilor. Ha Long **se adaugă**, pe indexul 15 (§7).
>
> **v0.1 (14 oct 2026), cererea dezvoltatorului:** „ce fel de biome am putea
> face la următoarea hartă dintr-o locație reală din lume, astfel încât să fie
> unică în felul ei, să aibă propria personalitate, poate să fie hazard nou
> sau și hazarde refolosite”. Candidații puși pe masă: **Ha Long Bay**,
> Monte Roraima / Angel Falls, terasele de orez Banaue, Salar de Uyuni.
> Alegerea dezvoltatorului: **Ha Long Bay**.
>
> **Ce gol din roster umple.** Cele 15 piste acoperă deșert (Dunele, Monument
> Valley, Jodhpur, Cappadocia), munte (Alpii, Machu Picchu, Transfăgărășan),
> gheață (Baikal), vulcan (Stromboli), coastă tropicală (Okinawa), savană
> (Serengeti), fiord (Fiordland) și urban (Chongqing, Kyoto, Jodhpur). Lipsesc
> trei familii: **junglă tropicală**, **mare de carst** și **zone umede**.
> Zonele umede sunt plate, ceea ce se bate cap în cap cu principiul 3
> (elevație folosită agresiv), deci rămân afară. Ha Long le ia pe celelalte
> două deodată: turnuri de calcar verticale ieșind din apă adâncă, cu junglă
> agățată pe pereți.
>
> **Ce e diferit față de celelalte piste cu apă.** Okinawa înseamnă *plajă,
> corali, apă turcoaz joasă, calcar Ryukyu*. Fiordland înseamnă *pereți uzi,
> verde închis, ploaie, apă neagră*. Baikal înseamnă *gheață*. Ha Long
> înseamnă **apă verde-jad adâncă din care ies turnuri de calcar pe verticală,
> și un drum care plutește pe ea**. Diferența se verifică pe capturi puse
> alături (§6), nu se presupune.

## 0. Într-o propoziție

O dimineață de primăvară târzie, cu **ceața joasă încă agățată între turnuri**
și soarele abia ridicat peste ele. Pornești de pe **cheiul de piatră al unui
sat de pescari**, treci pe **drumul de pontoane care se leagănă sub tine** prin
inima satului plutitor, ieși pe un **dig de piatră** printre primele turnuri de
calcar, intri în **grota marină** prin care drumul trece sub un turn întreg,
urci pe **spinarea unei insule** printre **ficuși cu rădăcini pe stâncă** și
vezi de sus **golful întreg, cu zeci de turnuri în ceață**, cobori în serpentină
scurtă pe **plaja din căldarea insulei**, treci **canalul pe un podeț de
plute** unde **jonca de pescari taie drumul**, și închizi bucla pe **drumul de
coastă săpat în peretele de calcar**, cu **maimuțele** pe parapet și **mareea**
care îți ia banda de jos când e sus.

Singura pistă din joc în care **o parte din drum plutește**: nu e platformă
care te duce (telecabina, podul rotitor), e **carosabil normal care cedează și
se leagănă sub masa mașinii**.

## 0.1 Regula de artă (ce NU e pista asta)

**Nu „Asia de sud-est generică”** (temple aurii, pagode, lampioane roșii,
dragoni, acoperișuri curbate — alea sunt Kyoto și, pe altă linie, Chongqing).
**Nu „insula tropicală de vacanță”** (palmieri de carte poștală, apă turcoaz,
umbrele, cocktailuri — alea sunt Okinawa). **Nu „piratul din Caraibe”**
(corăbii cu tunuri, steaguri negre, cufere).

Ce trebuie să recunoască jucătorul în 3 secunde: *„turnuri de calcar cenușii
ieșind drept din apă verde-jad, ceață joasă între ele, bărci de lemn cu vele
roșii, case pe plute.”* Turnurile de calcar văzute în șir, cu ceața între ele,
sunt pentru Ha Long ce sunt serpentinele pentru Transfăgărășan și Mittens-urile
pentru Monument Valley.

Ce **nu** luăm, cu motiv:
- **vapoare de croazieră mari, albe**: sunt reale în golf (prea reale), dar
  citesc „resort”, nu „golf de pescari”. Rămân joncile de lemn și bărcile mici;
- **plaje largi de nisip alb**: Ha Long are fâșii mici de nisip în căldări, nu
  plaje de Okinawa. O singură plajă, mică, în căldarea insulei (POI E);
- **apa turcoaz transparentă**: apa din golf e **verde-jad opac**, cu
  sedimentul care vine din deltă. Asta e culoarea locului și e principala
  diferență de paletă față de Okinawa;
- **corali și pești tropicali**: apa e tulbure, nu se vede în ea.

| pondere | strat |
|---|---|
| **35%** | turnurile de calcar: pereți verticali cenușiu-deschis, erodați la bază în **surplombe** (valul mâncă piciorul turnului), cu dungi verticale închise de la apa care curge, vârfuri rotunjite acoperite de vegetație |
| **25%** | apa: **verde-jad opac**, reflexii lungi ale turnurilor, siaj de barcă, ceața joasă care stă **pe** apă între turnuri |
| **20%** | vegetația de carst: **ficuși cu rădăcini aeriene** agățați pe pereți, bambus în căldări, iarbă aspră pe vârfuri, mangrove joase pe malul satului |
| **12%** | drumul și lucrările lui: **pontoane de bambus și butoaie albastre**, dig de piatră, **drumul săpat în perete** cu parapet de beton, podețul de plute, cheiul satului |
| **8%** | urmele omului: **case plutitoare** cu acoperiș de tablă ondulată, **ferme de pești** cu plase și pătrate de plute, **jonci cu vele roșii**, coșuri de nuiele, năvoade întinse, bărci-coș rotunde |

Trei acte pe un tur, **aceeași paletă, altă proporție**:
- **satul plutitor** (pontoane, case, plase, apă aproape: cenușiu-lemn,
  albastru de butoi, verde-jad);
- **turnurile și grota** (calcar, umbră, apă adâncă, ceață: cenușiu, verde
  închis, întuneric);
- **insula** (spinarea, jungla, plaja, coasta: verde cald, calcar însorit,
  nisip).

Nu trei palete.

## 1. Referința reală (ce luăm din fiecare loc)

Ha Long-dioramă: **fiecare reper există**, dar golful real are ~1 600 de
insule pe 1 500 km². Compresia e declarată, ca la Okinawa (insula compusă) și
Monument Valley (arcul). Bucla însăși e plauzibilă: e turul pe care îl fac
bărcile de o zi — sat plutitor, grotă, insulă cu belvedere, plajă.

| loc real | ce luăm |
|---|---|
| **Satul plutitor Cửa Vạn / Vung Vieng**: case pe plute legate între ele, cu pasarele de bambus, ferme de pești în pătrate de plase, școală plutitoare | **POI A + B**: startul pe cheiul de piatră și **drumul de pontoane** prin sat (§3, hazardul-semnătură) |
| **Turnurile de calcar** (karst tower): sute de turnuri verticale de 50–200 m, erodate la bază, cu vegetație pe creastă | **fundalul și flancurile pe tot turul**; cele apropiate sunt **flanc**, nu fundal (memoria `munte-flanc-nu-fundal`) |
| **Hang Luồn / Hang Trống**: tuneluri și arcade marine prin care bărcile mici trec dintr-o parte în alta a unui turn, la nivelul apei | **POI C**: **grota marină** prin care trece drumul, sub un turn întreg |
| **Insula Titop**: insulă cu scări până pe vârf, de unde se vede golful întreg, și o plajă mică în căldare | **POI D + E**: urcarea pe spinare, **belvederea cu golful în parbriz**, apoi coborârea pe plaja din căldare |
| **Ficușii de carst** (*Ficus* pe pereți de calcar), bambus, mangrove la gura râurilor | **vegetația**: rădăcini aeriene pe pereți, bambus în căldări, mangrove pe malul satului |
| **Joncile de pescari** cu vele roșii-cărămizii și **bărcile-coș** rotunde de bambus | **POI F**: **jonca** taie canalul (hazard refolosit), bărci-coș ca decor în sat |
| **Maimuțele macac** de pe insulele golfului (Monkey Island / Cát Bà), obișnuite cu oamenii | **POI G**: maimuțele pe parapetul drumului de coastă (§3) |
| **Mareea de 3–4 m** din golful Tonkin, care descoperă și acoperă baza turnurilor și plajele | **mecanica de fundal a pistei** (§3): **banda de jos a drumului de coastă** e sub apă la maree înaltă |
| **Ceața joasă de primăvară** (*mùa nồm*), care stă pe apă între turnuri și lasă vârfurile libere | **identitatea atmosferei** (§4): ceață **joasă, în strat**, nu globală |

**Culorile locului** (de măsurat pe fotografii la construcția temei, nu
copiate):
- calcarul: cenușiu-deschis în soare (`#A8A49A`), cenușiu-rece în umbră
  (`#6E7276`), dungi verticale închise de la scurgeri (`#4C4F4A`), **surplomba
  de la bază neagră-umedă** (`#3A3C38`);
- apa golfului: **verde-jad opac** (`#4A7A6B`), mai deschisă la mal
  (`#6E9B86`), aproape negru-verde în umbra turnurilor (`#2A4A42`);
- ceața joasă: alb-cald cu nuanță verzuie (`#D8DCD4`) — **în familia apei**,
  nu a cerului (memoria `ceata-in-familia-solului`, aplicată pe apă);
- vegetația: ficus verde-mediu cald (`#4E7A42`), bambus verde-gălbui
  (`#7D9A4E`), mangrove verde-închis (`#2E4A38`);
- lemnul pontoanelor și al joncilor: lemn cenușiu de apă sărată (`#8A7E6C`),
  **velele roșii-cărămizii** (`#A8503A`);
- butoaiele de flotor: **albastru de plastic** (`#2E6FA8`) — accentul cel mai
  puternic al pistei, în pete mici;
- tabla ondulată a caselor: albastru-verzui spălăcit (`#6E8A88`), ruginit
  (`#8A5A42`);
- nisipul plajei: crem-cenușiu (`#C8BFA8`), nu alb de Okinawa;
- asfaltul/betonul drumului de coastă: gri cald (`#9A968C`), **fără linii**
  (drum de insulă).

**Lumina:** soare de dimineață târzie, din **ESE** (~30°), alb-cald. Turnurile
dinspre est au fața aprinsă și aruncă **umbre lungi pe apă**, care sunt
lizibile fiindcă apa e opacă. Asta e identitatea luminii: **umbre de turn pe
apă verde**, plus **ceața joasă care taie turnurile la jumătate** și le separă
în straturi de adâncime (memoria `scara-de-adancime-are-gol`: ceața în strat
dă exact scara pe care o pierde ceața globală).

## 2.0 Verificarea cu camera (de ce reperele stau unde stau)

`ChaseCamera`: **10 m sus, 12,5 m în spate, 28,7° în jos, FOV 68°** (memoria
`verifica-cu-parametrii-lui`). Marginea de sus a cadrului e la **+5,25°**, deci
la distanța `d` camera vede cel mult **10 + 0,092·d** m peste cota drumului.
Jumătatea de cadru lateral e **~50°**. Fiecare reper se verifică pe **patru
axe**: distanță, verticală, **azimut** și **ocluzie** (memoria
`reperul-se-vede-pe-patru-axe`).

**Consecința principală, scrisă înaintea traseului:** turnurile de calcar au
50–200 m în realitate, iar camera vede doar `10 + 0,092·d` m peste cota
drumului. Un turn de 80 m la 100 m distanță intră în cadru doar pe
**19 m** din înălțime, adică un sfert. Două consecințe:

1. **Turnurile apropiate sunt flanc, nu reper** (memoria
   `munte-flanc-nu-fundal`): la < 40 m lateral se citesc ca **perete** care
   trece pe lângă tine, și e corect — exact așa se simt din barcă. Nu se
   încearcă să fie „văzute întregi”;
2. **Șirul de turnuri se citește de pe belvedere, privind în jos și în
   depărtare** (POI D). **Măsurat** (§2.1): de pe belvedere șirul de turnuri
   cade în cadru pe **7 din 10 cadre**, la **238–291 m**. Ce contează nu e
   înălțimea lor în cadru, ci **ceața joasă care le separă în straturi**.
   Dezvăluirea pistei nu e un obiect, e **adâncimea**.

De aceea pista **urcă pe insulă la mijlocul turului**: belvederea e singurul
loc din care golful se citește ca golf, iar ea cere cotă. Restul turului e la
nivelul apei, unde turnurile sunt pereți.

Tabelul de frustum se completează pe `Track22` cu
`tools/halong_frustum_table.py` (tiparul `transfagarasan_frustum_table.py`),
**înainte de decor**, pe reperele fixe din §2.1. Întrebările pe care trebuie
să le închidă:
- de pe belvedere (D), câte straturi de turnuri se văd în cadru, și ceața le
  separă sau le topește într-unul?
- de pe pontoane (B), se vede **turnul care conține grota** (C), ca
  telegrafare a ce urmează?
- din grotă (C), se vede ieșirea, sau tunelul citește ca „fund de sac”?
- de pe drumul de coastă (G), se vede satul plutitor peste golf, adică se
  închide bucla vizual?

## 2. Traseul și punctele de interes (POI)

Lungime **2 028 m, măsurată** (§2.1; tur ~70–75 s, 3 tururi ≈ 3:40), în
fereastra Ignition 65–80 s din `ref_notes/sisteme.md`.

**Sens ANTIORAR pe plan** (corectat în v0.3: v0.1 spunea „orar”, iar
măsurătoarea pe schiță a arătat antiorar — geometria e bună, afirmația era
greșită). Bucla are două jumătăți: jumătatea de **apă** (satul, pontoanele,
digul, grota, canalul) și jumătatea de **uscat** (insula: urcarea, belvederea,
plaja, drumul de coastă). Satul plutitor stă în **nord-vestul** buclei, iar
insula în **est / sud-est**: A coboară spre sud pe latura de vest, C taie spre
est pe latura de sud, D–E urcă și coboară insula în est, iar F–G se întorc
spre vest pe latura de nord.

Fracțiile și cotele de mai jos sunt **măsurate pe schița din §2.1**, nu
estimate:

| POI | fracții | cote | lățime (semi) | ce e |
|---|---|---|---|---|
| **A** cheiul satului | 0,98 → 0,05 | +1,0 | 7 | startul pe cheiul de piatră, casele plutitoare pe dreapta, plasele, bărcile-coș |
| **B** pontoanele | 0,05 → 0,24 | **+0,6** (plutitor) | **6** | **drumul de pontoane**: trei tronsoane care se leagănă (frac ~0,08 / ~0,15 / ~0,22), separate de două insulițe de piatră fixă (frac ~0,12 / ~0,18) |
| **C** digul și grota | 0,24 → 0,36 | +1,5 → +3,0 | 7 / **6** în grotă | dig de piatră printre turnuri (0,25), apoi **grota marină** (~70 m, frac 0,30 → 0,35) prin baza unui turn |
| **D** urcarea și belvederea | 0,36 → 0,53 | +3,0 → **+26** | 7 | urcare pe spinarea insulei printre ficuși, **belvederea** la frac **0,47**, de unde se telegrafiază mareea (§3) |
| **E** coborârea și plaja | 0,53 → 0,74 | +26 → +1,6 | 7 | două ace de păr (**rază 24 m**, frac ~0,60 și ~0,68), **plaja** din căldare la 0,71, nisip lent (§3) |
| **F** canalul | 0,74 → 0,84 | +1,4 | **6** pe podeț | **podețul de plute** peste canal (frac 0,78 → 0,83), cu **jonca** care îl taie la ~0,81 (§3) |
| **G** drumul de coastă | 0,84 → 0,98 | +1,6 → +1,2 | 7 (**banda de jos** separată) | drum săpat în peretele de calcar, cu **banda de jos la +0,4** care intră sub apă la maree înaltă (§3), **maimuțele** la ~0,94, satul plutitor vizibil peste golf (8/8 cadre, §2.1) |

Sens **ANTIORAR**. Nordul e sus; x creste spre est, y spre nord (§2.1).

```
   N ↑
     [A] CHEIUL ◄── START (-352, 322)
      │  case plutitoare, plase, barci-cos
      │                                     [G] DRUMUL DE COASTA
      ▼ [B] PONTOANELE (se leagana)      ◄───── sapat in perete de calcar
      ● tronson 1   (frac 0.08)                 MAIMUTELE pe parapet (0.94)
      ○ insulita    (0.12)  fixa                BANDA DE JOS sub apa la maree
      ● tronson 2   (0.15)                      (satul se vede: 8/8 cadre)
      ○ insulita    (0.18)  fixa                      ▲
      ● tronson 3   (0.22)                            │
      │                                               ● [F] CANALUL (0.78-0.83)
      ▼ [C] DIGUL (0.25) si GROTA (0.30-0.35)         │ PODETUL DE PLUTE
      ●──► printre turnuri, apoi SUB un turn          │ JONCA taie drumul (0.81)
          ╲                                           │
           ╲ [D] URCAREA pe spinare (ficusi)          ● PLAJA (0.71, nisip lent)
            ●  BELVEDEREA (0.47, +26 m):              ╱
            │  turnurile de fundal 7/10 cadre,       ╱ [E] COBORAREA
            │  la 238-291 m, in STRATURI de ceata   ╱  doua ace de par (raza 24)
            ╰────────► varf (+26) ──────────────────╯   (frac 0.60, 0.68)

   Turnurile de calcar: in jurul buclei si INTRE POI, ca FLANC (< 40 m lateral).
   Sirul de fundal e la EST, centrat pe (430, -150): se vede de pe belvedere,
   unde drumul merge spre NE. Trei planuri de adancime (240 / 270 / 290 m),
   separate de ceata joasa — aia e dezvaluirea, nu un obiect.
```

**Apa, relieful, mareea.**
- **apa golfului** e suprafața dominantă: tema are nevoie de apă de mare
  (tiparul Okinawa / Fiordland, nu lac). Cota apei e **0**, iar drumul de
  pontoane plutește la **+0,6**;
- **turnurile de calcar** sunt relief (`TerrainPeak` / `terrain_bluff`) **plus**
  GLB-uri de turn pentru cele apropiate, unde silueta contează. Cele de fundal
  (150–320 m) sunt `horizon_model`, cu **`cast_shadow` OFF** (memoria
  `caster-departat-fura-umbra`);
- **insula** (POI D–E) urcă la **+26** pe spinare (coborâtă de la +38 în v0.3,
  ca media cotelor să nu ridice marea — vezi caseta de mai jos), cu căldarea
  plajei la +1,6;
- **grota** (C) cere `CameraZone` cu **tavan propriu** (memoria
  `camera-zone-tavan-per-sala`: implicitul de 15 m ratează săli de 16/18 m);
  înălțimea grotei e ~11 m, deci tavanul se declară explicit;
- **mareea** nu mișcă toată apa (ar fi scump și ar strica siluetele): mișcă
  **doar banda de jos a drumului de coastă** (§3), printr-o suprafață de apă
  locală. Decizia e în §3.1.

**De măsurat cu ProbeLayout:** pantă < 13%, rază ≥ 9 m, apropiere de sine
≥ 20 m. Bucla stă la **< 420 m de centroid** (memoria
`ziduri-invizibile-ale-lumii`: zidul lumii e la 420, iar plasa de mare la cota
medie −7 taie piste noi — pe o pistă care e **jumătate pe apă**, asta se
verifică **înaintea** traseului, nu după).

> **Constrângerea tehnică centrală a pistei, găsită în cod (v0.3) și deja
> rezolvată în schiță.** `track.gd:7055` o spune explicit, cu avertisment:
> **cota mării e `_sampler.mean_road_y() + sea_level_offset`, relativă la
> media cotelor șoselei, nu la `y = 0`** („asta e capcana: … «nivelul mării e
> zero» e o presupunere pe care n-o pui la îndoială”).
>
> Pe o pistă **jumătate pe apă**, asta leagă cotele de pe apă (cheiul +1,0,
> pontoanele +0,6) de media **întregului** traseu — deci **insula ridică
> marea**. Cu insula la +38 din v0.1, media ieșea +8,2, iar marea la offsetul
> implicit (−7) ar fi stat la **+1,2**: pontoanele scufundate, cheiul la buza
> apei. Nu e un bug pe care l-ar fi prins o gardă geometrică; iese doar din
> citit cota mării împreună cu media.
>
> **Rezolvarea, măsurată:** insula coborâtă la **+26** (de la +38) duce media
> la **+6,0**, iar `sea_level_offset` se pune **explicit la −6,0**, nu pe
> implicit — atunci apa iese la **0,0**, exact cota pentru care sunt desenate
> cheiul și pontoanele. Offsetul **se recalculează la fiecare redesenare de
> traseu**, ca azimutul soarelui: orice mutare de cotă mișcă media, deci mișcă
> marea.
>
> **Plasa de repunere** nu e o cotă globală (cum spunea v0.1): `_build_sea_respawn`
> o pune la **`sea_y − 1,2`**, cu 60 m de adâncime. La apă 0,0 plasa e la
> **−1,2**, iar pontonul complet afundat (−0,3, adică `rest_sag + sag_bus` sub
> +0,6) rămâne **deasupra** ei — deci mașina de pe ponton nu e repusă din
> greșeală. Marja e 0,9 m și e **de verificat în ProbeRace**, fiindcă valul
> joncilor o mai mănâncă.
>
> ProbeRace rămâne **la început**, pe traseul gol (memoriile
> `proberace-la-inceput-nu-la-final`, `ziduri-invizibile-ale-lumii`): zidul
> lumii la 420 m e respectat (Cebîșev 305 m, §2.1), dar restul se vede doar
> conducând.

### 2.1 Schița de waypoint-uri — **MĂSURATĂ** (v0.3, 14 oct 2026)

Coordonate de hartă: x est, y nord, metri; în Godot `gx = x`, `gz = −y`,
**fără oglindire** (convenția din `gen_kyoto_route.py`). Coloanele sunt
(x, y, rază de fillet, cotă, etichetă).

Măsurată cu funcțiile geometrice din `gen_transfagarasan_route.py` (fillet pe
arc, pas 12 m, statistici ca ProbeLayout). **Patru iterații** au fost necesare:
prima schiță avea 1 140 m, rază 6,1 m, pantă 29,7% și apa peste pontoane.
Cifrele de mai jos sunt ale schiței care trece toate gărzile.

```python
WPTS = [
    # --- A: cheiul satului plutitor (nord-vest) ----------------------------
    (-352,  322, 44,  1.0, "A start"),     (-362,  240, 0,   1.0, "A chei"),
    # --- B: pontoanele, trei tronsoane despartite de insulite fixe ---------
    (-354,  168, 0,   0.6, "B pont1"),     (-346,   96, 0,   0.6, "B insulita1"),
    (-338,   24, 0,   0.6, "B pont2"),     (-330,  -48, 0,   0.6, "B insulita2"),
    (-320, -120, 0,   0.6, "B pont3"),
    # --- C: digul de piatra, apoi grota marina ----------------------------
    (-296, -188, 44,  1.5, "C dig"),       (-218, -240, 0,   2.4, "C grota V"),
    (-130, -266, 0,   3.0, "C grota E"),
    # --- D: urcarea pe spinarea insulei + belvederea -----------------------
    ( -36, -284, 48,  7.0, "D urcare"),    (  60, -272, 44, 14.0, "D creasta"),
    ( 152, -224, 40, 21.0, "D belvedere"), ( 204, -152, 0,  26.0, "D varf"),
    # --- E: coborarea in doua ace de par + plaja ---------------------------
    ( 196,  -52, 24, 21.0, "E ac1a"),      ( 132,  -36, 24, 17.0, "E ac1b"),
    ( 164,   28, 24, 11.0, "E ac2a"),      ( 228,   44, 24,  7.0, "E ac2b"),
    ( 212,  112, 0,   3.0, "E plaja"),     ( 156,  164, 44,  1.6, "E iesire"),
    # --- F: canalul cu podetul de plute -----------------------------------
    (  84,  192, 0,   1.4, "F podet E"),   (  -8,  206, 0,   1.4, "F podet V"),
    # --- G: drumul de coasta, sapat in perete -----------------------------
    (-104,  226, 48,  1.6, "G coasta E"),  (-206,  262, 0,   1.4, "G maimute"),
    (-292,  300, 44,  1.2, "G coasta V"),
]
```

**Cifrele măsurate:**

| mărime | valoare | prag |
|---|---|---|
| lungime | **2 028 m** (169 de puncte, pas 12 m) | țintă 2 000–2 200 |
| rază minimă | **21,2 m** (la frac 0,710, acul 2 de la E) | prag AI ~14 m, ProbeLayout ≥ 9 |
| pantă maximă | **9,7%** (la frac 0,621, coborârea E) | prag 13% |
| separare minimă | **42,7 m** (frac 0,024 ↔ 0,994, închiderea buclei) | ≥ 2 × half_width = 14 m |
| centroid | **(−82, 12)** | — |
| Cebîșev | **305 m** | zidul lumii la 420 |
| cote | min **+0,6**, max **+25,8**, medie **+6,0** | — |
| sens | **ANTIORAR** | §2 (corectat în v0.3) |

**Acele de păr de la E** sunt scrise ca **două puncte cu fillet de 24 m**
fiecare (90° + 90°), nu ca un singur punct de 180° (memoria
`viraje-stranse-puncte-pe-arc`: Catmull-Rom strânge curba dacă virajul e un
singur punct). Raza de 24 m e **deliberat mai largă** decât cea de 16 m de pe
Transfăgărășan: acolo acele sunt subiectul pistei, aici sunt doar coborârea de
pe insulă, iar o rază generoasă ține AI-ul departe de pragul de ~14 m.

**Repere fixe pentru garda de azimut**, scrise **înaintea** traseului și
**nederivate** din el (memoria `garda-circulara-propria-functie`):

| reper | poziție |
|---|---|
| centrul satului plutitor | (−366, 280) |
| gura grotei | (−174, −253) |
| punctul de belvedere | (152, −224) |
| centrul plajei | (212, 112) |
| mijlocul podețului de plute | (38, 199) |
| centrul șirului de turnuri de fundal | **(430, −150)** |

**Garda de azimut, măsurată** (jumătate de cadru 50°, privind înainte pe
traseu):

| verificare | rezultat | distanță |
|---|---|---|
| turnurile de fundal, de pe belvedere | **7/10 cadre** | 238–291 m |
| turnul cu grota, de pe pontoane | **8/8 cadre** | 249–323 m |
| satul plutitor, de pe drumul de coastă | **8/8 cadre** | 82–157 m |

**Sabotajul pică, deci garda măsoară ceva:** mutând șirul de turnuri 400 m spre
vest, verificarea de pe belvedere trece de la 7/10 la **0/10** și garda iese cu
cod ≠ 0. Fără proba asta, o gardă care nu poate da greș nu verifică nimic.

> **Poziția turnurilor de fundal e derivată, nu aleasă.** La prima schiță le
> pusesem la SE, din intuiția „golful se deschide spre mare”. Măsurătoarea a
> arătat **0/7 cadre**: pe belvedere drumul merge spre **NE**, deci reperul
> trebuie să fie spre est. Exact tiparul din memoria
> `masoara-inainte-nu-langa` — camera privește în față, nu lateral.

## 3. Hazarduri și mecanici

Cererea a fost „poate să fie hazard nou sau și hazarde refolosite”. Răspunsul:
**unul nou (semnătura pistei), cinci refolosite**. Rosterul are deja **37 de
clase de hazard**, deci greul e refolosire; ce e nou e o clasă care **moștenește
modelul fizic existent al podului de frânghie**.

Acoperirea celor cinci clase din `ref_notes/sisteme.md` §3:

| clasă (Ignition) | aici |
|---|---|
| **teatru** | joncile cu vele roșii pe golf, ceața joasă care se mișcă între turnuri, plasele de pescuit, bărcile-coș, păsările de mare, reflexiile turnurilor pe apă, satul plutitor văzut de pe coastă |
| frecare | **nisipul plajei** (E), **lemnul ud al pontoanelor** (grip mai mic pe B), scoicile de pe banda de jos descoperită de maree (G) |
| **oprire** | **jonca** la canal (F), **mareea** care închide banda de jos (G) |
| sabotaj de control | **pontoanele care se leagănă** (B — semnătura), **maimuțele** (G) |
| **aruncare** | **buza digului** (C), acele de păr de la coborâre (E), pontonul care te ridică pe val când intră o mașină grea (B) |

| mecanică | pe scurt | ce cere în cod |
|---|---|---|
| **Drumul de pontoane** (B, 0,05 → 0,16) — **NOU, semnătura pistei** | trei tronsoane de carosabil **plutitor** prin satul plutitor, legate de insulițe de piatră fixă. Pontonul **se afundă sub masa mașinii** (autobuzul lasă tronsonul cu ~0,45 m, sportul cu ~0,18 m), **se leagănă lateral** când intri descentrat, și **tanghează** (se înclină pe direcția de mers) la accelerare și frânare — un ponton nu are capete fixe ca un pod. Peste asta, **valul de la joncile care trec** îl ridică ritmic. Două mașini pe același tronson se simt una pe alta: cea ușoară e ridicată de valul celei grele. Fără pereți: cazi în apă, RespawnZone te repune | **NOU, dar derivat** — clasă `PontoonRoadHazard`, **moștenind modelul fizic al lui `RopeBridgeHazard`** (`scenes/hazards/rope_bridge_hazard.gd`): arc+amortizor pe săgeată globală, balans lateral ca pendul amortizat, plăci `AnimatableBody3D` cu `sync_to_physics` **permanente** (memoria `corp-cinematic-aparut-in-masina`), `platform_velocity` pe fiecare placă (memoria `telecabina-platforma-mobila`), `road_hole_span()` pentru golul din carosabil, shader de deformare din **aceiași** parametri (memoria: `_drop` din GDScript și `deck_drop` din shader trebuie să fie aceeași formulă). **Ce e nou față de pod:** (1) **tangajul** — a treia ecuație, un al doilea pendul pe axa longitudinală; (2) **forțarea externă** din valul joncilor, un termen sinusoidal cu fază per tronson; (3) **capetele libere** — podul e fix la buze, pontonul nu, deci `P(u)` nu mai pleacă din 0 la capete, ci din săgeata de repaus. Punctul (3) e cel care cere grijă: **pragul de la insuliță la ponton nu are voie să treacă 0,3 m** (memoria `suprafete-cu-goluri-si-praguri`: peste atât e zid), deci insulițele fixe se pun exact unde amplitudinea e minimă, iar tronsoanele se ancorează la capete cu o limită moale |
| **Mareea pe banda de jos** (G, pe toată latura) — **refolosit + nou mic** | drumul de coastă are **două benzi la cote diferite**: banda de sus (+2, mereu uscată, mai lungă, cu parapet) și **banda de jos** (+0,4, mai scurtă și mai directă, pe terasa de abraziune de la baza peretelui). La maree joasă banda de jos e **scurtătura** pistei; la maree înaltă e **sub apă** și te oprește. Ciclul e lung (~75–90 s, un tur întreg), iar **telegraful e de pe belvedere** (D, ~0,40): de sus vezi dacă terasa e descoperită sau nu, cu ~30 s înainte să ajungi la ea. Decizia: *o iau sau nu?*, luată **înainte**, nu la intrare | **reuse** — scurtătura e `TrackBranch` cu `surface = SAND` sau `WET_STONE`, ca scurtăturile din Track09 / Track19. Apa care o acoperă e o suprafață locală de apă animată pe cotă, cu **ciclul de fază al lui `RainCycle`** (memoria `ceasul-porneste-in-prima-faza`: la `t = 0` ciclul trebuie să fie în **telegraf**, nu în „sus”, altfel verdictele ProbeRace ies cu banda închisă de la start). **Nou mic, dar pe o bază care există deja:** `water_hazard.gd` e scris **anume** ca bază comună pentru variante de apă pe șosea („o variantă nouă = un fișier care răspunde la cele trei”: `_wet_patch_size()`, `_build_source()`, `_advance(delta)`). `TideHazard` e exact asta: `_advance` e ciclul mareei, `_wet_patch_size` e banda de jos, iar `film_material` **refolosește materialul mării**, deci apa de maree **nu costă niciun material în plus** (garda numără materiale per pistă). Rămâne de decis la fundație doar cine comută `TrackBranch`-ul (§5.3) |
| **Jonca la canal** (F, ~0,61) | o joncă de pescari cu velă roșie traversează canalul **pe sub podețul de plute**, iar velă plus arboradă **mătură podețul**: nu te lovește barca, te lovește velă. Telegraful e barca însăși, vizibilă pe canal de la ~0,56. **Fereastra de sosire e un interval, nu un moment** (memoria `eta-cu-viteza-curenta-minte-pe-banda-cu-viraje`: pe o scurtătură cu viraje, sosirea e `[rapid, lent]`) | **reuse** — `SlidingHazard` în mod `TRAVERSARE` (`HazardMarker kind = SLIDING`, `motion = 1`, `face_travel = true`), ca vaca din Track09, caii din Track19 și ursul din Track21. Modelul e GLB nou (`fishing_junk`), mecanica e neatinsă. **De măsurat pe ax înainte de ProbeRace** (memoria `hazard-dezaliniat-contamineaza-verdictul`: autocarul din Fiordland mergea la 8 m în afara drumului) |
| **Maimuțele** (G, ~0,80) | un grup de macaci stă pe parapetul drumului de coastă și **sare în drum** în pulsuri, când treci. Sunt **ușoare**: mașina grea trece prin grup, cea ușoară e deviată. E principiul 1 (masa contează) pe un hazard mic | **reuse** — `HerdHazard` ca nod separat, cu `flow_dir` transversal și `road_dir` de-a lungul drumului, ca „RaulDeGnu” din `Track14.tscn` și oile din Track21. Reglaje de pornire: `animal_mass` ~12 (gnu 200, oaie ~45), `speed` ~4, `corridor_m` ~10. Modelele vin din exporturile `animal_model` / `alt_model` adăugate pentru oi |
| **Grota marină** (C, 0,22 → 0,27) | tunel de ~70 m prin baza unui turn, cu apă pe ambele părți ale carosabilului și **tavan jos (~11 m)**. Nu e hazard cu ceas: e **schimbare de atmosferă** (întuneric, ecou, picături) și un carosabil îngustat la 6 m | **reuse** — relief (`TerrainPeak`) + GLB-uri de portal, ca tunelurile din Track21. Cere `CameraZone` cu **tavan declarat explicit** (memoria `camera-zone-tavan-per-sala`) și `ProbeCameraSolid`. Picăturile sunt particule cu limită de count |
| **Nisipul plajei** (E, ~0,50) | fâșia de nisip din căldare e **lentă** (ca iarba, 45%), iar linia rapidă trece pe piatra de la marginea ei: alegere de linie, nu obstacol | **reuse** — suprafață lentă, tiparul iarbă/off-road existent |

**Ce NU e nou:** jonca, maimuțele, grota, nisipul, scurtătura. **Nou în cod:**
`PontoonRoadHazard` (derivat din modelul podului de frânghie) și comutarea
mareei. **Nou ca asset:** joncile, casele plutitoare, pontoanele, turnurile de
calcar, ficușii, macacul.

**Identitatea vine din loc + drum + hazarde legate de el:** un drum care
plutește într-un sat de pescari, o grotă prin care treci sub un munte, o
scurtătură pe care ți-o dă și ți-o ia marea.

**Distanțe între hazardele cu ceas** (lecția din `track08.gd:267`: „două
hazarde cu ceas lipite nu produc două decizii, produc o loterie”):

**Măsurate** pe schița din §2.1 (nu estimate):

| de la | la | distanță |
|---|---|---|
| pontoane (B, tronson 2, frac 0,154) | jonca (F, frac 0,811) | **1 332 m** |
| jonca (F, frac 0,811) | maimuțele (G, frac 0,935) | **252 m** |
| maimuțele (G, frac 0,935) | pontoane (B, peste start) | **444 m** |

Mareea (G) e **ciclu lung** peste toată latura, telegrafiat de pe belvedere,
deci nu intră în socoteala de 200 m: e stare, nu eveniment. Toate distanțele
sunt peste țintă — **spre deosebire de Transfăgărășan, aici nu există nicio
abatere asumată**, fiindcă hazardele cu ceas sunt doar trei.

Respiro-ul e **C → E** (digul, grota, urcarea, belvederea, coborârea): condus
pur, fără ceas, cu dezvăluirea golfului la mijloc.

### 3.1 Decizii de luat (deschise, pentru dezvoltator)

Nu le iau singur, fiindcă schimbă scopul. Propunerea mea e prima la fiecare.

1. **Numele de afișare.** Propunere: **„Ha Long”** (fără diacritice, ca
   „Transfagarasan”). Alternativa „Halong” e mai puțin corectă.
2. **Tangajul pontonului: da sau nu?** Propunere: **da**, fiindcă e exact
   ce face un ponton și nu-l face un pod (§3). Dacă la implementare a treia
   ecuație se dovedește instabilă cu mașina grea, **se taie tangajul și
   rămân afundarea + balansul**, adică exact podul de frânghie cu capete
   libere. Pontonul rămâne o mecanică nouă și fără el.
3. **Mareea: cine comută scurtătura?** Partea de apă e lămurită (§3:
   `TideHazard` ca variantă de `WaterHazard`, care e scris exact pentru asta).
   **ÎNCHIS (14 oct 2026), pe cod citit: hazardul închide banda.** Propusesem
   „apa taie grip-ul, banda rămâne deschisă”, ca variantă mai ieftină. Dar
   `Track.branch_is_open` + `BRANCH_GATE_GROUP` **există deja** și cer două
   metode (`branch_index` + `shortcut_open()`), cu precedent dublu — lava de pe
   Stromboli și vaca de la Jodhpur. Deci închiderea nu e mai scumpă, și e mai
   onestă: la 1,5 m de apă peste terasă, o bandă „deschisă cu grip tăiat” ar fi
   o capcană, nu o decizie. Bonus neprevăzut: `shortcut_open()` e întrebat
   **per tur** în `AIController`, deci un AI care a decis „o iau pe scurtă” la
   turul 1 nu intră în apă la turul 3.

   **Compromisul păstrat:** banda se închide **doar** la apă plină. Fazele de
   urcare și de retragere o lasă deschisă **cu apă pe ea** — acolo stă riscul
   asumat, măsurat la **22,8 s per ciclu** de fereastră în care poți încerca.

   **DAR banda de jos nu e pusă pe pistă** (§7.3): măsurătoarea arată că pe
   traseul actual nu există nicio coardă care să scurteze la nivelul mării.
   Poarta de bandă rămâne implementată și testată, nefolosită până se ia una
   dintre cele trei opțiuni din §7.3. Decizia asta e **deschisă din nou**, la
   alt nivel: nu „cine comută banda”, ci **unde poate exista banda**.
4. **Grota: una lungă (70 m) sau două scurte?** Propunere: **una lungă**, ca
   să fie eveniment, nu detaliu. Depinde de ce arată `ProbeCameraSolid` pe
   tavanul de 11 m.
5. **Apa: tema `halong` pornește din `okinawa` (mare) sau `fiordland`?**
   Propunere: **`okinawa`**, fiindcă are deja apă de mare cu adâncimi, dar
   **cu paleta reîntoarsă spre verde-jad opac** — și asta e tocmai riscul:
   Okinawa e turcoaz transparent. Se măsoară HSV după remap, în joc (memoria
   `monocromia-se-masoara-dupa-remap`), nu pe `.glb` brut.
6. **Vaporul mare de croazieră: chiar deloc?** Propunere: **deloc** (§0.1),
   dar e o decizie de gust pe care o poate răsturna dezvoltatorul.

## 4. Paleta și lumina (fără slot nou)

**Nu există slot liber** — verificat, nu moștenit: `scripts/palette.gd:30`
declară `SLOTS = 32`, iar indicii 0–31 sunt toți alocați (`docs/style_bible.md:48`
e învechit și încă listează 24–31 ca rezervă). Ha Long se face din
**sloturi existente + clase noi pe dale existente** (memoriile
`slot-reutilizat-intre-piste`, `tenta-pe-clasa-partajata`): **fără** retentarea
claselor partajate, iar tenta doar **întunecă** (memoria
`surfacetool-clamp-vertex-color`), deci luminosul cere `CLASS_LIFT`. Se măsoară
**după remap, în joc**.

| rol | slot existent / clasă |
|---|---|
| calcarul turnurilor (fața însorită) | `ROCK_LIGHT` 3 + clasă nouă **`karst_limestone`** pe dala calcarului Ryukyu (Okinawa, Track20) — **aceeași dală, altă tentă**, fiindcă e aceeași rocă; de comparat cu `coral_rock` ca să nu iasă „Okinawa” |
| dungile de scurgere, surplomba udă de la bază | `ROCK_DARK` 4 — **în suprafețe mici** (memoria `rock-dark-nu-pe-bazalt`: pe suprafețe mari iese ruginiu; umbra o face AO-ul) |
| apa adâncă (verde-jad) | `SEA_DEEP` 18 cu tenta apei pe temă, **desaturată spre verde**; apa de aici e **opacă**, deci Fresnel-ul se reglează din chase cam (memoria `apa-iluminata-v12`) |
| apa de la mal, în umbra turnurilor | `SEA_SHALLOW` + `water_shore_slot` pe temă |
| spuma, siajul, valul de la jonci | `FOAM_WHITE` 22 |
| ficușii, bambusul, mangrovele | `TROPICAL_GREEN` 21 (ficus), `DRY_VEGETATION` 13 (bambus), `LOG_DARK` 28 + clasă `mangrove` |
| lemnul pontoanelor, al caselor, al joncilor | `WOOD_WEATHERED` 9 |
| velele joncilor | `KERB_RED` 7 sau `LARCH_RUST` 27 — **de măsurat**: velă roșie-cărămizie, nu roșu de kerb |
| butoaiele albastre de flotor | `PAINTED_METAL` 11 cu tentă albastră — accentul pistei, **în pete mici** |
| tabla ondulată a caselor | `RUST_METAL` 10, `PAINTED_METAL` 11 |
| plasele de pescuit, năvoadele | `DRY_VEGETATION` 13 (linii subțiri; **`prop_contact_skip`**, ca `rope_rail` din Machu Picchu: liniile subțiri n-au disc de contact) |
| nisipul plajei | `SAND_LIGHT` 0 |
| betonul drumului de coastă, parapetul | `CONCRETE` 8 |
| macacii | `LARCH_RUST` 27 / `ROCK_DARK` 4 — **de măsurat** (memoria de la urs: să nu iasă „vacă maro”) |

**Lumina:**
- **soarele:** ~30° din **ESE** (~110°), `#FFF0D8`, energie ~1,1. `exposure`
  **se măsoară**;
- **ambientul:** cer de dimineață, ~`#C8D8DC` la 0,32. Umbrele din grotă și de
  sub surplombe trebuie să iasă **verzi-albastre de la lumina reflectată de
  apă**, nu negre (memoria `umbra-fara-culoare-e-negru-mort`);
- **cerul:** albastru-pal spălăcit sus (`#6E9AC4`), alb-cald lăptos la orizont
  — aer umed de golf, **nu** albastrul adânc de altitudine de pe Alpi /
  Transfăgărășan;
- **ceața:** aici e **mecanică de compoziție, nu doar atmosferă**. Ceața
  globală 120 → 340 m (legată de `FAR_PLANE`), măsurată HSV față de **apă**,
  nu față de `ground_tint` (memoria `ceata-in-familia-solului`, adaptată: pe
  o pistă jumătate-apă, familia solului e apa). Peste ea, **ceața joasă în
  strat** între turnuri, care e **cea care dă adâncimea** de pe belvedere
  (memoria `scara-de-adancime-are-gol`). Tiparul de pornire e `FogCorridorHazard`
  / `horizon_model`, de ales la fundație;
- **umbrele:** pornite (`theme_shadows`), `shadow_distance` **90, de verificat
  că acoperă casterii** (memoria `umbre-exista-dar-cascada-e-scurta`):
  turnurile de calcar apropiate sunt caster mari, iar **umbra de turn pe apă e
  identitatea luminii** (§1), deci dacă nu încape în cascadă, se pierde fix
  reperul;
- **turnurile de fundal:** `cast_shadow` **OFF** (memoria
  `caster-departat-fura-umbra`: siluete scalate 25–60× sting direcționala).

**Azimutul soarelui față de drum** (se remăsoară la fiecare redesenare,
memoria `azimutul-soarelui-fata-de-drum`):

| porțiune | direcție | soarele | ce dă |
|---|---|---|---|
| A–B | spre S | din stânga-față | casele plutitoare luminate lateral, **umbrele lor lungi pe apă**: primul cadru arată locul |
| C | spre S / grota | din stânga, apoi nimic | gura grotei e **contralumină** (silueta turnului), interiorul e întuneric cu reflexie verde de pe apă |
| D urcarea | spre E | **din față** | ficușii în contralumină pe peretele de calcar, rădăcinile se citesc ca siluetă |
| D belvederea | spre SE | din față-dreapta | **turnurile în contralumină, ceața aprinsă între ele**: dezvăluirea |
| E coborârea | spre V | din spate | plaja și căldarea luminate din față, nisipul se citește |
| F canalul | spre N | din dreapta | **velă roșie a joncii aprinsă lateral**, se vede de departe |
| G coasta | spre N | din dreapta | peretele de calcar din dreapta aprins, **banda de jos în umbra lui** — exact unde trebuie să citești dacă e udă |

## 5. Assets

Categoria nouă `assets/models/halong/`, cu subfolderele `structures/`,
`buildings/`, `rocks/`, `plants/`, `props/`, `animals/`, `vehicles/`,
`effects/` (memoria `assets-models-categorii`).

### 5.1 Auditul kiturilor marine existente (ce refolosim)

De făcut la fundație, pe kiturile **Okinawa** (Track20: calcar Ryukyu, mare,
bărci) și **Fiordland** (Track16: apă, pereți, vegetație udă). Ținta de scară
vine din cameră (memoria `inaltimea-obiectelor-si-camera`): un obiect de la
marginea drumului care trebuie **citit** cere ≥ 3–4 m; un reper văzut de
departe, ≥ 15 m.

Candidați probabili de refolosit: stâncile de calcar Okinawa (pe clasa nouă
`karst_limestone`), bărcile mici, debarcaderele, plantele tropicale, pietrele
de mal, parapetele de beton. **Verdictul se scrie piesă cu piesă**, ca la
Transfăgărășan §5.1 — nu aici, fiindcă cere citit antetele din
`tools/blender/build_okinawa_*.py` și `build_fiordland_*.py`.

### 5.2 Piese noi (schiță)

**Hero:**
- `karst_tower` A/B/C: turnuri de calcar, 40–70 m în joc (nu 200), cu
  **surplomba erodată la bază** — forma care spune „Ha Long”; modulare, ca să
  compună șiruri;
- `grotto_portal`: gura grotei, calcar brut cu stalactite scurte;
- `floating_house` A/B: casă pe plute, cu tablă ondulată și terasă de plase;
- `fish_farm`: pătratul de plute cu plase, modular;
- `fishing_junk`: jonca cu velă roșie (hazardul de la canal), ~12 m;
- `pontoon_module`: modulul de ponton (bambus + butoaie albastre), din care se
  compune drumul plutitor — **cotele se iau din `PontoonRoadHazard`**, nu
  invers (memoria `brief-cere-glb-cod-il-face-deja`);
- **`macaque`**, pentru MultiMesh-ul grupului de maimuțe (statică, ca gnu-ul
  și zebra din Serengeti — memoria `serengeti-assets-kit`).

**Kit:**
- apă și sat: `basket_boat` (barca-coș rotundă), `fishing_net_rack`,
  `buoy_cluster`, `bamboo_walkway`, `stone_quay`;
- stâncă: `karst_stack` (turnuri mici, 8–15 m), `shore_boulder`,
  `abrasion_terrace` (terasa de la baza peretelui, pentru banda de jos);
- plante: `karst_ficus` A/B (cu rădăcini aeriene pe perete), `bamboo_clump`,
  `mangrove_low`;
- drum: `coast_parapet`, `raft_bridge` (podețul de plute), `stone_dike`.

**Fundal:** `karst_horizon` A/B/C — **trei planuri de adâncime** de șiruri de
turnuri (150 m, 230 m, 320 m), cu `cast_shadow` OFF. Astea sunt ce face
belvederea să funcționeze, împreună cu ceața în strat.

### 5.3 Trecerea de contracte — **de făcut înainte de primul build**

Memoria `brief-cere-glb-cod-il-face-deja`: înainte de comanda de kit se
verifică ce face deja codul. **Trecerea e făcută (14 oct 2026), pe cod citit
integral.** Verdictul pe scurt: **pontonul e o subclasă mică, mareea e o
variantă mică, și niciuna nu cere clasă de la zero.**

**1. `RopeBridgeHazard` — cât de departe duce pontonul? VERIFICAT ✔, duce
aproape tot.** Clasa e deja parametrizată pe exporturi (`rest_sag`, `sag_bus`,
`sag_sport`, `dip_ratio`, `dip_sigma`, `wave_gain`, `sag_freq`, `sag_damping`,
`sway_gain`, `deck_mass`, `sway_freq`, `sway_damping`, `sway_max`, `roll_arm`,
`plate_count`, `plate_overlap`), iar structura e exact cea de care are nevoie
pontonul:

| de ce are nevoie pontonul | ce există deja |
|---|---|
| afundare pe masă | `_calibrate()` + `amplitude_for(m)`: legea `a(m) = gain·m^exp`, calibrată din două puncte **în metri**, nu în coeficienți |
| balans lateral | `_integrate()`: pendul amortizat spre `_sway_target`, cu limită moale peste `sway_max` |
| „mașina ușoară ridicată de cea grea” | `wave_gain` — **deja măsurat** că sub 1.0 valul nu mai ridică mașina deloc |
| plăci de coliziune | `_build_plates()`: `AnimatableBody3D` + `sync_to_physics`, **permanente**, cu `platform_velocity` scris pe tick |
| o singură scriere de transform | `_place_plates()`: `body.global_transform = xf`, exact o dată |
| golul din carosabil | `road_hole_span()` |
| plasa de repunere coborâtă | `net_ceiling_drop()` |
| stare pentru sonde | `sag_amplitude()`, `sway()`, `sag_at(u)`, `drop_at(u)`, `deck_coords()`, `deck_point_global()`, `plates()`, `cars_on_deck()`, `settle_now()` |

**Ce trebuie schimbat, exact trei locuri** (și toate trei sunt mici):

- **capetele libere.** `_p(u) = 4u(1-u)` e **zero la ambele capete** — chiar
  definiția podului fix. Pontonul cere o formă de mod care nu moare la capete
  (de exemplu `p_pontoon(u) = a + b·4u(1-u)`, cu `a > 0`). Se schimbă în
  `_p()`, **și** în `e := smoothstep(0.0, 0.1, min(u, 1-u))` din `_drop()`,
  care stinge anume afundarea locală la capete;
- **tangajul.** A treia ecuație, pe același tipar ca `_sway` în `_integrate()`
  (cinci linii) plus un termen în `_plate_basis()`;
- **forțarea externă** din valul joncilor: un termen sinusoidal adăugat la
  `_sag_target` în `_gather_loads()` (o linie).

**Capcana de închis, găsită la citire — contaminarea Track15.** `snapshot.gd`
(liniile 1748, 1763) și `probe_machu_pod.gd` caută podul cu
`find_children("*", "RopeBridgeHazard", true, false)`. În Godot, **o subclasă
se potrivește la numele clasei de bază**, deci dacă `PontoonRoadHazard extends
RopeBridgeHazard`, uneltele de pe Machu Picchu vor „găsi” pontoanele de pe Ha
Long, iar `--rope-load` va așeza mașina pe un ponton crezând că e podul. Două
ieșiri, de decis la implementare: fie pontonul **nu** extinde clasa, ci se
extrage un strat comun (`SuspendedDeck`) din care moștenesc amândouă, fie
căutările din unelte se strâng pe tip exact. **Prima e mai curată**, a doua e
mai ieftină; oricum se alege, uneltele Machu Picchu rulează după schimbare, ca
să se vadă că podul n-a mișcat.

**Al doilea contract de respectat:** `_drop()` din GDScript și `deck_drop()`
din `assets/shaders/rope_bridge.gdshader` sunt **aceeași formulă scrisă de
două ori** (antetul shaderului o spune explicit: „dacă schimbi formula aici,
schimb-o și acolo, altfel mașina merge pe o suprafață pe care n-o vezi”).
Pontonul are nevoie de shaderul lui, cu **aceleași** trei schimbări — deci
sonda `probe_ponton` compară cota plăcii cu cota vizuală, nu doar cotele între
ele.

**2. mareea: VERIFICAT ✔** — `water_hazard.gd` e scris anume ca bază comună
pentru variante de apă pe șosea („o variantă nouă = un fișier care răspunde la
cele trei”: `_wet_patch_size()`, `_build_source()`, `_advance(delta)`), iar
`film_material` **refolosește materialul mării**, deci apa de maree nu costă
niciun material în plus. Petecul ud e **copil** al hazardului, deci dacă sursa
se mișcă, apa merge cu ea fără nicio linie în plus. Rămas de decis doar cine
comută banda (§3.1.3).

**3. apa de mare cu adâncimi** o face deja tema (`water_shallow_slot`,
`water_deep_slot`, `water_shore_slot`, `water_tint`) — din kit **nu** vine
nicio suprafață de apă.

**4. `CameraZone`** pentru grotă: tavan declarat explicit, nu implicitul de
15 m.

**5. `road_hole_span()`** taie carosabilul pentru ponton și pentru podețul de
plute, exact ca pentru podul de frânghie — deci nodurile se pun **pe punctele
copte**, iar capetele pe `±k` pași (tiparul Track15: nodul pe baked[619],
capetele pe baked[609] și baked[629], 34,24 m). Pe Ha Long sunt **trei**
tronsoane de ponton, deci trei noduri și trei găuri, fiecare cu insulițele
fixe la capete.

**6. `prop_contact_skip`** pentru plase, năvoade și balustrade de bambus:
liniile subțiri n-au disc de contact (tiparul `rope_rail` din Machu Picchu).

**Consecința pentru plan:** pasul 3 (fundația) nu mai e blocat de o clasă
nescrisă. `PontoonRoadHazard` se poate construi **după** fundație, cu cotele
luate din el, nu înaintea ei — iar fundația poate porni cu tronsoanele ca
carosabil fix, ca să se măsoare traseul și plasa lumii întâi (§7 pasul 4).

## 6. Bugete

| buget | țintă | cum se măsoară |
|---|---|---|
| materiale | **≤ 30** (garda pică la 38) | `probe_decor --track=22` |
| triunghiuri | raportate, fără plafon (CLAUDE.md) | `probe_decor` |
| timp de încărcare | ≤ Track21 + 0,5 s, **cu fereastră** | `probe_load_time` (memoria `headless-ascunde-citirea-de-pe-gpu`) |
| vegetația în masă | ficușii, bambusul, mangrovele pe **MultiMesh** peste ~1 000 de piese | memoria `decor-in-masa-cere-multimesh` |
| particule | picăturile din grotă, spray-ul de la pontoane, siajul joncilor, cu limită de count | `probe_fx` |
| **ProbeRace, la început** | 8 mașini, 16 seed-uri: **0 ieșiri din lume**, `[blocaj]` = 0 pe pontoane / în grotă / pe acele de păr, repuneri doar în apă de pe pontoane | memoriile `proberace-la-inceput-nu-la-final`, `zero-repuneri-ascunde-blocajul` (se citesc `[blocaj]`/lent/invers/carusel, nu doar ținta) |
| **plasa lumii și zidul** | plasa la cota medie − 7, pe o pistă jumătate-apă: **de verificat înaintea traseului** | memoria `ziduri-invizibile-ale-lumii` (§2) |

## 7. Ordinea de construcție

1. **Brief v0.1** (acest document). PR propriu.
2. **Trecerea de contracte ✔ FĂCUT** (§5.3, 14 oct 2026): `rope_bridge_hazard.gd`
   și `rope_bridge.gdshader` citite integral, `water_hazard.gd` verificat.
   Verdict: pontonul e subclasă mică (trei schimbări identificate), mareea e
   variantă mică. O capcană găsită și scrisă: `find_children("*",
   "RopeBridgeHazard")` din `snapshot.gd` / `probe_machu_pod.gd` ar prinde și
   pontoanele, deci ori se extrage un strat comun, ori se strâng căutările.
   **Rămas de făcut din pasul ăsta:** auditul kiturilor Okinawa / Fiordland
   (§5.1), care nu blochează fundația.
3. **Fundația `Track22.tscn` ✔ FĂCUT** (14 oct 2026),
   `tools/gen_halong_route.py` + `tools/ProbeHalongLoad.tscn`. Vezi §7.1 pentru
   ce a găsit. Ce e în scenă:
   - gărzile de **formă**, **apă**, **azimut**, **departare** și **hazarde cu
     ceas**, toate scrise **înaintea** traseului, pe reperele fixe din §2.1,
     plus `--sabotaj`, **care pică** (cod 1);
   - tema **`halong`** în `Track.themes()`, pornind din **copia** lui `okinawa`
     (singura temă cu mare cu adâncimi), fără să o editeze — Track20 rămâne
     bit-identică. Cheia în enum-ul din `track_from_path.gd` și
     `info/Track22.tres` (regiunea „ASIA”, accent verde-jad);
   - `custom_name` („Ha Long”) și `custom_world_seed_name` („halong22”)
     **înghețate** de la prima generare;
   - `custom_sea_level_offset = -5,99`, **nu** implicitul −7 (§2);
   - pe traseu: `custom_width_segments` (grota, podețul și cele trei tronsoane
     de ponton la 6 m), cinci `TerrainPeak` (insula + patru turnuri de calcar
     ca flanc), cinci râpe cu apă de golf, `HazardMarker` SLIDING pentru joncă
     și `HerdHazard` pentru maimuțe. Turnuri și pontoane **provizorii** din
     kitul Okinawa în `DecorManual` (41 de noduri), ca să se vadă scara;
   - `GameState`: Track22 la coada listei (**indexul 15**). Uneltele o
     adresează cu `--track=22`; atenție la cele două convenții —
     `probe_decor`/`probe_manual` vor **22**, `snapshot`/`probe_race`/
     `probe_layout` vor **15 SAU 22** (memoria `probe-decor-numar-de-scena`,
     care a costat 528 de piese plutind).

   **Ce NU e încă în scenă, deliberat:** `PontoonRoadHazard` (clasa nu există
   — §5.3), `TideHazard` și `TrackBranch`-ul benzii de jos, `CameraZone` pe
   grotă. Fundația pornește cu pontoanele ca **carosabil fix**, ca să se
   măsoare traseul, apa și repunerile înainte să existe un tablier care se
   leagănă. Fracțiile tronsoanelor sunt deja tipărite de generator, pentru
   `road_hole_span()`.
4. **ProbeRace la început ✔ FĂCUT** (§6, §7.1), pe traseul gol, înaintea
   oricărui decor — fiindcă apa pe o pistă jumătate-apă e riscul numărul unu
   (§2). A găsit un defect real și l-a închis.
5. **Gărzi:** `ProbeLayout --track=22`, `ProbeBuried`, `ProbeLaneClear` cu
   **linie de bază proprie, fără marjă** (memoria
   `garda-fara-linie-de-baza-iese-zero`: fără ea pare verde dar nu e armată) +
   `--sabotaj` care pică, `ProbeCameraSolid` pe grotă și pe portaluri. Nou:
   `probe_ponton` (afundare pe masă: autobuz ~0,45 m, sport ~0,18 m; prag la
   insulițe **< 0,3 m**; nicio placă care sare sub mașină) și `probe_maree`
   (banda de jos deschisă/închisă pe ciclu, și **faza la `t = 0` e telegraf**).
6. **Verdictul dezvoltatorului la volan** pe fundație: se simte pontonul că
   plutește, sau doar că e moale? Mareea e decizie, sau taxă? Belvederea arată
   golful, sau o ceață plată? Grota e eveniment?
7. **Planul real adnotat**: captura `Snapshot.tscn -- --track=22 --no-fog`,
   **cu fereastră** (memoria `snapshot-nu-merge-headless`), adnotată cu
   `tools/annotate_halong_plan.py` → prompt de dioramă → planșă de inventar →
   kit Blender → integrare → POI A–G (gauntlet, **valuri de 3**, memoria
   `valuri-de-trei-nu-opt-agenti`).

### 7.1 Ce a găsit pasul 3 (14 oct 2026)

Patru defecte, fiecare prins de o altă gardă. Niciunul n-ar fi fost găsit de
cel care l-a prins pe celălalt — de aceea sunt patru gărzi, nu una.

**1. `decor: false` oprea construcția pistei.** `TrackDecor.build` primește
modul ca `String` (al doilea argument), iar un bool arunca „Cannot convert
argument 2 from bool to String” și scena nu se mai construia. Celelalte teme
care sting decorul statistic folosesc **string gol**. Prins de
`ProbeHalongLoad` la prima rulare; nicio gardă geometrică nu l-ar fi văzut,
fiindcă traseul era corect.

**2. Patru râpe cereau apă pe care nu o puteau primi.** Prima versiune declara
`custom_ravine_water` pe **toate cinci** râpele, la aceeași cotă (0,0).
`_build_ravine_water` umple prin inundare de la buză în jos și ține minte
celulele ude în `_ravine_wet`, deci a doua râpă cu aceeași cotă **nu mai
găsește nicio celulă liberă**: patru `push_warning` („rapa N n-are nicio celula
sub 0.0”) și patru zone de repunere eliberate degeaba. Pe Ha Long apa e **un
singur golf**, deci se declară **o singură dată**. Cazul e simetric cu
Transfăgărășanul, unde cele patru râpe cu apă au **cote diferite** (Vidraru
+7,5, hăul −24, Oltul +3,4 și −2,5) și de aceea funcționează acolo.

**3. `sea_level_offset` în temă e citit de nimeni.** L-am pus prima dată ca
cheie de temă, iar sonda a raportat marea la **−0,99**, adică implicitul −7, nu
valoarea scrisă. Cauza: `sea_level_offset` e `@export` pe `Track`, iar
`TrackFromPath._ready` îl scrie din **`custom_sea_level_offset`**, *după* ce
tema s-a aplicat. Deci cota mării se pune **pe scenă**, nu pe temă. Sonda
`ProbeHalongLoad` verifică acum perechea (media cotelor × offset = marea la
0,00 ± 0,20), deci dacă cineva mută o cotă și uită offsetul, iese imediat.

**4. Repunerile de la frac 0,80 sunt JONCA, și nu sunt un defect — e un
hazard nereglat.** ProbeRace dă **2–8 repuneri pe fiecare seed**, toate la frac
0,80, toate în **același punct** `(61, 3, −196)`. Reproductibil, deci nu zgomot.

Cauza, după trei ipoteze greșite: la `Motion.TRAVERSARE`, `Track` îi dă joncii
`travel = side · half_width · 0,9` — pleacă de pe acostament și **traversează
carosabilul**, parcându-se dincolo. Jonca e, **prin design**, un obstacol solid
pe drum. `SlidingHazard` *extends* `AnimatableBody3D`, deci corpul chiar e
fizic. Repunerile sunt mașini care se izbesc de un hazard care **funcționează**.

**Ce a dovedit măsurătoarea A/B** (patru seed-uri, 260 s, același traseu):

| starea scenei | repuneri (seed 1/2/3/4) |
|---|---|
| canal lat pe tot podețul, joncă fără model | 2 / 5 / 5 / 2 |
| canal îngustat (ipoteza 1: cad lateral în apă) | 2 / 5 / — / — |
| canal îngustat + podeț lărgit la 7 m (ipoteza 2: nu încap) | 2 / 1 / 3 / 7 |
| podeț repus la 6 m + **joncă CU model** (ipoteza 3: zid invizibil) | **6 / 8 / 6 / 7** |

Primele două ipoteze au ieșit cu cifra **neschimbată**. A treia a făcut-o
**mai mare**, și asta a fost dovada decisivă: fără model `SlidingHazard` își
construiește `_build_placeholder_box()` de 4,5 × 2,2 × 2,6 m, iar
`fishing_boat.glb` are **9 m lungime** — obstacol mai lat pe un drum de 6–7 m,
deci mai multe coliziuni. Nu era un zid invizibil; era un obstacol real, pe
care l-am făcut mai mare.

**Deci nu e nimic de reparat în geometrie** — ce era de reglat e **hazardul**.

### Reglajul joncii, din două măsurători (14 oct 2026)

**1. Gabaritul**, măsurat cu `ProbeHlPoint` pe scena construită: corpul joncii
e **4,12 × 5,35 × 9,32 m**, iar carosabilul podețului măsoară **11,5 m**. La
`model_scale = 1,0` rămâneau **2,18 m** de bandă liberă când barca e pe axă —
mai puțin decât lățimea unei mașini (2,6 m). Traversarea nu era o decizie, era
un zid.

Scara iese din ținta de bandă liberă, nu din gust:
`model_scale = (11,5 − 5,0) / 9,32 = `**`0,697`**, pentru o bandă de **5,0 m**
(o mașină trece confortabil, dar trebuie să vrea).

**2. Viteza: implicitul clasei (12,0), nu 2,2.** Antetul lui `SlidingHazard`
are măsurătoarea, și e contraintuitivă: *„încetinirea măturării «ca să fie mai
citibil» ÎNRĂUTĂȚEȘTE lucrurile. Cu perioada dublă, obstacolul devine un blocaj
semi-static și toată lumea intră în el (cadre de contact per mașină: ~10 la
perioada originală, ~110 la dublu). Un obstacol rapid traversează și eliberează
drumul; unul lent stă în el.”*

Pusesem **2,2** din reflexul „o barcă e lentă” — exact greșeala pe care clasa o
avertizează în antet. Lamele de pe Track15 merg la 2,0 fiindcă *sunt* animale
lente și au `model_scale` 3,135 pe un GLB mic; o joncă de 9 m nu e o lamă.

**Gardă nouă în generator**, ca cifrele să nu poată fi schimbate fără
consecințe — contractul gimmickului scris ca cifră (memoria
`garda-cu-numele-gimmickului`):
- banda liberă **≥ 1,6 × lățimea mașinii** (4,16 m), altfel nu e decizie;
- banda liberă **≤ 60% din carosabil** (6,90 m), altfel jonca nu mai e obstacol;
- `sweep_speed` **≥ 8,0**, cu măsurătoarea din antetul clasei citată în mesaj.

**Verdictul, măsurat pe patru seed-uri** (ProbeRace, 8 mașini, 260 s):

| starea joncii | repuneri (seed 1/2/3/4) | tur mediu |
|---|---|---|
| fără model (box 4,5 m), `sweep` 2,2 | 2 / 5 / 5 / 2 | 69,0 s |
| model 9,32 m, `sweep` 2,2 | 6 / 8 / 6 / 7 | 70,8–71,8 s |
| **model 6,49 m (scale 0,697), `sweep` 12,0** | **1 / 3 / 2 / 1** | **68,6–70,1 s** |

**−75% repuneri**, iar turul mediu a *scăzut* — semn direct că mașinile nu mai
stau blocate în obstacol, ci îl trec. Toate cele 7 repuneri rămase sunt pe
joncă (frac 0,80), **0% offroad** și **zero blocaje** pe toate seed-urile.

Asta e comportamentul corect, nu un rest de defect: jonca **trebuie** să fie un
obstacol. Una până la trei atingeri per cursă de 260 s cu 8 mașini înseamnă că
cine n-o citește plătește, iar cine o citește trece prin banda de 5 m — exact
contractul din §3 („decizie, nu taxă”).

**Rămas de reglat, dacă verdictul la volan o cere:** `phase` (fereastra de
telegrafare — acum e cea derivată din fracție) și eventual `travel`. Nu le
ating fără un motiv măsurat: cifrele de mai sus sunt deja în contract.

**Confirmarea finală, cu sonda de punct** (`ProbeHlPoint` pe (61, −196)):
corpul mobil al joncii stă la **(37,8; 1,40; −187,4)**, adică la ~11 m pe cursa
de traversare din nodul declarat la (40,75; −198,58) — chiar prin punctul de
repunere. Drumul e la cota 1,40 pe toată lățimea pe axa x, deci **nu există
nicio gaură**: ipotezele 1 și 2 n-aveau pe ce să se sprijine.

Sonda a scos și **buza laterală a podețului**, măsurată: pe axa z, la ±8 m de
ax, terenul coboară la **0,27–1,10** față de drumul la 1,40 — o treaptă de
**0,30–1,13 m**, peste limita de 0,3 m de la care un prag e zid (memoria
`suprafete-cu-goluri-si-praguri`). Cifra e **dincolo de marginea carosabilului**
(podețul are semi-6, deci marginea e la 6 m), așa că nu e un prag *pe* drum și
nu explică repunerile — dar e o buză de care te agăți dacă ieși lateral.

**Verdict: se lasă așa, deliberat.** Podețul de plute *trebuie* să aibă o
margine: e o punte peste un canal, nu un drum cu acostament. După reglajul
joncii (banda liberă de 5 m, §mai jos) mașina împinsă are pe unde să treacă
fără să ajungă la buză. Se redeschide doar dacă ProbeRace arată repuneri
**laterale** acolo, nu frontale pe joncă.

**Lecția de metodă, mai valoroasă decât defectul.** Trei ipoteze, trei
măsurători, zero ghiceli validate:
- când repunerile cad mereu în **același punct**, defectul nu e de formă —
  **măsoară ce e acolo** (raycast + inventar de corpuri fizice), nu ajusta ce
  crezi că e de vină;
- o „reparație” care **nu schimbă cifra** nu e o reparație. Dacă o păstrezi
  oricum, e o modificare de design strecurată sub numele unui fix. De aceea
  lățimea podețului **s-a repus la 6 m** (intenția din brief), iar îngustarea
  râpei a rămas doar pentru că are motiv de design propriu;
- o reparație care **înrăutățește** cifra e cel mai informativ rezultat: aici a
  arătat că obstacolul era real și că mărimea lui e variabila care contează;
- **o sondă nerulată arată identic cu una care nu găsește nimic.** Prima
  versiune a lui `ProbeHlPoint` a fost scrisă, comisă *și citată ca dovadă*
  fără să compileze: `var p := center + axis * off`, cu `axis` venind dintr-un
  array literal netipizat, dă „Cannot infer the type of p” și scriptul nu se
  încarcă. Ieșirea era goală, și am pus-o pe seama unui timeout. Două apărări,
  amândouă în unealtă acum: **buclele sunt tipizate** (`for axis: Vector3 in
  axes`), și sonda **iese cu cod 1 dacă n-a măsurat nimic**, în loc să tacă
  (memoria `garda-verde-pe-zero-masuratori`). Regula generală: rulează sonda
  *înainte* de a o cita, și pune-i o linie care pică pe zero măsurători;
- **o lățime de drum măsurată pe axele lumii e greșită**, și a doua versiune a
  aceleiași sonde a dat **48 m** pe un drum de 11,5: pe o axă aliniată cu sensul
  de mers, `RoadTop` continuă pe sute de metri. Lățimea se măsoară
  **perpendicular pe ax** — practic, baleind unghiul și luând **minimul**, care
  e normala la drum. Tiparul e cel din memoria `masoara-inainte-nu-langa`, pe
  altă axă: nu presupune că axele lumii sunt axele drumului. A treia cifră
  (11,5 m pe un podeț declarat la semi-6) a fost prima credibilă.

**Cifrele fundației** (ProbeRace, 8 mașini, 260 s, patru seed-uri): tur minim
**59,5–59,9 s**, mediu **70,0–71,8 s** — în fereastra Ignition 65–80 s ✔ —,
**0% offroad** și **zero ieșiri din lume** pe toate seed-urile. Viteza medie e
**28–31 m/s** uniform pe tot turul, cu o singură felie mai lentă la
**0,95–1,00** (22 m/s, 23,9% „lent”): e intrarea în cheiul de start, unde
drumul se strânge. De urmărit la volan, nu neapărat un defect.

Repunerile (6–8 per seed) sunt **toate** pe joncă, la frac 0,80, și sunt
chestiune de **reglaj de hazard**, nu de traseu — vezi defectul 4. Verdictul
„se conduce cap-coadă” se dă după reglajul ei, nu acum.

Variația între seed-uri (de exemplu 2/1/3/7 pe o stare intermediară) e
nedeterminismul lui Jolt (memoria `proberace-nedeterminism`: se compară
**distribuții**, nu o rulare) — de aceea fiecare ipoteză s-a măsurat pe toate
cele patru seed-uri, nu pe unul.

**Ce rămâne de confirmat la pasul 4–5:** marja plasei de mare (0,85 m sub
pontonul complet afundat) se verifică abia când pontonul **chiar se leagănă**,
fiindcă valul joncilor o mai mănâncă. Până atunci garda din generator o
calculează din `rest_sag + sag_bus`, nu o măsoară.

**Două capcane de unelte, de evitat la reluare** (nu sunt despre pistă, dar au
costat timp aici):
- **`| head -N` pe ProbeRace blochează procesul.** Când `head` închide
  pipe-ul, Godot nu primește SIGPIPE dacă ieșirea e tăcută, iar procesul
  rămâne agățat cu CPU 0 — fără să termine și fără să scrie nimic. Rulează
  ProbeRace **cu redirectare în fișier** (`> seed1.txt 2>&1`) și filtrează
  fișierul după;
- **editorul Godot deschis rescrie `.tscn`-uri** (memoria
  `editor-godot-deschis-rescrie-tscn`). Înainte de orice regenerare a lui
  `Track22.tscn`, verifică `tasklist` / `git diff --stat` — aici am prins un
  proces de editor deschis din dimineață, și deși n-a atins scena, ar fi putut.

### 7.2 `PontoonRoadHazard` — semnătura pistei (14 oct 2026)

`scenes/hazards/pontoon_road_hazard.gd` + `assets/shaders/pontoon_road.gdshader`
+ `tools/ProbePonton.tscn`. Trei tronsoane vii pe `Track22`, cu faze de val
diferite (0, 0,333, 0,667) ca să nu se legene la unison.

**Decizia de arhitectură: clasă de sine stătătoare, nu subclasă.** §5.3
identificase capcana (`find_children("*", "RopeBridgeHazard")` din
`snapshot.gd` și `probe_machu_pod.gd` prinde și subclasele) și propunea ori un
strat comun extras, ori căutări strânse pe tip exact. Am ales **a treia cale**,
după ce am măsurat scopul: din cele 604 linii ale podului, ~36 de referințe sunt
vizual de pod (scânduri, cabluri portante, balustrade de frânghie, turnuri de
piatră), iar fizica comună e ~80 de linii. Un strat comun ar fi atins o clasă pe
care Track15 o folosește, pentru un câștig mic.

Deci: **cod propriu, model matematic împrumutat, podul neatins.** Contractul cu
`Track` merge prin **duck-typing** (`has_method("road_hole_span")`), deci
pontonul e recunoscut fără să fie rudă cu podul. Capcana e închisă **prin
construcție**, nu prin fix. Verificat: `rope_bridge_hazard.gd`,
`rope_bridge.gdshader`, `probe_machu_pod.gd`, `snapshot.gd` și `Track15.tscn`
sunt **nemodificate**, iar `ProbeMachu` trece cu cifrele neschimbate (săgeată
0,60 sport / 1,50 autobuz, balans 0,96 m, stingere 1,30 s).

**Cele trei schimbări față de pod**, exact cele prezise în §5.3:

| # | ce | de ce podul n-o are |
|---|---|---|
| 1 | **capete libere**: `P(u) = free_ends + (1−free_ends)·4u(1−u)` | la pod `4u(1−u)` e **zero** la capete — frânghia e ancorată în turnuri. Un ponton plutește pe toată lungimea |
| 2 | **tangaj**: a treia ecuație, pendul amortizat pe axa longitudinală | un pod cu capete fixe nu se poate înclina pe lung. E ce separă „drum moale” de „drum care plutește” |
| 3 | **valul joncilor**: termen sinusoidal cu fază proprie | pontonul e **viu când pista e goală**; podul, nu |

Capetele libere aduc o constrângere pe care podul n-o avea: **pragul de la
insuliță la ponton** nu are voie să treacă 0,3 m (memoria
`suprafete-cu-goluri-si-praguri`). De aceea există `edge_clamp`, care stinge
cedarea pe ultimii metri — măsurat **0,042 m**, cu marjă mare.

**Contractele, măsurate** (`ProbePonton`, pe sol plat, înaintea pistei):

| contract | țintă | măsurat |
|---|---|---|
| afundare autobuz (2,6) la mijloc | 0,45 m | **0,450 m** |
| afundare sport (0,9) la mijloc | 0,18 m | **0,180 m** |
| masa se vede (autobuz > sport) | — | **0,450 > 0,180** ✔ |
| prag la insuliță, cea mai rea din 4 faze | < 0,30 m | **0,042 m** |
| salt de placă pe tick | < 0,12 m | **0,099 m** |
| val cu pistă goală | > 0,02 m | **0,121 m** |
| tangaj: capătul încărcat **coboară** | semn negativ | **−0,125 m** ✔ |

**Sabotajul prinde:** `--sabotaj` stinge `free_ends`, `pitch_gain` și
`wave_amp` (adică face pontonul un pod), iar gărzile 5–6 trebuie să **pice** —
și pică (oscilație 0,0000 în loc de 0,121). Fără proba asta, gărzile n-ar
deosebi un ponton de un pod.

**Trei defecte găsite de sondă, toate la prima rulare:**
1. **semnul tangajului era invers** — masa la capătul departat îl *ridica*.
   `_pitch_at(u)` se adună la cotă, deci un pitch pozitiv ridică; ținta trebuia
   negată. Prins de garda 6, care verifică **semnul**, nu doar că răspunde;
2. **sonda măsura afundarea cu valul pornit** și raporta 0,507 m în loc de
   0,450. Diferența era *exact* `_wave(0,5)` la `t = 0` (−0,0571 m), la a patra
   zecimală — deci clasa era corectă, sonda măsura două lucruri deodată.
   Aceeași familie cu memoria `ceasul-porneste-in-prima-faza`. Acum garda 1
   stinge valul, iar garda 2 (pragul) îl **baleiază pe 4 faze**, fiindcă mașina
   intră pe ponton în orice fază a hulei;
3. **garda 3 era `async` dar chemată fără `await`**, deci verdictul se tipărea
   înaintea ei și secțiunea ieșea **goală** — o gardă care nu măsoară nimic și
   nici nu se plânge. Are acum și o linie care pică dacă saltul maxim e exact
   0,0000 (plăci care nu s-au mișcat deloc).

Plus unul găsit de **sabotaj**: garda 4 restaura `wave_amp = 0.10` cu o
constantă hardcodată, suprascriind sabotajul — deci garda 5 raporta oscilație
chiar și cu valul stins. O sondă care își rescrie subiectul nu-l mai măsoară.

#### Al cincilea defect, găsit de ProbeRace: tronsoane peste limita mecanismului

Cu pontoanele puse pe pistă (3 tronsoane de 71,5 m), ProbeRace a dat
**148–156 repuneri per cursă** — de la 1–3 — iar turul a urcat de la 69 s la
**152–192 s**. Repunerile erau grupate exact la fracțiile capetelor de tronson
(0,11 / 0,14 / 0,21).

Cauza **nu era pontonul**, ci un contract depășit în silențiu.
`Track._resolve_span_holes` taie gaura din carosabil pe `2·steps` puncte
coapte, cu bucla limitată la **`k = 15`**. Pasul mediu **măsurat** pe Track22
e **2,001 m** (1 009 puncte pe 2 019 m), deci gaura maximă pe care mecanismul
o poate tăia e **~60 m**. Tronsoanele mele de 71,5 m cereau `k = 18`: gaura s-a
tăiat la 60 m, iar ultimii ~11 m au rămas **asfalt peste plăcile care se
mișcă**. Niciun avertisment.

Diagnosticul a venit din raycast pe tablier, nu din ghicit: `RoadTop` era
prezent la u=0 și u=1 (deci asfalt pe tronson), iar `Plate` doar la mijloc.

**Remediul nu e creșterea limitei din `track.gd`** — ar atinge podul de pe
Machu Picchu, care merge la 34 m cu `k ≈ 8`. Sunt **7 tronsoane de 43 m**, cu
marjă față de 60, și o **gardă în generator** care verifică fiecare lungime
față de `2 · 15 · pas_măsurat`, plus un minim de 24 m (sub atât legănarea nu se
simte: e o treaptă, nu o plută).

A ieșit și un defect secundar: insulițele fixe stăteau la **1,19–1,41** în timp
ce tablierul e la 0,43–0,56, adică **prag de ~0,7 m** — de două ori limita de
0,3. Cauza: `harbour_quay.glb` are originea **la linia apei**, nu la bază, și
2,2 m peste ea (`docs/asset_briefs/okinawa_kit_v2.md:213`) — cote pe care le
presupusesem, nu le citisem. Corectat cu cifrele reale plus corecția de
afundare la buză: insulițele sunt acum la **0,59–0,60**, cu prag de
**0,03–0,17 m**.

#### Al șaselea defect: afundarea nu satura — grila de start scufunda tablierul

După tronsoanele scurte, repunerile au scăzut de la 148–156 la **41–56**, dar
**82 din 97** erau pe **primul tronson**, toate în primul tur (t = 22–25 s),
toate în același punct, cu autobuzul de două ori mai des decât restul. Profilul
longitudinal măsurat era curat (toate pragurile sub 0,17 m), deci nu geometria.

Cauza era un defect de **proiectare al clasei mele**: `_sag_target` e suma
`Σ a_i·P(u_i)`, deci afundarea e **liniară în încărcare**. Cu 8 mașini pe
același tronson iese ~2,3 m (8 × 0,29), iar tablierul de la +0,60 ajunge la
**−1,84 m** — sub plasa de repunere a mării (−1,20) și sub apă (0,00). Podul de
pe Machu Picchu n-are problema: are 35 m și trece pe el o mașină sau două. Un
ponton de pe grila de start primește **tot plutonul deodată**.

**Remediul e fizic, nu un plafon arbitrar: flotabilitate.** Un ponton are
butoaie care deplasează un volum **finit**, deci afundarea se **saturează** —
exact ce o coardă nu face. Implementat ca plafon moale (`sag_max = 0,70`, prin
`tanh`), ca să nu existe un punct în care tablierul se oprește brusc:
- la o mașină răspunsul rămâne **liniar** — calibrarea a derivat cu 3,5%
  (autobuz 0,434 în loc de 0,450), sub marja de 6% pe care o calculasem;
- la 8 mașini dă **1,63×** afundarea uneia, nu 8×;
- afundările **locale** trec și ele prin plafon (jumătate din `sag_max`),
  altfel patru gaussiene lipite ar scufunda tablierul pe lângă saturație;
- `net_ceiling_drop()` se socotește acum din `sag_max`, nu din `sag_bus`: cu
  flotabilitate, cât de jos poate ajunge tablierul nu mai depinde de câte
  mașini sunt pe el.

**Gardă nouă (7) în `ProbePonton`**, care testează exact cazul care a rupt
pista: 8 autobuze pe un tronson, strânse la mijloc. Verifică două lucruri —
că tablierul rămâne **peste plasa pe care pontonul însuși o cere** (măsurat:
1,080 m vs 1,320 m, marjă 0,240) și că raportul 8-mașini/1-mașină e **sub 3×**
(măsurat 1,63). Fără garda asta, defectul s-ar fi întors la orice schimbare de
calibrare.

#### Al șaptelea defect: tablier de 6 m pe carosabil de 12 m

Flotabilitatea a dus repunerile de la 41–56 la **7–24**, dar frac 0,10 rămânea
punctul cald (22 din 45). Profilul **lateral** măsurat a dat răspunsul: la
**+2,6 m** de ax se lovea `TerrainBody` la 0,28, nu tablierul la 0,43 — adică
tablierul se termina la ±2,6 m, iar mai departe mașina călca pe nimic.

Cauza e o **nepotrivire de unități între două contracte**, și e mută:
- `custom_width_segments` ia **semi**-lățimea (`TrackFromPath`: „(frac_start,
  frac_end, **half_width**)”), deci 6,0 → carosabil de **12 m**;
- `PontoonRoadHazard.deck_width` ia lățimea **totală**, deci 6,0 → tablier de
  **6 m**.

Pusesem 6,0 în amândouă. Rezultatul: 3 m de fiecare parte de carosabil tăiat
fără tablier dedesubt, și nicio eroare — mașina pur și simplu cade.

Corectat prin **o singură constantă** (`_PONT_HALF_W = 6.0`) derivată în ambele
locuri, plus gărzi care verifică sensul fizic în loc de tautologie: tablierul
≥ 3 lățimi de mașină (ca să se poată depăși pe el) și semi-lățimea ≤ cea a
pistei (ca tablierul să nu atârne peste apă). Verificat după: tablierul
acoperă **±5,3 m** în loc de ±2,6.

**Tiparul care se repetă în toate trei defectele de integrare** (gaura de 60 m,
saturația, lățimea): contractele izolate ale clasei treceau impecabil, iar
defectul era la **granița dintre clasă și pistă** — o limită nescrisă, o
încărcare pe care sonda izolată nu o produce, o unitate de măsură diferită.
De aceea `ProbeRace` pe pista reală nu e opțional după `ProbePonton`: măsoară
altceva (memoria `harnas-sintetic-comportament-emergent`).

### 7.3 `TideHazard` și banda de jos (14 oct 2026)

`scenes/hazards/tide_hazard.gd` + `tools/ProbeMaree.tscn`. Variantă de
`WaterHazard` (cele trei metode virtuale) **plus** poartă de bandă în
`Track.BRANCH_GATE_GROUP` — vezi decizia 3.1.3, închisă acum pe cod citit.

Ciclu de **80 s** în patru faze: JOS (terasa descoperită, scurtătură uscată) →
URCA (apa vine, banda **încă deschisă**) → SUS (apa peste terasă, banda
**închisă**) → COBOARA (se retrage, banda redeschisă udă).

**Contractele, măsurate** (`ProbeMaree`, izolat):

| contract | măsurat |
|---|---|
| ceasul la `t = 0` e **telegraf** (URCA), nu apă sus | ✔ URCA |
| banda deschisă majoritar | **49,6 s din 80** (62%) |
| fereastră de risc (apă pe bandă deschisă) | **22,8 s** per ciclu |
| toate patru fazele apar, în ordine | URCA → SUS → COBOARA → JOS |
| nivelul e continuu (fără salturi) | **0,0015** / tick |
| apa și poarta acordate | **0 / 400** contradicții |

`--sabotaj` pornește ceasul cu apa sus — exact greșeala din Fiordland — și
garda 1 **pică**, cum trebuie.

#### Scurtătura de maree e geometric IMPOSIBILĂ pe traseul ăsta — clasa rămâne, plasarea nu

**Clasa e gata și testată. Banda de jos NU e pusă pe pistă**, iar motivul e
măsurat, nu de gust. Trei încercări, fiecare infirmată de cifre:

**1. Banda paralelă (cum o descrie §3): −1,9% câștig.** §3 o descria ca „bandă
la +0,4 m, mai scurtă și mai directă”, pe terasa de la baza peretelui, paralelă
cu drumul de sus. Construită literal, garda a dat −1,9%. Baleind toată bucla
(patru ferestre × laterale de −12 la +12 m): **niciodată peste −2,3%**.

Motivul e geometric și evident în retrospectivă: **o bandă paralelă are aceeași
lungime ca drumul pe care merge.** Offsetul lateral scurtează doar pe interiorul
curbelor, iar latura de coastă e prea dreaptă. Ținta Monument Valley (−25…−35%)
nu e atingibilă așa — o scurtătură trebuie să **taie coarda**.

**2. Coarda de la închiderea buclei (0,962–1,040): −32%, dar rupe cursa.**
Măsurând câștigul de coardă pe tot traseul, candidata arăta perfectă: −32,0%,
plată (0,3 m pe 158 m), pe lângă satul plutitor. ProbeRace a arătat altceva:
**tur minim 2,88 s** pe o pistă de 2 km. Fracțiile 0,962 → 1,040 trec **peste
linia de start**, deci mașina care ia scurtătura închide turul pe ea și reintră
dincolo de start. Nu e scurtătură, e o eroare de topologie.

Pe drum a apărut și o a doua ipoteză greșită: cele 14 repuneri noi din zona
benzii le-am pus pe seama unei trepte de 1,2 m la joncțiune (banda era coborâtă
**uniform**, iar `TrackBranch` citește capetele de pe bucla principală — vezi
memoria `banda-coborata-uniform-lasa-treapta`). Racordarea cotei cu profil
`4u(1−u)` a fost **corectă ca principiu** și a rămas în lecții, dar **n-a
schimbat cifra**: tot 14 repuneri. Cauza era topologia, nu cota.

**3. Nicio altă coardă nu există la nivelul mării.** Baleind tot traseul cu
filtru „nu atinge startul”, **singura** scurtătură cu câștig ≥ 20% e la **acele
de păr** (0,58–0,68, −40%), la cotă **+12…+22 m**. Zero candidați sub +6 m.

**Concluzia intermediară a fost:** pe traseul de atunci o scurtătură de maree
nu avea loc. Mareea cere o terasă *plată și la nivelul apei*, iar singurul loc
care scurta ceva era pe insulă, la 20 m deasupra mării.

**Decizia dezvoltatorului (14 oct 2026): se redesenează latura de coastă** —
opțiunea (b) din cele trei puse pe masă. Celelalte două, respinse: (a)
scurtătura pe insulă cu mareea doar ca atmosferă, (c) mareea pe dig ca pasaj
obligatoriu fără decizie.

#### Redesenarea laturii G: golful care intră în uscat

Latura G era o linie aproape dreaptă de la (84, 192) la (−352, 322) — și pe o
dreaptă nu există scurtătură, fiindcă nu e nimic de tăiat. Acum drumul
**ocolește un golf care intră ~100 m spre uscat (nord)**, iar banda de jos taie
peste **gura golfului**, la nivelul apei.

**Adâncimea golfului e aleasă pe măsurătoare, nu din ochi:**

| adâncime | câștigul cordei | verdict |
|---|---|---|
| 60 m | −12,4% | prea puțin |
| 80 m | −22,0% | la limită |
| **100 m** | **−28,4%** | **în țintă** |
| 120 m | −36,2% | peste țintă |

La 100 m bucla crește de la 2 028 la **2 076 m**, deci rămâne în fereastra
2 000–2 200. Toate gărzile existente trec după redesenare: rază 22,1 m, pantă
9,7%, separare 88,9 m, Cebîșev 305 m, sens antiorar, iar cele trei gărzi de
azimut văd reperele (93%, 100%, 85%).

**Măsurat pe scurtătura finală:** ocol 227,9 m, coardă **153,3 m**, câștig
**−32,8%** — în ținta Monument Valley. Ocolul e plat (0,2 m abatere), deci
terasa de maree stă acolo credibil, iar banda **nu atinge linia de start**.

Două efecte secundare, amândouă corecte:
- **`sea_level_offset` s-a recalculat singur** la −5,91 (era −5,99), fiindcă
  media cotelor s-a schimbat odată cu traseul. Exact motivul pentru care e
  derivat în generator și nu scris de mână (memoria
  `cota-marii-e-relativa-la-media-drumului`);
- **maimuțele s-au mutat** pe ramura de intrare în golf (punctul „G maimute" a
  dispărut), iar distanțele dintre hazardele cu ceas rămân peste prag:
  1 326 / 246 / 504 m.

**Patru gărzi noi** pe contractul scurtăturii, fiecare pentru un defect care a
costat deja o rundă: câștig în intervalul [−45%, −20%]; **nu trece peste linia
de start**; ocolul plat; **treapta la joncțiune zero** (profilul de coborâre e
`4u(1−u)`, nu o constantă).

**Scurtătura funcționează în joc:** 9–13 treceri per cursă, timpi 6–19 s, zero
repuneri pe bandă, **niciun tur scurtcircuitat** (minim 60,3 s). Obiectivul
redesenării e atins.

#### PROBLEMĂ DESCHISĂ: regresie pe primul ponton după redesenare

Redesenarea a adus o **regresie măsurată** pe care nu am reușit să o
diagnostichez, și o las scrisă cu tot ce am eliminat, ca următoarea sesiune să
nu reia aceleași piste.

**Cifrele** (aceleași patru seed-uri, repuneri în zona pontoanelor /
repuneri totale):

| starea pistei | seed 1 | seed 2 | seed 3 | seed 4 |
|---|---|---|---|---|
| înainte de golf | 0 | 3 | 0 | 4 |
| **cu golf** | 1 | **13** | 2 | **9** |
| cu golf, fără nodul de maree | — | 10 | — | 7 |

Turul mediu a urcat de la 70,6–72,4 s la 72,6–80,5 s. Tiparul e în **valuri**
(t ≈ 23–25 s, 31–36 s, 45 s): tot plutonul cade la trecerile din primele
tururi, iar pe seed 1 și 3 aproape nimic.

**Cinci ipoteze, toate infirmate prin măsurare:**
1. **mareea** — scoasă din scenă, cifra rămâne 10/7 (vs 13/9). În limita
   nedeterminismului Jolt, deci **nu e mareea**;
2. **treaptă de cotă la joncțiunea benzii** — racordarea cu profil `4u(1−u)`
   e corectă ca principiu și a rămas, dar **n-a schimbat cifra**;
3. **fracțiile râpelor nealiniate** după lungirea buclei (2 028 → 2 076 m).
   Erau într-adevăr hardcodate și alunecaseră cu ~2%; **le-am legat la
   reperele reale**, ceea ce rămâne o îmbunătățire reală. Dar profilul măsurat
   la punctul de cădere e **identic** înainte și după;
4. **distanța start → primul ponton** — măsurată: **168 m în ambele stări**;
5. **grila de start** — toate cele opt sloturi sunt pe `RoadTop`, cote
   1,09–1,16, măsurat cu `spawn_transforms(8)` plus raycast. Sănătoasă.

**Ipotezele 6–7, tot infirmate:**
6. **profilul lateral asimetric** (−1,44 m pe o parte, +0,23 pe alta) e
   **corect prin design**: râpa golfului e pe **exteriorul** buclei, iar sonda
   măsura *dreapta drumului* la −8 m pe axa x — fiindcă la frac 0,09 drumul
   merge spre sud, deci lateralul-dreapta are x negativ. Nu e un defect;
7. **plutonul** (`--ai=3` vs `--ai=7`): zero repuneri pe ponton în **toate**
   cele patru rulări. Nu e înghesuială.

#### Ce a fost de fapt: o cauză reală, plus o concluzie prematură

**Cauza reală, găsită la a opta încercare: `edge_clamp` prea scurt.** Toate
contractele pontonului verificau **pragul** la buză (0,042 m) și **afundarea**
la mijloc (1,080 m), amândouă bune. Niciunul nu se uita la cât de *repede*
coboară tablierul între ele. Cu `edge_clamp = 5` pe un tronson de 43 m și
plutonul pe el, tablierul cădea **0,42 m pe primii 4 m** — o rampă de
**13,4%**, peste pragul de pantă al pistei (13%), apărută brusc exact când
mașinile urcă pe tronson.

Reparat: `edge_clamp = 14` → **8,7%** măsurat pe lungimea reală, cu
**garda 8** în `ProbePonton` care măsoară panta pe primii 20% cu plutonul pe el.

**Și concluzia prematură, care e lecția mai importantă.** Rulând aceeași scenă,
același seed, aceeași configurație, am obținut **15 / 12 / 4** repuneri. Deci
diferența „0/3/0/4 → 1/13/2/9" pe care am numit-o *regresie* era **în mare parte
nedeterminismul lui Jolt** (memoria `proberace-nedeterminism`: se compară
distribuții, nu rulări). Am tratat o fluctuație ca pe un defect și am ars șase
ipoteze pe ea.

Ce rămâne valid din investigație: `edge_clamp` **era** într-adevăr prea scurt
(13,4% e peste prag, independent de orice rulare), iar fracțiile râpelor **erau**
hardcodate și alunecaseră. Ambele reparate pe motive proprii, verificabile fără
ProbeRace.

**Două defecte în propria sondă**, găsite pe drum, amândouă din familia
„testezi alt obiect decât jocul" (memoria `verifica-cu-parametrii-lui`):
- rula pe tronsoane de **60 m**, jocul are **43,1 m** — iar panta depinde de
  raportul `edge_clamp / lungime`, deci raporta 7,1% în loc de 7,6%;
- folosea **12 plăci**, jocul **7** — rezoluție mai fină, deci garda de
  continuitate raporta salturi mai mici decât cele reale.

**Decizia:** golful **rămâne** — și-a atins scopul (scurtătura există, e
folosită, nu rupe turul).

**Lecția de metodă:** o afirmație de geometrie dintr-un brief („mai scurtă și
mai directă”) e o **ipoteză**, nu un fapt. Garda de scurtătură a expus-o, n-a
prins-o: fusese scrisă pentru contract, iar contractul a arătat că premisa nu-l
putea atinge. Și a doua lecție, mai scumpă: **o coardă bună pe hartă poate fi
invalidă în cursă** — fracțiile se verifică și față de linia de start, nu doar
față de lungime și cotă.

#### O capcană de format `.tscn`

`[sub_resource]` trebuie să fie **înaintea primului `[node]`**, altfel parserul
dă „Unknown tag 'sub_resource' in file" și scena nu se încarcă deloc. Curba
benzii se calculează deci *înainte* de header-ul scenei, nu lângă nodul care o
folosește. (Prima încercare de a muta blocul prin manipulare de string a rupt
generatorul — restaurat din git și refăcut cu editări țintite.)

## 8. Lecții aplicate anticipat, și ce a fost respins

- **Patru axe, scrise înaintea traseului** (§2.0). Consecința derivată din
  cameră, nu din gust: **turnurile apropiate sunt flanc, nu reper**, iar
  dezvăluirea de pe belvedere e **adâncime** (straturi de ceață), nu un obiect.
- **Scara e decizie.** Turnurile au 40–70 m, nu 200. Grota are 70 m, nu
  câteva sute. Mareea are ~1,6 m utili, nu 4. Satul plutitor are 12 case, nu
  200.
- **Hazardele cu ceas la ≥ 200 m unul de altul** (§3), aici cu marjă mare.
- **Pontonul moștenește un model fizic dovedit**, nu unul nou: podul de
  frânghie are deja închise capcanele care contează (amplitudini continue,
  plăci permanente, aceeași formulă în GDScript și în shader, `platform_velocity`
  în loc de cuplu — fiindcă **yaw-ul mașinii e rescris pe tick**, memoria
  `yaw-ul-masinii-e-rescris-pe-tick`).
- **Pragurile laterale > 0,3 m sunt ziduri** (memoria
  `suprafete-cu-goluri-si-praguri`): e constrângerea care decide unde stau
  insulițele fixe dintre tronsoanele de ponton.
- **Ceasurile pornesc în prima fază** (memoria `ceasul-porneste-in-prima-faza`):
  mareea la `t = 0` trebuie să fie în **telegraf**, altfel toate verdictele
  ProbeRace ies cu scurtătura închisă, ca ploaia de pe Fiordland.
- **Hazardul se măsoară pe ax înainte de ProbeRace** (memoria
  `hazard-dezaliniat-contamineaza-verdictul`).
- **Plasa lumii și zidul la 420 m** (memoria `ziduri-invizibile-ale-lumii`),
  verificate **înaintea** traseului, fiindcă pista e jumătate pe apă.
- **Umbra de turn pe apă e reperul luminii**, deci `shadow_distance` se
  verifică pe casteri (memoria `umbre-exista-dar-cascada-e-scurta`), iar
  turnurile de fundal au `cast_shadow` OFF (memoria
  `caster-departat-fura-umbra`).
- **Apa verde-jad se măsoară după remap, în joc** (memoria
  `monocromia-se-masoara-dupa-remap`), nu pe `.glb`; saturația, nu luminanța,
  e axa care decide (memoria `apa-stilizata-de-noapte`).
- **Diorama se face din geometria reală** (memoria `diorama-din-geometria-reala`):
  promptul se scrie pe captura reală a lui Track22, nu pe schița de aici.
- **Gauntlet-ul POI iese pe (a)/(b)/(c)**, iar acceptarea finală e la volan
  (memoria `gauntlet-iesirea-din-bucla`: câștigul orb față de dioramă nu vine
  niciodată, 0/11).
- **Respectul e regulă de design:**
  - **satul plutitor e un loc unde trăiesc oameni**, nu o curiozitate: casele
    sunt întregi și întreținute, nu ruine pitorești; nu există „sărăcie ca
    decor” (haine zdrențuite, copii cerșind, bărci pe jumătate scufundate);
  - **maimuțele nu sunt hrănite și nu sunt lovite „ca să sară”**: sar singure,
    iar contactul te deviază. Aceeași regulă ca la ursul de pe Transfăgărășan;
  - **fără locuri religioase**: fără pagode, altare pe bărci sau temple în
    grote (unele grote din golf au altare reale). Aceeași regulă ca la Okinawa
    (fără *utaki*) și Transfăgărășan (fără mănăstiri);
  - **fără simboluri politice sau de stat**: fără steaguri, fără stele.
- **Legal și nume:**
  - **„Ha Long” e nume geografic**, deci se poate folosi (ca „Okinawa”,
    „Serengeti”, „Transfagarasan”). Numele de companii de croazieră, de
    bărci sau de hoteluri din golf, **nu**;
  - fără mărci pe bărci, pe butoaie sau pe plase;
  - în UI apare doar „Ha Long”; numele satelor (Cửa Vạn, Vung Vieng) și al
    grotelor (Hang Luồn) **nu** apar;
  - semnele și indicatoarele sunt **fără text lizibil**;
  - **fără diacritice vietnameze în cod**, nici în numele de fișiere sau de
    noduri (sunt în brief, pentru referință, dar nu intră în repo ca
    identificatori).
- **Respins, cu motiv:**
  - **Monte Roraima / Angel Falls**: candidatul cel mai apropiat (umplea golul
    de junglă, cu cascada ca reper vertical). Respins fiindcă **silueta de
    munte-masă cu perete vertical e aproape de Machu Picchu și Fiordland**
    pe axa „perete înalt, verde ud, ceață”, iar Ha Long e mai departe de orice
    pistă existentă. Rămâne candidatul numărul 1 pentru pista următoare;
  - **terasele de orez Banaue**: elevația construită în biom era atractivă,
    dar **Machu Picchu are deja terase în siluetă**; „a doua pistă cu terase”
    e un risc de percepție pe care Ha Long nu-l are;
  - **Salar de Uyuni**: oglinda infinită ar fi fost contrastul maxim, dar
    **platitudinea contrazice direct principiul 3** (elevație folosită
    agresiv). Ar merge doar asumat ca „pistă-anomalie”;
  - **zonele umede / delta**: aceeași problemă de platitudine;
  - **al patrulea oraș** (Veneția era candidata evidentă pentru „drum pe
    apă”): urbanul e deja de trei ori în roster (Chongqing, Kyoto, Jodhpur),
    iar Ha Long dă drumul plutitor **fără** să mai adauge un oraș;
  - **vaporul de croazieră alb** (§0.1, decizie deschisă 3.1.6);
  - **plaja mare de nisip alb**: ar face pista să citească „Okinawa”.

## 9. Prompt pentru ChatGPT (dioramă de referință)

Se scrie la pasul 7 din §7, **pe captura reală de sus** a lui `Track22`
(`Snapshot.tscn -- --track=22 --no-fog`, cu fereastră), adnotată cu
`tools/annotate_halong_plan.py`. Nu se scrie acum: memoria
`diorama-din-geometria-reala` — referința e o captură ortografică adnotată a
pistei reale, nu un plan schematic desenat din brief.

Ce se ia din Okinawa v0.2 și Transfăgărășan v0.2 când se scrie:
**„ONE CLOSED LOOP”** ca prim paragraf, **densitatea pe cifre**, **hazardele
surprinse în cadru** (jonca tăind canalul, maimuțele sărind pe parapet,
pontonul afundat sub o mașină grea, banda de jos pe jumătate sub apă) și lista
**FORBIDDEN** din §8.

**Camera, de decis pe planul real** (lecția din Transfăgărășan §9: din SE
masivul tunelului ascundea serpentinele, din NE ascundea barajul — nu se pot
avea amândouă). Aici conflictul previzibil e între **satul plutitor** (NV) și
**belvedere + șirurile de turnuri** (SE). Reperul principal al pistei e
**șirul de turnuri în ceață** (§0.1), deci el merge în prim-plan, iar camera se
alege ca soarele de ESE să vină **din dreapta-față**, ca turnurile să fie în
contralumină parțială și umbrele să cadă pe apă.
