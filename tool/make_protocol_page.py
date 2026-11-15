"""Builds the clinician review page for the knee protocol: every phase,
session, dose, pain rule and moving-on check, with the exercise drawings.
It reads the app's own content files, so the page always matches the app.

    python3 tool/make_protocol_page.py [output.html]

Default output: build/joint-plus-knee-protocol.html (git-ignored). The page is
a single self-contained HTML file; the only external request is Google Fonts.
Run tool/make_illustrations.py first if the drawings changed.
"""

import html
import json
import math
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "build", "joint-plus-knee-protocol.html")

prog = json.load(open(os.path.join(ROOT, "assets/content/programs/knee_meniscus.json")))
EX = {e["id"]: e for e in json.load(open(os.path.join(ROOT, "assets/content/exercises.json")))["exercises"]}
E = html.escape

# ------------------------------------------------------------------ helpers

SIDES = {"each": "Each leg", "affected": "Injured leg", "together": "Both legs"}
GEAR = {"none": None, "band": "Band", "step": "Step / box", "monkii": "Pocket Monkii",
        "wall": "Wall", "towel": "Towel", "chair": "Chair"}
KIND = {"reps": "Reps", "hold": "Hold", "duration": "Timed"}


def rng(lo, hi):
    return f"{lo}" if hi is None or hi == lo else f"{lo}–{hi}"


def describe(d, ex):
    timed = "seconds" in d
    if timed:
        lo, hi = d["seconds"], d.get("secondsMax")
        if lo >= 120 and lo % 60 == 0 and (hi is None or hi % 60 == 0):
            amount = f"{rng(lo // 60, None if hi is None else hi // 60)} min"
        else:
            amount = f"{rng(lo, hi)} s"
    else:
        amount = rng(d["reps"], d.get("repsMax"))
    side = " / side" if ex["sides"] == "each" else ""
    return f"{amount}{side}" if d["sets"] == 1 and timed else f"{d['sets']} × {amount}{side}"


def minutes(session):
    total = 0
    for d in session["items"]:
        if d.get("optional"):
            continue
        ex = EX[d["ex"]]
        work = d.get("secondsMax", d.get("seconds")) if "seconds" in d else d.get("repsMax", d.get("reps")) * 4
        sides = 2 if ex["sides"] == "each" else 1
        rest = d.get("restSec", session["restSec"])
        total += d["sets"] * work * sides + (d["sets"] - 1) * rest + 20
    return math.ceil(total / 60)


def gear(ex):
    g = [GEAR[x] for x in ex["equipment"] if GEAR.get(x)]
    return " · ".join([SIDES[ex["sides"]]] + (g or ["No equipment"]))


def svg(ex_id, cls="ill"):
    s = open(os.path.join(ROOT, f"assets/illustrations/{ex_id}.svg")).read()
    s = s.replace('stroke="#FFFFFF"', 'stroke="currentColor"').replace('fill="#FFFFFF"', 'fill="currentColor"')
    s = s.replace('stroke="#00E676"', 'class="ac"').replace('fill="#00E676"', 'class="acf"')
    s = s.replace("<svg ", f'<svg class="{cls}" role="img" aria-label="{E(EX[ex_id]["name"])} drawing" ', 1)
    return re.sub(r"\n", "", s)


def gate_kind(g):
    if g["type"] == "check":
        return ("Self-test", "yes / no", "self")
    if g["type"] == "number":
        return ("Measured", f"≥ {g['min']} {g.get('unit', '')}".strip(), "measure")
    return ("Tracked by the app", f"≥ {g['min']} days", "auto")


phases = prog["phases"]
pr = prog["painRules"]

# ------------------------------------------------------------------ styles

