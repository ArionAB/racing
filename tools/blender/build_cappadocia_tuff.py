"""Cappadocia — TUFF KIT A: formatiunile de piatra (plansa, grupul 9).

  cappadocia/rocks/chimney_{a,b,c,d}.glb   hornuri de zana, 10-18 m, palarie de bazalt
  cappadocia/rocks/chimney_mushroom.glb    hornul-ciuperca (palarie mult mai lata ca gatul)
  cappadocia/rocks/chimney_triple.glb      hornul cu trei palarii (Pasabag)
  cappadocia/rocks/cliff_band_module.glb   felie de faleza in benzi roz-rosu, 20 m
  cappadocia/rocks/rock_church_facade.glb  fatada de biserica rupestra, sapata in con

De ce hornul NU e un con strunjit (brief §0.1, 55% din pista e geologie de tuf):

Runda 1 a retusat culoarea, runda 2 exponentul profilului — si critica oarba
tot a citit panoul drept "engine output", cu motivul scris exact: *"Kill the
revolve. Every cone is the same surface of revolution with the same horizontal
contour banding."* Avea dreptate pe amandoua, si amandoua sunt in MESH:

  1. **un singur con, instantiat.** Cele patru variante ieseau din aceeasi
     formula la scari diferite, deci profilul NORMALIZAT era identic —
     masurat: 100-91-80-68-54-35-19 vs 100-91-79-65-50-34-15. Yaw-ul aleator
     din generator nu schimba nimic pe o suprafata de revolutie. Acum exista o
     FAMILIE de profile (`_profile`): cort, spire, burta, talie, ciot — forme
     diferite ca STRUCTURA, cu inflexiuni si subtaieri, nu un exponent reglat.
  2. **finisaj de strung.** `Builder.revolve` face inele perfect circulare,
     echidistante pe unghi, pe axa dreapta: de acolo veneau "contour lines
     running perfectly parallel to the ground". Corpurile trec pe `tuff_body`,
     care pune canelurile pe VERTICALA (factor de raza fix pe segment, deci
     muchia coboara cu apa, cum cere referinta) si poate curba axa (`lean`),
     deci cateva hornuri chiar se apleaca.
  3. **palaria.** Tot aceeasi lozenga la acelasi unghi pe toate piesele. Acum
     `basalt_cap` primeste `tilt` si `offset`: sta stramb si iese in consola
     asimetric, ca o piatra ramasa in echilibru pe un gat erodat.

Silueta ramane citibila de la 40 m — asta nu s-a schimbat — dar acum e citibila
ca PIESE DIFERITE, care e tot ce cerea critica.

Buget: brief §6 cere `chimney_*` sub 600 tri fiecare, fiindca sunt ~40 pe
pista. Inelele s-au REDISTRIBUIT, nu inmultit: 7 de baza (erau 9) plus trei
indesate in zona poalei, acolo unde muchia dintre crem si rugina are nevoie de
ele. Sus, unde profilul e aproape drept, inelele dese nu descriau nimic. Ferestrele (doar pe `chimney_d`) sunt gauri INFUNDATE (cutii intrate
in corp cu slot intunecat), nu bool-uri — o gaura reala ar cere ca interiorul
sa fie modelat si ar dubla costul pentru ceva ce se vede de la 15 m ca o pata
intunecata. Vezi memoria `decor-manual-din-cod`: gaura pictata bate gaura
reala la scara asta.

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_cappadocia_tuff.py
"""

import math
from mathutils import Matrix, Vector

# AO: hornurile sunt corpuri mari si convexe, deci ocluzia geometrica e aproape
# nula — gradientul vertical face toata munca (baza infipta in pamant, varful
# in soare). `dist` mare fiindca piesele au 10-18 m.
AO_CHIMNEY = dict(samples=20, dist=8.0, gradient="vertical",
                  low=0.42, high=1.00, power=0.85, floor=0.14)
AO_CLIFF = dict(samples=18, dist=10.0, gradient="vertical",
                low=0.46, high=1.00, power=0.80, floor=0.16)
AO_FACADE = dict(samples=26, dist=5.0, gradient="vertical",
                 low=0.40, high=1.00, power=0.90, floor=0.12)

