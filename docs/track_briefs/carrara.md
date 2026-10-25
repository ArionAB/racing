# Track brief — Carrara / bazinul de marmură Fantiscritti (`Track23`, temă `carrara`) — v0.2 (concept, paletă caldă asumată)

> Concept de pistă, înaintea listei de assets. Scheletul e cel din
> `serengeti.md` / `fiordland.md`; secțiunile de assets (§5) sunt schițate,
> nu complete — se detaliază după ce traseul trece de ProbeLayout, de
> ProbeRace și de captura `--driver` (ordinea din memoria
> `diorama-din-geometria-reala`: traseu → gărzi verzi → captură adnotată →
> dioramă → foaie de assets → POI).
>
> **Prima pistă industrială** din joc, a treia din Europa (după Stromboli și
> Transfăgărășan), și **prima care dă casă la trei hazarde construite și
> nefolosite pe nicio pistă**: `ExcavatorHazard`, `CraneHazard` ca macara de
> carieră și `SlidingHazard`/`RockfallHazard` ca bloc pe sanie (§3). Nicio
> clasă mare nouă; ce e nou e mic și e scris la §3.
>
> **v0.1 (25 oct 2026), alegerea dezvoltatorului:** cerut „următoarea hartă,
> un loc real, cu hazarde reutilizabile sau noi”, cu observația lui că nu
> avem templu, junglă sau carieră. Inventarul celor 14 piste din joc (13 în
> carieră + Ha Long) a confirmat golurile și a adăugat altele: zonă umedă
> (mlaștină), agricol, industrial, și dezechilibrul geografic — **Asia 7
> piste, Europa 2, Africa / America de Nord / America de Sud / Oceania câte
> una**. Candidatele puse pe masă: **Carrara** (carieră, industrial, Europa),
> **Angkor** (templu + junglă într-un loc, dar a opta pistă asiatică și
> „ruina ca și carosabil” cere trepte sub pragul roții), **bayou-ul
> Atchafalaya** (zonă umedă, furtună cu fulgere — efectul nr. 1 din
> `ref_notes/README.md`, încă nefolosit — America de Nord), **Iguazú**
> (junglă pură, America de Sud). Alegerea: **Carrara**, cu Angkor
> următoarea candidată pentru „ruina ca și carosabil” (`05_jungla_ruine.md`)
> și bayou-ul pentru furtună. Nu se exclud.
>
> **Ce e diferit față de celelalte piste de munte alb.** Alpii / Baikal /
> Transfăgărășanul sunt albe de **zăpadă**; aici albul e **piatră tăiată cu
> firul diamantat**, vara, sub soare cald, cu pădure de castani verde
> alături și mașini de lucru galben-spălăcit și ruginii. Riscul nr. 1 al
> pistei e exact confuzia asta (§6, §8): „pare iarnă”. Se măsoară, nu se
> presupune.
>
> **v0.2 (25 oct 2026), rezerva dezvoltatorului și decizia lui:** „fiind de
> marmură o să pară mai degrabă grey? sau ca și cum ar fi iarnă? majoritatea
> carierelor sunt golden/brown” — apoi: „putem și să ajustăm să pară mai
> cald, chiar dacă nu e 100% accurate cu realitatea”. Rezerva e întemeiată
> mai mult decât o trata v0.1: marmura ar fi stat pe `FOAM_WHITE` 22 și
> `MARBLE_GREY` 29, adică **exact sloturile zăpezii de la Baikal și ale
> gneisului de la Fiordland**, iar alb + gri + verde + cer albastru e deja
> compoziția Transfăgărășanului și a Baikalului; într-un low-poly, o terasă
> albă tăiată drept și o pantă de zăpadă sunt aceleași plane plate. Garda
> din v0.1 („testul de anotimp” pe pista gata) venea prea târziu.
> **Abatere asumată de la realitate: Carrara caldă.** Albul rămâne doar pe
> fețele verticale proaspăt tăiate și pe blocuri, și e **crem-auriu la soare,
> gri-albăstrui în umbră**; tot ce e orizontal (terase, drumuri, piazzale,
> moloz) e **praf bej-cald**; lumina e de **oră aurie**; dâre de rugină pe
> pereți, marcaje portocalii pe blocuri, țiglă pe acoperișurile din sat,
> ginestra galbenă pe versant. Nu e pistă de iarnă nici la prima privire — și
> asta se verifică **înaintea traseului**, cu testul de mostră din §7 pasul
> 0, nu după decor. Dacă nici varianta caldă nu trece testul, locul se
> schimbă (Rio Tinto, Bingham Canyon — §8), păstrând structura.

## 0. Într-o propoziție

Oră aurie de iulie în Alpii Apuani: pornești din **piazzale-ul unei
cariere de marmură**, pe praf bej bătătorit, între blocuri stivuite cât o
casă, cu **excavatorul care coboară cupa peste bandă**; cobori pe
**gradonii crem-aurii** — trei terase tăiate drept în munte, legate prin ace
de păr, fețele la soare aproape aurii și cele din umbră albăstrui — cu
**camionul de marmură urcând încărcat spre tine** pe fiecare rampă; ajungi
pe fundul carierei, lângă **bălțile lăptoase turcoaz** de apă de tăiere,
unde **macaraua-derrick leagănă un bloc de 20 tone peste drum**; intri prin
portal în **galeria subterană** — o catedrală de marmură cu stâlpi lăsați
în picioare și lămpi calde de șantier — și urci în spirală prin munte
**până la cea mai înaltă carieră**, de unde se vede **tot amfiteatrul auriu
cu umbre albastre și bălțile turcoaz pe fund**; traversezi **Ponti di
Vara** — viaductul de cărămidă al fostei căi ferate a marmurei, lat cât un
camion — cobori rapid pe **ravaneto**, panta de moloz crem-gri (în realitate
alb ca un ghețar; la noi încălzit deliberat, §4) lângă pădurea verde de
castani și ginestra galbenă a Colonnatei, unde **sania de lizzatura cu un
bloc pe ea alunecă pe jgheab peste drum**, și intri prin **tunelul feroviar
vechi** înapoi în piazzale. Singura pistă din joc în care **lumea e tăiată
cu firul**: fiecare perete e o față plană cu dungi de tăiere, fiecare cotă
e o treaptă.

## 0.1 Regula de artă (ce NU e pista asta)

**Nu „munte cu zăpadă” și nu „șantier”. O carieră de marmură la oră aurie:
trepte crem-aurii uriașe tăiate drept, cu dungi orizontale de fir și dâre
de rugină, praf bej pe tot ce e orizontal, mașini galben-spălăcit și
ruginii mici ca jucăriile pe terase, bălți lăptoase turcoaz, pădure
verde-cald de castani cu ginestra galbenă pe un singur flanc.** Ce trebuie
să recunoască jucătorul în 3 secunde: *„crem-auriu tăiat în trepte, bej
de praf, galben de utilaj, verde de vară, turcoaz lăptos jos.”* Fața plană
cu dungi de fir e pentru Carrara ce e gneisul ud cu dungi de scurgere
pentru Fiordland. **Nimic alb-pur în cadru** (v0.2): albul curat rămâne al
spray-ului și al jeturilor de apă.

| pondere | strat |
|---|---|
| **30%** | marmura tăiată, **verticală**: gradonii (fețe de 6–9 m, dungi orizontale de tăiere la ~0,7 m, dâre de rugină de la apa de fir), blocurile stivuite (cuburi 2–3 m cu urme de fir și marcaje portocalii), stâlpii galeriei — **crem-auriu la soare, gri-albăstrui în umbră** |
| **15%** | praful, **orizontal**: terasele, drumurile, piazzale-ul, patul de moloz, ravaneto-ul (crem-gri, mărunt) — bej-cald, cu urme de roți; e stratul care încălzește cadrul și care în realitate e chiar bej (praful de tăiere amestecat cu pământ) |
| **20%** | mașinile: excavator pe șenile cu furcă, camioane basculante cu blocuri, macara-derrick, mașina de fir diamantat (volant + fir), ferăstrău-lanț pe șenile, mașina de forat; toate **galben-spălăcit + rugină + negru de cauciuc**, nicio culoare de mașină de joc |
| **15%** | verdele și galbenul: pădurea de castani de pe flancul Colonnatei, **ginestra galbenă** (reuse Stromboli) pe muchiile neexploatate, iarba din crăpături — culorile „vii” ale pistei, cele care spun „vară” |
| **10%** | apa și cerul: bălțile de marmettola (alb-turcoaz, opace, mate), jeturile de răcire pe fir, cerul albastru adânc cu orizont piersică |
| **10%** | istoria și satul: Ponti di Vara (cărămidă + marmură), tunelul Marmifera, vagonetul cu bloc din muzeu, sania de lizzatura cu bârne, Colonnata (case de piatră gri-cald, **acoperișuri de țiglă** — abatere: real sunt de ardezie —, turnul bisericii) |