CSS = r"""
/* Layout: one reading column (~72ch) with full-width bands for the timeline,
   the decision flow and the exercise library. Dark-first like the app. */
:root {
  --bg: #050706;
  --surface: #0E1311;
  --raise: #151B18;
  --line: #24302B;
  --fg: #F2F6F4;
  --muted: #8C9A94;
  --accent: #00E676;
  --accent-soft: rgba(0, 230, 118, 0.12);
  --accent-ink: #00170B;
  --warn: #FFB547;
  --warn-soft: rgba(255, 181, 71, 0.12);
  --danger: #FF6B5E;
  --danger-soft: rgba(255, 107, 94, 0.12);
  --ill: #F2F6F4;
  --font-display: "Archivo", "Helvetica Neue", Arial, sans-serif;
  --font-body: "IBM Plex Sans", "Helvetica Neue", Arial, sans-serif;
  --font-mono: "IBM Plex Mono", ui-monospace, "SF Mono", Menlo, monospace;
  color-scheme: dark;
}
@media (prefers-color-scheme: light) {
  :root:not([data-theme="dark"]) {
    --bg: #F4F7F5; --surface: #FFFFFF; --raise: #EDF2EF; --line: #D5DED9;
    --fg: #0C1310; --muted: #55635D; --accent: #00804A; --accent-soft: rgba(0, 128, 74, 0.09);
    --accent-ink: #FFFFFF; --warn: #A15C00; --warn-soft: rgba(161, 92, 0, 0.09);
    --danger: #C0312A; --danger-soft: rgba(192, 49, 42, 0.08); --ill: #0C1310;
    color-scheme: light;
  }
}
:root[data-theme="light"] {
  --bg: #F4F7F5; --surface: #FFFFFF; --raise: #EDF2EF; --line: #D5DED9;
  --fg: #0C1310; --muted: #55635D; --accent: #00804A; --accent-soft: rgba(0, 128, 74, 0.09);
  --accent-ink: #FFFFFF; --warn: #A15C00; --warn-soft: rgba(161, 92, 0, 0.09);
  --danger: #C0312A; --danger-soft: rgba(192, 49, 42, 0.08); --ill: #0C1310;
  color-scheme: light;
}

* { box-sizing: border-box; }
body {
  background: var(--bg); color: var(--fg);
  font: 16px/1.6 var(--font-body);
  -webkit-font-smoothing: antialiased;
}
.wrap {
  max-width: 1080px; margin: 0 auto;
  padding-left: max(16px, env(safe-area-inset-left, 0px));
  padding-right: max(16px, env(safe-area-inset-right, 0px));
}
.col { max-width: 72ch; }
h1, h2, h3, h4 { font-family: var(--font-display); text-wrap: balance; margin: 0; line-height: 1.12; }
h1 { font-size: clamp(2.4rem, 7vw, 4.4rem); font-weight: 800; letter-spacing: -0.03em; }
h2 { font-size: clamp(1.6rem, 4vw, 2.2rem); font-weight: 800; letter-spacing: -0.02em; }
h3 { font-size: 1.25rem; font-weight: 700; }
h4 { font-size: 1rem; font-weight: 700; }
p { margin: 0; }
a { color: var(--accent); text-underline-offset: 3px; }
a:focus-visible, summary:focus-visible { outline: 2px solid var(--accent); outline-offset: 3px; }
.label {
  font: 600 0.72rem/1.2 var(--font-mono); text-transform: uppercase;
  letter-spacing: 0.14em; color: var(--muted);
}
.label.acc { color: var(--accent); }
.mono { font-family: var(--font-mono); font-variant-numeric: tabular-nums; }
.muted { color: var(--muted); }
.stack { display: flex; flex-direction: column; gap: 12px; }

section { padding-block: 56px; border-top: 1px solid var(--line); }
.sec-head { display: flex; flex-direction: column; gap: 10px; margin-bottom: 28px; }

/* Masthead */
header.mast { padding-block: 48px 40px; }
.mast .grid { display: grid; grid-template-columns: 1fr auto; gap: 32px; align-items: end; }
.mast .lede { font-size: 1.15rem; color: var(--muted); max-width: 60ch; margin-top: 18px; }
.mast .lede strong { color: var(--fg); font-weight: 600; }
.mark { width: 112px; height: 112px; }
.disclaimer {
  margin-top: 28px; padding: 16px 18px; border: 1px solid var(--line);
  border-left: 3px solid var(--warn); background: var(--warn-soft); max-width: 78ch;
}
.disclaimer p { font-size: 0.95rem; }
.toc { display: flex; flex-wrap: wrap; gap: 8px 22px; margin-top: 28px; }
.toc a { color: var(--fg); text-decoration: none; font: 500 0.9rem var(--font-body); border-bottom: 1px solid var(--line); padding-bottom: 2px; }
.toc a:hover { border-color: var(--accent); }
.meta-row { display: flex; flex-wrap: wrap; gap: 8px 24px; margin-top: 18px; }

/* Facts strip */
.facts { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 1px; background: var(--line); border: 1px solid var(--line); }
.fact { background: var(--surface); padding: 18px; display: flex; flex-direction: column; gap: 6px; min-width: 0; }
.fact .v { font: 700 1.6rem/1.1 var(--font-display); }
.fact .v small { font-size: 0.95rem; color: var(--muted); font-weight: 600; }

/* Phase timeline */
.timeline { display: flex; gap: 0; align-items: stretch; margin-top: 28px; }
.tl-phase { min-width: 0; display: flex; flex-direction: column; gap: 10px; }
.tl-bar {
  height: 44px; background: var(--accent-soft); border: 1px solid var(--accent);
  display: flex; align-items: center; padding: 0 12px; gap: 10px;
  font: 700 0.95rem var(--font-display); color: var(--fg); white-space: nowrap; overflow: hidden;
}
.tl-bar .n { font: 700 0.75rem var(--font-mono); background: var(--accent); color: var(--accent-ink); padding: 2px 6px; }
.tl-gate { width: 34px; flex: none; display: flex; flex-direction: column; align-items: center; }
.tl-gate .diamond { width: 16px; height: 16px; transform: rotate(45deg); background: var(--bg); border: 2px solid var(--accent); margin-top: 14px; }
.tl-gate .gl { font: 600 0.62rem var(--font-mono); letter-spacing: .1em; color: var(--muted); margin-top: 10px; text-transform: uppercase; writing-mode: vertical-rl; }
.tl-phase .goal { font-size: 0.9rem; color: var(--muted); padding-right: 8px; }
.tl-phase .days { font: 500 0.8rem var(--font-mono); color: var(--fg); }
.tl-end { display: flex; flex-direction: column; justify-content: flex-start; padding-left: 10px; flex: none; }
.tl-end .pill { height: 44px; display: flex; align-items: center; padding: 0 12px; border: 1px dashed var(--muted); font: 600 0.8rem var(--font-mono); color: var(--muted); white-space: nowrap; }

/* Week */
.week { display: grid; grid-template-columns: repeat(7, minmax(0, 1fr)); gap: 6px; max-width: 560px; }
.day { border: 1px solid var(--line); background: var(--surface); padding: 10px 6px; display: flex; flex-direction: column; align-items: center; gap: 8px; }
.day .d { font: 600 0.75rem var(--font-mono); color: var(--muted); }
.chip-m, .chip-s { width: 100%; text-align: center; font: 600 0.62rem var(--font-mono); letter-spacing: .06em; padding: 4px 0; }
.chip-m { border: 1px solid var(--line); color: var(--muted); }
.chip-s { background: var(--accent); color: var(--accent-ink); }
.legend { display: flex; flex-wrap: wrap; gap: 8px 20px; margin-top: 12px; font-size: 0.85rem; color: var(--muted); }
.legend span { display: inline-flex; align-items: center; gap: 8px; }
.sw { width: 14px; height: 14px; display: inline-block; }

/* Pain scale */
.scale { display: grid; grid-template-columns: repeat(11, minmax(0, 1fr)); max-width: 720px; border: 1px solid var(--line); }
.cell { height: 52px; display: flex; align-items: center; justify-content: center; font: 700 1.05rem var(--font-mono); border-right: 1px solid var(--line); }
.cell:last-child { border-right: 0; }
.cell.ok { background: var(--accent); color: var(--accent-ink); }
.cell.over { background: var(--danger-soft); color: var(--danger); }
.scale-caps { display: grid; grid-template-columns: 4fr 7fr; max-width: 720px; margin-top: 8px; gap: 8px; }
.scale-caps div { font-size: 0.85rem; }
.scale-caps .r { text-align: right; color: var(--danger); }
.scale-caps .l { color: var(--accent); }

.rules { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 16px; margin-top: 32px; }
.rule { background: var(--surface); border: 1px solid var(--line); padding: 20px; display: flex; flex-direction: column; gap: 10px; min-width: 0; }
.rule .big { font: 800 2rem/1 var(--font-display); color: var(--accent); }
.rule p { font-size: 0.95rem; }

.split2 { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; margin-top: 16px; }
.flags { border: 1px solid var(--danger); background: var(--danger-soft); padding: 20px; min-width: 0; }
.flags ul, .protect ul { margin: 12px 0 0; padding-left: 1.1em; display: flex; flex-direction: column; gap: 6px; }
.flags li::marker { color: var(--danger); }
.protect { border: 1px solid var(--line); background: var(--surface); padding: 20px; min-width: 0; }
.protect li::marker { color: var(--accent); }

/* Decision flow */
.flow { display: flex; flex-direction: column; align-items: stretch; gap: 0; max-width: 900px; }
.frow { display: grid; gap: 14px; }
.frow.two { grid-template-columns: repeat(2, minmax(0, 1fr)); }
.frow.three { grid-template-columns: repeat(3, minmax(0, 1fr)); }
.node { border: 1px solid var(--line); background: var(--surface); padding: 16px 18px; display: flex; flex-direction: column; gap: 6px; min-width: 0; }
.node p { font-size: 0.93rem; }
.node.decision { border: 2px solid var(--fg); background: var(--raise); }
.node.decision ol { margin: 8px 0 0; padding-left: 1.3em; display: flex; flex-direction: column; gap: 6px; font-size: 0.95rem; }
.node.good { border-color: var(--accent); background: var(--accent-soft); }
.node.hold { border-color: var(--warn); background: var(--warn-soft); }
.node.drop { border-color: var(--danger); background: var(--danger-soft); }
.node.goal { border: 2px solid var(--accent); }
.node .label.g { color: var(--accent); } .node .label.w { color: var(--warn); } .node .label.r { color: var(--danger); }
.arrow { height: 34px; display: flex; justify-content: center; }
.arrow svg { width: 20px; height: 34px; }
.arrow path { stroke: var(--muted); fill: none; stroke-width: 2; }
.arrow.left { justify-content: flex-start; padding-left: 15%; }
.goalrow { display: grid; grid-template-columns: minmax(0, 2fr) auto minmax(0, 1fr); gap: 14px; align-items: stretch; }
.goalrow .h { display: flex; align-items: center; }
.goalrow .h svg { width: 34px; height: 20px; }
.goalrow .h path { stroke: var(--muted); fill: none; stroke-width: 2; }
.notes { margin-top: 28px; display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px 28px; }
.notes div { font-size: 0.93rem; min-width: 0; }
.notes strong { font-weight: 600; }

/* Phase sections */
.phase-head { display: grid; grid-template-columns: auto 1fr; gap: 20px; align-items: start; }
.phase-num { font: 800 clamp(4rem, 12vw, 6.5rem)/0.82 var(--font-display); color: var(--accent); letter-spacing: -0.04em; }
.phase-goal { font-size: 1.1rem; margin-top: 10px; max-width: 60ch; }
.cautions { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 14px; }
.caution { font-size: 0.85rem; border: 1px solid var(--warn); color: var(--warn); padding: 4px 10px; }
.sessions { display: grid; grid-template-columns: minmax(0, 1.35fr) minmax(0, 1fr); gap: 20px; margin-top: 30px; }
.sess { border: 1px solid var(--line); background: var(--surface); min-width: 0; }
.sess-head { display: flex; justify-content: space-between; align-items: baseline; gap: 12px; padding: 14px 16px; border-bottom: 1px solid var(--line); flex-wrap: wrap; }
.sess-head h3 { font-size: 1.1rem; }
.ex-row { display: grid; grid-template-columns: 92px minmax(0, 1fr) auto; gap: 14px; align-items: center; padding: 10px 16px 10px 8px; border-bottom: 1px solid var(--line); }
.ex-row:last-child { border-bottom: 0; }
.ex-row .ill { width: 92px; height: auto; color: var(--ill); }
.ex-row .nm { font-weight: 600; }
.ex-row .sub { font-size: 0.8rem; color: var(--muted); }
.ex-row .note { font-size: 0.82rem; color: var(--fg); margin-top: 4px; border-left: 2px solid var(--accent); padding-left: 8px; }
.ex-row .dose { text-align: right; }
.ex-row .dose .d { font: 600 0.95rem var(--font-mono); color: var(--accent); white-space: nowrap; }
.ex-row .dose .r { font: 500 0.75rem var(--font-mono); color: var(--muted); white-space: nowrap; }
.opt { font: 600 0.62rem var(--font-mono); letter-spacing: .1em; text-transform: uppercase; border: 1px solid var(--muted); color: var(--muted); padding: 1px 5px; margin-left: 6px; vertical-align: 2px; }
.ex-row.optional .ill { opacity: .6; }

.gate { margin-top: 22px; border: 2px solid var(--accent); }
.gate-head { display: flex; justify-content: space-between; align-items: center; gap: 12px; padding: 14px 16px; background: var(--accent-soft); border-bottom: 1px solid var(--accent); flex-wrap: wrap; }
.gate-head h3 { font-size: 1.1rem; }
.crit { display: grid; grid-template-columns: 28px minmax(0, 1fr) auto; gap: 14px; padding: 14px 16px; border-bottom: 1px solid var(--line); align-items: start; }
.crit:last-child { border-bottom: 0; }
.box { width: 20px; height: 20px; border: 2px solid var(--accent); margin-top: 3px; }
.crit .t { font-weight: 600; }
.crit .h { font-size: 0.85rem; color: var(--muted); margin-top: 4px; }
.crit .k { text-align: right; display: flex; flex-direction: column; align-items: flex-end; gap: 4px; }
.tag { font: 600 0.66rem var(--font-mono); letter-spacing: .08em; text-transform: uppercase; padding: 3px 7px; white-space: nowrap; }
.tag.self { border: 1px solid var(--fg); }
.tag.measure { background: var(--fg); color: var(--bg); }
.tag.auto { border: 1px dashed var(--muted); color: var(--muted); }
.crit .thr { font: 600 0.85rem var(--font-mono); color: var(--accent); white-space: nowrap; }
.maint { margin-top: 18px; padding: 16px; border: 1px dashed var(--accent); }

/* Library */
.lib { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 16px; }
.card { border: 1px solid var(--line); background: var(--surface); display: flex; flex-direction: column; min-width: 0; }
.card .ill { width: 100%; height: auto; color: var(--ill); background: var(--bg); border-bottom: 1px solid var(--line); display: block; }
.card .body { padding: 14px 16px 16px; display: flex; flex-direction: column; gap: 8px; }
.card .used { display: flex; flex-wrap: wrap; gap: 4px; }
.card .used span { font: 600 0.64rem var(--font-mono); background: var(--accent-soft); color: var(--accent); padding: 2px 6px; }
.card .used span.x { background: transparent; border: 1px solid var(--line); color: var(--muted); }
.card p { font-size: 0.9rem; }
.card ol, .card ul { margin: 0; padding-left: 1.2em; font-size: 0.86rem; display: flex; flex-direction: column; gap: 4px; }
.card ol li::marker { color: var(--accent); font-family: var(--font-mono); font-weight: 600; }
.card ul li::marker { color: var(--danger); }
.chain { display: flex; flex-wrap: wrap; align-items: center; gap: 6px; font-size: 0.8rem; color: var(--muted); }
.chain b { color: var(--fg); font-weight: 600; }

/* Review questions */
.qs { counter-reset: q; display: flex; flex-direction: column; gap: 0; border-top: 1px solid var(--line); max-width: 860px; }
.q { counter-increment: q; display: grid; grid-template-columns: 48px minmax(0, 1fr); gap: 12px; padding: 18px 0; border-bottom: 1px solid var(--line); }
.q::before { content: counter(q, decimal-leading-zero); font: 700 0.9rem var(--font-mono); color: var(--accent); padding-top: 2px; }
.q p { font-size: 0.93rem; color: var(--muted); margin-top: 4px; }
.q h4 { font-size: 1.02rem; }

footer { padding-block: 40px 64px; border-top: 1px solid var(--line); color: var(--muted); font-size: 0.85rem; }

.ill .ac { stroke: var(--accent); }
.ill .acf { fill: var(--accent); }

@media (max-width: 860px) {
  .sessions { grid-template-columns: minmax(0, 1fr); }
  .rules { grid-template-columns: minmax(0, 1fr); }
  .facts { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}
@media (max-width: 680px) {
  .mast .grid { grid-template-columns: 1fr; }
  .mark { display: none; }
  .split2, .notes, .frow.two, .frow.three { grid-template-columns: minmax(0, 1fr); }
  .goalrow { grid-template-columns: minmax(0, 1fr); }
  .goalrow .h { justify-content: center; transform: rotate(90deg); height: 34px; }
  .arrow.left { justify-content: center; padding-left: 0; }
  .timeline { flex-direction: column; gap: 6px; }
  .tl-phase { flex: none !important; }
  .tl-gate { flex-direction: row; width: auto; gap: 10px; padding-left: 14px; }
  .tl-gate .diamond { margin-top: 0; }
  .tl-gate .gl { writing-mode: horizontal-tb; margin-top: 0; }
  .tl-end { padding-left: 0; }
  .ex-row { grid-template-columns: 72px minmax(0, 1fr); }
  .ex-row .ill { width: 72px; }
  .ex-row .dose { grid-column: 2; text-align: left; }
  .crit { grid-template-columns: 24px minmax(0, 1fr); }
  .crit .k { grid-column: 2; align-items: flex-start; flex-direction: row; flex-wrap: wrap; }
  .phase-head { grid-template-columns: minmax(0, 1fr); gap: 6px; }
  section { padding-block: 40px; }
}
@media (prefers-reduced-motion: no-preference) {
  .toc a { transition: border-color .15s; }
}
"""

