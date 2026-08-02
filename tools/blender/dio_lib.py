"""Biblioteca de build pentru assets-urile "diorama" (Blender 4.x/5.x).

Contractul implementat aici e cel din docs/blender_export.md:
  1. UV-urile fiecarei fete colapsate pe CENTRUL unui slot din palette_atlas.png
  2. Vertex colors = AO copt (aici: raycast real in emisfera, nu doar gradient)
  3. Scara in metri, originea la baza obiectului, centrata in XY (Blender)
  4. Bevel consistent, aplicat in geometrie
  5. Export GLB cu UV + vertex colors

Rulare (din Blender, prin MCP):
    exec(open(r"d:/GameDev/ignition-spike/tools/blender/dio_lib.py").read())

Nota de axe: exportatorul glTF converteste Blender Z-up -> glTF Y-up prin
(x, y, z) -> (x, z, -y). Deci **Blender +Y devine Godot -Z**. Brief-urile cer
"fata spre -Z" in spatiul Godot, adica geometria din fata se modeleaza spre
+Y in Blender.
"""

import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree

# --- Paleta: indicii trebuie sa ramana identici cu scripts/palette.gd ---------
SLOTS = 32

SAND_LIGHT, SAND_MID, SAND_SHADOW = 0, 1, 2
ROCK_LIGHT, ROCK_DARK = 3, 4
ASPHALT, ASPHALT_EDGE, KERB_RED = 5, 6, 7
CONCRETE, WOOD, RUST, PAINTED = 8, 9, 10, 11
CACTUS_GREEN, DRY_VEGETATION = 12, 13

PROJECT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ATLAS = os.path.join(PROJECT, "assets", "textures", "palette_atlas.png")
MODELS = os.path.join(PROJECT, "assets", "models")
BLENDS = os.path.join(PROJECT, "assets", "blender")


def slot_u(slot):
    """Coordonata u care nimereste centrul slotului (v e mereu 0.5)."""
    return (slot + 0.5) / SLOTS


def _lcg(seed):
    """Generator determinist minimal. Nu folosim `random`: build-ul trebuie sa
    dea acelasi rezultat la fiecare rulare, indiferent de ordinea apelurilor.
    Acelasi LCG ca in Builder.rock()."""
    state = (seed * 1103515245 + 12345) & 0x7FFFFFFF

    def rand():
        nonlocal state
        state = (state * 1103515245 + 12345) & 0x7FFFFFFF
        return state / 0x7FFFFFFF

    return rand


def _span_points(p1, p2, count_or_step, endpoints=True):
    """Puncte echidistante pe segmentul p1->p2 — nucleul de repetitie comun
    pentru pickets/railing/ladder (vezi #A1).

    count_or_step: int = numar de puncte, float = pas in metri (rotunjit ca sa
    cada fix pe capete). endpoints=False decaleaza cu jumatate de pas, pentru
    sipci care nu trebuie sa se suprapuna peste stalpii de colt.
    """
    a, b = Vector(p1), Vector(p2)
    d = b - a
    if isinstance(count_or_step, bool):  # bool e subclasa de int, ar trece tacut
        raise TypeError("count_or_step trebuie int (numar) sau float (pas)")
    if isinstance(count_or_step, int):
        n = max(count_or_step, 1)
    else:
        n = max(int(round(d.length / max(count_or_step, 1e-6))) + 1, 2)
    if n == 1:
        return [(a + b) * 0.5]
    if endpoints:
        return [a + d * (i / (n - 1)) for i in range(n)]
    return [a + d * ((i + 0.5) / n) for i in range(n)]


# --- Contururi 2D reutilizabile (pentru Builder.prism) ------------------------

def star_outline(radius, inner=0.42, points=5, rotation=-90.0):
    """Contur de stea in planul XZ, pentru `Builder.prism`.

    Conturul e concav; bmesh il accepta ca ngon si exportatorul il trianguleaza.
    `rotation` e unghiul primului varf: implicit -90°, adica un varf in JOS —
    asa varful de jos intra in stalp si ascunde imbinarea.

    Traia local in build_gas_station.py:31-38; #C4 il refoloseste, deci a urcat
    aici (nota 32 din auditul de pipeline). Valorile implicite sunt cele vechi,
    ca benzinaria sa se regenereze identic.
    """
    pts = []
    for i in range(points * 2):
        a = math.radians(rotation + i * (360.0 / (points * 2)))
        r = radius if i % 2 == 0 else radius * inner
        pts.append((r * math.cos(a), r * math.sin(a)))
    return pts


# --- Constructie de geometrie -------------------------------------------------