TUFF = CORAL_SAND          # crem de tuf in soare — dominanta pistei
TUFF_MID = SAND_MID        # tuf mediu, banda de variatie de valoare
TUFF_SH = SAND_SHADOW      # tuf umbrit, la baza si sub consola palariei
# POALA ROSIE a hornului — singura separare de nuanta din cadru.
#
# Al patrulea punct al criticii oarbe: "B is monochrome tan. Rock, ground,
# distance and haze are all the same yellow-beige. Zero cream-vs-red
# separation." Masurat pe captura, si cifra confirma ochiul: peretele si solul
# dadeau saturatie 0.589 vs 0.580 si nuanta 37° vs 32° — practic acelasi corp.
#
# Prima incercare a fost un MAL de canion din cliff_band_module, adica rosul de
# la referinta pus intr-un obiect separat. A picat de doua ori la captura: in
# rand continuu citea gard de caramida pana la orizont, iar in pinteni scurti
# devenea zid de blocuri care umple cadrul si taie drumul. Modulul e autorat ca
# buza de canion vazuta DE SUS (brief §5.1), nu ca perete langa care treci la 2 m.
#
# Rosul trebuie sa fie pe silueta care oricum e in cadru, nu langa ea. Valea
# Rosie chiar asa arata: tuful crem sta pe o poala de ocru-rosu, iar linia
# dintre ele e la o treime de inaltime. Costa ZERO — slotul inlocuieste doar
# `TUFF_SH` la baza, pe fetele care existau deja.
# LARCH_RUST (#A8683A), nu TILE_TERRACOTTA (#C4784F): terracotta e slot de
# OLANE, autorat pentru acoperisuri, si la 0.30 din inaltime a iesit portocaliu
# de con de santier — captura a aratat o baie de vopsea, nu geologie. Rugina e
# aceeasi familie de nuanta, dar mai inchisa si mai putin saturata, deci separa
# de crem fara sa sara din paleta.
TUFF_FOOT = LARCH_RUST
CAP = VOLCANIC_BLACK       # palaria de bazalt
BAND_RED = TILE_TERRACOTTA  # banda lata rosie (Valea Rosie)
BAND_RUST = LARCH_RUST     # banda ingusta ruginie
HOLE = ROCK_DARK           # ferestre si usi sapate (gaura "pictata")

FLUTES = 13               # segmente pe circumferinta = canelurile de eroziune
DOOR_WOOD = WOOD


def _r_at(profile, z):
    """Raza profilului la cota z (interpolare liniara intre inele).

    Exista fiindca profilul nu mai e analitic: e o familie de chei interpolate,
    deci o formula scrisa a doua oara (cum era `t ** CONE_EXP` pentru ferestre)
    s-ar desincroniza de suprafata la prima modificare de forma.
    """
    if z <= profile[0][1]:
        return profile[0][0]
    for (r0, z0), (r1, z1) in zip(profile, profile[1:]):
        if z0 <= z <= z1:
            u = 0.0 if z1 <= z0 else (z - z0) / (z1 - z0)
            return r0 + (r1 - r0) * u
    return profile[-1][0]


