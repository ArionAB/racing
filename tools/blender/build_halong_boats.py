"""Ha Long, valul 2 — barcile (brief docs/asset_briefs/halong_kit.md §1.4).

  halong/vehicles/fishing_junk.glb   jonca cu vela ruginie cu lamele, 12 m
  halong/vehicles/sampan_a.glb       barca lunga joasa cu copertina de stuf, 7 m
  halong/vehicles/basket_boat.glb    barca-cos rotunda impletita, 2 m

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_halong_boats.py

Variabila HL_ONLY=<piesa> reface doar piesa respectiva.

ORIENTAREA, care a costat deja o runda pe alta pista
----------------------------------------------------
PROVA PE +Y BLENDER = -Z GODOT (brief §1.4). Pe Machu Picchu trenul a ieit pe
+X si a trebuit refacut (memoria `machu-picchu-assets-kit`). `verify_halong.sh`
ruleaza jonca si sampanul cu `--front=-Z`, deci orientarea nu mai e o nota in
brief, e o ASERTIUNE care pica build-ul.

Conventia `Hull` din build_okinawa_vessels.py: profilul in plan merge de la
pupa (t=0) la prova (t=1), iar prova se termina intr-un punct (f=0). Cu
`levels` pe (z, y_pupa, y_prova, kw), y_prova POZITIV = prova pe +Y. Refolosim
clasa, nu rescriem loft-ul.

VELA, singurul accent saturat de aici
-------------------------------------
Vela joncii ia KERB_RED 7, declarat in brief §0.4 si acceptat de garda prin
`--allow-slots=7`. Nu e decor: jonca e HAZARDUL de la canal, deci vela e
semnal de gameplay — trebuie sa se vada de departe ca "aici trece ceva".
Vela cu LAMELE (battened lug sail) e silueta care spune "jonca" si nu "barca
cu pânze": panza e impartita de vergi orizontale si sta inclinata, nu
triunghiulara.

NODURI (brief §0.6): jonca se sparge in `Hull` + `Sail` + `Rigging`, fiindca
la integrare carena primeste alt material decat panza.
Sampanul si barca-cos iau un nod fiecare (copertina de stuf si impletitura
sunt pe sloturi diferite de carena, dar piesele nu primesc clasa triplanara).

BARCA-COS e o calota, nu o farfurie: 2 m diametru, ~0,55 m adancime, cu o
bordura rulata. Impletitura NU se modeleaza (ar fi mii de triunghiuri) — vine
din slotul DRY_VEGETATION si, la integrare, din clasa de suprafata.
"""

import os
import math

_here_hb = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here_hb, "okinawa_shapes.py")).read())

clear_built()

# --- sloturile pe roluri (halong_kit.md §0.4) --------------------------------
HL_WOOD = WOOD                # 9: barne, carena, catarge, vergi
HL_SAIL = KERB_RED            # 7: vela ruginie — accent DECLARAT
HL_NET = DRY_VEGETATION       # 13: plase, franghii, stuf, impletitura
HL_DARK = VOLCANIC_BLACK      # 20: goluri, cauciucuri de amortizare
HL_WASHED = SAND_SHADOW       # 2: lemn spalat de soare
HL_LIME = FOAM_WHITE          # 22: var pe bord

HL_RESULTS = []


# ---------------------------------------------------------------------------
# coca: contururi in plan, interpolate pe inaltime
# ---------------------------------------------------------------------------
# `Hull`, `loft_open`, `ring_wall` si `hull_body` sunt COPIATE din
# build_okinawa_vessels.py, nu importate. Motivul: acolo sunt definite intr-un
# script de BUILD, nu in biblioteca partajata (okinawa_shapes.py n-are niciuna
# din ele). Un `exec` pe build_okinawa_vessels.py ar reconstrui si ar
# re-exporta feribotul, cargoul si barca de pescuit din Okinawa ca efect
# secundar — adica un build de Ha Long ar atinge GLB-uri ale altei piste, exact
# ce interzice brief §0.2 ("asset nou = fisier nou; nu se suprascrie niciun GLB
# pe care Godot il incarca deja").