Trei acte pe un tur, **aceeași paletă, altă proporție**: cariera
(crem-auriu + bej + galben-rugină + turcoaz), galeria (crem-gri în umbră +
lămpi calde + negrul boltei), flancul verde (crem-gri de moloz + verde de
castani + galben de ginestra + țiglă). Nu trei palete. **Lumina face
marmura**: fața la soare crem-aurie, fața în umbră gri-albăstruie — fără
contrastul ăsta pista e o pânză plată (§4, memoria
`suprafata-palida-e-lumina`).

## 1. De ce Carrara (referința reală, ce luăm din ea)

| loc real | ce luăm |
|---|---|
| **Bazinul Fantiscritti** (Miseglia), unul din cele trei bazine ale Carrarei (Torano, Fantiscritti, Colonnata), ~100 de cariere în total, ~30 active aici; amfiteatre de terase albe tăiate în munte | **forma pistei**: un amfiteatru de gradoni cu fundul la 0 m și buza la +45; se **coboară pe terase și se urcă prin munte**, nu se privește de pe margine (regula Serengeti: craterul se urcă și se coboară) |
| **Gradonii** (bancurile): fețe verticale de 6–9 m lăsate de firul diamantat, cu dungi orizontale; terase plane între ele, drumuri de transport în ace de păr pe rampe de moloz compactat | **verticalitatea ca treaptă, nu ca pantă**: muchia terasei e o cădere verticală, deci terasa de sub tine și bălțile se văd din conul de 63° al camerei fără taluz (memoria `umarul-ingust-ascunde-caderea` e rezolvată de geometria locului) |
| **Firul diamantat**: o tăietură de 10 × 10 m a scăzut de la 3 zile la ~4 ore față de firul elicoidal; blocul desprins e culcat pe un **pat de moloz** cu perne pneumatice sau cricuri hidraulice, apoi mutat de **excavatoare de 70 t** | **teatru**: mașina de fir cu volantul care se învârte și jetul de apă (cost zero); **hazardul blocului basculat** în galerie (§3) e exact gestul ăsta — blocul se culcă pe patul de moloz de lângă bandă și se rostogolește o dată pe ea |
| **Marmettola**: nămolul alb de calcit din apa de tăiere; bălți lăptoase, drumuri de pe fund alunecoase când sunt ude | **frecarea**: bălțile ca scurtătură lentă (0,6×), fundul carierei ud (`custom_wet_ranges`) — grip scăzut pe cea mai plată porțiune a turului |
| **Ravaneti**: pantele de deșeu (~80% din ce se taie nu e bloc) — de pe coastă, Apuanii par înzăpeziți în august | **coborârea rapidă** (POI G) pe moloz crem-gri (încălzit deliberat, §4), grip lateral 0,9×; și **capcana vizuală numită**: albul ravaneto-ului real e exact ce confundă lumea cu zăpada — de aici v0.2: molozul nu e alb la noi, iar pădurea verde și ginestra galbenă lipite de el sunt antidotul |
| **Ponti di Vara**: viaducte de cărămidă și marmură din secolul XIX ale căii ferate Marmifera (1876–1964), azi drum asfaltat „abia lat cât camioanele” | **POI F**: pod de 6 m peste chei, fără parapet real, camionul venind din față; **punctuația** de pe pistă — singurul loc unde cazi în gol |
| **Marmifera**: galerii feroviare prin munte, acum drum spre Fantiscritti; filonul Ravaccione a fost descoperit la săparea unui tunel | **POI H**: tunelul vechi, scurt (45 m), întunecat, lat cât un vagon — contrastul „din lumină în întuneric în lumină” înainte de linie |
| **Galeria Ravaccione 84**: carieră **subterană**, o sală uriașă în munte unde se taie blocuri, vizitată cu microbuzul prin tuneluri | **POI D, urcarea**: galeria e drumul prin care pista câștigă 43 m fără ca traseul să se suprapună cu sine — `CameraZone` cu tavan, stâlpi lăsați în picioare **pe carosabil** (gimmick de linie), lămpi |
| **Lizzatura** (până în anii 1960): blocurile coborau pe sănii de lemn pe bârne unse cu săpun, pe „vie di lizza” — jgheaburi drepte pe versant, frânate cu funii | **hazardul istoric** (POI G): sania cu bloc alunecă pe jgheab și **traversează drumul în diagonală**, apoi parchează jos; fereastră de timing ca tractorul din Ignition, cu poveste |
| **Colonnata**, sat la 8,5 km est, „într-un cadru deosebit de verde”: case de piatră, biserică, cariere deasupra lui | **flancul verde** al POI G: castani (reuse fagii din Transfăgărășan) + 5–6 case + turn de biserică la 120–160 m, pe pantă, în cadru după aritmetica din §2.0 |
| **Cava Museo Fantiscritti**: unelte și mașini vechi expuse afară (vagonet cu bloc, roată de fir elicoidal, sănii) | **decorul piazzale-ului** (POI A): muzeul în aer liber e motivul pentru care piesele istorice stau lângă cele moderne fără să mintă |

Culorile locului, **încălzite deliberat** (v0.2): **crem-auriu de marmură
la soare**, **gri-albăstrui de marmură în umbră**, **bej-cald de praf** pe
tot ce e orizontal, crem-gri de moloz, **galben-spălăcit de utilaj** +
**rugină** + negru de cauciuc și hidraulică, dâre de rugină pe pereți,
**alb-turcoaz lăptos de baltă**, verde-cald de castan + **galben de
ginestra**, gri-cald de piatră de sat + **țiglă**, roșu-cărămidă stins al
viaductului, albastru adânc de cer cu orizont piersică. În realitate fețele
sunt alb-crem, molozul alb-gri, acoperișurile de ardezie — abaterea e
scrisă, nu strecurată. Lumina: soare la **~22°**, de oră aurie (șablonul
temei Monument Valley: `FFD2A0`, ambient albăstrui mic), **prin deschiderea
amfiteatrului** (carierele reale sunt amfiteatre deschise spre vale, nu
puțuri — deschiderea stă spre soare, ca fundul să fie luminat, nu un bol
albastru); fiecare gradon are o față la soare și una în umbră; **umbre
pornite** — umbra terasei de sus pe terasa de jos e identitatea, cum erau
dungile teraselor la Machu Picchu. Ambient **rece și mic** (cer albastru
pe marmură = umbre albăstrui, raport soare/ambient ≥ 3, memoria
`geometria-fara-lumina-e-invizibila`).

## 2.0 Verificarea cu camera (de ce se coboară în carieră și de ce galeria e urcarea)

`ChaseCamera`: **10 m sus, 12,5 m în spate, 28,7° în jos, FOV 68°**.
Marginea de sus a frustumului e la **~+5° peste orizontală**: la distanța
`d` vezi în sus cel mult `10 + 0,093·d` m față de cota drumului. În jos
vezi până la **63°**.

- **Amfiteatrul nu se arată de jos, se coboară în el și se urcă din el.**
  De pe fundul carierei (POI C, +2 m), un perete de 43 m la 30 m lateral
  intră în cadru doar până la 10 + 2,8 ≈ **12,8 m**: vezi primul gradon și
  jumătate din al doilea — un **canion alb**, nu un amfiteatru. E corect
  așa: jos trebuie să te simți închis. Dezvăluirea se câștigă în galerie:
  la ieșirea din portalul de sus (POI E, +45), camera la +55 vede 63° în
  jos — **tot amfiteatrul, bălțile și piazzale-ul la 43 m sub tine umplu
  cadrul** pe dreapta. A doua dezvăluire, mai mică, e chiar la start: de
  pe piazzale (+25) bălțile sunt la 23 m sub bandă, pe dreapta.
- **Muchia terasei e treaptă, nu umăr.** Lecția `umarul-ingust-ascunde-
  caderea` cere taluz > 45° în primii 3 m ca să se vadă golul; gradonii au
  fața **verticală** prin natura tăieturii, deci terasa de sub tine intră
  în cadru fără artificii. Capcana e inversă: o **bermă de siguranță**
  (dâmbul de moloz de la marginea drumului de carieră, real și
  obligatoriu acolo) de 0,6 m e un **zid** pentru roată (memoria
  `suprafete-cu-goluri-si-praguri`: pragurile laterale > 0,3 m sunt
  ziduri). Berma se pune ca **punctuație** (`04_coasta.md`): la vârful
  acelor de păr și la capetele podului, în pantă pe fața dinspre drum,
  nu continuu. În rest marginea e tăiată vertical, fără nimic.