def _profile(kind, height, r_base, r_neck, seed, steps=7):
    """Profilul (raza, z) al unui corp de tuf, dupa FAMILIE, nu dupa scara.

    Aici e reparatia principala a rundei 3. Pana acum toate hornurile ieseau
    din aceeasi formula (`r_base + (r_neck-r_base) * t**1.35`), deci profilul
    NORMALIZAT era identic pe toate patru — masurat: a/b/c/d dadeau
    100-91-80-68-54-35-19 vs 100-91-79-65-50-34-15. Adica un singur con, scalat
    de patru ori. Critica oarba a numit exact asta ("one cone, instanced";
    "every formation is the same isoceles triangle at a different scale"), si
    avea dreptate in cifre, nu doar in impresie: yaw-ul aleator din generator nu
    schimba nimic pe o suprafata de revolutie, iar scara uniforma cu atat mai
    putin.

    Deci profilul devine o FAMILIE cu forme diferite ca STRUCTURA:

      "spire"   zvelt, umar jos si gat lung — silueta ascutita
      "tent"    indesat, aproape drept de la poala la varf — cortul lat
      "belly"   burta la mijloc (r > r_base pe la 0.22H), apoi strangulare —
                asta da subtaierea pe care referinta o are si noi n-o aveam
      "stub"    ciot: se opreste scurt si gros, fara gat
      "waist"   talie stransa la mijloc si evazare din nou spre palarie

    Nu sunt exponenti diferiti pe aceeasi curba: sunt chei (t, factor)
    interpolate liniar, fiindca doar asa poti pune r > r_base la mijloc (burta)
    sau o inflexiune (talie). O singura formula analitica nu are inflexiuni.
    """
    keys = {
        # (t, raza ca fractie din r_base) — r_neck da capatul de sus
        "spire": [(0.0, 1.00), (0.18, 0.86), (0.42, 0.62), (0.68, 0.38), (1.0, 0.0)],
        "tent":  [(0.0, 1.00), (0.30, 0.90), (0.60, 0.72), (0.85, 0.44), (1.0, 0.0)],
        "belly": [(0.0, 0.88), (0.22, 1.02), (0.45, 0.96), (0.72, 0.52), (1.0, 0.0)],
        "stub":  [(0.0, 1.00), (0.35, 0.93), (0.70, 0.80), (0.92, 0.66), (1.0, 0.0)],
        "waist": [(0.0, 1.00), (0.26, 0.74), (0.52, 0.60), (0.78, 0.66), (1.0, 0.0)],
    }[kind]
    rand = _lcg(seed)
    prof = []
    for i in range(steps):
        t = i / (steps - 1.0)
        # interpolare liniara intre cheile familiei
        f = keys[-1][1]
        for (t0, f0), (t1, f1) in zip(keys, keys[1:]):
            if t0 <= t <= t1:
                u = 0.0 if t1 <= t0 else (t - t0) / (t1 - t0)
                f = f0 + (f1 - f0) * u
                break
        # capatul de sus se aduce pe r_neck, ca palaria sa aiba pe ce sta
        r = r_base * f
        if t > 0.80:
            u = (t - 0.80) / 0.20
            r = r * (1.0 - u) + r_neck * u
        # neregularitate MICA pe verticala: pastreaza ideea de eroziune fara sa
        # refaca inelele orizontale (variatia tare e pe unghi, in `tuff_body`)
        r *= 1.0 + (rand() - 0.5) * 0.05
        prof.append((max(r, 0.05), height * t))
    # INELE IN PLUS in zona poalei (sub ~0.22H). `retag` coloreaza FETE
    # intregi, deci marginea dintre crem si rugina poate urma doar muchiile
    # care exista: cu 9 inele pe toata inaltimea, o fata din zona joasa are
    # peste un metru si linia iesea o treapta dreptunghiulara — masca de
    # vopsea, nu contact geologic. Trei inele suplimentare, dese, dau
    # marginii pe ce sa serpuiasca. Cost: 3 * segments * 2 triunghiuri.
    extra = []
    for u in (0.07, 0.14, 0.21):
        z = height * u
        extra.append((_r_at(prof, z), z))
    prof = sorted(prof + extra, key=lambda rz: rz[1])
    return prof


