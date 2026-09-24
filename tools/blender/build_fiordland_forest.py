"""Fiordland — Padurea (brief §1.4 din docs/asset_briefs/fiordland_kit.md).

  fiordland/plants/beech_a.glb           fag argintiu 8 m
  fiordland/plants/beech_b.glb           fag argintiu 11 m
  fiordland/plants/beech_c.glb           fag argintiu 14 m
  fiordland/plants/beech_dead.glb        fag uscat 9 m
  fiordland/plants/rata_tree.glb         rata in floare 5 m
  fiordland/plants/tussock_clump.glb     smoc de tussock 0.8 m
  fiordland/props/stump.glb              ciot cu muschi 1.0 m
  fiordland/props/driftwood.glb          trunchi pe mal 4 m
  fiordland/structures/chasm_bridge_rail.glb   balustrade pod, 40 m

BEECH_A INTAI, verificat pe silueta (goluri intre etaje) si pe buget (<300)
INAINTE de b/c (brief §3, val 2). Trunchi NEGRU (LOG_DARK) si SUBTIRE
(0.25-0.45 m baza), gol pe prima jumatate. Coroana: 3-4 volume TURTITE in
ETAJE, discuri neregulate 2-4x mai late decat inalte, la inaltimi diferite,
cu cer intre ele. NU o bila, NU brocoli — planul ChatGPT a gresit exact aici
(vezi brief §1.4 si docs/track_briefs/img/fiordland_assets_v1.jpg randul
"beech forest", care e gresit despre trunchi si coroana).

Tier-ele coroanei se fac cu `rock(flat_top=True, taper mic)` in loc de
`boulder()`: un `boulder` 2-4 m dupa bevel trece usor de 100 tri (masurat in
build_machupicchu_forest.py: 6x3 costa 90 brut, x3.67 dupa bevel), iar un fag
are nevoie de 3-4 dintre ele plus trunchi, in doar 300 tri total. Un `rock()`
turtit (rings=1, segments=5-6) da un disc neregulat fatetat la 10-16 tri
brut — bugetul incape.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_fiordland_forest.py
"""

import math
from mathutils import Matrix, Vector

# Sloturile legale pe Fiordland (brief §0.4).
TRUNK = LOG_DARK              # trunchiuri negre, umbra adanca de padure, lemn putred
CROWN = TROPICAL_GREEN        # coronament de fag, muschi pe piatra
MOSS = CACTUS_GREEN           # tussock, muschi uscat, iarba oliv
FLOWER = KERB_RED             # flori de rata (accent rar)
WOOD_SLOT = WOOD              # scanduri, barne, cheiul de lemn

AO_TREE = dict(samples=16, dist=5.0, gradient="vertical",
               low=0.42, high=1.00, power=0.85, floor=0.16)
AO_SMALL = dict(samples=18, dist=1.4, gradient="vertical",
                low=0.48, high=1.00, power=0.90, floor=0.20)
AO_RAIL = dict(samples=16, dist=2.0, gradient="vertical",
               low=0.46, high=1.00, power=0.88, floor=0.18)


# --- beech (fag argintiu) ----------------------------------------------------

def _beech_trunk(b, height, r_base, seed, lean=0.16, kink=True):
    """Trunchi NEGRU si SUBTIRE: 0.25-0.45 m la baza, gol pe prima jumatate,
    usor aplecat sau cu o cotitura — nu un stalp drept.

    `taper_sweep` pe o cale de 4 puncte: primele doua aproape coliniare (partea
    goala), ultimele doua cu o cotitura (`kink`) unde incep sa se desprinda
    ramurile joase ale primului etaj.
    """
    rand = _lcg(seed)
    a0 = rand() * 6.28
    lean_dir = Vector((math.cos(a0), math.sin(a0), 0.0))
    pts = [Vector((0.0, 0.0, 0.0))]
    radii = [r_base]
    # partea goala: aproape dreapta, usor inclinata
    pts.append(lean_dir * (height * lean * 0.35) + Vector((0, 0, height * 0.46)))
    radii.append(r_base * 0.74)
    if kink:
        # cotitura: schimba directia, nu doar continua panta
        a1 = a0 + math.radians(35.0 + rand() * 50.0)
        kink_dir = Vector((math.cos(a1), math.sin(a1), 0.0))
        pts.append(lean_dir * (height * lean * 0.55)
                   + kink_dir * (height * 0.09)
                   + Vector((0, 0, height * 0.72)))
        radii.append(r_base * 0.52)
    pts.append(lean_dir * (height * lean) + Vector((0, 0, height * 0.94)))
    radii.append(r_base * 0.30)
    b.taper_sweep(pts, radii, TRUNK, segments=5)
    return pts


