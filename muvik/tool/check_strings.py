"""Verifies every translation key used in lib/ exists in strings_src.py.

Usage: python tool/check_strings.py   (exit code 1 when keys are missing)
"""
import glob
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from strings_src import S  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), '..')
INDIRECT = re.compile(
    r"'((?:accent|eq_preset|error|sort|feedback_type|greeting|onb\d|tab|playlist_name)_[a-z0-9_]+)'")
DYNAMIC = re.compile(r'(weekday_short|month_short|rate_label)_\d+')
SKIP = ('configs', 'repository', 'storage', 'native')

used = set()
for f in glob.glob(os.path.join(ROOT, 'lib', '**', '*.dart'), recursive=True):
    s = open(f, encoding='utf8').read()
    used |= {m.group(1) for m in re.finditer(r"'([a-z][a-z0-9_]*)'\.tr(Params)?\b", s)}
    if not any(f'{os.sep}{d}{os.sep}' in f for d in SKIP):
        used |= {m.group(1) for m in INDIRECT.finditer(s)}

missing = sorted(k for k in used - set(S) if not DYNAMIC.fullmatch(k))
unused = sorted(k for k in set(S) - used if not DYNAMIC.fullmatch(k))
print('missing:', missing)
print('unused :', unused)
sys.exit(1 if missing else 0)
