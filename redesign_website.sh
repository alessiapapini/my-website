#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f hugo.toml && ! -f config.toml && ! -f hugo.yaml && ! -f hugo.yml ]]; then
  echo 'ERROR: Run this script from the root of your Hugo website.' >&2
  exit 1
fi
if ! command -v hugo >/dev/null 2>&1; then
  echo 'ERROR: Hugo is not installed or not on PATH.' >&2
  exit 1
fi

stamp="$(date +%Y%m%d-%H%M%S)"
backup=".site-backups/$stamp"
mkdir -p "$backup" layouts/partials layouts/research layouts/teaching assets/css
for f in layouts/index.html layouts/research/list.html layouts/teaching/list.html layouts/_default/list.html layouts/partials/head.html layouts/partials/header.html layouts/partials/footer.html content/_index.md content/research/_index.md content/teaching/_index.md hugo.toml; do
  if [[ -f "$f" ]]; then mkdir -p "$backup/$(dirname "$f")"; cp -p "$f" "$backup/$f"; fi
done

# Standalone templates avoid inherited hugo-researcher theme CSS and duplicated headings.
cat > layouts/partials/viviens-head.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="light">
  <title>{{ if .IsHome }}{{ .Site.Title }}{{ else }}{{ .Title }} | {{ .Site.Title }}{{ end }}</title>
  {{ with .Site.Params.description }}<meta name="description" content="{{ . }}">{{ end }}
  {{ $css := resources.Get "css/viviens.css" | minify | fingerprint }}
  <link rel="stylesheet" href="{{ $css.RelPermalink }}">
</head>
<body>
<header class="site-header">
  <a class="site-brand" href="{{ .Site.Home.RelPermalink }}">{{ .Site.Title }}</a>
  <nav class="site-nav" aria-label="Main navigation">
    <a href="{{ .Site.Home.RelPermalink }}" {{ if .IsHome }}aria-current="page"{{ end }}>Home</a>
    <a href="{{ "research/" | relURL }}" {{ if eq .Section "research" }}aria-current="page"{{ end }}>Research</a>
    <a href="{{ "teaching/" | relURL }}" {{ if eq .Section "teaching" }}aria-current="page"{{ end }}>Teaching</a>
  </nav>
</header>
EOF

cat > layouts/index.html <<'EOF'
{{ partial "viviens-head.html" . }}
<main class="home-page">
  <div class="home-grid">
    <div class="portrait-wrap">
      {{/* Set params.portrait in hugo.toml if auto-discovery does not find your photo. */}}
      {{ $portrait := .Site.Params.portrait | default "" }}
      {{ if not $portrait }}
        {{ $files := slice }}
        {{ range (readDir "static") }}
          {{ if .IsDir }}
            {{ $dirname := .Name }}
            {{ range (readDir (printf "static/%s" $dirname)) }}
              {{ if not .IsDir }}{{ $files = $files | append (printf "%s/%s" $dirname .Name) }}{{ end }}
            {{ end }}
          {{ else }}
            {{ $files = $files | append .Name }}
          {{ end }}
        {{ end }}
        {{ range $files }}
          {{ if and (not $portrait) (findRE `(?i)(portrait|profile|headshot|alessia|photo|foto)` .) (findRE `(?i)\.(jpe?g|png|webp)$` .) }}
            {{ $portrait = . }}
          {{ end }}
        {{ end }}
      {{ end }}
      {{ with $portrait }}<img class="portrait" src="{{ strings.TrimPrefix "/" . | relURL }}" alt="Portrait of Alessia Papini">{{ else }}<div class="portrait-missing">Add your portrait using <code>portrait = "images/your-photo.jpg"</code> under <code>[params]</code> in hugo.toml.</div>{{ end }}
    </div>
    <div class="home-copy">
      <h1>Alessia Papini</h1>
      <p>I'm a Ph.D. candidate in Economics at the <a href="https://www.eui.eu/">European University Institute</a> (Florence, Italy).</p>
      <p>My research interests are in applied macroeconomics, fiscal policy, and household expectations.</p>
      <p>My advisors are <a href="https://www.giancarlocorsetti.com/">Giancarlo Corsetti</a> and Alexander Ludwig.</p>
      {{ with .Site.Params.cvURL }}<p>You can find my latest CV <a href="{{ . | relURL }}">here</a>.</p>{{ end }}
      {{ with .Site.Params.homeExtra }}<p class="home-extra">{{ . | markdownify }}</p>{{ end }}
    </div>
  </div>
</main>
</body>
</html>
EOF

cat > layouts/research/list.html <<'EOF'
{{ partial "viviens-head.html" . }}
<main class="content-page research-page">
  <h1 class="page-title">Research</h1>
  <section class="content-section">
    <h2>Working Papers</h2>
    <ul class="paper-list">
      <li><strong>Fiscal Policy and Household Over-Optimism</strong><div class="paper-detail">Presented at: EUI May Forum (2026)</div></li>
      <li><strong>Layoff Announcements and Consumption Behavior</strong> with <a href="https://ludovicroussel.github.io/">Ludovic Roussel</a></li>
    </ul>
  </section>
  <section class="content-section">
    <h2>Pre-PhD Publications</h2>
    <ul class="paper-list">
      <li><strong><a href="https://www.sciencedirect.com/science/article/pii/S0165176524004658">European Politicians and Financial Literacy Activism: Does Financial (In)Stability Matter?</a></strong> (2024) with Elisa Borghi and Donato Masciandaro<div class="paper-detail"><em>Economics Letters</em></div></li>
      <li><strong><a href="https://link.springer.com/article/10.1007/s40797-024-00287-1">Literacy and Financial Education: Private Providers, Public Certification and Political Preferences</a></strong> (2024) with Carolina Guerini and Donato Masciandaro<div class="paper-detail"><em>Italian Economic Journal</em></div></li>
    </ul>
  </section>