def tuff_body(b, profile, slot, seed, segments=FLUTES, origin=(0, 0, 0),
              lean=(0.0, 0.0), flute=0.13, twist=0.0):
    """Corpul de tuf: loft cu CANELURI VERTICALE si axa care poate fi inclinata.

    Inlocuieste `Builder.revolve` pe toata familia de hornuri, si asta e a doua
    jumatate a reparatiei din runda 3. `revolve` face exact ce spune numele:
    inele PERFECT circulare, echidistante pe unghi, pe o axa DREAPTA. Din ea nu
    poate iesi decat un obiect strunjit, si critica a citit-o din prima ("that
    is not stratigraphy, that is a topographic map or a lathe finish"; "exposes
    the shape as a revolve"). Nicio retusare de culoare sau de exponent nu
    scoate asta din mesh, fiindca problema E mesh-ul.

    Trei lucruri pe care `revolve` nu le poate face si care sunt aici:

    1. **Caneluri VERTICALE.** Fiecare segment de pe circumferinta primeste un
       factor de raza propriu, CONSTANT pe toata inaltimea (`fl[]` se calculeaza
       o singura data, in afara buclei pe inele). Asa iese o muchie care coboara
       de sus pana jos — santurile de siroire pe care le are referinta ("the
       marks run *down* the cone with the water, not around it"). Daca factorul
       s-ar recalcula pe fiecare inel, ar iesi zgomot, adica exact inelele
       orizontale pe care le scoatem.
    2. **Axa inclinata / curbata.** `lean` = deplasarea (dx, dy) a varfului fata
       de baza, aplicata cu t**1.6 ca sa iasa o curba (piesa se apleaca tot mai
       tare spre varf), nu o piesa dreapta pusa strambа. Cateva hornuri aplecate
       rup imediat citirea de "sir de conuri identice".
    3. **Rasucire.** `twist` roteste inelele cu inaltimea, deci canelurile ies
       usor spiralate, ca la formatiunile reale scobite de vant.

    Costul e acelasi ca la `revolve` (segments*(steps-1)*2 triunghiuri): nu se
    adauga geometrie, doar se aseaza altfel vertecsii care oricum existau.
    """
    ox, oy, oz = origin
    rand = _lcg(seed + 17)
    # factorii de canelura: FIXATI pe segment, deci muchia e verticala
    fl = []
    for i in range(segments):
        # doua armonici pe unghi + zgomot: santuri de latimi diferite, altfel
        # canelura devine ea insasi un motiv regulat (o "roata dintata")
        a = 2.0 * math.pi * i / segments
        w = (math.sin(a * 3.0 + seed * 0.7) * 0.55
             + math.sin(a * 5.0 + seed * 1.3) * 0.30
             + (rand() - 0.5) * 1.10)
        fl.append(1.0 + flute * w)

    top_z = profile[-1][1] if profile[-1][1] > 1e-6 else 1.0
    rings, apex = [], None
    for (r, z) in profile:
        t = z / top_z
        # axa: deplasare progresiva (t**1.6), deci CURBA, nu inclinare rigida
        cx = ox + lean[0] * (t ** 1.6)
        cy = oy + lean[1] * (t ** 1.6)
        if r <= 1e-6:
            apex = b.bm.verts.new((cx, cy, oz + z))
            break
        # canelurile se sting spre varf: sus piesa e subtire si santurile ar
        # inghiti-o (raza ar trece prin zero pe segmentele negative)
        damp = 1.0 - 0.55 * t
        ring = []
        for i in range(segments):
            a = 2.0 * math.pi * i / segments + twist * t
            rr = r * (1.0 + (fl[i] - 1.0) * damp)
            ring.append(b.bm.verts.new((cx + rr * math.cos(a),
                                        cy + rr * math.sin(a), oz + z)))
        rings.append(ring)

    new_verts = [v for ring in rings for v in ring] + ([apex] if apex else [])
    for lo, hi in zip(rings, rings[1:]):
        for i in range(segments):
            j = (i + 1) % segments
            b.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    if apex and rings:
        top = rings[-1]
        for i in range(segments):
            j = (i + 1) % segments
            b.bm.faces.new((top[i], top[j], apex))
    if rings:
        b.bm.faces.new(tuple(reversed(rings[0])))
    return b._tag(new_verts, slot)


def basalt_cap(b, z, r_neck, r_cap, thickness, seed=0, segments=9,
               tilt=0.0, offset=(0.0, 0.0), center=(0.0, 0.0)):
    """Palaria de bazalt: con TURTIT asezat pe gat, cu consola mica.

    `tilt`, `offset` si `center` sunt noi in runda 3, si sunt jumatate din
    raspunsul la "every cap is the same dark lozenge at the same angle".
    Palaria reala e o bucata de bazalt ramasa in echilibru pe un gat care s-a
    erodat sub ea: sta STRAMB si iese in consola pe o parte. Cu toate palariile
    orizontale si centrate, cele ~40 de piese de pe pista aveau acelasi accent
    negru identic, repetat.

    `tilt` e in radiani si deplaseaza cele doua frustumuri pe arcul de bascula;
    `offset` mai si muta palaria in lateral, deci consola devine asimetrica;
    `center` o aseaza peste varful unui corp INCLINAT (`lean` din `tuff_body`).
    """
    rand = _lcg(seed + 91)
    wob = 1.0 + (rand() - 0.5) * 0.10
    cx, cy = center
    dx, dy = offset

    def _put(zc, rb, rt, th):
        # frustum-ul e pe axa Z; inclinarea se face mutand centrul pe arcul de
        # bascula. Piesele au 1-1.5 m, deci fata inclinata nu se citeste de la
        # 15 m — dar DEPLASAREA se citeste imediat pe silueta.
        px = cx + dx + (zc - z) * math.sin(tilt)
        py = cy + dy
        b.frustum((px, py, zc), rb, rt, th, CAP, segments=segments)

    _put(z - thickness * 0.22, r_neck * 1.02, r_cap * wob, thickness * 0.44)
    _put(z + thickness * 0.30, r_cap * wob, r_cap * 0.30 * wob, thickness * 0.85)
    return r_cap * wob


