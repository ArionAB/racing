# CLAUDE.md — Toy Racer (titlu de lucru)

## Ce construim

Racer 3D arcade cu mașinuțe de jucărie, în spiritul Ignition (1997): chase cam,
piste compacte cu personalitate (dealuri, sărituri, scurtături, obstacole
mobile), îmbrânceli cu masă între mașini și drift-boost în stil CTR.
**Fără arme/items** — diferențierea față de Beach Buggy Racing & co e condusul
pur plus haosul fizic, nu proiectilele.

- **Engine:** Godot 4.7 (GDScript)
- **Perspectivă:** 3D low-poly, chase cam (camera în spatele mașinii)
- **Target:** mobile-first (Android + iOS), 60fps constant pe device mid-range
- **Dezvoltator:** web developer solo, primul proiect de gamedev — explică
  conceptele de gamedev/3D când apar, nu presupune experiență
- **Istoric:** proiectul a crescut din spike-ul de evaluare 2D-vs-3D. Jocul
  2D top-down din `d:\GameDev\racing` rămâne sursă de port pentru mecanici
  deja construite: drift CTR, AI, race flow, pauză/setări, audio.

## Principii de design (acestea decid orice trade-off)

1. **Fun-ul vine din fizică + pistă, nu din items.** Bumping cu masă (mașina
   grea împinge, cea ușoară zboară), sărituri cu airtime, hazarde mobile,
   scurtături prin off-road lent. Contactul între mașini e mecanică, nu bug.
2. **Turbo-ul e resursă, tu decizi când** (modelul Ignition, ales explicit
   de dezvoltator după playtest în locul drift-boost-ului CTR): o bară care
   se încarcă din mers (mult mai repede în drift) și pe care o arzi când
   vrei ținând TURBO. Skill de decizie (pe ce dreaptă, înaintea cărei
   sărituri, la ce depășire), nu de timing la viraj. Drift-ul e handbrake
   pur — unealtă de viraj care hrănește bara.
3. **Piste scurte cu personalitate.** Fiecare pistă are un "gimmick" memorabil
   (barieră mobilă, tren, pod). Alternanță drepte/viraje, elevație folosită
   agresiv (creste care te aruncă în aer), scurtături risc/recompensă.
4. **Mașini cu identitate.** Presetări cu stiluri distincte (viteză/grip/masă),
   nu upgrade-uri numerice. Alegerea mașinii = alegerea stilului de joc.
5. **AI onest.** Fără viteză trișată. Variație prin linii diferite și
   performanță ușor diferită, vizibil corectă.
6. **Juice peste tot** (filozofia din 2D): screen shake, înclinarea caroseriei,
   FOV cu viteza, particule, pitch de motor variabil.
7. **Accesibil în 10 secunde, adânc în 10 ore.** Curse de 2-3 minute, burst
   play, fără sisteme care blochează jocul.

## Mecanici core (MVP)

- **Fizică întreagă** pe `RigidBody3D` cu suspensie pe raycast ✔ (pivotul din
  aug 2026, #261: 4 roți cu arc + amortizor, forțele de cauciuc la sol —
  ruliul/tangajul/legănarea ies din fizică; grip lateral amortizat și direcție
  arcade păstrate; suspensia e identitate per mașină în `CarData`)
- Pante, gravitate, sărituri, iarbă lentă (45%), pereți doar pe exterior +
  secțiuni înălțate ✔
- Bumping cu masă ✔ (de tunat)
- Hazarde mobile (`SlidingHazard`) ✔ (de transformat în familie de scene)
- 3 AI cu waypoints, drift, anti-blocaj ✔ (de rafinat)
- Presetări de mașini ✔ (de mutat în resurse `CarData`)
- Turbo Ignition: bară care se încarcă din mers (accelerat de drift), arsă
  la cerere cu butonul TURBO ✔
- Countdown + rocket start (ține TURBO în ultima secundă), poziții live ✔
- Touch controls: viraj pe jumătăți de ecran + auto-accelerate + butoane
  DRIFT/TURBO ✔ — **de validat pe device fizic**

## Post-MVP (nu implementa fără să fie cerut)

Multiplayer, campionat lung, unlockables, tuning vizual de mașini, monetizare.

## Arhitectură (ținta restructurării — M1)

```
res://
  scenes/
    main_menu/
    race/            # Race.tscn — orchestrează o cursă
    cars/            # Car.tscn (player + AI același corp, controller separat)
    tracks/          # o scenă/script per pistă, generare din puncte de control
    hazards/         # o scenă per tip de obstacol
    ui/              # HUD, touch controls, meniuri, setări
  scripts/autoload/  # GameState.gd, AudioManager.gd
  assets/            # modele, texturi, audio
```

- **Separă fizica de input:** mașina primește comenzi de la un Controller —
  `PlayerController` (touch/tastatură) sau `AIController`. Pattern-ul din 2D.
- **Signals pentru evenimente** (lap_completed, race_finished) — nu polling.
- **Resurse pentru date:** `CarData` (presetări mașini), puncte de control per
  pistă. Conținut nou = fișier nou, zero modificări în cod.
- **Tuning în export vars** — feel-ul se găsește prin iterare, nu prin calcul.

## Convenții

- GDScript cu static typing; snake_case fișiere/funcții, PascalCase clase/scene
- O scenă = o responsabilitate; scene mici, compozabile
- Commit-uri mici și dese; `.godot/` în .gitignore
- Verificare headless cu sonde temporare (`--headless --fixed-fps 60`) înainte
  de commit la orice schimbare de fizică/gameplay

## Constrângeri mobile 3D

- 60fps pe mid-range: low-poly, **o singură lumină direcțională**, fără
  post-procesare scumpă (fog simplu e ok)
