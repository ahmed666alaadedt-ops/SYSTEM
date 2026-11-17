#!/usr/bin/env python3
"""Run and verify the SYSTEM WORLD Blender -> BLEND/GLB pipeline.

This is an orchestration/acceptance-test runner, not a Blender replacement.
It never creates fake output files when Blender is unavailable.

Examples:
  python3 SYSTEM-WORLD/tools/blender/run_environment_pipeline_test.py --world modern
  python3 SYSTEM-WORLD/tools/blender/run_environment_pipeline_test.py --world all
  python3 SYSTEM-WORLD/tools/blender/run_environment_pipeline_test.py --world greed_island --seed 20261117

Exit codes:
  0: every requested Blender export and GLB validation passed
  1: Blender ran but generation, output checks, or GLB validation failed
  2: Blender executable is unavailable
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
    parser.add_argument(
        "--output", type=Path,
        default=PROJECT_DIR / "generated" / "environment_tiles",
    )
    parser.add_argument(
        "--report", type=Path,
        help="Optional JSON report path (default: <output>/pipeline_test_report.json)",
    )
    return parser.parse_args()


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
            "was generated; install Blender 4.x and rerun this command."
        )
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
        print(json.dumps(report, indent=2))
        return 2

    try:
        version = subprocess.run(
            [blender, "--version"], check=True, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        )
        report["blender_version"] = version.stdout.splitlines()[0] if version.stdout else "unknown"
    except (OSError, subprocess.CalledProcessError) as exc:
        report["status"] = "blender_launch_failed"
        report["blocker"] = str(exc)
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
            "glb_validation": None,
            "status": "not_run",
        }
        try:
            run = subprocess.run(
                command, text=True, stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT, check=False,
            )
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
            outputs_exist = all(x["exists"] and x["bytes"] > 0 for x in item["outputs"].values())
            if run.returncode == 0 and outputs_exist:
                validation = subprocess.run(
                    [sys.executable, str(VALIDATOR), str(glb_path)],
                    text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                    check=False,
                )
                item["glb_validation"] = {
                    "exit_code": validation.returncode,
                    "output": validation.stdout[-6000:],
                }
                item["status"] = "passed" if validation.returncode == 0 else "glb_validation_failed"
            else:
                item["status"] = "generation_failed_or_outputs_missing"
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
