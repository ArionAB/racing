"""Transfagarasan -- vehiculele de decor (brief docs/asset_briefs/transfagarasan_kit.md §1.7).

  transfagarasan/vehicles/parked_car_a.glb   hatchback mic generic, CAR_BLUE
  transfagarasan/vehicles/parked_car_b.glb   break / SUV mic generic, CAR_RED, bare + cutie
  transfagarasan/vehicles/motorbike.glb      turism-aventura generica, pe cric, 2 genti

  transfagarasan/vehicles/ro_train.glb      locomotiva electrica + vagon de bagaje + vagon (TrainHazard), val 3
  transfagarasan/vehicles/cable_cabin_large.glb  cabina mare a telecabinei, pe linia cablului, val 3

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_tf_vehicles.py
Variabila de mediu TF_ONLY=<piesa> reface doar piesa respectiva.

GABARITUL MASINII DE JOC (kit §1.7: "la latimea si lungimea carcasei din
scenes/cars/Car.tscn, masurate, nu presupuse"). Car.tscn nu are forma de
coliziune in text: o face `car.gd` la `_ready` -- `BoxShape3D` de
**2,2 (X) x 1,0 (Y) x 3,8 (Z) m** (car.gd:482), talpa la +0,25. `apply_data`
o redimensioneaza pe fiecare masina la `body_width*0,9 x body_length*0,85`
(car.gd:550); pe masina implicita a jucatorului (Muscle, `selected_car = 0`,
body 2,00 x 4,37) iese 1,80 x 3,71 m, iar modelul ei (`open_roadster.glb`)
masoara 2,10 x 4,37 m (`measure_tf_f.py aabb`). Masinile parcate sunt pe
carcasa din Car.tscn: **a = 2,20 x 3,80 m**, **b = 2,20 x 4,37 m** (+15 %);
tabelul complet e in docs/asset_briefs/transfagarasan_inventory_f.md.

CORECTURA DE COORDONATOR (kit, capul fisierului; brief §8): masinile NU au voie
sa semene cu Dacia. Pe planșă `parked_car_a` e un Logan, `parked_car_b` un
Sandero/Duster: grila cu bara cromata si sigla, farurile in Y si silueta Logan
NU se modeleaza. Aici: grila = o fanta simpla, farurile = dreptunghiuri, placuta
goala, silueta de masinuta de jucarie (scurta, lata, roti mari, cabina mare).

Axe: X latime, Y lungime (fata spre +Y in Blender = -Z in Godot), Z sus.
Originea pe centrul amprentei, la sol. Un nod = un slot (un material pe atlas).
"""

import math
import os
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "transfagarasan_shapes.py"), encoding="utf-8").read())

ONLY = os.environ.get("TF_ONLY", "")
hull = _hull          # invelitoare convexa (transfagarasan_shapes)
PAINTED_METAL = PAINTED   # 11, numele din kit §0 (dio_lib il cheama PAINTED)

AO_CAR = dict(samples=20, dist=1.1, gradient="vertical", low=0.62, high=1.0,
              power=0.8, floor=0.40, z_range=(0.0, 1.9))
AO_MOTO = dict(samples=20, dist=0.6, gradient="vertical", low=0.66, high=1.0,
               power=0.8, floor=0.42, z_range=(0.0, 1.3))

CAR_W = 2.20          # latimea carcasei din Car.tscn (car.gd:482), la anvelope/oglinzi
CAR_L = 3.80          # lungimea carcasei din Car.tscn (car.gd:482), la bare


# ---------------------------------------------------------------------------
# caroseria din sectiuni (loft pe Y)
# ---------------------------------------------------------------------------

def _lerp_track(track, y):
    """Interpolare liniara pe o lista sortata de (y, valori...)."""
    if y <= track[0][0]:
        return track[0][1:]
    for a, b in zip(track, track[1:]):
        if a[0] <= y <= b[0]:
            t = (y - a[0]) / (b[0] - a[0]) if b[0] > a[0] else 0.0
            return tuple(va + (vb - va) * t for va, vb in zip(a[1:], b[1:]))
    return track[-1][1:]


def _section(w, z0, zb, zr, wg):
    """Sectiunea (x, z) a caroseriei, inel inchis de 18 puncte (aceeasi
    numerotare la orice statie): 0 = mijlocul talpii, 1..9 partea +X de jos
    pana la mijlocul plafonului, 10..17 partea -X inapoi spre talpa.
      1 muchia talpii   2-4 flancul   5 umarul (linia de centura)
      6 baza serei (centura interioara)   7 sus pe lateralul serei
      8 muchia plafonului   9 mijlocul plafonului (usor bombat)
    Unde nu e sera (capota, portbagaj) zr ~ zb si punctele 6-9 dau capota."""
    h = max(0.10, zb - z0)
    wb = w - 0.13
    gh = max(0.02, zr - zb)
    wg = min(wg, wb - 0.12)
    half = [
        (w - 0.16, z0),
        (w - 0.03, z0 + 0.22 * h),
        (w, z0 + 0.55 * h),
        (w - 0.01, zb - 0.30 * min(h, 0.20)),
        (w - 0.07, zb),
        (wb, zb + 0.02),
        (wg + 0.06, zb + 0.02 + 0.80 * max(0.0, gh - 0.02)),
        (wg - 0.08, zr - 0.01 if gh > 0.05 else zb + 0.035),
        (0.0, (zr + 0.015) if gh > 0.05 else zb + 0.05),
    ]
    ring = [(0.0, z0)] + half + [(-x, z) for (x, z) in reversed(half[:-1])]
    return ring


def car_stations(track, wheels, arch_r, n_arch=9):
    """Statiile loft-ului: cheile din `track` + esantioane dese pe arcadele
    rotilor. `track` = [(y, w, z0, zb, zr, wg)], `wheels` = [(y, z_centru)].
    Talpa (z0) urca pe cercul arcadei deasupra fiecarei roti: din lateral se
    citesc arcadele, iar intre roti talpa trece la inaltimea arcadei (tunel
    peste axa, nevazut din camera)."""
    ys = {round(t[0], 4) for t in track}
    for (yw, zc) in wheels:
        for k in range(n_arch):
            a = math.pi * k / (n_arch - 1)
            ys.add(round(yw + arch_r * math.cos(a), 4))
        ys.add(round(yw + arch_r + 0.012, 4))
        ys.add(round(yw - arch_r - 0.012, 4))
    out = []
    for y in sorted(ys):
        w, z0, zb, zr, wg = _lerp_track(track, y)
        for (yw, zc) in wheels:
            d = y - yw
            if abs(d) <= arch_r + 1e-6:
                z0 = max(z0, zc + math.sqrt(max(0.0, arch_r * arch_r - d * d)))
        out.append((y, w, z0, zb, zr, wg))
    return out


def body_loft(b, stations, slot):
    """Construieste caroseria; intoarce grila P[i][j] (statie, punct de inel)."""
    grid = []
    for (y, w, z0, zb, zr, wg) in stations:
        grid.append([Vector((x, y, z)) for (x, z) in _section(w, z0, zb, zr, wg)])
    ring_stack(b, [[tuple(p) for p in r] for r in grid], slot)
    return grid


def _y_to_u(stations, y):
    ys = [s[0] for s in stations]
    for i in range(len(ys) - 1):
        if ys[i] <= y <= ys[i + 1]:
            return i + (y - ys[i]) / (ys[i + 1] - ys[i])
    return 0.0 if y < ys[0] else float(len(ys) - 1)


def _grid_at(P, u, v):
    n = len(P[0])
    i = max(0, min(len(P) - 2, int(math.floor(u))))
    fu = u - i
    j = int(math.floor(v)) % n
    fv = v - math.floor(v)
    j2 = (j + 1) % n
    a = P[i][j].lerp(P[i][j2], fv)
    c = P[i + 1][j].lerp(P[i + 1][j2], fv)
    return a.lerp(c, fu)


