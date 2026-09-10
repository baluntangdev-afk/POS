# -*- coding: utf-8 -*-
"""Builds the two POS Mobile manuals (User + Technical) as styled HTML, then
renders each to PDF with headless Chrome / Edge.

    cd docs/manuals/mobile
    python build_manuals.py

Output (next to this script):
    POSMobile-User-Manual.html / .pdf
    POSMobile-Technical-Manual.html / .pdf

Content lives in this file. Layout / CSS is shared with the kiosk manual
pipeline in spirit but kept self-contained here.
"""

import html
import os
import subprocess

OUT = os.path.dirname(os.path.abspath(__file__))

_CHROME_CANDIDATES = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
]
CHROME = next((c for c in _CHROME_CANDIDATES if os.path.exists(c)), _CHROME_CANDIDATES[0])

VERSION = "App v1.2.0 \u00b7 Manual rev. 1"
DATE = "September 2026"

CSS = r"""
:root{
  --teal:#1B7A8C; --teal-d:#125863; --olive:#BCBE68; --olive-d:#8f9142;
  --ink:#1f2733; --ink-soft:#45505f; --muted:#6b7685;
  --bg:#ffffff; --panel:#f4f7f8; --panel-2:#eef3f4;
  --line:#d7dee2; --line-soft:#e7ecee;
  --warn-bg:#fff4e5; --warn-line:#e08a1e; --warn-ink:#8a4b00;
  --note-bg:#e9f4f6; --note-line:#1B7A8C;
  --ok-bg:#ecf6ec; --ok-line:#3f8f3f;
  --code-bg:#f2f4f5;
}
*{box-sizing:border-box}
html{-webkit-print-color-adjust:exact; print-color-adjust:exact}
body{font-family:"Segoe UI",Arial,Helvetica,sans-serif; color:var(--ink);
  font-size:10.6pt; line-height:1.5; margin:0}
h1,h2,h3,h4{font-family:"Segoe UI Semibold","Segoe UI",Arial,sans-serif; line-height:1.25}
p{margin:.45em 0}
a{color:var(--teal-d); text-decoration:none}
small{color:var(--muted)}

.cover{height:247mm; display:flex; flex-direction:column; justify-content:center;
  padding:0 22mm; background:linear-gradient(150deg,var(--teal) 0%,var(--teal-d) 62%,#0d454e 100%);
  color:#fff; page-break-after:always}
.cover .kicker{font-size:12pt; letter-spacing:.32em; text-transform:uppercase; color:var(--olive); font-weight:700}
.cover h1{font-size:33pt; margin:.35em 0 .15em; font-weight:700; letter-spacing:-.01em}
.cover .sub{font-size:15pt; color:#d8ecef; font-weight:400; max-width:150mm}
.cover .aud{margin-top:26mm; font-size:11pt; color:#bfe0e4}
.cover .aud b{display:block; font-size:16pt; color:#fff; letter-spacing:.02em; margin-top:2mm}
.cover .meta{margin-top:auto; padding-top:14mm; border-top:2px solid rgba(255,255,255,.28);
  font-size:9.5pt; color:#bcdde1; display:flex; justify-content:space-between}

.toc{page-break-after:always; padding:16mm 18mm}
.toc h2{color:var(--teal); font-size:20pt; border-bottom:2px solid var(--olive); padding-bottom:3mm; margin:0 0 6mm}
.toc ol{list-style:none; margin:0; padding:0; counter-reset:toc}
.toc li{counter-increment:toc; padding:2.1mm 0; border-bottom:1px solid var(--line-soft);
  display:flex; gap:4mm; font-size:10.5pt}
.toc li::before{content:counter(toc) "."; color:var(--olive-d); font-weight:700; min-width:9mm}

section{page-break-before:always}
h2.sec{color:#fff; background:var(--teal); border-left:6px solid var(--olive);
  font-size:15.5pt; margin:0 0 5mm; padding:3.2mm 5mm; border-radius:2px}
h3{color:var(--teal-d); font-size:12.6pt; margin:7mm 0 2mm; border-bottom:1px solid var(--olive);
  padding-bottom:1.4mm}
h4{color:var(--ink); font-size:10.9pt; margin:5mm 0 1mm}

ul,ol{margin:.4em 0; padding-left:6.5mm}
li{margin:1.3mm 0}
ol.steps{counter-reset:st; list-style:none; padding-left:0; margin:3mm 0}
ol.steps>li{counter-increment:st; position:relative; padding:2.4mm 0 2.4mm 12mm; border-bottom:1px solid var(--line-soft)}
ol.steps>li:last-child{border-bottom:none}
ol.steps>li::before{content:counter(st); position:absolute; left:0; top:2.2mm;
  width:8mm; height:8mm; background:var(--teal); color:#fff; border-radius:50%;
  font-size:9pt; font-weight:700; display:flex; align-items:center; justify-content:center}

.box{border-radius:3px; padding:3mm 4mm; margin:3.5mm 0; font-size:9.9pt; page-break-inside:avoid}
.box b{text-transform:uppercase; letter-spacing:.04em; font-size:8.7pt}
.box.note{background:var(--note-bg); border-left:4px solid var(--note-line)}
.box.warn{background:var(--warn-bg); border-left:4px solid var(--warn-line); color:var(--warn-ink)}
.box.ok{background:var(--ok-bg); border-left:4px solid var(--ok-line)}

table{border-collapse:collapse; width:100%; margin:3.5mm 0; font-size:9.4pt; page-break-inside:avoid}
th,td{border:1px solid var(--line); padding:2mm 3mm; text-align:left; vertical-align:top}
th{background:var(--panel-2); color:var(--teal-d); font-weight:700}
tr:nth-child(even) td{background:var(--panel)}
td code, p code, li code{background:var(--code-bg); padding:.5mm 1.4mm; border-radius:2px;
  font-family:"Cascadia Mono",Consolas,monospace; font-size:8.7pt}
pre{background:#1e2732; color:#e8edf2; padding:3.5mm 4mm; border-radius:3px; overflow:auto;
  font-family:"Cascadia Mono",Consolas,monospace; font-size:8.5pt; line-height:1.45; margin:3mm 0;
  page-break-inside:avoid; white-space:pre-wrap}

.lead{font-size:11pt; color:var(--ink-soft); margin-bottom:5mm}
.role{display:inline-block; border:1px solid var(--teal); color:var(--teal-d); font-size:8pt;
  font-weight:700; padding:.4mm 1.8mm; border-radius:10px; margin-left:2mm}
hr.soft{border:none; border-top:1px solid var(--line-soft); margin:6mm 0}
.footer{margin-top:12mm; padding-top:4mm; border-top:1px solid var(--line);
  color:var(--muted); font-size:8.4pt; text-align:center}
"""


