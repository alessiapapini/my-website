#!/usr/bin/env bash
set -euo pipefail
if [[ ! -f hugo.toml || ! -f layouts/index.html || ! -f assets/css/viviens.css ]]; then
  echo 'Run this in the my-website Hugo project after the redesign.' >&2
  exit 1
fi
stamp="$(date +%Y%m%d-%H%M%S)"
backup=".site-backups/$stamp"
mkdir -p "$backup/layouts" "$backup/assets/css" static/files
cp layouts/index.html "$backup/layouts/index.html"
cp assets/css/viviens.css "$backup/assets/css/viviens.css"
python3 - <<'PY'
from pathlib import Path
import re, shutil
home = Path('layouts/index.html')
s = home.read_text()
# Replace the optional CV paragraph with a direct link to the detected file.
# The exact CV filename is determined below, rather than guessed.
pattern = r'\s*{{ with \.Site\.Params\.cvURL }}<p>You can find my latest CV <a href="{{ \. \| relURL }}">here</a>\.</p>{{ end }}'
s, n = re.subn(pattern, '', s)
if n == 0 and 'You can find my latest CV' in s:
    raise SystemExit('Existing CV markup is different; stopping to avoid duplicate links.')
# Prefer a CV PDF already under static/, then one in the project root or subdirectories.
root = Path('.')
candidates = []
for p in root.rglob('*.pdf'):
    if any(x in p.parts for x in ('.git', '.site-backups', 'public', 'resources', 'node_modules')):
        continue
    if re.search(r'(^|[_\-\s])(cv|curriculum|vitae)([_\-\s.]|$)', p.stem, re.I) or 'curriculum' in p.stem.lower():
        candidates.append(p)
# Case-insensitive extension support.
for p in root.rglob('*.PDF'):
    if not any(x in p.parts for x in ('.git', '.site-backups', 'public', 'resources', 'node_modules')) and re.search(r'cv|curriculum|vitae', p.stem, re.I):
        candidates.append(p)
candidates = sorted(set(candidates), key=lambda p: (0 if p.parts[0] == 'static' else 1, len(p.parts), str(p)))
if not candidates:
    raise SystemExit('No CV PDF found. Please put your CV PDF in the my-website folder and run this script again.')
cv = candidates[0]
if cv.parts[0] != 'static':
    dest = Path('static/files') / cv.name
    if dest.exists() and dest.resolve() != cv.resolve():
        raise SystemExit(f'CV destination {dest} already exists; please check which file to use.')
    shutil.copy2(cv, dest)
    cv = dest
url = '/' + cv.relative_to('static').as_posix()
paragraph = f'      <p>You can find my latest CV <a href="{{{{ {url!r} | relURL }}}}">here</a>.</p>'
needle = '      {{ with .Site.Params.homeExtra }}'
if needle not in s:
    raise SystemExit('Could not locate homepage insertion point; no changes made.')
s = s.replace(needle, paragraph + '\n' + needle, 1)
home.write_text(s)
css = Path('assets/css/viviens.css')
t = css.read_text()
# Increase whitespace only in Research, preserving Teaching and global typography.
block = '''
/* Research: slightly more breathing room between entries and sections. */
.research-page .content-section { margin-bottom: 35px; }
.research-page .content-section h2 { margin-bottom: 20px; }
.research-page .paper-list li { margin-bottom: 26px; line-height: 1.42; }
.research-page .paper-detail { margin-top: 4px; }
'''
if '/* Research: slightly more breathing room' not in t:
    t += '\n' + block
css.write_text(t)
print(f'CV linked: {cv} -> {url}')
print('Research spacing increased; other pages unchanged.')
PY
if command -v hugo >/dev/null 2>&1; then hugo --gc; fi
echo "Done. Backup saved in $backup"
echo 'Preview: hugo server -D'