def glass_patch(b, P, stations, y0, y1, v0, v1, slot, out=0.014, inn=0.02, nu=None, nv=4):
    """Geam: o placa SUBTIRE (inchisa) urmand suprafata caroseriei pe petecul
    (y0..y1, v0..v1) din grila, iesita `out` m in afara (memoria val 1: un
    strat lipit coplanar fura culoarea, deci 1,4 cm intre ele) si infipta `inn`
    m inauntru. Normala locala se orienteaza dinspre axa masinii."""
    u0, u1 = _y_to_u(stations, y0), _y_to_u(stations, y1)
    if nu is None:
        nu = max(2, int(abs(u1 - u0)) + 2)
    pts_o, pts_i = [], []
    for a in range(nu + 1):
        u = u0 + (u1 - u0) * a / nu
        row_o, row_i = [], []
        for c in range(nv + 1):
            v = v0 + (v1 - v0) * c / nv
            p = _grid_at(P, u, v)
            du = _grid_at(P, min(u + 0.05, len(P) - 1.001), v) - _grid_at(P, max(u - 0.05, 0.0), v)
            dv = _grid_at(P, u, v + 0.05) - _grid_at(P, u, v - 0.05)
            n = du.cross(dv)
            if n.length < 1e-9:
                n = Vector((0, 0, 1))
            n.normalize()
            axis = Vector((0.0, p.y, 0.9))
            if n.dot(p - axis) < 0:
                n = -n
            row_o.append(b.bm.verts.new(p + n * out))
            row_i.append(b.bm.verts.new(p - n * inn))
        pts_o.append(row_o)
        pts_i.append(row_i)
    faces = []
    for a in range(nu):
        for c in range(nv):
            faces.append(b.bm.faces.new((pts_o[a][c], pts_o[a + 1][c], pts_o[a + 1][c + 1], pts_o[a][c + 1])))
            faces.append(b.bm.faces.new((pts_i[a][c + 1], pts_i[a + 1][c + 1], pts_i[a + 1][c], pts_i[a][c])))
    for a in range(nu):
        for c in (0, nv):
            faces.append(b.bm.faces.new((pts_o[a][c], pts_i[a][c], pts_i[a + 1][c], pts_o[a + 1][c])))
    for c in range(nv):
        for a in (0, nu):
            faces.append(b.bm.faces.new((pts_o[a][c], pts_o[a][c + 1], pts_i[a][c + 1], pts_i[a][c])))
    for f in faces:
        f[b.slot] = slot
    return faces


def wheel_set(tyre, hub, wheels, x_out, radius, width, hub_r, seg=14):
    """4 roti: anvelopa (cilindru, rotunjita de bevel) + janta (disc iesit 1 cm
    pe fata exterioara, cu un capac central)."""
    for (yw, zc) in wheels:
        for sx in (-1.0, 1.0):
            xc = sx * (x_out - width * 0.5)
            tyre.cylinder((xc, yw, zc), radius, width, VOLCANIC_BLACK, segments=seg, axis="X")
            hub.cylinder((sx * (x_out - 0.010), yw, zc), hub_r, 0.040, MARBLE_GREY, segments=10, axis="X")
            hub.cylinder((sx * (x_out + 0.008), yw, zc), hub_r * 0.38, 0.030, MARBLE_GREY, segments=8, axis="X")


def rect(b, center, size, slot, rot_z=0.0, rot_x=0.0):
    rot = Matrix.Rotation(math.radians(rot_z), 3, "Z") @ Matrix.Rotation(math.radians(rot_x), 3, "X")
    b.box(center, size, slot, rotation=rot)


# ---------------------------------------------------------------------------
# parked_car_a
# ---------------------------------------------------------------------------

def build_parked_car_a():
    """Masina parcata A (`parked_car_a`): HATCHBACK MIC GENERIC, CAR_BLUE.

    LISTA DE ELEMENTE (din decuparea `transfagarasan_assets_v1/parked_car_a.png`,
    scrisa INAINTE de geometrie; unde corectura „nu Dacia” contrazice decuparea,
    lista urmeaza corectura si o spune):
      1) caroseria albastra dintr-o bucata: capota scurta, sera mare, plafon
         drept, hayon aproape vertical. DECUPAREA: sedan Logan cu portbagaj si
         capota lunga -> CORECTURA: hatchback de jucarie (fara portbagaj in trepte),
         capota scurta, roti mari, scurt si lat
      2) 4 roti mari, negre, cu jante argintii (decuparea: 4 roti, jante cu spite;
         aici disc + capac, fara spite: la 30 m nu se vad)
      3) 4 arcade de roata decupate in flanc (decuparea: arcade vizibile)
      4) parbriz mare inclinat, luneta, 2 geamuri laterale pe parte cu stalpul B
         si unul mic in spate (decuparea: 3 geamuri laterale pe parte, rame
         negre) -> 3 pe parte (fata, spate, sfert)
      5) 2 oglinzi pe stalpul A, in culoarea caroseriei (decuparea: 2)
      6) faruri: decuparea are farurile Dacia trase in Y -> CORECTURA: 2
         DREPTUNGHIURI albe simple
      7) grila: decuparea are bara cromata cu sigla -> CORECTURA: O FANTA simpla
         neagra, fara sigla
      8) bara fata si bara spate din plastic gri-inchis (decuparea: bare in
         culoarea caroseriei cu plastic jos) -> plastic ASPHALT, ca rol
      9) placuta alba GOALA fata si spate (decuparea: placuta cu caractere ->
         fara text, regula 9)
     10) 2 stopuri rosii verticale in colturile hayonului
     11) bare de plafon: decuparea are 2 bare subtiri -> NU pe A (sunt semnul
         lui B, ca sa difere ca tip); un eleron mic pe muchia hayonului
     12) praguri negre intre arcade

    Cote: 2,20 x 3,80 m (carcasa din Car.tscn, car.gd:482), ~1,64 m inalt,
    roti R 0,40 (masinile garajului au 0,37-0,41). Noduri (un slot fiecare):
    Car_Body CAR_BLUE 15, Car_Glass VOLCANIC_BLACK 20, Car_Tyre VOLCANIC_BLACK 20,
    Car_Trim ASPHALT 5, Car_Hub MARBLE_GREY 29, Car_Lamp FOAM_WHITE 22,
    Car_Tail KERB_RED 7.
    """
    body, glass, tyre, trim, hub, lamp, tail = (Builder() for _ in range(7))
    E = 1.84                       # capetele caroseriei; barele ies pana la +-1,90
    R, ZC = 0.40, 0.40
    wheels = [(-1.22, ZC), (1.22, ZC)]
    #          y      w     z0    zb    zr    wg
    track = [(-E,    0.97, 0.40, 0.98, 1.00, 0.70),
             (-1.80, 1.02, 0.33, 1.04, 1.26, 0.66),
             (-1.66, 1.04, 0.30, 1.06, 1.50, 0.66),
             (-1.40, 1.04, 0.30, 1.07, 1.60, 0.68),
             (-0.10, 1.04, 0.30, 1.07, 1.62, 0.69),
             (0.15,  1.04, 0.30, 1.07, 1.56, 0.71),
             (0.95,  1.04, 0.30, 1.04, 1.07, 0.76),
             (1.55,  1.02, 0.30, 0.98, 1.00, 0.74),
             (1.78,  0.98, 0.33, 0.92, 0.94, 0.70),
             (E,     0.92, 0.40, 0.85, 0.87, 0.65)]
    st = car_stations(track, wheels, arch_r=0.46)
    P = body_loft(body, st, CAR_BLUE)

    # --- geamurile (placi subtiri pe suprafata serei)
    # v pe inel: 6 = centura, 7 = sus pe lateral, 8 = muchia plafonului,
    # 9 = mijloc; partea -X e oglinda: v' = 18 - v
    glass_patch(glass, P, st, 0.24, 0.90, 7.55, 10.45, VOLCANIC_BLACK, nu=6, nv=6)     # parbriz
    glass_patch(glass, P, st, -1.78, -1.44, 7.55, 10.45, VOLCANIC_BLACK, nu=3, nv=6)   # luneta
    for (y0, y1) in ((-0.40, 0.36), (-1.16, -0.52), (-1.52, -1.28)):
        glass_patch(glass, P, st, y0, y1, 6.18, 7.80, VOLCANIC_BLACK, nu=4, nv=2)
        glass_patch(glass, P, st, y0, y1, 18 - 7.80, 18 - 6.18, VOLCANIC_BLACK, nu=4, nv=2)

    # --- oglinzile (culoarea caroseriei) pe stalpul A
    for sx in (-1.0, 1.0):
        body.box((sx * 1.04, 0.86, 1.10), (0.10, 0.05, 0.05), CAR_BLUE)
        body.box((sx * 1.075, 0.84, 1.13), (0.05, 0.12, 0.10), CAR_BLUE)
    # --- eleronul mic pe muchia hayonului
    body.box((0.0, -1.47, 1.615), (1.04, 0.12, 0.03), CAR_BLUE)

    # --- barele, pragurile, fanta grilei (plastic)
    for sy in (-1.0, 1.0):
        trim.box((0.0, sy * 1.86, 0.47), (1.86, 0.07, 0.20), ASPHALT)
        for sx in (-1.0, 1.0):
            rect(trim, (sx * 0.93, sy * 1.80, 0.47), (0.10, 0.20, 0.20), ASPHALT, rot_z=sx * sy * 30.0)
    trim.box((0.0, E + 0.012, 0.635), (0.82, 0.03, 0.08), ASPHALT)         # fanta grilei
    for sx in (-1.0, 1.0):
        trim.box((sx * 1.035, 0.0, 0.345), (0.04, 1.42, 0.07), ASPHALT)       # pragul

    # --- farurile (dreptunghiuri), placutele GOALE, stopurile
    for sx in (-1.0, 1.0):
        lamp.box((sx * 0.60, E + 0.012, 0.745), (0.32, 0.03, 0.11), FOAM_WHITE)
        tail.box((sx * 0.80, -E - 0.012, 0.88), (0.15, 0.03, 0.26), KERB_RED)
    lamp.box((0.0, 1.888, 0.47), (0.40, 0.02, 0.10), FOAM_WHITE)
    lamp.box((0.0, -1.888, 0.47), (0.40, 0.02, 0.10), FOAM_WHITE)

    wheel_set(tyre, hub, wheels, x_out=1.072, radius=R, width=0.30, hub_r=0.25)

    return [body.to_object("Car_Body"), glass.to_object("Car_Glass"),
            tyre.to_object("Car_Tyre"), trim.to_object("Car_Trim"),
            hub.to_object("Car_Hub"), lamp.to_object("Car_Lamp"),
            tail.to_object("Car_Tail")]