class Builder:
    """Aduna toate piesele intr-un singur bmesh, marcand fiecare fata cu slotul
    ei de paleta. Slotul se pastreaza intr-un layer int si se transforma in UV
    abia dupa bevel (vezi assign_uvs)."""

    def __init__(self):
        self.bm = bmesh.new()
        self.slot = self.bm.faces.layers.int.new("slot")

    def _tag(self, verts, slot):
        faces = set()
        for v in verts:
            faces.update(v.link_faces)
        for f in faces:
            f[self.slot] = slot
        return faces

    def box(self, center, size, slot, rotation=None):
        """Cutie aliniata pe axe (sau rotita), definita prin centru + dimensiuni."""
        mat = Matrix.Translation(Vector(center))
        if rotation is not None:
            rot = rotation.to_matrix() if hasattr(rotation, "to_matrix") else rotation
            mat = mat @ rot.to_4x4()
        mat = mat @ Matrix.Diagonal(Vector(size).to_4d())
        res = bmesh.ops.create_cube(self.bm, size=1.0, matrix=mat)
        return self._tag(res["verts"], slot)

    def beam(self, p1, p2, thickness, slot, up=None):
        """Grinda dreptunghiulara intre doua puncte. Baza pentru schele/turnuri."""
        p1, p2 = Vector(p1), Vector(p2)
        d = p2 - p1
        length = d.length
        if length < 1e-6:
            return set()
        z = d.normalized()
        ref = Vector(up) if up else (Vector((0, 0, 1)) if abs(z.z) < 0.9 else Vector((1, 0, 0)))
        x = ref.cross(z)
        if x.length < 1e-6:
            x = Vector((1, 0, 0)).cross(z)
        x.normalize()
        y = z.cross(x)
        rot = Matrix((x, y, z)).transposed().to_4x4()
        t = thickness if isinstance(thickness, (tuple, list)) else (thickness, thickness)
        mat = Matrix.Translation((p1 + p2) * 0.5) @ rot @ Matrix.Diagonal(Vector((t[0], t[1], length, 1.0)))
        res = bmesh.ops.create_cube(self.bm, size=1.0, matrix=mat)
        return self._tag(res["verts"], slot)

    def cylinder(self, center, radius, depth, slot, segments=8, axis="Z"):
        """Cilindru cu capace (ngon)."""
        rot = {
            "Z": Matrix.Identity(4),
            "X": Matrix.Rotation(math.radians(90), 4, "Y"),
            "Y": Matrix.Rotation(math.radians(-90), 4, "X"),
        }[axis]
        mat = Matrix.Translation(Vector(center)) @ rot
        try:
            res = bmesh.ops.create_cone(
                self.bm, cap_ends=True, cap_tris=False, segments=segments,
                radius1=radius, radius2=radius, depth=depth, matrix=mat)
        except TypeError:  # Blender < 3.0 folosea diameter1/diameter2
            res = bmesh.ops.create_cone(
                self.bm, cap_ends=True, cap_tris=False, segments=segments,
                diameter1=radius, diameter2=radius, depth=depth, matrix=mat)
        return self._tag(res["verts"], slot)

    def frustum(self, center, r_bottom, r_top, depth, slot, segments=8, axis="Z"):
        """Trunchi de con, cu AMBELE capace. Stalpi conici, palnii, cosuri.

        Exista fiindca celelalte doua primitive nu acopera cazul: `cylinder` are
        raza constanta, iar `revolve` inchide doar baza — varful ii ramane
        deschis, deci un stalp care se subtiaza cerea un capac scris de mana.

        r_top=0 da un con cu varf ascutit. Un stalp care se subtiaza spre varf
        citeste mult mai bine decat un cilindru drept: silueta capata directie.

        Buget: 3*segments triunghiuri (segments quad-uri laterale + 2 capace),
        inainte de bevel. Cu segments=8: 24.
        """
        rot = {
            "Z": Matrix.Identity(4),
            "X": Matrix.Rotation(math.radians(90), 4, "Y"),
            "Y": Matrix.Rotation(math.radians(-90), 4, "X"),
        }[axis]
        mat = Matrix.Translation(Vector(center)) @ rot
        try:
            res = bmesh.ops.create_cone(
                self.bm, cap_ends=True, cap_tris=False, segments=segments,
                radius1=r_bottom, radius2=r_top, depth=depth, matrix=mat)
        except TypeError:  # Blender < 3.0 folosea diameter1/diameter2
            res = bmesh.ops.create_cone(
                self.bm, cap_ends=True, cap_tris=False, segments=segments,
                diameter1=r_bottom, diameter2=r_top, depth=depth, matrix=mat)
        return self._tag(res["verts"], slot)

    def pickets(self, p1, p2, count_or_step, size, slot, tilt_jitter=0.0,
                seed=0, endpoints=True):
        """Rand de sipci/montanti identici de-a lungul segmentului p1->p2.

        p1 si p2 sunt puncte de BAZA: fiecare sipca creste pe +Z cu size[2].
        count_or_step: int = cate bucati, float = pasul in metri.

        tilt_jitter (grade) le inclina in jurul directiei randului, DETERMINIST
        din `seed` — un rand perfect aliniat citeste ca plastic injectat, iar
        style_bible §4 cere uzura. Zero inseamna aliniat perfect (montanti de
        panou, unde stramb ar arata a greseala, nu a vechime).

        Gard, montanti, jaluzele, gratare, coaste de rigidizare pe spatele unui
        panou. Buget: 12 triunghiuri per sipca, inainte de bevel.
        """
        w, d, h = size
        pts = _span_points(p1, p2, count_or_step, endpoints)
        run = Vector(p2) - Vector(p1)
        axis = run.normalized() if run.length > 1e-6 else Vector((1.0, 0.0, 0.0))
        rand = _lcg(seed)
        faces = set()
        for p in pts:
            rot = None
            if tilt_jitter > 0.0:
                # inclinare in jurul directiei randului = sipci care cad in
                # lateral, exact cum imbatraneste un gard
                rot = Matrix.Rotation(math.radians((rand() * 2.0 - 1.0) * tilt_jitter), 3, axis)
            faces |= self.box(center=(p.x, p.y, p.z + h * 0.5),
                              size=(w, d, h), slot=slot, rotation=rot)
        return faces

    def railing(self, p1, p2, height, post_step, post_t, rail_t, slot, rails=2):
        """Balustrada: stalpi la pas regulat + lise orizontale intre ei.

        p1/p2 sunt punctele de BAZA ale capetelor; balustrada creste pe +Z.
        `rails` = cate lise: 1 doar sus, 2 sus+mijloc, 3 sus + doua treimi.

        style_bible §3 interzice "balustradele subtiri", si nu degeaba: la 60 km/h
        o lisa de 4 cm dispare, iar silueta capata zgomot in loc de detaliu. De
        aceea ajutorul asta impune o grosime minima — vezi MIN_T mai jos. Daca
        ai nevoie de o balustrada mai fina decat atat, ce vrei de fapt e sa n-o
        pui deloc.

        Buget: 12 triunghiuri per stalp + 12 per lisa, inainte de bevel. O
        pasarela de 6 m cu pas de 1.5 m si 2 lise: 5 stalpi + 2 lise = 84.
        """
        span = (Vector(p2) - Vector(p1)).length
        # Sub 6 cm nu mai e balustrada, e sarma. Pragul e relativ la deschidere:
        # o lisa de 8 cm pe 2 m citeste, aceeasi lisa pe 12 m nu.
        MIN_T = max(0.06, span * 0.012)
        post_t = max(post_t, MIN_T)
        rail_t = max(rail_t, MIN_T)

        faces = self.pickets(p1, p2, float(post_step), (post_t, post_t, height), slot)

        levels = {1: (1.0,), 2: (1.0, 0.55), 3: (1.0, 0.67, 0.34)}[rails]
        a, b = Vector(p1), Vector(p2)
        for frac in levels:
            z = height * frac - rail_t * 0.5
            faces |= self.beam(a + Vector((0, 0, z)), b + Vector((0, 0, z)),
                               rail_t, slot)
        return faces

    def ladder(self, base, top, width, rung_step, rail_t, rung_r, slot, side=None):
        """Scara: doua montante + trepte la pas regulat, intre doua puncte.

        Exista fiindca lipsa ei se vede in brief-uri: `water_tower.md:27-29` face
        scara OPTIONALA ("doar daca ramane chunky... Daca iese subtire, omite-o")
        tocmai fiindca geometria subtire scrisa de mana iesea urat. Ajutorul asta
        **impune** grosimile minime, deci raspunsul devine "da".

        `side` e directia laterala (perpendiculara pe scara). Daca lipseste, se
        deduce — pentru o scara verticala iese pe -X.

        Buget: 12 triunghiuri per montant + 12 per treapta. O scara de 5 m cu pas
        de 0.4 m: 2 + 13 piese = 180.
        """
        a, b = Vector(base), Vector(top)
        d = b - a
        if d.length < 1e-6:
            return set()
        if side is None:
            side = d.cross(Vector((0, 1, 0)))
            if side.length < 1e-6:
                side = d.cross(Vector((1, 0, 0)))
        side = Vector(side).normalized()

        # Pragurile care fac diferenta dintre "scara" si "zgarietura pe silueta".
        # Sunt relative la latimea scarii, nu absolute: o scara de 0.5 m si una
        # de 1.2 m nu au nevoie de aceeasi treapta.
        rail_t = max(rail_t, width * 0.14)
        rung_r = max(rung_r, width * 0.09)

        faces = set()
        for s in (-0.5, 0.5):
            off = side * (width * s)
            faces |= self.beam(a + off, b + off, rail_t, slot)

        # treptele stau INTRE montante, retrase cu jumatate de montant la fiecare
        # capat, ca sa nu iasa colturi din silueta
        inner = width * 0.5 - rail_t * 0.5
        for p in _span_points(a, b, float(rung_step), endpoints=False):
            faces |= self.beam(p - side * inner, p + side * inner, rung_r, slot)
        return faces

    def torus(self, center, major_r, minor_r, slot, major_seg=8, minor_seg=6,
              axis="Z"):
        """Inel inchis. Cercuri de rezervor, colier de teava, cauciucuri, jante.

        Nicio primitiva existenta nu producea un inel: `revolve` se invarte in
        jurul axei dar porneste de pe ea, deci da forme pline, nu gauri.

        Buget: 2 * major_seg * minor_seg triunghiuri. Cu 8x6: 96 — scump pentru
        cat de mic e de obicei in cadru, deci tine major_seg jos. Pentru cercurile
        de pe un rezervor, un `torus` de 8x4 (64) sau chiar o banda dreptunghiulara
        din `revolve` sunt alegeri mai bune decat 12x8 (192).
        """
        cx, cy, cz = center
        basis = {
            "Z": (Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))),
            "Y": (Vector((1, 0, 0)), Vector((0, 0, 1)), Vector((0, 1, 0))),
            "X": (Vector((0, 1, 0)), Vector((0, 0, 1)), Vector((1, 0, 0))),
        }[axis]
        e1, e2, up = basis

        rings = []
        for i in range(major_seg):
            a = 2.0 * math.pi * i / major_seg
            radial = e1 * math.cos(a) + e2 * math.sin(a)
            hub = Vector((cx, cy, cz)) + radial * major_r
            ring = []
            for k in range(minor_seg):
                t = 2.0 * math.pi * k / minor_seg
                p = hub + radial * (minor_r * math.cos(t)) + up * (minor_r * math.sin(t))
                ring.append(self.bm.verts.new(p))
            rings.append(ring)

        for i in range(major_seg):
            lo, hi = rings[i], rings[(i + 1) % major_seg]
            for k in range(minor_seg):
                j = (k + 1) % minor_seg
                self.bm.faces.new((lo[k], lo[j], hi[j], hi[k]))
        return self._tag([v for r in rings for v in r], slot)

    def corrugate(self, center, size, slot, ribs=5, depth=0.06):
        """Panou de tabla ondulata: nervuri verticale pe fata dinspre +Y.

        Cel mai bun raport detaliu/triunghi pentru o diorama de desert — soproane,
        rezervoare, baraci, garduri improvizate. Fara boolean si fara o bucla de
        nervuri scrisa de mana era imposibil.

        Se construieste ca UN SINGUR solid cu profil de unda dreptunghiulara, nu
        ca placa + sipci lipite deasupra: cutiile suprapuse ar lasa fete interne
        care nu se vad niciodata dar intra in numaratoare si strica AO-ul.

        size = (latime pe X, grosime pe Y, inaltime pe Z). Nervurile ies spre +Y.

        ATENTIE la pas: sub ~0.4 m intre nervuri devine detaliu de frecventa
        inalta si style_bible §3 il interzice — la viteza se transforma in moar,
        nu in tabla. Cu 5 nervuri pe 4 m iese un pas de 0.4 m: exact la limita.

        Buget: 4*ribs + 2 varfuri -> ~(6*ribs + 2) triunghiuri inainte de bevel.
        Cu ribs=5: 84.
        """
        w, t, h = size
        cx, cy, cz = center
        y_back = cy - t * 0.5
        y_front = cy + t * 0.5
        cells = 2 * ribs                      # alterneaza iesit / intrat
        step = w / cells

        # Profilul in plan (XY), parcurs pe fata dinspre +Y de la stanga la dreapta
        outline = []
        for c in range(cells):
            x0 = cx - w * 0.5 + step * c
            x1 = x0 + step
            y = y_front + (depth if c % 2 == 0 else 0.0)
            outline.append((x0, y))
            outline.append((x1, y))
        # ...si inapoi pe spatele plat
        outline.append((cx + w * 0.5, y_back))
        outline.append((cx - w * 0.5, y_back))

        bot, top = [], []
        for x, y in outline:
            bot.append(self.bm.verts.new((x, y, cz - h * 0.5)))
            top.append(self.bm.verts.new((x, y, cz + h * 0.5)))
        n = len(outline)
        self.bm.faces.new(tuple(top))
        self.bm.faces.new(tuple(reversed(bot)))
        for i in range(n):
            j = (i + 1) % n
            self.bm.faces.new((bot[i], bot[j], top[j], top[i]))
        return self._tag(bot + top, slot)

    def window(self, center, w, h, frame_t, depth, glass_slot, frame_slot,
               mullions=(0, 0), rotation=None):
        """Fereastra: cadru din patru grinzi + placa intunecata retrasa in gol.

        E diferenta dintre "cutie cu o pata" si "cladire". Azi benzinaria are trei
        placi lipite 2 cm peste perete (`build_gas_station.py:61-63`) fiindca
        n-avea alt mod: fara cadru, ochiul citeste o vopsea, nu o deschidere.

        Cadrul iese `depth/2` in fata (spre +Y), geamul sta retras `depth/2` in
        spate — retragerea e cea care produce umbra proprie, deci senzatia de gol.
        `mullions=(verticale, orizontale)` adauga montanti in interior.

        `rotation` roteste tot ansamblul in jurul lui `center`, pentru pereti
        care nu privesc spre +Y.

        Buget: 5 cutii = 60 de triunghiuri inainte de bevel, plus 12 per montant.
        """
        cx, cy, cz = center

        def place(local, size, slot):
            lx, ly, lz = local
            p = Vector((lx, ly, lz))
            if rotation is not None:
                rot = rotation.to_matrix() if hasattr(rotation, "to_matrix") else rotation
                p = rot @ p
            return self.box(center=(cx + p.x, cy + p.y, cz + p.z), size=size,
                            slot=slot, rotation=rotation)

        faces = set()
        # geamul: slotul cel mai inchis din lume citeste ca gol, nu ca sticla
        faces |= place((0.0, -depth * 0.5, 0.0),
                       (w - 2 * frame_t, frame_t * 0.6, h - 2 * frame_t), glass_slot)
        # cadru: sus, jos, stanga, dreapta
        faces |= place((0.0, depth * 0.5, (h - frame_t) * 0.5), (w, depth, frame_t), frame_slot)
        faces |= place((0.0, depth * 0.5, -(h - frame_t) * 0.5), (w, depth, frame_t), frame_slot)
        faces |= place((-(w - frame_t) * 0.5, depth * 0.5, 0.0), (frame_t, depth, h), frame_slot)
        faces |= place(((w - frame_t) * 0.5, depth * 0.5, 0.0), (frame_t, depth, h), frame_slot)

        mv, mh = mullions
        inner_w, inner_h = w - 2 * frame_t, h - 2 * frame_t
        for i in range(mv):
            x = -inner_w * 0.5 + inner_w * (i + 1) / (mv + 1)
            faces |= place((x, depth * 0.35, 0.0),
                           (frame_t * 0.8, depth * 0.6, inner_h), frame_slot)
        for i in range(mh):
            z = -inner_h * 0.5 + inner_h * (i + 1) / (mh + 1)
            faces |= place((0.0, depth * 0.35, z),
                           (inner_w, depth * 0.6, frame_t * 0.8), frame_slot)
        return faces

    def retag(self, faces, slot, where=None):
        """Re-eticheteaza slotul unui set de fete. Costa ZERO triunghiuri.

        `where` filtreaza:
          None                      toate fetele
          "up" / "down" / "side"    dupa normala
          callable(centru, normala) filtru propriu — inaltime, pozitie, orice
                                    (ex. `lambda c, n: n.y > 0.5` = doar fata)

        Mecanismul exista de la inceput (stratul `slot` e public si primitivele
        intorc `set[BMFace]`), dar singurul care il folosea era
        `rock(strata_slots=)`, inchis in primitiva si doar pentru stanci. Aici e
        general: o cutie construita cu un slot poate primi alta culoare doar pe
        fata, doar pe fetele de sus (style_bible §4: "fetele de sus decolorate
        +10% valoare"), sau pe un panou din cinci ca sa nu iasa suprafata
        uniforma. Variatie de valoare fara niciun triunghi in plus.

        Intoarce doar fetele efectiv re-etichetate, ca sa se poata inlantui.
        """
        faces = [f for f in faces if f.is_valid]
        if faces:
            # normalele bmesh sunt lene; fara asta filtrul dupa directie
            # citeste vectori nuli pe fetele proaspat create
            bmesh.ops.recalc_face_normals(self.bm, faces=faces)
        out = set()
        for f in faces:
            f.normal_update()
            n = f.normal
            if where is None:
                keep = True
            elif where == "up":
                keep = n.z > 0.5
            elif where == "down":
                keep = n.z < -0.5
            elif where == "side":
                keep = abs(n.z) <= 0.5
            else:
                keep = where(f.calc_center_median(), n)
            if keep:
                f[self.slot] = slot
                out.add(f)
        return out

    def revolve(self, profile, slot, segments=8, origin=(0, 0, 0), cap_bottom=True):
        """Suprafata de revolutie in jurul axei Z locale.

        profile: lista de (raza, z) de jos in sus. O raza 0 la varf produce un apex
        (varf rotunjit/dom, in functie de cum e desenat profilul)."""
        ox, oy, oz = origin
        rings = []
        apex = None
        for r, z in profile:
            if r <= 1e-6:
                apex = self.bm.verts.new((ox, oy, oz + z))
                break
            ring = []
            for i in range(segments):
                a = 2.0 * math.pi * i / segments
                ring.append(self.bm.verts.new((ox + r * math.cos(a), oy + r * math.sin(a), oz + z)))
            rings.append(ring)

        new_verts = [v for ring in rings for v in ring] + ([apex] if apex else [])
        for lo, hi in zip(rings, rings[1:]):
            for i in range(segments):
                j = (i + 1) % segments
                self.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
        if apex and rings:
            top = rings[-1]
            for i in range(segments):
                j = (i + 1) % segments
                self.bm.faces.new((top[i], top[j], apex))
        if cap_bottom and rings:
            self.bm.faces.new(tuple(reversed(rings[0])))
        return self._tag(new_verts, slot)

    def sweep(self, path, radius, slot, segments=6, dome_end=True, cap_start=True,
              dome_rings=2):
        """Tub poligonal de-a lungul unei polilinii; optional dom la capat.
        Folosit pentru bratele de cactus (cotul clasic de saguaro)."""
        pts = [Vector(p) for p in path]
        if len(pts) < 2:
            return set()

        tangents = []
        for i, p in enumerate(pts):
            if i == 0:
                t = (pts[1] - pts[0])
            elif i == len(pts) - 1:
                t = (pts[-1] - pts[-2])
            else:
                t = (pts[i + 1] - pts[i - 1])
            tangents.append(t.normalized())

        # transport paralel ca sa nu se rasuceasca inelele
        ref = Vector((0, 1, 0)) if abs(tangents[0].y) < 0.9 else Vector((1, 0, 0))
        x_axis = ref.cross(tangents[0]).normalized()
        rings, new_verts = [], []
        for i, (p, t) in enumerate(zip(pts, tangents)):
            if i > 0:
                x_axis = (x_axis - t * x_axis.dot(t))
                if x_axis.length < 1e-6:
                    x_axis = (Vector((0, 0, 1)).cross(t))
                x_axis.normalize()
            y_axis = t.cross(x_axis)
            ring = []
            for k in range(segments):
                a = 2.0 * math.pi * k / segments
                ring.append(self.bm.verts.new(p + x_axis * (radius * math.cos(a)) + y_axis * (radius * math.sin(a))))
            rings.append(ring)
            new_verts.extend(ring)

        for lo, hi in zip(rings, rings[1:]):
            for i in range(segments):
                j = (i + 1) % segments
                self.bm.faces.new((lo[i], lo[j], hi[j], hi[i]))

        if cap_start:
            self.bm.faces.new(tuple(reversed(rings[0])))

        if dome_end:
            t = tangents[-1]
            x_axis_d = x_axis
            y_axis_d = t.cross(x_axis_d)
            prev = rings[-1]
            base = pts[-1]
            angles = {1: (55.0,), 2: (40.0, 70.0), 3: (30.0, 55.0, 75.0)}[dome_rings]
            for ang in angles:
                rad = math.radians(ang)
                r = radius * math.cos(rad)
                c = base + t * (radius * math.sin(rad))
                ring = []
                for k in range(segments):
                    a = 2.0 * math.pi * k / segments
                    ring.append(self.bm.verts.new(c + x_axis_d * (r * math.cos(a)) + y_axis_d * (r * math.sin(a))))
                new_verts.extend(ring)
                for i in range(segments):
                    j = (i + 1) % segments
                    self.bm.faces.new((prev[i], prev[j], ring[j], ring[i]))
                prev = ring
            tip = self.bm.verts.new(base + t * radius)
            new_verts.append(tip)
            for i in range(segments):
                j = (i + 1) % segments
                self.bm.faces.new((prev[i], prev[j], tip))
        else:
            self.bm.faces.new(tuple(rings[-1]))

        return self._tag(new_verts, slot)

    def rock(self, center, size, slot, seed=0, segments=7, rings=4,
             flat_top=False, squash=1.0, taper=0.35, wall_axis=None,
             strata_slots=None):
        """Bolovan: elipsoid din inele orizontale, cu raza perturbata determinist.

        Baza intregii familii de stanci (bolovani, faleze, butte). Perturbatia e
        pseudo-aleatoare DAR reproductibila din `seed` — acelasi seed da mereu
        aceeasi silueta, deci build-urile nu se schimba intre rulari.

        style_bible §3 cere stanci rotunjite (70%) sau fatetate (30%), NICIODATA
        zimtate, cu straturi orizontale la 0.4-0.8 m. De aici alegerile:
          - `segments` mic (7) -> fatete late, nu detaliu de frecventa inalta
          - perturbatia variaza mai mult PE INEL decat intre inele vecine, ca sa
            iasa straturi orizontale in loc de zgomot izotrop
          - `flat_top` taie varful: silueta de mesa, semnatura peisajului de canion

        size: (lungime_x, latime_y, inaltime_z).
        taper: cat se ingusteaza spre varf. 0 = pereti verticali (faleza),
               1 = varf ascutit (bolovan). Un elipsoid pur (taper mare) da o
               MOVILA, nu un perete — pentru faleze trebuie 0.10-0.20.
        wall_axis: 'y' inseamna "fata dinspre -Y ramane VERTICALA, doar spatele
               cade in trepte". Asa iese perete de canion vazut din masina, si
               tot economisesti triunghiuri pe partea nevazuta.
        squash < 1 turteste inelele de sus.
        strata_slots: lista de sloturi ciclata PE INEL, in loc de un slot unic.
               Cu (ROCK_LIGHT, ROCK_DARK, ROCK_LIGHT, SAND_SHADOW) iese roca
               sedimentara reala: benzi orizontale de valoare diferita, blocate
               de geometrie, la scara de ~2 m. E variatia de bloc pe care
               stratul de detaliu (fin, ~0.7 m) n-o poate da.

               Costa ZERO triunghiuri si ZERO materiale — sunt aceleasi sloturi
               din acelasi atlas, doar repartizate altfel. Bevel-ul de la granita
               dintre inele se lipeste de o parte, deci apare o treapta neta la
               fiecare strat: exact aspectul din imaginile de referinta.
        """
        sx, sy, sz = size
        cx, cy, cz = center
        rings_v = []
        # Un LCG mic: nu vrem random-ul global al Python, care ar face build-ul
        # dependent de ordinea apelurilor.
        state = (seed * 1103515245 + 12345) & 0x7FFFFFFF

        def rand():
            nonlocal state
            state = (state * 1103515245 + 12345) & 0x7FFFFFFF
            return state / 0x7FFFFFFF

        # o deviatie per inel (stratul) si una per coloana (verticala), combinate:
        # asa fetele raman continue pe verticala, ca la roca sedimentara
        col_dev = [0.88 + rand() * 0.24 for _ in range(segments)]
        top_frac = 0.82 if flat_top else 1.0

        for k in range(rings + 1):
            t = k / rings
            z = cz + (t * top_frac) * sz
            # Profilul: 1.0 la baza -> (1 - taper) la varf. Cu taper mic raman
            # pereti aproape verticali; cu taper mare iese bolovan.
            radius_scale = 1.0 - taper * (t ** 1.35)
            if flat_top and t > 0.9:
                radius_scale = max(radius_scale, 1.0 - taper * 0.85)
            ring_dev = 0.94 + rand() * 0.12
            vert_squash = 1.0 - t * (1.0 - squash)
            ring = []
            for i in range(segments):
                a = 2.0 * math.pi * i / segments
                ca, sa = math.cos(a), math.sin(a)
                r = radius_scale * ring_dev * col_dev[i] * vert_squash
                # Peretele de faleza: jumatatea dinspre -Y nu se retrage cu
                # inaltimea. Fara asta silueta se ingusteaza in toate directiile
                # si obtii o movila conica in loc de perete.
                if wall_axis == "y" and sa < 0.0:
                    r = ring_dev * col_dev[i]
                ring.append(self.bm.verts.new(
                    (cx + ca * r * sx * 0.5,
                     cy + sa * r * sy * 0.5,
                     z)))
            rings_v.append(ring)

        new_verts = [v for ring in rings_v for v in ring]
        band_faces = []
        for k, (lo, hi) in enumerate(zip(rings_v, rings_v[1:])):
            for i in range(segments):
                j = (i + 1) % segments
                band_faces.append((k, self.bm.faces.new(
                    (lo[i], lo[j], hi[j], hi[i]))))
        base_face = self.bm.faces.new(tuple(reversed(rings_v[0])))
        top_face = self.bm.faces.new(tuple(rings_v[-1]))

        if not strata_slots:
            return self._tag(new_verts, slot)

        # Strate: fiecare banda de inel ia alt slot, ciclic. Baza primeste cel
        # mai inchis slot din lista (sta in umbra oricum), varful pe cel dat —
        # la mesa, capacul plat e fata cea mai insorita.
        for k, f in band_faces:
            f[self.slot] = strata_slots[k % len(strata_slots)]
        base_face[self.slot] = strata_slots[0]
        top_face[self.slot] = slot
        out = set(f for _, f in band_faces)
        out.add(base_face)
        out.add(top_face)
        return out

    def prism(self, outline, thickness, slot, center=(0, 0, 0)):
        """Prisma dintr-un contur 2D in planul XZ, extrudata pe Y.

        Fata "din fata" (spre +Y in Blender) devine -Z in Godot — vezi nota de
        axe din capul fisierului. Folosita pentru placi: scut de semn, panouri."""
        cx, cy, cz = center
        half = thickness * 0.5
        front, back = [], []
        for x, z in outline:
            back.append(self.bm.verts.new((cx + x, cy - half, cz + z)))
            front.append(self.bm.verts.new((cx + x, cy + half, cz + z)))
        n = len(outline)
        self.bm.faces.new(tuple(front))
        self.bm.faces.new(tuple(reversed(back)))
        for i in range(n):
            j = (i + 1) % n
            self.bm.faces.new((back[i], back[j], front[j], front[i]))
        return self._tag(front + back, slot)

    def to_object(self, name):
        """Scrie bmesh-ul intr-un obiect nou, pastrand slotul ca atribut de fata."""
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces[:])
        me = bpy.data.meshes.new(name)
        self.bm.to_mesh(me)
        self.bm.free()
        obj = bpy.data.objects.new(name, me)
        bpy.context.collection.objects.link(obj)
        return obj


