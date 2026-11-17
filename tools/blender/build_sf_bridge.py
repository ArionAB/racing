"""San Francisco -- podul rosu carosabil, kit modular (brief docs/asset_briefs/sf_red_bridge.md).

  sanfrancisco/structures/sf_bridge_tower.glb       turnul-portal (x2, X 50 / 150)
  sanfrancisco/structures/sf_bridge_deck_8.glb      segmentul de tablier, 8 m (x25)
  sanfrancisco/structures/sf_bridge_parapet_8.glb   parapetul, 8 m, ambele parti (x28)
  sanfrancisco/structures/sf_bridge_flares.glb      evazarile de la capete (x2)
  sanfrancisco/structures/sf_bridge_cable_main.glb  cablurile deschiderii centrale (x1)
  sanfrancisco/structures/sf_bridge_cable_side.glb  cablul deschiderii laterale (x2)
  sanfrancisco/structures/sf_bridge_anchor.glb      ancorajul de capat (x2)
  sanfrancisco/structures/sf_bridge_walkway_8.glb   trotuarul exterior, 8 m (x28)
  sanfrancisco/structures/sf_bridge_lamp.glb        felinarul (2 x 8)

Rulare (din radacina worktree-ului):
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_sf_bridge.py
Variabila de mediu SFB_ONLY=<piesa>[,<piesa>] reface doar piesele date
(numele scurt: tower, deck_8, parapet_8, flares, cable_main, cable_side, anchor,
walkway_8, lamp).

CADRUL (brief §3): toate cotele de aici sunt in coordonatele GODOT ale podului --
X de-a lungul podului, Y in sus (0 = fata carosabilului), Z lateral (0 = axa).
Helperii `gb`/`gp` le convertesc in Blender ((x, y, z) Godot -> (x, -z, y)
Blender; exportatorul glTF face inversul). Piesele se construiesc DIRECT pe
cadru, iar exportul NU muta nimic (origin=None): originea fiecarei piese e cea
din §4, nu „baza centrata” (memoria finish-recentreaza-fiecare-nod-separat).

Un nod-mesh per material: `<Piesa>_Steel` (slot 7 kerb_red; in felinar si
slotul 22 foam_white pentru sticla) si `<Piesa>_Concrete` (slot 8 concrete).

Bevel (brief §8): fiecare nod se compune din PARTI, fiecare cu bevelul ei,
aplicat inainte de unire. Turnul 0,08 (picioarele 0,03: treapta rosturilor de
tabla are doar 0,06 m, iar tesitura de 0,2 m a muchiilor e modelata); pile si
ancoraje 0,08; parapete, grinzi 0,04; cablurile si tirantii fara bevel. Unde o
parte nu are bevel desi brief-ul il cere (corpul parapetului, placile
trotuarului), motivul e scris langa ea: fete ascunse la imbinarea segmentelor,
sau tesitura e modelata direct in profil (mana curenta).

Gabaritul (§3) si cotele (§4) le verifica pe GLB-ul exportat
`tools/blender/measure_sf_bridge.py` (cu --selftest).

=====================================================================================
LISTELE DE ELEMENTE (scrise INAINTE de geometrie; acceptanta e lista, element cu
element; decuparea din tools/../sf_assets_v1/<piesa>.png da caracterul, brief-ul
cotele)
=====================================================================================

sf_bridge_tower  (decupare: doua picioare-cutie rosii cu rosturi orizontale de
tabla, capace in varf, doua traverse cu colțari si un X gros, talpi de beton)
  T1. Doua picioare, centrate la Z +-14,5, Y -30..+45, sectiune octogonala =
      patrat cu muchiile tesite 0,2 m; se ingusteaza CONTINUU spre centrul
      patratului: anvelopa (cu rosturi) 3,0 m jos -> 2,4 m sus. Niciodata in
      afara patratului X +-1,5, |Z| 13,0..16,0.
  T2. Rosturi orizontale de tabla pe picioare: fasii de 0,30 m in relief de
      0,06 m, la 4 m una de alta (Y -12, -8, ... , +40), AO ~0,8.
  T3. Papuc de otel la baza piciorului, pe pila (Y -16..-15,5), in patrat.
  T4. Traversa de jos: grinda-cutie 2,4 x 2,4, Z -13..+13 (intra 0,1 m in
      picioare), fundul la Y +13,95 (>= +13,8 cu marja), cu 3 rosturi verticale
      in relief (Z 0, +-6,5).
  T5. Colțari triunghiulari grosi (1,5 m pe latura, 1,4 m grosime pe X) in
      cele doua colturi de SUS ale traversei de jos.
  T6. Traversa de sus: centrul la +39 (Y 37,8..40,2), aceeasi grinda-cutie cu
      rosturi, colțari in toate cele patru colturi.
  T7. Contravantuirea: UN SINGUR X din doua bare-cutie de 1,2 x 1,2 m, de la
      colturile traversei de jos la ale traversei de sus.
  T8. Placa de imbinare la incrucisarea X-ului (bloc 1,5 x 2,2 x 2,2).
  T9. Capitelul piciorului (Y 42,4..43,9, putin mai lat decat piciorul,
      tot in patrat).
  T10. Cuseta cablului (saddle) Y 43,9..45: talpa + doi obraji pe X, cu golul
      pentru cablul de 1,0 m la Z +-14,5, Y +44,5.
  T11. Pila de beton (`Tower_Concrete`): un bloc pentru ambele picioare, X +-4,5,
      Z +-19, Y -30..-16, cu soclu (treapta la -19,6, chiar peste apa) si
      margine tesita sus.
  Fara: caneluri, trepte de ingustare, panouri de portal, nervuri verticale.

sf_bridge_deck_8  (decupare: fascia rosie cu panouri si montanti, sub asfalt)
  D1. Doua grinzi laterale (fascia), Z +-15,9..+-16,4, Y +0,25..-4,0, X 0..8.
  D2. Ferma in relief pe fata exterioara (0,2 m spre exterior): stalp de 0,4 m
      la capatul panoului (X 0), doua diagonale groase in V (bare 0,4 m) cu
      varful jos la X 4, talpa jos (Y -4,0..-3,5). Fara goluri.
  D3. Intradosul: placa Z +-16,4, Y -0,6..-1,0, AO ~0,5.
  D4. O grinda transversala la X 0, sub intrados: Y -1,0..-2,5, Z +-15,9.
  Nimic peste Y -0,3 pe |Z| < 15,9. Asfaltul NU se modeleaza (il are jocul).

sf_bridge_parapet_8  (decupare: perete rosu plin cu panouri si o mana curenta
rotunjita; soclul de beton al decuparii NU -- brief-ul pune parapetele pe otel)
  P1. Doi pereti plini, fata interioara la |Z| = 12,2, exterioara la 12,7,
      Y 0..1,2, X 0..8.
  P2. Fata interioara plana: panouri adancite 0,03 m intre pilastri plati de
      0,24 m (la X 0, 2, 4, 6, 8); pilastrii si mana curenta sunt EXACT la 12,2.
  P3. Montanti pe fata exterioara la 2,0 m (X 1, 3, 5, 7), relief 0,15 m.
  P4. Mana curenta rotunjita sus (Y 0,92..1,2), profil cu tesituri la 45 de
      grade, iese DOAR spre exterior, pana la 12,85.

sf_bridge_flares  (decupare: aripile evazate ale capatului)
  F1. Doi pereti, fiecare de la (X 0, |Z| 12,2) pe 10 m spre -X la 20 de grade
      spre exterior, pana la (X -9,40, |Z| 15,62) pe fata interioara.
  F2. Acelasi profil ca parapetul: panouri + pilastri pe interior, montanti
      la 2 m pe exterior, mana curenta rotunjita.

sf_bridge_cable_main  (decupare: cablu gros rosu cu coliere luminoase)
  C1. Doua cabluri principale la Z +-14,5, diametrul 1,0 m (10 laturi),
      parabola de la (0, +44,5) la (100, +44,5) cu varful jos la (50, +3,0).
  C2. Tiranti verticali la X 10..90 (9 pe parte), diametrul 0,35 m (6 laturi),
      de la cablu la Y +0,25.
  C3. Coliere pe cablu la fiecare tirant (diametrul 1,32 m, 0,7 m lungime).
  C4. Mufa de jos a tirantului (diametrul 0,54, Y 0,2..1,0), pe trotuar.

sf_bridge_cable_side  (decupare: acelasi cablu)
  S1. Doua cabluri la Z +-14,5, diametrul 1,0, Y = 4 + 40,5*((X+50)/50)^2,
      X 0 -> -50.
  S2. Tiranti la X -10, -20, -30, -40, diametrul 0,35, pana la Y +0,25.
  S3. Coliere la tiranti.  S4. Mufe la baza tirantilor (ca la C4).

sf_bridge_anchor  (decupare: bloc de beton in trepte, cu carcasa rosie in care
intra cablul)
  A1. Doi piloni de ancoraj (`_Concrete`), Z 13,2..17,8, X -6..+2, Y -24..+6,
      in patru trepte (talpa la apa, fus, doua trepte sus; mai lati jos),
      treapta de sus cu spatele inclinat. Fata +X (gura cablului) si fata
      interioara (13,2) raman drepte.
  A2. Capac de otel pe varful pilonului.
  A3. Gura de cuseta pe fata +X: carcasa de otel cu doi obraji, la
      (X 0..2, Y +4,0, Z +-14,5), in care intra cablul lateral.
  A4. Culeea: zid X -1..+1, Z +-16,4, Y -1,0..-24.
  Nimic pe |Z| < 13,2 deasupra lui Y -0,3.

sf_bridge_walkway_8  (decupare: dale de beton cu balustrada rosie)
  W1. Trotuarul, Z +-12,7..+-16,1, fata de sus la Y +0,20, din patru dale de
      2 m cu rost de 4 cm intre ele (`_Concrete`).
  W2. Bordura rosie la margine, Z +-16,1..+-16,4, pana la Y +0,5.
  W3. Balustrada exterioara groasa: stalpi 0,2 x 0,2 la 4 m si o lisa de
      0,22 x 0,2 la Y 1,0..1,2 (fara lise subtiri).

sf_bridge_lamp  (decupare: felinar rosu pe soclu de beton, cap cu sticla)
  L1. Soclu de beton 0,56 x 0,56, Y 0..0,25 (`Lamp_Concrete`).
  L2. Baza de otel 0,42 x 0,42, Y 0,25..0,85.
  L3. Stalp diametrul 0,3, pana la Y 5,0, cu un inel sub cap.
  L4. Capul diametrul 0,6 (sticla 0,54, ramele 0,6-0,64, streasina
      acoperisului 0,7): palnie scurta jos, sticla hexagonala (slotul 22),
      rame, acoperis-piramida si buton in varf, Y 6,0.
"""

