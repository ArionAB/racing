# Runda 33 — flancul Erciyes. Premisa e corecta, tinta nu se poate atinge cinstit.

## Ce am confirmat din decizia de lead

Da, defectul e in cadranul dreapta-sus, si da, e UN singur obiect. Atribuit,
nu presupus (`tools/probe_flanc.gd` proiecteaza toate instantele de orizont in
dala care pica, r0 c3 = px x 768..1024, y 0..144):

    @Node3D@128/Erciyes ...... acopera 100% din dala
    orice alta instanta ...... 0%

Deci nu e "flancul muntelui" ca teren. Terenul (`ground_y`) nu e lovit de
NICIO raza prin dala. E o **silueta de orizont**, `horizon_model` din tema,
`add_child` direct pe pista in `_build_horizon` — plasata aleator din seed, cu
nume auto. **Nu e nod editabil in Track13.tscn si nu poate deveni unul** fara
sa rescrii sistemul de orizont. Asta invalideaza de la inceput cerinta
"totul ramane noduri editabile" pentru orice fix aplicat PE obiectul asta.

## De ce sub-dala nu poate trece, masurat

Dala are 36% CER si 64% munte. Descompus:

    dala r0 c3, intreaga ......... 1.12
      doar pixelii de cer ........ 0.62   (36% din dala)
      doar pixelii de munte ...... 1.41   (64% din dala)

Ca dala sa atinga pragul 1.63 cu 36% cer la 0.62, **muntele trebuie sa dea
2.20**. Nu 1.63 — 2.20, fiindca cerul dilueaza.

Referinta pe care e calibrat pragul (`B_chimneys.png`) e o vedere AERIANA:
randul 0 al ei are 0% cer, e plin de hornuri la 20-40 m. Pragul 1.63 e "cea
mai plata dala a unui cadru fara cer si fara fundal". Cadrul nostru de sofer
are orizont in randul 0 prin constructie — camera sta pe sosea si se uita
inainte. Nu e acelasi tip de dala.

## De ce obiectul e plat: mesh-ul, nu shading-ul

`erciyes.glb`, citit din GLB (nu presupus):

    500 vertecsi / 706 triunghiuri pe un con de 280 m
    UV: TREI valori distincte — u*32 = 2.5 / 22.5 / 29.5, v = 0.5
        (SAND_SHADOW / FOAM_WHITE zapada / MARBLE_GREY)
    COLOR_0: exista, 209 valori distincte, std 0.21

Adica **UV colapsate**: o fata = un texel = o culoare plata. Detaliul de
suprafata nu exista in textura fiindca nu exista UV-uri care sa-l poarte.
AO-ul din vertex color EXISTA si e generos, dar la 706 triunghiuri pe 104.000
m2 un triunghi are ~18 m latura, adica **~30 px pe ecran la 340 m**. Sonda
masoara abaterea fata de vecinii de 1 px; un gradient care se schimba o data
la 30-60 px da ~0, oricat de mare i-ar fi ecartul. Vertex color nu poate
produce detaliu de frecventa 1 px pe un mesh cu 30 px pe triunghi.

## Trei ipoteze picate — nu le relua in runda 34

### 1. "Ceata inghite flancul, deci orice adaug e inmultit cu zero." FALS.
Aritmetica spunea asta (suprafata e la 294..386 m, `fog_end` = 300). Masurat
pe pixeli, e fals: conul citeste 80..85 gri cald, iar ceata temei e
`Color(0.72,0.74,0.80)` = 184,189,204, rece si palida. Daca ar fi fost
inghitit ar fi avut CULOAREA CETII. Ecart 152 niveluri, std 24.4 — mai mult
decat cea mai plata dala a referintei (131 / 22.9). Suprafata ARE buget de
contrast. (Am scris asta ca ipoteza si am picat-o singur; nu porni de la ea.)

### 2. Cornise `cliff_band_module` pe flanc. TRECE SONDA, POZA E MAI PROASTA.
Doua variante:
  - prima, pe un profil raza(cota) derivat din `ProbeErciyes`: **zero pixeli
    schimbati**, desi 23 din 25 module cadeau geometric in dala cu 19..62 px
    latime. Cauza: raza masurata pe benzi de cota da 55..247 m la ACEEASI
    cota — piesa nu e axisimetrica, deci "raza la cota y" nu e o functie, iar
    modulele au aterizat IN SPATELE conului (316..398 m vs suprafata la
    294..386). Un obiect care exista, e vizibil, are mesh si nu deseneaza
    nimic: exact `efecte-invizibile-nu-se-numara`.
  - a doua, pe puncte de suprafata din raycast pe triunghiuri + normala
    masurata (`tools/probe_flanc_surf.gd`): **sonda trece, r0 c3 = 4.22,
    median 3.70 -> 3.99, ZERO dale in scadere**. Si totusi e de aruncat:
    in captura sunt **scanduri desprinse care ies din silueta in cer gol**,
    cu puncte negre pe ele. 86% din pixelii schimbati cad pe roca si tot arata
    a rafturi suspendate, fiindca piesa e broadside, luminata plin, si nu se
    leaga de suprafata. Cifra 4.22 e platita cu muchii de scandura.
    **Sonda se lasa satisfacuta de orice zgomot de inalta frecventa in dala.**

### 3. `horizon_class: "rock"` (clasa triplanara pe silueta). PICA SI CIFRA SI POZA.
1.12 -> 1.54, tot sub prag. Si face exact ce scria in comentariul din
`track.gd` ca face: muntele iese **portocaliu ca dunele**, calota de zapada
**dispare** (clasa se aplica `material_override` pe tot subarborele), iar
tiparul citeste tapet. Comentariul avertiza; l-am testat oricum ca sa fie
masurat, si avertismentul e corect.

## Concluzie

Premisa lead-ului e corecta la nivel de diagnostic — flancul E defectul, si e
un singur obiect. Dar tinta binara nu se poate atinge in runda asta fara sa
incalci ceva:
  - prin adaugare de piese pe flanc: se atinge cifra si se strica poza
  - prin clasa triplanara: nu se atinge cifra si se strica poza mai rau
  - prin vertex color: imposibil ca frecventa, 30 px/triunghi
  - prin schimbarea pragului sau a cerului: interzis explicit

**Ce ar rezolva de-adevaratelea:** `erciyes.glb` are nevoie de UV-uri reale si
de subdiviziune (500 verts sunt prea putini), sau de o varianta cu straturi
modelate. Adica munca de asset in Blender, nu de plasare in .tscn. Pana
atunci, dala r0 c3 ramane la 1.12, si asta e o cifra onesta.

Nimic nu s-a comis in Track13.tscn. Toate cele trei incercari au fost
reversate; sondele si generatorul raman, ca runda 34 sa nu le rescrie.
