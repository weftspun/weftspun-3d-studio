"""Wraps RFD 0064 dataset images as billboard cards in one USD stage.

RFD 0073 records the decision (both RFDs now in
weftspun/request-for-discussion). Each image becomes a flat,
textured quad, alpha cutout, no mesh generation. Cards lay out on a
grid, and each carries its caption as USD metadata (customData), so
a viewer can show it without a second lookup.

Usage:
    python scripts/make_billboard_gallery.py --shards 1 --out-dir apps/usd_viewer_app/public/usd/gallery
"""

import argparse
import io
import time
from pathlib import Path

import pyarrow.parquet as pq
from PIL import Image
from pxr import Usd, UsdGeom, UsdShade, Sdf, UsdUtils

DATASET_DIR = Path("datasets/anime-caption-cc0/data")
THUMB_SIZE = 128
GRID_SPACING = 1.2


def iter_rows(shard_paths):
    for shard_path in shard_paths:
        pf = pq.ParquetFile(shard_path)
        for batch in pf.iter_batches(batch_size=64):
            for row in batch.to_pylist():
                yield row


def make_stage(rows, out_dir: Path, cols: int):
    out_dir.mkdir(parents=True, exist_ok=True)
    tex_dir = out_dir / "tex"
    tex_dir.mkdir(exist_ok=True)

    usda_path = out_dir / "gallery.usda"
    stage = Usd.Stage.CreateNew(str(usda_path))
    UsdGeom.SetStageUpAxis(stage, UsdGeom.Tokens.y)
    root = UsdGeom.Xform.Define(stage, "/Gallery")
    stage.SetDefaultPrim(root.GetPrim())

    count = 0
    total_bytes = 0
    for i, row in enumerate(rows):
        img_field = row.get("image")
        img_bytes = img_field["bytes"] if isinstance(img_field, dict) else img_field
        if not img_bytes:
            continue

        img = Image.open(io.BytesIO(img_bytes)).convert("RGBA")
        img.thumbnail((THUMB_SIZE, THUMB_SIZE))
        tex_name = f"card_{i:05d}.jpg"
        # JPEG, no alpha: the dataset's own art has no transparency
        # need for a "cutout" look here, and JPEG keeps each card
        # under a few KB, which is what makes 15,000 of them
        # feasible to ship at all.
        img.convert("RGB").save(tex_dir / tex_name, "JPEG", quality=72)
        total_bytes += (tex_dir / tex_name).stat().st_size

        card_path = f"/Gallery/Card_{i:05d}"
        card = UsdGeom.Xform.Define(stage, card_path)
        col = i % cols
        row_i = i // cols
        card.AddTranslateOp().Set((col * GRID_SPACING, -row_i * GRID_SPACING, 0.0))

        mesh = UsdGeom.Mesh.Define(stage, f"{card_path}/geom")
        mesh.CreateFaceVertexCountsAttr([4])
        mesh.CreateFaceVertexIndicesAttr([0, 1, 2, 3])
        h = 0.5
        mesh.CreatePointsAttr([(-h, -h, 0), (h, -h, 0), (h, h, 0), (-h, h, 0)])
        mesh.CreateNormalsAttr([(0, 0, 1)] * 4)
        st = UsdGeom.PrimvarsAPI(mesh).CreatePrimvar(
            "st", Sdf.ValueTypeNames.TexCoord2fArray, UsdGeom.Tokens.vertex
        )
        st.Set([(0, 0), (1, 0), (1, 1), (0, 1)])
        mesh.CreateSubdivisionSchemeAttr(UsdGeom.Tokens.none)

        caption = row.get("phi3_caption") or row.get("prompt") or ""
        mesh.GetPrim().SetCustomDataByKey("caption", caption)

        mat = UsdShade.Material.Define(stage, f"{card_path}/mat")
        surface = UsdShade.Shader.Define(stage, f"{card_path}/mat/surface")
        surface.CreateIdAttr("UsdPreviewSurface")
        tex = UsdShade.Shader.Define(stage, f"{card_path}/mat/texture")
        tex.CreateIdAttr("UsdUVTexture")
        tex.CreateInput("file", Sdf.ValueTypeNames.Asset).Set(f"./tex/{tex_name}")
        tex.CreateInput("sourceColorSpace", Sdf.ValueTypeNames.Token).Set("sRGB")
        tex.CreateOutput("rgb", Sdf.ValueTypeNames.Float3)
        surface.CreateInput(
            "diffuseColor", Sdf.ValueTypeNames.Color3f
        ).ConnectToSource(tex.ConnectableAPI(), "rgb")
        surface.CreateOutput("surface", Sdf.ValueTypeNames.Token)
        mat.CreateSurfaceOutput().ConnectToSource(surface.ConnectableAPI(), "surface")
        UsdShade.MaterialBindingAPI(mesh).Bind(mat)

        count += 1

    stage.GetRootLayer().Save()
    return usda_path, count, total_bytes


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--shards", type=int, default=1, help="how many of the 42 parquet shards to process")
    parser.add_argument("--cols", type=int, default=20)
    parser.add_argument("--out-dir", default="apps/usd_viewer_app/public/usd/gallery")
    args = parser.parse_args()

    shard_paths = sorted(DATASET_DIR.glob("train-*.parquet"))[: args.shards]
    print(f"Processing {len(shard_paths)} shard(s): {[p.name for p in shard_paths]}")

    t0 = time.time()
    usda_path, count, total_bytes = make_stage(iter_rows(shard_paths), Path(args.out_dir), args.cols)
    elapsed = time.time() - t0

    usdz_path = usda_path.with_suffix(".usdz")
    packaged = UsdUtils.CreateNewUsdzPackage(str(usda_path), str(usdz_path))

    print(f"cards: {count}")
    print(f"texture bytes: {total_bytes} ({total_bytes / 1e6:.2f} MB)")
    print(f"elapsed: {elapsed:.1f}s ({elapsed / max(count, 1):.3f}s/card)")
    print(f"usda: {usda_path}")
    print(f"usdz packaged: {packaged} -> {usdz_path}")
    if usdz_path.exists():
        print(f"usdz size: {usdz_path.stat().st_size / 1e6:.2f} MB")


if __name__ == "__main__":
    main()