def carve_window(b, cx, cy, cz, w, h, depth, normal, slot=HOLE):
    """Fereastra "sapata": cutie intrata in corp, tag-uita intunecat.

    NU e o gaura reala. La 15 m distanta (cea mai apropiata pozitie in care
    hornurile de langa banda se vad — brief §2.0) o cavitate de 0.6 m citeste
    identic cu o pata intunecata cu buza in umbra, si costa 12 tri in loc de
    ~90 plus un interior.
    """
    n = Vector(normal).normalized()
    ang = math.atan2(n.y, n.x)
    rot = Matrix.Rotation(ang, 3, "Z")
    c = Vector((cx, cy, cz)) - n * (depth * 0.35)
    b.box(tuple(c), (depth, w, h), slot, rotation=rot)
    # buza de sus: praguri de sapare, prind lumina razanta de zori
    lip = Vector((cx, cy, cz + h * 0.5 + 0.06)) + n * 0.05
    b.box(tuple(lip), (depth * 0.9, w * 1.12, 0.10), TUFF_SH, rotation=rot)


# Cele patru hornuri de baza. Runda 3: difera prin FAMILIE de profil, prin
# inclinare si prin palarie, nu doar prin scara.
#  (kind,   H,    r_base, r_neck, cap_t, lean,          tilt,  seed)
CHIMNEY_SPEC = [
    ("tent",  10.5, 3.55, 0.70, 1.05, (0.00, 0.00), 0.16, 7),
    ("spire", 14.6, 3.10, 0.46, 0.95, (0.95, -0.35), 0.09, 23),
    ("belly", 16.4, 3.85, 0.62, 1.25, (-0.55, 0.40), -0.21, 41),
    ("waist", 12.6, 3.70, 0.80, 1.05, (0.30, 0.60), 0.05, 59),
]


def build_chimney(variant):
    """Un horn din familia de baza.

    Ce s-a schimbat in runda 3 si DE CE (critica oarba, verdict 3/10 pe
    "geometry is one asset repeated"): pana acum cele patru variante erau
    acelasi profil normalizat la scari diferite, invelit in inelele orizontale
    ale lui `revolve`. Acum:
      - profilul vine din `_profile(kind, ...)`, deci a/b/c/d au forme DIFERITE
        ca structura (cort, spire, burta, talie), nu doar dimensiuni;
      - corpul se face cu `tuff_body`: caneluri VERTICALE si axa curbata
        (`lean`), deci nu mai e suprafata de revolutie;
      - palaria e inclinata si decentrata (`tilt`/`offset`), diferit pe fiecare.
    """
    b = Builder()
    kind, H, R_BASE, R_NECK, CAP_T, LEAN, TILT, SEED = CHIMNEY_SPEC[variant]

    prof = _profile(kind, H, R_BASE, R_NECK, SEED)
    faces = tuff_body(b, prof, TUFF, SEED, lean=LEAN, flute=0.15,
                      twist=0.10 if variant % 2 else -0.07)

    # O SINGURA calcare de valoare, jos, si fara muchie orizontala.
    #
    # Ramane doar praful de la baza, taiat pe o cota NEregulata (variaza cu
    # unghiul in jurul axei) ca sa nu iasa un inel perfect. Cu canelurile
    # verticale marginea se rupe si mai bine: pragul cade pe fete aflate la
    # raze diferite, deci nu mai exista un inel de fete la aceeasi cota pe
    # care sa se aseze o dunga.
    b.retag(faces, TUFF_FOOT,
            where=lambda c, n, h=H: c.z < h * (0.17 + 0.055 * math.sin(
                math.atan2(c.y, c.x) * 3.0)
                + 0.035 * math.sin(math.atan2(c.y, c.x) * 7.0 + 1.1)))

    # varful conului DUPA inclinare: palaria trebuie sa stea PE el
    basalt_cap(b, H, R_NECK, R_NECK * 1.30, CAP_T, seed=SEED, tilt=TILT,
               center=(LEAN[0], LEAN[1]),
               offset=(R_NECK * 0.22, -R_NECK * 0.15))

    if variant == 3:
        # hornul locuit: usa la baza + trei ferestre pe fata (spre +Y = -Z Godot)
        carve_window(b, 0.0, R_BASE * 0.90, 1.05, 1.05, 1.85, 0.55, (0, 1, 0),
                     slot=DOOR_WOOD)
        for (fz, fa, fw) in ((4.4, 8.0, 0.62), (6.9, -34.0, 0.55),
                             (8.8, 26.0, 0.50)):
            # raza REALA la cota `fz`, citita din profilul construit
            r = _r_at(prof, fz) * 0.94
            t = fz / H
            cx = LEAN[0] * (t ** 1.6)
            cy = LEAN[1] * (t ** 1.6)
            a = math.radians(90.0 + fa)
            carve_window(b, cx + r * math.cos(a), cy + r * math.sin(a), fz,
                         fw, fw * 1.25, 0.45, (math.cos(a), math.sin(a), 0))

    return b.to_object("Chimney_" + "ABCD"[variant])


