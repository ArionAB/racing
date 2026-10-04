"""Penita pentru piese compuse Monument Valley (cladiri, vehicule, oameni).

`Pen(b, M)` imbraca un `Builder` cu o transformare 4x4 (rotatie + mutare): se
modeleaza o data "cu fata spre +Y" si se pune cu M pe fiecare latura/persoana.
Primitivele rotunde au segmente EXPLICITE (brief §0 pct. 10).

Se incarca cu exec dupa dio_lib si monument_shapes (vezi build_monument_*.py).
"""

import math
from mathutils import Vector, Matrix


class Pen:
    def __init__(self, b, M=None):
        self.b = b
        self.M = Matrix.Identity(4) if M is None else M

    def P(self, p):
        return self.M @ Vector(p)

    def box(self, center, size, slot, rot=None):
        """Cutie centrata, dimensiuni locale; `rot` = Matrix 3x3 locala."""
        R = self.M.to_3x3() @ (Matrix.Identity(3) if rot is None else rot)
        return self.b.box(self.P(center), size, slot, rotation=R)

    def beam(self, p1, p2, thick, slot, up=None):
        u = None if up is None else self.M.to_3x3() @ Vector(up)
        return self.b.beam(self.P(p1), self.P(p2), thick, slot, up=u)

    def tube(self, p1, p2, r1, r2, slot, seg=8):
        """Con trunchi cu capace intre doua puncte (r1 la p1, r2 la p2)."""
        a, c = self.P(p1), self.P(p2)
        d = c - a
        if d.length < 1e-6:
            return set()
        rot = d.normalized().to_track_quat("Z", "Y").to_matrix().to_4x4()
        mat = Matrix.Translation((a + c) * 0.5) @ rot
        res = bmesh.ops.create_cone(
            self.b.bm, cap_ends=True, cap_tris=False, segments=seg,
            radius1=r1, radius2=r2, depth=d.length, matrix=mat)
        return self.b._tag(res["verts"], slot)

    def ball(self, c, r, slot, seg=8, rings=6, scale=(1.0, 1.0, 1.0)):
        """Sfera/elipsoid UV cu segmente explicite."""
        mat = (Matrix.Translation(self.P(c)) @ self.M.to_3x3().to_4x4()
               @ Matrix.Diagonal(Vector((r * scale[0], r * scale[1], r * scale[2], 1.0))))
        res = bmesh.ops.create_uvsphere(self.b.bm, u_segments=seg, v_segments=rings,
                                        radius=1.0, matrix=mat)
        return self.b._tag(res["verts"], slot)

    def loft(self, bottom, z0, top, z1, slot, cap_bottom=True):
        """loft() din monument_shapes, cu contururile 2D si cotele locale."""
        n = len(bottom)
        for i in range(n):
            j = (i + 1) % n
            vs = [self.P((bottom[i][0], bottom[i][1], z0)), self.P((bottom[j][0], bottom[j][1], z0)),
                  self.P((top[j][0], top[j][1], z1)), self.P((top[i][0], top[i][1], z1))]
            f = self.b.bm.faces.new([self.b.bm.verts.new(v) for v in vs])
            f[self.b.slot] = slot
        f = self.b.bm.faces.new([self.b.bm.verts.new(self.P((p[0], p[1], z1))) for p in top])
        f[self.b.slot] = slot
        if cap_bottom:
            f = self.b.bm.faces.new([self.b.bm.verts.new(self.P((p[0], p[1], z0))) for p in reversed(bottom)])
            f[self.b.slot] = slot


def rz(deg):
    return Matrix.Rotation(math.radians(deg), 4, "Z")


def at(x, y, z=0.0, yaw=0.0):
    return Matrix.Translation((x, y, z)) @ rz(yaw)
