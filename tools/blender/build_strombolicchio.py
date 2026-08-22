"""Stromboli — Strombolicchio (brief docs/asset_briefs/strombolicchio.md).

  Strombolicchio  stromboli/structures/strombolicchio.glb
                  Stack_Rock / Stack_Stairs / Lighthouse_White / Lighthouse_Lantern

Fundal-erou: sta la ~200 m in larg si e silueta-semnatura a pistei. Se vede DOAR
de la 150-250 m, prin ceata calda — deci se judeca pe SILUETA si CONTRAST, nu pe
detaliu. Toate deciziile de mai jos vin din asta:

  - peretii sunt aproape verticali (dinte zvelt), nu conici: un con la 200 m
    citeste "movila", iar noi vrem un neck vulcanic
  - politele orizontale sunt PUTINE si LATE — la distanta aia, detaliul de
    frecventa inalta dispare oricum si costa triunghiuri degeaba
  - farul alb e singurul accent luminos si trebuie sa ramana citibil ca punct,
    deci soclul si turnul sunt volume simple

**Originea e la LINIA APEI**, nu la baza: gulerul de val sta la z=0 si fusta
coboara sub el, ca sa se inece in mare. `verify_glb --origin=waterline`
verifica exact asta (geometria incaleca Y=0).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_strombolicchio.py
"""

import math
from mathutils import Matrix, Vector

# AO pe distanta MARE: stanca are 32 m, iar politele trebuie sa-si arunce umbra
# una pe alta ca silueta sa aiba relief prin ceata.
AO_ROCK = dict(samples=30, dist=12.0, gradient="vertical",
               low=0.60, high=1.00, power=0.95, floor=0.35)
AO_STAIR = dict(samples=22, dist=4.0, gradient="vertical",
                low=0.65, high=1.00, power=0.9, floor=0.40)
AO_LIGHT = dict(samples=24, dist=4.0, gradient="vertical",
                low=0.85, high=1.00, power=0.9, floor=0.60)

H = 32.0             # inaltimea peste linia apei
SKIRT = 2.5          # cat coboara sub apa (se ineaca, dar nu lasa gaura)
BASE_X, BASE_Y = 30.0, 22.0     # la linia apei
# Varful: 11 x 8, nu 14 x 10.
#
# Brief-ul cere "dinte zvelt" SI "baza 30x22, inaltime 32", iar cele doua se
# bat cap in cap: 32 m peste o baza de 30 m da un raport inaltime/latime de
# 1.07-1.45, adica un ciot. Masurat pe randarea de la 200 m (distanta reala de
# joc), silueta iesea la 1.40 — sub pragul de ~1.5 la care ochiul citeste
# "turn" in loc de "movila".
#
# Cotele bazei si inaltimea sunt CONTRACT si raman. Ce lasa brief-ul liber e
# varful ("~14 x 10"), deci de acolo se ia zveltetea: 11 x 8 subtiaza partea
# de sus fara sa atinga nicio cota fixa.
TOP_X, TOP_Y = 11.0, 8.0        # la platou (brief: "~14 x 10" — vezi nota)
SEG = 11             # laturi ale prismei: fatete late, nu stanca rotunda

# Politele: (fractie din inaltime, cat iese in afara peretelui de DEDESUBT).
#
# A doua calibrare, dupa doua randari gresite in directii opuse. La 0.5-0.9 m
# politele erau invizibile (7% dintr-o semi-axa de 13 m). La 2.2 m ieseau
# RAFTURI: bulge-ul se adauga peste conturul comun, deci polita iesea in afara
# si a peretelui de deasupra, SI a celui de dedesubt — streasina pe ambele
# parti, adica pagoda.
#
# Un neck vulcanic real are polita la nivelul peretelui de dedesubt; treapta o
# face peretele de DEASUPRA, care se retrage. Deci bulge mic (doar cat sa
# prinda o muchie de umbra) si retragere reala in TIERS.
LEDGES = [(0.22, 0.35), (0.46, 0.28)]


