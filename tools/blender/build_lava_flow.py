"""Stromboli — limba de lava, trei stadii (brief docs/asset_briefs/lava_set.md).

  LavaFlow  stromboli/effects/lava_flow.glb
            Lava_Stage1 / Lava_Stage2 / Lava_Stage3

Gimmick-ul pistei: limba inchide ruta scurta tur dupa tur. Stadiul 1 e liber,
stadiul 2 lasa o poarta de 4 m, stadiul 3 e zid.

Trei lucruri sunt CONTRACT cu `LavaFlowHazard` si cu fizica:

1. **Coada comuna.** Toate trei stadiile pleaca din acelasi punct (y=0 in
   Blender) si cresc INAINTE. Hazardul schimba doar mesh-ul vizibil, fara sa
   mute nodul — deci daca stadiile n-ar impartasi coada, limba ar SARI la
   fiecare tur in loc sa avanseze.

2. **Directia.** Frontul e spre -Z in Godot, adica spre +Y in Blender (exportul
   Y-up inverseaza). Acelasi semn pe care l-am gresit pe Strombolicchio.

3. **Marginea tesita sub 40 de grade.** Nu e estetica: raycast-ul suspensiei
   citeste un prag vertical ca zid, iar masina care atinge lateral limba
   trebuie oprita de fizica, nu aruncata. Vezi memoria
   `suprafete-cu-goluri-si-praguri`.

Crapaturile sunt geometrie separata, pe slotul 30, si raman la AO 1.0 —
altfel ocluzia le stinge exact semnalul pentru care exista slotul.

FORMA E UN CLESTE, NU TRUNCHI+BRATE, si asta e o lectie platita (aug 2026):

Versiunea din brief (trunchi comun care se desparte la 2/3 in doua brate) avea
poarta INFUNDATA prin constructie: culoarul dintre brate se inchidea in amonte
de fata trunchiului, deci nu se putea traversa din nicio directie — cutia de
gabarit a masinii (tools/probe_lava_stages.gd) atingea la orice aliniere a
rutei, chiar cu banda coapta centrata pe axa la ±0.2 m. Captura de livrare
arata o masina PARCATA in culoar; nimeni nu incercase o trecere.

Acum:
  Stage1  lobul dinspre munte, singur, 12 m — ruta e libera langa el
  Stage2  DOUA limbi gemene (0->38 si 6->38) cu banda de 4.0 m intre ele pe
          TOATA lungimea: ruta trece drept prin canionul de lava
  Stage3  limba unita, lata, 0->48: zidul care inchide banda

Lungimile sunt si ele masurate pe pista, nu din brief: scurtatura reala are
~46 m, iar buzunarul dintre ea si ocol ~40-50 m — cu 40/60/80 coada ajungea
pe ocol oriunde am fi rotit axa. Coada comuna (y=0) si latimile per limba
raman contractul vechi; nodul sta pe INTRAREA scurtaturii, cu -Z pe axa ei.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \
        --python tools/blender/run_build.py -- build_lava_flow.py
"""

import math
from mathutils import Matrix, Vector

# `dist` mic: pliurile de funie au 0.2-0.3 m, deci ocluzia care conteaza e
# LOCALA. Cu dist mare, toata limba iese uniform intunecata.
AO_CRUST = dict(samples=26, dist=2.2, gradient="none", floor=0.55)

THICK = 0.85           # grosimea crustei peste sol
BEVEL_SIDE = 0.55      # cat se retrage fata laterala pe verticala -> ~35 grade
CRACK_W = 0.28
CRACK_SINK = 0.05

CRUST = VOLCANIC_BLACK
GLOW = LAVA_ORANGE


def _lcg(seed):
    st = [seed & 0x7FFFFFFF]

    def nxt():
        st[0] = (st[0] * 1103515245 + 12345) & 0x7FFFFFFF
        return st[0] / float(0x7FFFFFFF)
    return nxt


def _half_width(t, length, base=5.0):
    """Semi-latimea limbii la fractia `t` din lungime (0 = coada, 1 = front).

    Brief: 8-12 m lat, variabil. Coada mai ingusta (lava s-a scurs), mijlocul
    plin, frontul bulbos — lobii care se impung inainte sunt tot o umflare.
    """
    w = base * (0.72 + 0.42 * math.sin(t * math.pi * 0.85 + 0.35))
    if t > 0.82:                      # frontul se umfla
        w *= 1.0 + 0.16 * math.sin((t - 0.82) / 0.18 * math.pi)
    return w