import math
import os

import bmesh
import bpy
from mathutils import Vector

ONLY = [s.strip() for s in os.environ.get("SFB_ONLY", "").split(",") if s.strip()]

STEEL = KERB_RED        # 7
CONC = CONCRETE         # 8
GLASS = FOAM_WHITE      # 22, doar sticla felinarului

DIR = "sanfrancisco/structures/"
SFB_RESULTS = []


# ---------------------------------------------------------------------------
# cadrul: Godot -> Blender
# ---------------------------------------------------------------------------

def gp(x, y, z):
    """Punct Godot (x, y, z) -> Blender (x, -z, y)."""
    return Vector((x, -z, y))


def gb(b, x0, x1, y0, y1, z0, z1, slot):
    """Cutie aliniata, data prin intervalele Godot pe X, Y, Z."""
    zl, zh = min(z0, z1), max(z0, z1)
    return b.box(center=gp(0.5 * (x0 + x1), 0.5 * (y0 + y1), 0.5 * (zl + zh)),
                 size=(x1 - x0, zh - zl, y1 - y0), slot=slot)


def gb2(b, x0, x1, y0, y1, z0, z1, slot):
    """Aceeasi cutie pe ambele parti ale axei (Z si -Z)."""
    for s in (1, -1):
        gb(b, x0, x1, y0, y1, s * z0, s * z1, slot)


