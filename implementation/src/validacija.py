#!/usr/bin/env python3
import argparse
import hashlib
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable

CHUNK_SIZE = 1024 * 1024

@dataclass(frozen=True)
class FileInfo:
    size: int

def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while True:
            chunk = f.read(CHUNK_SIZE)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()

def iter_files(root: Path) -> Iterable[Path]:
    for p in root.rglob("*"):
        try:
            if p.is_symlink():
                continue
            if p.is_file():
                yield p
        except OSError:
            continue

def build_index(root: Path) -> Dict[str, FileInfo]:
    index: Dict[str, FileInfo] = {}
    for f in iter_files(root):
        rel = str(f.relative_to(root))
        try:
            st = f.stat()
            index[rel] = FileInfo(size=st.st_size)
        except OSError:
            continue
    return index

def audit_dirs(orig: Path, rest: Path) -> int:
    orig = orig.resolve()
    rest = rest.resolve()

    if not orig.exists() or not orig.is_dir():
        print(f"ORIG folder ne postoji ili nije direktorij: {orig}", file=sys.stderr)
        return 2
    if not rest.exists() or not rest.is_dir():
        print(f"RESTORE folder ne postoji ili nije direktorij: {rest}", file=sys.stderr)
        return 2

    orig_index = build_index(orig)
    rest_index = build_index(rest)

    all_keys = sorted(set(orig_index.keys()) | set(rest_index.keys()))

    ok = 0
    missing = 0
    extra = 0
    changed = 0
    errors = 0

    print("--- IZVJESTAJ O INTEGRITETU I CJELOVITOSTI (REKURZIVNO) ---")
    print(f"ORIG:   {orig}")
    print(f"REST:   {rest}")
    print(f"FAJLOVI ORIG: {len(orig_index)} | FAJLOVI REST: {len(rest_index)}")
    print("----------------------------------------------------------")

    for rel in all_keys:
        in_orig = rel in orig_index
        in_rest = rel in rest_index

        if in_orig and not in_rest:
            missing += 1
            print(f"{rel:<70}  NEDOSTAJE")
            continue

        if in_rest and not in_orig:
            extra += 1
            print(f"{rel:<70}  DODATNO")
            continue

        o = orig / rel
        r = rest / rel

        try:
            if orig_index[rel].size != rest_index[rel].size:
                changed += 1
                print(f"{rel:<70}  GRESKA (size mismatch)")
                continue

            oh = sha256_file(o)
            rh = sha256_file(r)

            if oh == rh:
                ok += 1
                print(f"{rel:<70}  OK (identično)")
            else:
                changed += 1
                print(f"{rel:<70}  GRESKA (hash mismatch)")
        except Exception as e:
            errors += 1
            print(f"{rel:<70}  GRESKA (exception: {e})")

    print("----------------------------------------------------------")
    print(f"OK: {ok} | NEDOSTAJE: {missing} | DODATNO: {extra} | PROMIJENJENO: {changed} | ERROR: {errors}")

    if errors > 0:
        return 2
    if missing > 0 or changed > 0 or extra > 0:
        return 4
    return 0

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--orig", required=True)
    ap.add_argument("--rest", required=True)
    args = ap.parse_args()

    code = audit_dirs(Path(args.orig), Path(args.rest))
    sys.exit(code)

if __name__ == "__main__":
    main()
