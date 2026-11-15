# Joint+

A minimal, offline physical therapy app. It guides you through a rehab
progression one session at a time. You move up a phase when you pass its
checks, not when a set amount of time has gone by.

The first program is for the knee, after inflammation and a meniscus strain:
four phases from *Calm & Activate* to *Dynamic & Return*.

> **Not medical advice.** The progression follows common evidence-informed
> patterns: criteria-based phases, the pain-monitoring model, and protecting
> the meniscus from loaded deep bending and twisting early on. Have a
> clinician look over the phases and checks before relying on them. Stop and
> contact them if the knee locks, gives way, swells suddenly, or can't take
> weight.

## Features

- **Today**: your phase, today's strength or mobility session, and one big start button
- **Guided sessions**: one exercise at a time, with hold and rest timers, set
  and side tracking, form cues, and a pain check before and after
- **Morning check-in**: pain, swelling and stiffness in three taps
- **Progression**:
  - an entry check suggests where to start
  - each phase has self-tests plus tracked "days within the pain rules"
  - flare-ups suggest repeating a dose or dropping back a phase
- **History**: a 4-week session grid, a morning pain trend, and phase milestones
- **Reminders**: check-in, mobility, and strength on chosen weekdays
- **Export**: all data as one JSON file through the share sheet
- **Private**: everything stays on the device, with no accounts and no network

Equipment used: bodyweight, resistance bands, a step or box, a chair, and a
suspension trainer (Pocket Monkii).

## Running it

Requires Flutter 3.47 or later.

```bash
flutter pub get
flutter run
```

```bash
flutter test
```

## Project layout

```
lib/
  app/        app shell, router
  content/    content models, JSON parser/validator, loader
  data/       drift (SQLite) database, export
  engine/     progression rules: pain rules, gates, flare-up advice
  reminders/  local notifications
  features/   today, player, checkin, program, exercise, history, settings, start
  widgets/    shared minimal components
  theme/      color, type and spacing tokens
assets/
  content/        exercises.json, programs/*.json, index.json
  illustrations/  one SVG per exercise
  icon/           app icon sources
tool/
  make_illustrations.py   generates the exercise drawings
  make_icon.py            generates the app icon
  make_protocol_page.py   builds the illustrated protocol page for clinical review
```

## Content

Programs are data. To add one, write `assets/content/programs/<id>.json` and
list it in `assets/content/index.json`. Exercises are shared across programs
in `assets/content/exercises.json`.

The loader checks every reference when the app starts and reports all
problems at once. It checks exercise ids, easier and harder links, that
reps or seconds match the exercise type, and gate fields.

Illustrations are found by exercise id. To change a drawing, edit its pose in
`tool/make_illustrations.py` and regenerate. Adding a second path also writes a
contact sheet of every drawing, which needs Pillow:

```bash
python3 tool/make_illustrations.py assets/illustrations [preview.png]
```

After changing the database schema in `lib/data/database.dart`, regenerate its
code:

```bash
dart run build_runner build
```

## Protocol page for clinicians

`tool/make_protocol_page.py` builds one self-contained HTML page for clinical
review. It covers every phase, session, dose, pain rule and moving-on check,
with the drawings and a list of questions for the reviewer. It reads the same
content files as the app, so after changing a program, rebuild it to keep the
page in step:

```bash
python3 tool/make_protocol_page.py [output.html]
```

The default output is `build/joint-plus-knee-protocol.html`.

See [PLAN.md](PLAN.md) for the full program design and milestones.
