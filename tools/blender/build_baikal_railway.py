"""Baikal — calea ferata Circum-Baikal (planşa "Baikal kit", pozitiile 3 si 4).

  RailwayViaduct  baikal/structures/railway_viaduct.glb
                  Viaduct_Pier / Viaduct_Arch / Viaduct_End
  TunnelPortal    baikal/structures/railway_tunnel_portal.glb
                  Tunnel_Portal / Tunnel_Bore / Tunnel_Niche

Viaductul e MODULAR, nu o piesa de 60 m: pista are 5 arcade in brief, dar
lungimea reala se masoara abia dupa ce traseul e desenat. Trei module (pila,
arcada de 12 m, capat) se repeta cat trebuie — asa un viaduct mai lung nu cere
un asset nou, doar inca o instanta.

Contract cu pista (POI F, fractiile 0.74-0.84): drumul trece PE terasament,
intre sine, deci fata de sus a modulelor e CARIABILA — la cota 0 a piesei sta
patul de pietris, sinele ies deasupra si servesc de kerb. Sub arcada e gol
(masina trece pe gheata pe dedesubt la 0.66-0.72).

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_baikal_railway.py
"""

import math
from mathutils import Matrix, Vector

AO_STONE = dict(samples=28, dist=6.0, gradient="vertical",
                low=0.40, high=1.00, power=0.95, floor=0.10)
AO_TUNNEL = dict(samples=32, dist=8.0, gradient="vertical",
                 low=0.22, high=1.00, power=1.0, floor=0.05)

# Cotele din brief. Deschiderea arcadei si inaltimea pilei sunt cuplate: patul
# de cale ferata trebuie sa iasa la aceeasi cota pe toate modulele, altfel
# sinele fac trepte la imbinari.
ARCH_SPAN = 12.0        # deschidere libera
DECK_Z = 12.0           # cota patului (fata de baza pilei)
DECK_W = 6.5            # latimea tablierului = latimea drumului din brief
PIER_W = 3.2            # grosimea pilei pe directia de mers

RAIL_GAUGE = 1.52       # ecartament rusesc 1520 mm — sinele sunt kerb-ul
BALLAST_H = 0.55


def _deck(b, y_center, length, top_z=DECK_Z):
    """Patul de cale ferata: pietris + traverse + sine, pe o lungime data.

    Comun celor trei module, ca sa iasa cota IDENTICA la imbinari — daca fiecare
    modul si-ar calcula patul separat, o diferenta de un centimetru s-ar citi ca
    o treapta sub roti la 100 km/h.
    """
    # patul de pietris, usor mai lat decat tablierul
    b.box((0.0, y_center, top_z + BALLAST_H * 0.5),
          (DECK_W + 0.5, length, BALLAST_H), ASPHALT_EDGE)
    # traverse: pas de 0.65 m, lemn inchis
    z_sleep = top_z + BALLAST_H + 0.06
    for pt in _span_points((0.0, y_center - length * 0.5, z_sleep),
                           (0.0, y_center + length * 0.5, z_sleep),
                           0.65, endpoints=False):
        b.box((pt.x, pt.y, pt.z), (2.7, 0.24, 0.14), LOG_DARK)
    # sinele: doua profile continue. Ele SUNT kerb-ul pistei, deci ies 12 cm
    # peste traverse — destul cat sa se simta la contact, nu cat sa opreasca.
    for sx in (-RAIL_GAUGE * 0.5, RAIL_GAUGE * 0.5):
        b.box((sx, y_center, z_sleep + 0.13), (0.12, length, 0.12), RUST)
    # parapet NU: brief-ul cere explicit viaduct fara parapet (cazi 12 m).


def _stone_face(b, center, size, seed, slot=CONCRETE):
    """Bloc de piatra cioplita cu fata neregulata — asize randuri de blocuri.

    Un paralelipiped curat citeste ca beton turnat; viaductul Circum-Baikal e
    din piatra cioplita, iar diferenta se vede in randurile orizontale.
    """
    cx, cy, cz = center
    sx, sy, sz = size
    rows = max(int(sz / 0.9), 1)
    rand = _lcg(seed)
    h = sz / rows
    for i in range(rows):
        z = cz - sz * 0.5 + h * (i + 0.5)
        # fiecare rand iese/intra cu cativa centimetri
        d = (rand() - 0.5) * 0.10
        # Un rand din sase primeste tonul mai inchis. Prima versiune arunca
        # zarul la 22% si iesea zebra alb-negru: la piatra cioplita reala
        # variatia intre blocuri e mica, ce se citeste de departe e ROSTUL
        # dintre randuri (umbra din bevel), nu culoarea. Cu 1/6 raman pete
        # rare, care rup uniformitatea fara sa deseneze dungi.
        b.box((cx, cy, z), (sx + d, sy + d, h * 0.97),
              ASPHALT_EDGE if (i % 6 == 3 and rand() > 0.45) else slot)