# --- Post-procesare: bevel, UV, AO, origine ----------------------------------

def snapshot_slots(obj):
    """Retine geometria + slotul fiecarei fete INAINTE de bevel, ca sa putem
    reatribui UV-urile dupa. Fetele nou create de bevel iau slotul celei mai
    apropiate fete originale -> banda de bevel primeste una din culorile vecine,
    curat, fara interpolare intre sloturi (care ar amesteca culori din atlas)."""
    me = obj.data
    me.calc_loop_triangles()  # BVHTree nu accepta ngon-uri (capace de cilindru/revolutie)
    attr = me.attributes.get("slot")
    verts = [v.co.copy() for v in me.vertices]
    tris, slots = [], []
    for lt in me.loop_triangles:
        tris.append(tuple(lt.vertices))
        slots.append(int(attr.data[lt.polygon_index].value) if attr else 0)
    return {"bvh": BVHTree.FromPolygons(verts, tris, all_triangles=True), "slots": slots}


def apply_bevel(obj, width, segments=1, angle_deg=30.0):
    if width <= 0:
        return
    mod = obj.modifiers.new("Bevel", "BEVEL")
    mod.width = width
    mod.segments = segments
    mod.limit_method = "ANGLE"
    mod.angle_limit = math.radians(angle_deg)
    # numele s-a schimbat intre versiuni (clamp_overlap -> use_clamp_overlap in 5.x)
    for attr in ("use_clamp_overlap", "clamp_overlap"):
        if hasattr(mod, attr):
            setattr(mod, attr, True)
            break
    mod.miter_outer = "MITER_ARC"
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=mod.name)