# Ingustarea se face IN TREPTE, la polite, nu continuu. `TIERS` da fractia din
# ingustarea totala consumata pana SUB fiecare polita; intre ele peretele sta
# vertical.
#
# Asta e diferenta dintre "neck vulcanic" si "con", si nu e o chestiune de
# panta: raportul din brief (30x22 -> 14x10 pe 32 m) inseamna doar 14 grade
# fata de verticala, adica deja zvelt. Dar o suprafata care se subtiaza NETED
# citeste con la orice panta. Prima randare a iesit exact asa.
# Doua trepte JOS + varf care se subtiaza continuu. Trei trepte egale
# ieseau tort de nunta (randarea a doua): un neck real are masa in partea de
# jos si un dinte zvelt deasupra, nu etaje repetate.
TIERS = [(0.22, 0.20), (0.46, 0.46)]


def _shrink(t):
    """Cat din ingustarea totala s-a consumat la fractia `t` din inaltime.

    Constant intre polite (perete vertical), sare la fiecare polita.
    """
    prev_t, prev_k = 0.0, 0.0
    for lt, lk in TIERS:
        if t < lt - 0.02:
            return prev_k
        if t <= lt + 0.02:            # chiar in dreptul politei: tranzitia
            f = (t - (lt - 0.02)) / 0.04
            return prev_k + (lk - prev_k) * f
        prev_t, prev_k = lt, lk
    # deasupra ultimei polite: restul ingustarii, pana la platou
    f = (t - TIERS[-1][0] - 0.02) / max(1.0 - TIERS[-1][0] - 0.02, 1e-6)
    return prev_k + (1.0 - prev_k) * min(max(f, 0.0), 1.0)


def _profile_xy(t):
    """Semi-axele stancii la fractia `t` din inaltime (0 = apa, 1 = platou)."""
    k = _shrink(t)
    return (BASE_X * 0.5 + (TOP_X - BASE_X) * 0.5 * k,
            BASE_Y * 0.5 + (TOP_Y - BASE_Y) * 0.5 * k)


def _ring(bm, t, z, seed, bulge=0.0):
    """Inel de varfuri pe conturul stancii la inaltimea z."""
    rx, ry = _profile_xy(t)
    rx += bulge
    ry += bulge
    verts = []
    state = (seed * 1103515245 + 12345) & 0x7FFFFFFF
    for i in range(SEG):
        a = 2.0 * math.pi * i / SEG
        state = (state * 1103515245 + 12345) & 0x7FFFFFFF
        # perturbatie mica si pe FATETA, nu pe varf: coloanele de bazalt sunt
        # plane, doar latimea lor variaza
        j = 1.0 + ((state / float(0x7FFFFFFF)) - 0.5) * 0.10
        verts.append(bm.verts.new((rx * math.cos(a) * j, ry * math.sin(a) * j, z)))
    return verts


def _bridge(bm, lo, hi, layer, slot):
    for i in range(SEG):
        k = (i + 1) % SEG
        f = bm.faces.new((lo[i], lo[k], hi[k], hi[i]))
        f[layer] = slot


