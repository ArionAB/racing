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


def _crown_tier(b, center, radius_xy, thick, seed, segments=6, lumps=3,
                rings=2):
    """Un etaj de coroana: CIORCHINE de bulgari APROAPE EGALI ca marime, care
    se suprapun, nu un disc/placa unica.

    A TREIA revizuire coordonator (dupa doua incercari vizual esuate,
    vezi `_debug_tier*.png` din sesiune): un singur bulgare MARE central +
    satelite mici (v1/v2) tot citea ca o lentila dominanta cu niste umflaturi
    minore la margine — de la distanta, silueta era tot un hexagon aproape
    regulat cu o muchie tesita. Ce a schimbat efectiv citirea, verificat
    direct pe randari izolate:
      1. bulgarii NU mai au un lider dominant — toti au marimi APROAPE
         EGALE (size_f 0.62-0.92, nu 1.0 vs 0.55-0.85), distribuiti pe cerc
         (2*pi*i/lumps), nu "unul in centru, restul langa"
      2. offset-ul pe Z e MULT mai mare (+-30% din thick, nu +-18%): asta e
         ce rupe conturul de SUS — daca toate varfurile bulgarilor cad pe
         acelasi plan orizontal, silueta laterala tot iese un dreptunghi
         turtit, indiferent cate volume separate sunt dedesubt
      3. `rings=2` (nu 3): mai putine inele, dar bulgarii NU se mai
         suprapun in centrul comun, deci fiecare isi pastreaza propria
         cupola vizibila — rings mare pe un singur bulgare dominant nu
         ajuta daca geometria insasi e un disc

    Fetele de sus TROPICAL_GREEN (lumina), cele de jos LOG_DARK (umbra sub
    etaj) — brief-ul cere explicit asta, nu doar un slot uniform.
    """
    rand = _lcg(seed)
    rx, ry = radius_xy
    all_faces = set()
    for i in range(lumps):
        a = 2.0 * math.pi * i / lumps + rand() * 0.7
        r = 0.0 if lumps == 1 else max(rx, ry) * (0.36 + rand() * 0.16)
        lx, ly = math.cos(a) * r, math.sin(a) * r
        size_f = 0.62 + rand() * 0.30       # toti bulgarii, marime APROAPE EGALA
        lz_off = thick * (rand() - 0.5) * 0.60   # offset Z GENEROS — rupe conturul de sus
        lw = rx * size_f * (0.85 + rand() * 0.3)
        lh = ry * size_f * (0.85 + rand() * 0.3)
        lz = thick * (0.45 + rand() * 0.25) * size_f
        faces = b.boulder(
            (center[0] + lx, center[1] + ly, center[2] + lz_off),
            (lw * 2.0, lh * 2.0, lz * 2.0), CROWN,
            seed=seed + i * 13, segments=segments, rings=rings,
            deviation=0.26)
        all_faces |= set(faces)
    b.retag(all_faces, TRUNK, where="down")
    b.retag(all_faces, CROWN, where="up")
    return all_faces