def assign_uvs(obj, snap):
    """Colapseaza UV-urile fiecarei fete pe centrul slotului ei."""
    me = obj.data
    uv = me.uv_layers.get("UVMap") or me.uv_layers.new(name="UVMap")
    bvh, slots = snap["bvh"], snap["slots"]
    for poly in me.polygons:
        loc, nor, idx, dist = bvh.find_nearest(poly.center)
        slot = slots[idx] if idx is not None and idx < len(slots) else 0
        u = slot_u(slot)
        for li in poly.loop_indices:
            uv.data[li].uv = (u, 0.5)


def _hemisphere_dirs(n):
    """Directii distribuite uniform in emisfera (spirala Fibonacci) — determinist,
    deci build-uri reproductibile."""
    ga = math.pi * (3.0 - math.sqrt(5.0))
    out = []
    for i in range(n):
        z = (i + 0.5) / n
        r = math.sqrt(max(0.0, 1.0 - z * z))
        a = ga * i
        out.append(Vector((r * math.cos(a), r * math.sin(a), z)))
    return out


def bake_ao(obj, samples=32, dist=2.5, gradient="vertical",
            low=0.55, high=1.0, power=1.0, floor=0.30, strength=1.0,
            radial_axis="Z"):
    """AO real prin raycast in emisfera + gradient, scris in vertex colors.

    gradient='vertical' -> jos mai inchis (cladiri, turnuri, cactusi)
    gradient='radial'   -> centru mai inchis (roata morii: trebuie sa arate bine
                           in ORICE rotatie, deci fara gradient directional)
    gradient='none'     -> doar ocluzia geometrica
    """
    me = obj.data
    me.calc_loop_triangles()
    bvh = BVHTree.FromPolygons([v.co.copy() for v in me.vertices],
                               [tuple(lt.vertices) for lt in me.loop_triangles],
                               all_triangles=True)
    dirs = _hemisphere_dirs(samples)

    zs = [v.co.z for v in me.vertices]
    z_lo, z_hi = min(zs), max(zs)
    span = max(z_hi - z_lo, 1e-6)
    # roata morii e construita in planul XZ, deci raza ei se masoara fata de axa Y
    if radial_axis == "Y":
        radii = [math.hypot(v.co.x, v.co.z) for v in me.vertices]
    else:
        radii = [math.hypot(v.co.x, v.co.y) for v in me.vertices]
    r_max = max(max(radii), 1e-6)

    values = []
    for i, v in enumerate(me.vertices):
        n = v.normal.normalized()
        ref = Vector((0, 0, 1)) if abs(n.z) < 0.9 else Vector((1, 0, 0))
        tx = ref.cross(n).normalized()
        ty = n.cross(tx)
        basis = Matrix((tx, ty, n)).transposed()
        origin = v.co + n * 0.003

        occ = 0.0
        for d in dirs:
            hit = bvh.ray_cast(origin, basis @ d, dist)
            if hit[0] is not None:
                occ += 1.0 - min(hit[3] / dist, 1.0)  # atenuare cu distanta
        ao = 1.0 - (occ / len(dirs)) * strength

        if gradient == "vertical":
            t = (v.co.z - z_lo) / span
            g = low + (high - low) * (t ** power)
        elif gradient == "radial":
            t = radii[i] / r_max
            g = low + (high - low) * (t ** power)
        else:
            g = 1.0

        values.append(max(floor, min(1.0, ao * g)))

    for ca in list(me.color_attributes):
        me.color_attributes.remove(ca)
    ca = me.color_attributes.new(name="AO", type="FLOAT_COLOR", domain="POINT")
    for i, val in enumerate(values):
        ca.data[i].color = (val, val, val, 1.0)
    me.color_attributes.active_color_index = 0
    me.color_attributes.render_color_index = 0
    return min(values), max(values)