- **Umbre: abatere asumată.** Regula inițială cerea blob shadows. Rulăm acum umbre
  dinamice reale — o singură cascadă pe 90 m — după comparația cu Reckless Racing
  3 / Beach Buggy Racing: fără contact cu solul, orice obiect pare lipit peste
  fundal. Rămâne tot o singură lumină, doar că aruncă. Comutatorul e
  `Track.theme_shadows`; **e prima setare de stins dacă testul pe device nu ține
  60fps.**
- **Texturi: materiale de clasă, nu per asset.** Culoarea vine dintr-un atlas
  de paletă, detaliul de suprafață dintr-un strat triplanar partajat
  (`Palette.world_material()`). Un asset nu aduce NICIODATĂ texturi proprii —
  dar o *clasă* de assets poate primi un material partajat deliberat (trim
  sheet de rocă, decal-uri de urme), decis explicit, nu strecurat. Asta e ce
  ține draw call-urile jos: garda numără totalul de materiale per pistă.
  Vezi `docs/style_bible.md` §4. Regula s-a relaxat în august 2026 după
  comparația cu Beach Buggy Racing 2: diferența vizuală față de referință nu
  era poligonajul, ci detaliul pictat în texturi (deviație de luminanță ~2.7
  la noi vs ~36–40 la ei), iar texturile comprimate sunt aproape gratis pe
  GPU-urile mobile.
- **Triunghiuri: măsurate și raportate, dar fără plafon.** Garda le numără în
  continuare (`tools/probe_decor.gd`) fiindcă cifra prinde *clasa de accident*:
  o primitivă lăsată la rezoluția implicită sare cu zeci de mii dintr-un foc —
  un `SphereMesh` are 64×32 = **4.224 de triunghiuri**, deci o tufă de 40 cm
  ajunge cu geometria unei planete. **Când creezi o primitivă în cod,
  setează-i `radial_segments`/`rings`.** Dar numărul **nu mai pică build-ul**
  (decizia dezvoltatorului, august 2026).
  Două motive, amândouă verificate în practică. Întâi: cifra e pe **toată
  pista**, iar pe ecran nu ajunge niciodată toată — ceața taie tot ce e peste
  250 m, iar `visibility_range` plus topirea din shader scot vegetația de
  departe (pe Alpi, felia randată pe cadru măsurase ~10% din total). Un plafon
  pe suma întregii piste pedepsește geometrie care nu se desenează în același
  cadru. Al doilea, mai convingător: pragul a fost ridicat de **cinci** ori
  (80k → 150k → 300k → 400k, plus patru override-uri per pistă), de fiecare
  dată fiindcă muncă legitimă nu încăpea, și **de fiecare dată cu materialele
  neschimbate sau în scădere** — adică se îngreuna axa care nu doare pe mobil.
  Un prag care se mută ori de câte ori e atins nu măsoară nimic: cere doar o
  ceremonie înainte de fiecare merge. Ajunsese să țină CI-ul roșu pe main
  (Track10 la 1.36M cu override de 900k).
  Constrângerea reală rămâne **draw calls / overdraw / fill rate**, de aceea
  singurul test cu drept de veto e numărătoarea de **materiale** (max 38 per
  pistă). Validarea finală e primul test pe device fizic — și se începe cu
  Okinawa, fiind cea mai grea (2.75M triunghiuri, dar doar **21 de materiale**).
  Garda numără doar ce se **vede**: variantele stinse (`visible = false`) ale
  GLB-urilor multi-variantă nu se randează, deci nu intră în cifră.
- Texturi comprimate ETC2/ASTC, materiale simple (albedo, fără PBR complex)
- Particule cu limită de count; test pe device fizic de la primul build (M4,
  dar mai devreme dacă apar dubii de feel pe touch)
- Build size țintă: sub 100MB

## Nume și legal

Titlu de lucru: **Toy Racer**. Numele "Ignition" NU se folosește (e marca
altcuiva) — nici în titlu, nici în store listing. Inspirația mecanică e
legitimă; assets, nume sau trade dress copiate nu sunt.

## Roadmap

- **M0 ✔ (spike):** fizică validată, pistă cu dealuri, AI, bumping, iarbă
  lentă, rampă, barieră mobilă, 3 mașini, poziții/tururi
- **M1 ✔:** restructurare pe arhitectură + touch controls + countdown
- **M2 ✔:** juice complet (particule, urme, shake, audio) + meniu/pauză/setări
- **M2.5 ✔:** turbo model Ignition (înlocuiește drift-boost-ul CTR, decizia
  dezvoltatorului după playtest) + fix echilibru drag
- **M3 ✔:** 3 piste cu gimmick propriu + garaj 4 mașini + mini-campionat
- **M3.5 ✔:** identitate vizuală (linie start șah, kerbs, decor procedural cu
  coliziune) + recorduri best-lap persistate + scrâșnet de drift
- **M3.75 ✔ (aug 2026):** pivot la fizica întreagă — `RigidBody3D` + suspensie
  pe raycast, în 6 pași cu sonde (#255–#260, umbrela #261). Decizia: feelingul
  de condus e produsul; verdictul final de feel rămâne al dezvoltatorului, la
  volan, pe cele 3 piste
- **M4 (amânat — dezvoltatorul nu are device Android):** build Android,
  profilare 60fps pe telefon. Până atunci: dezvoltare pe desktop, cu
  constrângerile mobile respectate în continuare (poly buget, particule
  limitate, UI touch-first)

## Definiția lui "fun" pentru verificare

La fiecare milestone: *e satisfăcător să faci un tur singur, cu drift și o
săritură?* Dacă drift-ul + săritura + bumping-ul nu sunt fun fără adversari,
restul nu salvează jocul. Întâi feel, apoi conținut.