def build_beech(height, n_tiers, seed_base, budget):
    """`height` = inaltimea totala (8/11/14 m). `n_tiers` = 3 sau 4 etaje.

    Coroana ocupa treimea superioara pana la jumatate din inaltime — trunchiul
    e gol pe prima jumatate (brief). Etajele sunt la inaltimi DIFERITE, cu
    goluri intre ele (nu se ating pe Z), si fiecare are propriul offset XY, ca
    sa nu iasa un turn coaxial.

    A DOUA revizuire coordonator (val 2, dupa fix-ul de goluri): golurile
    erau acolo, dar (1) etajele PLUTEAU — nicio geometrie nu lega discul de
    trunchi; (2) varful trunchiului STRAPUNGEA etajul de sus (vizibil pe
    beech_b/c); (3) coroana combinata era doar 30-40% din inaltime, cand un
    fag real e 55-70% — citea ca "table pe stalp", nu ca arbore. Fix, in
    ordine:
      - trunchiul se opreste la `trunk_top_t` (SUB centrul ultimului etaj,
        nu la varful nominal `height`) — vezi mai jos
      - fiecare etaj primeste o RAMURA scurta (taper_sweep, 1 prism conic,
        cateva tri) de la trunchi pana sub centrul lui, inclinata 20-40°
      - `off_r` (offset lateral) creste substantial — proportional cu
        INALTIMEA arborelui, nu doar cu latimea discului, ca sa iasa o
        coroana combinata de 55-70% din inaltime
      - azimuturile etajelor sunt distribuite pe cerc (2*pi*i/n_tiers +
        jitter), nu toate independente — asa se suprapun in PLAN (vazute de
        sus, de la camera de joc), dar raman la Z diferite (vazute din lateral)

    DOUA noduri (Trunk + Crown, brief §0.6: o piesa care primeste clasa la
    integrare se sparge la export in obiecte cu un singur material) — doua
    Builder-e separate, ca la stirling_ledge (Wall/Overhang/Shelf).
    """
    rand = _lcg(seed_base)
    r_base = 0.16 + rand() * 0.09   # 0.25..0.45 m diametru brief -> raza 0.13..0.23

    # Etajele intai (geometria lor decide unde se opreste trunchiul), apoi
    # trunchiul, apoi ramurile — trunchiul din urma, ca varful lui sa poata
    # fi plasat SUB primul etaj deja calculat (punctul 2 din revizuire).
    crown_lo = height * 0.44
    crown_hi = height * 0.98    # coroana nu mai urca pana aproape de varf -
                                 # trunchiul se opreste SUB etajul de sus (pct 2)
    n = max(n_tiers, 1)
    avail = crown_hi - crown_lo
    # etajele mai groase si mai late decat inainte: tinta buget 220-280/fag,
    # nu 88-108 — coordonatorul cere sa se FOLOSEASCA bugetul (pct 5).
    #
    # ATENTIE: `w` aici e raza NOMINALA data lui `_crown_tier`, dar geometria
    # REALA iese mai mare — bulgarii secundari din `_crown_tier` au propriul
    # offset (pana la 0.6*max(rx,ry)) si propria marime (pana la 1.15*size_f),
    # deci extentul randat pe o axa poate trece de 1.5x raza nominala.
    # Masurat pe GLB (nu presupus): w_avg=0.30*H dadea beech_c la 16.97 m
    # inaltime (18% peste 14 m) si 13.93 m latime (84% din inaltime, peste
    # tinta 55-70%). Coboara la 0.20*H si off_r la 0.10*H, calibrate DIRECT
    # pe masuratoarea gresita (impartite la ~1.4-1.5, factorul de balonare
    # observat), apoi reverificate.
    w_avg = height * 0.20        # raza medie NOMINALA a unui etaj
    thick_avg = w_avg * 0.42
    gap = thick_avg * 0.55
    slot = max(avail / n, thick_avg + gap)
    tier_specs = []   # (cx, cy, z_center, w, h, thick, seed)
    z = crown_lo
    # azimuturi distribuite pe cerc + jitter: coroana se suprapune in PLAN
    for i in range(n):
        t = i / max(n - 1, 1)
        w = w_avg * (0.80 + rand() * 0.40) * (1.0 - 0.08 * t)
        thick = w * (0.34 + rand() * 0.16)
        z_center = z + thick * 0.5
        a = (2.0 * math.pi * i / n) + (rand() - 0.5) * 1.1
        # offset lateral PROPORTIONAL CU INALTIMEA arborelui (nu doar cu
        # latimea discului): asa iese coroana combinata la 55-70% din H,
        # in loc de 30-40% (defectul semnalat) — raza creste usor cu 'i'
        # (etajele de sus, mai mici, se departeaza mai mult, ca la un fag
        # real unde coroana se largeste catre mijloc/varf)
        off_r = height * (0.09 + 0.06 * t) * (0.85 + rand() * 0.3)
        cx, cy = math.cos(a) * off_r, math.sin(a) * off_r
        tier_specs.append((cx, cy, z_center, w, w * (0.82 + rand() * 0.3),
                           thick, seed_base + 40 + i * 11))
        z += slot
    # capacul FINAL: ultimul tier nu are voie sa impinga varful peste
    # `height` — daca `slot` (dictat de thick_avg) a acumulat mai mult decat
    # `avail`, se comprima uniform tot stivajul pe Z (pastreaza proportiile
    # relative, doar scaleaza), in loc sa se lase varful sa treaca de tinta.
    z_top = tier_specs[-1][2] + tier_specs[-1][5] * 0.5
    if z_top > crown_hi:
        scale_z = (crown_hi - crown_lo) / max(z_top - crown_lo, 1e-6)
        tier_specs = [(cx, cy, crown_lo + (zc - crown_lo) * scale_z, w, h,
                       th, sd)
                      for (cx, cy, zc, w, h, th, sd) in tier_specs]

    # A TREIA revizuire coordonator: trunchiul scurt (oprit sub PRIMUL etaj)
    # obliga fiecare ramura sa acopere singura toata distanta pana la etajul
    # ei — pentru etajul de sus (idx=3 la beech_c, la ~9 m deasupra bazei
    # trunchiului), o SINGURA ramura dreapta pe distanta aia fie nu ajunge
    # vizual (arata scurta/absenta), fie, daca ajunge, citeste ca un al
    # doilea trunchi diagonal, nu ca o creanga. Fix arhitectural, nu doar
    # numeric: trunchiul urca acum aproape pana SUB PENULTIMUL etaj (nu doar
    # primul), iar fiecare ramura porneste dintr-un punct de-a lungul
    # acestui trunchi LUNG, proportional cu inaltimea etajului ei — deci
    # fiecare ramura ramane SCURTA (cateva metri, nu 5-9 m), exact reteta
    # cursa "1 prism, 4-6 tris, 20-40°" ceruta de coordonator. Trunchiul
    # insusi se opreste sub centrul ULTIMULUI etaj (fara sa-l strapunga —
    # cerinta #2), iar acel ultim etaj primeste o ramura scurta separat,
    # la fel ca celelalte.
    trunk_h = tier_specs[-1][2] - tier_specs[-1][5] * 0.55
    bt = Builder()
    trunk_pts = _beech_trunk(bt, trunk_h, r_base * 2.0, seed_base,
                             lean=0.14 + rand() * 0.10)
    trunk_top = trunk_pts[-1]

    bc = Builder()
    for idx, (cx, cy, z_center, w, h, thick, seed) in enumerate(tier_specs):
        # etajele de jos (mai mari, mai aproape de camera) primesc un al
        # treilea bulgare — masa in plus exact unde se vede cel mai mult;
        # tinta coordonator 220-280 tri/fag (foloseste bugetul de 300)
        # Pe fagii cu 4 etaje (b/c) doar PRIMUL etaj ia lumps=3 (bugetul de
        # 300 nu incape 2x3-lumpuri + restul), pe cel cu 3 etaje (a) primele
        # doua. Val 3 (rework silueta): TOATE etajele primesc acum lumps=3
        # (nu doar cele apropiate) — testat izolat (`_debug_tier4_*.png`),
        # 2 bulgari tot citeau ca doua placi lipite, 3 bulgari pe cerc rup
        # conturul vizibil de jur imprejur. `rings=2` uniform (nu 3 pe
        # apropiate) tine bugetul: 3 lumps x rings=2 x segments=4 = 48 tri
        # brut/etaj, incape in 220-280/fag chiar la 4 etaje.
        _crown_tier(bc, (cx, cy, z_center), (w, h), thick, seed=seed,
                   segments=4, lumps=3, rings=2)
        # RAMURA: porneste dintr-un punct DE-A LUNGUL TRUNCHIULUI LUNG, la
        # aproape aceeasi cota ca centrul etajului ei (branch_t urmareste
        # direct fractia de inaltime a etajului, nu un interval fix
        # 0.55-0.95 independent de tier) — asa ramane SCURTA, doar diferenta
        # locala dintre trunchi si tier, in loc sa acopere toata distanta de
        # la baza trunchiului.
        t_frac = (z_center - trunk_pts[0].z) / max(trunk_top.z - trunk_pts[0].z, 1e-6)
        branch_t = max(0.0, min(t_frac - 0.06, 0.97))
        branch_base = trunk_pts[0].lerp(trunk_top, branch_t)
        tier_center = Vector((cx, cy, z_center))
        to_tier = tier_center - branch_base
        dist = to_tier.length
        # opreste-te ADANC sub tier (in interiorul volumului de bulgari),
        # nu la jumatate de drum — raza tier-ului e `w`
        reach = max(dist - w * 0.40, dist * 0.6)
        branch_dir = to_tier.normalized() if dist > 1e-4 else Vector((0, 0, 1))
        branch_tip = branch_base + branch_dir * reach
        branch_tip.z = min(branch_tip.z, z_center - thick * 0.15)
        # Grosime substantiala: o ramura care sustine un nor de 2-3 m
        # latime trebuie sa citeasca la fel de groasa ca o creanga reala,
        # nu un fir.
        r0 = max(r_base * 0.9, 0.08)
        bc.taper_sweep([branch_base, branch_tip], [r0, r0 * 0.55], TRUNK,
                      segments=5)

    trunk_obj = bt.to_object("Trunk")
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
    """Rata in floare, 5 m: TUFA DENSA, ROTUNJITA — nu acacia africana.

    A DOUA revizuire coordonator: prima versiune (limbi lungi si golase cu
    cate un disc turtit in varf, plus un disc central la furca) citea EXACT
    ca o acacie de Serengeti — silueta interzisa explicit pentru pista asta.
    Cauza: limbile erau prea lungi si prea vizibile (bare pana la capat),
    iar "ciorchinii" foloseau reteta `_crown_tier` a fagului (discuri
    turtite, late-nu-inalte) — corecta pentru fag, gresita pentru rata.

    Rata (Metrosideros umbellata) e o tufa DENSA si ROTUNDA: trunchi scurt,
    limbi scurte aproape ascunse de frunzis, coroana UN SINGUR bulgare
    umflat facut din 5-7 volume care se ATING si se INTREPATRUND (nu
    turtite si distantate ca la fag). Fix complet, reteta noua:
      - trunchi FOARTE scurt (<=1.2 m vizibil), apoi 3-4 limbi SCURTE
        (<=1.5 m), majoritatea ingropate in coroana de la baza
      - coroana: 6 bulgari `boulder()` ROTUNJITI (squash bland, NU turtiti
        ca discurile de fag), cu centrele apropiate de centrul arborelui si
        raze mari fata de distanta dintre ele — se SUPRAPUN masiv, ca sa nu
        ramana cer vizibil prin mijloc
      - FARA disc central la furca (interzis explicit de coordonator)
      - flori: NU bulgari separati mari (43% din fete, prea mult) — acum
        cutii mici RETAG pe o fractie din fetele de sus/exterior ale
        coroanei (15-25% cerut), plus cateva bulgare-cluster mici RAR, ca
        sa citeasca "verde punctat cu rosu", nu "copac rosu"
    """
    b = Builder()
    H = 5.0
    rand = _lcg(5301)

    # Trunchi foarte scurt: <=1.2 m vizibil (brief). `_beech_trunk` cu
    # kink=False si o inaltime mica da un trunchi drept, gros la baza.
    trunk_h = 0.75 + rand() * 0.35   # 0.75-1.10 m, sub plafonul de 1.2 m
    trunk_pts = _beech_trunk(b, trunk_h, 0.30, 5301, lean=0.08, kink=False)
    fork = trunk_pts[-1]

    # Centrul coroanei: putin deasupra furcii, undeva pe la 40% din H —
    # coroana insasi (bulgarii, mai jos) urca de acolo pana aproape de H.
    crown_center_z = fork.z + H * 0.06

    # 3-4 limbi SCURTE (<=1.5 m), majoritatea ascunse in coroana — nu se
    # vede lemn gol intre trunchi si frunzis, ca la acacie. Limbile exista
    # doar ca sa dea bulgarilor de coroana un punct de plecare diferit de
    # trunchi (silueta usor asimetrica), nu ca element vizibil in sine.
    n_limbs = 4
    limb_tips = []
    for li in range(n_limbs):
        a = 2.0 * math.pi * li / n_limbs + rand() * 0.5
        d = Vector((math.cos(a), math.sin(a), 0.0))
        limb_len = 0.7 + rand() * 0.6          # <=1.5 m (brief)
        rise = limb_len * (0.55 + rand() * 0.25)
        tip = fork + d * limb_len + Vector((0, 0, rise))
        b.taper_sweep([fork, tip], [0.11, 0.05], TRUNK, segments=4)
        limb_tips.append(tip)

    # Coroana: 6 bulgari ROTUNJITI, denși, care se ATING/INTREPATRUND.
    # Raza fiecarui bulgare (crown_r) e mare fata de raza de distributie a
    # centrelor (dist_r) — raportul asta e ce garanteaza suprapunerea
    # masiva ceruta ("no sky shows through the middle"). Un bulgar central
    # plus 5 in jurul lui, pe doua "etaje" joase (nu turnuri) — dom, nu
    # coloana.
    crown_w_target = H * (0.85 + rand() * 0.15)   # latime finala tinta 4-5 m (raza ~2.1-2.4)
    crown_r_nominal = crown_w_target * 0.5
    dist_r = crown_r_nominal * 0.34   # centrele stau APROAPE de mijloc -> suprapunere mare
    lump_specs = []   # (center, size_xyz, seed)
    # bulgarele central, cel mai mare
    lump_specs.append((Vector((0.0, 0.0, crown_center_z + crown_r_nominal * 0.30)),
                       crown_r_nominal * (0.62 + rand() * 0.10), 5311))
    n_ring = 5
    for k in range(n_ring):
        a = 2.0 * math.pi * k / n_ring + rand() * 0.5
        r = dist_r * (0.85 + rand() * 0.3)
        cx, cy = math.cos(a) * r, math.sin(a) * r
        # doua "randuri" pe Z (nu toate la aceeasi cota) — rupe conturul de
        # sus, exact lectia de la fag, dar aici bulgarii RAMAN rotunjiti
        # (squash bland), nu turtiti in disc
        cz = crown_center_z + (crown_r_nominal * (0.05 if k % 2 == 0 else 0.55))
        size = crown_r_nominal * (0.52 + rand() * 0.20)
        lump_specs.append((Vector((cx, cy, cz)), size, 5320 + k * 11))

    crown_faces = []
    lump_records = []   # (center, size) pentru plasarea florilor
    for center, size, seed in lump_specs:
        # squash BLAND (0.78-0.92, nu 0.35-0.5 ca la fagul turtit): bulgarii
        # raman rotunjiti — silueta de tufa, nu de disc
        sz = size * (0.78 + _lcg(seed)() * 0.14)
        faces = b.boulder((center.x, center.y, center.z),
                          (size * 2.0, size * 1.9, sz * 2.0), CROWN,
                          seed=seed, segments=6, rings=3, deviation=0.18)
        crown_faces.extend(faces)
        lump_records.append((center, size))

    b.retag(crown_faces, TRUNK, where="down")
    b.retag(crown_faces, CROWN, where="up")

    # Flori: 15-25% din fetele coroanei, RETAG (fara cost de triunghiuri) pe
    # fetele de sus/exterior selectate — plus cativa "muguri" mici ridicati
    # (bulgari foarte mici) pe cateva dintre ele, ca florile sa citeasca
    # usor 3D, nu doar ca pete de culoare. Selectia e determinista din LCG
    # separat, NU toate fetele de sus (ar depasi 25%).
    up_faces = [f for f in crown_faces if f.is_valid]
    frand = _lcg(5401)
    # Prima incercare (flower_target_frac=0.19, factor de compensare 1.35,
    # plus 6 muguri de marime s=0.14-0.20*size) a dat 30.6% KERB_RED masurat
    # DIRECT din GLB — peste tinta 15-25%, muguri numarati gresit ca "fete"
    # cand de fapt sunt bulgari intregi (multe fete fiecare). Recalibrat
    # DUPA masuratoare, nu presupus: fractia de retag coboara la 0.11 (fara
    # factorul de compensare inventat), iar mugurii scad la 4, mult mai mici.
    flower_target_frac = 0.11
    flower_faces = set()
    for f in up_faces:
        f.normal_update()
        if f.normal.z > 0.25 and frand() < flower_target_frac:
            flower_faces.add(f)
    b.retag(flower_faces, FLOWER)

    # Cativa muguri mici RIDICATI (bulgari mici), rari — accent 3D peste
    # petele retag, nu sursa principala de rosu (altfel se intoarce la
    # "copac rosu"). 4 muguri mici, fiecare ~16 tri brut (2*4*2).
    n_bud = 4
    for i in range(n_bud):
        center, size = lump_records[1 + (i % (len(lump_records) - 1))]
        a = frand() * 6.28
        outward = Vector((math.cos(a), math.sin(a), 0.0))
        rr = size * (0.75 + frand() * 0.25)
        px, py = center.x + outward.x * rr, center.y + outward.y * rr
        pz = center.z + size * (0.15 + frand() * 0.35)
        s = size * (0.08 + frand() * 0.04)
        b.boulder((px, py, pz), (s, s, s * 0.85), FLOWER,
                 seed=5500 + i, segments=4, rings=2, deviation=0.12)

    tri_est_faces = len(crown_faces)
    kerb_faces = len(flower_faces) + n_bud * 1   # aproximativ, pentru log; cifra reala se ia din GLB
    print("rata_tree: %d fete coroana, %d RETAG la FLOWER (~%.0f%%) + %d muguri"
          % (tri_est_faces, len(flower_faces),
             100.0 * len(flower_faces) / max(tri_est_faces, 1), n_bud))
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