class Hull:
    """Coca din niveluri (z, y_pupa, y_prova, kw): `kw` = fractia din
    semilatimea maxima W la nivelul respectiv. `plan(z)` interpoleaza liniar
    intre niveluri, deci contururile intermediare cad EXACT pe fetele
    loft-ului."""

    def __init__(self, W, levels, prof):
        self.W, self.levels, self.prof = W, levels, prof

    def params(self, z):
        lv = self.levels
        if z <= lv[0][0]:
            return lv[0][1:]
        for a, b in zip(lv, lv[1:]):
            if z <= b[0] + 1e-9:
                t = (z - a[0]) / (b[0] - a[0])
                return tuple(a[i] + (b[i] - a[i]) * t for i in (1, 2, 3))
        return lv[-1][1:]

    def plan(self, z, dx=0.0, kwm=1.0, dy=0.0):
        """Contur ANTIORAR (vazut de sus), pupa -> prova pe dreapta, apoi
        stanga. `dx` iese lateral, `kwm` inmulteste latimea, `dy` iese in
        prova."""
        ys, yb, kw = self.params(z)
        right = []
        for t, f in self.prof:
            x = f * self.W * kw * kwm + (dx if f > 0 else 0.0)
            y = ys + t * (yb - ys) + (dy if f == 0 else 0.0)
            right.append((x, y))
        left = [(-x, y) for x, y in reversed(right[:-1])]
        return right + left

    def zs(self):
        return [lv[0] for lv in self.levels]


def loft_open(b, bot, z0, top, z1, slot, cap_bottom=False, cap_top=False):
    """Prisma intre doua contururi antiorare; capacele sunt optionale (cand
    corpul sta peste altul, capacele ar fi doar fete ascunse)."""
    n = len(bot)
    for i in range(n):
        j = (i + 1) % n
        _face(b, [(bot[i][0], bot[i][1], z0), (bot[j][0], bot[j][1], z0),
                  (top[j][0], top[j][1], z1), (top[i][0], top[i][1], z1)], slot)
    if cap_top:
        _face(b, [(p[0], p[1], z1) for p in top], slot)
    if cap_bottom:
        _face(b, [(p[0], p[1], z0) for p in reversed(bot)], slot)


def ring_wall(b, outer, inner, z0, z1, slot):
    """Parapet: perete cu grosime, deschis in mijloc."""
    n = len(outer)
    for i in range(n):
        j = (i + 1) % n
        _face(b, [(outer[i][0], outer[i][1], z0), (outer[j][0], outer[j][1], z0),
                  (outer[j][0], outer[j][1], z1), (outer[i][0], outer[i][1], z1)], slot)
        _face(b, [(inner[j][0], inner[j][1], z0), (inner[i][0], inner[i][1], z0),
                  (inner[i][0], inner[i][1], z1), (inner[j][0], inner[j][1], z1)], slot)
        _face(b, [(outer[i][0], outer[i][1], z1), (outer[j][0], outer[j][1], z1),
                  (inner[j][0], inner[j][1], z1), (inner[i][0], inner[i][1], z1)], slot)


def hull_body(b, hull, slot_of_seg, cap_top=True):
    """Coca plina, pe nivelurile ei; `slot_of_seg(i)` = slotul segmentului i."""
    zs = hull.zs()
    for i in range(len(zs) - 1):
        loft_open(b, hull.plan(zs[i]), zs[i], hull.plan(zs[i + 1]), zs[i + 1],
                  slot_of_seg(i), cap_bottom=(i == 0),
                  cap_top=(cap_top and i == len(zs) - 2))


def _ao(top=None, dist=2.0, bottom=None):
    """AO pe gradient vertical. FARA `z_range` la barci, si asta e esential.

    `bake_ao` normalizeaza cota fiecarui vertex pe `z_range` si ridica
    rezultatul la `power` (dio_lib.py:1270). O carena are chila SUB zero, deci
    cu un `z_range` care porneste de la 0 fractia iese NEGATIVA, iar un numar
    negativ la puterea 0,8 e COMPLEX in Python: build-ul cadea cu
    "'<' not supported between instances of 'complex' and 'float'".

    Prima incercare a fost sa dau `bottom` explicit (-0,85 pe jonca). A picat
    la fel, fiindca `bake_ao` citeste `v.co.z` INAINTE de offsetul de asezare
    din `emit_hl`, deci cota reala a vertecsilor nu e cea pe care o calculasem
    din `levels`. Lasand `z_range` nedat, dio_lib si-l deriva singur din
    geometrie (linia 1239: `z_lo, z_hi = min(zs), max(zs)`), ceea ce e corect
    prin construcie pe ORICE piesa — si pentru una care incaleca zero e
    singura varianta care nu cere sa ghicesc cota minima.

    `top`/`bottom` sunt pastrate in semnatura doar ca sa documenteze intervalul
    asteptat al piesei; nu mai sunt folosite."""
    return dict(samples=20, dist=dist, gradient="vertical", low=0.45, high=1.0,
                power=0.8, floor=0.22)