# ============================================================ Viaduct: pila
def build_pier():
    b = Builder()
    # Pila se ingusteaza spre varf (batalie clasica de zidarie): 4.2 m la baza,
    # 3.2 m sus. Fara conicitate arata ca un stalp de beton.
    steps = 5
    for i in range(steps):
        t = i / (steps - 1.0)
        w = 4.2 - 1.0 * t
        z = DECK_Z * (i + 0.5) / steps
        _stone_face(b, (0.0, 0.0, z), (w, PIER_W + 0.6 - 0.4 * t,
                                       DECK_Z / steps), seed=71 + i * 17)
    # soclu evazat, in apa/gheata
    _stone_face(b, (0.0, 0.0, -0.6), (5.0, PIER_W + 1.2, 1.2), seed=903)
    _deck(b, 0.0, PIER_W + 0.6)
    obj = b.to_object("Viaduct_Pier")
    finish(obj, bevel=0.05, ao=AO_STONE, origin="base")
    return obj


# ============================================================ Viaduct: arcada
def build_arch():
    """Un modul de arcada de 12 m: bolta + timpanele + patul deasupra.

    Bolta e construita din voussoir-uri (blocuri radiale) cu `revolve`? Nu —
    revolve ar da un tor. Aici bolta e un sir de blocuri asezate pe un arc de
    cerc, fiecare rotit pe tangenta: asta e si constructia reala, si singura
    care lasa muchii curate la intrados.
    """
    b = Builder()
    r = ARCH_SPAN * 0.5                 # arc semicircular
    spring_z = DECK_Z - r - 1.4         # cota de nastere a boltii
    n = 13                              # blocuri pe bolta (impar: cheia la mijloc)
    ring_t = 0.9                        # grosimea inelului de bolta

    # AXELE: patul de cale ferata merge pe Y (vezi _deck), deci bolta se
    # intinde tot pe Y — intre doua pile aflate la ±6 m PE DIRECTIA DE MERS —
    # iar grosimea ei (latimea tablierului) e pe X. Prima versiune a construit
    # bolta in planul XZ, cu grosimea PIER_W pe Y: un arc de 12 m de-a
    # CURMEZISUL drumului, gros de 3 m, si nimic sub restul patului de 12 m.
    # Vazut din lateral, viaductul n-avea arcade; masurat pe GLB: bolta x ±8.8,
    # y ±1.6, patul x ±3.5, y ±6. Acum bolta e in planul YZ si lata cat patul.
    for i in range(n):
        a = math.pi * (i + 0.5) / n     # 0..pi, de la spate spre fata
        cy = -math.cos(a) * (r + ring_t * 0.5)
        cz = spring_z + math.sin(a) * (r + ring_t * 0.5)
        # Fiecare voussoir se roteste cu UNGHIUL POLAR, nu cu complementul lui:
        # `Matrix.Rotation(a, 3, "Y")` duce axa lunga a blocului (Z local) in
        # (sin a, cos a), care e TANGENTA la arc — deci blocul sta pe arc, cu
        # rosturile pe raza, ca in zidaria reala. Cu `-a + pi/2` (prima
        # versiune) axa iesea RADIALA: blocurile stateau cu capul spre centru
        # si bolta se citea ca un morman. Se verifica numeric — produsul scalar
        # dintre axa lunga si raza trebuie sa fie 0.
        # Rotatie in jurul lui X cu -a: duce axa lunga (Z local) in
        # (0, sin a, cos a), tangenta la arcul din planul YZ — produsul scalar
        # cu raza (-cos a, sin a) e zero, ca inainte in planul XZ.
        rot = Matrix.Rotation(-a, 3, "X")
        b.box((0.0, cy, cz), (DECK_W + 0.5, ring_t * 1.05, (math.pi * r / n) * 1.12),
              CONCRETE, rotation=rot)

    # timpanele: zidaria dintre extradosul boltii si pat, pe ambele fete.
    # Se construieste in coloane verticale care se opresc la conturul boltii —
    # asa apare decupajul de arc, fara operatii booleene.
    # Coloana incepe DEASUPRA extradosului, si numai daca mai are loc pana la
    # pat. Prima versiune calcula `inner` cu `max(..., spring_z)`, deci
    # coloanele din dreptul golului coborau pana la nasterea boltii si umpleau
    # arcada — de aici jumatatea de sus haotica din prima randare de control.
    # Aici, sub extrados nu se pune NIMIC: golul e gol prin constructie.
    r_out = r + ring_t
    for col in _span_points((0, -r - 2.4, 0), (0, r + 2.4, 0), 0.8):
        y = col.y
        if abs(y) < r_out:
            base_z = spring_z + math.sqrt(max(r_out * r_out - y * y, 0.0))
        else:
            base_z = spring_z - 1.0     # in afara deschiderii, zidarie plina
        top_z = DECK_Z
        if top_z - base_z < 0.35:
            continue                    # deasupra cheii nu mai incape nimic
        _stone_face(b, (0.0, y, (base_z + top_z) * 0.5),
                    (DECK_W + 0.5, 0.82, top_z - base_z), seed=int(abs(y) * 31) + 5)

    # sub nasterea boltii, plinul dintre pile
    for sy in (-r - 1.55, r + 1.55):
        _stone_face(b, (0.0, sy, spring_z * 0.5), (DECK_W + 0.5, 2.1, spring_z),
                    seed=int(abs(sy) * 13) + 400)

    # turturi sub arcada (brief): 6 tepi de gheata la intrados
    rand = _lcg(2211)
    for i in range(6):
        a = math.pi * (0.18 + 0.64 * (i / 5.0))
        iy = -math.cos(a) * r * 0.96
        iz = spring_z + math.sin(a) * r * 0.96
        _icicle(b, ((rand() - 0.5) * DECK_W * 0.7, iy, iz),
                length=0.7 + rand() * 1.5, radius=0.09 + rand() * 0.06)

    _deck(b, 0.0, ARCH_SPAN)
    obj = b.to_object("Viaduct_Arch")
    finish(obj, bevel=0.04, ao=AO_STONE, origin="base")
    return obj