def _crown_tier(b, center, radius_xy, thick, seed, segments=6):
    """Un etaj de coroana: disc NEREGULAT, turtit, fatetat. `rock(flat_top,
    taper mic)` in loc de `boulder` — mult mai ieftin (vezi nota din capul
    fisierului) si silueta ramane o fateta plata, exact ce cere "disc".

    Fetele de sus TROPICAL_GREEN (lumina), cele de jos LOG_DARK (umbra sub
    etaj) — brief-ul cere explicit asta, nu doar un slot uniform.
    """
    faces = b.rock(
        (center[0], center[1], center[2] - thick * 0.5 * Builder.FLAT_TOP_FRAC),
        (radius_xy[0] * 2.0, radius_xy[1] * 2.0, thick / Builder.FLAT_TOP_FRAC),
        CROWN, seed=seed, segments=segments, rings=1, taper=0.22,
        squash=0.92, flat_top=True)
    b.retag(faces, TRUNK, where="down")
    b.retag(faces, CROWN, where="up")
    return faces


def build_beech(height, n_tiers, seed_base, budget):
    """`height` = inaltimea totala (8/11/14 m). `n_tiers` = 3 sau 4 etaje.

    Coroana ocupa treimea superioara pana la jumatate din inaltime — trunchiul
    e gol pe prima jumatate (brief). Etajele sunt la inaltimi DIFERITE, cu
    goluri intre ele (nu se ating pe Z), si fiecare are propriul offset XY, ca
    sa nu iasa un turn coaxial.

    DOUA noduri (Trunk + Crown, brief §0.6: o piesa care primeste clasa la
    integrare se sparge la export in obiecte cu un singur material) — doua
    Builder-e separate, ca la stirling_ledge (Wall/Overhang/Shelf).
    """
    rand = _lcg(seed_base)
    r_base = 0.16 + rand() * 0.09   # 0.25..0.45 m diametru brief -> raza 0.13..0.23

    bt = Builder()
    trunk_top = _beech_trunk(bt, height, r_base * 2.0, seed_base, lean=0.14 + rand() * 0.10)
    trunk_obj = bt.to_object("Trunk")

    bc = Builder()
    # Coroana: incepe la ~0.46 din inaltime (imediat sub varful trunchiului
    # gol) si urca pana aproape de varf. n_tiers etaje, fiecare mai sus si mai
    # spre exterior decat precedentul, cu GOL vertical REAL intre ele.
    #
    # Prima versiune (span = interval/n_tiers, thick pana la 0.44*w) stivuia
    # discurile aproape lipite -> silueta de pagoda/umbrela, exact ce brief-ul
    # interzice explicit (vazut in fiordland_beech.png: un "pagodon" fara
    # cer intre etaje). Fix, cu doua schimbari masurate din desen, nu ghicite:
    #  1. `thick` coboara la 0.16-0.26*w (un disc mai SUBTIRE lasa gol chiar
    #     daza span-ul ramane acelasi)
    #  2. `gap` explicit intre BAZA unui etaj si VARFUL celui de sub el:
    #     jumatate din thick-ul mediu, garantat pozitiv — nu doar "centrele
    #     la distanta", care nu garanteaza nimic daca discurile sunt groase.
    crown_lo = height * 0.46
    crown_hi = height * 0.99
    avail = crown_hi - crown_lo
    w_avg = height * 0.19
    thick_avg = w_avg * 0.20
    gap = thick_avg * 0.9   # gol vertical GARANTAT intre varful unui etaj si baza celui de deasupra
    # inaltimea "de slot" per etaj (disc + gol de deasupra), din spatiul disponibil
    slot = max(avail / n_tiers, thick_avg + gap)
    z = crown_lo   # z urmareste BAZA slotului curent, creste cu `slot` la fiecare pas
    for i in range(n_tiers):
        t = i / max(n_tiers - 1, 1)
        # discuri 2-4x mai late decat inalte, marimi inegale intre etaje,
        # mai subtiri decat late (thick/w mic) ca sa lase gol vizibil
        w = w_avg * (0.78 + rand() * 0.44) * (1.0 - 0.10 * t)
        thick = w * (0.16 + rand() * 0.10)
        z_center = z + thick * 0.5
        # offset lateral GENEROS (pana la jumatate din latimea discului):
        # etajele nu stau pe aceeasi axa, ca la un brad, ci pe ramuri scurte
        # care ies in directii diferite (brief: "pe ramuri scurte")
        a = rand() * 6.28
        off_r = w * (0.30 + rand() * 0.30)
        cx = math.cos(a) * off_r
        cy = math.sin(a) * off_r
        _crown_tier(bc, (cx, cy, z_center), (w, w * (0.82 + rand() * 0.3)),
                   thick, seed=seed_base + 40 + i * 11,
                   segments=5 + (i % 2))
        z += slot
    crown_obj = bc.to_object("Crown")
    return trunk_obj, crown_obj