def ghull(b, pts, slot):
    """Corp convex din puncte Godot; fetele coplanare se unesc (dissolve)."""
    verts = [b.bm.verts.new(gp(*p)) for p in pts]
    res = bmesh.ops.convex_hull(b.bm, input=verts)
    dead = list({g for g in res["geom_interior"] + res["geom_unused"]
                 if isinstance(g, bmesh.types.BMVert)})
    if dead:
        bmesh.ops.delete(b.bm, geom=dead, context="VERTS")
    alive = [v for v in verts if v.is_valid]
    edges = list({e for v in alive for e in v.link_edges})
    bmesh.ops.dissolve_limit(b.bm, angle_limit=math.radians(1.0), verts=alive, edges=edges)
    alive = [v for v in alive if v.is_valid]
    faces = {f for v in alive for f in v.link_faces}
    for f in faces:
        f[b.slot] = slot
    return faces


def loft(b, rings, slot, cap_start=True, cap_end=True):
    """Suprafata din inele de puncte Godot (acelasi numar de puncte, aceeasi
    ordine), legate cu quad-uri; capete optionale."""
    vr = [[b.bm.verts.new(gp(*p)) for p in r] for r in rings]
    n = len(rings[0])
    faces = []
    for lo, hi in zip(vr, vr[1:]):
        for i in range(n):
            j = (i + 1) % n
            faces.append(b.bm.faces.new((lo[i], lo[j], hi[j], hi[i])))
    if cap_start:
        faces.append(b.bm.faces.new(tuple(reversed(vr[0]))))
    if cap_end:
        faces.append(b.bm.faces.new(tuple(vr[-1])))
    for f in faces:
        f[b.slot] = slot
    return faces


def frame_box(b, P, s0, s1, n0, n1, y0, y1, slot):
    """Cutie in cadrul local al unui perete: P(s, n, y) -> punct Godot
    (s de-a lungul peretelui, n lateral spre exterior, y in sus)."""
    pts = [P(s, n, y) for s in (s0, s1) for n in (n0, n1) for y in (y0, y1)]
    return ghull(b, pts, slot)


def frame_prism(b, P, s0, s1, profile, slot):
    """Profil (n, y) extrudat de-a lungul peretelui de la s0 la s1."""
    rings = [[P(s, n, y) for n, y in profile] for s in (s0, s1)]
    return loft(b, rings, slot)


# ---------------------------------------------------------------------------
# finisare: parti cu bevel propriu -> un nod -> UV pe sloturi, AO, export
# ---------------------------------------------------------------------------