def _icicle(b, tip_anchor, length, radius, slot=ICE_TURQUOISE, segments=6):
    """Un turture: con ingust care ATARNA din punctul dat in jos."""
    b.frustum((tip_anchor[0], tip_anchor[1], tip_anchor[2] - length * 0.5),
              radius, radius * 0.12, length, slot, segments=segments)


# ============================================================ Viaduct: capat
def build_end():
    """Piesa de capat: aripa de racordare cu terasamentul de pamant."""
    b = Builder()
    length = 6.0
    # zid de sprijin care coboara in panta spre teren
    steps = 4
    for i in range(steps):
        t = i / (steps - 1.0)
        z_top = DECK_Z * (1.0 - 0.22 * t)
        y = -length * 0.5 + length * (i + 0.5) / steps
        _stone_face(b, (0.0, y, z_top * 0.5), (DECK_W + 1.0 - 0.8 * t,
                                               length / steps, z_top),
                    seed=610 + i * 23)
    # aripile laterale, evazate
    for sx in (-1, 1):
        b.box((sx * (DECK_W * 0.5 + 0.55), -length * 0.32, DECK_Z * 0.42),
              (1.1, length * 0.5, DECK_Z * 0.84), CONCRETE,
              rotation=Matrix.Rotation(math.radians(sx * -7.0), 3, "Y"))
    _deck(b, 0.0, length)
    obj = b.to_object("Viaduct_End")
    finish(obj, bevel=0.05, ao=AO_STONE, origin="base")
    return obj


# ============================================================ Sina libera
def build_rail_track():
    """Patul de cale ferata SINGUR: pietris + traverse + sine, 12 m, pe sol.

    Piesa exista ca sina sa poata continua DINCOLO de viaduct si de tunel —
    pe terasament, spre sat — fara sa cari un modul de zidarie intreg. Acelasi
    _deck() ca pe module (cota patului identica la imbinare), doar ca la
    top_z=0: originea la baza pietrisului, gata de pus pe drum.

    12 m ca arcada: aceleasi pozitii de instantiere, cap la cap. In Godot
    sina merge pe -Z local (Blender +Y), conventia "face along" a proiectului.
    """
    clear_built()
    b = Builder()
    _deck(b, 0.0, ARCH_SPAN, top_z=0.0)
    obj = b.to_object("RailTrack")
    finish(obj, bevel=0.03, ao=AO_STONE, origin="base_axis")
    print("RailTrack: %d tris" % tri_count(obj))
    export_glb([obj], "baikal/structures/rail_track.glb")
    save_blend([obj], "baikal_rail_track.blend")
    return obj