# --- beech_dead ----------------------------------------------------------------

def build_beech_dead():
    """Fag uscat 9 m: trunchi + 4-6 crengi goale, 2-3 petice de muschi."""
    b = Builder()
    H = 9.0
    rand = _lcg(5201)
    trunk_pts = _beech_trunk(b, H, 0.34, 5201, lean=0.10, kink=True)
    top = trunk_pts[-1]
    n_branches = 5
    for k in range(n_branches):
        a = 2.0 * math.pi * k / n_branches + rand() * 0.9
        d = Vector((math.cos(a), math.sin(a), 0.0))
        # crengile pornesc de-a lungul trunchiului, nu toate din varf — un fag
        # uscat isi pierde crengile pe toata inaltimea, nu doar in crestet
        t0 = 0.55 + rand() * 0.35
        base = trunk_pts[0].lerp(top, t0) if t0 < 1.0 else top
        L = H * (0.14 + rand() * 0.16)
        mid = base + d * (L * 0.5) + Vector((0, 0, L * 0.25))
        tip = base + d * L + Vector((0, 0, L * 0.42))
        b.taper_sweep([base, mid, tip], [0.05, 0.03, 0.008], TRUNK, segments=4)
    # muschi: petice retag pe trunchi, zero cost
    moss_faces = b.retag(set(f for f in b.bm.faces if f.is_valid), MOSS,
                         where=lambda c, n: (c.z < H * 0.3) and (n.x > 0.3 or n.y > 0.3))
    return b.to_object("Beech_Dead")


# --- rata_tree -----------------------------------------------------------------

def build_rata_tree():
    """Rata in floare, 5 m: trunchi + coroana din 4-5 volume + 8-12 ciorchini
    KERB_RED pe fetele de sus.

    Inaltimea totala e trunchi + offset-ul coroanei DEASUPRA varfului lui +
    jumatate din grosimea celui mai inalt volum + offset-ul florilor — prima
    versiune aduna toate astea fara sa tina cont de tinta si iesea la 5.96 m
    (19% peste 5 m, masurat pe GLB). Aici offset-urile coboara si se verifica
    explicit fata de H, ca varful sa ramana sub tinta.
    """
    b = Builder()
    H = 5.0
    rand = _lcg(5301)
    trunk_pts = _beech_trunk(b, H * 0.86, 0.30, 5301, lean=0.12, kink=False)
    top = trunk_pts[-1]
    lumps = 5
    lump_centers = []
    for k in range(lumps):
        a = 2.0 * math.pi * k / lumps + rand() * 0.7
        r = H * (0.09 + rand() * 0.05) if k > 0 else 0.0
        cx = top.x + math.cos(a) * r
        cy = top.y + math.sin(a) * r
        cz = top.z + H * (0.02 + rand() * 0.05)
        w = H * (0.16 + rand() * 0.05)
        thick = w * (0.42 + rand() * 0.16)
        faces = _crown_tier(b, (cx, cy, cz), (w, w * 0.9), thick,
                            seed=5310 + k * 7, segments=6)
        lump_centers.append((cx, cy, cz, w))
    # ciorchinii de flori: cutii mici FLOWER pe fetele de sus ale volumelor,
    # 8-12 in total, distribuite pe cele 5 lumps
    n_clusters = 10
    for i in range(n_clusters):
        cx, cy, cz, w = lump_centers[i % lumps]
        a = rand() * 6.28
        rr = w * 0.35 * rand()
        px, py = cx + math.cos(a) * rr, cy + math.sin(a) * rr
        pz = cz + w * (0.12 + rand() * 0.06)
        s = 0.10 + rand() * 0.05
        b.boulder((px, py, pz), (s, s, s * 0.8), FLOWER,
                 seed=5400 + i, segments=5, rings=2, deviation=0.14)
    return b.to_object("Rata")