def make_node(name, parts, ao, smooth=30.0, ao_fn=None):
    """`parts` = [(Builder, bevel, unghi_bevel)]. Fiecare parte primeste bevelul
    ei si UV-urile pe sloturi INAINTE de unire; nodul unit primeste materialul
    atlasului si AO-ul copt pe tot ansamblul (razele vad toate partile).
    `ao_fn(p_godot, n_godot) -> multiplicator` corecteaza AO-ul dupa coacere
    (fetele spre jos, rosturile de tabla)."""
    objs = []
    for i, (b, w, ang) in enumerate(parts):
        if len(b.bm.verts) == 0:
            b.bm.free()
            continue
        o = b.to_object("%s__p%d" % (name, i))
        snap = snapshot_slots(o)
        if w > 0:
            apply_bevel(o, w, angle_deg=ang)
        assign_uvs(o, snap)
        objs.append(o)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    obj.data.name = name
    apply_smooth(obj, smooth)
    obj.data.materials.clear()
    obj.data.materials.append(atlas_material())
    bake_ao(obj, **ao)
    if ao_fn is not None:
        me = obj.data
        ca = me.color_attributes["AO"]
        for i, v in enumerate(me.vertices):
            p = (v.co.x, v.co.z, -v.co.y)
            nrm = (v.normal.x, v.normal.z, -v.normal.y)
            val = ca.data[i].color[0] * ao_fn(p, nrm)
            val = max(0.12, min(1.0, val))
            ca.data[i].color = (val, val, val, 1.0)
    if "slot" in obj.data.attributes:
        obj.data.attributes.remove(obj.data.attributes["slot"])
    return obj


def emit(key, objs):
    """Export fara nicio mutare de origine + raport (AABB Godot, triunghiuri)."""
    total, per = 0, {}
    lo = [1e9] * 3
    hi = [-1e9] * 3
    for o in objs:
        per[o.name] = tri_count(o)
        total += per[o.name]
        for v in o.data.vertices:
            g = (v.co.x, v.co.z, -v.co.y)
            for a in range(3):
                lo[a] = min(lo[a], g[a])
                hi[a] = max(hi[a], g[a])
    path, size = export_glb(objs, DIR + "sf_bridge_%s.glb" % key)
    save_blend(objs, "sf_bridge_%s.blend" % key)
    SFB_RESULTS.append((key, total, per, lo, hi, size))
    return objs


def report():
    print("\n===== podul rosu: raport (coordonate Godot) =====")
    for key, total, per, lo, hi, size in SFB_RESULTS:
        print("sf_bridge_%-11s %6d tris  X %8.3f..%8.3f  Y %8.3f..%8.3f  Z %8.3f..%8.3f  %5.1f KB"
              % (key, total, lo[0], hi[0], lo[1], hi[1], lo[2], hi[2], size / 1024.0))
        for n, t in sorted(per.items()):
            print("      %-18s %6d" % (n, t))


def down_dark(k=0.72):
    """Fetele spre jos (intradosuri, burta traverselor) sunt mereu in umbra:
    razele AO nu le gasesc ocluzia (sub ele e cer liber in scena piesei)."""
    def fn(p, n):
        return k if n[1] < -0.5 else 1.0
    return fn


# ---------------------------------------------------------------------------
# turnul
# ---------------------------------------------------------------------------

LEG_Z = 14.5
LEG_Y0, LEG_Y1 = -30.0, 45.0
SEAM_RELIEF = 0.06
SEAM_H = 0.30
SEAMS = [-12.0 + 4.0 * k for k in range(14)]      # -12 .. +40
LB_Y0, LB_Y1 = 13.95, 16.35                       # traversa de jos (fund >= 13,8)
UB_Y0, UB_Y1 = 37.8, 40.2                         # traversa de sus (centrul +39)
CAP_Y0, CAP_Y1 = 42.4, 43.9                       # capitelul
HW_CAP = 1.44


def leg_hw(y):
    """Semilatimea CORPULUI piciorului (fara rosturi): 1,44 jos -> 1,14 sus, ca
    anvelopa cu rosturi de 0,06 sa fie 3,0 -> 2,4 m."""
    return 1.44 - 0.30 * (y - LEG_Y0) / (LEG_Y1 - LEG_Y0)


def octo(y, hw, c, zc):
    """Inel octogonal (patrat de semilatura hw, tesit cu c) la cota y, centrat
    pe (x 0, z zc)."""
    k = hw - c
    pts2 = [(hw, -k), (hw, k), (k, hw), (-k, hw), (-hw, k), (-hw, -k), (-k, -hw), (k, -hw)]
    return [(x, y, zc + z) for x, z in pts2]