def build_viaduct():
    clear_built()
    pier, arch, end = build_pier(), build_arch(), build_end()
    # asezate distantat pe X, ca planşa de referinta: modulele se instantiaza
    # separat in Godot, deci nu trebuie sa se atinga in GLB.
    pier.location.x = -14.0
    end.location.x = 16.0
    objs = [pier, arch, end]
    print("RailwayViaduct: %d tris (%s)"
          % (sum(tri_count(o) for o in objs),
             ", ".join("%s %d" % (o.name, tri_count(o)) for o in objs)))
    export_glb(objs, "baikal/structures/railway_viaduct.glb")
    save_blend(objs, "baikal_railway_viaduct.blend")
    return objs


# ============================================================ Tunelul
# Portal 7x7 m, galerie 40 m cu nise laterale la fiecare 12 m. Nisele sunt
# REFUGIUL din mecanica trenului-pe-sens, deci nu sunt ornament: trebuie sa
# incapa o masina (2.2 m latime la noi), deci 2.8 m adancime libera.

TUNNEL_W = 7.0
TUNNEL_H = 7.0
TUNNEL_LEN = 40.0
NICHE_STEP = 12.0
NICHE_DEPTH = 2.8


def _bore_shell(b, length, slot=CONCRETE, niches=()):
    """Galeria: DOAR suprafata interioara (pereti + intrados), nu un tub plin.

    Prima versiune construia inele complete de zidarie de 1.2 m grosime, la
    fiecare metru pe 40 m: 20.020 de triunghiuri pentru un obiect din care se
    vede exclusiv fata dinauntru. Randarea de control a aratat de ce e gresit
    conceptual, nu doar scump — iesea un BUTOI asezat pe camp, cu exteriorul la
    vedere, cand un tunel e sapat IN faleza: exteriorul nu exista.

    Aici peretii sunt placi subtiri (0.35 m) care privesc spre interior, iar
    intradosul e un singur inel de placi pe toata lungimea. Faleza din jur o
    pune pista (`cliff_face_olkhon`), nu asset-ul.

    `niches` = lista de (y, semn) pentru refugiile laterale — mecanica trenului
    pe sens, deci golul lor trebuie sa fie REAL, nu sugerat: peretele se
    intrerupe pe portiunea nisei si se inchide in spatele ei.
    """
    half = TUNNEL_W * 0.5
    spring = TUNNEL_H - half
    t = 0.35                        # grosimea placii de captuseala

    # --- peretii laterali, cu goluri in dreptul niselor --------------------
    for sx in (-1, 1):
        cuts = sorted((ny, ) for ny, side in niches if side == sx)
        y0 = 0.0
        spans = []
        for (ny, ) in cuts:
            spans.append((y0, ny - 1.5))
            y0 = ny + 1.5
        spans.append((y0, length))
        for a, bb in spans:
            if bb - a < 0.05:
                continue
            b.box((sx * (half + t * 0.5), (a + bb) * 0.5, spring * 0.5),
                  (t, bb - a, spring), slot)

    # --- nisele: gol lateral de NICHE_DEPTH, inchis in spate ---------------
    for ny, side in niches:
        b.box((side * (half + NICHE_DEPTH + t * 0.5), ny, spring * 0.5),
              (t, 3.0, spring), slot)                       # fundul nisei
        for dy in (-1.5, 1.5):                              # peretii nisei
            b.box((side * (half + NICHE_DEPTH * 0.5), ny + dy, spring * 0.5),
                  (NICHE_DEPTH, t, spring), slot)
        b.box((side * (half + NICHE_DEPTH * 0.5), ny, spring + t * 0.5),
              (NICHE_DEPTH, 3.0, t), slot)                  # tavanul nisei

    # --- intradosul: inel de placi pe toata lungimea -----------------------
    n = 11
    for i in range(n):
        a = math.pi * (i + 0.5) / n
        cx = -math.cos(a) * (half + t * 0.5)
        cz = spring + math.sin(a) * (half + t * 0.5)
        rot = Matrix.Rotation(a, 3, "Y")
        b.box((cx, length * 0.5, cz), (t, length, (math.pi * half / n) * 1.12),
              slot, rotation=rot)