def build_rock():
    clear_built()
    bm = bmesh.new()
    layer = bm.faces.layers.int.new("slot")

    rings = []
    # fusta scufundata
    rings.append((_ring(bm, 0.0, -SKIRT, 7, bulge=0.8), VOLCANIC_BLACK))
    # Gulerul de val ramane pe SCORIE, nu pe spuma — ABATERE DE LA BRIEF,
    # verificata pe foaia de referinta si pe randarea de la distanta reala.
    #
    # Brief-ul cere FOAM_WHITE pentru "gulerul de la linia apei". Masurat la
    # 200 m, un guler alb iese la luminanta 172 pe o stanca de 60 — adica 2.9x,
    # EXACT cat farul (173). Cele doua se bateau ca semnal, iar farul trebuie
    # sa ramana punctul cel mai luminos: e singurul lucru care spune "insula
    # locuita" de la distanta aia. Turcoazul de recif (incercat al doilea) a
    # dus contrastul la 2.2x, dar a lasat o dunga saturata la baza.
    #
    # Pe panoul 4 al foii de referinta stanca ramane INTUNECATA (28-91 pe 8
    # biti) pana la linia apei; albul de acolo e al APEI, nu al stancii. Spuma
    # vine deci la integrare, din materialul marii, nu din asset.
    #
    # Gulerul ramane ca GEOMETRIE (evazarea de la baza, ceruta de brief) — doar
    # culoarea lui se schimba.
    rings.append((_ring(bm, 0.0, -0.30, 11, bulge=0.75), VOLCANIC_BLACK))
    rings.append((_ring(bm, 0.01, 0.25, 13, bulge=0.35), VOLCANIC_BLACK))

    prev_t = 0.02
    for idx, (frac, out) in enumerate(LEDGES):
        # peretele pana sub polita
        rings.append((_ring(bm, frac - 0.015, H * (frac - 0.015), 17 + idx * 5),
                      VOLCANIC_BLACK))
        # polita: iese in afara, fata de dedesubt ramane in umbra
        # Politele raman VOLCANIC_BLACK. ROCK_DARK (#67421F) e maroul de
        # desert al canionului si pe bazalt iese RUGINA — exact greseala
        # prinsa deja pe crater (vezi crater_bowl.md, abaterea 3). Muchia de
        # umbra sub polita o face AO-ul, nu un al doilea slot.
        rings.append((_ring(bm, frac, H * frac, 19 + idx * 5, bulge=out),
                      VOLCANIC_BLACK))
        rings.append((_ring(bm, frac + 0.02, H * (frac + 0.02), 23 + idx * 5,
                            bulge=out * 0.35), VOLCANIC_BLACK))
        prev_t = frac + 0.02

    # platoul de varf
    rings.append((_ring(bm, 1.0, H, 61), VOLCANIC_BLACK))

    for (lo, _), (hi, slot) in zip(rings, rings[1:]):
        _bridge(bm, lo, hi, layer, slot)

    # capac de sus (platoul pentru far) si fund (nu se vede, dar inchide corpul)
    top = bm.faces.new(tuple(rings[-1][0]))
    top[layer] = VOLCANIC_BLACK
    bot = bm.faces.new(tuple(reversed(rings[0][0])))
    bot[layer] = VOLCANIC_BLACK

    me = bpy.data.meshes.new("Stack_Rock")
    bm.to_mesh(me)
    bm.free()
    rock = bpy.data.objects.new("Stack_Rock", me)
    bpy.context.collection.objects.link(rock)
    return rock


def build_stairs():
    """Scara in zigzag pe fata +Y a stancii — care e -Z in GODOT, cum cere
    brief-ul.

    Semnul e usor de gresit si l-am gresit: exportul Y-up mapeaza +Y_blender pe
    -Z_godot (verificat pe route66_sign, care isi construieste scutul pe +Y si
    trece `verify_glb --front=-Z`). Prima versiune construia scara pe -Y_blender
    si `verify_glb` a raportat-o la Z pozitiv, adica pe fata din SPATE.

    Geometrie de PANGLICA: fiecare rampa e o placa inclinata cu cateva praguri
    sugerate deasupra, nu trepte reale. La 200 m nimeni nu numara treptele; ce
    se vede e linia in zigzag care urca pe fata intunecata.
    """
    b = Builder()
    w = 1.0
    ramps = 4
    z0, z1 = 0.5, H - 1.6

    def face_y(z, x):
        """Y-ul fetei stancii la inaltimea z si abscisa x.

        Conturul e o elipsa, deci fata nu e un plan: la capatul rampei (x mare)
        stanca e mai "trasa inapoi" decat in ax. Prima versiune folosea doar
        semi-axa, deci rampele ieseau din stanca spre capete si pluteau.
        """
        rx, ry = _profile_xy(z / H)
        q = min(abs(x) / max(rx, 1e-6), 0.999)
        return ry * math.sqrt(1.0 - q * q)

    for i in range(ramps):
        za = z0 + (z1 - z0) * (i / float(ramps))
        zb = z0 + (z1 - z0) * ((i + 1) / float(ramps))
        xa = (-1 if i % 2 == 0 else 1) * _profile_xy(za / H)[0] * 0.48
        xb = (1 if i % 2 == 0 else -1) * _profile_xy(zb / H)[0] * 0.48
        # +0.15, nu +0.55: scara trebuie sa fie LIPITA de fata, iar `face_y`
        # da deja conturul. A doua randare le-a impins cu 0.55 in interior si
        # rampele au disparut in stanca — se vedeau doar capetele podestelor.
        # Semnul conteaza: fata e la Y POZITIV, deci "in afara" inseamna PLUS.
        ya = face_y(za, xa) + 0.15
        yb = face_y(zb, xb) + 0.15

        # rampa: placa lata si subtire, LIPITA de fata (panglica, nu bara)
        b.beam((xa, ya, za), (xb, yb, zb), (w, 0.30), MARBLE_GREY, up=(0, 0, 1))
        # muretul, pe exteriorul rampei
        b.beam((xa, ya + 0.50, za + 0.34), (xb, yb + 0.50, zb + 0.34),
               (0.16, 0.44), MARBLE_GREY, up=(0, 0, 1))
        # podest la capatul de sus al rampei
        b.box((xb, yb, zb + 0.10), (1.7, 1.4, 0.26), MARBLE_GREY)

    return b.to_object("Stack_Stairs")