def build_leg(b, zc):
    c = 0.20
    cb = c + SEAM_RELIEF * (math.sqrt(2.0) - 1.0)  # tesitura paralela pe rost
    rings = [octo(LEG_Y0, leg_hw(LEG_Y0), c, zc)]
    # T3: papucul de la baza (pe pila), Y -16..-15,5: o treapta in patrat
    for y0, y1, hwo in [(-16.0, -15.5, 1.50)] + [(s - SEAM_H / 2, s + SEAM_H / 2, None) for s in SEAMS]:
        hb0, hb1 = leg_hw(y0), leg_hw(y1)
        o0 = hwo if hwo else hb0 + SEAM_RELIEF
        o1 = hwo if hwo else hb1 + SEAM_RELIEF
        rings += [octo(y0, hb0, c, zc), octo(y0, o0, cb, zc), octo(y1, o1, cb, zc), octo(y1, hb1, c, zc)]
    rings.append(octo(CAP_Y0, leg_hw(CAP_Y0), c, zc))
    # T9: capitelul
    rings.append(octo(CAP_Y0, HW_CAP, 0.26, zc))
    rings.append(octo(CAP_Y1, HW_CAP, 0.26, zc))
    loft(b, rings, STEEL)


def gusset(b, zc_edge, y_edge, dz, dy, half_x=1.26):
    """Colțar triunghiular in planul YZ: unghiul drept in (zc_edge, y_edge),
    catetele `dz` (spre axa) si `dy` (sus/jos), grosimea 2*half_x pe X."""
    pts = []
    for x in (-half_x, half_x):
        pts += [(x, y_edge, zc_edge), (x, y_edge, zc_edge + dz), (x, y_edge + dy, zc_edge)]
    ghull(b, pts, STEEL)


def crossbeam(b, y0, y1, z_end):
    gb(b, -1.2, 1.2, y0, y1, -z_end, z_end, STEEL)
    r = SEAM_RELIEF
    for zc in (-6.5, 0.0, 6.5):         # rosturi verticale pe grinda
        gb(b, -1.2 - r, 1.2 + r, y0 - r, y1 + r, zc - 0.15, zc + 0.15, STEEL)


def build_tower():
    legs = Builder()        # bevel mic: treapta rostului are 0,06
    steel = Builder()       # traverse, colțari, X, cusete: bevel 0,08
    conc = Builder()
    for s in (1, -1):
        build_leg(legs, s * LEG_Z)

    # T4 + T5: traversa de jos, colțarii in colturile de SUS
    crossbeam(steel, LB_Y0, LB_Y1, 13.35)
    for s in (1, -1):
        gusset(steel, s * 13.30, LB_Y1, -s * 1.5, 1.5)
    # T6: traversa de sus, colțari sus si jos
    crossbeam(steel, UB_Y0, UB_Y1, 13.45)
    for s in (1, -1):
        gusset(steel, s * 13.40, UB_Y1, -s * 1.5, 1.5)
        gusset(steel, s * 13.40, UB_Y0, -s * 1.5, -1.5)
    # T7: un singur X, bare-cutie 1,2 x 1,2, de la colturile traversei de jos
    # la ale traversei de sus (capetele intra in grinzi)
    for s in (1, -1):
        steel.beam(gp(0.0, LB_Y1 - 0.30, -s * 12.25), gp(0.0, UB_Y0 + 0.30, s * 12.25),
                   (1.2, 1.2), STEEL, up=(1.0, 0.0, 0.0))
    # T8: placa de la incrucisare
    ym = 0.5 * (LB_Y1 + UB_Y0)
    gb(steel, -0.75, 0.75, ym - 1.1, ym + 1.1, -1.1, 1.1, STEEL)
    # T10: cuseta cablului, pe capitel
    for s in (1, -1):
        zc = s * LEG_Z
        gb(steel, -1.30, 1.30, CAP_Y1 - 0.05, 44.15, zc - 0.95, zc + 0.95, STEEL)
        for dz in (-0.66, 0.66):
            gb(steel, -1.15, 1.15, 44.0, 45.0, zc + dz - 0.125, zc + dz + 0.125, STEEL)

    # T11: pila de beton
    gb(conc, -4.5, 4.5, -30.0, -19.6, -19.0, 19.0, CONC)
    pts = []
    for sx in (1, -1):
        for sz in (1, -1):
            pts += [(sx * 4.25, -19.6, sz * 18.75), (sx * 4.25, -16.6, sz * 18.75),
                    (sx * 3.70, -16.0, sz * 18.20)]
    ghull(conc, pts, CONC)

    def tower_ao(p, n):
        k = 1.0
        if n[1] < -0.5:
            k *= 0.70                            # burta traverselor, sub capitel
        az = abs(abs(p[2]) - LEG_Z)
        r = max(abs(p[0]), az)
        if -16.0 < p[1] < 44.0 and r > leg_hw(p[1]) + 0.02 and r < 1.52:
            for sy in SEAMS:
                if abs(p[1] - sy) <= SEAM_H / 2 + 0.01:
                    k *= 0.80                    # rosturile de tabla
                    break
        return k

    ao = dict(samples=64, dist=3.0, gradient="vertical", low=0.55, high=1.0,
              power=0.6, floor=0.35, z_range=(LEG_Y0, LEG_Y1))
    st = make_node("Tower_Steel", [(legs, 0.03, 50.0), (steel, 0.08, 30.0)], ao, ao_fn=tower_ao)
    co = make_node("Tower_Concrete", [(conc, 0.08, 30.0)], ao)
    return [st, co]