def build_tunnel():
    clear_built()

    # --- portalul ----------------------------------------------------------
    b = Builder()
    half = TUNNEL_W * 0.5
    spring = TUNNEL_H - half
    face_y = 0.0
    face_t = 1.6            # grosimea frontispiciului

    # frontispiciul: zidarie in jurul golului, construita in coloane care se
    # opresc la conturul arcului (aceeasi tehnica ca la timpanele viaductului)
    for col in _span_points((-half - 3.2, 0, 0), (half + 3.2, 0, 0), 0.85):
        x = col.x
        if abs(x) <= half:
            base_z = spring + math.sqrt(max(half * half - x * x, 0.0))
        else:
            base_z = 0.0
        top_z = TUNNEL_H + 2.6
        if top_z - base_z < 0.2:
            continue
        _stone_face(b, (x, face_y, (base_z + top_z) * 0.5),
                    (0.87, face_t, top_z - base_z), seed=int(abs(x) * 41) + 9)

    # arhivolta: inelul de blocuri care margineste arcul, iesit 20 cm in fata
    for i in range(11):
        a = math.pi * (i + 0.5) / 11
        cx = -math.cos(a) * (half + 0.55)
        cz = spring + math.sin(a) * (half + 0.55)
        rot = Matrix.Rotation(a, 3, "Y")
        b.box((cx, face_y + 0.22, cz), (1.1, face_t + 0.44,
                                        (math.pi * half / 11) * 1.15),
              ASPHALT_EDGE, rotation=rot)

    # placa comemorativa: relief NEUTRU, fara text (brief: "placa cu 1904",
    # dar text real ar cere alt material si ar fi ilizibil la viteza)
    b.box((0.0, face_y + 0.30, TUNNEL_H + 1.5), (2.2, face_t + 0.6, 1.1),
          ASPHALT_EDGE)
    b.box((0.0, face_y + 0.42, TUNNEL_H + 1.5), (1.7, face_t + 0.5, 0.7),
          CONCRETE)
    # cornisa de sus
    b.box((0.0, face_y + 0.15, TUNNEL_H + 2.75), (TUNNEL_W + 7.0, face_t + 0.5,
                                                  0.5), ASPHALT_EDGE)
    portal = b.to_object("Tunnel_Portal")
    finish(portal, bevel=0.05, ao=AO_STONE, origin="base")

    # --- galeria -----------------------------------------------------------
    b = Builder()
    # Nisele alterneaza stanga/dreapta la fiecare NICHE_STEP. Sunt REFUGIUL din
    # mecanica trenului-pe-sens, deci adancimea (2.8 m) e derivata din latimea
    # masinii (2.2 m), nu aleasa estetic.
    niches = []
    k = 1
    y = NICHE_STEP
    while y < TUNNEL_LEN - 2.0:
        niches.append((y, -1 if k % 2 else 1))
        y += NICHE_STEP
        k += 1
    _bore_shell(b, TUNNEL_LEN, niches=niches)

    # Gheata pe pereti: scurgeri SUBTIRI, lipite de perete.
    #
    # Prima versiune punea 26 de blocuri de 20x80 cm inalte de pana la 3 m: din
    # ochiul soferului iesea o COLONADA turcoaz pe ambele parti, adica un
    # element de arhitectura, nu apa inghetata. Randarea din interior a
    # aratat-o imediat — din exterior piesa parea in regula.
    #
    # Gheata reala pe un perete de tunel e o pelicula verticala de cativa
    # centimetri, mai lata jos unde se aduna. De aici: adancime 6 cm (nu 20),
    # latime sub 40 cm, si mai putine — 14 in loc de 26.
    rand = _lcg(4417)
    for i in range(14):
        yy = 2.0 + rand() * (TUNNEL_LEN - 4.0)
        sx = -1 if rand() > 0.5 else 1
        h = 0.7 + rand() * 1.8
        w = 0.16 + rand() * 0.22
        b.box((sx * (TUNNEL_W * 0.5 - 0.03), yy, h * 0.5),
              (0.06, w, h), ICE_TURQUOISE)
    bore = b.to_object("Tunnel_Bore")
    finish(bore, bevel=0.03, ao=AO_TUNNEL, origin=None)

    # --- o nisa separata, ca piesa de sine statatoare ----------------------
    # Pista poate avea nevoie s-o aseze independent (refugiul e mecanica).
    b = Builder()
    b.box((0.0, 0.0, 1.6), (NICHE_DEPTH, 3.0, 3.2), CONCRETE)
    b.box((0.35, 0.0, 1.5), (NICHE_DEPTH, 2.4, 2.8), ASPHALT_EDGE)
    niche = b.to_object("Tunnel_Niche")
    finish(niche, bevel=0.04, ao=AO_TUNNEL, origin="base")
    niche.location.x = 14.0

    objs = [portal, bore, niche]
    print("TunnelPortal: %d tris (%s)"
          % (sum(tri_count(o) for o in objs),
             ", ".join("%s %d" % (o.name, tri_count(o)) for o in objs)))
    export_glb(objs, "baikal/structures/railway_tunnel_portal.glb")
    save_blend(objs, "baikal_railway_tunnel.blend")
    return objs


if __name__ == "__main__":
    build_viaduct()
    build_tunnel()
    build_rail_track()
