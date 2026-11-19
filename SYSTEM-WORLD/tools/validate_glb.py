#!/usr/bin/env python3
"""Validate the structure and mobile-safety basics of a binary glTF (GLB).

Uses only the Python standard library. It does not replace Godot import testing.
Run:
  python3 SYSTEM-WORLD/tools/validate_glb.py path/to/model.glb
  python3 SYSTEM-WORLD/tools/validate_glb.py --self-test
"""

from __future__ import annotations

import argparse
import json
import struct
import sys
import tempfile
from pathlib import Path
from typing import Any


COMPONENT_BYTES = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}
TYPE_COMPONENTS = {
    "SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4,
    "MAT2": 4, "MAT3": 9, "MAT4": 16,
}
GLB_MAGIC = b"glTF"
JSON_CHUNK = 0x4E4F534A
BIN_CHUNK = 0x004E4942


class GLBValidationError(ValueError):
    pass


def inspect_glb(path: Path) -> dict[str, Any]:
    data = path.read_bytes()
    if len(data) < 20:
        raise GLBValidationError("file is too small to be a GLB")
    magic, version, declared_length = struct.unpack_from("<4sII", data, 0)
    if magic != GLB_MAGIC:
        raise GLBValidationError("invalid GLB magic; expected 'glTF'")
    if version != 2:
        raise GLBValidationError(f"unsupported GLB container version: {version}")
    if declared_length != len(data):
        raise GLBValidationError(
            f"header length {declared_length} does not match file size {len(data)}"
        )

    offset = 12
    chunks: list[tuple[int, bytes]] = []
    while offset < len(data):
        if offset + 8 > len(data):
            raise GLBValidationError("truncated chunk header")
        chunk_length, chunk_type = struct.unpack_from("<II", data, offset)
        offset += 8
        end = offset + chunk_length
        if end > len(data):
            raise GLBValidationError("chunk exceeds declared GLB length")
        chunks.append((chunk_type, data[offset:end]))
        offset = end
    if not chunks or chunks[0][0] != JSON_CHUNK:
        raise GLBValidationError("first GLB chunk must contain JSON")
    try:
        document = json.loads(chunks[0][1].decode("utf-8").rstrip(" \t\r\n\0"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise GLBValidationError(f"invalid glTF JSON chunk: {exc}") from exc

    asset_version = document.get("asset", {}).get("version")
    if asset_version != "2.0":
        raise GLBValidationError(f"glTF asset.version must be 2.0, got {asset_version!r}")

    binary_chunks = [payload for kind, payload in chunks if kind == BIN_CHUNK]
    binary = binary_chunks[0] if binary_chunks else b""
    buffers = document.get("buffers", [])
    for index, buffer in enumerate(buffers):
        if buffer.get("uri"):
            raise GLBValidationError(
                f"buffer {index} uses an external URI; self-contained GLB expected"
            )
        if index == 0 and int(buffer.get("byteLength", 0)) > len(binary):
            raise GLBValidationError("binary chunk is shorter than buffer.byteLength")

    for index, image in enumerate(document.get("images", [])):
        uri = image.get("uri", "")
        if uri and not uri.startswith("data:"):
            raise GLBValidationError(
                f"image {index} uses an external URI; embed textures before shipping"
            )

    views = document.get("bufferViews", [])
    for index, view in enumerate(views):
        buffer_index = int(view.get("buffer", 0))
        if buffer_index >= len(buffers):
            raise GLBValidationError(f"bufferView {index} references missing buffer")
        start = int(view.get("byteOffset", 0))
        length = int(view.get("byteLength", 0))
        if start < 0 or length < 0:
            raise GLBValidationError(f"bufferView {index} has negative bounds")
        if buffer_index == 0 and start + length > len(binary):
            raise GLBValidationError(f"bufferView {index} exceeds binary chunk")

    accessors = document.get("accessors", [])
    for index, accessor in enumerate(accessors):
        component_size = COMPONENT_BYTES.get(accessor.get("componentType"))
        component_count = TYPE_COMPONENTS.get(accessor.get("type"))
        count = int(accessor.get("count", -1))
        if component_size is None or component_count is None or count < 0:
            raise GLBValidationError(f"accessor {index} has invalid component metadata")
        if "bufferView" not in accessor:
            if "sparse" not in accessor:
                raise GLBValidationError(f"accessor {index} has no bufferView or sparse data")
            continue
        view_index = int(accessor["bufferView"])
        if view_index >= len(views):
            raise GLBValidationError(f"accessor {index} references missing bufferView")
        view = views[view_index]
        element_size = component_size * component_count
        stride = int(view.get("byteStride", element_size))
        accessor_offset = int(accessor.get("byteOffset", 0))
        required = accessor_offset if count == 0 else (
            accessor_offset + (count - 1) * stride + element_size
        )
        if required > int(view.get("byteLength", 0)):
            raise GLBValidationError(f"accessor {index} exceeds its bufferView")

    meshes = document.get("meshes", [])
    if not meshes:
        raise GLBValidationError("no mesh primitives found")
    primitive_count = 0
    triangle_count = 0
    for mesh_index, mesh in enumerate(meshes):
        for primitive in mesh.get("primitives", []):
            primitive_count += 1
            attributes = primitive.get("attributes", {})
            position_index = attributes.get("POSITION")
            if position_index is None or int(position_index) >= len(accessors):
                raise GLBValidationError(
                    f"mesh {mesh_index} primitive has no valid POSITION accessor"
                )
            mode = int(primitive.get("mode", 4))
            if mode == 4:
                if "indices" in primitive:
                    index_accessor = int(primitive["indices"])
                    if index_accessor >= len(accessors):
                        raise GLBValidationError("primitive references missing index accessor")
                    element_count = int(accessors[index_accessor]["count"])
                else:
                    element_count = int(accessors[int(position_index)]["count"])
                triangle_count += element_count // 3

    if primitive_count == 0:
        raise GLBValidationError("meshes contain no primitives")

    skins = document.get("skins", [])
    animations = document.get("animations", [])
    joint_count = sum(len(skin.get("joints", [])) for skin in skins)
    skinned_primitive_count = 0
    for mesh_index, mesh in enumerate(meshes):
        for primitive_index, primitive in enumerate(mesh.get("primitives", [])):
            attributes = primitive.get("attributes", {})
            if "JOINTS_0" in attributes and "WEIGHTS_0" in attributes:
                skinned_primitive_count += 1
                for attribute_name in ("JOINTS_0", "WEIGHTS_0"):
                    accessor_index = int(attributes[attribute_name])
                    if accessor_index >= len(accessors):
                        raise GLBValidationError(
                            f"mesh {mesh_index} primitive {primitive_index} has invalid {attribute_name}"
                        )
    if skins and skinned_primitive_count == 0:
        raise GLBValidationError("skin exists but no mesh primitive contains JOINTS_0 and WEIGHTS_0")

    nodes = document.get("nodes", [])
    joint_nodes = {int(index) for skin in skins for index in skin.get("joints", [])}
    parent_of: dict[int, int] = {}
    for parent_index, node in enumerate(nodes):
        for child_index in node.get("children", []):
            parent_of[int(child_index)] = parent_index
    bone_attached_mesh_count = 0
    for node_index, node in enumerate(nodes):
        if "mesh" not in node or node_index in joint_nodes:
            continue
        parent_index = parent_of.get(node_index)
        visited: set[int] = set()
        while parent_index is not None and parent_index not in visited:
            if parent_index in joint_nodes:
                bone_attached_mesh_count += 1
                break
            visited.add(parent_index)
            parent_index = parent_of.get(parent_index)

    return {
        "file": str(path),
        "glb_version": version,
        "gltf_asset_version": asset_version,
        "file_bytes": len(data),
        "mesh_count": len(meshes),
        "primitive_count": primitive_count,
        "triangle_count": triangle_count,
        "skin_count": len(skins),
        "joint_count": joint_count,
        "skinned_primitive_count": skinned_primitive_count,
        "bone_attached_mesh_count": bone_attached_mesh_count,
        "animation_count": len(animations),
        "embedded_binary_bytes": len(binary),
        "external_resource_uris": 0,
        "status": "structural_validation_passed",
        "note": "Godot import, visual review and device performance remain separate checks.",
    }


def build_test_glb(path: Path) -> None:
    binary = struct.pack("<9f", 0, 0, 0, 1, 0, 0, 0, 1, 0)
    document = {
        "asset": {"version": "2.0", "generator": "SYSTEM GLB validator self-test"},
        "buffers": [{"byteLength": len(binary)}],
        "bufferViews": [{"buffer": 0, "byteOffset": 0, "byteLength": len(binary)}],
        "accessors": [{
            "bufferView": 0, "componentType": 5126, "count": 3, "type": "VEC3"
        }],
        "meshes": [{"primitives": [{"attributes": {"POSITION": 0}, "mode": 4}]}],
        "nodes": [{"mesh": 0}],
        "scenes": [{"nodes": [0]}],
        "scene": 0,
    }
    json_chunk = json.dumps(document, separators=(",", ":")).encode("utf-8")
    json_chunk += b" " * ((4 - len(json_chunk) % 4) % 4)
    binary += b"\0" * ((4 - len(binary) % 4) % 4)
    total = 12 + 8 + len(json_chunk) + 8 + len(binary)
    glb = (
        struct.pack("<4sII", GLB_MAGIC, 2, total)
        + struct.pack("<II", len(json_chunk), JSON_CHUNK) + json_chunk
        + struct.pack("<II", len(binary), BIN_CHUNK) + binary
    )
    path.write_bytes(glb)


def run_self_test() -> None:
    with tempfile.TemporaryDirectory(prefix="system_glb_test_") as folder:
        path = Path(folder) / "validator_fixture.glb"
        build_test_glb(path)
        report = inspect_glb(path)
        assert report["mesh_count"] == 1
        assert report["triangle_count"] == 1
        assert report["external_resource_uris"] == 0
    print("SELF-TEST PASS: valid GLB fixture parsed; one triangle verified")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("glb", nargs="?", type=Path)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--require-skin", action="store_true", help="fail unless the GLB contains a skeletal skin")
    parser.add_argument("--require-animation", action="store_true", help="fail unless the GLB contains at least one animation")
    parser.add_argument("--max-triangles", type=int, default=85000, help="mobile-friendly triangle budget")
    args = parser.parse_args()
    try:
        if args.self_test:
            run_self_test()
            return 0
        if args.glb is None:
            parser.error("provide a .glb file or use --self-test")
        report = inspect_glb(args.glb)
        if args.require_skin and (report["skin_count"] < 1 or report["joint_count"] < 10):
            raise GLBValidationError("rigged character must contain a skin with at least 10 joints")
        if args.require_animation and report["animation_count"] < 5:
            raise GLBValidationError("humanoid must contain idle, walk, run, jump and attack animation clips")
        if args.require_skin and report["skinned_primitive_count"] < 1:
            raise GLBValidationError("humanoid mesh must be weighted to its skeleton")
        if args.require_skin and report["bone_attached_mesh_count"] < 10:
            raise GLBValidationError("character details and clothing must remain attached to rig bones")
        if report["triangle_count"] > args.max_triangles:
            raise GLBValidationError(
                f"triangle count {report['triangle_count']} exceeds budget {args.max_triangles}"
            )
        print(json.dumps(report, indent=2))
        return 0
    except (OSError, GLBValidationError, AssertionError) as exc:
        print(f"VALIDATION FAILED: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
