# Monetizare — modelul, argumentat pro și contra — v0.1 (analiză, nedecis)

> Analiza cerută de dezvoltator pe 13 oct 2026, în locul unui set de documente:
> ce model de monetizare ar funcționa pentru un racer arcade cu mașinuțe, cu
> libertatea de a adăuga mecanici noi. Nimic de aici nu se implementează până
> la deciziile din §11. Cifrele au dată și sursă (§8) și se reverifică la
> fiecare lansare. Nu e consultanță juridică sau fiscală. Monetizarea rămâne
> „Post-MVP” în `CLAUDE.md`; documentul ăsta pregătește decizia, nu o ia.
>
> **v0.1 (13 oct 2026):** analiza din conversație, înclinațiile dezvoltatorului
> marcate ca nedecise, recomandarea coordonatorului.

## 0. Într-o propoziție

Modelul cu cele mai bune șanse e „gratuit de încercat, plătești o dată pentru
toate lumile”, cu mașinile deblocate doar prin joc, personaje și skinuri
câștigate sau vândute, lumi noi ca pachete după lansare, fără interstițiale și
fără upgrade-uri de statistici; reclamele recompensate rămân o opțiune de
v1.1, doar la volum mare.

## 1. Ce vinde jocul, și ce nu

| Activ | De ce contează pentru bani |
|---|---|
| Condusul: fizică întreagă, drift, turbo-resursă, îmbrânceli cu masă | E argumentul de vânzare, dar nu se vede în fișa de magazin; trebuie SIMȚIT, deci jucătorul trebuie să poată încerca înainte să plătească |
| 12 lumi de release, fiecare o dioramă cu gimmick propriu | Unități de conținut recognoscibile și vandabile; cele 4 candidate post-release (Uyuni, Veneția, Petra, Maroc) sunt pachete naturale |
| 6 mașini cu stiluri distincte (viteză / grip / masă) | Identitate, nu scară de putere; scop de deblocare prin joc |
| Cockpit deschis + șofer ragdoll | Personajele sunt vizibile tot timpul: cel mai bun cosmetic |
| Aspect de dioramă stilizată | Se citește ca indie premium (zona Mini Motorways, Alto's), nu ca F2P; reclamele ieftinesc exact asta |
| Zero cont, zero date, zero server | Avantaj de conformitate care dispare la primul SDK de reclame |

Ce NU avem: vopsea sau skin pe mașină la runtime, monedă, cont, online,
live-ops, analytics, cont Apple Developer, device Android.

Constrângerile din `CLAUDE.md` care decid orice trade-off: principiul 1 (fără
items), 4 (mașini = stil, nu upgrade-uri numerice), 5 (AI onest, fără viteză
trișată), 7 (accesibil în 10 secunde, burst play de 2-3 minute, fără sisteme
care blochează jocul).

## 2. Starea din cod (13 oct 2026)

- **Zero monetizare**: niciun SDK, shop, monedă sau concept de blocare; singura
  mențiune e linia Post-MVP din `CLAUDE.md`.
- **Persistență** `ConfigFile` în `user://settings.cfg` și `user://records.cfg`
  — `scripts/autoload/game_state.gd` (`load_settings` 317, `try_record` 230,
  `load_records` 242). Mașina aleasă se salvează ca *index* în `CAR_DATA` (12),
  recordurile pe *numele* pistei din `TRACK_NAMES` (70). Fără versiune de
  schemă, fără `id` pe `CarData` / `TrackInfo`.
- **Garaj**: 6 mașini + tuk-tuk doar ca trafic; panou de butoane text în
  `scenes/main_menu/main_menu.gd`. Culoarea caroseriei vine din UV-urile GLB
  prin materialul partajat (`Palette.apply_world_material`), deci „vopsea”
  înseamnă sistem nou. Singura variantă vizuală: figurina șoferului
  (`driver_model`, 4 variante). Tastele 1-6 schimbă mașina în cursă fără
  verificare de debug (`scenes/race/race.gd`, ~621).
- **Piste**: 15 scene în `TRACK_SCENES` (34), fără listă de release; după
  swap-ul 19→01, 20→08, 21→09 rămân 12. Campionatul = primele 3 piste
  (`CHAMP_ROUNDS` 75). „Monument Valley” e marcă înregistrată
  (`docs/track_briefs/monument_valley.md` §3.1); redenumirea pierde recordurile
  fiindcă cheia e numele.
- **UI**: CURSA RAPIDA / CAMPIONAT / GARAJ / SETARI / IESIRE; IESIRE apelează
  `get_tree().quit()` (`main_menu.gd:41-42`), iar Apple respinge butoane
  explicite de ieșire. Fără Recorduri, Credite, Shop.
- **Export**: `export_presets.cfg` doar pe ramurile `ios/*`, un preset iOS cu
  `bundle_identifier="app.toyracer.dev"` (substituent, permanent după creare),
  fără Android. Primul `.ipa`: 123 MB. Build fără cont Apple Developer
  (Sideloadly, Apple ID gratuit).
- **Evenimente**: `race_finished` / `lap_completed` cerute de `CLAUDE.md`
  există doar în comentarii; fluxul e pe funcții (`race.gd` `_finish_race`
  ~526, `_show_champion` ~579). Orice ofertă, reclamă sau măsurare se agață de
  ele.
- **AI**: `scenes/cars/ai_controller.gd` n-are parametru de dificultate; ținta
  de viteză e `car.max_speed * lerp(1, 0.44, severity)` (549), pe aceeași
  mașină ca a jucătorului; comentariul de la 293 apără explicit principiul 5.
- **Licențe**: `assets/CREDITS.md` are 3 modele CC-BY cu atribuire
  obligatorie, dar jocul n-are ecran de credite; audio sintetizat in-house
  (commit `543830d1`), de confirmat pentru sunetele adăugate după.

## 3. Modelele candidate, pro și contra

| Model | Ce aduce | Ce cere | Conflict cu principiile | Verdict |
|---|---|---|---|---|
| (a) Premium plătit o dată | zero compromis | nimic în joc | niciunul | corect, probabil invizibil |
| (b) Gratuit de încercat + deblocare unică | descoperire + feel încercat | IAP, gating, id-uri | niciunul | **cea mai bună potrivire** |
| (c) Gratuit cu reclame + „scoate reclamele” | venit de la neplătitori | SDK, consimțământ, copii | 7 (întrerupe bucla) | doar la volum mare |
| (d) Cosmetice: skinuri, personaje | zero pay-to-win | vizibilitate, sistem de vopsea | niciunul | strat secundar |
| (e) Upgrade-uri de statistici | progresie | monedă, echilibru | **4, plus 1 și 5 dacă se vând** | nu ca monetizare |
| (f) Pachete de lumi post-release | vinde ce facem cel mai bine | id-uri, formularea ofertei | niciunul | etapa a doua |
| (g) Abonamente: Arcade, Play Pass, Netflix | bani în avans | pitch, exclusivitate | niciunul | pitch înainte de lansare |
| (h) PC și console premium | public care plătește | controller, port | niciunul | a doua piață |

### 3.1 Premium, plătit o dată
- Pro: zero compromis de design, zero SDK, zero consimțământ, cel mai ușor de
  construit, recenzii mai bune, Apple îl preferă la featuring.
- Contra: jocurile plătite nu se descoperă fără presă sau featuring, iar e
  primul joc, fără audiență. Nimeni nu poate încerca feelingul înainte să
  plătească, și feelingul e tot argumentul. Pe Android vânzările plătite sunt
  și mai slabe.
- Verdict: corect, dar probabil invizibil. Bun pe PC și console, nu ca plan
  principal pe mobil.

### 3.2 Gratuit de încercat, o singură plată deblochează tot (modelul Horizon Chase)
- Pro: descoperirea unui joc gratuit, jucătorul simte condusul înainte să
  plătească, zero reclame, un singur produs IAP non-consumabil, fără monedă,
  fără grind. Compatibil cu principiile 1, 4, 5 și 7 fără nicio ajustare. Lasă
  loc pentru cosmetice și pachete.
- Contra: conversia e mică, deci trăiești din volum. Cele 3 lumi gratuite
  trebuie să fie cele mai bune cârlige, iar peretele trebuie să se simtă ca
  „mai mult conținut”, nu ca pedeapsă. Cere id-uri stabile, gating, plugin IAP,
  restaurare de achiziții. Deblocarea locală se piratează pe Android; se
  acceptă.
- „Trial” nu e limitat în timp: cele 3 lumi se joacă la nesfârșit. Baza de
  jucători rămâne 100%; 1-5% plătesc. Cei 95% dau recenzii, vorbesc despre
  joc, umplu clasamentele, iar unii plătesc mai târziu, la o lume nouă sau la o
  reducere.

| Model | Instalări | Cine plătește | Bani la 3 $, net ~2,55 $ | Baza rămasă |
|---|---|---|---|---|
| Plătit | 500 | toți | ~1 275 $ | 500 |
| Gratuit + deblocare | 20 000 | 2% | ~1 020 $ | 20 000 |

Cifre ilustrative, nu măsurători: bani similari la lansare, bază de 40 de ori
mai mare. Baza e ce crește tot ce vine după.

### 3.3 Gratuit cu reclame, plată ca să le scoți
Candidatul dezvoltatorului: 3 piste gratis fără reclame, apoi jocul full
gratuit cu reclame sau full plătit fără reclame. Analizat în detaliu în §5.
- Pro: monetizează și pe cei care nu plătesc niciodată; două fluxuri de venit;
  „scoate reclamele” e un IAP cu motivație clară; plugin-ul Poing Studios
  acoperă Android și iOS cu consimțământ UMP inclus.
- Contra: o cursă durează 2-3 minute, deci un interstițial după fiecare cursă
  e cea mai lungă întrerupere din buclă. Reclamele cer consimțământ GDPR, ATT
  pe iOS, declarații în ambele magazine și apropie jocul de zona „apelează la
  copii”, unde rămân doar reclamele nepersonalizate, care plătesc puțin.
  Reclamele recompensate n-au ce recompensa: fără monedă, items sau vieți,
  singura recompensă onestă e „încearcă o pistă blocată o dată”. Bucla devine
  „plătesc ca jocul să fie ce ar fi trebuit să fie”.
- Verdict: funcționează doar la volum mare și costă exact identitatea de joc
  curat. Direcția „lansezi curat, adaugi reclame recompensate mai târziu” e
  reversibilă; inversul, interstițiale adăugate peste o bază instalată curat,
  aduce revoltă în recenzii.

### 3.4 Cosmetice: skinuri de mașină, personaje, roți, dâre, claxoane
- Pro: zero pay-to-win, se potrivește cu fantezia „colecționez mașinuțe”, se
  adaugă la orice model. Șoferii există deja în 4 variante, deci primul strat
  e aproape gratis.
- Contra: cosmeticele vând doar când cineva le vede. Într-un joc single-player
  fără clasamente, nimeni nu-ți vede skinul. Vopseaua pe mașină cere sistem
  nou. Un catalog cere producție continuă.
- Verdict: strat secundar, nu model principal. Devine real cu vizibilitate:
  clasamente Game Center / Play Games cu iconița mașinii, fantome de best-lap,
  mod foto de partajat. Personajele, în §7.3.

### 3.5 Upgrade-uri de accelerație, viteză, handling, frâne
- Pro: progresie și retenție, obiective pe termen lung, modelul standard F2P
  pentru racere.
- Contra: contrazice principiul 4 și, dacă sunt de cumpărat, principiile 1 și
  5. În single-player, pay-to-win înseamnă „plătesc ca să bat un AI pe care tot
  noi îl reglăm”, citit imediat ca grind artificial. Cere echilibru pe 12
  piste, o monedă și un AI care ține pasul cu nivelul jucătorului, adică
  sistemele care blochează jocul. Statisticile din `CarData` devin stare per
  jucător.
- Verdict: ca monetizare, nu. Ca progresie câștigată prin joc, posibil, dar e
  altă identitate de joc și cere rescrierea principiului 4. Un „tuning” care
  mută grip contra viteză la sumă constantă păstrează identitatea, dar nu se
  vinde. Scopul căutat, un motiv pentru statistici diferite, se obține prin §7
  fără upgrade-uri.

### 3.6 Pachete de lumi după lansare (Uyuni, Veneția, Petra, Maroc)
- Pro: vinde exact ce facem cel mai bine; fiecare lume nouă e un moment de
  vizibilitate în magazin; nu afectează echilibrul.
- Contra: o lume costă săptămâni de producție și se vinde doar dacă baza e
  populară. Oferta de lansare se formulează „toate lumile de la lansare”, nu
  „tot jocul”, altfel pachetele par o trădare.
- Verdict: da, ca etapa a doua, peste (b).

### 3.7 Abonamente: Apple Arcade, Google Play Pass, Netflix Games
- Pro: bani în avans sau plată pe angajament, zero monetizare în joc, zero
  reclame, distribuție făcută de altcineva. Un racer stilizat, curat, fără
  items, e profilul pe care îl caută. Play Pass se aplică după lansare, fără
  exclusivitate.
- Contra: Arcade și Netflix cer pitch și vertical slice, decizii lente,
  exclusivitate pe mobil la Arcade, suport de controller și iCloud. Nu depinde
  de noi.
- Verdict: pitch înaintea lansării gratuite, cu termen fix. Dacă vine, rezolvă
  totul; dacă nu, nu s-a pierdut nimic. Play Pass: da, după lansare.

### 3.8 PC și console, premium
- Pro: publicul de pe Steam și Switch plătește prețuri de joc întreg pentru
  racere arcade cu farmec; Godot exportă pe PC azi; wishlist-urile sunt
  marketing gratuit.
- Contra: controller și tastatură de lustruit, concurență, trailer; consolele
  cer partener de port.
- Verdict: a doua piață, nu prima; nu schimbă modelul de pe mobil.

### 3.9 Respinse, cu motiv
Bannere (ocupă ecranul de joc), energie sau bilete (respins deja în proiectul
2D), battle pass și sezoane (fără live-ops), loot box și cutii oarbe (legal,
copii, Apple cere afișarea șanselor), monedă virtuală cumpărabilă (§4), Lite +
Full ca două aplicații (recordurile se despart, Apple 4.3), early access (nu la
primul joc).

## 4. Studiu de caz: Reckless Racing 3

Plătit, cu carieră în care fiecare cursă dă bani, banii cumpără mașini pe clase
de curse, iar personalizarea e doar cosmetică (vopsea, roți). Pixelbite a scos
upgrade-urile de statistici pe care le avea Reckless Racing 2. IAP-ul e
exclusiv pachete de bani, scurtătură pentru cine nu vrea să joace arcade ca să
strângă. Fără reclame, fără colectare de date.

| Ce | Cât |
|---|---|
| Preț la lansare, 2014 | 4,99 $ |
| Preț acum pe App Store | 2,99 $ |
| Pachete de bani | 0,99 / 1,99 / 9,99 / 19,99 $ |
| Promoții văzute | 0,10 € pe Android, gratuit temporar pe iOS |
| TouchArcade | 4 din 5 |

- Ce merge: tot conținutul se câștigă din joc; economia dă carierei un scop;
  cine a plătit intrarea e plătitor dovedit, deci convertește mai bine; jocul
  se poate pune gratuit o săptămână și tot încasează din pachete.
- Ce nu merge, structural: pachetele se vând doar dacă grind-ul se simte
  (recenzenții: primele ore merg fără să plătești, apoi distracția se tulbură);
  eticheta „In-App Purchases” pe un joc plătit sperie cumpărătorii de premium;
  un pachet de 19,99 $ într-un joc de 3 $ semnalează vânătoare de balene;
  economia cere echilibru care nu produce feel.
- De luat: scoaterea upgrade-urilor și păstrarea doar a cumpărării de mașini
  plus cosmetice. E principiul 4 pus în practică într-un racer comercial.
- De nu luat: vânzarea monedei. Peste (b), un IAP de monedă transformă jocul
  într-o economie F2P cu tot bagajul ei.

## 5. Reclama după fiecare cursă

Cadența: 3 tururi înseamnă o cursă de 2-3,5 minute, deci o reclamă la ~3
minute. După standardele casual nu e agresiv (hyper-casualul arată una pe
minut); după standardele de indie premium e intruziv: 15-30 s de reclamă la 3
minute de joc, singura întrerupere din bucla de burst play.

Bani, ordin de mărime (4 curse pe zi per jucător activ, reclame nepersonalizate,
eCPM amestecat ~4 $; estimări, nu măsurători):

| Jucători activi pe zi | Venit lunar din reclame |
|---|---|
| 100 | ~50 $ |
| 1 000 | ~500 $ |
| 10 000 | ~5 000 $ |

Sub o mie de jucători activi pe zi, reclamele plătesc mai puțin decât un IAP
„scoate reclamele și deblochează tot” la 3 $ cu conversie de 1-2%. Peste
câteva mii, reclamele scalează cu angajamentul, iar deblocarea nu; de aceea
industria le combină. Mia de jucători zilnici cere zeci de mii de instalări,
pe care fără featuring sau viralitate nu le ai la lansare.

Ce costă concret la jocul ăsta:
- **Fereastra de lansare.** Recenziile din primele săptămâni pedepsesc
  reclamele mai dur decât orice preț; reclamele se pot scoate oricând, dar
  lansarea nu se reface.
- **Copiii** (§6): rețele certificate și reclame nepersonalizate, care plătesc
  cam la jumătate.
- **Build-ul.** SDK-ul și dependențele lui adaugă MB și complică pipeline-ul
  iOS din Actions.
- **Orbirea.** Fără analytics nu vezi ce retenție mănâncă reclama; consolele
  dau retenție brută, atât.
- **Best-lap-ul.** Jucătorul care vânează recordul dă restart la 2 minute; o
  reclamă pe cursă omoară exact bucla cea mai adâncă.

Dacă totuși se merge pe reclame, regulile care fac modelul suportabil:
1. După ecranul de rezultate, niciodată înainte de poziție și timp, niciodată
   pe ecranul de încărcare.
2. Plafon pe timp, nu pe cursă: cel mult una la 3-4 minute; restart-urile și
   time-trial-ul exceptate.
3. Zero reclame în primele curse ale unui jucător nou; „primele 3 piste fără
   reclame” face asta automat.
4. Offline nu se blochează nimic.
5. IAP-ul „scoate reclamele” apare imediat după prima reclamă; în varianta
   hibridă scoate reclamele și deblochează tot, un singur produs.
6. Reclame nepersonalizate din start, ca să fim acoperiți pe copii și să nu
   avem nevoie de ATT.
7. Între rundele de campionat e locul natural: acolo deja aștepți.

Verdict: lansare fără interstițiale; reclama recompensată „încearcă o pistă
blocată”, temporară și cu plafon pe zi, doar în v1.1 și doar dacă instalările
depășesc câteva mii pe lună. O reclamă care deblochează harta PERMANENT ucide
IAP-ul: 9 reclame, sub un dolar de venit, ar înlocui achiziția de 3 $.

## 6. Publicul-țintă și nișa de copii

Clarificare: clasificarea „pentru copii” costă doar dacă ai reclame sau
colectezi date. Reclamele sunt permise la toate vârstele; le restricționează
înscrierea în Kids Category (Apple) sau Designed for Families (Google), ori
clasificarea de către Google ca joc care „apelează la copii” (risc real pentru
mașinuțe de jucărie cu stil cartoon), și nici atunci total, ci prin rețele
certificate și reclame nepersonalizate. Cu deblocare și zero date, Kids
Category e opțională la Apple, iar Families se aplică doar dacă declari tu
copiii ca public.

Problema reală e comercială: copiii n-au card, iar părinții blochează
achizițiile. Levierele ca să atragi adulți:
- **Titlul.** „Toy” e cel mai puternic semnal de copii din tot jocul; e titlu
  de lucru. Un nume din zona de modelism și diorame, verificat la marcă.
- **Cadrul.** Nu „jucării pentru copii”, ci modelism: machete, diorame, hobby
  de adulți; nostalgia racerelor arcade din anii '90.
- **Fișa de magazin.** Capturi cu drift, airtime, îmbrânceli, clasamente;
  descriere cu fizică, time attack, hazarde. Fără „distracție pentru toată
  familia”, mascote zâmbitoare, voci de copii.
- **Mecanici de adult.** Clasamente și fantome prin Game Center / Play Games,
  time attack, stele pe pistă. Ragdoll-ul și hazardele cu urși, trenuri și
  lavă citesc ca arcade cu tupeu, nu ca joc de grădiniță.
- **Declarațiile.** Google: public-țintă 13+ și „nu e conceput pentru copii”.
  IARC răspuns onest; violența de desen animat ușoară dă probabil PEGI 7.
  Apple: nu Kids Category; 9+ dacă ragdoll-ul se încadrează.
- **Canalele.** TouchArcade, Pocket Gamer, subreddit-urile de iOS gaming,
  canale YouTube de racere.

Caveat: Google judecă după fișă. Dacă spun totuși „apelează la copii”,
ajustezi fișa sau accepți. Fără reclame e un non-eveniment.

## 7. Progresia: deblocare, mașini, personaje, Bronz / Argint / Aur

Dezvoltatorul vrea ca statisticile diferite ale mașinilor să aibă un scop:
deblocarea altor mașini, skinuri și personaje. De acord pe fond; diferența e
unde intră banii reali.

### 7.1 Deblocarea cu puncte
- **Stele pe pistă** (recomandat): 3 obiective per lume și nivel, de exemplu
  câștigă / bate timpul țintă / termină fără repunere. Total fix, zero
  inflație, zero matematică de grind. „Mașina X cere 9 stele, șoferul Y cere o
  victorie cu Autobuzul.”
- **Bani pe cursă**, ca în Reckless Racing 3: senzație de carieră, dar prețuri,
  curbe de câștig, echilibru pe 12 piste și tentația de a-i vinde.
- Linia: **banii reali nu cumpără niciodată statistici.** Mașinile se
  deblochează doar cu puncte. Skinurile și personajele pot fi și cumpărate, și
  câștigate. Horizon Chase face exact asta: cumperi jocul complet, mașinile tot
  prin progres le deblochezi.

### 7.2 Mașinile: ordine pe stil, nu pe putere
Dacă ultima mașină deblocată e și cea mai bună, garajul se citește ca scară de
upgrade-uri și principiul 4 moare pe ușa din dos. Fiecare mașină are nevoie de
un teritoriu în care e cea mai bună.

| Mașină | Viteză | Accel. | Grip | Masă | Teritoriul propus |
|---|---|---|---|---|---|
| Muscle | 37 | 15 | 7,0 | 1,35 | drepte lungi |
| Politia | 36 | 17 | 10,0 | 0,9 | serpentine (Transfăgărășan) |
| Taxi | 33 | 16 | 9,0 | 1,15 | **aproape dominat de Politia**: de reprofilat |
| Autobuzul | 30 | 11 | 8,0 | 2,6 | îmbrânceli, piste cu trafic |
| Pompierii | 32 | 12 | 8,0 | 2,0 | greu, dar mai iute decât Autobuzul |
| Buggy | 35 | 16 | 8,5 | 1,0 | sărituri, viraje scurte |

Valori din `scenes/cars/data/*.tres` la 13 oct 2026. O mașină dominată e o
recompensă moartă.

Obiective care dau rost statisticilor: record pe pistă **per mașină**, nu doar
per pistă (cel mai bun timp cu Autobuzul pe Okinawa e alt record decât cu
Buggy-ul); provocări per mașină (3 victorii cu Pompierii, o săritură de X metri
cu Buggy-ul).

### 7.3 Personajele: personalitate, nu performanță
Cockpitul deschis le face vizibile în cursă, în zborul ragdoll, pe rezultate,
într-un mod foto. Sunt cel mai bun cosmetic și cel mai ieftin: 4 figurine cu
sloturi de paletă există deja. Regula: nume, animație de bucurie sau panică,
claxon propriu, dar nicio cifră pe fizică. Așa pot fi și câștigate, și vândute
în seturi, fără ca vreun cumpărător să ia un avantaj. Deblocări legate de
mașini: pompierul după 3 victorii cu Pompierii, polițista după un tur fără
repunere cu Politia.

### 7.4 Legătura cu modelul gratuit + deblocare
Jucătorul gratuit are 3 lumi, deci cel mult 9 stele pe nivel, deci deblochează
doar primele mașini. Lumile blocate se văd cu gimmickul lor, mașinile blocate
se văd în mâinile AI-ului. Deblocarea jocului complet aduce două lucruri
deodată: mai multe lumi și mai multe obiective. IAP-ul se vinde fără să vinzi
nicio mașină direct.

### 7.5 Bronz / Argint / Aur cu AI onest
Aceleași 12 piste de trei ori, cu recompense diferite: cea mai ieftină triplare
a conținutului. Dificultatea crește onest: AI-ul de Aur nu e mai rapid decât
mașina, e mai rapid decât tine, fiindcă folosește toată mașina. Cel de Bronz
folosește o parte din ea. Niciunul nu primește viteză sau grip în plus.

Butoanele există deja în `scenes/cars/ai_controller.gd`, azi constante:
- **Marja în viraj**: podeaua 0,44 (`CORNER_SPEED_FLOOR`, ținta la 549) și
  `CORNER_SOFT` / `CORNER_HARD` (30-31). Bronz frânează devreme și mult, Aur
  ține limita.
- **Turbo** (637-646): azi îl arde când bara trece de 0,6 pe drept și îl taie
  înaintea virajului. Bronz îl irosește, Aur îl păstrează pentru cea mai lungă
  dreaptă și face rocket start.
- **Drift** (631-635): azi peste severitatea 0,34. Bronz driftează rar, deci
  are turbo puțin; Aur pe fiecare viraj susținut.
- **Linia**: `INSIDE_BIAS` (35) și `line_offset` (276), lookahead-ul apropiat
  și depărtat (22-27). Aur ia apexul, Bronz intră larg.
- **Scurtătura**: `SHORTCUT_CHANCE` 0,4 (69), decisă o dată pe cursă (297).
  Bronz 0,1, Aur 0,7, și doar dacă e mai rapidă pentru mașina lui.
- **Depășirea**: ferestrele de evitare (48-60). Aur atacă, Bronz cedează.
- **Greșeli vizibile**: Bronz frânează uneori târziu sau ratează linia; onest
  fiindcă e condus mai prost, nu fizică trișată.
- **Alegerea mașinii**: Aur ia mașina potrivită pistei.

De nu făcut: înmulțitor pe `max_speed` sau grip, catch-up pe viteză
(principiul 5, comentariul de la 293). Plutonul strâns de dragul spectacolului
se face tot prin conducere: liderul puțin mai prudent, coada mai agresivă cu
turbo-ul; nimeni nu depășește ce poate mașina.

| Nivel | Timp pe tur față de referință | Recompensă |
|---|---|---|
| Bronz | ~12% mai lent | 1 stea |
| Argint | ~6% mai lent | 2 stele |
| Aur | ~2% mai lent | 3 stele |

Referința: turul AI-ului cu toate butoanele la maximum. Procentele sunt punct
de pornire, se reglează la volan și se măsoară cu ProbeRace pe 16 seed-uri, ca
distribuție, nu ca o singură rulare. 12 piste × 3 niveluri = 36 de stele; scara
de deblocare se așază pe ele. Tehnic: un `AiSkill` cu ~8 câmpuri în locul
constantelor, setat per cursă din nivelul campionatului, plus sonda care
verifică procentele.

## 8. Cifre verificate (13 oct 2026)

| Ce | Cât | Sursă |
|---|---|---|
| Comision Apple, sub 1 M$ proceeds pe an | 15% | App Store Small Business Program |
| Comision Google Play din 30 iun 2026, UE / UK / SUA | 10% serviciu + 5% facturare Play | Play Console; 15% în restul piețelor până la extindere |
| Preț de deblocare la Horizon Chase | ~3 $ | TouchArcade |
| Descărcări Horizon Chase în 5 ani | 50 M | Pocket Gamer, 2020 |
| Conversie tipică free-to-paid | 1-5% | regulă de industrie, nu măsurătoare |
| Reclame la 300 de jucători activi pe zi | ~100-150 $ pe lună | estimare la eCPM 5 $ |
| Plugin IAP Godot 4 | godot-iap (OpenIAP): StoreKit 2 + Play Billing 8, MIT | Asset Library, listat pentru 4.3; de verificat pe 4.7 |
| Plugin reclame Godot 4 | Poing Studios AdMob: Android + iOS, UMP, mediere | GitHub, 4.2+ |
| Play: modulul de bază al AAB | sub 200 MB comprimat; pachete PAD până la 1,5 GB | Play Console |
| iOS: prag de descărcare pe celular | 200 MB, cu confirmarea utilizatorului | TechCrunch, 2019 |
| Reckless Racing 3 | 4,99 $ la lansare, 2,99 $ acum, pachete 0,99-19,99 $ | App Store, TouchArcade |

Surse: [Small Business Program](https://developer.apple.com/app-store/small-business-program/),
[Google Play service fees](https://support.google.com/googleplay/android-developer/answer/112622?hl=en),
[ITPro: Google Play 15%](https://itpro.com/mobile/google-android/358915/google-play-reduces-developer-service-fee-to-15),
[TouchArcade: Horizon Chase](https://toucharcade.com/?p=267244),
[Pocket Gamer: 50 M descărcări](https://www.pocketgamer.com/articles/083919/horizon-chase-is-celebrating-its-5th-anniversary-and-50-million-downloads-with-special-events-and-rewards/),
[godot-iap în Asset Library](https://www.godotengine.org/asset-library/asset/edit/24073),
[Poing Studios AdMob](https://github.com/poingstudios/godot-admob-ios),
[Android App Bundle](https://developer.android.com/guide/app-bundle?hl=en),
[limitele de mărime în Play Console](https://support.google.com/googleplay/android-developer/answer/9302563),
[pragul de celular pe iOS](https://techcrunch.com/?p=1835511),
[App Store: Reckless Racing 3](https://apps.apple.com/us/app/-/id882453590),
[TouchArcade: Reckless Racing 3](https://toucharcade.com/2014/10/17/reckless-racing-3-review/),
[mobiFlip: Reckless Racing 3](https://www.mobiflip.de/?p=208671).

## 9. Recomandarea și fazarea

Combinația: (b) ca bază, strat de colecție de jucării (§7), pachete de lumi
după lansare, pitch la Arcade și Netflix în paralel, fără interstițiale, fără
upgrade-uri.

| Fază | Ce intră |
|---|---|
| v1.0 | 3 lumi gratuite cu campionatul lor; deblocare unică „toate lumile”; stele și deblocări de mașini și personaje prin joc; Bronz / Argint / Aur; clasamente Game Center / Play Games; fără SDK de reclame |
| v1.1 | reclama recompensată „cursă de probă pe o lume blocată”, temporară și cu plafon, doar dacă instalările justifică; seturi de personaje și skinuri vândute |
| post-release | pachete de lumi (Uyuni, Veneția, Petra, Maroc); Play Pass; PC / Steam |

Mecanici noi, în ordinea raportului efect pe efort:
1. **Stele pe pistă**: dau adâncimea de „10 ore” în cele 3 lumi gratuite și
   arată ce ai de pierdut dacă nu deblochezi.
2. **Fantome și clasamente** prin Game Center și Play Games: fără server
   propriu, retenție, vizibilitate pentru skinuri.
3. **Lumi blocate vizibile**, cu miniatura reală și gimmickul descris; AI-ul
   conduce și mașinile blocate. Vezi ce cumperi.
4. **Colecția de jucării**: mașini și personaje câștigate prin stele, câteva
   seturi vândute; fără cutii oarbe.
5. **Mod foto** cu partajare: diorama se vinde singură pe rețele.

Reversibilitate: plătit → gratuit se poate oricând; gratuit → plătit nu; curat
→ cu reclame recompensate se poate; curat → cu interstițiale peste o bază
instalată, nu.

## 10. Precondiții tehnice (inventar, nu design)

Efort: S = ore, M = zile, L = săptămâni.

| P# | Ce | Fișiere | Efort | Cerută de |
|---|---|---|---|---|
| P1 | Id-uri stabile pentru piste și mașini; recordurile și `selected_car` pe id | `scenes/tracks/track_info.gd`, `scenes/cars/car_data.gd`, `scenes/tracks/info/*.tres`, `game_state.gd` | M | orice gating, redenumiri |
| P2 | Schemă de save versionată + migrare nume → id | `game_state.gd` | S-M | P1 |
| P3 | Redenumirea Monument Valley, dublura Okinawa, swap-ul 19 / 20 / 21 | `game_state.gd`, `Track19.tres` | S | scadentă oricum |
| P4 | Semnalele `race_finished` / `lap_completed` | `race.gd` | S | ofertă, stele, măsurare |
| P5 | Stele + deblocări: stare locală, cartonașe blocate cu condiția afișată, garaj cu bare de stil | `game_state.gd`, `scenes/ui/track_select_panel.gd`, `scenes/ui/track_card.gd`, `main_menu.gd` | M | §7 |
| P6 | Gating-ul lumilor + oferta „toate lumile”; tastele 1-6 doar în debug | `track_select_panel.gd`, `race.gd` | M | (b) |
| P7 | Plugin IAP într-un autoload `store.gd` cu stub pe desktop, restore, pending | plugin + autoload nou | M-L | (b); netestabil fără cont Apple plătit |
| P8 | `AiSkill` per nivel + sondă de procente | `ai_controller.gd`, `race.gd`, ProbeRace | M | §7.5 |
| P9 | Recorduri per pistă × mașină | `game_state.gd`, HUD, cartonaș | S-M | §7.2 |
| P10 | Ecran Credite / Licențe (CC-BY, MIT, Godot) | `main_menu.gd`, `assets/CREDITS.md` | S-M | orice vânzare |
| P11 | IESIRE ascuns pe iOS | `main_menu.gd:41-42` | S | review Apple |
| P12 | `export_presets.cfg` pe `main` (iOS + Android), bundle id final, versiune, icon | `project.godot`, preset | M | primul build de store |
| P13 | Clasamente și fantome prin Game Center / Play Games | plugin-uri | M | §9 |
| P14 | Sistem de vopsea pe mașini (doar dacă se vând skinuri de mașină) | `scripts/palette.gd`, `car_data.gd` | L | (d) |
| P15 | Plugin reclame + UMP + ATT (doar v1.1, dacă se decide) | plugin | M-L | (c) |

Ordinea: P1 → P2 → P3 → P4 → P5 / P9 → P10 / P11 / P12 (= „lansabil”) → P6 →
P7 → P8 → P13 → restul, la decizie.

## 11. Decizii pentru dezvoltator

Format: variante, recomandare, înclinația declarată pe 13 oct 2026, când se
decide.

1. **D1 Publicul-țintă și vârsta.** A: toate vârstele fără program de copii,
   zero date, reclame doar nepersonalizate dacă vreodată; B: Kids Category /
   Designed for Families; C: 13+ cu reclame și analytics. **Recomandare:** A,
   cu levierele din §6. Înclinație: a întrebat dacă A exclude reclamele (nu).
   **Se decide înainte de** D2.
2. **D2 Modelul.** (a) premium; (b) gratuit + deblocare unică; (c) gratuit cu
   reclame + „scoate reclamele”; candidatul propriu: 3 piste gratis fără
   reclame, apoi full cu reclame sau full plătit. **Recomandare:** (b), cu
   reclama recompensată doar în v1.1. Înclinație: nedecis, între candidatul
   propriu și (b). **Se decide înainte de** P6 / P7 și de fișa de magazin.
3. **D3 Upgrade-uri de statistici.** Deloc; câștigate prin joc (rescrie
   principiul 4); cumpărabile. **Recomandare:** deloc; scopul se obține prin
   §7. Înclinație: s-a gândit la ele, nedecis. **Se decide înainte de** P5.
4. **D4 Ce cumpără banii reali.** Doar lumi + cosmetice; sau și mașini
   (pay-to-skip). **Recomandare:** doar lumi + cosmetice; mașinile exclusiv cu
   puncte. Înclinație: „fie cu bani, fie cu puncte”. **Se decide înainte de**
   P5 / P7.
5. **D5 Moneda de progresie.** Stele cu total fix; bani pe cursă.
   **Recomandare:** stele. **Se decide înainte de** P5.
6. **D6 Bronz / Argint / Aur.** Da, cu AI onest pe butoanele din §7.5; nu.
   **Recomandare:** da; țintele ~12 / 6 / 2% se reglează la volan. Înclinație:
   da. **Se decide înainte de** P8.
7. **D7 Pitch Apple Arcade / Netflix.** Înainte de lansarea gratuită, cu
   termen; nu. **Recomandare:** da, cu termen de 2-3 luni. **Se decide înainte
   de** anunțul public.
8. **D8 Lumile post-release.** Gratuite; pachete plătite. **Recomandare:**
   pachete, cu oferta de lansare formulată „toate lumile de la lansare”. **Se
   decide înainte de** textul ofertei (P6).
9. **D9 Titlul.** „Toy Racer” (semnal de copii); nume din zona de modelism.
   **Recomandare:** nume nou, verificat la marcă și pe App Store (numele sunt
   unice acolo). **Se decide înainte de** crearea aplicației în App Store
   Connect, care rezervă numele.

## 12. Ce NU e aici

Implementare (orice P#), marketing, prețul exact și localizarea lui, entitatea
juridică și conturile de dezvoltator, politica de confidențialitate, planul de
lansare. Se scriu când D1 / D2 sunt luate.

## Istoric

- **v0.1 (13 oct 2026):** analiza din conversația de monetizare, cu
  înclinațiile dezvoltatorului marcate ca nedecise; cifrele verificate la
  aceeași dată; linia de 100 MB din `CLAUDE.md` scoasă separat (#488).