def set_origin_base(obj, center_xy=True, to_z=0.0):
    """Muta geometria astfel incat originea sa fie la baza, centrata in XY.
    Godot: global_position aseaza propul direct pe sol."""
    me = obj.data
    xs = [v.co.x for v in me.vertices]
    ys = [v.co.y for v in me.vertices]
    zs = [v.co.z for v in me.vertices]
    dx = -(min(xs) + max(xs)) * 0.5 if center_xy else 0.0
    dy = -(min(ys) + max(ys)) * 0.5 if center_xy else 0.0
    dz = to_z - min(zs)
    for v in me.vertices:
        v.co.x += dx
        v.co.y += dy
        v.co.z += dz
    return Vector((dx, dy, dz))


def set_origin_at(obj, point):
    """Muta geometria ca originea obiectului sa cada exact in `point`
    (folosit pentru pivotul rotii morii, in centrul butucului)."""
    p = Vector(point)
    for v in obj.data.vertices:
        v.co -= p
    obj.location = obj.location + p
    return p


def tri_count(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


# --- Material de preview + export --------------------------------------------

def atlas_material():
    """Material unic de preview care arata spre acelasi atlas ca in joc.
    In Godot materialul e inlocuit oricum de Palette.apply_world_material();
    aici exista ca sa garanteze exportul UV-urilor si ca sa putem verifica
    vizual culorile in viewport."""
    mat = bpy.data.materials.get("PaletteAtlas")
    if mat:
        return mat
    mat = bpy.data.materials.new("PaletteAtlas")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.9
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.1

    img = bpy.data.images.get("palette_atlas.png")
    if img is None and os.path.exists(ATLAS):
        img = bpy.data.images.load(ATLAS)
    if img:
        img.colorspace_settings.name = "sRGB"
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = img
        tex.interpolation = "Closest"  # fara amestec intre sloturi vecine
        tex.location = (-600, 200)
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])

    col = nt.nodes.new("ShaderNodeVertexColor")
    col.layer_name = "AO"
    col.location = (-600, -150)
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    mix.blend_type = "MULTIPLY"
    mix.inputs["Factor"].default_value = 1.0
    mix.location = (-300, 100)
    if img:
        nt.links.new(tex.outputs["Color"], mix.inputs[6])
    nt.links.new(col.outputs["Color"], mix.inputs[7])
    nt.links.new(mix.outputs[2], bsdf.inputs["Base Color"])
    return mat