def emit_hl(objs, path, ao, keep_xy=False, bevel=0.0, smooth_angle=None,
            budget=None, bevel_angle=30.0, bevels=None, flat_ao=False,
            keep_z=False):
    """Vezi build_halong_village.py — offsetul de origine O DATA pe ansamblu
    (memoria `finish-recentreaza-fiecare-nod-separat`): la o jonca, altfel
    vela si catargul ar coborî la zero, iar carena ar urca.

    `keep_z=True` NU coboara piesa la Y=0: o barca e ancorata de LINIA APEI,
    nu de sol. Z=0 in Blender e nivelul marii, chila coboara sub el, puntea sta
    peste. Garda cere exact asta (`--origin=waterline`): o barca exportata cu
    baza la zero ar pluti cu TOTUL peste apa, ca o jucarie pe gresie."""
    objs = [o for o in objs if o is not None and len(o.data.vertices) > 0]
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    place = Vector((0.0 if keep_xy else -(min(xs) + max(xs)) * 0.5,
                    0.0 if keep_xy else -(min(ys) + max(ys)) * 0.5,
                    0.0 if keep_z else -min(zs)))
    total = 0
    per_node = {}
    for o in objs:
        for v in o.data.vertices:
            v.co += place
        bw = bevel
        for suf, w in (bevels or {}).items():
            if o.name.endswith(suf):
                bw = w
        if flat_ao:
            _split_all_edges(o)
        st = finish(o, bevel=bw, bevel_angle=bevel_angle, ao=ao,
                    origin=None, smooth_angle=smooth_angle)
        if flat_ao:
            _flatten_ao(o)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    xs, ys, zs = [], [], []
    for o in objs:
        for v in o.data.vertices:
            xs.append(v.co.x); ys.append(v.co.y); zs.append(v.co.z)
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    _, sz = export_glb(objs, "halong/" + path)
    HL_RESULTS.append((path, total, dims, budget, per_node, sz / 1024.0))


def _drop(objs):
    for o in objs:
        if o is not None:
            bpy.data.objects.remove(o, do_unlink=True)


def _want(name):
    only = os.environ.get("HL_ONLY", "")
    return (not only) or (only == name)


# ---------------------------------------------------------------------------
# fishing_junk — 12 m, vela cu lamele, hazardul de la canal
# ---------------------------------------------------------------------------

# Profil in plan al joncii: pupa LATA si retezata (o jonca are tabla de pupa,
# nu capat ascutit), prova ridicata si ascutita. f=0 la t=1 => prova in punct.
JUNK_PROF = [(0.0, 0.88), (0.12, 0.98), (0.45, 1.0), (0.70, 0.93),
             (0.86, 0.66), (1.0, 0.0)]