# ---------------------------------------------------------------------------
# parked_car_b
# ---------------------------------------------------------------------------

def build_parked_car_b():
    """Masina parcata B (`parked_car_b`): BREAK / SUV MIC GENERIC, CAR_RED,
    cu bare de plafon si o cutie de 1,2 m pe ele.

    LISTA DE ELEMENTE (din decuparea `transfagarasan_assets_v1/parked_car_b.png`,
    scrisa INAINTE de geometrie; corectura „nu Dacia” bate decuparea):
      1) caroserie rosie inalta, cu plafon lung si drept pana in spate, stalpul D
         aproape vertical (decuparea: SUV compact Duster -> CORECTURA: silueta
         generica de jucarie, mai lunga +15 % si mai inalta decat A)
      2) 4 roti mari negre cu jante argintii (decuparea: 4, jante cu spite)
      3) 4 arcade cu buza de plastic negru (decuparea: arcade cu plastic gri
         inchis, semn de SUV) -> tub ASPHALT pe arcada
      4) garda la sol mare (decuparea: SUV ridicat)
      5) parbriz, luneta, 3 geamuri laterale pe parte (decuparea: 3)
      6) 2 bare de plafon pe toata lungimea (decuparea: 2, negre)
      7) CUTIE de plafon de 1,2 m pe bare (contract; nu e pe decupare)
      8) faruri: decuparea are farurile Duster -> CORECTURA: 2 dreptunghiuri albe
      9) grila: decuparea are grila Dacia cu sigla -> CORECTURA: o fanta simpla
     10) bare fata/spate de plastic gri-inchis, cu scut jos (decuparea: idem)
     11) placute albe GOALE
     12) 2 oglinzi in culoarea caroseriei (decuparea: 2)
     13) stopuri rosii orizontale in colturile spate
     14) placare de plastic pe partea de jos a usilor (decuparea: banda inchisa)

    Cote: 2,20 x 4,37 m (A + 15 %), ~1,90 m la plafon, ~2,22 m cu cutia; roti
    R 0,45. Noduri ca la A (Car_Body pe CAR_RED 14).
    """
    body, glass, tyre, trim, hub, lamp, tail = (Builder() for _ in range(7))
    E = 2.125                      # barele ies pana la +-2,185 (L = 4,37)
    R, ZC = 0.45, 0.45
    wheels = [(-1.42, ZC), (1.45, ZC)]
    track = [(-E,    0.97, 0.47, 1.10, 1.12, 0.70),
             (-2.08, 1.03, 0.40, 1.16, 1.62, 0.74),
             (-2.00, 1.04, 0.38, 1.18, 1.84, 0.74),
             (-1.82, 1.04, 0.38, 1.18, 1.89, 0.75),
             (0.30,  1.04, 0.38, 1.18, 1.91, 0.75),
             (0.55,  1.04, 0.38, 1.18, 1.83, 0.77),
             (1.12,  1.04, 0.38, 1.16, 1.20, 0.78),
             (1.80,  1.03, 0.38, 1.13, 1.15, 0.77),
             (2.05,  0.99, 0.41, 1.07, 1.09, 0.73),
             (E,     0.94, 0.48, 1.00, 1.02, 0.68)]
    st = car_stations(track, wheels, arch_r=0.53)
    P = body_loft(body, st, CAR_RED)

    glass_patch(glass, P, st, 0.60, 1.08, 7.55, 10.45, VOLCANIC_BLACK, nu=5, nv=6)     # parbriz
    glass_patch(glass, P, st, -2.07, -1.98, 7.45, 10.55, VOLCANIC_BLACK, nu=2, nv=6)   # luneta
    for (y0, y1) in ((-0.36, 0.60), (-1.28, -0.48), (-1.94, -1.40)):
        glass_patch(glass, P, st, y0, y1, 6.18, 7.80, VOLCANIC_BLACK, nu=4, nv=2)
        glass_patch(glass, P, st, y0, y1, 18 - 7.80, 18 - 6.18, VOLCANIC_BLACK, nu=4, nv=2)

    for sx in (-1.0, 1.0):
        body.box((sx * 1.04, 0.98, 1.23), (0.10, 0.05, 0.05), CAR_RED)
        body.box((sx * 1.075, 0.96, 1.26), (0.05, 0.12, 0.11), CAR_RED)

    # --- bare de plafon (2) pe picioruse, cutia de 1,2 m pe ele
    for sx in (-1.0, 1.0):
        x = sx * 0.62
        trim.beam((x, -1.78, 1.97), (x, 0.32, 1.97), (0.05, 0.05), ASPHALT)
        for y in (-1.80, -0.74, 0.34):
            trim.box((x, y, 1.935), (0.06, 0.10, 0.07), ASPHALT)
    trim.box((0.0, -0.78, 2.12), (0.86, 1.20, 0.26), ASPHALT)
    trim.box((0.0, -0.78, 2.005), (0.80, 1.10, 0.04), ASPHALT)

    # --- buza de plastic pe arcade (SUV), placarea de jos, barele, fanta
    for (yw, zc) in wheels:
        for sx in (-1.0, 1.0):
            path = []
            for k in range(11):
                a = math.pi * k / 10.0
                path.append((sx * 1.035, yw + 0.56 * math.cos(a), zc + 0.56 * math.sin(a)))
            trim.sweep(path, 0.045, ASPHALT, segments=6, dome_end=False)
    for sx in (-1.0, 1.0):
        trim.box((sx * 1.035, 0.02, 0.50), (0.045, 1.72, 0.16), ASPHALT)
    for sy in (-1.0, 1.0):
        trim.box((0.0, sy * 2.135, 0.55), (1.88, 0.07, 0.24), ASPHALT)
        trim.box((0.0, sy * 2.10, 0.42), (1.20, 0.10, 0.06), ASPHALT)          # scutul
        for sx in (-1.0, 1.0):
            rect(trim, (sx * 0.93, sy * 2.07, 0.55), (0.10, 0.20, 0.24), ASPHALT, rot_z=sx * sy * 30.0)
    trim.box((0.0, E + 0.012, 0.82), (0.86, 0.03, 0.10), ASPHALT)

    for sx in (-1.0, 1.0):
        lamp.box((sx * 0.64, E + 0.012, 0.92), (0.32, 0.03, 0.12), FOAM_WHITE)
        tail.box((sx * 0.78, -E - 0.012, 0.98), (0.30, 0.03, 0.12), KERB_RED)
    lamp.box((0.0, 2.172, 0.55), (0.40, 0.02, 0.10), FOAM_WHITE)
    lamp.box((0.0, -2.172, 0.55), (0.40, 0.02, 0.10), FOAM_WHITE)

    wheel_set(tyre, hub, wheels, x_out=1.072, radius=R, width=0.32, hub_r=0.27)

    return [body.to_object("Car_Body"), glass.to_object("Car_Glass"),
            tyre.to_object("Car_Tyre"), trim.to_object("Car_Trim"),
            hub.to_object("Car_Hub"), lamp.to_object("Car_Lamp"),
            tail.to_object("Car_Tail")]


# ---------------------------------------------------------------------------
# motorbike
# ---------------------------------------------------------------------------