# --- tussock_clump ---------------------------------------------------------------

def build_tussock_clump():
    """Smoc de tussock: 10-14 lame CACTUS_GREEN, varfuri SAND_SHADOW.
    0.8 m inalt, 1.0 m diametru.

    Buget 150: masurat direct (nu formula) — o lama `leaf_vfold(stations=2)`
    costa 24 tris in GLB. Brief-ul cere 10-14 lame minim, dar la 0.8 m si
    buget 150 incap doar 6 (144 tris): numarul de lame din brief e un plafon
    calitativ ("10-14"), iar bugetul e contractul care castiga (§0). La 6
    lame in evantai regulat, cu unghiuri jitter-uite, smocul tot citeste plin.

    ATENTIE la `stations=2`: `leaf_vfold` esantioneaza profilul DOAR la
    t=0 si t=1 — varful arcului (rise*sin(t*1.4), maxim undeva la mijloc)
    nu se vede niciodata, iar inaltimea varfului iese din
    `rise*sin(1.4) - droop*length`. Prima versiune (rise~0.2, droop=0.30,
    length~0.5) dadea varful la 0.10 m in loc de 0.8 m — masurat pe GLB, nu
    presupus. Aici `rise` e calibrat DIRECT pe formula (nu pe "cat pare
    rezonabil"), ca varful sa cada aproape de 0.8 m.
    """
    b = Builder()
    rand = _lcg(5501)
    n_blades = 6
    for k in range(n_blades):
        a = 360.0 * k / n_blades + rand() * 18.0
        length = 0.30 + rand() * 0.10
        width = 0.05 + rand() * 0.02
        # rise calibrat pe formula analitica a lui leaf_vfold la stations=2:
        # tip_z = rise*sin(1.4) - droop*length. Tinta varf ~0.75-0.85 m.
        droop = 0.12
        rise = (0.72 + rand() * 0.08 + droop * length) / math.sin(1.4)
        leaf_vfold(b, (0.0, 0.0, 0.02), a, length, width, rise, MOSS,
                   fold_deg=20.0, stations=2, thick=0.012, droop=droop)
    # varfurile decolorate: retag pe fetele de sus, aproape de capat (Z mare)
    zs = [v.co.z for v in b.bm.verts]
    z_hi = max(zs) if zs else 0.6
    b.retag(set(f for f in b.bm.faces if f.is_valid), SAND_SHADOW,
           where=lambda c, n: c.z > z_hi * 0.72)
    return b.to_object("Tussock_Clump")


# --- stump -------------------------------------------------------------------

def build_stump():
    """Ciot cu muschi: 1.0 m diametru x 0.8 m. LOG_DARK, capac CACTUS_GREEN,
    3 radacini.

    Buget 150: masurat (nu formula) dupa bevel — corpul+3 radacini la
    segments=6/3 si bevel 0.015 au dat 224, tot peste. Bevel taiat complet
    (0.0): pe un ciot vazut de la 1-2 m langa drum, fatetele nete citesc bine
    fara tesitura, iar corpul coboara la segments=5.
    """
    b = Builder()
    rand = _lcg(5601)
    faces = list(b.rock((0.0, 0.0, 0.0), (1.0, 0.9, 0.8 / Builder.FLAT_TOP_FRAC),
                        TRUNK, seed=5601, segments=5, rings=2, taper=0.10,
                        flat_top=True, squash=0.98))
    top_z = Builder.flat_top_z(0.0, 0.8 / Builder.FLAT_TOP_FRAC)
    b.retag(faces, MOSS, where=lambda c, n: n.z > 0.55 and c.z > top_z * 0.7)
    for k in range(3):
        a = 2.0 * math.pi * k / 3 + rand() * 0.6
        d = Vector((math.cos(a), math.sin(a), 0.0))
        b.taper_sweep([Vector((0, 0, 0.14)), d * 0.34 + Vector((0, 0, 0.04)),
                       d * 0.62 + Vector((0, 0, 0.0))],
                      [0.11, 0.07, 0.02], TRUNK, segments=3)
    return b.to_object("Stump")


# --- driftwood -----------------------------------------------------------------