def build_chimney_mushroom():
    """Hornul-ciuperca: gatul ROADE pana aproape de nimic sub o palarie enorma.

    Proportia e tot: palaria are 3.1x raza gatului. Sub 2.5x arata ca un horn
    obisnuit cu capac; masurat pe randarea de control, 2.4x inca citea drept
    "capac", nu drept palarie de ciuperca. Piesa asta e "citatul" din Pasabag pe care il pui langa drum ca
    reper de POI.
    """
    b = Builder()
    # baza latita ca la restul familiei (vezi `build_chimney`): ciuperca statea
    # pe 2.15 m si iesea un pai cu palarie, langa conuri de 3.3-4.3 m
    H, R_BASE, R_NECK = 11.2, 3.20, 0.62
    # familia "waist": talia stransa E subiectul ciupercii, deci profilul o are
    # deja in chei — nu mai e nevoie de strangularea lipita peste profil.
    prof = _profile("waist", H, R_BASE, R_NECK, 103, steps=7)
    faces = tuff_body(b, prof, TUFF, 103, lean=(-0.42, 0.28), flute=0.17,
                      twist=0.14)
    # aceleasi doua motive ca la `build_chimney`: fara banda de mijloc, si
    # praful de la baza taiat pe o cota neregulata (ciuperca e cea mai numeroasa
    # piesa de langa banda, deci dungile ei se vedeau cel mai des)
    b.retag(faces, TUFF_FOOT,
            where=lambda c, n, h=H: c.z < h * (0.15 + 0.050 * math.sin(
                math.atan2(c.y, c.x) * 3.0 + 0.9)
                + 0.032 * math.sin(math.atan2(c.y, c.x) * 7.0 + 2.3)))
    # palaria enorma sta pe varful DEPLASAT si e inclinata mai tare decat la
    # restul familiei: consola larga inclinata e chiar silueta din Pasabag
    basalt_cap(b, H, R_NECK * 0.80, R_NECK * 3.10, 1.55, seed=103, segments=10,
               tilt=-0.13, center=(-0.42, 0.28), offset=(0.30, 0.12))
    return b.to_object("Chimney_Mushroom")