def build_motorbike():
    """Motocicleta (`motorbike`): TURISM-AVENTURA GENERICA, pe cric lateral,
    inclinata ~10 grade spre stanga (-X), cu 2 genti laterale. Fara sigla.

    LISTA DE ELEMENTE (din decuparea `transfagarasan_assets_v1/motorbike.png`,
    scrisa INAINTE de geometrie; unde contractul cere altceva decat decuparea
    -- turism-aventura cu genti, pe cric -- urmeaza contractul si o spune):
      1) 2 roti, fata putin mai mare (decuparea: 2 roti egale, jante cu spite)
      2) furca telescopica inclinata ~27 grade (decuparea: tuburi aurii) ->
         metal PAINTED_METAL
      3) aripa fata sus + „cioc” sub far (decuparea: aripa joasa de sport ->
         CONTRACT aventura: cioc)
      4) semicarenaj cu far (1 far dreptunghiular) si parbriz INALT
         (decuparea: semicarenaj de sport-turism, parbriz mediu)
      5) ghidon lat cu 2 aparatori de maini si 2 oglinzi pe tije
      6) rezervor mare albastru cu flancuri care coboara pe laterale
         (decuparea: rezervor albastru, flancuri albastre)
      7) sa neagra in doua trepte, pilot + pasager (decuparea: idem)
      8) coada albastra subtire sub sa + stop rosu (decuparea: idem, fara stop vizibil)
      9) motorul (bloc + chiulasa inclinata), scut sub motor (decuparea: motor
         gri inchis vizibil, fara scut -> CONTRACT aventura: scut)
     10) bascula + amortizor spate (decuparea: idem)
     11) toba pe dreapta, ridicata spre spate (decuparea: toba scurta, dreapta)
     12) 2 GENTI laterale cu rama (CONTRACT; pe decupare nu sunt)
     13) cricul lateral pe stanga, motocicleta sprijinita pe el (CONTRACT)
     14) scarite (2)

    Cote: 2,20 m lung, ~1,30 m inalt dupa inclinare. Noduri (un slot fiecare):
    Moto_Body CAR_BLUE 15, Moto_Metal PAINTED_METAL 11, Moto_Dark VOLCANIC_BLACK 20,
    Moto_Lamp FOAM_WHITE 22 (farul), Moto_Tail KERB_RED 7 (stopul).
    """
    bodyb, metal, dark, lamp, tail = (Builder() for _ in range(5))
    YF, ZF, RF = 0.76, 0.37, 0.37      # roata fata
    YR, ZR, RR = -0.72, 0.35, 0.35     # roata spate

    # 1) roti: anvelopa-tor + janta (disc) + butuc
    for (y, z, r, wt) in ((YF, ZF, RF, 0.065), (YR, ZR, RR, 0.08)):
        dark.torus((0.0, y, z), r - wt, wt, VOLCANIC_BLACK, major_seg=16, minor_seg=6, axis="X")
        # janta: inel metalic subtire + 6 spite + butuc; golul dintre spite e
        # un disc negru retras (se vede roata, nu un capac plin)
        metal.torus((0.0, y, z), r - wt - 0.035, 0.022, PAINTED_METAL, major_seg=16, minor_seg=4, axis="X")
        dark.cylinder((0.0, y, z), r - wt - 0.03, 0.02, VOLCANIC_BLACK, segments=12, axis="X")
        for k in range(6):
            a = math.pi * 2.0 * k / 6.0 + 0.3
            ry_, rz_ = math.cos(a) * (r - wt - 0.04), math.sin(a) * (r - wt - 0.04)
            metal.beam((0.0, y, z), (0.0, y + ry_, z + rz_), (0.05, 0.022), PAINTED_METAL)
        metal.cylinder((0.0, y, z), 0.06, 0.14, PAINTED_METAL, segments=8, axis="X")

    # 2) furca: 2 tuburi de la ax la jugul de sus
    head_lo = Vector((0.0, 0.47, 0.98))
    for sx in (-1.0, 1.0):
        metal.beam((sx * 0.075, YF, ZF), (sx * 0.075, head_lo.y, head_lo.z), 0.07, PAINTED_METAL)
    metal.box((0.0, 0.50, 0.93), (0.22, 0.08, 0.05), PAINTED_METAL)                # jugul
    # 3) aripa fata sus + ciocul sub far
    # aripa joasa peste roata (urmeaza anvelopa) + ciocul (pana sub far)
    hull(bodyb, [(-0.08, YF - 0.20, 0.80), (0.08, YF - 0.20, 0.80), (-0.08, YF + 0.22, 0.79),
                 (0.08, YF + 0.22, 0.79), (-0.07, YF - 0.16, 0.76), (0.07, YF - 0.16, 0.76),
                 (-0.07, YF + 0.20, 0.75), (0.07, YF + 0.20, 0.75), (0.0, YF, 0.82)], CAR_BLUE)
    hull(bodyb, [(-0.11, 0.56, 0.98), (0.11, 0.56, 0.98), (-0.09, 0.58, 0.86), (0.09, 0.58, 0.86),
                 (-0.04, 0.84, 0.86), (0.04, 0.84, 0.86), (0.0, 0.82, 0.90)], CAR_BLUE)
    # 4) semicarenajul (cu flancuri) + farul + parbrizul inalt
    hull(bodyb, [(-0.22, 0.42, 0.90), (0.22, 0.42, 0.90), (-0.24, 0.40, 1.08), (0.24, 0.40, 1.08),
                 (-0.15, 0.62, 0.94), (0.15, 0.62, 0.94), (-0.14, 0.60, 1.10), (0.14, 0.60, 1.10),
                 (-0.10, 0.50, 1.18), (0.10, 0.50, 1.18), (0.0, 0.66, 1.02)], CAR_BLUE)
    rect(lamp, (0.0, 0.638, 1.03), (0.20, 0.03, 0.09), FOAM_WHITE, rot_x=-14.0)
    rect(metal, (0.0, 0.48, 1.20), (0.34, 0.012, 0.26), PAINTED_METAL, rot_x=-24.0)   # parbriz
    # 5) ghidon, aparatori, oglinzi
    dark.beam((-0.40, 0.36, 1.12), (0.40, 0.36, 1.12), 0.035, VOLCANIC_BLACK)
    dark.box((0.0, 0.40, 1.05), (0.06, 0.06, 0.14), VOLCANIC_BLACK)
    for sx in (-1.0, 1.0):
        hull(bodyb, [(sx * 0.34, 0.40, 1.08), (sx * 0.44, 0.40, 1.08), (sx * 0.34, 0.44, 1.16),
                     (sx * 0.44, 0.44, 1.16), (sx * 0.39, 0.47, 1.12), (sx * 0.36, 0.38, 1.14)], CAR_BLUE)
        dark.beam((sx * 0.28, 0.37, 1.13), (sx * 0.33, 0.39, 1.24), 0.018, VOLCANIC_BLACK)
        dark.box((sx * 0.35, 0.39, 1.26), (0.12, 0.025, 0.07), VOLCANIC_BLACK)
    # 6) rezervorul cu flancuri
    hull(bodyb, [(-0.20, 0.42, 1.04), (0.20, 0.42, 1.04), (-0.17, 0.02, 0.98), (0.17, 0.02, 0.98),
                 (-0.24, 0.40, 0.78), (0.24, 0.40, 0.78), (-0.20, 0.10, 0.74), (0.20, 0.10, 0.74),
                 (-0.13, 0.30, 1.10), (0.13, 0.30, 1.10), (0.0, 0.06, 1.03)], CAR_BLUE)
    # 7) saua in doua trepte
    hull(dark, [(-0.16, 0.04, 0.92), (0.16, 0.04, 0.92), (-0.15, -0.38, 0.88), (0.15, -0.38, 0.88),
                (-0.13, 0.00, 1.00), (0.13, 0.00, 1.00), (-0.13, -0.36, 0.96), (0.13, -0.36, 0.96)],
         VOLCANIC_BLACK)
    hull(dark, [(-0.14, -0.36, 0.92), (0.14, -0.36, 0.92), (-0.12, -0.72, 0.94), (0.12, -0.72, 0.94),
                (-0.12, -0.38, 1.04), (0.12, -0.38, 1.04), (-0.10, -0.70, 1.02), (0.10, -0.70, 1.02)],
         VOLCANIC_BLACK)
    # 8) coada sub sa + stopul
    hull(bodyb, [(-0.15, -0.30, 0.78), (0.15, -0.30, 0.78), (-0.10, -0.90, 0.86), (0.10, -0.90, 0.86),
                 (-0.13, -0.32, 0.92), (0.13, -0.32, 0.92), (-0.08, -0.92, 0.94), (0.08, -0.92, 0.94)],
         CAR_BLUE)
    tail.box((0.0, -0.93, 0.89), (0.12, 0.03, 0.05), KERB_RED)
    # capacele laterale sub sa: umplu golul dintre rezervor si coada (decuparea:
    # flancul albastru continuu de la rezervor la coada)
    hull(bodyb, [(-0.15, 0.06, 0.66), (0.15, 0.06, 0.66), (-0.14, -0.34, 0.74), (0.14, -0.34, 0.74),
                 (-0.16, 0.06, 0.90), (0.16, 0.06, 0.90), (-0.14, -0.36, 0.88), (0.14, -0.36, 0.88)],
         CAR_BLUE)
    # 9) motorul: bloc, chiulasa inclinata in fata, scutul
    dark.box((0.0, 0.08, 0.50), (0.34, 0.40, 0.30), VOLCANIC_BLACK)                # carterul
    rect(metal, (0.0, 0.24, 0.70), (0.30, 0.18, 0.24), PAINTED_METAL, rot_x=-25.0)   # chiulasa
    dark.box((0.0, -0.12, 0.56), (0.30, 0.12, 0.22), VOLCANIC_BLACK)                # cutia
    hull(metal, [(-0.18, 0.34, 0.40), (0.18, 0.34, 0.40), (-0.18, -0.10, 0.27), (0.18, -0.10, 0.27),
                 (-0.16, 0.38, 0.30), (0.16, 0.38, 0.30), (-0.16, -0.12, 0.33), (0.16, -0.12, 0.33)],
         PAINTED_METAL)
    # cadrul: tub de la jug la pivotul basculei, pe ambele parti
    for sx in (-1.0, 1.0):
        dark.beam((sx * 0.09, 0.46, 0.96), (sx * 0.12, -0.10, 0.80), 0.045, VOLCANIC_BLACK)
        dark.beam((sx * 0.12, -0.10, 0.80), (sx * 0.12, -0.20, 0.48), 0.045, VOLCANIC_BLACK)
    # 10) bascula + amortizorul
    for sx in (-1.0, 1.0):
        metal.beam((sx * 0.10, -0.20, 0.47), (sx * 0.10, YR, ZR), (0.04, 0.07), PAINTED_METAL)
    dark.beam((0.0, -0.22, 0.86), (0.0, -0.42, 0.50), 0.05, VOLCANIC_BLACK)
    # 11) toba pe dreapta, ridicata spre spate (+ colectorul)
    metal.beam((0.10, 0.30, 0.42), (0.18, -0.20, 0.42), 0.05, PAINTED_METAL)
    metal.beam((0.19, -0.26, 0.50), (0.19, -0.62, 0.70), 0.11, PAINTED_METAL)
    # 12) gentile laterale cu rama si capac
    for sx in (-1.0, 1.0):
        metal.box((sx * 0.33, -0.66, 0.68), (0.20, 0.48, 0.36), PAINTED_METAL)
        dark.box((sx * 0.33, -0.66, 0.875), (0.215, 0.50, 0.05), VOLCANIC_BLACK)
        dark.beam((sx * 0.22, -0.38, 0.48), (sx * 0.22, -0.92, 0.48), 0.03, VOLCANIC_BLACK)
        dark.beam((sx * 0.22, -0.40, 0.48), (sx * 0.14, -0.40, 0.86), 0.03, VOLCANIC_BLACK)
    # 14) scaritele
    for sx in (-1.0, 1.0):
        dark.box((sx * 0.18, -0.06, 0.36), (0.12, 0.05, 0.04), VOLCANIC_BLACK)

    objs = [bodyb.to_object("Moto_Body"), metal.to_object("Moto_Metal"),
            dark.to_object("Moto_Dark"), lamp.to_object("Moto_Lamp"),
            tail.to_object("Moto_Tail")]

    # 13) inclinarea pe cric: totul se roteste in jurul liniei de contact a
    # rotilor (axa Y, z = 0) cu ~10 grade spre -X; apoi cricul, din lume.
    lean = Matrix.Rotation(math.radians(-10.0), 4, "Y")
    for o in objs:
        o.data.transform(lean)
        o.data.update()
    pivot = lean @ Vector((-0.14, -0.10, 0.38))
    foot = Vector((pivot.x - 0.30, pivot.y + 0.10, 0.012))
    stand = Builder()
    stand.beam(tuple(pivot), tuple(foot), 0.03, PAINTED_METAL)
    stand.box((foot.x, foot.y, 0.012), (0.07, 0.09, 0.024), PAINTED_METAL)
    so = stand.to_object("Moto_Stand")
    # cricul e metal: intra in nodul Moto_Metal (un slot), nu nod separat
    bpy.ops.object.select_all(action="DESELECT")
    objs[1].select_set(True)
    so.select_set(True)
    bpy.context.view_layer.objects.active = objs[1]
    bpy.ops.object.join()
    return objs