def build_driftwood():
    """Trunchi decolorat pe mal, 4 m lung. WOOD.

    Buget 150: masurat dupa bevel (0.02 il scumpea la 160) — bevel=0.0 la
    emit, `taper_sweep(segments=5)` pe 4 puncte + 2 crengi ramane sub buget.
    """
    b = Builder()
    rand = _lcg(5701)
    pts = [Vector((0.0, 0.0, 0.14)),
           Vector((1.3, 0.12, 0.10)),
           Vector((2.6, -0.08, 0.16)),
           Vector((4.0, 0.05, 0.11))]
    radii = [0.19, 0.17, 0.14, 0.09]
    b.taper_sweep(pts, radii, WOOD_SLOT, segments=5)
    # 2 crengi rupte, scurte
    for k, t0 in enumerate((0.35, 0.68)):
        i = min(int(t0 * (len(pts) - 1)), len(pts) - 2)
        f = t0 * (len(pts) - 1) - i
        p = pts[i].lerp(pts[i + 1], f)
        a = rand() * 6.28
        d = Vector((math.cos(a), math.sin(a), 0.3))
        tip = p + d.normalized() * 0.5
        b.taper_sweep([p, tip], [0.06, 0.015], WOOD_SLOT, segments=3)
    return b.to_object("Driftwood")


# --- chasm_bridge_rail -----------------------------------------------------------
#
# Contract: DOAR balustradele si grinzile laterale, tablia NU. 40 m lung (Y),
# doua balustrade la X = ±5.8. Stalpi la 4 m, doua randuri de mana curenta,
# grinda laterala 0.4x0.3 sub fiecare balustrada. WOOD. Noduri Rail_L, Rail_R.
# Origine pe axa drumului, la cota tabliei, centrata pe Y (--origin=assembly).
CB_LEN = 40.0
CB_X = 5.8
CB_POST_STEP = 4.0
CB_HEIGHT = 1.0
CB_BEAM_SIZE = (0.4, 0.3)


def _bridge_rail(sign):
    """O balustrada (Rail_L sau Rail_R), la X = sign * CB_X.

    Buget total 600 pentru AMBELE noduri (300/nod): 11 stalpi (pas 4 m pe
    40 m) + 2 lise + 1 grinda laterala = 14 cutii/grinzi, 12 tris brut fiecare
    = 168 brut, dar bevel-ul (3.67x masurat in dio_lib) le duce la ~617 — mult
    peste 300/nod. Bevel-ul e taiat aici (piesa se vede de la distanta, pe un
    pod, nu de aproape ca stirling_ledge), deci ramane geometria brut-cubica,
    sub buget cu marja.
    """
    b = Builder()
    hl = CB_LEN * 0.5
    x = sign * CB_X
    p1 = (x, -hl, 0.0)
    p2 = (x, hl, 0.0)
    faces = b.railing(p1, p2, CB_HEIGHT, CB_POST_STEP, 0.09, 0.07,
                      WOOD_SLOT, rails=2)
    # grinda laterala, sub balustrada, in AFARA (spre exterior de tablie)
    beam_y0 = (-hl, hl)
    beam_x = x + sign * (CB_BEAM_SIZE[1] * 0.5 + 0.02)
    beam = b.beam((beam_x, -hl, -CB_BEAM_SIZE[0] * 0.5),
                  (beam_x, hl, -CB_BEAM_SIZE[0] * 0.5),
                  (CB_BEAM_SIZE[1], CB_BEAM_SIZE[0]), WOOD_SLOT,
                  up=(0, 0, 1))
    name = "Rail_L" if sign < 0 else "Rail_R"
    return b.to_object(name)


# --- emit ----------------------------------------------------------------------

clear_built()
results = []


def emit(objs, path, ao, origin="base", bevel=0.02, smooth_angle=45.0,
         budget=None, tint=None):
    if not isinstance(objs, (list, tuple)):
        objs = [objs]
    solo = len(objs) == 1
    place = Vector((0.0, 0.0, 0.0))
    if not solo:
        xs, ys, zs = [], [], []
        for o in objs:
            for v in o.data.vertices:
                xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
        place = Vector((0.0, -(min(ys) + max(ys)) * 0.5, 0.0))
    total_tris = 0
    ao_lo, ao_hi = 1.0, 0.0
    for o in objs:
        st = finish(o, bevel=bevel, ao=ao, origin=(origin if solo else None),
                    smooth_angle=smooth_angle)
        if not solo:
            for v in o.data.vertices:
                v.co += place
        if tint is not None:
            tint_gradient(o, base=tint[0], tip=tint[1])
        total_tris += st["tris"]
        ao_lo = min(ao_lo, st["ao_min"])
        ao_hi = max(ao_hi, st["ao_max"])
    _, sz = export_glb(objs, "fiordland/" + path)
    results.append((path, total_tris, sz / 1024.0, ao_lo, ao_hi, budget))
    return total_tris


