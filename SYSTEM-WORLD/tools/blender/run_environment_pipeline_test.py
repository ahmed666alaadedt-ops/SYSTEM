#!/usr/bin/env python3
"""Run and verify the SYSTEM WORLD Blender -> BLEND/GLB pipeline.

Exit codes:
  0: every requested Blender export, reopen check and GLB validation passed
  1: Blender ran but generation or an artifact validation failed
  2: Blender executable is unavailable or cannot be launched
"""
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

WORLDS = ("modern", "historical", "fantasy", "greed_island")
HERE = Path(__file__).resolve().parent
TOOLS_DIR = HERE.parent
PROJECT_DIR = TOOLS_DIR.parent
GENERATOR = HERE / "generate_system_world_environment.py"
VALIDATOR = TOOLS_DIR / "validate_glb.py"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--blender", default="blender", help="Blender executable or absolute path")
    parser.add_argument("--world", choices=(*WORLDS, "all"), default="modern")
    parser.add_argument("--seed", type=int, default=20261117)
    parser.add_argument("--segments", type=int, default=48)
    parser.add_argument("--size", type=float, default=64.0)
    parser.add_argument("--output", type=Path, default=PROJECT_DIR / "generated" / "environment_tiles")
    parser.add_argument("--report", type=Path, help="Optional JSON report path")
    return parser.parse_args()


def run_command(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command, text=True, stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT, check=False,
    )


def validate_blend(blender: str, path: Path) -> tuple[bool, str]:
    # Reopen the saved file in a fresh Blender process; a non-empty file alone
    # is not evidence that Blender can parse the project.
    expression = (
        "import bpy; "
        "meshes=[o for o in bpy.data.objects if o.type == 'MESH']; "
        "assert bpy.data.filepath, 'blend file path is empty'; "
        "assert len(meshes) >= 1, 'no mesh objects in saved scene'; "
        "assert bpy.context.scene.camera is not None, 'preview camera missing'; "
        "print('BLEND_REOPEN_VALIDATION_PASS')"
    )
    result = run_command([blender, "--background", str(path), "--python-expr", expression])
    passed = result.returncode == 0 and "BLEND_REOPEN_VALIDATION_PASS" in result.stdout
    return passed, result.stdout[-6000:]


def main() -> int:
    args = parse_args()
    if not 16 <= args.segments <= 128:
        print("ERROR: --segments must be between 16 and 128", file=sys.stderr)
        return 1
    if args.size <= 0:
        print("ERROR: --size must be greater than zero", file=sys.stderr)
        return 1
    if not GENERATOR.is_file() or not VALIDATOR.is_file():
        print("ERROR: generator or GLB validator file is missing", file=sys.stderr)
        return 1

    output = args.output.expanduser().resolve()
    output.mkdir(parents=True, exist_ok=True)
    report_path = (args.report or output / "pipeline_test_report.json").expanduser().resolve()
    blender = shutil.which(args.blender)
    worlds = WORLDS if args.world == "all" else (args.world,)
    report = {
        "tool": "SYSTEM WORLD Blender Environment Pipeline Test",
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "blender_executable_requested": args.blender,
        "blender_executable_resolved": blender,
        "worlds_requested": list(worlds),
        "seed": args.seed,
        "segments": args.segments,
        "tile_size_m": args.size,
        "output_directory": str(output),
        "status": "blocked_blender_unavailable" if not blender else "running",
        "world_results": [],
    }

    if not blender:
        report["blocker"] = (
            "Blender executable was not found. No .blend or Blender-exported .glb "
            "was generated; install the CI-pinned Blender 4.0.2 and rerun."
        )
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
        print(json.dumps(report, indent=2))
        return 2

    try:
        version = run_command([blender, "--version"])
        if version.returncode != 0:
            raise RuntimeError(version.stdout[-2000:])
        report["blender_version"] = version.stdout.splitlines()[0] if version.stdout else "unknown"
    except (OSError, RuntimeError) as exc:
        report["status"] = "blender_launch_failed"
        report["blocker"] = str(exc)
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
        print(json.dumps(report, indent=2))
        return 2

    failures = 0
    for world in worlds:
        stem = f"sw_{world}_tile_s{args.seed}"
        blend_path = output / f"{stem}.blend"
        glb_path = output / f"{stem}.glb"
        metadata_path = output / f"{stem}.json"
        command = [
            blender, "--background", "--python", str(GENERATOR), "--",
            "--world", world, "--seed", str(args.seed),
            "--segments", str(args.segments), "--size", str(args.size),
            "--output", str(output),
        ]
        item = {
            "world": world,
            "command": command,
            "generator_exit_code": None,
            "outputs": {},
            "blend_reopen_validation": None,
            "glb_validation": None,
            "metadata_validation": None,
            "status": "not_run",
        }
        try:
            run = run_command(command)
            item["generator_exit_code"] = run.returncode
            item["generator_log_tail"] = run.stdout[-6000:]
            for label, path in (
                ("blend", blend_path), ("glb", glb_path), ("metadata", metadata_path)
            ):
                item["outputs"][label] = {
                    "path": str(path),
                    "exists": path.is_file(),
                    "bytes": path.stat().st_size if path.is_file() else 0,
                }

            outputs_exist = all(
                value["exists"] and value["bytes"] > 0
                for value in item["outputs"].values()
            )
            export_marker = f"EXPORTED: {glb_path.name}"
            if run.returncode != 0 or not outputs_exist or export_marker not in run.stdout or "Traceback" in run.stdout:
                item["status"] = "generation_failed_or_outputs_missing"
            else:
                try:
                    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
                    metadata_ok = (
                        metadata.get("asset") == stem
                        and metadata.get("world") == world
                        and metadata.get("seed") == args.seed
                        and metadata.get("terrain_segments") == args.segments
                        and metadata.get("source_file") == blend_path.name
                        and metadata.get("runtime_file") == glb_path.name
                        and metadata.get("status") == "procedural_blockout_requires_visual_review"
                    )
                except (OSError, json.JSONDecodeError) as exc:
                    metadata_ok = False
                    item["metadata_error"] = str(exc)
                item["metadata_validation"] = {"passed": metadata_ok}
                blend_ok, blend_log = validate_blend(blender, blend_path)
                item["blend_reopen_validation"] = {
                    "passed": blend_ok, "output": blend_log,
                }
                validation = run_command([sys.executable, str(VALIDATOR), str(glb_path)])
                try:\n                    glb_report = json.loads(validation.stdout) if validation.returncode == 0 else {}\n                    glb_ok = glb_report.get("status") == "structural_validation_passed" and glb_report.get("glb_version") == 2 and glb_report.get("triangle_count", 0) > 0\n                except json.JSONDecodeError:\n                    glb_ok = False
                item["glb_validation"] = {
                    "exit_code": validation.returncode,
                    "passed": glb_ok,
                    "output": validation.stdout[-6000:],
                }
                item["status"] = (
                    "passed" if metadata_ok and blend_ok and glb_ok
                    else "artifact_validation_failed"
                )
        except OSError as exc:
            item["status"] = "process_error"
            item["error"] = str(exc)

        if item["status"] != "passed":
            failures += 1
        report["world_results"].append(item)

    report["status"] = "passed" if failures == 0 else "failed"
    report["passed_worlds"] = len(worlds) - failures
    report["failed_worlds"] = failures
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