- **Camionul se vede de la 100 m pe rampă, nu de la 300.** Un camion de
  3,6 m înălțime care urcă rampa spre tine e în cadru întreg de oriunde
  pe aceeași terasă; pe terasa de **deasupra** (9 m mai sus) îl vezi de la
  ≥ 50 m (9 < 10 + 0,093·50). Deci întâlnirea e anunțată de cel puțin un
  ac de păr înainte — cinstit, și fără HUD.
- **Galeria cere `CameraZone`.** Bolta la 16–18 m peste carosabil: cu
  camera implicită intră în cadru abia de la ~54 m (memoria
  `camera-zone-tavan-per-sala`: implicitul de 15 m ratează sălile de
  16/18 m — se declară `ceiling` 18 explicit). Presetul coboară camera și
  ridică ținta, ca la Cappadocia; sala (POI D, 0,46–0,50) are propria
  zonă cu tavanul ei, tunelul spiral alta, mai joasă (10 m).
- **Colonnata e flanc, nu fundal** (memoria `munte-flanc-nu-fundal`). Pe
  coborârea G (+43 → +27), satul stă pe versantul din stânga, la **120–160
  m lateral și +15…+22 m peste drum**: la 150 m vezi în sus până la
  10 + 14 ≈ 24 m, deci primele case și turnul intră în cadru; o Colonnata
  „pe creastă, la 300 m” ar fi ceață. Azimutul se **măsoară** după ce
  există traseul (memoria `reperul-se-vede-pe-patru-axe`: distanță,
  verticală, azimut, ocluzie), nu se promite acum.
- **Marea nu intră.** Litoralul e la 5–8 km de cariere; la noi orice
  dincolo de `fog_end` (~300 m) e ceață. Adâncimea pistei e **amfiteatrul**,
  nu orizontul (`world_design.md` §2: adâncimea prin proximitate). Marea
  e respinsă la §8.

## 2. Traseul și punctele de interes (POI)

Lungime țintă **~2,1 km** (tur ~70–75 s, 3 tururi ≈ 3:40 — fereastra
Ignition 65–80 s din `ref_notes/sisteme.md`). Sens: **cu amfiteatrul pe
dreapta**, în interiorul buclei, ca la Serengeti (singurul gol al pistei e
înăuntru). Cote: piazzale **+25**, fundul carierei **+2**, ieșirea din
galerie **+45** (maxim), pod **+43**, baza ravaneto-ului **+27**. Urcare
**într-o singură treaptă, prin munte** (2 → 45 pe ~370 m ≈ **11,6%**, sub
13% — **se măsoară cu ProbeLayout înaintea oricărui decor**), coborâre în
două: gradonii (25 → 2 pe ~400 m, cu rampele de 9 m pe ~80 m ≈ 11%, și
terasele plate între ele) și ravaneto-ul (43 → 27 pe ~380 m ≈ 4%, rapid).

```
   [A] START piazzale (+25) ──── [B] gradonii: 3 terase, 2 ace, camionul (+25→+2)
        ↑                                        |
   [H] tunelul Marmifera (+27→+25)        [C] fundul carierei: bălți, derrick, ud (+2)
        |                                        |
   [G] ravaneto + Colonnata + sania (+43→+27)   [D] galeria Ravaccione: sala, blocul (+2→+45)
        |                                        |
   [F] Ponti di Vara (+43) ──────────── [E] cariera de sus: dezvăluirea (+45)
```

| # | frac | POI | ce se întâmplă | lățime |
|---|---|---|---|---|
| **A** | 0.00–0.06 | **Piazzale-ul carierei** — platoul de încărcare de pe terasa a treia: blocuri stivuite 2–3 înalte pe ambele părți (coridor), un excavator cu furcă, un camion parcat, containerul-birou, rezervorul de carburant, muzeul în aer liber (vagonetul cu bloc, roata de fir elicoidal, o sanie veche); pe dreapta, dincolo de bermă, **bălțile la 23 m sub tine**. La **0.055**, la ieșirea din coridorul de blocuri, **excavatorul** parcat pe stânga coboară ciclic cupa peste banda stângă | grilă pe pulbere bej bătătorită; respiro + prima poartă de timing: cupa jos = banda stângă închisă 2,5 s din 7. **Reuse** `ExcavatorHazard` (zero cod, §3). Calibrare: ≈ +1,5 s dacă intri pe banda închisă (schimbi banda sau frânezi), 0 dacă citești ciclul | 10 m |
| **B** | 0.06–0.26 | **Gradonii** — coborârea pe trei terase: terasă plană (7 m, peretele crem cu dungi de fir și dâre de rugină pe stânga, golul pe dreapta) → **ac de păr pe rampă** (6 m, 9 m de coborâre pe 80 m) → terasă → ac → terasă. **Camionul de marmură** urcă încărcat **spre tine** pe rampe și terase (bucla lui e tot traseul B + F, §3): corp greu pe traseu fix care **te împinge spre exterior** dacă ești pe partea lui în ac. Berme doar la vârful acelor. Pe terase, la 3–5 m de bandă: mașini de fir cu volantul învârtindu-se și jetul de apă (teatru), blocuri proaspăt tăiate, cabluri | **hazardul-semnătură nr. 1**: fereastră de **linie**, nu de timp — îl vezi de pe terasa de sus, alegi interiorul acului. **Reuse** `BusHazard` cu model de camion (zero cod). Cădere de pe terasă = aterizare pe terasa de sub tine (9 m, suspensia ține, pierzi linia) sau pe fund = repunere ~2 s. Virajele > 90° cu 3–4 puncte pe arc (memoria `viraje-stranse-puncte-pe-arc`), raza > half_width, terasele la ≥ 2·half_width lateral (memoria `dunele-hairpin-pileup`) | 7 m / 6 m |
| **C** | 0.26–0.40 | **Fundul carierei** — drum plat de 9 m pe pulbere udă (`custom_wet_ranges`: grip scăzut, stropi albi), pe dreapta **bălțile de marmettola** (alb-turcoaz, opace), pe stânga **macaraua-derrick** (catarg A-frame de 16 m, braț, cablu) care leagănă **un bloc de 20 t** peste drum de două ori pe rotație; blocuri „informi” pe margini, un ferăstrău-lanț pe șenile tăind la perete (teatru). **Scurtătura** la 0.33: prin **marginea bălții** (apă 30 cm, 0,6×, stropi) tai colțul în loc să ocolești pe sub derrick — mai scurt cu ~35 m, dar lent; cu turbo intri rapid și câștigi, fără turbo pierzi | decizia: ocol uscat cu pericolul pendulului **sau** scurt prin apă fără pericol; **reuse** `CraneHazard` (zero cod dacă modelul respectă contractul §5.6) + `TrackBranch` cu `wet` și `speed_factor` 0,6 (zero cod). Calibrare: contact cu blocul = învârtit, ≈ +1,5 s (contractul Chongqing); baltă cu turbo ≈ −1,5 s, fără ≈ +2 s | 9 m / 5 m |
| **D** | 0.40–0.56 | **Galeria Ravaccione** — portal tăiat drept în perete (8 × 8 m), întuneric (`CameraZone` cu `darkness`), tunel spiral de 7 m care **urcă 43 m prin munte**; la 0.46–0.50 **sala**: 16 m lățime, 18 m tavan, **doi stâlpi de marmură lăsați în picioare PE carosabil** (alegi stânga sau dreapta fiecăruia — gimmick de linie), lămpi de șantier pe trepied (calde, `HazardLamp`), un puț de lumină din tavan; la 0.48, pe dreapta, **blocul basculat**: la 2 s după ce pernele pneumatice „suflă” (telegraph, sunet + umflare), un bloc informe de 3 m se desprinde din perete, cade pe patul de moloz și **se rostogolește o dată pe bandă**, apoi dispare (e ridicat); ciclu ~29 s | urcarea tehnică a pistei, **în întuneric**, cu linie de ales la stâlpi; **reuse** `RockfallHazard` în modul cu traseu (`Path3D` de 12 m, zero cod — memoria `rockfall-traseu-path3d`). Blocul = strivire 3 s (contractul clasei). Panta **11,6%** măsurată cu ProbeLayout | 7 m / 16 m |
| **E** | 0.56–0.64 | **Cariera de sus** — ieșirea din portal pe cea mai înaltă terasă (+45): **dezvăluirea** — pe dreapta, fără bermă, tot amfiteatrul: gradonii, bălțile turcoaz, piazzale-ul cu mașinile mici, camionul urcând; două S-uri cu **concavitatea spre gol** ca fundul să intre în cadru prin față (memoria `masoara-inainte-nu-langa`); pe stânga, blocul-semn al carierei (un bloc uriaș cu fața șlefuită, fără text), mașina de forat, stive | **vârful vizual**; niciun hazard — respiro după galerie. Cădere = repunere ~2 s | 7 m |
| **F** | 0.64–0.70 | **Ponti di Vara** — viaductul de cărămidă cu arce de marmură peste cheiul torentului (30 m gol, 25 m adâncime, pârâu alb-gri jos): tablier de **6 m**, fără parapet, berme scurte la capete; **camionul nr. 2** vine din față pe pod (aceeași buclă, defazat), deci ori treci înainte, ori aștepți la cap, ori te lipești de margine | **punctuația pistei**: singurul loc unde golul e sub roți. **Reuse** `TrackChannel` cu `static_deck`, `jump = false`, `build_towers = false` (tablierul) + GLB-ul arcelor sub el (decor); `RespawnZone` pe chei. Calibrare: cădere ≈ 2 s ≈ 2 poziții; așteptare camion ≈ +3 s | 6 m |
| **G** | 0.70–0.90 | **Ravaneto-ul și Colonnata** — coborâre rapidă (4%) pe moloz crem-gri (**grip lateral 0,9×**, pulbere bej în spatele roților), peretele de deșeu urcând pe dreapta, **pădurea de castani cu ginestra galbenă** și **satul** pe versantul din stânga (case de piatră gri-cald, țiglă, turnul bisericii, la 120–160 m); la **0.80**, **via di lizza**: un jgheab drept de moloz coboară versantul din dreapta și **taie drumul în diagonală**; pe el, la ~41 s, **sania de lemn cu un bloc de 2 m** alunecă în jos (clopot de avertizare 2 s înainte), traversează banda și se oprește pe platforma de jos, în stânga; apoi „urcă” nevăzută | **hazardul-semnătură nr. 2**, cel istoric: fereastră de timing pe cea mai rapidă porțiune a turului (presiune înainte de tunel și linie). **Reuse** `RockfallHazard` cu traseu + un flag nou `roll_model = false` (sania **alunecă**, nu se rostogolește — 3 linii, §3). Contact = ghiont lateral ≈ +1 s; așteptare ≈ +2 s. Contrast: crem de moloz lângă verde-cald și galben de ginestra — **aici se decide dacă pista citește „vară”** (§6, §7 pasul 0) | 9 m |
| **H** | 0.90–0.96 | **Tunelul Marmifera** — portal de piatră cu arc, tunel de 45 m lat cât un vagon (6,5 m), întuneric (`CameraZone` scurtă, tavan 7 m), șine vechi îngropate în asfalt (decal), apoi ieșirea direct în lumina piazzale-ului; 60 m până la linie | contrast lumină/întuneric/lumină înainte de linie (rolul spărturii Lerai la Serengeti); fără hazard — toată presiunea a fost pe G | 6,5 m |

