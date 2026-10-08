#!/usr/bin/env bash
set -euo pipefail
if [[ ! -f layouts/index.html || ! -f assets/css/viviens.css ]]; then
  echo 'Please run this from your Hugo website folder after the redesign script.' >&2
  exit 1
fi
stamp="$(date +%Y%m%d-%H%M%S)"
mkdir -p ".site-backups/$stamp/layouts" ".site-backups/$stamp/assets/css"
cp layouts/index.html ".site-backups/$stamp/layouts/index.html"
cp assets/css/viviens.css ".site-backups/$stamp/assets/css/viviens.css"
python3 - <<'PY'
from pathlib import Path
import re
home = Path('layouts/index.html')
s = home.read_text()
s = s.replace('European University Institute</a> (Florence, Italy)', 'European University Institute</a>')
s = s.replace('and Alexander Ludwig.', 'and <a href="https://alexander-ludwig.com/">Alexander Ludwig</a>.')
home.write_text(s)
css = Path('assets/css/viviens.css')
s = css.read_text()
replacements = {
    'font-size:20px; line-height:1.35;': 'font-size:19px; line-height:1.35;',
    '.site-brand { font-size:20px;': '.site-brand { font-size:19px;',
    'font-size:18px; white-space:nowrap;': 'font-size:17px; white-space:nowrap;',
    'font-size:48px; font-weight:700;': 'font-size:44px; font-weight:600;',
    'font-size:22px; line-height:1.5;': 'font-size:20px; line-height:1.5;',
    'font-size:44px; line-height:1.2;': 'font-size:42px; line-height:1.2;',
    'font-size:27px; line-height:1.2;': 'font-size:25px; line-height:1.2;',
    'font-size:17px; line-height:1.28;': 'font-size:16px; line-height:1.28;',
    'font-size:21px; line-height:1.3;': 'font-size:19px; line-height:1.3;',
    '.home-copy h1 { font-size:40px; }': '.home-copy h1 { font-size:37px; }',
    '.home-copy p { font-size:19px; }': '.home-copy p { font-size:18px; }',
    '.page-title { font-size:40px;': '.page-title { font-size:38px;',
    '.content-section h2 { font-size:25px; }': '.content-section h2 { font-size:23px; }',
    '.course p { font-size:19px; }': '.course p { font-size:18px; }',
}
for before, after in replacements.items():
    if before not in s:
        print('Warning: CSS pattern not found:', before)
    s = s.replace(before, after)
css.write_text(s)
PY
if command -v hugo >/dev/null 2>&1; then hugo --gc; fi
echo 'Adjustments complete. Preview with: hugo server -D'
