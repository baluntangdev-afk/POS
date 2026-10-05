#!/usr/bin/env python3
r"""Downscale oversized product images in place.

Product photos are uploaded at full camera/export resolution (up to 1500x1500,
3.6 MB) but render into grid tiles 210dp wide. That costs transfer bandwidth on
every catalog fetch and a UI-thread decode on the kiosk.

Filenames and extensions are preserved exactly: products.image_url stores the
full URL including the extension (e.g. /static/products/hot_dark_mocha.webp),
so renaming or converting formats would break every row pointing at the file.
Re-encoding happens in the original format.

Dry run by default. Pass --apply to write. Originals are copied to a backup
directory first unless --no-backup is given.

Requires Pillow:  pip install Pillow

Usage:
    python resize-product-images.py                      # dry run, repo images
    python resize-product-images.py --apply
    python resize-product-images.py --dir C:\POSKiosk\backend\public\products --apply
"""

import argparse
import os
import shutil
import sys
from datetime import datetime

try:
    from PIL import Image, ImageOps
except ImportError:
    sys.exit("Pillow is required:  pip install Pillow")

SUPPORTED = {".jpg": "JPEG", ".jpeg": "JPEG", ".png": "PNG", ".webp": "WEBP"}
DEFAULT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "public", "products")


def human(n):
    for unit in ("B", "KB", "MB"):
        if abs(n) < 1024 or unit == "MB":
            return f"{n:,.0f} {unit}" if unit == "B" else f"{n/1.0:,.1f} {unit}"
        n /= 1024.0


def size_str(n):
    if n >= 1024 * 1024:
        return f"{n/1024/1024:.1f} MB"
    return f"{n/1024:.0f} KB"


def has_alpha(img):
    """True when the image carries transparency that actually varies."""
    if img.mode not in ("RGBA", "LA", "PA") and "transparency" not in img.info:
        return False
    try:
        alpha = img.convert("RGBA").getchannel("A")
        return alpha.getextrema()[0] < 255
    except Exception:
        return True


def encode_args(fmt, img, quality):
    if fmt == "JPEG":
        return {"quality": quality, "optimize": True, "progressive": True}
    if fmt == "WEBP":
        return {"quality": quality, "method": 6}
    return {"optimize": True, "compress_level": 9}  # PNG


def process(path, fmt, args, backup_dir):
    """Returns (before, after, note) or None when the file is left alone."""
    before = os.path.getsize(path)

    with Image.open(path) as src:
        src = ImageOps.exif_transpose(src)
        w, h = src.size
        longest = max(w, h)

        # Idempotent: already small enough in both pixels and bytes.
        if longest <= args.max_dim and before <= args.skip_under:
            return None

        if longest > args.max_dim:
            scale = args.max_dim / float(longest)
            new_size = (max(1, round(w * scale)), max(1, round(h * scale)))
            out = src.resize(new_size, Image.Resampling.LANCZOS)
        else:
            new_size = (w, h)
            out = src.copy()

        note = ""
        if fmt == "JPEG" and out.mode not in ("RGB", "L"):
            flat = Image.new("RGB", out.size, (255, 255, 255))
            flat.paste(out, mask=out.convert("RGBA").getchannel("A"))
            out = flat
        elif fmt == "PNG" and not has_alpha(src):
            note = "opaque PNG - would shrink far more as JPEG"

        tmp = path + ".resized.tmp"
        out.save(tmp, fmt, **encode_args(fmt, out, args.quality))

    after = os.path.getsize(tmp)

    # Never let a re-encode make a file bigger. Some sources are already well
    # compressed at high resolution, and re-encoding them costs bytes even
    # after the pixel count drops. memCacheWidth on the Flutter side already
    # caps decode cost, so the only win left here is transfer size.
    #
    # When no downscale happened, also require a real saving -- otherwise a
    # second run re-encodes already-processed files for nothing, and repeated
    # JPEG generations lose quality each time.
    resized = new_size != (w, h)
    if after >= before or (not resized and after > before * 0.95):
        os.remove(tmp)
        return None

    if not args.apply:
        os.remove(tmp)
        return (before, after, note, (w, h), new_size)

    if backup_dir:
        os.makedirs(backup_dir, exist_ok=True)
        shutil.copy2(path, os.path.join(backup_dir, os.path.basename(path)))
    os.replace(tmp, path)
    return (before, after, note, (w, h), new_size)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--dir", default=os.path.normpath(DEFAULT_DIR),
                   help="image directory (default: be/public/products)")
    p.add_argument("--max-dim", type=int, default=800,
                   help="longest edge in px (default: 800; tiles render at 210dp)")
    p.add_argument("--quality", type=int, default=82, help="JPEG/WebP quality (default: 82)")
    p.add_argument("--skip-under", type=int, default=120 * 1024,
                   help="leave files smaller than this alone (default: 120 KB)")
    p.add_argument("--backup-dir", default=None,
                   help="where originals go (default: <dir>/_originals_<timestamp>)")
    p.add_argument("--no-backup", action="store_true", help="overwrite without keeping originals")
    p.add_argument("--apply", action="store_true", help="actually write (default is a dry run)")
    args = p.parse_args()

    if not os.path.isdir(args.dir):
        sys.exit(f"Not a directory: {args.dir}")

    backup_dir = None
    if args.apply and not args.no_backup:
        backup_dir = args.backup_dir or os.path.join(
            args.dir, "_originals_" + datetime.now().strftime("%Y%m%d_%H%M%S"))

    files = sorted(f for f in os.listdir(args.dir)
                   if os.path.splitext(f)[1].lower() in SUPPORTED
                   and os.path.isfile(os.path.join(args.dir, f)))

    print(f"Directory : {args.dir}")
    print(f"Images    : {len(files)}")
    print(f"Target    : longest edge {args.max_dim}px, quality {args.quality}")
    print(f"Mode      : {'APPLY' if args.apply else 'DRY RUN (use --apply to write)'}")
    if backup_dir:
        print(f"Backup    : {backup_dir}")
    print()

    total_before = total_after = 0
    changed = skipped = failed = 0
    notes = []

    for name in files:
        path = os.path.join(args.dir, name)
        fmt = SUPPORTED[os.path.splitext(name)[1].lower()]
        try:
            result = process(path, fmt, args, backup_dir)
        except Exception as e:
            print(f"  FAILED   {name:<34} {e}")
            failed += 1
            continue

        if result is None:
            skipped += 1
            total_before += os.path.getsize(path)
            total_after += os.path.getsize(path)
            continue

        before, after, note, old_size, new_size = result
        changed += 1
        total_before += before
        total_after += after
        pct = (1 - after / before) * 100
        dims = f"{old_size[0]}x{old_size[1]}"
        if new_size != old_size:
            dims += f" -> {new_size[0]}x{new_size[1]}"
        print(f"  {name:<34} {size_str(before):>9} -> {size_str(after):>9}  ({pct:4.0f}% less)  {dims}")
        if note:
            notes.append((name, note))

    print()
    print(f"Changed {changed}, left alone {skipped}" + (f", failed {failed}" if failed else ""))
    print(f"Total   {size_str(total_before)} -> {size_str(total_after)}", end="")
    if total_before:
        print(f"  ({(1 - total_after/total_before)*100:.0f}% less)")
    else:
        print()

    if notes:
        print()
        print("Worth re-uploading as JPEG (no transparency to preserve):")
        for name, note in notes:
            print(f"  {name}")

    if not args.apply and changed:
        print()
        print("Dry run - nothing was written. Re-run with --apply.")


if __name__ == "__main__":
    main()