# ------------------------------------------------------------------ content

def where_used():
    used = {k: [] for k in EX}
    for ph in phases:
        for s in ph["sessions"].values():
            for d in s["items"]:
                tag = f"P{phases.index(ph) + 1}"
                if tag not in used[d["ex"]]:
                    used[d["ex"]].append(tag)
    return used


USED = where_used()
easier_of = {e["harder"]: e["id"] for e in EX.values() if e.get("harder")}


def session_block(ph, kind):
    s = ph["sessions"][kind]
    title = "Strength" if kind == "strength" else "Daily mobility"
    if s["name"] not in ("Strength", "Mobility"):
        title = f'{s["name"]} (strength day)'
    freq = f'{prog["strengthDaysPerWeek"]}× a week' if kind == "strength" else "Every day"
    rows = []
    for d in s["items"]:
        ex = EX[d["ex"]]
        rest = d.get("restSec", s["restSec"])
        rest_s = f"rest {rest} s" if d["sets"] > 1 else ""
        opt = '<span class="opt">Optional</span>' if d.get("optional") else ""
        note = f'<div class="note">{E(d["note"])}</div>' if d.get("note") else ""
        rows.append(f"""
        <div class="ex-row{' optional' if d.get('optional') else ''}">
          {svg(d['ex'])}
          <div><div class="nm">{E(ex['name'])}{opt}</div><div class="sub">{E(gear(ex))}</div>{note}</div>
          <div class="dose"><div class="d">{E(describe(d, ex))}</div><div class="r">{rest_s}</div></div>
        </div>""")
    return f"""
    <div class="sess">
      <div class="sess-head"><h3>{E(title)}</h3><span class="label">{freq} · ~{minutes(s)} min</span></div>
      {''.join(rows)}
    </div>"""