# ---------------------------------------------------------------------------
# ro_train (valul 3, tf-h): Train_Loco + Train_Tender + Train_Wagon
# ---------------------------------------------------------------------------
#
# CONTRACT DE COD (scenes/hazards/train_hazard.gd, MASURAT, nu presupus):
#   - noduri cautate dupa nume EXACT, doar printre copiii DIRECTI ai radacinii:
#     Train_Loco, Train_Tender, Train_Wagon (lipseste unul => toata garnitura
#     cade pe cutii, in tacere)
#   - lungimea fiecarei piese pe X, BOTUL PE +X (hazardul pune locomotiva
#     ultima, la x maxim), roti la y = 0 (hazardul ridica piesa la RAIL_TOP 0,28)
#   - ecartament |z| = 0,45 (GAUGE_HALF); piesele centrate pe axa, fiecare cu
#     capatul din coada luat din AABB (originea nu conteaza pe X)
#   - cotele (lungime, coliziune, zona de lovire) ies din AABB-ul piesei
# SCARA (tf-h2, verdictul coordonatorului): cifrele 17 / 20 m din kit §1.7 sunt
# ANULATE; scara de joc a garniturilor (train.glb, perurail_train.glb) e 8-9 m
# pe piesa. Loco ~11 m, tender ~5 m, vagon ~8,5 m, latime ~2,9, h ~3,6 m.
# In Blender: X lungime (bot +X), Y latime (sina la |y| = 0,45), Z sus.

TR_GREY = ASPHALT_EDGE      # 6: banda, acoperisul (decizie: nu PAINTED_METAL 11, iese albastru)
TR_W = 2.80                 # latimea caroseriei (cu ferestre/banda ~2,9)
TR_HW = TR_W * 0.5
TR_GAUGE = 0.45             # GAUGE_HALF din train_hazard.gd
TR_WR = 0.45                # raza rotii; baza la z = 0
TR_SILL = 0.95              # talpa caroseriei (peste rotile de 0,45 -> varf 0,90)
TR_BAND = 1.50              # varful benzii gri (~27% din flancul 0,95..3,0, +talpa); sus: rosu
TR_BUF = 0.40               # cat ies tampoanele dincolo de caroserie
AO_TRAIN = dict(samples=20, dist=1.6, gradient="vertical", low=0.64, high=1.0,
                power=0.9, floor=0.30, z_range=(0.0, 4.4))


def _tr_wheelset(b, x, motor=False):
    """O osie: 2 roti (r 0,45, 12 segmente) la |y| = 0,45, butuc, axul intre ele."""
    for sy in (-1.0, 1.0):
        b.cylinder((x, sy * TR_GAUGE, TR_WR), TR_WR, 0.16, VOLCANIC_BLACK,
                   segments=12, axis="Y")
        b.cylinder((x, sy * (TR_GAUGE + 0.09), TR_WR), 0.20, 0.06, TR_GREY,
                   segments=8, axis="Y")
    b.cylinder((x, 0.0, TR_WR), 0.07, 2 * TR_GAUGE, VOLCANIC_BLACK, segments=6, axis="Y")
    if motor:   # carcasa motorului de tractiune, pe axa
        b.cylinder((x + 0.05, 0.0, TR_WR + 0.06), 0.24, 0.62, VOLCANIC_BLACK,
                   segments=8, axis="Y")


def _tr_bogie(b, cx, wb, motor=True):
    """Boghiu cu 2 osii (la cx +- wb/2): 4 roti, 2 lonjeroane laterale, travers."""
    for dx in (-wb * 0.5, wb * 0.5):
        _tr_wheelset(b, cx + dx, motor=motor)
    for sy in (-1.0, 1.0):
        b.box((cx, sy * 0.68, 0.62), (wb - 0.50, 0.14, 0.34), VOLCANIC_BLACK)
        b.box((cx, sy * 0.68, 0.80), (wb + 0.70, 0.12, 0.10), VOLCANIC_BLACK)
    b.box((cx, 0.0, 0.84), (0.90, 1.50, 0.20), VOLCANIC_BLACK)    # travers / pivot


def _tr_body(b, hl, eave, peak):
    """Banda gri LATA jos (talpa..TR_BAND, iese 2 cm din flanc), linie
    FOAM_WHITE subtire la limita, corp rosu deasupra, acoperis gri bombat (hull).
    `hl` = jumatate din lungimea caroseriei, `eave` = streasina, `peak` = coama."""
    b.box((0.0, 0.0, (TR_SILL + TR_BAND) * 0.5), (2 * hl, TR_W + 0.04, TR_BAND - TR_SILL),
          TR_GREY)
    b.box((0.0, 0.0, TR_BAND + 0.03), (2 * hl, TR_W + 0.07, 0.06), FOAM_WHITE)
    b.box((0.0, 0.0, (TR_BAND + eave) * 0.5), (2 * hl, TR_W, eave - TR_BAND), CAR_RED)
    h = peak - eave
    yz = [(1.0, eave - 0.02), (1.0, eave + 0.06), (0.88, eave + 0.46 * h),
          (0.62, eave + 0.76 * h), (0.30, eave + 0.94 * h), (0.0, peak)]
    pts = []
    for x in (-hl, hl):
        for (f, z) in yz:
            pts.append((x, f * TR_HW, z))
            if f > 0:
                pts.append((x, -f * TR_HW, z))
    hull(b, pts, TR_GREY)