**Ritmul turului:** piazzale (respiro, cupa) → gradoni (linie: camionul în
ac, de două ori) → fund (decizie: derrick sau baltă; grip scăzut) → galerie
(urcare tehnică, întuneric, stâlpi, blocul) → cariera de sus (dezvăluire,
respiro) → pod (punctuație, camionul 2) → ravaneto (viteză, sania) → tunel
(întuneric scurt) → piazzale.

**Ceasuri care nu împart durata turului** (lecția Stromboli): cupa **7 s**
(ciclul implicit al clasei), bucla camioanelor **~110 s** cu două camioane
defazate la 0,5 → o întâlnire la ~55 s, **în alt loc la fiecare tur**;
derrick-ul **23 s** pe rotație (două traversări), blocul **~29 s**, sania
**~41 s**. Niciunul nu e multiplu de ~72.

## 3. Hazarduri și mecanici (ce e nou pentru motor)

Acoperirea claselor din `ref_notes/sisteme.md` §3:

| clasă (Ignition) | aici |
|---|---|
| teatru | mașinile de fir cu volantul și jetul, ferăstrăul-lanț, pulberea din spatele roților, lămpile din galerie, clopotul saniei |
| frecare | fundul ud (marmettola), marginea bălții, molozul ravaneto-ului (grip lateral 0,9×) |
| oprire | **nu** (deliberat: trenul e la Machu Picchu / Transfăgărășan; aici nimic nu te ține pe loc 12 s) |
| sabotaj de control | **nu** (vârtejul e al Serengeti; §8) |
| aruncare / îmbrânceală | camionul în ac (împins spre exterior), blocul derrick-ului (învârtit), sania (ghiont), blocul basculat (strivire 3 s) |
| **poartă de timing / linie** | cupa excavatorului (timing), stâlpii din sală și acul cu camion (linie) |

| mecanică | pe scurt | ce cere în cod |
|---|---|---|
| **Camioanele de marmură** (B, F) | două corpuri grele pe **aceeași buclă `Path3D`** (terasele B în sens invers cursei, podul F, un drum de serviciu nevăzut care le închide bucla prin spatele carierei de sus), ~8 m/s, defazate 0,5; în ac, cel de pe partea ta te **împinge spre exterior** (botul oblic + `shove`), pe pod îți ia banda | **reuse** `BusHazard` (`scenes/hazards/bus_hazard.gd`, extinde `PathMover`): `nose_side`, `nose_angle_deg`, `apex_outer_m`, `apex_radius_m`, `shove`, `side_accel` — contractul Machu Picchu „nu te oprește, te împinge”. Două instanțe pe aceeași curbă cu `phase` 0,0 / 0,5 (`PathMover.phase` există). Model: `quarry_truck.glb` (§5). **Zero cod.** De verificat cu ProbeRace: AI-ul în ac cu camionul (Machu Picchu a validat autobuzul pe serpentine, dar acolo venea din spate; aici vine din față) |
| **Cupa excavatorului** (A) | excavator parcat pe stânga, cupa coboară peste banda stângă: jos 2,5 s, urcă 1 s, sus 2,5 s, coboară 1 s | **reuse** `ExcavatorHazard` (`scenes/hazards/excavator_hazard.gd`, `StaticBody3D`): `period` 7, `raise_angle` 0,55; cere în GLB un nod **`arm`** copil al lui **`body`** (contractul din `_ready`: `find_child("arm")`, AABB-ul corpului fără braț). Prin `HazardMarker` kind `EXCAVATOR`. **Zero cod.** Prima pistă care îl folosește — AI-ul vede un `StaticBody3D` care apare și dispare: **ProbeRace la început**, pe `[blocaj]` (memoria `zero-repuneri-ascunde-blocajul`) |
| **Derrick-ul cu bloc** (C) | catarg lângă drum, braț de ~13 m, blocul atârnat la 0,6 m de sol traversează drumul de două ori pe rotație (23 s), 4 m/s la capăt; contact = învârtit (spin vizual) + ghiont pe tangentă, nu zid | **reuse** `CraneHazard` (`scenes/hazards/crane_hazard.gd`): pivotul = înălțimea turnului din GLB, `hook_radius` 13, excepția de coliziune `clear_seconds` (memoria `HazardThrow`). Model `derrick.glb` cu catargul de **16 m** (nu 22 ca la Chongqing — pivotul coboară cu el) + `marble_block_hooked.glb` ca sarcină. **Zero cod** dacă `tools/probe_cq_dims.gd` confirmă cotele pe modelul nou |
| **Scurtătura prin baltă** (C) | ramură de 5 m prin marginea bălții, apă 30 cm, 0,6×, stropi albi | **reuse** `TrackBranch` (`wet = true`, `speed_factor` 0,6, `surface` apă) + apa locală ca la lacul Magadi (Serengeti G) — **opacă, lăptoasă**, deliberat (nu e defectul din `apa-iluminata-v12`: marmettola chiar e opacă); **zero cod** |
| **Fundul ud** (C) | pulbere udă pe 0,27–0,39: grip scăzut, stropi | **reuse** `custom_wet_ranges` (`TrackFromPath`); **zero cod** |
| **Blocul basculat** (D) | telegraph 2 s (pernele se umflă, sunet), blocul informe de 3 m cade pe patul de moloz și se rostogolește o dată pe bandă, dispare, pauză ~24 s | **reuse** `RockfallHazard` în modul **cu traseu** (`Path3D` de 12 m sub `HazardMarker`, memoria `rockfall-traseu-path3d`); blocul e **informe** (nu cub), deci rostogolirea „unghi = distanță / rază” citește corect. Strivire 3 s = contractul clasei. **Zero cod** |
| **Stâlpii din sală** (D) | doi stâlpi de 3 × 3 m pe carosabilul de 16 m, decalați | geometrie + coliziune din `DecorManual` (`world_prop`, memoria `decor-manual-coliziune`); AI-ul: waypoint-urile ocolesc stâlpul (memoria `obstacol-pe-drum-poate-fi-gimmick`: AI-ul nu vede decor static — se verifică cu ProbeRace, nu se presupune). **Zero cod** |
| **Sania de lizzatura** (G) | sania cu bloc coboară jgheabul (30°) și taie drumul în diagonală, 6–7 m/s pe drum, se oprește jos; clopot 2 s înainte; ciclu ~41 s | **reuse** `RockfallHazard` cu traseu + **nou, mic**: `roll_model: bool = true` — pe `false` modelul nu se rotește cu distanța (o sanie care se rostogolește ar fi absurdă). ~3 linii în `_physics_process`. Ghiontul lateral al clasei (mai mic decât al barierei mobile) rămâne. Alternativa `PathMover` în `BUCLA` a fost respinsă: la capătul curbei se teleportează la vedere; `RockfallHazard` dispare la capăt și reapare după `pause`, exact ce trebuie |
| **Galeria și tunelul** (D, H) | întuneric, tavan de 18 m în sală / 10 m în spirală / 7 m în Marmifera | **reuse** `CameraZone` cu `ceiling` + `ceiling_dist` + `darkness` (memoria `camera-zone-tavan-per-sala`); tubul ca la Fiordland / Transfăgărășan (masiv `TerrainPeak` + portaluri GLB). **Ce nu există azi**: o **sală** — lărgirea tubului la 16 m pe 80 m cu tavan la 18. Două opțiuni, decizia la pasul 1 din §7 după ce se citește builderul tunelului: (a) parametru de lărgire pe interval în builder, (b) GLB hero cu coliziune (`world_prop`) pentru sală, tubul rămâne al builderului |
| **Podul** (F) | tablier static de 6 m peste 30 m de gol, fără salt | **reuse** `TrackChannel` (`static_deck = true`, `jump = false`, `build_towers = false`, `build_ships = false`, `deck_material_class` cărămidă/marmură) + `ponti_di_vara.glb` (arcele) ca decor sub tablier + `RespawnZone`. **Zero cod** |
| **Bermele** (B, F) | dâmburi de moloz de 0,6 m la vârful acelor și la capetele podului, în pantă spre drum | `DecorManual` cu `rock_cluster.glb` pe clasa de marmură + coliziune; **punctuație**, nu regulă (§2.0). **Zero cod** |
| **Teatrul** | volantul mașinii de fir (`AnimationPlayer` în GLB), jetul de apă (particule reuse din spray, memoria `strop-apa-particule`), pulberea din spatele roților (urmele / praful existent pe pulbere), lămpile (`HazardLamp`, fără material nou), clopotul saniei (audio) | **zero cod** |