# Fagul: A intai, verificat, apoi B/C. tint usor pe coroana (baza spre umbra
# rece, varf spre culoarea slotului) - vezi tint_gradient in dio_lib.
CROWN_TINT = ((0.56, 0.62, 0.52), (1.04, 1.00, 0.82))

def emit_beech(height, n_tiers, seed_base, path, budget=300):
    trunk_obj, crown_obj = build_beech(height, n_tiers, seed_base, budget)
    # tint DOAR pe Crown (verde) — Trunk e LOG_DARK, tint_gradient l-ar sari
    # oricum (green_only), dar apelul separat e mai clar decat un tint comun.
    st_t = finish(trunk_obj, bevel=0.0, ao=AO_TREE, origin=None,
                 smooth_angle=45.0)
    st_c = finish(crown_obj, bevel=0.0, ao=AO_TREE, origin=None,
                 smooth_angle=45.0)
    tint_gradient(crown_obj, base=CROWN_TINT[0], tip=CROWN_TINT[1])
    # origine comuna: baza trunchiului e deja la Z=0 (taper_sweep incepe la
    # (0,0,0)), deci NU trebuie offset suplimentar — dar se calculeaza oricum
    # din bbox-ul ambelor, ca la stirling_ledge, in caz ca trunchiul se
    # apleaca sub 0 din bevel/jitter.
    xs, ys, zs = [], [], []
    for o in (trunk_obj, crown_obj):
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    place = Vector((-(min(xs) + max(xs)) * 0.5, -(min(ys) + max(ys)) * 0.5,
                    -min(zs)))
    for o in (trunk_obj, crown_obj):
        for v in o.data.vertices:
            v.co += place
    total_tris = st_t["tris"] + st_c["tris"]
    ao_lo = min(st_t["ao_min"], st_c["ao_min"])
    ao_hi = max(st_t["ao_max"], st_c["ao_max"])
    _, sz = export_glb([trunk_obj, crown_obj], "fiordland/" + path)
    results.append((path, total_tris, sz / 1024.0, ao_lo, ao_hi, budget))
    return trunk_obj, crown_obj


beech_a_t, beech_a_c = emit_beech(8.0, 3, 6101, "plants/beech_a.glb", 300)
beech_b_t, beech_b_c = emit_beech(11.0, 4, 6201, "plants/beech_b.glb", 300)
beech_c_t, beech_c_c = emit_beech(14.0, 4, 6301, "plants/beech_c.glb", 300)

dead_obj = build_beech_dead()
emit(dead_obj, "plants/beech_dead.glb", AO_TREE, bevel=0.0, budget=250)

rata_obj = build_rata_tree()
emit(rata_obj, "plants/rata_tree.glb", AO_TREE, bevel=0.0, budget=400,
     tint=CROWN_TINT)

tussock_obj = build_tussock_clump()
emit(tussock_obj, "plants/tussock_clump.glb", AO_SMALL, bevel=0.0, budget=150)

stump_obj = build_stump()
emit(stump_obj, "props/stump.glb", AO_SMALL, bevel=0.0, budget=150)

driftwood_obj = build_driftwood()
emit(driftwood_obj, "props/driftwood.glb", AO_SMALL, bevel=0.0, budget=150)

rail_l = _bridge_rail(-1)
rail_r = _bridge_rail(1)
emit([rail_l, rail_r], "structures/chasm_bridge_rail.glb", AO_RAIL,
     origin="base_axis", bevel=0.0, budget=600)

print()
for path, tris, kb, ao_lo, ao_hi, budget in results:
    flag = ""
    if budget is not None:
        flag = "  OK" if tris <= budget else "  DEPASIT (buget %d)" % budget
    print("%-40s tris=%6d%s %8.1f kB  AO %.2f..%.2f"
          % (path, tris, flag, kb, ao_lo, ao_hi))
print("TOTAL forest: %d tris" % sum(t for _, t, _, _, _, _ in results))

save_blend([beech_a_t, beech_a_c, beech_b_t, beech_b_c, beech_c_t, beech_c_c,
            dead_obj, rata_obj, tussock_obj, stump_obj, driftwood_obj,
            rail_l, rail_r],
           "fiordland_forest.blend")