def _tr_window(b, x, side, zc, w, h):
    """Fereastra pe flanc: rama rosie iesita 3 cm + geam negru iesit 6 cm."""
    b.box((x, side * TR_HW, zc), (w + 0.14, 0.06, h + 0.14), CAR_RED)
    b.box((x, side * (TR_HW + 0.03), zc), (w, 0.06, h), VOLCANIC_BLACK)


def _tr_door(b, x, side, z0, z1, win=True):
    """Usa pe flanc: 2 rosturi verticale negre (1,0 m intre ele) + geam mic."""
    zc = (z0 + z1) * 0.5
    for dx in (-0.5, 0.5):
        b.box((x + dx, side * (TR_HW + 0.012), zc), (0.05, 0.05, z1 - z0), VOLCANIC_BLACK)
    if win:
        _tr_window(b, x, side, z1 - 0.62, 0.50, 0.62)


def _tr_louvre(b, x, side, z0, z1, w=1.3, slats=5):
    """Grila de aerisire: `slats` lamele negre orizontale."""
    for i in range(slats):
        z = z0 + (z1 - z0) * i / (slats - 1)
        b.box((x, side * (TR_HW + 0.02), z), (w, 0.04, 0.07), VOLCANIC_BLACK)


def _tr_buffers(b, hl):
    """Grinda de capat + 2 tampoane (ax r 0,11, taler r 0,20) pe fiecare capat;
    capatul total al piesei = hl + TR_BUF."""
    for sx in (-1.0, 1.0):
        b.box((sx * (hl + 0.05), 0.0, 1.05), (0.10, 2.60, 0.30), VOLCANIC_BLACK)
        for sy in (-1.0, 1.0):
            b.cylinder((sx * (hl + 0.20), sy * 1.00, 1.05), 0.11, 0.30, VOLCANIC_BLACK,
                       segments=8, axis="X")
            b.cylinder((sx * (hl + TR_BUF - 0.03), sy * 1.00, 1.05), 0.20, 0.06,
                       TR_GREY, segments=8, axis="X")


def _tr_underframe(b, hl, xs, box_l=1.2):
    """Sasiu continuu sub talpa + cutii/rezervoare la x din `xs` (cate 2, pe parte)."""
    b.box((0.0, 0.0, 0.87), (2 * hl - 0.3, 2.40, 0.16), VOLCANIC_BLACK)
    for x in xs:
        for sy in (-1.0, 1.0):
            b.box((x, sy * 0.95, 0.60), (box_l, 0.46, 0.40), VOLCANIC_BLACK)


def _tr_pantograph(b, x, raised, top=4.40, half=1.75):
    """Pantograf MARE, ROMB in plan laterala (~3,5 m = ~1/3 din loco): postament
    pe 4 izolatori rosii, 2 romburi de brate rosii (y = +-0,5) groase de 14 cm,
    bara de captare neagra pe Y (2,0 m) cu cornite, tije negre de ax.
    `raised`: varful rombului la `top`; altfel pliat (romb turtit, ~3,95 m)."""
    for sx in (-0.9, 0.9):
        for sy in (-0.55, 0.55):
            b.cylinder((x + sx, sy, 3.52), 0.08, 0.22, CAR_RED, segments=6)
    b.box((x, 0.0, 3.65), (2.20, 1.40, 0.10), VOLCANIC_BLACK)       # postament
    zb = 3.72
    zt = top - 0.07 if raised else 3.98
    zk = zb + (zt - zb) * 0.38
    for sy in (-0.5, 0.5):
        pl = (x - half, sy, zk)
        pr = (x + half, sy, zk)
        pb = (x, sy, zb)
        pt = (x, sy, zt)
        for p, q in ((pb, pl), (pl, pt), (pt, pr), (pr, pb)):
            b.beam(p, q, 0.19, CAR_RED)
        b.box((x, sy, zb + 0.06), (0.30, 0.20, 0.12), CAR_RED)       # articulatie jos
    b.beam((x, 0.0, zb), (x, 0.0, zt), (0.06, 0.06), VOLCANIC_BLACK)
    b.beam((x - half, 0.0, zk), (x + half, 0.0, zk), (0.06, 0.06), VOLCANIC_BLACK)
    b.beam((x, -1.00, zt + 0.07), (x, 1.00, zt + 0.07), 0.09, VOLCANIC_BLACK)   # bara de captare
    for sy in (-1.0, 1.0):
        b.beam((x, sy * 1.00, zt + 0.07), (x, sy * 1.15, zt - 0.03), 0.07, VOLCANIC_BLACK)


def _tr_gangway(b, sx, hl, z0=1.70, z1=3.05):
    """Capat de vagon cu tambuchi de trecere: rama rosie + panou negru de 1,6 m
    iesit 18 cm."""
    b.box((sx * (hl + 0.005), 0.0, (z0 + z1) * 0.5), (0.04, 1.80, z1 - z0 + 0.20), CAR_RED)
    b.box((sx * (hl + 0.09), 0.0, (z0 + z1) * 0.5), (0.18, 1.60, z1 - z0), VOLCANIC_BLACK)


def build_train_loco():
    """`Train_Loco`: LOCOMOTIVA ELECTRICA romaneasca, CAR_RED cu banda gri lata, ~10,8 m.

    LISTA DE ELEMENTE (decuparea `ro_train.png`, scrisa INAINTE de geometrie;
    scara de joc, nu cifrele din kit):
      1) caroserie 10,0 m (hl 5,0) x 2,8 m, streasina 3,0, coama 3,40; acoperis
         gri bombat; inaltime fara pantograf ~3,6 m
      2) BANDA GRI LATA jos, z 0,95..1,50 (~27% din flanc, iese 2 cm) +
         LINIE FOAM_WHITE de 6 cm la limita rosu/gri (nu galben: slot de masini)
      3) per parte (de la coada): usa cu geam, fereastra 1,05x0,8, grila 5
         lamele, fereastra, grila, fereastra, usa cu geam = 2 usi + 3 ferestre
         + 2 grile pe parte
      4) cabine la ambele capete: 2 parbrize (0,84 x 0,80), 3 faruri albe,
         grinda de capat, 2 tampoane
      5) 2 PANTOGRAFE ROMB de ~3,5 m (aprox 1/3 din loco) pe postament si 4
         izolatori: unul RIDICAT (varf 4,4 m), unul PLIAT (varf ~4,0 m)
      6) cutie de rezistente cu 4 lamele pe acoperis (x = 0) + 2 cabluri laterale
      7) 2 BOGHIURI x 2 osii = 8 ROTI (r 0,45), motoare, lonjeroane, travers
      8) sasiu negru + 4 cutii intre boghiuri
    Cote tinta: ~10,8 x 2,9 x 3,6 (4,4 cu pantograf). Sloturi: CAR_RED 14,
    ASPHALT_EDGE 6, VOLCANIC_BLACK 20, FOAM_WHITE 22.
    """
    b = Builder()
    hl = 5.0
    eave, peak = 3.00, 3.40
    _tr_body(b, hl, eave, peak)
    for cx in (-3.4, 3.4):                                  # 7) boghiuri
        _tr_bogie(b, cx, 2.4, motor=True)
    _tr_underframe(b, hl, (-1.44, 1.44))                    # 8)
    for side in (-1.0, 1.0):                                # 3) flancurile
        _tr_door(b, -4.2, side, 1.55, 3.0)
        _tr_door(b, 4.2, side, 1.55, 3.0)
        for x in (-2.8, 0.2, 3.0):
            _tr_window(b, x, side, 2.40, 1.05, 0.80)
        for x in (-1.3, 1.6):
            _tr_louvre(b, x, side, 1.90, 2.75, w=1.1)
    for sx in (-1.0, 1.0):                                  # 4) capetele
        for sy in (-1.0, 1.0):
            b.box((sx * (hl + 0.03), sy * 0.62, 2.40), (0.06, 0.98, 0.94), CAR_RED)
            b.box((sx * (hl + 0.06), sy * 0.62, 2.40), (0.06, 0.84, 0.80), VOLCANIC_BLACK)
            b.box((sx * (hl + 0.025), sy * 1.10, 1.25), (0.05, 0.26, 0.16), FOAM_WHITE)
        b.box((sx * (hl + 0.025), 0.0, 3.30), (0.05, 0.26, 0.16), FOAM_WHITE)
    _tr_buffers(b, hl)
    _tr_pantograph(b, -2.15, True)                          # 5)
    _tr_pantograph(b, 2.15, False)
    b.box((0.0, 0.0, 3.46), (0.90, 1.00, 0.16), VOLCANIC_BLACK)   # 6)
    for k in range(4):
        b.box((-0.30 + k * 0.20, 0.0, 3.56), (0.05, 0.90, 0.05), TR_GREY)
    for sy in (-1.0, 1.0):
        b.beam((-4.4, sy * 1.00, 3.15), (4.4, sy * 1.00, 3.15), (0.05, 0.05), VOLCANIC_BLACK)
    return [b.to_object("Train_Loco")]


