# Joint+ — Plan

Personal, offline, cross-platform (Flutter) rehab app. Progressions are data, not code.
First program: **Knee — inflammation + meniscus strain**, starting at "settling down" stage.

> Not medical advice. This progression follows common evidence-informed patterns
> (criteria-based phases, the pain-monitoring model, protecting the meniscus from loaded deep
> flexion and twisting early). Have your physio look over the phases and criteria before you rely on it.

---

## 1. Decisions so far

| Area | Decision |
|---|---|
| Stack | Flutter (iOS + Android) |
| Audience | Personal use, no accounts |
| Progression | Criteria-based phase gates (plus a short minimum time) |
| Media | Generated SVG line art: white lines, green marks the working area or direction of movement |
| Schedule | Split: daily mobility (~10 min) + 3 strength sessions a week (~30 min, non-consecutive days) |
| Data | On-device SQLite, offline |
| Scope | Multi-program engine. Knee is program #1 |
| Equipment | Bodyweight, resistance bands, step/box, Pocket Monkii suspension trainer |
| Features | Guided session player, logging + pain ratings, reminders, progress history |

---

## 2. Aesthetic

- **Colors:** `#000000` background, `#FFFFFF` text/lines, one accent `#00E676` (green) used only for
  *active / done / next*. Grey `#6B6B6B` for secondary text. No gradients, no shadows, no rounded cards.
  The green should mean one thing: "this is the thing to act on."
- **Type:** one family (Inter or Space Grotesk). Tabular figures for timers. Big numbers, few words.
- **Layout:** full-bleed, 1px white dividers, generous spacing. One primary action per screen.
- **Motion:** none, except the timer ring and the illustration loop.

---

## 3. The knee progression

**Pain rules (all phases):**
- During exercise, pain up to **3/10** is acceptable.
- Pain must settle within **24 h**, and next-morning pain/stiffness must be **no worse than baseline**.
- Any rule broken → repeat the current week's dose. Broken twice in a row → the app suggests dropping one phase.

**Red flags (stop, contact your clinician):** the knee locks or catches and won't straighten, it gives way,
sudden large swelling, you can't bear weight. A red-flag button is always one tap away.

**Meniscus protection:** no loaded knee bending past ~90° and no twisting under load until Phase 3.

Dose notation: sets × reps (or × hold). Each strength exercise links to an easier and a harder version.

### Phase 1 — Calm & Activate  (min 7 days)
Goal: full straightening, quad switched on, swelling quiet.

*Daily (~10 min)*
- Heel slides — 2×15
- Quad sets (towel under knee) — 10 × 5 s hold
- Straight leg raise — 3×10
- Standing calf raise — 2×15

*Strength (3×/week)*
- Wall sit, shallow (~30–45°) isometric — 5 × 30–45 s (also helps with pain)
- Terminal knee extension, band — 3×15
- Glute bridge — 3×12
- Clamshell, band — 3×15/side
- Pocket Monkii assisted partial squat (0–60°) — 3×12
- Single-leg balance — 3 × 30 s

**Gate → Phase 2** (all checked)
- [ ] Knee straightens fully, same as the other side
- [ ] Straight leg raise 3×15 with no knee bend/lag
- [ ] Single-leg balance 30 s on the injured side
- [ ] 7 days with the pain rules met and no increase in swelling

### Phase 2 — Build Strength  (min 14 days)
Goal: bilateral strength to 90°, start single-leg work.

*Daily (~10 min):* heel slides, straight leg raise, single-leg calf raise 2×12/side,
lateral band walk 2 × 10 steps each way. Optional: brisk walk 10–20 min.

*Strength (~30 min)*
- Monkii assisted squat to 90° → bodyweight squat to 90° — 3×12–15
- Spanish squat (band behind knees) isometric — 4 × 30–45 s
- Monkii assisted split squat (short range) — 3×10/side
- Step-up, 15–20 cm box — 3×10/side
- Monkii hamstring curl (heels in straps, hips up) — 3×10
- Single-leg glute bridge — 3×10/side

**Gate → Phase 3**
- [ ] Bodyweight squat to 90°, 3×15, pain ≤2/10
- [ ] Step-down from 15–20 cm: 10 reps, knee stays over the toes (no caving in)
- [ ] Step-ups 3×10 with no next-day reaction
- [ ] 14 days with the pain rules met

### Phase 3 — Load & Control  (min 14–21 days)
Goal: single-leg strength, slow lowering control, careful deeper bending.

*Daily (~8 min):* heel slides, eyes-closed single-leg balance 3 × 20 s, side plank 2 × 30 s/side.
Optional: brisk walk 15–25 min.

*Strength (~30 min)*
- Bulgarian split squat (Monkii assist → none) — 3×8–10/side
- Forward step-down, slow 3 s lowering — 3×10/side
- Single-leg squat to box (Monkii assist → none) — 3×8/side
- Single-leg Monkii hamstring curl — 3×8/side
- Single-leg Romanian deadlift — 3×10/side
- Deep squat to a pain-free depth, deeper each week — 2×10

**Gate → Phase 4**
- [ ] Single-leg squat to box, 10 reps each side, looks the same on both sides
- [ ] Slow step-down from 20 cm, 10 reps, no pain and no knee caving
- [ ] Eyes-closed single-leg balance for 20 s
- [ ] Deep bodyweight squat pain-free

### Phase 4 — Dynamic & Return  (min 14 days)
Goal: impact, changing direction, pivoting tolerance.

*Daily (~8 min):* eyes-closed balance 3 × 30 s, side plank, single-leg calf raise 2×15/side.
Optional: brisk walk 20–30 min.