def finish(obj, bevel=0.04, bevel_angle=30.0, ao=None, origin="base",
           bevel_segments=1):
    """Lantul standard: bevel -> UV pe sloturi -> origine -> AO copt.

    origin="base"      centreaza si XY pe bounding box
    origin="base_axis" coboara doar pe Z, pastrand XY asa cum a fost construit
                       (cand piesa e asimetrica: un semn al carui scut iese in
                       fata, dar a carui origine trebuie sa stea pe axa stalpului)
    bevel_segments     `apply_bevel` il accepta de la inceput, dar `finish` il
                       fixa la 1 si nu-l expunea. 2 segmente inseamna un colt
                       vizibil rotund in loc de tesit — merita doar pe piese care
                       stau langa camera, fiindca dubleaza banda de bevel.
    Ordinea conteaza: originea se muta INAINTE de bake, ca gradientul vertical
    de AO sa se calculeze de la baza reala (z=0).
    """
    snap = snapshot_slots(obj)
    apply_bevel(obj, bevel, segments=bevel_segments, angle_deg=bevel_angle)
    assign_uvs(obj, snap)
    if origin == "base":
        set_origin_base(obj, center_xy=True)
    elif origin == "base_axis":
        set_origin_base(obj, center_xy=False)
    obj.data.materials.clear()
    obj.data.materials.append(atlas_material())
    rng = bake_ao(obj, **(ao or {}))
    if "slot" in obj.data.attributes:  # atributul de lucru nu are ce cauta in GLB
        obj.data.attributes.remove(obj.data.attributes["slot"])
    return {"tris": tri_count(obj), "ao_min": round(rng[0], 3), "ao_max": round(rng[1], 3)}