# ---------------------------------------------------------------------------
# segmentul de tablier
# ---------------------------------------------------------------------------

def build_deck():
    st = Builder()
    flat = Builder()        # intradosul: fara bevel (muchiile intra in grinzi)
    for s in (1, -1):
        # D1: grinda laterala
        gb(st, 0.0, 8.0, -4.0, 0.25, s * 15.9, s * 16.4, STEEL)
        zo0, zo1 = s * 16.35, s * 16.60          # relieful fermei (intra 5 cm in grinda)
        # D2: stalpul de la capatul panoului, talpa, diagonalele in V
        gb(st, -0.2, 0.2, -4.0, 0.25, zo0, zo1, STEEL)
        gb(st, 0.0, 8.0, -4.0, -3.5, zo0, zo1, STEEL)
        zc = s * 16.475
        for xa, xb in ((0.25, 4.0), (7.75, 4.0)):
            st.beam(gp(xa, 0.0, zc), gp(xb, -3.55, zc), (0.4, 0.25), STEEL, up=(0.0, 1.0, 0.0))
    # D3: intradosul
    gb(flat, 0.0, 8.0, -1.0, -0.6, -16.4, 16.4, STEEL)
    # D4: grinda transversala la X 0
    gb(st, -0.3, 0.3, -2.5, -1.0, -15.9, 15.9, STEEL)

    def deck_ao(p, n):
        if n[1] < -0.5 and abs(p[2]) < 15.95 and p[1] > -1.05:
            return 0.55                          # intradosul: mereu in umbra
        if n[1] < -0.5:
            return 0.75
        return 1.0

    ao = dict(samples=32, dist=2.5, gradient="vertical", low=0.75, high=0.95,
              power=1.0, floor=0.35, z_range=(-4.0, 0.25))
    return [make_node("Deck_Steel", [(st, 0.04, 30.0), (flat, 0.0, 30.0)], ao, ao_fn=deck_ao)]


# ---------------------------------------------------------------------------
# parapetul si evazarile: acelasi profil de perete
# ---------------------------------------------------------------------------

PAR_IN, PAR_T = 12.2, 0.5
# P4: mana curenta (n lateral spre exterior de la fata interioara, y). Tesiturile
# la 45 de grade SUNT rotunjirea (bevelul e modelat, nu modificator): fata
# interioara ramane la n = 0, iar spre exterior iese pana la n = 0,65 (|Z| 12,85).
CAP_PROFILE = [(0.0, 0.92), (0.58, 0.92), (0.65, 0.99), (0.65, 1.12),
               (0.57, 1.20), (0.08, 1.20), (0.0, 1.12)]


def wall(b, P, length, posts_out, pilasters):
    """Un perete de parapet in cadrul P(s, n, y): corp (fata interioara
    retrasa 0,03 = panourile), pilastri plati la n = 0, montanti exteriori,
    mana curenta."""
    frame_box(b, P, 0.0, length, 0.03, PAR_T, 0.0, 0.95, STEEL)
    frame_prism(b, P, 0.0, length, CAP_PROFILE, STEEL)
    for s0, s1 in pilasters:
        frame_box(b, P, s0, s1, 0.0, 0.10, 0.0, 0.93, STEEL)
    for sc in posts_out:
        frame_box(b, P, sc - 0.12, sc + 0.12, PAR_T - 0.05, PAR_T + 0.15, 0.0, 0.93, STEEL)


def wall_ao():
    return dict(samples=32, dist=1.5, gradient="vertical", low=0.80, high=1.0,
                power=1.0, floor=0.5, strength=0.6, z_range=(0.0, 1.2))


def build_parapet():
    b = Builder()
    for s in (1, -1):
        def P(sv, n, y, s=s):
            return (sv, y, s * (PAR_IN + n))
        wall(b, P, 8.0, posts_out=(1.0, 3.0, 5.0, 7.0),
             pilasters=((0.0, 0.12), (1.88, 2.12), (3.88, 4.12), (5.88, 6.12), (7.88, 8.0)))
    # fara modificator de bevel: capetele de pe X sunt imbinari ascunse intre
    # segmente, iar rotunjirea mainii curente e in profil (CAP_PROFILE)
    return [make_node("Parapet_Steel", [(b, 0.0, 30.0)], wall_ao(), ao_fn=down_dark(0.8))]


FLARE_L, FLARE_A = 10.0, math.radians(20.0)


