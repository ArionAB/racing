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
2. **Drift-ul CTR e nucleul de skill** (port din 2D): 3 niveluri de boost
   încărcate cu timpul, eliberare cu timing, backfire dacă ții prea mult,
   chaining. Floor jos, ceiling înalt.
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

- Fizică arcade pe `CharacterBody3D` cu grip lateral amortizat ✔ (din spike)
- Pante, gravitate, sărituri, iarbă lentă (45%), pereți doar pe exterior +
  secțiuni înălțate ✔
- Bumping cu masă ✔ (de tunat)
- Hazarde mobile (`SlidingHazard`) ✔ (de transformat în familie de scene)
- 3 AI cu waypoints, drift, anti-blocaj ✔ (de rafinat)
- Presetări de mașini ✔ (de mutat în resurse `CarData`)
- Drift CTR complet: niveluri + backfire + chaining — **de portat din 2D**
- Countdown + rocket start, poziții live, rezultate — **de portat din 2D**
- Touch controls: viraj pe jumătăți de ecran + auto-accelerate + buton drift
  (modelul din 2D, adaptat la chase cam) — **de validat pe device fizic**

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

- 60fps pe mid-range: low-poly (buget ~50k triunghiuri pe scenă), o singură
  lumină direcțională, umbre ieftine sau blob shadows sub mașini, fără
  post-procesare scumpă (fog simplu e ok)
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
- **M1:** restructurare pe arhitectura de mai sus + drift CTR portat + touch
  controls. Testul: un tur satisfăcător, cu drift și săritură, pe telefon
- **M2:** juice complet (particule, urme, shake, audio portat) + HUD mobil,
  meniu, pauză, setări (port din 2D)
- **M3:** 2-3 piste cu gimmick propriu + garaj 3-4 mașini + mini-campionat
- **M4:** build Android, profilare 60fps, iterare de feel pe device

## Definiția lui "fun" pentru verificare

La fiecare milestone: *e satisfăcător să faci un tur singur, cu drift și o
săritură?* Dacă drift-ul + săritura + bumping-ul nu sunt fun fără adversari,
restul nu salvează jocul. Întâi feel, apoi conținut.