def build_lighthouse():
    """Farul alb + anexa, pe platou. Doua noduri: corpul si lanterna."""
    b = Builder()
    base_z = H
    # soclu patrat 4 x 4 x 1
    b.box((0.0, 0.0, base_z + 0.5), (4.0, 4.0, 1.0), FOAM_WHITE)
    # turn: prisma cu 10 laturi, D 3 m, inalt 6.5
    b.cylinder((0.0, 0.0, base_z + 1.0 + 3.25), 1.5, 6.5, FOAM_WHITE,
               segments=10)
    # balustrada de sus: un inel plat, nu stalpi (la 200 m stalpii sunt zgomot)
    b.cylinder((0.0, 0.0, base_z + 1.0 + 6.5 + 0.18), 1.85, 0.36, FOAM_WHITE,
               segments=10)
    # casuta-anexa lipita de soclu
    b.box((3.1, 0.4, base_z + 1.0), (3.0, 2.0, 2.0), FOAM_WHITE)
    tower = b.to_object("Lighthouse_White")

    b = Builder()
    lz = base_z + 1.0 + 6.5 + 0.36
    # tambur cu 8 laturi + calota
    b.cylinder((0.0, 0.0, lz + 0.55), 1.05, 1.1, PAINTED, segments=8)
    b.revolve([(1.05, 0.0), (0.75, 0.22), (0.0, 0.42)], PAINTED, segments=8,
              origin=(0.0, 0.0, lz + 1.1))
    lantern = b.to_object("Lighthouse_Lantern")
    return tower, lantern


if __name__ == "__main__":
    rock = build_rock()
    stairs = build_stairs()
    tower, lantern = build_lighthouse()

    # z_range comun: toate piesele fac parte din aceeasi silueta, deci
    # gradientul de AO se calculeaza pe ANSAMBLU (vezi bake_ao z_range).
    # Altfel farul, care sta in ultimii 8 m, si-ar coace singur un gradient
    # complet si baza lui ar iesi la fel de intunecata ca linia apei.
    zr = (-SKIRT, H + 9.0)
    specs = ((rock, AO_ROCK, 0.20), (stairs, AO_STAIR, 0.05),
             (tower, AO_LIGHT, 0.05), (lantern, AO_LIGHT, 0.04))
    for obj, ao, bev in specs:
        snap = snapshot_slots(obj)
        apply_bevel(obj, bev, segments=1, angle_deg=30.0)
        apply_smooth(obj, 55.0)
        assign_uvs(obj, snap)
        obj.data.materials.clear()
        obj.data.materials.append(atlas_material())
        bake_ao(obj, z_range=zr, **ao)
        if "slot" in obj.data.attributes:
            obj.data.attributes.remove(obj.data.attributes["slot"])

    objs = [rock, stairs, tower, lantern]
    total = sum(tri_count(o) for o in objs)
    for o in objs:
        print("%-20s %4d tris" % (o.name, tri_count(o)))
    print("TOTAL                %4d tris  (buget 2400)" % total)
    path, size = export_glb(objs, "stromboli/structures/strombolicchio.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