def phase_section(i, ph):
    last = i == len(phases) - 1
    crits = []
    for g in ph["gate"]:
        kind, thr, cls = gate_kind(g)
        help_ = f'<div class="h">{E(g["help"])}</div>' if g.get("help") else ""
        crits.append(f"""
        <div class="crit"><div class="box" aria-hidden="true"></div>
          <div><div class="t">{E(g['text'])}</div>{help_}</div>
          <div class="k"><span class="tag {cls}">{kind}</span><span class="thr">{E(thr)}</span></div>
        </div>""")
    crits.append(f"""
        <div class="crit"><div class="box" aria-hidden="true"></div>
          <div><div class="t">At least {ph['minDays']} days in this phase</div>
          <div class="h">A floor, not a target. Most people will take longer.</div></div>
          <div class="k"><span class="tag auto">Tracked by the app</span><span class="thr">≥ {ph['minDays']} days</span></div>
        </div>""")
    nxt = "graduate to maintenance" if last else f"move to Phase {i + 2}"
    maint = (f'<div class="maint"><span class="label acc">After graduation</span>'
             f'<p style="margin-top:6px">Maintenance: {E(prog["maintenance"])}</p></div>') if last else ""
    return f"""
<section id="phase-{i + 1}">
  <div class="wrap">
    <div class="phase-head">
      <div class="phase-num">{i + 1}</div>
      <div>
        <span class="label">Phase {i + 1} of {len(phases)} · minimum {ph['minDays']} days</span>
        <h2 style="margin-top:8px">{E(ph['name'])}</h2>
        <p class="phase-goal">{E(ph['goal'])}</p>
        <div class="cautions">{''.join(f'<span class="caution">{E(c)}</span>' for c in ph.get('cautions', []))}</div>
      </div>
    </div>
    <div class="sessions">
      {session_block(ph, 'strength')}
      {session_block(ph, 'daily')}
    </div>
    <div class="gate">
      <div class="gate-head"><h3>{'To graduate' if last else 'Checks to move on'}</h3>
        <span class="label acc">All must be met to {nxt}</span></div>
      {''.join(crits)}
    </div>
    {maint}
  </div>
</section>"""