def _ribbon(b, path, seed, crack_density=1.0, tail_taper=True):
    """O limba de lava de-a lungul unei axe, cu crusta + crapaturi.

    `path` e o lista de (x, y, half_width) de la coada spre front.
    Returneaza lista de centre de crapatura, ca sa le putem ridica AO-ul.
    """
    rnd = _lcg(seed)
    n = len(path)
    glow_pts = []

    # --- crusta: doua inele de varfuri (sus si jos), legate lateral ----------
    bm = b.bm
    layer = b.slot
    top_l, top_r, bot_l, bot_r = [], [], [], []
    for i, (x, y, hw) in enumerate(path):
        t = i / float(n - 1)
        # pliurile de funie: unde joase PE DIRECTIA curgerii
        fold = 0.13 * math.sin(t * math.pi * 7.0) + 0.07 * math.sin(t * math.pi * 13.0)
        z_top = THICK + fold
        jitter = (rnd() - 0.5) * 0.5
        hwj = hw + jitter
        top_l.append(bm.verts.new((x - hwj, y, z_top)))
        top_r.append(bm.verts.new((x + hwj, y, z_top)))
        # baza iese mai in afara: fata laterala cade tesit (vezi antet)
        bot_l.append(bm.verts.new((x - hwj - BEVEL_SIDE, y, 0.0)))
        bot_r.append(bm.verts.new((x + hwj + BEVEL_SIDE, y, 0.0)))

    for i in range(n - 1):
        f = bm.faces.new((top_l[i], top_r[i], top_r[i + 1], top_l[i + 1]))
        f[layer] = CRUST
        f = bm.faces.new((bot_l[i], top_l[i], top_l[i + 1], bot_l[i + 1]))
        f[layer] = CRUST
        f = bm.faces.new((top_r[i], bot_r[i], bot_r[i + 1], top_r[i + 1]))
        f[layer] = CRUST

    # capacul frontului: buza bulboasa, incandescenta (brief)
    f = bm.faces.new((top_l[-1], top_r[-1], bot_r[-1], bot_l[-1]))
    f[layer] = GLOW
    glow_pts.append((path[-1][0], path[-1][1], THICK * 0.5))
    # coada: inchisa, dar pe crusta (lava veche)
    f = bm.faces.new((bot_l[0], bot_r[0], top_r[0], top_l[0]))
    f[layer] = CRUST

    # --- crapaturi: fasii scufundate care urmeaza pliurile ------------------
    # Se inmultesc spre front (lava proaspata), se raresc spre coada.
    count = max(3, int(n * 0.42 * crack_density))
    for k in range(count):
        # distributie inclinata spre front: t = u^0.65
        u = (k + 0.5) / count
        t = u ** 0.65
        i = min(int(t * (n - 1)), n - 2)
        x, y, hw = path[i]
        z = THICK + 0.13 * math.sin(t * math.pi * 7.0) - CRACK_SINK
        # crapatura transversala, cu lungime aleatoare, decalata pe latime
        span = hw * (0.35 + 0.55 * rnd())
        off = (rnd() - 0.5) * hw * 0.8
        ang = (rnd() - 0.5) * 0.9          # usor oblica, urmeaza pliul
        dx, dy = math.cos(ang) * span, math.sin(ang) * span * 0.55
        p0 = (x + off - dx, y - dy, z)
        p1 = (x + off + dx, y + dy, z)
        b.beam(p0, p1, (CRACK_W, 0.07), GLOW, up=(0, 0, 1))
        # Se retin AMBELE capete, nu mijlocul: o crapatura se intinde pana la
        # +-2 m pe Y (dx/dy sunt aleatoare), iar o cautare cu raza 1.2 in jurul
        # mijlocului nu prinde niciun varf al ei. Prima versiune raporta "0
        # varfuri ridicate la AO 1.0" pe stadiile 1 si 3 — numaratoarea aia e
        # singurul motiv pentru care s-a vazut; pe imagine, o crapatura
        # intunecata langa una luminoasa nu sare in ochi.
        glow_pts.append(p0)
        glow_pts.append(p1)
    return glow_pts


def _spine(length, bend=0.0, seed=1):
    """Axa limbii: puncte (x, y, half_width) de la coada (y=0) spre front."""
    step = 2.6
    n = max(6, int(length / step))
    pts = []
    for i in range(n + 1):
        t = i / float(n)
        y = length * t
        x = bend * math.sin(t * math.pi * 0.8) * length * 0.06
        pts.append((x, y, _half_width(t, length)))
    return pts


# 5.0, nu 4.0 (brief): poarta reala se masoara CU MASINA, nu pe mesh. Doua
# lucruri o ingusteaza sub cifra nominala: bevelul de 0.10 umfla fiecare limba
# spre banda cu ~0.18 m, iar EVAZAREA bazei (BEVEL_SIDE 0.55) mai ia o data pe
# atat la firul solului — unde calca rotile. Cu 4.37 nominal, ProbeLavaStages
# (masina reala, AI la volan) ardea pe o trecere cu ±1 m abatere: toleranta
# era sub ce poate tine cineva la 20 m/s. La 5.0 golul de sus ramane ~4.6 —
# citeste tot "abia incap" — iar la sol raman ~3.5 m intre evazari.
GATE = 5.0


def _twin_arm(sgn, start, length, seed):
    """O limba a clestelui: axa ei sta la GATE/2 + semi-latime de axa benzii,
    pe partea `sgn`, de la `start` la `length`. Semi-latimea foloseste fractia
    din PROPRIA lungime, ca frontul bulbos sa cada la capatul ei real."""
    step = 2.6
    n = max(6, int((length - start) / step))
    pts = []
    for i in range(n + 1):
        t = i / float(n)
        y = start + (length - start) * t
        hw = _half_width(t, length - start, base=3.4)
        # unda usoara pe axa limbii, ca marginea interioara sa nu iasa rigla —
        # amplitudine sub jumatate de jitter, ca poarta sa ramana ~4 m
        x = sgn * (GATE * 0.5 + hw) + 0.35 * math.sin(y * 0.31 + sgn)
        pts.append((x, y, hw))
    return pts