*Strength + power (~30 min)*
- Forward hop and stick (start with squat jumps until landings are soft) — 3×6/side
- Lateral hop / skater — 3×8/side
- Deceleration drill (jog → stop on one leg) — 3×6/side
- Pivot drill: slow controlled turns, progress speed — 3×8/side
- Bulgarian split squat — 3×8/side
- Forward step-down — 3×10/side

**Session design:** 6 strength exercises at most, weighted toward the quads plus the
movements each gate tests. Effort beats volume: the last 2–3 reps of each set should be hard
while pain stays ≤3/10. Walks are optional extras, not counted in session time.

**Graduation**
- [ ] Single-leg hop for distance on the injured side ≥90% of the other side
- [ ] Pivoting and cutting without pain or apprehension
- [ ] Pain rules met for 14 days → **maintenance mode** (2×/week, picked from Phase 3–4)

### Entry check
When the program starts, a short self-test runs through the Phase 1 gate questions. Your answers
suggest Phase 1 or Phase 2 (you said "settling down", which likely means late Phase 1 or early Phase 2).

---

## 4. App structure

**Screens**
1. **Today** — current phase, today's session (daily or strength), one big green START. Morning check-in prompt if it hasn't been done.
2. **Session player** — one exercise at a time, full screen: illustration, name, 2–3 form cues, big set/rep counter or hold timer, rest timer, DONE. Pain 0–10 slider before and after.
3. **Morning check-in** — 3 taps: pain 0–10, swelling (less / same / more), stiffness (less / same / more).
4. **Program** — the 4 phases as a vertical list, gate criteria with checkmarks, button to take the gate test.
5. **Exercise detail** — illustration, cues, common mistakes, easier/harder versions.
6. **History** — session streak grid, pain trend line (white line, green dots = sessions), phase milestones.
7. **Settings** — reminder times (daily + strength days), disclaimer, export data (JSON).

**Navigation:** 3 bottom tabs: Today · Program · History. Settings opens from Today.

---

## 5. Technical architecture

```
lib/
  theme/            colors, type, spacing tokens
  content/          models + JSON loader (Program, Phase, SessionTemplate, Exercise, Gate)
  data/             drift (SQLite) db: logs, check-ins, gate results, user state
  engine/           progression rules: pain rules, gate evaluation, flare-up/deload
  features/         today/, player/, checkin/, program/, exercise/, history/, settings/
  widgets/          stark primitives: StarkButton, Divider, TimerRing, PainSlider
assets/
  content/index.json                  lists the exercise library + every program file
  content/exercises.json              shared exercise library (all programs use it)
  content/programs/knee_meniscus.json phases, doses, gates, pain rules, red flags
  illustrations/<exercise_id>.svg     found by naming convention
```
To add a program, add a JSON file under `content/programs/` and list it in `index.json`.
The loader validates every reference (exercise ids, easier/harder links,
reps-vs-seconds matching the exercise type, gate fields) and reports every error at once.

**Packages:** `flutter_riverpod` (state), `go_router` (navigation), `drift` + `sqlite3_flutter_libs`
(local DB), `flutter_svg` (art), `flutter_local_notifications` + `timezone` (reminders),
`google_fonts` (or a bundled font). Charts are drawn with a `CustomPainter` to keep the look stark.

**Content model (sketch)**
```jsonc
// exercises/spanish_squat.json
{ "id": "spanish_squat", "name": "Spanish Squat",
  "equipment": ["band"], "illustration": "spanish_squat.svg",
  "cues": ["Band behind both knees, anchored", "Sit back, shins vertical", "Hold — knees push into band"],
  "mistakes": ["Knees drifting forward"], "easier": "wall_sit_shallow", "harder": null }

// program.json (excerpt)
{ "id": "knee_meniscus", "name": "Knee — Meniscus & Inflammation",
  "painRules": { "maxDuring": 3, "settleHours": 24, "morningNoWorse": true },
  "phases": [{ "id": "p1", "name": "Calm & Activate", "minDays": 7,
    "sessions": { "daily": [{ "ex": "heel_slides", "sets": 2, "reps": 15 }],
                  "strength": [{ "ex": "wall_sit_shallow", "sets": 5, "holdSec": 40, "restSec": 60 }] },
    "gate": [{ "id": "full_ext", "type": "bool", "text": "Knee straightens fully, same as other side" },
             { "id": "pain_window", "type": "auto", "rule": "painRulesMetDays>=7" }] }] }
```
Gate criteria are either **self-test** (yes/no, or a number such as seconds held) or **auto** (worked out from logs).

**Illustrations:** 1 SVG per exercise. Simple stick figure with a 2.5px white stroke. The working area
and the direction arrow are in green. Start and end poses alternate as a 2-frame loop.

---

## 6. Build milestones

1. **Scaffold** — Flutter project, theme tokens, 3-tab shell, stark widgets
2. **Content** — models, JSON loader, full knee program + exercise files
3. **Today + Program + Exercise detail** — read-only content browsing
4. **Session player** — counters, hold/rest timers, pain before/after ✓ (results not saved until 5; illustrations slot in at 9)
5. **Logging + DB** — drift schema, session logs, morning check-in ✓ (History shows the grid + session list; trend and export at 8)
6. **Engine** — pain rules, gate tests, phase advance, flare-up deload, entry check ✓
7. **Reminders** — local notifications for daily and strength days ✓ (check-in, mobility, strength on chosen weekdays)
8. **History** — streak grid, pain trend, milestones, JSON export ✓
9. **Illustrations** — SVG set for all ~35 exercises ✓ (generated by tool/make_illustrations.py)

## 7. Open questions (later)
- Exact green shade and font: pick once the scaffold can be seen on a phone
- Strength days: fixed (Mon/Wed/Fri) or any 3 non-consecutive days?
- Track sides separately (left/right) or the injured side only?