def build_junk():
    """Jonca de 12 m: carena cu pupa lata, bord inalt, catarg inclinat spre
    prova si vela cu lamele intinsa pe vergi.

    Lungimea totala iese din `levels`: pupa la y=-5,2, prova la y=+6,8 pe
    nivelul de sus — 12 m. Prova pe +Y, cum cere §1.4."""
    W = 1.75                                 # semilatime maxima
    # (z, y_pupa, y_prova, kw): carena se ingusteaza spre chila si se
    # lateste spre bord, iar prova URCA (y_prova creste cu z) — sheer-ul
    # caracteristic al joncii.
    H = Hull(W, [(-0.85, -4.30, 5.10, 0.42),   # chila
                 (-0.30, -4.90, 5.95, 0.80),
                 (0.25, -5.20, 6.55, 0.98),
                 (0.95, -5.20, 6.80, 1.00)],   # bordul
             prof=JUNK_PROF)

    hb = Builder()
    hull_body(hb, H, lambda i: HL_WOOD, cap_top=False)
    # puntea: un capac plan la z=0,95, ca sa fie suprafata continua
    loft_open(hb, H.plan(0.95), 0.90, H.plan(0.95), 0.95, HL_WOOD,
              cap_top=True, cap_bottom=False)
    # parapetul de bord, 0,45 m peste punte
    ring_wall(hb, H.plan(0.95), H.plan(0.95, kwm=0.88), 0.95, 1.40, HL_WOOD)
    # dunga de var pe bord — barcile din Ha Long au bordul vopsit
    loft_open(hb, H.plan(0.95, dx=0.03), 1.12, H.plan(0.95, dx=0.03), 1.34,
              HL_LIME)
    # ruful de la pupa (cabina joasa cu acoperis de stuf)
    K = [(-1.25, -5.0), (1.25, -5.0), (1.25, -2.3), (-1.25, -2.3)]
    loft_open(hb, K, 1.40, inset_convex(K, 0.10), 2.45, HL_WOOD,
              cap_bottom=False)
    o_hull = hb.to_object("Hull")

    # acoperisul de stuf al rufului + copertina: slot de paie
    rg = Builder()
    rf = inset_convex(K, -0.18)
    loft_open(rg, rf, 2.45, rf, 2.58, HL_NET, cap_top=True, cap_bottom=True)
    # catargul: inclinat spre prova (jonca are catargul cazut in fata)
    # Catargul: 6,9 m peste punte. Prima versiune avea 8,6 m, ceea ce dadea o
    # piesa de 10,2 m inaltime pe un corp de 12 m — masurat pe GLB. O jonca
    # reala are catargul cam cat lungimea corpului SAU MAI SCURT, si piesa
    # trebuie sa intre in plafonul de frustum al camerei de joc (memoria
    # `inaltimea-obiectelor-si-camera`).
    rg.beam((0.0, 0.60, 1.30), (0.0, 1.80, 6.90), 0.17, HL_WOOD)
    # catarg mic de prova
    rg.beam((0.0, 4.30, 1.30), (0.0, 4.85, 3.90), 0.11, HL_WOOD)
    # vergile velei: 5 lamele orizontale, tot mai lungi spre jos
    for k in range(5):
        t = k / 4.0
        z = 2.70 + t * 3.90
        half = 1.30 + (1.0 - t) * 1.00
        y0 = 1.10 + t * 0.70
        rg.box((0.0, y0, z), (half * 2.0, 0.09, 0.09), HL_WOOD)
    o_rig = rg.to_object("Rigging")

    # vela: panza intre vergi, UN volum turtit per interval (nu plan: Godot
    # face backface culling, deci o panza dintr-un strat de fete dispare de pe
    # o parte — aceeasi alegere ca la frunze, vezi docstring-ul lui `blade`).
    sl = Builder()
    for k in range(4):
        t0, t1 = k / 4.0, (k + 1) / 4.0
        z0, z1 = 2.70 + t0 * 3.90, 2.70 + t1 * 3.90
        h0 = 1.30 + (1.0 - t0) * 1.00
        h1 = 1.30 + (1.0 - t1) * 1.00
        y0 = 1.10 + t0 * 0.70
        y1 = 1.10 + t1 * 0.70
        sl.prism([(-h0, y0), (h0, y0), (h1, y1), (-h1, y1)], 0.06, HL_SAIL,
                 center=(0.0, 0.0, (z0 + z1) * 0.5))
    o_sail = sl.to_object("Sail")

    objs = [o_hull, o_sail, o_rig]
    emit_hl(objs, "vehicles/fishing_junk.glb",
            _ao(7.1, dist=3.0, bottom=-0.85), budget=800, keep_z=True)
    _drop(objs)


# ---------------------------------------------------------------------------
# sampan_a — 7 m, barca lunga joasa cu copertina de stuf
# ---------------------------------------------------------------------------

SAMPAN_PROF = [(0.0, 0.70), (0.15, 0.95), (0.5, 1.0), (0.78, 0.92),
               (0.92, 0.62), (1.0, 0.0)]


def build_sampan():
    """Sampan de 7 m: carena joasa si lunga, copertina de stuf pe mijloc,
    o vasla la pupa. Prova pe +Y.

    Mai joasa decat jonca: bordul la 0,55 m, deci de pe sosea se citeste ca o
    barca de lucru, nu ca o ambarcatiune de pasageri."""
    W = 0.92
    # Lungimea e CONTRACT (7 m, brief §1.4): pupa -2,62 + prova 3,38 = 7,00 pe
    # nivelul de bord. Prima versiune ieise 8,22 m — masurat pe GLB, nu estimat.
    H = Hull(W, [(-0.42, -2.10, 2.70, 0.40),
                 (-0.10, -2.50, 3.20, 0.82),
                 (0.30, -2.62, 3.38, 1.00)],
             prof=SAMPAN_PROF)

    hb = Builder()
    hull_body(hb, H, lambda i: HL_WOOD, cap_top=False)
    loft_open(hb, H.plan(0.30), 0.26, H.plan(0.30), 0.30, HL_WOOD,
              cap_top=True, cap_bottom=False)
    ring_wall(hb, H.plan(0.30), H.plan(0.30, kwm=0.86), 0.30, 0.55, HL_WOOD)
    # banchete
    for y in (-1.3, 0.3, 1.8):
        hb.box((0.0, y, 0.40), (W * 1.5, 0.22, 0.07), HL_WASHED)
    # vasla la pupa, sprijinita pe bord
    hb.beam((0.55, -2.25, 0.62), (1.10, -3.60, 0.18), 0.075, HL_WASHED)
    o_hull = hb.to_object("Hull")

    # copertina de stuf: arcuri + panza, pe mijloc
    cv = Builder()
    for y in (-0.70, 0.35, 1.40):
        # arc transversal: trei segmente, ca sa se citeasca rotund
        cv.beam((-0.80, y, 0.50), (-0.52, y, 1.08), 0.055, HL_NET)
        cv.beam((-0.52, y, 1.08), (0.52, y, 1.08), 0.055, HL_NET)
        cv.beam((0.52, y, 1.08), (0.80, y, 0.50), 0.055, HL_NET)
    # panza copertinei: o lamela curbata peste arcuri
    cv.blade([(0.0, -0.95, 1.05), (0.0, 0.35, 1.12), (0.0, 1.65, 1.05)],
             [1.62, 1.68, 1.62], 0.05, HL_NET, up=(0.0, 0.0, 1.0))
    o_cv = cv.to_object("Canopy")

    objs = [o_hull, o_cv]
    emit_hl(objs, "vehicles/sampan_a.glb", _ao(1.2, bottom=-0.42), budget=400,
            keep_z=True)
    _drop(objs)