def build_train_wagon():
    """`Train_Wagon`: VAGON DE CALATORI rosu cu banda gri lata, ~8,3 m.

    LISTA DE ELEMENTE (decuparea `ro_train.png`, scrisa INAINTE de geometrie):
      1) acelasi corp ca locomotiva: banda gri 0,95..1,50 + linie FOAM_WHITE,
         corp rosu, acoperis gri bombat, caroserie 7,5 m x 2,8 m, coama 3,45
      2) per parte: 4 ferestre mari 1,0 x 0,9 (pas 1,3 m) intre 2 usi cu geam
         (decuparea: 3 ferestre + usa); fara ovalul cu text
      3) 3 guri de aerisire negre pe acoperis (z pana la 3,55)
      4) tambuchi de trecere la ambele capete (panou negru + rama rosie),
         grinda de capat, 2 tampoane
      5) 2 BOGHIURI x 2 osii = 8 ROTI (r 0,45)
      6) sasiu negru + 2 cutii
    Cote tinta: 8,3 x 2,9 x 3,6 m. Sloturi: CAR_RED 14, ASPHALT_EDGE 6,
    VOLCANIC_BLACK 20, FOAM_WHITE 22.
    """
    b = Builder()
    hl = 3.75
    eave, peak = 3.00, 3.45
    _tr_body(b, hl, eave, peak)
    for cx in (-2.5, 2.5):
        _tr_bogie(b, cx, 2.2, motor=False)
    _tr_underframe(b, hl, (0.0,), box_l=1.0)
    for side in (-1.0, 1.0):
        _tr_door(b, -3.2, side, 1.55, 3.0)
        _tr_door(b, 3.2, side, 1.55, 3.0)
        for x in (-2.0, -0.7, 0.7, 2.0):
            _tr_window(b, x, side, 2.40, 1.0, 0.90)
    for x in (-2.0, 0.0, 2.0):
        b.box((x, 0.0, 3.52), (0.70, 0.40, 0.12), VOLCANIC_BLACK)
    for sx in (-1.0, 1.0):
        _tr_gangway(b, sx, hl)
    _tr_buffers(b, hl)
    return [b.to_object("Train_Wagon")]


def build_train_tender():
    """`Train_Tender`: VAGON DE BAGAJE scurt, 5,0 m (nodul trebuie sa existe:
    TrainHazard arunca toata garnitura daca lipseste; tiparul PeruRail).

    LISTA DE ELEMENTE (nu e pe decupare; acelasi limbaj ca vagonul):
      1) acelasi corp (banda gri + linie alba, corp rosu, acoperis gri, coama
         3,45), caroseria 4,2 m + 2 x 0,4 m tampoane
      2) per parte: 1 usa mare de bagaje (2 rosturi la 1,6 m) si 2 ferestre mici
      3) o gura de aerisire pe acoperis
      4) tambuchi de trecere la ambele capete, grinda de capat, 2 tampoane
      5) 2 osii separate = 4 roti (r 0,45), la x = +-1,25, cu lonjeroane
      6) sasiu negru
    Sloturi: CAR_RED 14, ASPHALT_EDGE 6, VOLCANIC_BLACK 20, FOAM_WHITE 22.
    """
    b = Builder()
    hl = 2.1
    eave, peak = 3.00, 3.45
    _tr_body(b, hl, eave, peak)
    for dx in (-1.25, 1.25):
        _tr_wheelset(b, dx)
    for sy in (-1.0, 1.0):
        b.box((0.0, sy * 0.68, 0.62), (2.1, 0.14, 0.30), VOLCANIC_BLACK)
        b.box((0.0, sy * 0.68, 0.80), (3.2, 0.12, 0.10), VOLCANIC_BLACK)
    b.box((0.0, 0.0, 0.87), (2 * hl - 0.3, 2.40, 0.16), VOLCANIC_BLACK)
    for side in (-1.0, 1.0):
        for dx in (-0.8, 0.8):                     # usa de bagaje: 2 rosturi
            b.box((dx, side * (TR_HW + 0.012), 2.30), (0.05, 0.05, 1.50), VOLCANIC_BLACK)
        for x in (-1.5, 1.5):
            _tr_window(b, x, side, 2.50, 0.50, 0.50)
    b.box((0.0, 0.0, 3.52), (0.70, 0.40, 0.12), VOLCANIC_BLACK)
    for sx in (-1.0, 1.0):
        _tr_gangway(b, sx, hl)
    _tr_buffers(b, hl)
    return [b.to_object("Train_Tender")]


def _emit_train():
    """Cele trei noduri pleaca intr-un GLB, cu offsetul de origine calculat O
    DATA pe ansamblu (talpa rotilor la z = 0, XY pastrat: fiecare piesa e deja
    centrata pe axa ei, ecartamentul pe y = 0). `finish` per nod ar desface
    piesele (memoria finish-recentreaza-fiecare-nod-separat)."""
    objs = build_train_loco() + build_train_tender() + build_train_wagon()
    _emit(objs, "vehicles/ro_train.glb", AO_TRAIN, bevel=0.02, smooth=40.0)


# ---------------------------------------------------------------------------
# cable_cabin_large (valul 3, tf-h)
# ---------------------------------------------------------------------------

AO_CABIN = dict(samples=20, dist=1.4, gradient="vertical", low=0.70, high=1.0,
                power=0.8, floor=0.35, z_range=(0.0, 7.5))

# sectiunile cabinei de jos in sus: (z, semi-lungime X, semi-latime Y, raza coltului)
# ~4,1 x 3,3 x 3,3 m; podea plata, burta la z 1,3, acoperis usor bombat
CAB_SECT = [(0.00, 1.70, 1.35, 0.45), (0.12, 1.88, 1.52, 0.46), (0.55, 2.00, 1.62, 0.46),
            (1.30, 2.05, 1.65, 0.46), (2.40, 2.02, 1.62, 0.46), (3.00, 1.88, 1.48, 0.46),
            (3.15, 1.65, 1.28, 0.45), (3.25, 1.40, 1.05, 0.42), (3.30, 1.20, 0.85, 0.40)]
CAB_ARC = 4   # segmente pe arcul fiecarui colt


def _cab_dims(z):
    """(hx, hy, r) interpolat liniar pe CAB_SECT la cota z (punctele inelului
    sunt liniare in aceste valori, deci inelul interpolat e exact)."""
    for a, c in zip(CAB_SECT, CAB_SECT[1:]):
        if a[0] <= z <= c[0]:
            t = (z - a[0]) / (c[0] - a[0])
            return tuple(a[i] + (c[i] - a[i]) * t for i in (1, 2, 3))
    return CAB_SECT[-1][1:]


def _cab_corner_centers(hx, hy, r):
    return [(hx - r, hy - r, 0.0), (-(hx - r), hy - r, 90.0),
            (-(hx - r), -(hy - r), 180.0), (hx - r, -(hy - r), 270.0)]


def _cab_ring(z, grow=0.0):
    """Inel dreptunghi cu colturi ROTUNJITE (4 arce x (CAB_ARC+1) puncte = 20),
    antiorar vazut de sus; `grow` il dilata."""
    hx, hy, r = _cab_dims(z)
    hx += grow
    hy += grow
    r += grow
    pts = []
    for cx, cy, a0 in _cab_corner_centers(hx, hy, r):
        for k in range(CAB_ARC + 1):
            a = math.radians(a0 + 90.0 * k / CAB_ARC)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a), z))
    return pts


def _cab_surface(z, kind, f):
    """Punct (x, y) + normala exterioara pe suprafata la cota z.
    'corner': f = indexul coltului 0..3 (la 45 grade pe arc);
    'long': f = (fata +-1 pe Y, t) cu t = 0 la x = +(hx-r) .. 1 la -(hx-r);
    'short': f = (fata +-1 pe X, t) cu t = 0 la y = +(hy-r) .. 1 la -(hy-r)."""
    hx, hy, r = _cab_dims(z)
    if kind == "corner":
        cx, cy, a0 = _cab_corner_centers(hx, hy, r)[f]
        a = math.radians(a0 + 45.0)
        n = (math.cos(a), math.sin(a))
        return (cx + r * n[0], cy + r * n[1]), n
    face, t = f
    if kind == "long":
        x = (hx - r) * (1.0 - 2.0 * t)
        return (x, face * hy), (0.0, float(face))
    y = (hy - r) * (1.0 - 2.0 * t)
    return (face * hx, y), (float(face), 0.0)


def _cab_post(b, kind, f, z_levels, w, off=0.055):
    """Montant rosu LAT (w) pe suprafata, urmareste profilul pe toate cotele:
    sectiune de 4 puncte extrudata pe z_levels (ring_stack)."""
    rings = []
    for z in z_levels:
        (px, py), (nx, ny) = _cab_surface(z, kind, f)
        tx, ty = -ny, nx          # tangenta antiorara
        h = w * 0.5
        sec = [(-0.01, -h), (off, -h), (off, h), (-0.01, h)]     # (n, t)
        rings.append([(px + nx * a + tx * c, py + ny * a + ty * c, z) for a, c in sec])
    ring_stack(b, rings, CAR_RED)