def build_flares():
    b = Builder()
    ca, sa = math.cos(FLARE_A), math.sin(FLARE_A)
    for s in (1, -1):
        # s de-a lungul peretelui (spre -X, 20 de grade spre exterior),
        # n spre exterior (perpendicular pe perete, departe de drum)
        def P(sv, n, y, s=s):
            return (-sv * ca + n * sa, y, s * (PAR_IN + sv * sa + n * ca))
        wall(b, P, FLARE_L, posts_out=(1.0, 3.0, 5.0, 7.0, 9.0),
             pilasters=((1.88, 2.12), (3.88, 4.12), (5.88, 6.12), (7.88, 8.12)))
    return [make_node("Flares_Steel", [(b, 0.0, 30.0)], wall_ao(), ao_fn=down_dark(0.8))]


# ---------------------------------------------------------------------------
# cablurile
# ---------------------------------------------------------------------------

CABLE_R, CABLE_SEG = 0.5, 10
HANGER_R, HANGER_SEG = 0.175, 6
COLLAR_R, COLLAR_L = 0.66, 0.7
HANGER_FOOT = 0.25


def cable_set(b, f, xs_path, hangers):
    """Cabluri la Z +-14,5 pe curba y = f(x), cu tiranti, coliere si papuci."""
    for s in (1, -1):
        z = s * LEG_Z
        path = [gp(x, f(x), z) for x in xs_path]
        b.sweep(path, CABLE_R, STEEL, segments=CABLE_SEG, dome_end=False, cap_start=True)
        for xh in hangers:
            yc = f(xh)
            # tirantul: de la papuc (Y 0,25) pana in axa cablului
            y0 = HANGER_FOOT
            b.cylinder(gp(xh, 0.5 * (y0 + yc), z), HANGER_R, yc - y0, STEEL,
                       segments=HANGER_SEG, axis="Z")
            # colierul, pe tangenta cablului
            h = 0.05
            t = (gp(xh + h, f(xh + h), z) - gp(xh - h, f(xh - h), z)).normalized()
            c = gp(xh, yc, z)
            b.sweep([c - t * (COLLAR_L / 2), c + t * (COLLAR_L / 2)], COLLAR_R, STEEL,
                    segments=CABLE_SEG, dome_end=False, cap_start=True)
            # mufa de prindere de jos (decuparea `cable_side` arata tirantul cu
            # mufe groase la capete), asezata pe trotuar (fata lui e la +0,20)
            b.cylinder(gp(xh, 0.60, z), 0.27, 0.80, STEEL, segments=HANGER_SEG, axis="Z")


CABLE_AO = dict(samples=8, dist=1.0, gradient="none", strength=0.0, floor=1.0)


def build_cable_main():
    b = Builder()

    def f(x):
        return 3.0 + 41.5 * ((x - 50.0) / 50.0) ** 2
    xs = [2.5 * i for i in range(41)]
    cable_set(b, f, xs, [10.0 * k for k in range(1, 10)])
    return [make_node("CableMain_Steel", [(b, 0.0, 30.0)], CABLE_AO, smooth=40.0)]


def build_cable_side():
    b = Builder()

    def f(x):
        return 4.0 + 40.5 * ((x + 50.0) / 50.0) ** 2
    xs = [-2.5 * i for i in range(21)]
    cable_set(b, f, xs, [-10.0, -20.0, -30.0, -40.0])
    return [make_node("CableSide_Steel", [(b, 0.0, 30.0)], CABLE_AO, smooth=40.0)]


# ---------------------------------------------------------------------------
# ancorajul
# ---------------------------------------------------------------------------

def build_anchor():
    conc = Builder()
    st = Builder()
    for s in (1, -1):
        def Z(a, c, s=s):
            return (s * a, s * c)
        # A1: trei trepte, mai late jos; fata interioara ramane la 13,2
        gb(conc, -6.0, 2.0, -24.0, -18.6, *Z(13.2, 17.8), CONC)        # talpa
        gb(conc, -5.6, 2.0, -18.6, 0.6, *Z(13.2, 17.4), CONC)          # fusul
        gb(conc, -5.1, 2.0, 0.6, 3.0, *Z(13.2, 17.3), CONC)
        pts = []
        for zz in (13.4, 16.9):
            pts += [(-3.9, 3.0, s * zz), (1.6, 3.0, s * zz), (1.6, 5.5, s * zz),
                    (-1.6, 5.5, s * zz), (-3.9, 4.0, s * zz)]
        ghull(conc, pts, CONC)
        # A2: capacul de otel
        gb(st, -1.8, 1.8, 5.45, 6.0, *Z(13.55, 16.75), STEEL)
        # A3: carcasa cusetei pe fata +X, cu doi obraji; cablul (Y 4,0, Z 14,5,
        # raza 0,5) intra intre ei
        gb(st, 0.6, 1.75, 2.95, 5.35, *Z(13.65, 15.35), STEEL)
        for dz in (-0.66, 0.66):
            gb(st, 1.6, 2.0, 3.0, 5.25, *Z(14.5 + dz - 0.15, 14.5 + dz + 0.15), STEEL)
        gb(st, 1.6, 2.0, 3.0, 3.42, *Z(13.85, 15.15), STEEL)     # pragul de sub cablu
    # A4: culeea
    gb(conc, -1.0, 1.0, -24.0, -1.0, -16.4, 16.4, CONC)

    ao = dict(samples=64, dist=3.0, gradient="vertical", low=0.60, high=1.0,
              power=0.7, floor=0.35, z_range=(-24.0, 6.0))
    co = make_node("Anchor_Concrete", [(conc, 0.08, 30.0)], ao, ao_fn=down_dark(0.72))
    sto = make_node("Anchor_Steel", [(st, 0.08, 30.0)], ao, ao_fn=down_dark(0.72))
    return [sto, co]