# ---------------------------------------------------------------------------
# basket_boat — 2 m, barca-cos rotunda impletita
# ---------------------------------------------------------------------------

def build_basket_boat():
    """Thuyen thung: cos rotund de 2 m, ~0,55 m adanc, cu bordura rulata.

    O CALOTA, nu o farfurie. `revolve` pe un profil care coboara concav:
    altfel iese o tava si se citeste ca un capac de canal.
    Impletitura NU se modeleaza — vine din slot si, la integrare, din clasa de
    suprafata. `segments=12` explicit (regula primitivelor din CLAUDE.md):
    la 2 m diametru si vazut de sus, 12 e minimul care nu se citeste poligonal.
    """
    b = Builder()
    R, D = 1.0, 0.55
    # profilul: (raza, z) de la centru spre bordura. Concav => calota.
    # Profilul coboara SUB zero: fundul cosului la -0,22 (pescaj), bordura la
    # +0,33 — incaleca linia apei, cum cere `--origin=waterline`.
    #
    # ATENTIE la prima raza: `revolve` se OPRESTE la prima raza <= 1e-6 si face
    # un apex din ea (dio_lib.py:530-533). Cu `(0.0, -0.22)` pe primul rand,
    # tot restul profilului era ARUNCAT: in GLB rtamaneau doar bordura si
    # banchetă, iar garda a prins exact asta ("geometria nu incaleca Y=0",
    # Y 0,175..0,335 — adica fundul cosului lipsea de tot). Fundul porneste
    # acum de la 0,10 m raza: un cos impletit are oricum un fund plat mic, nu
    # un varf ascutit.
    prof = [(0.10, -0.22), (0.34, -0.185), (0.60, -0.09), (0.80, 0.05),
            (0.93, 0.20), (1.00, 0.33)]
    b.revolve(prof, HL_NET, segments=12, origin=(0.0, 0.0, 0.0),
              cap_bottom=False)
    # bordura rulata: un tor ar costa 2*12*6 = 144 tri; un inel de frustum
    # scurt costa 48 si de pe sosea se citeste identic.
    b.frustum((0.0, 0.0, 0.29), R + 0.055, R + 0.055, 0.09, HL_WASHED,
              segments=12)
    # o banchetă transversala, ca sa nu arate ca un vas gol
    b.box((0.0, 0.0, 0.20), (R * 1.35, 0.17, 0.05), HL_WASHED)
    o = b.to_object("Basket")
    emit_hl([o], "vehicles/basket_boat.glb",
            _ao(0.38, dist=1.0, bottom=-0.22), budget=200, keep_z=True)
    _drop([o])


# ---------------------------------------------------------------------------

if _want("fishing_junk"):
    build_junk()
if _want("sampan_a"):
    build_sampan()
if _want("basket_boat"):
    build_basket_boat()

print()
print("=== Ha Long val 2 — barcile ===")
for path, tris, dims, budget, per_node, kb in HL_RESULTS:
    flag = ""
    if budget:
        flag = "OK" if tris <= budget else "PESTE BUGET (%d)" % budget
    print("  %-38s %5d tri  %5.1f x %4.1f x %4.1f m  %7.1f kB  %s"
          % (path, tris, dims.x, dims.y, dims.z, kb, flag))
    for n, t in sorted(per_node.items()):
        print("        %-28s %5d tri" % (n, t))