def build_cable_cabin_large():
    """`cable_cabin_large`: cabina MARE a telecabinei de la Balea (~30 de oameni),
    CAR_RED, ~4,2 x 3,4 x 3,3 m (aproape un CUB), cu brat in A si cărucior orizontal.

    LISTA DE ELEMENTE (decuparea `cable_cabin_large.png`, scrisa INAINTE de
    geometrie; cota 5,5 x 3,2 x 3,0 din kit e ANULATA de coordonator):
      1) corp rosu loftat din 9 sectiuni, colturi ROTUNJITE PE VERTICALA (raza
         0,46 m, 4 arce x 5 puncte), podea plata, burta la z 1,3, acoperis
         usor BOMBAT (z 3,0 -> 3,3)
      2) BRAU ROSU PLIN jos, z 0..1,35 (~40% din 3,3)
      3) GEAMURI = ~50% din inaltime (z 1,38..3,0), panouri inalte intre
         montanti, din fete VOLCANIC_BLACK; sunt ADANCITE ~4 cm fata de montanti
         (geamul 1,5 cm peste corp, montantul 5,5 cm); 4 panouri pe fata lunga
         (3 montanti), 3 pe cea scurta (2 montanti)
      4) MONTANTI rosii LATI (0,22 m) pe fete + 4 montanti de colt CURBATI (0,30),
         de la burta pana la umar; rame orizontale rosii sus si jos de geam
      5) ramă de prindere pe acoperis (patrat 1,9 x 1,2, 4 picioare)
      6) BRAT = stalp in A (4 picioare care se strang in sus, 2 randuri de
         traverse pe X si Y) + coloana ingusta + 2 diagonale spre carucior
      7) CARUCIOR = GRINDA JOASA de 3,0 m pe X (paralela cu cablul), 2 obraji,
         4 ROTI vizibile (r 0,28) pe linia cablului
    Cote tinta: ~4,3 x 3,4 x 7,2 m in total, originea pe LINIA CABLULUI (varful
    rotilor, y = 0 in glTF), cablul pe X. Noduri: Cabin_Body CAR_RED 14 (corp +
    montanti), Cabin_Glass VOLCANIC_BLACK 20, Cabin_Cart ASPHALT_EDGE 6
    (+ VOLCANIC_BLACK la roti).
    """
    body, glass, cart = Builder(), Builder(), Builder()
    zs = [s[0] for s in CAB_SECT]
    ring_stack(body, [_cab_ring(z) for z in zs], CAR_RED)                       # 1), 2)
    gz = [1.38, 1.65, 2.0, 2.4, 2.75, 3.0]
    ring_stack(glass, [_cab_ring(z, 0.015) for z in gz], VOLCANIC_BLACK,
               cap_top=False, cap_bottom=False)                                 # 3)
    for z in (1.34, 3.04):                                                       # rame orizontale
        ring_stack(body, [_cab_ring(z - 0.05, 0.055), _cab_ring(z + 0.05, 0.055)],
                   CAR_RED, cap_top=False, cap_bottom=False)
    pz = [1.20, 1.38, 1.65, 2.0, 2.4, 2.75, 3.0, 3.12]
    for c in range(4):                                                           # 4) colt
        _cab_post(body, "corner", c, pz, 0.30, off=0.06)
    for face in (1, -1):
        for t in (0.2, 0.5, 0.8):
            _cab_post(body, "long", (face, t), pz, 0.22)
        for t in (0.29, 0.71):
            _cab_post(body, "short", (face, t), pz, 0.22)
    # 5) rama de pe acoperis
    fx, fy, zr = 0.95, 0.60, 3.38
    for sy in (-1.0, 1.0):
        cart.beam((-fx, sy * fy, zr), (fx, sy * fy, zr), 0.11, TR_GREY)
    for sx in (-1.0, 1.0):
        cart.beam((sx * fx, -fy, zr), (sx * fx, fy, zr), 0.11, TR_GREY)
        for sy in (-1.0, 1.0):
            cart.box((sx * fx, sy * fy, zr - 0.05), (0.12, 0.12, 0.16), TR_GREY)
    # 6) bratul in A: 4 picioare, traverse, coloana, diagonale
    z_b, z_c = zr, 5.35
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            cart.beam((sx * fx, sy * fy, z_b), (sx * 0.17, sy * 0.13, z_c), 0.20, TR_GREY)
    for zb in (4.0, 4.65):
        t = (zb - z_b) / (z_c - z_b)
        hx_ = fx + (0.17 - fx) * t
        hy_ = fy + (0.13 - fy) * t
        cart.beam((-hx_, 0.0, zb), (hx_, 0.0, zb), (0.10, 0.12), TR_GREY)
        cart.beam((0.0, -hy_, zb), (0.0, hy_, zb), (0.10, 0.12), TR_GREY)
    cart.beam((0.0, 0.0, z_c - 0.05), (0.0, 0.0, 6.55), (0.40, 0.30), TR_GREY)
    for sx in (-1.0, 1.0):
        cart.beam((sx * 0.10, 0.0, 6.0), (sx * 1.15, 0.0, 6.52), (0.12, 0.14), TR_GREY)
    # 7) caruciorul: grinda joasa de-a lungul cablului, obraji, 4 roti
    cart.box((0.0, 0.0, 6.60), (3.00, 0.50, 0.24), TR_GREY)
    for sy in (-1.0, 1.0):
        cart.box((0.0, sy * 0.19, 6.88), (2.80, 0.05, 0.36), TR_GREY)
    for x in (-1.2, -0.4, 0.4, 1.2):
        cart.cylinder((x, 0.0, 6.97), 0.28, 0.46, VOLCANIC_BLACK, segments=12, axis="Y")
        cart.cylinder((x, 0.0, 6.97), 0.06, 0.52, TR_GREY, segments=6, axis="Y")
    return [body.to_object("Cabin_Body"), glass.to_object("Cabin_Glass"),
            cart.to_object("Cabin_Cart")]


def _emit_cabin():
    """Ca emit_tf, dar OFFSETUL de origine pune VARFUL rotilor (linia cablului)
    la y = 0, iar geometria atarna sub el (`verify_glb --origin=rim`). Baza se
    construieste la z = 0 ca gradientul de AO sa porneasca de la podea; dupa
    finish se coboara tot ansamblul cu inaltimea maxima."""
    objs = build_cable_cabin_large()
    total, per_node = 0, {}
    for o in objs:
        bw = 0.015 if o.name.endswith("_Cart") else (0.0 if o.name.endswith("_Glass") else 0.02)
        st = finish(o, bevel=bw, bevel_angle=30.0, ao=AO_CABIN, origin=None, smooth_angle=50.0)
        total += st["tris"]
        per_node[o.name] = st["tris"]
    top = max(v.co.z for o in objs for v in o.data.vertices)
    for o in objs:
        for v in o.data.vertices:
            v.co.z -= top
    xs = [v.co.x for o in objs for v in o.data.vertices]
    ys = [v.co.y for o in objs for v in o.data.vertices]
    zs = [v.co.z for o in objs for v in o.data.vertices]
    dims = Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))
    _, sz = export_glb(objs, "transfagarasan/vehicles/cable_cabin_large.glb")
    TF_RESULTS.append(("vehicles/cable_cabin_large.glb", total, dims, per_node, sz / 1024.0))
    clear_built()


# ---------------------------------------------------------------------------

def _emit(objs, path, ao, bevels=None, smooth=50.0, bevel=0.0):
    emit_tf(objs, path, ao, keep_xy=True, bevel=bevel, bevels=bevels, smooth_angle=smooth)
    clear_built()


clear_built()
if not ONLY or ONLY == "parked_car_a":
    _emit(build_parked_car_a(), "vehicles/parked_car_a.glb", AO_CAR,
          bevels={"_Trim": 0.02, "_Tyre": 0.05, "_Hub": 0.008, "_Lamp": 0.008, "_Tail": 0.008})
if not ONLY or ONLY == "parked_car_b":
    _emit(build_parked_car_b(), "vehicles/parked_car_b.glb", AO_CAR,
          bevels={"_Trim": 0.02, "_Tyre": 0.05, "_Hub": 0.008, "_Lamp": 0.008, "_Tail": 0.008})
if not ONLY or ONLY == "motorbike":
    _emit(build_motorbike(), "vehicles/motorbike.glb", AO_MOTO,
          bevels={"_Body": 0.0, "_Metal": 0.006, "_Dark": 0.006}, smooth=40.0)
if not ONLY or ONLY == "ro_train":
    _emit_train()
if not ONLY or ONLY == "cable_cabin_large":
    _emit_cabin()
report_tf()