def build_chimney_triple():
    """Trei hornuri crescuti din acelasi soclu — silueta din Valea Calugarilor.

    Un soclu comun (nu trei piese separate): asa se planteaza intr-un singur
    world_prop si coliziunea e una singura. Inaltimile sunt DIFERITE si
    neregulate, altfel citeste ca o furculita.
    """
    b = Builder()
    # soclul comun, o movila joasa
    # Soclul s-a LATIT odata cu gaturile: cu bazele conice de 2.1-2.7 m raza,
    # cel mai departat ajunge la x=+5.7, deci pe 8 m latime picioarele ar fi
    # atarnat in aer. Masurat pe extentele reale ale celor trei, nu pe AABB.
    b.rock((0.0, 0.0, 0.0), (12.4, 8.4, 3.2), TUFF_SH, seed=311, segments=9,
           rings=3, flat_top=True, taper=0.30)

    # Cele trei gaturi au FAMILII diferite si se apleaca in directii diferite —
    # asta e ce transforma piesa din "furculita" in grup. Al treilea ramane
    # descoperit (`cap=False`): referinta are conuri fara palarie, si un ciot
    # tesit langa doua cu caciula citeste imediat ca formatiune, nu ca set.
    #        x      y     h    rb    rn    ct   lean          kind    cap  seed
    stems = [(-2.60, -0.60, 12.8, 2.45, 0.48, 0.95, (0.55, 0.30), "spire", True, 17),
             (1.35, 1.05, 15.6, 2.70, 0.52, 1.05, (-0.40, 0.62), "belly", True, 53),
             (3.60, -1.60, 9.4, 2.10, 0.44, 0.82, (0.70, -0.45), "stub", False, 89)]
    for (x, y, h, rb, rn, ct, lean, kind, cap, seed) in stems:
        prof = _profile(kind, h, rb, rn, seed)
        base_z = 2.15
        faces = tuff_body(b, prof, TUFF, seed, segments=11,
                          origin=(x, y, base_z), lean=lean, flute=0.16,
                          twist=0.12 if seed % 2 else -0.11)
        # poala rosie si pe gaturile hornului triplu: piesa e cea mai vizibila
        # din familie (trei siluete deodata), deci daca ei ii lipseste separarea
        # de nuanta, lipseste din cadru.
        b.retag(faces, TUFF_FOOT,
                where=lambda c, n, bz=base_z, hh=h, px=x, py=y:
                    c.z < bz + hh * (0.16 + 0.05 * math.sin(
                        math.atan2(c.y - py, c.x - px) * 3.0)
                        + 0.03 * math.sin(math.atan2(c.y - py, c.x - px) * 7.0)))
        if not cap:
            continue
        basalt_cap(b, base_z + h, rn, rn * 1.30, ct, seed=seed, segments=9,
                   tilt=0.18 if seed == 17 else -0.15,
                   center=(x + lean[0], y + lean[1]),
                   offset=(rn * 0.25, rn * 0.18))
    return b.to_object("Chimney_Triple")


def build_cliff_band_module():
    """Felie de faleza in BENZI, 20 m lungime — modul de cornisa si de canion.

    Benzile roz-rosu sunt cerinta explicita din brief §5.1: "benzile in textura
    de clasa, nu in geometrie". Aici sunt totusi geometrie SUBTIRE (straturi de
    0.8-1.6 m), din doua motive:
      - modulul e folosit si acolo unde nu ajunge clasa `tuff_banded` (capete,
        colturi), si trebuie sa citeasca la fel;
      - `retag` face benzile pe fetele EXISTENTE ale straturilor, deci costul e
        zero peste geometria oricum necesara.
    Ordinea benzilor e cea reala din Valea Rosie: crem jos, rosu lat la mijloc,
    ruginiu ingust, crem sus (partea de sub platou).

    `origin="base_axis"`: modulele se insiruie cap la cap pe X, deci bbox-ul
    NU se recentreaza (memoria `chongqing-assets-kit`, piesele modulare).
    """
    b = Builder()
    L, D = 20.0, 4.5
    # straturi: (grosime, slot, retragere fata de cel de dedesubt)
    layers = [(1.6, TUFF_SH, 0.00), (1.2, BAND_RED, 0.18), (0.8, BAND_RUST, 0.30),
              (1.5, BAND_RED, 0.42), (1.1, TUFF_MID, 0.66), (1.9, TUFF, 0.82),
              (1.4, BAND_RUST, 1.05), (2.2, TUFF, 1.20)]
    z = 0.0
    rand = _lcg(457)
    for (t, slot, back) in layers:
        d = D - back
        # fiecare strat e usor mai scurt si decalat -> profil erodat, nu scara
        jitter = (rand() - 0.5) * 0.35
        b.box((jitter, -back * 0.5, z + t * 0.5), (L, d, t), slot)
        z += t

    # buza de sus, in consola: ce se vede de pe cornisa privind in jos
    b.box((0.0, -1.20 * 0.5 + 0.15, z + 0.35), (L, D - 1.20, 0.70), TUFF)

    # moloz la baza — fusta care leaga faleza de fundul vaii
    for i in range(7):
        fx = -L * 0.5 + L * (rand() * 0.94 + 0.03)
        s = 0.55 + rand() * 0.85
        b.rock((fx, D * 0.5 + rand() * 0.8, 0.0), (s * 2.1, s * 1.7, s),
               TUFF_SH, seed=int(rand() * 900), segments=6, rings=3, taper=0.55)
    return b.to_object("Cliff_Band_Module")