def build_stage1():
    clear_built()
    b = Builder()
    # Lobul dinspre munte (x negativ = latura din amonte la asezarea din
    # Track11). Singur si scurt: la turul 1 ruta trece libera pe langa el.
    glow = _ribbon(b, _twin_arm(-1, 0.0, 12.0, seed=3), seed=11,
                   crack_density=0.85)
    return b.to_object("Lava_Stage1"), glow


def build_stage2():
    """Clestele: doua limbi gemene cu banda de 4.0 m intre ele, cap la cap.

    Banda e MASURATA, nu aproximata: `GATE` e distanta libera dintre marginile
    interioare, iar axele limbilor se aseaza la GATE/2 + semi-latime. Daca o
    desenezi din ochi, poarta iese 2 m sau 7 m si gimmick-ul pistei (mai
    incapi sau nu) devine intamplare.
    """
    b = Builder()
    glow = []
    glow += _ribbon(b, _twin_arm(-1, 0.0, 38.0, seed=5), seed=21,
                    crack_density=1.2)
    # Limba a doua abia AJUNGE: canionul cu ambii pereti tine doar ultimii
    # 16 m (22->38) — cat poarta din brief. Restul apropierii are un singur
    # perete, pe stanga: loc sa te aliniezi INAINTE de stramtoare. Cu ambele
    # limbi pe toata lungimea, ProbeLavaStages ardea trecerea cu ±1 m abatere
    # — un canion de 38 m e alt joc decat o poarta de 16.
    glow += _ribbon(b, _twin_arm(1, 22.0, 38.0, seed=7), seed=31,
                    crack_density=1.6)
    return b.to_object("Lava_Stage2"), glow


def build_stage3():
    """48 m, front lat si continuu: limbile s-au unit, banda nu mai exista."""
    b = Builder()
    path = _spine(48.0, bend=0.25, seed=9)
    # destul de lata cat sa acopere amprenta ambelor limbi + banda
    path = [(x, y, hw * 1.75) for (x, y, hw) in path]
    # frontul se latteste mult in ultima cincime: zid revarsat
    path = [(x, y, hw * (1.0 + 0.85 * max(0.0, (i / float(len(path) - 1)) - 0.78) / 0.22))
            for i, (x, y, hw) in enumerate(path)]
    glow = _ribbon(b, path, seed=41, crack_density=1.35)
    return b.to_object("Lava_Stage3"), glow


def _lift_glow(obj, slot=GLOW):
    """Ridica AO la 1.0 pe varfurile fetelor incandescente (brief).

    Se recunosc dupa UV: `assign_uvs` a colapsat deja fiecare fata pe centrul
    slotului ei, deci `u` spune exact ce e fata. Varianta anterioara cauta dupa
    DISTANTA fata de centrele retinute la constructie si rata: o crapatura se
    intinde pana la +-2 m, iar o raza in jurul mijlocului ei nu prinde niciun
    varf (stadiile 1 si 3 raportau 0). Cu UV-ul nu mai exista cazul.
    """
    me = obj.data
    ca = me.color_attributes.get("AO")
    uv = me.uv_layers.get("UVMap")
    if ca is None or uv is None:
        return 0
    want = (slot + 0.5) / 32.0
    touched = set()
    for poly in me.polygons:
        u = sum(uv.data[li].uv[0] for li in poly.loop_indices) / poly.loop_total
        if abs(u - want) < 0.008:
            for vi in poly.vertices:
                touched.add(vi)
    for vi in touched:
        ca.data[vi].color = (1.0, 1.0, 1.0, 1.0)
    return len(touched)


if __name__ == "__main__":
    built = []
    for fn in (build_stage1, build_stage2, build_stage3):
        obj, glow = fn()
        snap = snapshot_slots(obj)
        apply_bevel(obj, 0.10, segments=1, angle_deg=30.0)
        apply_smooth(obj, 40.0)     # prag mic: crusta trebuie sa ramana fatetata
        assign_uvs(obj, snap)
        obj.data.materials.clear()
        obj.data.materials.append(atlas_material())
        bake_ao(obj, **AO_CRUST)
        if "slot" in obj.data.attributes:
            obj.data.attributes.remove(obj.data.attributes["slot"])
        lit = _lift_glow(obj)
        print("%-12s %4d tris  (%d varfuri de crapatura la AO 1.0)"
              % (obj.name, tri_count(obj), lit))
        built.append(obj)

    total = sum(tri_count(o) for o in built)
    print("TOTAL        %4d tris  (buget 3600)" % total)
    path, size = export_glb(built, "stromboli/effects/lava_flow.glb")
    print("export: %s (%.1f KB)" % (path, size / 1024.0))
