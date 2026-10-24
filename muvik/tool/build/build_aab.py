"""Build the Play Store bundle (product flavor, release). Run from anywhere:

    python tool/build/build_aab.py

Needs android/key.properties for the store key (see android/app/build.gradle.kts);
without it the bundle is signed with the debug key and Play will reject it.
"""
import os
import shutil
import subprocess
import sys

PROJECT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
os.chdir(PROJECT_DIR)
sys.path.insert(0, os.path.dirname(__file__))

import build_helper  # noqa: E402


def build_aab():
    build = build_helper.Build()
    build_helper.bump_version(build)
    flutter = shutil.which("flutter")
    if not flutter:
        sys.exit("'flutter' not found in PATH")
    if not os.path.exists(os.path.join("android", "key.properties")):
        print("WARNING: android/key.properties missing - bundle is debug-signed.")
    cmd = [
        flutter, "build", "appbundle", "--flavor", "product", "--release",
        "--build-name", build.version_name, "--build-number", build.build_number,
    ]
    print("Building AAB:", " ".join(cmd))
    if subprocess.run(cmd).returncode != 0:
        sys.exit("AAB build failed")
    folder = os.path.realpath(os.path.join("build", "app", "outputs", "bundle", "productRelease"))
    print(f"AAB ready: {folder}")


if __name__ == "__main__":
    build_aab()