def library():
    cards = []
    for ex in EX.values():
        used = USED[ex["id"]]
        used_html = "".join(f"<span>{u}</span>" for u in used) or '<span class="x">Swap only</span>'
        chain = []
        if ex.get("easier"):
            chain.append(f'Easier: <b>{E(EX[ex["easier"]]["name"])}</b>')
        if ex.get("harder"):
            chain.append(f'Harder: <b>{E(EX[ex["harder"]]["name"])}</b>')
        cues = "".join(f"<li>{E(c)}</li>" for c in ex["cues"])
        mistakes = "".join(f"<li>{E(m)}</li>" for m in ex.get("mistakes", []))
        cards.append(f"""
      <article class="card" id="ex-{ex['id'].replace('_', '-')}">
        {svg(ex['id'])}
        <div class="body">
          <div class="used">{used_html}<span class="x">{KIND[ex['kind']]}</span></div>
          <h4>{E(ex['name'])}</h4>
          <span class="label">{E(gear(ex))}</span>
          <p>{E(ex['summary'])}</p>
          <ol>{cues}</ol>
          {f'<ul>{mistakes}</ul>' if mistakes else ''}
          {f'<div class="chain">{" · ".join(chain)}</div>' if chain else ''}
        </div>
      </article>""")
    return "".join(cards)