def esc(s):
    return html.escape(str(s), quote=False)


def p(t):
    return f"<p>{t}</p>"


def lead(t):
    return f"<p class='lead'>{t}</p>"


def h3(t):
    return f"<h3>{esc(t)}</h3>"


def h4(t):
    return f"<h4>{esc(t)}</h4>"


def ul(items):
    return "<ul>" + "".join(f"<li>{x}</li>" for x in items) + "</ul>"


def ol(items):
    return "<ol>" + "".join(f"<li>{x}</li>" for x in items) + "</ol>"


def steps(items):
    return "<ol class='steps'>" + "".join(f"<li>{x}</li>" for x in items) + "</ol>"


def note(text, kind="note", label=None):
    label = label or {"note": "Note", "warn": "Important", "ok": "Tip"}[kind]
    return f"<div class='box {kind}'><b>{label}</b> &nbsp;{text}</div>"


def table(headers, rows):
    h = "".join(f"<th>{c}</th>" for c in headers)
    b = "".join("<tr>" + "".join(f"<td>{c}</td>" for c in r) + "</tr>" for r in rows)
    return f"<table><thead><tr>{h}</tr></thead><tbody>{b}</tbody></table>"


def pre(text):
    return "<pre>" + text.replace("&", "&amp;").replace("<", "&lt;") + "</pre>"


def build(slug, title, subtitle, audience_name, intro, sections):
    toc_items, body = [], []
    n = 0
    for st, content in sections:
        n += 1
        toc_items.append(f"<li>{esc(st)}</li>")
        body.append(
            f"<section><h2 class='sec'>{n}. {esc(st)}</h2>{content}"
            f"<div class='footer'>{esc(title)} &nbsp;&middot;&nbsp; {VERSION} &nbsp;&middot;&nbsp; {DATE}</div></section>"
        )
    doc = f"""<!doctype html><html lang="en"><head><meta charset="utf-8">
<title>{esc(title)}</title><style>{CSS}</style></head><body>
<div class="cover">
  <div class="kicker">POS Mobile &middot; Cartivo</div>
  <h1>{esc(title)}</h1>
  <div class="sub">{esc(subtitle)}</div>
  <div class="aud">Written for<b>{esc(audience_name)}</b></div>
  <div class="meta"><span>{VERSION} &nbsp;&middot;&nbsp; {DATE}</span><span>Confidential &mdash; for authorized personnel</span></div>
</div>
<div class="toc"><h2>Contents</h2><ol>{''.join(toc_items)}</ol>
<p style="margin-top:8mm;color:var(--muted);font-size:9pt">Use your PDF reader's bookmarks / outline panel to jump between sections.</p>
{note(intro)}
</div>
{''.join(body)}
</body></html>"""
    hp = os.path.join(OUT, slug + ".html")
    pp = os.path.join(OUT, slug + ".pdf")
    with open(hp, "w", encoding="utf-8") as f:
        f.write(doc)
    subprocess.run(
        [CHROME, "--headless", "--disable-gpu", "--no-pdf-header-footer",
         f"--print-to-pdf={pp}", "--print-to-pdf-no-header", hp],
        check=True, capture_output=True,
    )
    print(f"  {slug}.html + .pdf  ({os.path.getsize(pp)//1024} KB pdf)")


# ===========================================================================
from content_user import SECTIONS as USER
from content_tech import SECTIONS as TECH

if __name__ == "__main__":
    print("Building POS Mobile manuals ->", OUT)
    build(
        "POSMobile-User-Manual",
        "POS Mobile \u2014 User Manual",
        "How to set up the app on a phone or tablet and use every screen, step by step.",
        "Store Owners, Managers, Supervisors & Cashiers",
        "This is a non-technical guide. It assumes the POS Mobile app is already "
        "installed on the device. If it still needs installing or configuring, hand "
        "your IT person the <i>POS Mobile \u2014 Technical Manual</i> first.",
        USER,
    )
    build(
        "POSMobile-Technical-Manual",
        "POS Mobile \u2014 Technical Manual",
        "Architecture, environment, local database, build and deployment for the Flutter POS app.",
        "Developers, Integrators & IT Staff",
        "The app lives in the <code>mobile/</code> folder of the repository. "
        "A Flutter SDK (Dart 3.7+), Android tooling, and a populated <code>.env</code> "
        "file are assumed.",
        TECH,
    )
    print("Done.")
