"""Compunere decupare | randare pentru kitul podului rosu -- Python de SISTEM (cu
PIL; interpretorul lui Blender nu are PIL). Apelat din `preview_sf_bridge.py`.

    python tools/blender/compose_sf_bridge.py --compare <decupare.png> \
        --render <randare.png> --out <png> --height 900

Refoloseste `compare` din compose_transfagarasan.py (acelasi fundal #C4C4C4).
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from compose_transfagarasan import compare  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--compare", required=True)
    ap.add_argument("--render", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--height", type=int, default=900)
    a = ap.parse_args()
    compare(a.compare, a.render, a.out, a.height)


if __name__ == "__main__":
    main()