def timeline():
    parts = []
    for i, ph in enumerate(phases):
        parts.append(f"""
      <div class="tl-phase" style="flex:{ph['minDays']} 1 0">
        <div class="tl-bar"><span class="n">P{i + 1}</span>{E(ph['name'])}</div>
        <span class="days">≥ {ph['minDays']} days</span>
        <p class="goal">{E(ph['goal'])}</p>
      </div>""")
        parts.append(f"""
      <div class="tl-gate" aria-hidden="true"><div class="diamond"></div><div class="gl">{'Graduate' if i == len(phases) - 1 else 'Gate'}</div></div>""")
    parts.append('<div class="tl-end"><div class="pill">Maintenance</div></div>')
    return "".join(parts)


ARROW_DOWN = '<div class="arrow" aria-hidden="true"><svg viewBox="0 0 20 34"><path d="M10 2 V30 M3 23 L10 31 L17 23"/></svg></div>'
ARROW_RIGHT = '<div class="h" aria-hidden="true"><svg viewBox="0 0 34 20"><path d="M2 10 H30 M23 3 L31 10 L23 17"/></svg></div>'

total_items = sum(len(s["items"]) for ph in phases for s in ph["sessions"].values())
min_total = sum(ph["minDays"] for ph in phases)

PAGE = f"""<title>Joint+ Knee Protocol</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Archivo:wght@600;700;800&family=IBM+Plex+Mono:wght@500;600;700&family=IBM+Plex+Sans:wght@400;500;600&display=swap">
<style>{CSS}</style>

<header class="mast">
  <div class="wrap">
    <div class="grid">
      <div>
        <span class="label acc">For clinical review · Knee: inflammation and meniscus strain</span>
        <h1 style="margin-top:14px">Joint+ Knee Protocol</h1>
        <p class="lede">A four-phase, <strong>criteria-based</strong> rehab progression as built into the Joint+ app.
        Patients move up when they pass each phase's checks, not after a fixed number of weeks.
        This page lays out every exercise, dose, rule and check the app uses, so you can review it and say what to change.</p>
      </div>
      <svg class="mark" viewBox="0 0 128 128" aria-hidden="true">
        <rect x="52" y="8" width="24" height="112" fill="currentColor"/>
        <rect x="8" y="52" width="112" height="24" fill="currentColor"/>
        <circle cx="64" cy="64" r="22" fill="var(--bg)"/>
        <circle cx="64" cy="64" r="17" fill="var(--accent)"/>
      </svg>
    </div>
    <div class="disclaimer"><p><strong>Draft for review.</strong> This is a self-guided program written by the patient (with an AI assistant) from common
      evidence-informed patterns: criteria-based phases, the pain-monitoring model, and protecting the meniscus from loaded deep flexion
      and twisting early. It has not been reviewed by a clinician yet. Your feedback decides what changes.</p></div>
    <nav class="toc" aria-label="Contents">
      <a href="#overview">Overview</a><a href="#safety">Pain rules and red flags</a><a href="#decisions">How it decides</a>
      {''.join(f'<a href="#phase-{i + 1}">Phase {i + 1}</a>' for i in range(len(phases)))}
      <a href="#library">Exercise library</a><a href="#questions">Questions for you</a>
    </nav>
  </div>
</header>

<section id="overview">
  <div class="wrap">
    <div class="sec-head"><span class="label acc">Overview</span><h2>Four phases, each with a gate</h2>
      <p class="col muted">{E(prog['description'])} Bar widths below show each phase's minimum length; the real length depends on passing the checks.</p></div>
    <div class="facts">
      <div class="fact"><span class="label">Phases</span><span class="v">{len(phases)}</span></div>
      <div class="fact"><span class="label">Shortest possible route</span><span class="v">{min_total} <small>days</small></span></div>
      <div class="fact"><span class="label">Exercises in the library</span><span class="v">{len(EX)}</span></div>
      <div class="fact"><span class="label">Pain ceiling during exercise</span><span class="v">{pr['maxDuring']}<small>/10</small></span></div>
    </div>
    <div class="timeline">{timeline()}</div>

    <div class="split2" style="margin-top:40px">
      <div class="stack">
        <h3>A typical week</h3>
        <p class="muted" style="font-size:.95rem">A short mobility session every day (about 10 minutes), plus a strength session
        {prog['strengthDaysPerWeek']} times a week on non-consecutive days (about 30–35 minutes). The patient picks the strength days; Monday, Wednesday and Friday are the default.</p>
        <div class="week">
          {''.join(f'<div class="day"><span class="d">{d}</span><span class="chip-m">MOB</span>{"<span class=chip-s>STR</span>" if s else ""}</div>' for d, s in zip("MTWTFSS", [1,0,1,0,1,0,0]))}
        </div>
        <div class="legend"><span><i class="sw" style="border:1px solid var(--line)"></i>Daily mobility</span><span><i class="sw" style="background:var(--accent)"></i>Strength</span></div>
      </div>
      <div class="stack">
        <h3>Equipment</h3>
        <p class="muted" style="font-size:.95rem">Home setup only: bodyweight, resistance bands, a step or box, a chair, a wall, a towel,
        and a Pocket Monkii suspension trainer (straps from a door anchor) used to unload squats and split squats early on.</p>
        <h3 style="margin-top:12px">Each session in the app</h3>
        <p class="muted" style="font-size:.95rem">Pain is rated 0–10 before starting and as the worst pain after finishing. The player guides one set at a time,
        injured leg first, with hold and rest timers. Cue on every rep set: <em>the last 2–3 reps should feel hard; pain up to {pr['maxDuring']}/10 is fine.</em></p>
      </div>
    </div>
  </div>
</section>

<section id="safety">
  <div class="wrap">
    <div class="sec-head"><span class="label acc">Safety</span><h2>Pain-monitoring rules</h2>
      <p class="col muted">The same rules apply in every phase. They drive both the day-to-day advice and the "days meeting the pain rules" check in each gate.</p></div>
    <div class="scale" role="img" aria-label="Pain scale 0 to 10. 0 to 3 acceptable during exercise; 4 and above is over the limit.">
      {''.join(f'<div class="cell {"ok" if n <= pr["maxDuring"] else "over"}">{n}</div>' for n in range(11))}
    </div>
    <div class="scale-caps"><div class="l">0–{pr['maxDuring']}: acceptable during exercise</div><div class="r">{pr['maxDuring'] + 1}–10: over the limit, ease off</div></div>

    <div class="rules">
      <div class="rule"><span class="label">During exercise</span><span class="big">≤ {pr['maxDuring']}/10</span>
        <p>Worst pain in a session stays at {pr['maxDuring']} or below. A higher score breaks the rules for the next morning.</p></div>
      <div class="rule"><span class="label">Afterwards</span><span class="big">{pr['settleHours']} h</span>
        <p>Any pain from exercise settles back to baseline within {pr['settleHours']} hours.</p></div>
      <div class="rule"><span class="label">Next morning</span><span class="big">No worse</span>
        <p>Morning pain no higher than the previous check-in, and swelling and stiffness not "more" than the day before.</p></div>
    </div>

    <div class="split2" style="margin-top:24px">
      <div class="flags"><span class="label" style="color:var(--danger)">Red flags</span>
        <h3 style="margin-top:8px">Stop and contact a clinician if</h3>
        <ul>{''.join(f'<li>{E(f)}</li>' for f in prog['redFlags'])}</ul>
        <p class="muted" style="font-size:.85rem;margin-top:12px">Always visible on the app's Program screen and in the check-in when swelling or stiffness is worse.</p></div>
      <div class="protect"><span class="label acc">Meniscus protection</span>
        <h3 style="margin-top:8px">Built into the phase order</h3>
        <ul>
          <li>Phases 1–2: no loaded knee bending past about 90°.</li>
          <li>Phases 1–3: no twisting or pivoting under load.</li>
          <li>Phase 3: deeper bending is added gradually, only to a pain-free depth, stopping at any pinch.</li>
          <li>Phase 4: impact, deceleration and pivoting, starting with squat jumps until landings are soft.</li>
        </ul></div>
    </div>
  </div>
</section>

<section id="decisions">
  <div class="wrap">
    <div class="sec-head"><span class="label acc">How it decides</span><h2>From daily check-in to moving up</h2>
      <p class="col muted">The app judges each morning against the pain rules, keeps a running count of good mornings in the current phase, and gives one of three kinds of advice. Moving up or dropping back always needs the patient to confirm.</p></div>
    <div class="flow">
      <div class="frow two">
        <div class="node"><span class="label">Input · every morning</span><h4>Morning check-in</h4>
          <p>Knee pain 0–10, and swelling and stiffness compared with yesterday (less, same or more). Three taps.</p></div>
        <div class="node"><span class="label">Input · from yesterday</span><h4>Session pain</h4>
          <p>The worst pain reported after each session the day before (0–10).</p></div>
      </div>
      {ARROW_DOWN}
      <div class="node decision"><span class="label">Decision</span><h4>Does this morning meet the pain rules?</h4>
        <p class="muted">It does only if all four are true:</p>
        <ol>
          <li>No session yesterday went above {pr['maxDuring']}/10.</li>
          <li>Swelling is not "more" than yesterday.</li>
          <li>Stiffness is not "more" than yesterday.</li>
          <li>Morning pain is no higher than at the previous check-in.</li>
        </ol>
        <p class="muted" style="margin-top:8px">A day with no check-in is skipped: it neither counts nor breaks the run.</p></div>
      {ARROW_DOWN}
      <div class="frow three">
        <div class="node good"><span class="label g">Met</span><h4>+1 good day</h4>
          <p>Adds to the run of good mornings in this phase. The run is what the "days meeting the pain rules" check counts.</p></div>
        <div class="node hold"><span class="label w">Broken once</span><h4>Repeat this dose</h4>
          <p>Today shows the reason and advises keeping the same exercises and doses, with no move to harder versions. The run of good days restarts.</p></div>
        <div class="node drop"><span class="label r">Broken two mornings running</span><h4>Suggest dropping back</h4>
          <p>Offers to move down one phase; the patient confirms. In Phase 1 it advises keeping things gentle and contacting a clinician if it doesn't settle.</p></div>
      </div>
      <div class="arrow left" aria-hidden="true"><svg viewBox="0 0 20 34"><path d="M10 2 V30 M3 23 L10 31 L17 23"/></svg></div>
      <div class="goalrow">
        <div class="node goal"><span class="label g">Gate</span><h4>All checks for the phase are met</h4>
          <p>Every self-test passed and every measurement reached, plus enough good mornings in a row, plus the phase's minimum number of days.</p></div>
        {ARROW_RIGHT}
        <div class="node good"><span class="label g">Then</span><h4>Move up a phase</h4>
          <p>The patient confirms. The new phase starts with new sessions and its checks start fresh.</p></div>
      </div>
    </div>
    <div class="notes">
      <div><strong>Entry check.</strong> At the start, the Phase 1 checks are asked as yes/no questions, plus "the knee has settled after activity this past week, with no increase in swelling". All yes suggests Phase 2; anything else suggests Phase 1. The patient can choose either.</div>
      <div><strong>Checks reset every phase.</strong> Self-test answers and good-day counts only count from the day a phase began, including after a drop-back, so each phase is earned again.</div>
      <div><strong>Stale advice is ignored.</strong> Flare-up advice only looks at the latest check-in when it is from today or yesterday.</div>
      <div><strong>Easier and harder versions.</strong> Every exercise links to an easier and a harder version. Swaps are the patient's choice; the app never progresses an exercise automatically.</div>
    </div>
  </div>
</section>

{''.join(phase_section(i, ph) for i, ph in enumerate(phases))}

<section id="library">
  <div class="wrap">
    <div class="sec-head"><span class="label acc">Exercise library</span><h2>All {len(EX)} exercises</h2>
      <p class="col muted">Each card shows the app's drawing (green marks the working area or the direction of movement; the faint figure is the starting position),
      the form cues, the common mistakes to avoid, the phases that use it, and its easier and harder versions. Exercises marked "Swap only" appear as an easier or harder option rather than in a session.</p></div>
    <div class="lib">{library()}</div>
  </div>
</section>

<section id="questions">
  <div class="wrap">
    <div class="sec-head"><span class="label acc">For you</span><h2>Questions for the reviewing clinician</h2>
      <p class="col muted">These are the decisions in the protocol that most need a professional opinion. Notes against a phase or an exercise name are easiest to act on.</p></div>
    <div class="qs">
      <div class="q"><div><h4>Is {pr['maxDuring']}/10 the right pain ceiling during exercise for this knee?</h4><p>It is also the threshold that breaks the next morning's pain rules.</p></div></div>
      <div class="q"><div><h4>Is the morning rule too strict?</h4><p>Any rise in morning pain, even 1 point, from the previous check-in breaks the day and resets the run of good days.</p></div></div>
      <div class="q"><div><h4>Are the minimum phase lengths sensible?</h4><p>{', '.join(f"Phase {i + 1}: {ph['minDays']} days" for i, ph in enumerate(phases))}. They are floors; the checks usually take longer.</p></div></div>
      <div class="q"><div><h4>Are the flexion and rotation limits right for the meniscus findings?</h4><p>Loaded bending kept to about 90° until Phase 3; no twisting under load until Phase 4.</p></div></div>
      <div class="q"><div><h4>Is "two broken mornings in a row" the right trigger to suggest dropping back a phase?</h4><p>One broken morning only advises repeating the same dose.</p></div></div>
      <div class="q"><div><h4>Are the gate tests and thresholds the right ones?</h4><p>For example: 30 s single-leg balance, step-down control from 15–20 cm, eyes-closed balance of 20 s, and a hop distance of at least 90% of the other leg. Should any objective measure be added, such as a strength test or a Y-balance reach?</p></div></div>
      <div class="q"><div><h4>Anything to remove, swap or re-dose?</h4><p>Especially the deep squat in Phase 3, the Bulgarian split squat, and the impact and pivoting work in Phase 4.</p></div></div>
      <div class="q"><div><h4>Is the weekly load appropriate?</h4><p>Daily mobility plus strength {prog['strengthDaysPerWeek']}× a week on non-consecutive days, each session about 30–35 minutes.</p></div></div>
      <div class="q"><div><h4>Is the entry check safe?</h4><p>It lets the patient start in Phase 2 if they answer yes to all the Phase 1 checks.</p></div></div>
      <div class="q"><div><h4>Is the maintenance plan enough after graduation?</h4><p>{E(prog['maintenance'])}</p></div></div>
    </div>
  </div>
</section>

<footer>
  <div class="wrap">
    <p>Generated from the Joint+ app's content files (program "{E(prog['name'])}", version {prog.get('version', 1)}). {total_items} session items across {len(phases)} phases.
    Joint+ is not medical advice and does not replace assessment or treatment by a clinician.</p>
  </div>
</footer>
"""

PAGE = PAGE.replace("<span class=chip-s>", '<span class="chip-s">')
os.makedirs(os.path.dirname(OUT) or ".", exist_ok=True)
open(OUT, "w").write(PAGE)
print(f"wrote {OUT} ({len(PAGE) // 1024} KB)")