def build_rock_church_facade():
    """Fatada de biserica rupestra: con de tuf cu portal sapat si cruce incizata.

    Piesa de POI, nu de statistica: se pune UNA pe pista (brief §1, Goreme).
    Portalul e un arc SAPAT (arcada in trepte, tag-uita intunecat), plus doua
    ferestre ogivale si o cruce in relief negativ. Tot pe "gaura pictata" —
    interiorul nu exista, fiindca nu se intra in el.
    """
    b = Builder()
    H, R_BASE, R_NECK = 14.0, 4.20, 1.55
    # "tent": fatada trebuie sa aiba un perete aproape drept in care sa incapa
    # portalul, deci cortul indesat, nu spire-ul. Fara `lean`: pe piesa asta se
    # sapa un portal aliniat, iar o axa curbata l-ar aseza stramb.
    prof = _profile("tent", H, R_BASE, R_NECK, 601, steps=7)
    faces = tuff_body(b, prof, TUFF, 601, segments=13, flute=0.10)
    # idem pe fatada bisericii: e tot un con de tuf, langa drum
    b.retag(faces, TUFF_FOOT,
            where=lambda c, n, h=H: c.z < h * (0.14 + 0.045 * math.sin(
                math.atan2(c.y, c.x) * 3.0 + 2.4)
                + 0.030 * math.sin(math.atan2(c.y, c.x) * 7.0 + 0.4)))
    basalt_cap(b, H, R_NECK, R_NECK * 1.95, 1.45, seed=601, segments=10)

    y = R_BASE * 0.86
    # portalul: golul + arcada in trepte deasupra lui
    b.box((0.0, y - 0.35, 2.05), (0.90, 2.30, 4.10), HOLE)
    for i, (w, dz) in enumerate(((2.55, 4.20), (2.15, 4.62), (1.60, 4.96))):
        b.box((0.0, y - 0.10, dz), (0.55, w, 0.34), TUFF_SH if i else TUFF_MID)
    # doua ferestre ogivale, flancand portalul
    for sx in (-1.0, 1.0):
        carve_window(b, sx * 2.05, y * 0.92, 6.35, 0.68, 1.15, 0.45, (0, 1, 0))
    # crucea incizata deasupra portalului (doua bare intrate in corp)
    b.box((0.0, y - 0.12, 8.30), (0.30, 0.28, 1.60), HOLE)
    b.box((0.0, y - 0.12, 8.62), (0.30, 1.20, 0.28), HOLE)
    # pragul de intrare, iesit in fata
    b.box((0.0, y + 0.30, 0.12), (1.10, 2.80, 0.24), TUFF_MID)
    return b.to_object("Rock_Church_Facade")


clear_built()

results = []


def emit(obj, path, ao, origin="base", bevel=0.05):
    st = finish(obj, bevel=bevel, ao=ao, origin=origin)
    _, sz = export_glb([obj], "cappadocia/" + path)
    results.append((path, st["tris"], sz / 1024.0))


for v in range(4):
    emit(build_chimney(v), "rocks/chimney_%s.glb" % "abcd"[v], AO_CHIMNEY)
emit(build_chimney_mushroom(), "rocks/chimney_mushroom.glb", AO_CHIMNEY)
emit(build_chimney_triple(), "rocks/chimney_triple.glb", AO_CHIMNEY)
emit(build_cliff_band_module(), "rocks/cliff_band_module.glb", AO_CLIFF,
     origin="base_axis", bevel=0.06)
emit(build_rock_church_facade(), "rocks/rock_church_facade.glb", AO_FACADE)

print()
for path, tris, kb in results:
    print("%-40s tris=%6d %8.1f kB" % (path, tris, kb))
print("TOTAL tuff kit A: %d tris" % sum(t for _, t, _ in results))
