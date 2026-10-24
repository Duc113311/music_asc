"""Build automation shared in spirit with the other ASC apps (smart_drink).

Same CLI and same files as the ASC `dsp_base/build_helper.py`: a flavor/build
menu, version bump (`build_version.txt` + pubspec build number), release notes
from the uncommitted git changes, `flutter build apk`, Firebase App
Distribution, and an optional Telegram / e-mail notification.

Difference on purpose: NO secret lives in this file or in the repo. Telegram
token/chat id and the e-mail password come from environment variables or from
the git-ignored `tool/build/build_secrets.json`:

    {"telegram_bot_token": "...", "telegram_chat_id": "...",
     "email_to": "...", "email_from": "...", "email_password": "..."}

A missing value just skips that notification. Firebase App Distribution uses
`build_auth.json` (service account, git-ignored) or the logged-in `firebase` CLI.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import threading
import time
import urllib.parse
import urllib.request

PATH_APK = os.path.join("build", "app", "outputs", "flutter-apk")
RELEASE_NOTES_FILE = "build_release_notes.txt"
VERSION_FILE = "build_version.txt"

MENU_OPTIONS = [
    ("NoAds Debug    (alpha)", "Alpha", "Debug"),
    ("NoAds Release  (alpha)", "Alpha", "Release"),
    ("Dev Debug      (dev)", "Dev", "Debug"),
    ("Dev Release    (dev)", "Dev", "Release"),
    ("Product Debug  (product)", "Product", "Debug"),
    ("Product Release (product)", "Product", "Release"),
]


class Build:
    """State of one build run."""

    def __init__(self):
        self.flavor = "Dev"
        self.build_type = "Release"
        self.build_number = "0"
        self.version_name = ""
        self.git_user = None
        self.firebase_app_id = ""
        self.testers = ""
        self.service_account = ""
        self.secrets = {}


def load_secrets(tool_dir):
    """Secrets from env vars first, then tool/build/build_secrets.json."""
    data = {}
    path = os.path.join(tool_dir, "build_secrets.json")
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    env = {
        "telegram_bot_token": "ASC_TELEGRAM_BOT_TOKEN",
        "telegram_chat_id": "ASC_TELEGRAM_CHAT_ID",
        "email_to": "ASC_EMAIL_TO",
        "email_from": "ASC_EMAIL_FROM",
        "email_password": "ASC_EMAIL_PASSWORD",
    }
    for key, var in env.items():
        if os.environ.get(var):
            data[key] = os.environ[var]
    return data


def firebase_app_id_from_google_services(package_name):
    """App id (mobilesdk_app_id) of [package_name] in google-services.json."""
    path = os.path.join("android", "app", "google-services.json")
    if not os.path.exists(path):
        return ""
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    for client in data.get("client", []):
        info = client.get("client_info", {})
        if info.get("android_client_info", {}).get("package_name") == package_name:
            return info.get("mobilesdk_app_id", "")
    return ""


# --- version -----------------------------------------------------------------

def read_pubspec_build_number():
    """Build number N of `version: x.y.z+N` in pubspec.yaml."""
    with open("pubspec.yaml", "r", encoding="utf-8") as f:
        for line in f:
            if line.strip().startswith("version:"):
                m = re.match(r"version:\s*\d+\.\d+\.\d+\+(\d+)", line.strip())
                if m:
                    return m.group(1)
    raise SystemExit("pubspec.yaml: no `version: x.y.z+N` line found")


def bump_version(build):
    """Increment the minor counter in build_version.txt ("minor(build)").

    The counter resets to 1 when the pubspec build number changed. Version name
    is `1.<build>.<minor>`, as in the other ASC apps.
    """
    build.build_number = read_pubspec_build_number()
    minor = 1
    if os.path.exists(VERSION_FILE):
        with open(VERSION_FILE, "r", encoding="utf-8") as f:
            m = re.match(r"(\d+)\((\d+)\)", f.readline().strip())
        if m and m.group(2) == build.build_number:
            minor = int(m.group(1)) + 1
    with open(VERSION_FILE, "w", encoding="utf-8") as f:
        f.write(f"{minor}({build.build_number})")
    build.version_name = f"1.{build.build_number}.{minor}"
    print(f"Version {build.version_name}+{build.build_number}")


# --- git / release notes -----------------------------------------------------

def _git(*args):
    r = subprocess.run(["git", *args], capture_output=True, text=True, check=False)
    return r.stdout.strip() if r.returncode == 0 else ""


def git_summary():
    """Uncommitted-changes summary used for release notes and notifications."""
    stat = _git("diff", "--stat", "--ignore-submodules", "HEAD")
    changed = [f for f in _git("diff", "--name-only", "--ignore-submodules", "HEAD").splitlines() if f]
    untracked = [f for f in _git("ls-files", "--others", "--exclude-standard").splitlines() if f]
    files = ins = dele = 0
    if stat:
        last = stat.splitlines()[-1]
        m = re.search(r"(\d+) files? changed", last)
        files = int(m.group(1)) if m else 0
        m = re.search(r"(\d+) insertions?\(\+\)", last)
        ins = int(m.group(1)) if m else 0
        m = re.search(r"(\d+) deletions?\(-\)", last)
        dele = int(m.group(1)) if m else 0
    lines = [
        f"Branch: {_git('rev-parse', '--abbrev-ref', 'HEAD') or 'unknown'} "
        f"({_git('rev-parse', '--short', 'HEAD') or 'unknown'})",
        f"Files changed: {files}",
    ]
    if untracked:
        lines.append(f"New files: {len(untracked)}")
    lines += [f"Lines changed: {ins + dele}", f"  +{ins}", f"  -{dele}"]
    exts = {}
    for f in changed + untracked:
        ext = os.path.splitext(f)[1] or "(no ext)"
        exts[ext] = exts.get(ext, 0) + 1
    if exts:
        top = sorted(exts.items(), key=lambda x: x[1], reverse=True)[:5]
        lines.append("File types: " + ", ".join(f"{e}({c})" for e, c in top))
    if changed:
        lines.append("Top changes:")
        lines += [f"  - {f}" for f in changed[:3]]
    return "\n".join(lines)


def write_release_notes(build):
    header = f"[{build.flavor}_{build.build_type}_{time.strftime('%H:%M')}"
    if build.git_user:
        header += f" by {build.git_user}"
    header += "]"
    with open(RELEASE_NOTES_FILE, "w", encoding="utf-8") as f:
        f.write(header + "\n" + git_summary() + "\n")


# --- build / distribute ------------------------------------------------------

def flutter_build_apk(build):
    flutter = shutil.which("flutter")
    if not flutter:
        raise SystemExit("'flutter' not found in PATH")
    cmd = [
        flutter, "build", "apk",
        "--flavor", build.flavor.lower(), "--" + build.build_type.lower(),
        "--build-name", build.version_name,
        "--build-number", build.build_number,
        "--target-platform", "android-arm64",
    ]
    print("Building APK:", " ".join(cmd))
    r = subprocess.run(cmd, text=True, encoding="utf-8", errors="replace")
    if r.returncode != 0:
        raise SystemExit("Flutter build failed")


def apk_path(build):
    return os.path.join(PATH_APK, f"app-{build.flavor.lower()}-{build.build_type.lower()}.apk")


def distribute_apk(build):
    """Firebase App Distribution; skipped when no app id or tester is set."""
    path = apk_path(build)
    if not os.path.exists(path):
        print(f"APK not found: {path}")
        return
    if not build.firebase_app_id or not build.testers:
        print("Firebase App Distribution skipped (no app id or testers).")
        return
    firebase = shutil.which("firebase") or "firebase"
    # --release-notes-file: a multi-line --release-notes value is cut at the
    # first newline by cmd.exe on Windows and silently drops later flags.
    cmd = [
        firebase, "appdistribution:distribute", path,
        "--app", build.firebase_app_id,
        "--release-notes-file", RELEASE_NOTES_FILE,
        "--testers", build.testers,
    ]
    env = os.environ.copy()
    if build.service_account and os.path.exists(build.service_account):
        env["GOOGLE_APPLICATION_CREDENTIALS"] = build.service_account
    r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", env=env)
    print(r.stdout)
    if r.returncode != 0:
        print(f"Error distributing {path}: {r.stderr}")


# --- notifications (optional) ------------------------------------------------

def notify_telegram(build, message):
    token = build.secrets.get("telegram_bot_token")
    chat = build.secrets.get("telegram_chat_id")
    if not token or not chat:
        print("Telegram skipped (no token/chat id configured).")
        return
    try:
        data = urllib.parse.urlencode({"chat_id": chat, "text": message}).encode("utf-8")
        req = urllib.request.Request(f"https://api.telegram.org/bot{token}/sendMessage", data=data)
        with urllib.request.urlopen(req, timeout=10) as resp:
            print("Telegram notification sent" if resp.getcode() == 200 else f"Telegram failed: {resp.getcode()}")
    except Exception as e:  # noqa: BLE001 - notification must never fail the build
        print(f"Telegram error: {e}")


def notify_email(build, subject, body):
    s = build.secrets
    if not (s.get("email_password") and s.get("email_from") and s.get("email_to")):
        print("E-mail skipped (not configured).")
        return
    try:
        import smtplib
        from email.mime.multipart import MIMEMultipart
        from email.mime.text import MIMEText

        msg = MIMEMultipart()
        msg["From"], msg["To"], msg["Subject"] = s["email_from"], s["email_to"], subject
        msg.attach(MIMEText(body, "plain", "utf-8"))
        with smtplib.SMTP("smtp.gmail.com", 587) as server:
            server.ehlo()
            server.starttls()
            server.login(s["email_from"], s["email_password"])
            server.sendmail(s["email_from"], s["email_to"], msg.as_string())
        print(f"E-mail sent to {s['email_to']}")
    except Exception as e:  # noqa: BLE001
        print(f"E-mail error: {e}")


# --- CLI ---------------------------------------------------------------------

def _timed_input(timeout_seconds):
    result = [None]

    def read():
        try:
            result[0] = input().strip()
        except (EOFError, OSError):
            result[0] = ""

    print(f"Enter number (auto-exit in {timeout_seconds}s): ", end="", flush=True)
    t = threading.Thread(target=read, daemon=True)
    t.start()
    t.join(timeout=timeout_seconds)
    if t.is_alive():
        print("\nNo input. Exiting.")
        sys.exit(0)
    return result[0] or ""


def _menu():
    check = len(MENU_OPTIONS) + 1
    print("\n=== Select Build Configuration ===\n")
    for i, (label, _, _) in enumerate(MENU_OPTIONS, start=1):
        print(f"{i:>2}. {label}")
    print(f"{check:>2}. Check strings (tool/check_strings.py)")
    print(" 0. Exit\n")
    try:
        choice = int(_timed_input(15))
    except ValueError:
        raise SystemExit("Invalid input")
    if choice == 0:
        sys.exit(0)
    if choice == check:
        return None, None
    if not 1 <= choice <= len(MENU_OPTIONS):
        raise SystemExit("Invalid choice")
    return MENU_OPTIONS[choice - 1][1:]


def check_strings():
    """True when every used translation key has a string."""
    script = os.path.join("tool", "check_strings.py")
    if not os.path.exists(script):
        return True
    return subprocess.run([sys.executable, script]).returncode == 0


def main_build(argv, package_name, tester_emails="", tool_dir=None):
    """`python build.py [flavor] [debug|release]`; no args shows the menu."""
    build = Build()
    build.testers = tester_emails or os.environ.get("ASC_TESTER_EMAILS", "")
    build.service_account = os.path.join(os.getcwd(), "build_auth.json")
    build.secrets = load_secrets(tool_dir or os.path.dirname(os.path.abspath(__file__)))
    build.firebase_app_id = firebase_app_id_from_google_services(package_name)

    if len(argv) > 1 and argv[1].lower() == "check-strings":
        sys.exit(0 if check_strings() else 1)
    if len(argv) > 1:
        flavor = argv[1]
        build_type = argv[2] if len(argv) > 2 else "Release"
    else:
        flavor, build_type = _menu()
        if flavor is None:
            sys.exit(0 if check_strings() else 1)
    build.flavor = flavor[:1].upper() + flavor[1:]
    build.build_type = build_type[:1].upper() + build_type[1:]
    if build.flavor.lower() == "prod":
        build.flavor = "Product"

    if not check_strings():
        print("Missing translation keys: fix them before building.")
        sys.exit(1)

    shutil.rmtree(PATH_APK, ignore_errors=True)
    build.git_user = _git("config", "user.email") or _git("config", "user.name") or None

    bump_version(build)
    write_release_notes(build)
    summary = git_summary()
    flutter_build_apk(build)
    distribute_apk(build)

    app_name = os.path.basename(os.getcwd())
    path = apk_path(build)
    if os.path.exists(path):
        size = round(os.path.getsize(path) / (1024 * 1024), 2)
        message = (f"{app_name} v{build.version_name} - build done\n"
                   f"[{build.flavor}_{build.build_type}] by {build.git_user}\n"
                   f"APK size: {size} MB\n\n{summary}")
        print(message)
        notify_telegram(build, message)
        notify_email(build, f"{app_name} build completed [{build.flavor}_{build.build_type}]", message)
    else:
        fail = f"{app_name} - build FAILED, no APK generated (by {build.git_user})"
        print(fail)
        notify_telegram(build, fail)
        notify_email(build, f"{app_name} build failed [{build.flavor}_{build.build_type}]", fail)
        sys.exit(1)