</main>
</body>
</html>
EOF

cat > layouts/teaching/list.html <<'EOF'
{{ partial "viviens-head.html" . }}
<main class="content-page teaching-page">
  <h1 class="page-title">Teaching</h1>
  <section class="content-section">
    <h2>Teaching Assistant (EUI)</h2>
    <div class="course"><p><strong>Macroeconomics I (PhD)</strong> Fall 2025, Fall 2026</p><p>Prof. Alexander Ludwig</p></div>
  </section>
  <section class="content-section">
    <h2>Teaching Assistant (Politecnico di Milano)</h2>
    <div class="course"><p><strong>Microeconomics</strong> Spring 2024, Spring 2025</p><p>Prof. Lucia Tajoli</p></div>
    <div class="course"><p><strong>International Economics</strong> Spring 2024</p><p>Prof. Giulia Felice</p></div>
  </section>
</main>
</body>
</html>
EOF

cat > assets/css/viviens.css <<'EOF'
:root { --page-bg:#EAF3F3; --ink:#161616; --accent:#2a8a90; }
* { box-sizing:border-box; }
html { background:var(--page-bg); min-height:100%; }
body { margin:0; min-height:100vh; background:var(--page-bg); color:var(--ink); font-family:Georgia,"Times New Roman",serif; font-size:20px; line-height:1.35; }
a { color:inherit; text-decoration:underline; text-decoration-thickness:1px; text-underline-offset:2px; }
a:hover, a:focus-visible { color:var(--accent); }
.site-header { display:flex; align-items:center; justify-content:space-between; gap:2rem; padding:28px 3.9% 0; }
.site-brand { font-size:20px; text-decoration:none; white-space:nowrap; }
.site-nav { display:flex; gap:28px; align-items:center; }
.site-nav a { display:block; padding:0 1px 12px; border-bottom:7px solid transparent; text-decoration:none; font-size:18px; white-space:nowrap; }
.site-nav a[aria-current="page"] { border-bottom-color:#000; }
.site-nav a:hover { color:var(--accent); }
.home-page { padding:24px 5% 80px; }
.home-grid { display:grid; grid-template-columns:minmax(280px, 31%) minmax(0,1fr); align-items:start; gap:32px; }
.portrait { display:block; width:100%; height:auto; max-height:520px; object-fit:cover; object-position:top center; }
.portrait-missing { padding:1rem; border:1px dashed #777; font-size:14px; }
.home-copy h1 { margin:8px 0 16px; font-size:48px; font-weight:700; line-height:1.12; }
.home-copy p { margin:0 0 18px; font-size:22px; line-height:1.5; }
.home-copy .home-extra { margin-top:32px; }
.content-page { padding:22px 8% 90px; }
.page-title { margin:5px 0 52px; font-size:44px; line-height:1.2; font-weight:700; text-align:center; }
.content-section { margin:0 0 22px; }
.content-section h2 { font-size:27px; line-height:1.2; margin:0 0 14px; font-weight:700; }
.paper-list { list-style:none; padding:0; margin:0; }
.paper-list li { position:relative; padding-left:17px; margin:0 0 17px; font-size:17px; line-height:1.28; }
.paper-list li::before { content:"▶"; position:absolute; left:0; top:1px; font-size:12px; }
.paper-detail { margin-top:1px; }
.teaching-page .content-section { margin-bottom:24px; }
.course { margin-bottom:13px; }
.course p { margin:0 0 3px; font-size:21px; line-height:1.3; }
@media (max-width:800px) {
 .site-header { padding:20px 5% 0; flex-wrap:wrap; gap:12px; }
 .site-nav { gap:20px; }
 .site-nav a { font-size:17px; padding-bottom:8px; border-bottom-width:5px; }
 .home-page { padding:28px 5% 60px; }
 .home-grid { grid-template-columns:1fr; gap:20px; }
 .portrait { width:min(100%, 340px); max-height:none; }
 .home-copy h1 { font-size:40px; }
 .home-copy p { font-size:19px; }
 .content-page { padding:28px 6% 70px; }
 .page-title { font-size:40px; margin:10px 0 42px; }
 .content-section h2 { font-size:25px; }
 .course p { font-size:19px; }
}
EOF

# Ignore backups, while preserving them on disk.
if [[ -f .gitignore ]]; then
  grep -qxF '.site-backups/' .gitignore || printf '\n.site-backups/\n' >> .gitignore
else
  printf '.site-backups/\n' > .gitignore
fi

printf '\nBuilding Hugo site...\n'
hugo --gc
printf '\nSUCCESS: Hugo site built. Backups are in %s\n' "$backup"
printf 'Preview with: hugo server -D\n'
printf 'Then visit: http://localhost:1313/my-website/\n'
printf '\nNote: Set portrait and cvURL under [params] in hugo.toml if necessary.\n'