# ---------------------------------------------------------------------------
# trotuarul
# ---------------------------------------------------------------------------

def build_walkway():
    slabs = Builder()       # dalele: rostul de 4 cm e golul dintre ele, fara bevel
    st = Builder()
    posts = Builder()       # stalpii: fara bevel (0,2 m, intra in bordura si in lisa)
    for s in (1, -1):
        for k in range(4):
            gb(slabs, 2.0 * k + 0.02, 2.0 * k + 1.98, -0.05, 0.20, s * 12.7, s * 16.1, CONC)
        gb(st, 0.0, 8.0, -0.05, 0.50, s * 16.1, s * 16.4, STEEL)           # W2 bordura
        for xp in (0.0, 4.0):                                              # W3 stalpi
            gb(posts, xp, xp + 0.2, 0.45, 1.05, s * 16.15, s * 16.35, STEEL)
        gb(st, 0.0, 8.0, 1.0, 1.2, s * 16.14, s * 16.36, STEEL)            # W3 lisa
    ao = dict(samples=32, dist=1.5, gradient="vertical", low=0.85, high=1.0,
              power=1.0, floor=0.5, strength=0.6, z_range=(-0.05, 1.2))
    co = make_node("Walkway_Concrete", [(slabs, 0.0, 30.0)], ao)
    sto = make_node("Walkway_Steel", [(st, 0.04, 30.0), (posts, 0.0, 30.0)], ao,
                    ao_fn=down_dark(0.8))
    return [sto, co]


# ---------------------------------------------------------------------------
# felinarul
# ---------------------------------------------------------------------------

def build_lamp():
    conc = Builder()
    st = Builder()
    tube = Builder()        # stalpul si inelele: fara bevel (cilindri cu putine laturi)
    gb(conc, -0.28, 0.28, 0.0, 0.25, -0.28, 0.28, CONC)                    # L1
    gb(st, -0.21, 0.21, 0.25, 0.85, -0.21, 0.21, STEEL)                    # L2
    gb(st, -0.25, 0.25, 0.80, 0.90, -0.25, 0.25, STEEL)
    tube.cylinder(gp(0, 2.95, 0), 0.15, 4.1, STEEL, segments=8)            # L3 stalpul
    tube.cylinder(gp(0, 4.95, 0), 0.21, 0.12, STEEL, segments=8)           # inelul
    tube.frustum(gp(0, 5.12, 0), 0.13, 0.28, 0.24, STEEL, segments=6)      # L4 palnia
    tube.cylinder(gp(0, 5.27, 0), 0.30, 0.06, STEEL, segments=6)           # rama jos
    tube.cylinder(gp(0, 5.52, 0), 0.27, 0.44, GLASS, segments=6)           # sticla
    tube.cylinder(gp(0, 5.77, 0), 0.32, 0.06, STEEL, segments=6)           # rama sus
    tube.frustum(gp(0, 5.875, 0), 0.35, 0.08, 0.15, STEEL, segments=6)     # acoperisul
    tube.cylinder(gp(0, 5.975, 0), 0.06, 0.05, STEEL, segments=6)          # butonul
    ao = dict(samples=32, dist=1.0, gradient="vertical", low=0.75, high=1.0,
              power=1.0, floor=0.5, strength=0.5, z_range=(0.0, 6.0))
    sto = make_node("Lamp_Steel", [(st, 0.04, 30.0), (tube, 0.0, 30.0)], ao, smooth=50.0)
    co = make_node("Lamp_Concrete", [(conc, 0.04, 30.0)], ao)
    return [sto, co]


# ---------------------------------------------------------------------------

PIECES = [
    ("tower", build_tower),
    ("deck_8", build_deck),
    ("parapet_8", build_parapet),
    ("flares", build_flares),
    ("cable_main", build_cable_main),
    ("cable_side", build_cable_side),
    ("anchor", build_anchor),
    ("walkway_8", build_walkway),
    ("lamp", build_lamp),
]

clear_built()
for key, fn in PIECES:
    if ONLY and key not in ONLY:
        continue
    emit(key, fn())
    clear_built()
report()