def export_glb(objects, filename):
    """Export GLB cu UV + vertex colors, Y-up, modificatori aplicati."""
    os.makedirs(MODELS, exist_ok=True)
    path = os.path.join(MODELS, filename)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_normals=True,
        export_texcoords=True,
        export_vertex_color="ACTIVE",
        export_materials="EXPORT",
        # Materialul se pastreaza (altfel exportatorul arunca UV-urile), dar imaginea
        # NU se incorporeaza: Godot ar extrage-o intr-un PNG separat langa fiecare GLB
        # si am ajunge cu 4 copii ale aceluiasi atlas in build. Culoarea vine oricum
        # din Palette.apply_world_material, la instantiere.
        export_image_format="NONE",
        export_cameras=False,
        export_lights=False,
        export_extras=False,
    )
    return path, os.path.getsize(path)


def save_blend(objects, filename):
    """Scrie sursa .blend FARA sa schimbe fisierul deschis in sesiunea curenta."""
    os.makedirs(BLENDS, exist_ok=True)
    path = os.path.join(BLENDS, filename)
    bpy.data.libraries.write(path, set(objects), fake_user=True)
    return path, os.path.getsize(path)


def clear_built(prefix=None):
    """Sterge obiectele construite de scripturi (nu atinge restul scenei).

    Sterge si mesh-urile ramase orfane: altfel numele se acumuleaza intre rulari
    (Cactus_A -> Cactus_A.001 -> ...), iar nodurile din GLB trebuie sa aiba nume
    stabile (Godot cauta nodul "Blades" al morii dupa nume)."""
    for o in list(bpy.data.objects):
        if o.type == "MESH" and (prefix is None or o.name.startswith(prefix)):
            bpy.data.objects.remove(o, do_unlink=True)
    for me in list(bpy.data.meshes):
        if me.users == 0 and (prefix is None or me.name.startswith(prefix)):
            bpy.data.meshes.remove(me)


print("dio_lib incarcat | atlas:", os.path.exists(ATLAS), "| models:", MODELS)