Calibrare (sisteme.md): cupa ≈ +1,5 s, camionul în ac ≈ +2 s (împins în
bermă), derrick ≈ +1,5 s (învârtit), baltă cu turbo ≈ −1,5 s / fără ≈ +2 s,
blocul basculat ≈ +3 s (strivire), camionul pe pod ≈ +3 s (așteptare) sau
cădere ≈ 2 s, sania ≈ +1 s ghiont / +2 s așteptare, cădere de pe terasă pe
cea de jos ≈ +1,5 s (linie pierdută, nu repunere).

**Regula „AI onest” și camioanele:** AI-ul vede aceleași `AnimatableBody3D`
ca jucătorul (anti-blocaj), fără informație despre fază. Dacă ProbeRace
arată AI-ul intrând în camion în > 50% din întâlnirile din ac, se pune un
`HazardMarker` de „ține interiorul” pe waypoint-urile acului (mecanismul
`custom_lane_corridors`), nu se trișează cu viteză.

## 4. Paleta și lumina (fără slot nou)

**Regula v0.2: niciun slot de zăpadă.** `FOAM_WHITE` 22 (zăpada Baikal)
nu apare pe nicio suprafață a pistei; `MARBLE_GREY` 29 (gneisul Fiordland,
cenușa Stromboli) apare **doar** ca al doilea slot al fețelor în umbră și
al molozului, niciodată singur pe o față mare. Verificabil pe GLB-uri și
pe teren cu `verify_glb.py` / `probe_decor` (aria slotului, memoria
`aria-slotului-spune-cat-nu-ce`).

**Marmura** nu e un slot, e **lumină pe un crem**. Baza fețelor tăiate și a
blocurilor: `CORAL_SAND` 19 (alb-crem, slotul solului din Cappadocia) ca
albedo, cu `MARBLE_GREY` 29 pe jumătatea de jos a fețelor (patina + AO
copt în vertex color — două sloturi pe același corp = nod copil, memoria
`benzi-vertex-color-bisect`; `ruptura-accente-doua-sloturi`: se măsoară
intervalul de valoare dintre ele). Identitatea vine dintr-o **clasă
triplanară nouă, `carrara_marble`**, pe dala **existentă**
`olkhon_marble.png` (deja marmură cu vene — e dala lui `mv_cap`, `granite`,
`mv_sandstone`), cu tenta calculată invers din lumina temei (metoda
`tf_stone`) ca să iasă **crem-auriu ≈ (232, 214, 178) la soare**; peste ea,
**dungile orizontale de fir** la ~0,7 m pe fețele verticale (trim-ul de
rocă cu benzi, orientat orizontal — mecanismul stratificației de la
Cappadocia) și **dârele de rugină** (`LARCH_RUST` 27, #A8683A, în vertex
color sub cotele de scurgere — mecanismul dungilor ude de la Fiordland, cu
alt slot). Zero texturi noi. Un asset de marmură nu aduce textură proprie;
**toată** cariera e o singură clasă.

**Praful** (tot ce e orizontal): `ground_tint` bej-cald calculat invers ca
să iasă ≈ (196, 176, 142) după randare — familia `SAND_SHADOW` 2 / `mv_cap`
(#B9A08C), **nu** `SAND_LIGHT` 0 (prea galben, ar fi deșert). Drumul pe
clasa de sol a prafului (`custom_dirt_ranges`), nu asfalt. Ravaneto:
același `ground_tint` tras 30% spre `MARBLE_GREY` — crem-gri, nu alb.

Ținta măsurabilă (memoria `suprafata-palida-e-lumina`): pe captura de joc,
fața la soare a unui gradon **V ≈ 0,85–0,92 cu H ≈ 30–45°** (crem-auriu),
fața în umbră **V ≈ 0,50–0,60 cu H ≈ 200–230°** (gri-albăstrui). Două
contracte: **ΔV ≥ 0,28** între fețe (sub 0,2 pista e o pânză plată, se
intervine la soare/ambient) și **H cald pe fața luminată** (H < 60° pe ≥
80% din pixelii feței; dacă iese neutru, tenta clasei se încălzește, nu
slotul). Cinci eșantioane pe cinci gradoni, nu unul (memoria
`o-captura-nu-e-un-verdict`, `caseta-de-masura-exclude-defectul`).
Comparația de **anotimp** e la §7 pasul 0.

**Mașinile**: galben-spălăcit = `DRY_VEGETATION` 13 (#AF9F4E, olivul uscat
citește ca vopsea de utilaj decolorată de soare) + `RUST_METAL` **10**
(bene, lanțuri, cârlig, cabine vechi) + `VOLCANIC_BLACK` 20 (cauciuc,
hidraulică, șenile) + praful de pe ele pe `SAND_SHADOW` 2. **Nu**
`CAR_YELLOW` 16: regula style_bible §1 (sloturile 14–16 sunt ale mașinilor
de joc) ține aici fără excepție — un excavator galben saturat de 3 m ar fi
cel mai saturat obiect din cadru, lângă Taxiul galben. Lămpile de
avertizare și **marcajele de pe blocuri** (dungă de vopsea de 10 cm):
slotul de lavă (Stromboli, `burner`), excepția panglicilor Baikal — sub un
metru pătrat în total.

**Apa**: bălțile de marmettola pe `REEF_SHALLOW` 17 amestecat spre
`CORAL_SAND` 19 în shader-ul de apă existent, **opacitate mare, mată,
`water_dim` ridicat** — o baltă de calcit nu reflectă pereții, le ia
culoarea. Verdictul de la Okinawa (`apa-iluminata-v12`: pata gri = pânză
opacă) nu se aplică: aici opacul e **corect**; ce se măsoară e că balta
rămâne **turcoaz**, nu gri (saturație pe masca bălții ≥ 0,25).

**Verdele și galbenul**: castanii pe clasa `tf_beech` (Transfăgărășan,
#5E8A3A verde cald) cu modelele `beech_tree_a/b.glb` — coroana castanului
e destul de aproape de a fagului la 100 m; `ginestra_bush.glb` (Stromboli,
flori galbene) pe muchiile neexploatate și pe marginea ravaneto-ului;
tufele de pe muchii `TROPICAL_GREEN` 21. **Satul**: pereți pe `tf_stone`
(gri neutru #8E8C82, trasă 10% spre cald), **acoperișuri pe `roof_tiles`**
(țiglă — abatere asumată, real ardezie), lemnărie `LOG_DARK` 28.
**Viaductul**: cărămida pe `roof_tiles` cu arcele de marmură pe
`carrara_marble`.

**Cer și lumină** (șablonul temei `monumentvalley`, adaptat): `sky_top`
albastru adânc (#3F79C9), `sky_horizon` piersică palid (#F1D3AA); soare
**~22°**, `sun_color` #FFD2A0, `sun_energy` ~1.25; `ambient_color`
albăstrui (#A9BEDD), `ambient_energy` ~0.38 → raport ~3.3 (memoria
`geometria-fara-lumina-e-invizibila`); `fog` **în familia prafului**
(bej-cald palid, #D9C4A6 — memoria `ceata-in-familia-solului`), `fog_end`
300, `fog_begin` 120 (amfiteatrul are ~180 m — totul înăuntru e clar).
Soarele intră **prin deschiderea amfiteatrului**: la 22°, un perete de 45 m
aruncă umbră pe ~110 m, deci un bol închis ar avea fundul albastru; bolul
e **deschis spre soare** (cum sunt carierele reale, deschise spre vale) și
fundul C stă în lumină cel puțin pe bălți și pe banda de sub derrick.
Azimutul soarelui **provizoriu**, se remăsoară pe traseul real (memoria
`azimutul-soarelui-fata-de-drum`): cerința e că pe B și E fețele gradonilor
alternează lumină/umbră, fundul C are soare pe bălți, iar în sală puțul de
lumină cade pe bandă. **Umbre pornite**, `shadow_distance` 120 (terasa de
sus aruncă umbră pe cea de jos — memoria `umbre-exista-dar-cascada-e-scurta`:
casterii sunt la ≤ 30 m, deci 120 ajunge).

## 5. Assets (schiță — lista completă după ProbeLayout)

### 5.1 Teren și suprafețe (cod, clase de textură)

- gradonii și pereții: teren cu `scarp_tint` pe pantă (mecanismul Machu
  Picchu / Fiordland) + clasa `carrara_marble` (venele + dungile de fir);
  terasele = plane prin `custom_step_ranges`? **Nu** — terasele sunt
  **drumul însuși** (cote constante pe segment), iar fețele verticale dintre
  ele ies din `custom_ravines` / `cliff_face` cu panta la 90°; se verifică
  cu `ProbeBuried` că nicio terasă nu e îngropată (memoria
  `carosabil-ingropat-garda`)
- drumul: pulbere bej bătătorită (`custom_dirt_ranges` pe tot turul, clasa
  de sol **nu** asfalt, ca lateritul de la Serengeti), ud pe C, asfalt doar
  pe pod și în Marmifera
- ravaneto: teren pe `ground_tint`-ul prafului tras spre `MARBLE_GREY`
  (crem-gri, §4) cu scatter de moloz (`rock_cluster.glb`, `scree_cone.glb`
  din Transfăgărășan remapate pe `carrara_marble`), grip lateral 0,9× pe
  interval; **fără** `FOAM_WHITE`
- bălțile: apa locală (Serengeti G), opacă; cheiul podului: `TrackChannel`
  cu pârâu alb-gri jos

### 5.2 Hero (unice)

| piesă | consumator (din cod citit, §5.6) | contract |
|---|---|---|
| `quarry_truck.glb` — basculantă grea cu 2 blocuri în benă, 3,6 × 3 × 7 m | `BusHazard` (`model`, `PathMover`) | botul pe −Z, originea la sol, centrat |
| `quarry_excavator.glb` — excavator pe șenile cu furcă pentru blocuri, 70 t, ~4 m | `ExcavatorHazard` | noduri **`body`** și **`arm`** (copil al lui `body`), pivotul brațului la originea lui `arm`, cupa spre −Z |
| `derrick.glb` — catarg A-frame de **16 m** + braț + cablu | `CraneHazard` | înălțimea catargului = pivotul; brațul pe −Z până la 13 m (`hook_radius`) |
| `marble_block_hooked.glb` — bloc 2,5 m în chingi, cu cârlig | `CraneHazard` (sarcina) | originea în punctul de agățare |
| `lizza_sled.glb` — sanie de bârne cu bloc de 2 m și funii | `RockfallHazard` (`roll_model = false`) | originea pe talpă, lungimea pe −Z |
| `wire_saw.glb` — mașina de fir diamantat: șasiu pe șine, volant de 1 m, fir, jet | decor cu `AnimationPlayer` (volantul) | nod `flywheel`; animație `Spin` |
| `chain_saw_crawler.glb` — ferăstrău-lanț pe șenile, braț în perete | decor static | — |
| `drill_rig.glb` — mașina de forat, mast de 6 m | decor static | — |
| `ponti_di_vara.glb` — viaduct cu 3 arce de cărămidă, pile de marmură, 30 × 25 m | decor sub tablierul `TrackChannel` | fără coliziune proprie (tablierul o are) |
| `marmifera_portal.glb` — portal feroviar de piatră cu arc, 7 × 6,5 m | portalurile tunelului H | ca `rock_tunnel_portal.glb` |
| `gallery_portal.glb` — portal tăiat drept, 8 × 8 m, cu lampă | portalurile galeriei D | — |
| `gallery_pillar.glb` — stâlp de marmură 3 × 3 × 18 m, fețe tăiate | `DecorManual` cu coliziune (`world_prop`) | originea la bază |
| `museum_set.glb` — vagonet pe șine cu bloc, roata de fir elicoidal, sanie veche (3 noduri) | decor A | variante `keep_variants` (memoria `decor-manual-din-cod`) |
| `colonnata_church.glb` + `colonnata_house_a/b/c.glb` — turn cu clopotniță 14 m, case de piatră cu **țiglă** (abatere v0.2; real ardezie) | decor G, flanc | pe `tf_stone` / `roof_tiles` |
| `quarry_sign_block.glb` — blocul-semn cu fața șlefuită, fără text | decor E | — |

### 5.3 Kit de carieră (modular, statistice)

`marble_block_a/b/c.glb` (1,5 / 2 / 3 m, cuburi cu urme de fir — **12
triunghiuri fiecare**, cel mai ieftin kit din joc), `block_stack_a/b.glb`
(stive 2–3 înalte), `block_informe_a/b.glb` (bucăți neregulate — și
modelul blocului basculat), `rubble_pile_a/b.glb`, `safety_berm.glb`
(dâmb 6 m lung, în pantă spre drum), `work_lamp.glb` (trepied + reflector,
`HazardLamp`), `cable_reel.glb`, `water_tank.glb`, `fuel_tank.glb`,
`office_container.glb`, `quarry_sign_a/b.glb` (chevron, glif de bloc
suspendat, **fără text**), `pipe_run.glb` (conducte de apă pe terase).
Reuse direct: `beech_tree_a/b.glb` (castani, clasa `tf_beech`),
`ginestra_bush.glb` (Stromboli — ginestra galbenă, semnul verii),
`rock_cluster.glb` / `scree_cone.glb` (moloz, clasa `carrara_marble`),
`kamaz_truck.glb` (camionul parcat din A, remapat pe 13/10),
`retaining_wall_*.glb` (ziduri de sprijin la rampe), `road_works.glb`.

### 5.4 Fundal (`horizon_class`)

Crestele Apuanilor: 2–3 vârfuri de calcar crem-gri în ceața aurie, cu
**pete deschise de ravaneto pe flanc** (nu calotă albă — calota = zăpadă =
Alpi; petele pe `CORAL_SAND`, nu pe `FOAM_WHITE`), la 200–300 m, sub
`fog_end`; pădure verde-cald la bază. `cast_shadow` OFF pe orizont
(memoria `caster-departat-fura-umbra`). Scări subunitare ca la Fiordland.

### 5.5 Sunet

Zumzetul firului diamantat (ton continuu, se apropie/depărtează pe B și
E), jetul de apă, motorul diesel al camionului (dopplerat, vine spre
tine), scrâșnetul cupei, clopotul saniei (2 s înainte), pernele
pneumatice (telegraph-ul blocului), ecoul din galerie (reverb în
`CameraZone`), pulberea sub roți pe ravaneto. Fără voci.

### 5.6 Trecerea de contracte (de făcut la pasul 1 din §7, memoria `brief-cere-glb-cod-il-face-deja`)

Înainte de primul GLB, un agent de explorare citește **consumatorul**
fiecărei piese din §5.2 și dă verdictul ARE CONSUMATOR (fișier:linie) /
decor pur / CONFLICT. Trei locuri unde codul **ar putea face singur**
piesa, de verificat: (1) `TrackChannel` construiește tablier **și
turnuri** — cu `build_towers = false` arcele vin din GLB, dar dacă builderul
pune și pile, GLB-ul le dublează; (2) `TunnelSignalHazard` / builderul
tunelului de la Fiordland construiește **tubul și portalurile** — galeria D
și tunelul H poate n-au nevoie de `gallery_portal.glb` / `marmifera_portal.glb`
deloc; (3) `ExcavatorHazard` are placeholder procedural dacă GLB-ul nu are
`arm` — un model fără nodul ăsta trece `verify_glb.py` și nu mișcă nimic.

## 6. Bugete

- triunghiuri: raportate, fără plafon; **blocurile sunt cuburi** (12 tri),
  deci kitul e aproape gratis; castanii ~120 × < 400 tri; mașinile 2–4k
  fiecare, 8–10 pe pistă; `radial_segments` pe orice primitivă din cod
- materiale: atlas + `carrara_marble` + `tf_beech` + `tf_stone` + clasa de
  sol (pulbere) + ud (decal) + apă (bălți) + `roof_tiles` (viaduct) +
  urme/praf → estimat **~16–18**, plafon **≤ 30**. Comparativ: Machu Picchu
  19, Cappadocia 21, Fiordland ~24, Serengeti 31, Chongqing 32 — ar fi **a
  doua cea mai ieftină pistă din joc** (memoria `plafon-masurat-nu-presupus`:
  plafonul nu e alocare; un material nou se cere explicit în raport)
- fizică: 2 camioane + derrick + excavator + 2 `RockfallHazard` + 2 stâlpi
  + apă locală — ieftin. Riscul pistei **nu e GPU** (puțină vegetație,
  zero transparențe mari), e **vizual**: (1) **albul care arde** —
  `suprafata-palida-e-lumina`; (2) **monocromia** — `monocromia-se-masoara-
  dupa-remap`: 45% din cadru e un singur material; (3) **„pare iarnă”**
- **umbre pornite** (umbra gradonului) — dacă device-ul nu ține 60 fps,
  `shadow_distance` 120 → 90, apoi stins
- **de verificat devreme:** (1) captura `--driver` de pe E: se vede fundul
  cu bălțile, sau se vede terasa de sub tine? (2) **testul de anotimp**,
  de **două ori**: pe mostră, înaintea traseului (§7 pasul 0 — acolo se
  decide dacă locul rămâne) și pe pista reală, la pasul 8: 5 capturi de pe
  B, G, E date unui critic orb, amestecate cu capturi din Baikal și
  Transfăgărășan, cu întrebarea „care sunt iarnă, și ce fel de loc e
  fiecare?” — dacă > 1 din 5 capturi Carrara ies „zăpadă” / „iarnă”, se
  intervine pe lumină și pe praf (mai cald), pe G (castanii și ginestra
  mai aproape), **nu** pe geometrie; (3) contrastul soare/umbră pe gradoni
  ≥ 0,28 și H cald pe fața luminată (§4), 5 eșantioane; (4) AI-ul vs cupa
  excavatorului și vs camionul din față, pe `[blocaj]`, 16 seed-uri; (5)
  blocul basculat **chiar ajunge pe bandă** cu hazardul în stare activă
  (memoria `garda-cu-numele-gimmickului`: contractul ca cifră față de
  bandă — centrul blocului la ≤ 1,5 m de axa benzii drepte la frac 0,48)

## 7. Ordinea de construcție

0. **Testul de mostră (v0.2, înaintea oricărui traseu — aici se decide
   dacă locul rămâne).** O scenă sintetică de ~80 m (`tools/SvCarraraMostra`,
   tiparul `ProbeCavecam`): trei gradoni de 7 m cu fețe verticale pe clasa
   `carrara_marble` + `CORAL_SAND`/`MARBLE_GREY`, praf bej pe terase, un
   `kamaz_truck.glb` remapat pe 13/10, două `beech_tree_a.glb` pe `tf_beech`,
   o `ginestra_bush.glb`, o baltă opacă turcoaz, lumina și ceața din §4,
   camera de joc reală (`--gamecam`, memoria `verifica-cu-parametrii-lui`).
   Cinci capturi (dimineață de drum drept, ac de păr, de sus de pe terasă,
   în umbra peretelui, cu balta în față) × **două variante**: A = §4 așa cum
   e scris; B = §4 cu soarele la 38° și praful mai neutru (varianta „mai
   aproape de realitate”, ca martor). Capturile se amestecă cu 5 din Baikal
   și 5 din Transfăgărășan și merg la un critic orb cu două întrebări:
   „care sunt iarnă?” și „ce fel de loc e fiecare?”. **Contractul**: ≤ 1
   din 5 capturi Carrara-A citite ca iarnă/zăpadă, și ≥ 3 din 5 citite ca
   „carieră / mină / piatră tăiată”. Tot acolo se măsoară ΔV și H-ul feței
   luminate din §4. Dacă A trece → pasul 1. Dacă A pică și B nu e mai bun →
   locul se schimbă (§8: Rio Tinto / Bingham), și brief-ul se rescrie
   păstrând §2–§3. Cost: câteva ore, zero traseu, zero kit.
1. **Trecerea de contracte (§5.6) + sonde tehnice înaintea traseului**
   (`tools/ProbeCarrara.tscn`): (a) două `BusHazard` pe o buclă `Path3D`
   care taie sensul cursei de două ori, `phase` 0 / 0,5, 8 AI, 16 seed-uri:
   `[blocaj]` în ac, contacte frontale, AI-ul ia interiorul? (b)
   `ExcavatorHazard` pe drum drept cu 8 AI: se opresc sub cupă? trec pe
   banda liberă? (c) `RockfallHazard` cu `roll_model = false` pe un jgheab
   de 30° care taie un drum de 9 m în diagonală: sania ajunge pe bandă,
   nu plutește (memoria `rockfall-traseu-path3d`: cota din raycast), 4
   mașini lovite lateral — ghiontul e al clasei; (d) `CraneHazard` cu
   catarg de 16 m: `probe_cq_dims` pe `derrick.glb`, blocul la 0,6 m de
   sol, trecere prin el = învârtit, nu oprit (contractul 22 → 1,1 m/s e
   **eșecul**, nu reușita); (e) decizia **sală**: citit builderul tunelului,
   ales (a) sau (b) din §3.
2. `Track23.tscn` din `TrackFromPath` (`tools/gen_carrara_route.py`, schela
   `gen_fiordland_route.py`: pas 12 m, viraje > 90° pe arc), temă `carrara`
   (doar lumina, cerul, ceața, solul), traseul din §2, `custom_ravines` pe
   amfiteatru și chei, `TerrainPeak` pentru masivul galeriei și al
   Marmiferei, `custom_wet_ranges` pe C, `custom_dirt_ranges` pe tot
   turul minus pod/tunel. ProbeLayout: urcarea D < 13%, rampele B < 13%,
   terasele la ≥ 2·half_width lateral și **`STACK_MIN_DY` 14 m** dacă
   vreun segment trece peste altul (nu ar trebui — galeria urcă prin
   munte, nu peste pistă). `GameState`: Track23 = **indexul 15**
   (`--track=15` la snapshot/probe_race, `--track=23` la probe_decor/
   probe_manual — memoria `probe-decor-numar-de-scena`). Zidul lumii la
   420 m de centroid și plasa de mare la −7 (memoria `ziduri-invizibile-
   ale-lumii`): amfiteatrul are fundul la +2, deci `custom_sea_level_offset`
   coboară sub el.
3. **ProbeRace la început, nu la final** (memoria
   `proberace-la-inceput-nu-la-final`): 8 mașini, 16 seed-uri, fără decor —
   ajung la linie? Galeria (7 m, 11,6%) nu face coadă la mașinile grele?
   Citit pe `[blocaj]` / lent / invers, nu pe repuneri.
4. Sonda de feel: piazzale → gradoni → fund → galerie → cariera de sus →
   pod → ravaneto → tunel, un tur singur. **Captura `--driver` de pe E** (se
   vede fundul?) și **de pe A** (bălțile pe dreapta?). Captura de sus
   adnotată → dioramă (§9) → foaia de assets.
5. Camioanele (hazardul-semnătură nr. 1) + cupa; ProbeRace A/B pe
   distribuții (memoria `proberace-nedeterminism`).
6. Derrick, baltă (ramura), ud, blocul basculat, stâlpii, sania, podul,
   bermele, `CameraZone`-urile.
7. Hero-assets: camionul, excavatorul, derrick-ul, sania, viaductul,
   portalurile, stâlpii, mașina de fir.
8. Kit de carieră, castanii și satul, fundal, teatru, sunet; probe_decor,
   **testul de anotimp**, verdict la volan.

## 8. Lecții aplicate anticipat, și ce a fost respins

- **Frustumul decide:** amfiteatrul se coboară și se urcă, nu se privește;
  dezvăluirea e la ieșirea din galerie, câștigată prin 43 m de urcare în
  întuneric (`world_design.md`: „urcarea e ce transformă un decor într-un
  moment”).
- **Urcarea prin munte, nu peste pistă.** O spirală care se suprapune cu
  sine (coborârea pe gradoni sub urcarea pe gradoni) ar fi cerut
  `custom_overpass_ranges` + 14 m de separare + relocarea de etaj la
  repunere (`chongqing.md` §7.1). Galeria dă aceeași verticalitate cu zero
  suprapunere, și e **reală** (Ravaccione).
- **Hazarduri distincte mecanic, unul per loc:** poartă de timing (cupă),
  linie cu corp greu (camion în ac), pendul (derrick), frecare cu decizie
  (baltă), cădere + strivire (bloc), linie statică (stâlpi), punctuație
  (pod + camion 2), fereastră de timing cu poveste (sanie). Nimic nu
  dublează trenul (oprire 12 s), avalanșa (eveniment rar cu drag), vârtejul
  (sabotaj), semaforul (decizie pe roșu) sau caruselul (butuc pe drum).
- **Trei hazarde orfane primesc casă:** `ExcavatorHazard`, `CraneHazard`
  în afara Chongqing-ului, `RockfallHazard` ca sanie. Costul e **un flag**.
- **Abatere asumată de la realitate (v0.2, decizia dezvoltatorului):**
  Carrara e în realitate alb-gri, și de pe coastă pare înzăpezită în
  august. La noi e **caldă**: crem-auriu pe fețele tăiate, bej pe praf, oră
  aurie, rugină, țiglă, ginestra. Motivul e scris în antet: albul ar fi
  stat pe sloturile zăpezii, iar compoziția alb + gri + verde e deja a
  trei piste. E aceeași regulă ca la umbre în CLAUDE.md: abaterea se
  scrie, nu se strecoară; fidelitatea e față de **gestul** locului (treapta
  tăiată, firul, camionul, sania), nu față de temperatura lui de culoare.
- **Fără slot nou de paletă și fără slot de zăpadă.** Marmura e
  `CORAL_SAND` 19 + `MARBLE_GREY` 29 (doar în umbră) + o clasă triplanară
  pe dala existentă `olkhon_marble.png`; `FOAM_WHITE` 22 **nu apare**. Dacă
  venele nu ies, se îngroașă detaliul în clasă, nu se cere slot.
- **Albul e lumină, și culoarea se decide pe mostră:** contractul de
  contrast soare/umbră și de nuanță caldă (§4) se măsoară pe scena de
  mostră (§7 pasul 0), înainte de traseu; **testul de anotimp** cu martor
  din Baikal și Transfăgărășan e garda împotriva „Alpii 2”, și e singura
  cu drept de veto asupra locului.
- **Berma e punctuație**, nu parapet (`04_coasta.md`): la ace și la pod.
  Pragurile laterale > 0,3 m sunt ziduri — berma e în pantă spre drum.
- **Respins, cu motiv:** **sirena și explozia** (firul diamantat a înlocuit
  explozivul la Carrara; și ar fi a patra avalanșă din joc după Alpi,
  Fiordland, Transfăgărășan — reuse-ul e bun, dublarea gimmick-ului nu);
  **tunel cu camion din față pe un sens** (e exact semaforul Fiordland);
  **marea la orizont** (dincolo de `fog_end`; adâncimea e amfiteatrul);
  **galben Caterpillar** pe utilaje (concurează Taxiul; slotul 13 e
  galben-spălăcit); **statuia / David** în piazzale (kitsch și citește
  Florența, nu Carrara; blocul-semn șlefuit e destul); **firul diamantat
  ca hazard** (taie milimetri pe minut — e teatru, nu mișcare); **conveior**
  (nu există la Carrara; blocurile merg cu camionul); **zăpadă pe
  vârfurile din fundal** (ar confirma confuzia; petele albe sunt ravaneti,
  pe flanc, cu pădure la bază); **a doua scurtătură** (una pe tur ajunge,
  regula „accesibil în 10 s”).
- **Alternativele de loc, dacă mostra pică** (v0.2, puse pe masă la
  rezerva dezvoltatorului, nealese): **Rio Tinto** (Spania — puțul Corta
  Atalaya, rocă ruginie-ocru-galben cu pete verzi de cupru, **râul roșu** ca
  hazard de apă, trenul minier turistic = reuse `TrainHazard`; cea mai
  colorată, dar familia roșu-cald e a Monument Valley); **Bingham Canyon**
  (Utah — cel mai mare puț, terase brun-cafenii, camioane de 400 t care
  fac mașinile noastre jucării lângă o casă; dar tot Utah, lângă Monument
  Valley); **Hambach** (Germania — lignit brun, excavatorul cu roată-cupe de
  96 m, benzi transportoare; vizual perfect „carieră din Ignition”, dar loc
  încărcat politic). Oricare păstrează §2–§3 (puț, gradoni, camioane, pod,
  galerie sau tren) și schimbă §4–§5.
- **Nume și legal:** Carrara, Fantiscritti, Ponti di Vara, Colonnata,
  Ravaccione sunt locuri; **niciun nume de producător** pe utilaje (nici
  Caterpillar, nici Volvo, nici Mercedes), semne fără text, nicio marcă
  de marmură.
- **Cariera (modul de joc) ≠ cariera (de marmură):** `docs/cariera/` e
  modul Carieră. Pista intră în `CareerConfig` doar prin decizia
  dezvoltatorului (§2 din `mod_cariera.md`: regruparea e o editare de
  `.tres`); până atunci, ca Ha Long, **doar cursă rapidă**.

## 9. Prompt pentru ChatGPT (dioramă de referință) — se scrie la pasul 4

Decizia din memoria `diorama-din-geometria-reala` (Serengeti, 6 sep 2026):
imaginea dată pentru dioramă e **captura reală de sus din Godot**
(`snapshot.gd --track=15`) peste care se desenează legenda (POI, culoarea
hazardului, loturile, nordul, scara), **după** ce traseul trece de
ProbeLayout și ProbeRace — nu un plan de propunere. Promptul complet vine
cu v0.2, odată cu captura. Ce e fix de acum, paragraful de stil:

> *Stylized toy-diorama, low-poly, single low golden-hour sun from the
> side with long blue shadows, deep blue sky fading to peach at the
> horizon. A marble quarry amphitheatre cut into a mountain in flat
> terraces: every vertical cut face is warm cream, almost golden where the
> sun hits it and blue-grey in shadow, with horizontal wire-saw stripes
> and rust drip stains; every horizontal surface (terraces, haul roads,
> yard) is warm beige dust with tyre tracks; cream-grey rubble slopes;
> faded-yellow and rusty toy machines (excavator with block forks, dump
> truck with blocks, A-frame derrick swinging a block, wire-saw machine
> with a flywheel and a water jet); stacked marble cubes with small
> orange paint marks; opaque milky turquoise slurry pools on the quarry
> floor; one dark tunnel portal in the cream wall; a brick railway viaduct
> over a gorge; on one flank only, a warm green chestnut forest with
> yellow broom bushes and a small stone village with terracotta roofs and
> a church tower. High summer, golden light: nothing in the image is
> white, nothing reads as snow or winter. No text, no brand names, no
> people. The geometry in the attached top-down capture is mandatory;
> letters are the legend.*
