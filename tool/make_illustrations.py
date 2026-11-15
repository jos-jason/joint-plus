"""Generates the exercise illustrations: minimal white line figures on black,
green for the working area and the direction of movement.

    python3 tool/make_illustrations.py assets/illustrations [preview.png]

Writes one <exercise_id>.svg per pose in POSES, and optionally a PNG contact
sheet of all of them (needs Pillow) to check the drawings by eye.

Figures are posed by placing the hip, feet and hands; knees and elbows are
solved with two-bone inverse kinematics so limb lengths never change. Side
view faces right. "near" limbs are bright, "far" limbs dimmer for depth.
A faint ghost figure shows the starting position where the move matters.
"""

import math
import os
import sys

W, H = 400, 300
FLOOR = 268

WHITE = "#FFFFFF"
GREEN = "#00E676"
BODY = 7  # limb stroke width
FAR = 0.45  # far-limb opacity
GHOST = 0.2  # ghost-figure opacity

LEN = dict(torso=66, thigh=60, shin=56, uarm=44, farm=40, head=12)


# ---------------------------------------------------------------- geometry

def d(a):
    """Unit vector for an angle in degrees: 0 down, 90 forward (right), 180 up."""
    r = math.radians(a)
    return (math.sin(r), math.cos(r))


def add(p, v, k=1.0):
    return (p[0] + v[0] * k, p[1] + v[1] * k)


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1])


def norm(v):
    n = math.hypot(*v) or 1.0
    return (v[0] / n, v[1] / n)


def rot(v, deg):
    r = math.radians(deg)
    c, s = math.cos(r), math.sin(r)
    return (v[0] * c - v[1] * s, v[0] * s + v[1] * c)


def ik(root, target, a, b, hint):
    """Middle joint of a two-bone chain from root toward target, bending toward hint."""
    dx, dy = sub(target, root)
    dist = min(math.hypot(dx, dy), a + b - 0.01)
    u = norm((dx, dy))
    cosang = max(-1.0, min(1.0, (a * a + dist * dist - b * b) / (2 * a * dist)))
    ang = math.degrees(math.acos(cosang))
    options = [add(root, rot(u, s * ang), a) for s in (1, -1)]
    h = norm(hint)
    return max(options, key=lambda m: (m[0] - root[0]) * h[0] + (m[1] - root[1]) * h[1])


def reach(root, target, length):
    """End point at most `length` from root, toward target."""
    v = sub(target, root)
    n = math.hypot(*v)
    return target if n <= length else add(root, norm(v), length)


# ----------------------------------------------------------------- figures

def figure(
    hip,
    torso=180,
    shoulder=None,
    legs=(),
    arms=(),
    hip_width=0,
    eyes_closed=False,
):
    """Returns (joints, strokes). Each leg/arm is a dict:
    legs: side ('near'|'far'), ankle, knee (hint vector), foot (angle) [, foot_len]
    arms: side, hand, elbow (hint vector)
    """
    j = {"hip": hip}
    if shoulder is None:
        shoulder = add(hip, d(torso), LEN["torso"])
    up = norm(sub(shoulder, hip))
    j["shoulder"] = shoulder
    j["head"] = add(shoulder, up, LEN["head"] + 9)
    strokes = [("torso", hip, shoulder, "near")]
    for leg in legs:
        side = leg.get("side", "near")
        off = (hip_width if side == "near" else -hip_width, 0)
        h = add(hip, off)
        ankle = leg["ankle"]
        # Scales < 1 foreshorten a limb pointing toward the viewer.
        thigh = LEN["thigh"] * leg.get("thigh_scale", 1.0)
        shin = LEN["shin"] * leg.get("shin_scale", 1.0)
        if "knee_at" in leg:
            # Placed directly, for foreshortened poses the solver can't express.
            knee = leg["knee_at"]
        else:
            knee = ik(h, ankle, thigh, shin, leg.get("knee", (1, 0)))
            ankle = reach(knee, ankle, shin)
        toe = add(ankle, d(leg.get("foot", 90)), leg.get("foot_len", 18))
        j[f"{side}_hip"], j[f"{side}_knee"] = h, knee
        j[f"{side}_ankle"], j[f"{side}_toe"] = ankle, toe
        strokes += [
            (f"{side}_thigh", h, knee, side),
            (f"{side}_shin", knee, ankle, side),
            (f"{side}_foot", ankle, toe, side),
        ]
    for arm in arms:
        side = arm.get("side", "near")
        hand = arm["hand"]
        elbow = ik(shoulder, hand, LEN["uarm"], LEN["farm"], arm.get("elbow", (0, 1)))
        hand = reach(elbow, hand, LEN["farm"])
        j[f"{side}_elbow"], j[f"{side}_hand"] = elbow, hand
        strokes += [
            (f"{side}_uarm", shoulder, elbow, side),
            (f"{side}_farm", elbow, hand, side),
        ]
    j["eyes_closed"] = eyes_closed
    return j, strokes


# --------------------------------------------------------------- primitives
# Every drawing is a list of primitives shared by the SVG and PNG writers:
#   ("line", p1, p2, color, width, opacity, dashed)
#   ("poly", [points], color, width, opacity)
#   ("circle", center, r, color, width, opacity, filled)


def draw_figure(fig, opacity=1.0, green=(), dots=()):
    joints, strokes = fig
    out = []
    # Far limbs first, so near limbs sit on top.
    for name, a, b, side in sorted(strokes, key=lambda s: s[3] != "far"):
        color = GREEN if name in green else WHITE
        op = opacity * (FAR if side == "far" and name not in green else 1.0)
        out.append(("line", a, b, color, BODY, op, False))
    out.append(("circle", joints["head"], LEN["head"], WHITE, BODY - 2, opacity, False))
    if joints.get("eyes_closed"):
        h = joints["head"]
        out.append(("line", add(h, (2, 1)), add(h, (10, 1)), WHITE, 3, opacity, False))
    for name in dots:
        out.append(("circle", joints[name], 6, GREEN, 0, opacity, True))
    return out


def arrow(points, color=GREEN, width=4):
    """Polyline with an arrowhead at the last point."""
    tip, prev = points[-1], points[-2]
    back = norm(sub(prev, tip))
    head = [add(tip, rot(back, 28), 13), tip, add(tip, rot(back, -28), 13)]
    return [("poly", points, color, width, 1.0), ("poly", head, color, width, 1.0)]


def straight(a, b):
    return arrow([a, b])


def arc(center, r, a0, a1, steps=24):
    """Arc in figure angles (0 down, 90 right, 180 up) from a0 to a1."""
    pts = [add(center, d(a0 + (a1 - a0) * i / steps), r) for i in range(steps + 1)]
    return arrow(pts)


def curve(a, ctrl, b, steps=24):
    """Quadratic Bézier arrow from a to b."""
    pts = []
    for i in range(steps + 1):
        t = i / steps
        x = (1 - t) ** 2 * a[0] + 2 * (1 - t) * t * ctrl[0] + t * t * b[0]
        y = (1 - t) ** 2 * a[1] + 2 * (1 - t) * t * ctrl[1] + t * t * b[1]
        pts.append((x, y))
    return arrow(pts)


def ellipse(center, rx, ry, a0, a1, steps=32):
    """Ellipse arrow, math angles in degrees (0 right, 90 down on screen)."""
    pts = []
    for i in range(steps + 1):
        t = math.radians(a0 + (a1 - a0) * i / steps)
        pts.append((center[0] + rx * math.cos(t), center[1] + ry * math.sin(t)))
    return arrow(pts)


def prop_line(a, b, opacity=0.5, dashed=False, width=3):
    return ("line", a, b, WHITE, width, opacity, dashed)


def floor(x0=40, x1=360):
    return [prop_line((x0, FLOOR + 6), (x1, FLOOR + 6), 0.3, width=2)]


def wall(x, top=70):
    return [prop_line((x, top), (x, FLOOR + 6), 0.5)]


def box(x0, x1, top):
    return [
        ("poly", [(x0, FLOOR + 6), (x0, top), (x1, top), (x1, FLOOR + 6)], WHITE, 3, 0.5),
    ]


def chair(x0, x1, seat, back=True):
    out = [prop_line((x0, seat), (x1, seat)), prop_line((x0 + 3, seat), (x0 + 3, FLOOR + 6)),
           prop_line((x1 - 3, seat), (x1 - 3, FLOOR + 6))]
    if back:
        out.append(prop_line((x0, seat), (x0, seat - 52)))
    return out


def band(a, b):
    return [("line", a, b, WHITE, 3, 0.8, True)]


def strap(hand, anchor):
    """Suspension strap from a high anchor to a hand, with a handle."""
    v = norm(sub(hand, anchor))
    perp = (-v[1], v[0])
    return [
        prop_line(anchor, hand, 0.6, width=2),
        ("line", add(hand, perp, -9), add(hand, perp, 9), WHITE, 4, 0.6, False),
    ]


def anchor_mark(p):
    return [("circle", p, 4, WHITE, 0, 0.6, True)]


# ------------------------------------------------------------------- poses
# Standing reference: hip (200, 152), ankle (200, 266), shoulder (200, 86).

STAND_ARMS = [
    dict(side="far", hand=(196, 194), elbow=(-1, 0)),
    dict(side="near", hand=(204, 194), elbow=(-1, 0)),
]


def stand(x=200, hip_y=152, torso=180, arms=None, **kw):
    legs = kw.pop("legs", None) or [
        dict(side="far", ankle=(x - 4, 266), knee=(1, 0)),
        dict(side="near", ankle=(x + 2, 266), knee=(1, 0)),
    ]
    return figure((x, hip_y), torso=torso, legs=legs, arms=arms or [
        dict(side="far", hand=(x - 4, hip_y + 42), elbow=(-1, 0)),
        dict(side="near", hand=(x + 4, hip_y + 42), elbow=(-1, 0)),
    ], **kw)


def supine(hip, near_ankle, far_ankle, near_knee=(0, -1), far_knee=(0, -1),
           shoulder=None, near_foot=180, far_foot=180, arms_to=None):
    shoulder = shoulder or (hip[0] - 66, hip[1])
    hand = arms_to or (shoulder[0] + 82, FLOOR - 2)
    return figure(
        hip,
        shoulder=shoulder,
        legs=[
            dict(side="far", ankle=far_ankle, knee=far_knee, foot=far_foot),
            dict(side="near", ankle=near_ankle, knee=near_knee, foot=near_foot),
        ],
        arms=[dict(side="near", hand=hand, elbow=(0, 1))],
    )


def poses():
    P = {}

    # Lying on the back, slide the heel in to bend the knee.
    hip = (230, FLOOR - 8)
    ghost = supine(hip, (344, FLOOR - 4), (344, FLOOR - 4))
    fig = supine(hip, (300, FLOOR - 4), (344, FLOOR - 4))
    P["heel_slide"] = (
        floor() + draw_figure(ghost, GHOST) + draw_figure(fig, dots=["near_knee"])
        + straight((338, FLOOR - 26), (304, FLOOR - 26))
    )

    # Straight legs, towel roll under the knee, press it down.
    fig = supine(hip, (344, FLOOR - 4), (342, FLOOR - 4), near_knee=(0, -1))
    k = fig[0]["near_knee"]
    P["quad_set"] = (
        floor() + [("circle", (k[0], FLOOR - 4), 8, WHITE, 3, 0.6, False)]
        + draw_figure(fig, green=["near_thigh"])
        + straight((k[0], k[1] - 40), (k[0], k[1] - 16))
    )

    # Far knee bent, near leg lifts straight.
    ghost = supine(hip, (344, FLOOR - 4), (296, FLOOR - 4))
    fig = supine(hip, add(hip, d(118), 115), (296, FLOOR - 4), near_knee=(0, -1), near_foot=208)
    P["straight_leg_raise"] = (
        floor() + draw_figure(ghost, GHOST) + draw_figure(fig, green=["near_thigh"])
        + arc(hip, 128, 98, 114)
    )

    # Facing a wall, rise onto the toes.
    def calf(hip_y, foot, single=False, ghost=False):
        ankle_y = FLOOR - 2 - (18 * math.cos(math.radians(foot)) if foot < 90 else 0)
        legs = [dict(side="near", ankle=(222, ankle_y), knee=(1, 0), foot=foot)]
        legs.insert(0, dict(side="far", ankle=(200, 222), knee=(1, 0.4), foot=60) if single
                    else dict(side="far", ankle=(218, ankle_y), knee=(1, 0), foot=foot))
        return figure(
            (222, ankle_y - 114), legs=legs,
            arms=[dict(side="far", hand=(298, ankle_y - 152), elbow=(0, 1)),
                  dict(side="near", hand=(298, ankle_y - 146), elbow=(0, 1))],
        )

    P["calf_raise"] = (
        floor() + wall(302, 60) + draw_figure(calf(0, 90), GHOST)
        + draw_figure(calf(0, 40), green=["near_shin"]) + straight((196, FLOOR - 6), (196, FLOOR - 38))
    )
    P["single_leg_calf_raise"] = (
        floor() + wall(302, 60) + draw_figure(calf(0, 90, single=True), GHOST)
        + draw_figure(calf(0, 40, single=True), green=["near_shin"])
        + straight((246, FLOOR - 6), (246, FLOOR - 38))
    )

    # Back against the wall, slight knee bend, hold.
    fig = figure(
        (152, 182), torso=180,
        legs=[dict(side="far", ankle=(208, FLOOR - 2), knee=(1, -0.3)),
              dict(side="near", ankle=(214, FLOOR - 2), knee=(1, -0.3))],
        arms=[dict(side="near", hand=(186, 184), elbow=(0, 1))],
    )
    P["wall_sit_shallow"] = floor() + wall(140, 50) + draw_figure(fig, green=["near_thigh"])

    # Band behind the knee from a post in front; straighten the knee.
    def tke(bent):
        hip = (196, 158) if bent else (200, 152)
        return figure(
            hip,
            legs=[dict(side="far", ankle=(186, FLOOR - 2), knee=(1, 0)),
                  dict(side="near", ankle=(202, FLOOR - 2), knee=(1, 0) if not bent else (1, -0.2))],
            arms=[dict(side="near", hand=(214, hip[1] - 4), elbow=(1, 0.4))],
        )

    fig = tke(False)
    k = fig[0]["near_knee"]
    P["tke_band"] = (
        floor() + [prop_line((338, 150), (338, FLOOR + 6), 0.5)] + anchor_mark((338, k[1]))
        + band(k, (338, k[1])) + draw_figure(tke(True), GHOST)
        + draw_figure(fig, green=["near_thigh"]) + straight((k[0] + 30, k[1] - 22), (k[0] + 6, k[1] - 22))
    )

    # Bridges: shoulders on the floor, push the hips up.
    def bridge(up, single=False):
        hip = (222, 206) if up else (226, FLOOR - 8)
        legs = [dict(side="near", ankle=(288, FLOOR - 4), knee=(0, -1), foot=90)]
        if single:
            legs.insert(0, dict(side="far", ankle=add(hip, d(118 if up else 100), 115),
                                knee=(0, -1), foot=200))
        else:
            legs.insert(0, dict(side="far", ankle=(282, FLOOR - 4), knee=(0, -1), foot=90))
        return figure(hip, shoulder=(158, FLOOR - 8), legs=legs,
                      arms=[dict(side="near", hand=(240, FLOOR - 2), elbow=(0, 1))])

    for name, single in (("glute_bridge", False), ("single_leg_bridge", True)):
        P[name] = (
            floor() + draw_figure(bridge(False, single), GHOST)
            + draw_figure(bridge(True, single), dots=["hip"])
            + straight((236, FLOOR - 14), (236, 222))
        )

    # Side-lying, knees bent, feet together, top knee opens against a band.
    def clam(open_):
        # Seen from the front: thighs open from the hip, feet stay together.
        hip = (232, FLOOR - 9)
        return figure(
            hip, shoulder=(168, FLOOR - 14),
            legs=[dict(side="far", knee_at=(292, FLOOR - 7), ankle=(262, FLOOR - 4),
                       foot=200, foot_len=8),
                  dict(side="near", knee_at=(284, FLOOR - 50) if open_ else (290, FLOOR - 14),
                       ankle=(262, FLOOR - 10), foot=200, foot_len=8)],
            arms=[dict(side="far", hand=(138, FLOOR - 40), elbow=(0, 1))],
        )

    fig = clam(True)
    j = fig[0]
    P["clamshell_band"] = (
        floor() + draw_figure(clam(False), GHOST)
        + band(add(j["near_hip"], sub(j["near_knee"], j["near_hip"]), 0.8),
               add(j["far_hip"], sub(j["far_knee"], j["far_hip"]), 0.8))
        + draw_figure(fig, dots=["hip"]) + arc(j["hip"], 84, 100, 140)
    )

    # Suspension-trainer squats: hands on handles, straps to a high anchor.
    ANCHOR = (330, 26)

    def monkii_squat(hip, torso, ankle=(222, FLOOR - 2), hand=(272, 150)):
        return figure(
            hip, torso=torso,
            legs=[dict(side="far", ankle=(ankle[0] - 6, ankle[1]), knee=(1, -0.2)),
                  dict(side="near", ankle=ankle, knee=(1, -0.2))],
            arms=[dict(side="near", hand=hand, elbow=(0, 1))],
        )

    for name, hip, torso, hand in (
        ("monkii_partial_squat", (196, 178), 168, (270, 146)),
        ("monkii_squat_90", (182, 208), 158, (266, 160)),
    ):
        fig = monkii_squat(hip, torso, hand=hand)
        P[name] = (
            floor() + anchor_mark(ANCHOR) + strap(fig[0]["near_hand"], ANCHOR)
            + draw_figure(monkii_squat((214, 152), 180, hand=(272, 132)), GHOST)
            + draw_figure(fig, green=["near_thigh"]) + straight((140, 150), (140, 196))
        )

    # Squat to a chair, arms forward.
    def squat(hip, torso, hands, ankle=(220, FLOOR - 2)):
        return figure(
            hip, torso=torso,
            legs=[dict(side="far", ankle=(ankle[0] - 6, ankle[1]), knee=(1, -0.2)),
                  dict(side="near", ankle=ankle, knee=(1, -0.2))],
            arms=[dict(side="far", hand=add(hands, (-4, 4)), elbow=(0, 1)),
                  dict(side="near", hand=hands, elbow=(0, 1))],
        )

    P["bodyweight_squat_90"] = (
        floor() + chair(110, 164, 206)
        + draw_figure(squat((216, 152), 180, (222, 194)), GHOST)
        + draw_figure(squat((174, 200), 150, (276, 152)), green=["near_thigh"])
        + straight((92, 150), (92, 196))
    )

    # Spanish squat: band behind the knees to a post behind, shins vertical.
    fig = squat((158, 200), 172, (246, 160), ankle=(212, FLOOR - 2))
    k = fig[0]["near_knee"]
    P["spanish_squat"] = (
        floor() + [prop_line((80, 150), (80, FLOOR + 6), 0.5)] + anchor_mark((80, k[1]))
        + band(k, (80, k[1])) + draw_figure(fig, green=["near_thigh"])
    )

    # Deep squat to a comfortable depth.
    P["deep_squat"] = (
        floor() + draw_figure(squat((216, 152), 180, (222, 194)), GHOST)
        + draw_figure(squat((188, 238), 142, (268, 182)), dots=["near_knee"])
        + straight((120, 150), (120, 220))
    )

    # Split squat with straps.
    def split(hip_y, hand, rear=(132, FLOOR - 6), rear_foot=60):
        return figure(
            (194, hip_y), torso=180,
            legs=[dict(side="far", ankle=rear, knee=(0.2, 1), foot=rear_foot),
                  dict(side="near", ankle=(252, FLOOR - 2), knee=(1, -0.2))],
            arms=[dict(side="near", hand=hand, elbow=(0, 1))],
        )

    fig = split(212, (262, 152))
    P["monkii_split_squat"] = (
        floor() + anchor_mark(ANCHOR) + strap(fig[0]["near_hand"], ANCHOR)
        + draw_figure(split(166, (262, 120)), GHOST)
        + draw_figure(fig, green=["near_thigh"]) + straight((112, 150), (112, 196))
    )

    # Bulgarian split squat: rear foot on a bench behind.
    def bulgarian(hip_y):
        return figure(
            (198, hip_y), torso=174,
            legs=[dict(side="far", ankle=(136, 214), knee=(0.1, 1), foot=-110),
                  dict(side="near", ankle=(254, FLOOR - 2), knee=(1, -0.2))],
            arms=[dict(side="near", hand=(208, hip_y + 34), elbow=(-1, 0))],
        )

    P["bulgarian_split_squat"] = (
        floor() + box(70, 150, 222) + draw_figure(bulgarian(170), GHOST)
        + draw_figure(bulgarian(212), green=["near_thigh"]) + straight((300, 150), (300, 196))
    )

    # Step-up: near foot on the step, drive up.
    def step_up(top):
        if top:
            return figure((256, 108), torso=176,
                          legs=[dict(side="far", ankle=(240, 186), knee=(1, 0), foot=70),
                                dict(side="near", ankle=(260, 220), knee=(1, 0))],
                          arms=[dict(side="far", hand=(276, 130), elbow=(0, 1)),
                                dict(side="near", hand=(236, 150), elbow=(0, 1))])
        return figure((214, 158), torso=166,
                      legs=[dict(side="far", ankle=(178, FLOOR - 2), knee=(1, 0)),
                            dict(side="near", ankle=(260, 220), knee=(1, -0.6))],
                      arms=[dict(side="near", hand=(236, 196), elbow=(-1, 0))])

    P["step_up"] = (
        floor() + box(232, 330, 222) + draw_figure(step_up(False), GHOST)
        + draw_figure(step_up(True), green=["near_thigh"]) + straight((340, 180), (340, 120))
    )

    # Forward step-down: standing on the step, lower the other heel in front.
    def step_down(low):
        hip = (176, 140) if low else (184, 106)
        return figure(
            hip, torso=172,
            legs=[dict(side="far", ankle=(258, FLOOR - 4) if low else (232, 226),
                       knee=(1, 0), foot=120 if low else 70),
                  dict(side="near", ankle=(190, 220), knee=(1, -0.1))],
            arms=[dict(side="near", hand=(244, hip[1] - 4), elbow=(0, 1))],
        )

    fig = step_down(True)
    P["forward_step_down"] = (
        floor() + box(130, 226, 222) + draw_figure(step_down(False), GHOST)
        + draw_figure(fig, green=["near_thigh"])
        + straight((290, 210), (290, FLOOR - 6))
    )

    # Single-leg squat back to a box, other leg reaching forward.
    def box_squat(low):
        hip = (174, 202) if low else (212, 152)
        return figure(
            hip, torso=150 if low else 176,
            legs=[dict(side="far", ankle=add(hip, d(78 if low else 30), 112), knee=(1, -0.3), foot=150),
                  dict(side="near", ankle=(218, FLOOR - 2), knee=(1, -0.2))],
            arms=[dict(side="near", hand=(268, 150) if low else (240, 178), elbow=(0, 1))],
        )

    P["single_leg_box_squat"] = (
        floor() + box(104, 160, 208) + draw_figure(box_squat(False), GHOST)
        + draw_figure(box_squat(True), green=["near_thigh"]) + straight((84, 140), (84, 186))
    )

    # Hamstring curls: heels in the straps, hips up, pull the heels in.
    STRAP_TOP = (372, 24)

    def curl(pulled, single=False):
        hip = (214, 222) if pulled else (218, 244)
        heel = (290, 214) if pulled else (330, 238)
        legs = [dict(side="near", ankle=heel, knee=(0, -1), foot=170)]
        legs.insert(0, dict(side="far", ankle=add(hip, d(112), 114), knee=(0, -1), foot=200)
                    if single else dict(side="far", ankle=add(heel, (-6, 2)), knee=(0, -1), foot=170))
        return figure(hip, shoulder=(150, FLOOR - 8), legs=legs,
                      arms=[dict(side="near", hand=(232, FLOOR - 2), elbow=(0, 1))])

    for name, single in (("monkii_hamstring_curl", False), ("monkii_single_leg_curl", True)):
        fig = curl(True, single)
        P[name] = (
            floor() + anchor_mark(STRAP_TOP) + strap(fig[0]["near_ankle"], STRAP_TOP)
            + draw_figure(curl(False, single), GHOST)
            + draw_figure(fig, green=["near_thigh"])
            + straight((336, 266), (298, 266))
        )

    # Balance on one leg; fingertips on the wall for the easier version.
    def balance(eyes_closed, wall_hand):
        arms = ([dict(side="far", hand=(180, 190), elbow=(-1, 0)),
                 dict(side="near", hand=(292, 136), elbow=(0, 1))] if wall_hand else
                [dict(side="far", hand=(150, 168), elbow=(0, 1)),
                 dict(side="near", hand=(252, 168), elbow=(0, 1))])
        return figure(
            (200, 152), torso=180, eyes_closed=eyes_closed,
            legs=[dict(side="far", ankle=(174, 214), knee=(1, 0.2), foot=40),
                  dict(side="near", ankle=(202, FLOOR - 2), knee=(1, 0))],
            arms=arms,
        )

    P["single_leg_balance"] = (
        floor() + wall(296, 60) + draw_figure(balance(False, True), dots=["near_ankle"])
    )
    P["single_leg_balance_eyes_closed"] = (
        floor() + draw_figure(balance(True, False), dots=["near_ankle"])
    )

    # Single-leg Romanian deadlift: hinge at the hip, back leg rises.
    def rdl(hinged):
        hip = (196, 154)
        torso = 98 if hinged else 180
        sh = add(hip, d(torso), 66)
        return figure(
            hip, torso=torso,
            legs=[dict(side="far", ankle=add(hip, d(-84 if hinged else -6), 114), knee=(0, 1), foot=0),
                  dict(side="near", ankle=(204, FLOOR - 2), knee=(1, 0))],
            arms=[dict(side="near", hand=add(sh, (2, 74)), elbow=(1, 0))],
        )

    P["single_leg_rdl"] = (
        floor() + draw_figure(rdl(False), GHOST) + draw_figure(rdl(True), green=["near_thigh"])
        + arc((196, 154), 100, 166, 112)
    )

    # Side plank on the forearm, body in a straight line.
    fig = figure(
        (244, 232), shoulder=(156, 206),
        legs=[dict(side="far", ankle=(332, FLOOR - 4), knee=(0, -1), foot=100, foot_len=12),
              dict(side="near", ankle=(326, FLOOR - 12), knee=(0, -1), foot=100, foot_len=12)],
        arms=[dict(side="far", hand=(186, FLOOR - 2), elbow=(-0.3, 1)),
              dict(side="near", hand=(250, 214), elbow=(0, -1))],
    )
    P["side_plank"] = floor() + draw_figure(fig, green=["torso"])

    # Brisk walk: one stride.
    fig = figure(
        (200, 152), torso=176,
        legs=[dict(side="far", ankle=(156, FLOOR - 8), knee=(1, 0), foot=50),
              dict(side="near", ankle=(240, FLOOR - 6), knee=(1, -0.2), foot=124)],
        arms=[dict(side="far", hand=(226, 182), elbow=(0, 1)),
              dict(side="near", hand=(170, 186), elbow=(0, 1))],
    )
    P["brisk_walk"] = floor() + draw_figure(fig) + straight((262, 70), (330, 70))

    # Squat jump: from the squat, jump, land softly.
    jump = figure(
        (210, 110), torso=178,
        legs=[dict(side="far", ankle=(206, 222), knee=(1, 0), foot=30),
              dict(side="near", ankle=(214, 222), knee=(1, 0), foot=30)],
        arms=[dict(side="far", hand=(258, 24), elbow=(1, 0)),
              dict(side="near", hand=(266, 30), elbow=(1, 0))],
    )
    P["squat_jump"] = (
        floor() + draw_figure(squat((190, 206), 154, (268, 160)), GHOST)
        + draw_figure(jump) + straight((290, 200), (290, 130))
    )

    # Hop forward, land on one leg and hold.
    def land(x):
        return figure(
            (x, 178), torso=160,
            legs=[dict(side="far", ankle=(x - 34, 220), knee=(1, 0.5), foot=40),
                  dict(side="near", ankle=(x + 22, FLOOR - 2), knee=(1, -0.2))],
            arms=[dict(side="far", hand=(x + 20, 170), elbow=(0, 1)),
                  dict(side="near", hand=(x + 60, 160), elbow=(0, 1))],
        )

    P["forward_hop_stick"] = (
        floor() + draw_figure(land(120), GHOST) + draw_figure(land(250), dots=["near_knee"])
        + curve((150, 100), (200, 30), (250, 90))
    )

    # Skater hop sideways (front view), land on the outside leg.
    def skater(x, lean):
        return figure(
            (x, 176), torso=180 + lean, hip_width=11,
            legs=[dict(side="far", ankle=(x - 36, 226), knee=(-1, 0.3), foot=-90, foot_len=8),
                  dict(side="near", ankle=(x + 14, FLOOR - 2), knee=(1, -0.1), foot=90, foot_len=8)],
            arms=[dict(side="far", hand=(x - 44, 166), elbow=(-1, 1)),
                  dict(side="near", hand=(x + 40, 180), elbow=(1, 1))],
        )

    P["lateral_hop"] = (
        floor() + draw_figure(skater(118, 0), GHOST)
        + draw_figure(skater(264, -8), dots=["near_knee"])
        + curve((150, 110), (200, 40), (252, 104))
    )

    # Lateral band walk (front view): small steps sideways, band at the ankles.
    def band_walk(spread):
        return figure(
            (200, 166), torso=180, hip_width=11,
            legs=[dict(side="far", ankle=(200 - spread, FLOOR - 2), knee=(-1, -0.2), foot=-90, foot_len=8),
                  dict(side="near", ankle=(200 + spread, FLOOR - 2), knee=(1, -0.2), foot=90, foot_len=8)],
            arms=[dict(side="far", hand=(178, 202), elbow=(-1, 0)),
                  dict(side="near", hand=(222, 202), elbow=(1, 0))],
        )

    fig = band_walk(38)
    j = fig[0]
    P["lateral_band_walk"] = (
        floor() + draw_figure(band_walk(22), GHOST)
        + band(add(j["far_ankle"], (0, -10)), add(j["near_ankle"], (0, -10)))
        + draw_figure(fig, dots=["near_hip", "far_hip"])
        + straight((262, 120), (322, 120))
    )

    # Deceleration: jog in, brake into a low stance.
    fig = figure(
        (204, 184), torso=184,
        legs=[dict(side="far", ankle=(150, FLOOR - 6), knee=(1, -0.2), foot=60),
              dict(side="near", ankle=(268, FLOOR - 4), knee=(1, -0.4), foot=118)],
        arms=[dict(side="far", hand=(244, 166), elbow=(0, 1)),
              dict(side="near", hand=(166, 172), elbow=(0, 1))],
    )
    P["deceleration_drill"] = (
        floor() + draw_figure(fig, green=["near_thigh"])
        + straight((60, 96), (150, 96)) + [("line", (166, 78), (166, 114), GREEN, 4, 1.0, False)]
    )

    # Pivot on the ball of the foot.
    fig = figure(
        (200, 160), torso=176,
        legs=[dict(side="far", ankle=(176, FLOOR - 2), knee=(1, -0.2)),
              dict(side="near", ankle=(214, FLOOR - 4), knee=(1, -0.2), foot=70)],
        arms=[dict(side="far", hand=(176, 196), elbow=(-1, 0)),
              dict(side="near", hand=(236, 192), elbow=(1, 0.5))],
    )
    P["pivot_drill"] = (
        floor() + draw_figure(fig, dots=["near_knee"]) + ellipse((214, FLOOR + 2), 56, 14, 200, 500)
    )

    return P


# ------------------------------------------------------------------ output

def f(v):
    return f"{v:.1f}".rstrip("0").rstrip(".")


def svg(prims):
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" '
           f'fill="none" stroke-linecap="round" stroke-linejoin="round">']
    for p in prims:
        kind = p[0]
        if kind == "line":
            _, a, b, color, w, op, dashed = p
            dash = ' stroke-dasharray="6 8"' if dashed else ""
            out.append(f'<line x1="{f(a[0])}" y1="{f(a[1])}" x2="{f(b[0])}" y2="{f(b[1])}" '
                       f'stroke="{color}" stroke-width="{w}" stroke-opacity="{f(op)}"{dash}/>')
        elif kind == "poly":
            _, pts, color, w, op = p
            pts_s = " ".join(f"{f(x)},{f(y)}" for x, y in pts)
            out.append(f'<polyline points="{pts_s}" stroke="{color}" stroke-width="{w}" '
                       f'stroke-opacity="{f(op)}"/>')
        elif kind == "circle":
            _, c, r, color, w, op, filled = p
            style = (f'fill="{color}" fill-opacity="{f(op)}" stroke="none"' if filled else
                     f'stroke="{color}" stroke-width="{w}" stroke-opacity="{f(op)}"')
            out.append(f'<circle cx="{f(c[0])}" cy="{f(c[1])}" r="{f(r)}" {style}/>')
    out.append("</svg>")
    return "\n".join(out) + "\n"


def png(prims, scale=2):
    from PIL import Image, ImageDraw

    img = Image.new("RGB", (W * scale, H * scale), (0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")

    def rgba(color, op):
        h = color.lstrip("#")
        return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (int(255 * op),)

    def seg(a, b, col, w, dashed=False):
        a = (a[0] * scale, a[1] * scale)
        b = (b[0] * scale, b[1] * scale)
        if dashed:
            n = max(1, int(math.dist(a, b) / (14 * scale)))
            for i in range(n):
                t0, t1 = i / n, (i + 0.43) / n
                seg2((a[0] + (b[0] - a[0]) * t0, a[1] + (b[1] - a[1]) * t0),
                     (a[0] + (b[0] - a[0]) * t1, a[1] + (b[1] - a[1]) * t1), col, w)
        else:
            seg2(a, b, col, w)

    def seg2(a, b, col, w):
        draw.line([a, b], fill=col, width=int(w * scale))
        r = w * scale / 2
        for p in (a, b):
            draw.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=col)

    for p in prims:
        if p[0] == "line":
            _, a, b, color, w, op, dashed = p
            seg(a, b, rgba(color, op), w, dashed)
        elif p[0] == "poly":
            _, pts, color, w, op = p
            for a, b in zip(pts, pts[1:]):
                seg(a, b, rgba(color, op), w)
        elif p[0] == "circle":
            _, c, r, color, w, op, filled = p
            box_ = [(c[0] - r) * scale, (c[1] - r) * scale, (c[0] + r) * scale, (c[1] + r) * scale]
            if filled:
                draw.ellipse(box_, fill=rgba(color, op))
            else:
                draw.ellipse(box_, outline=rgba(color, op), width=int(w * scale))
    return img


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "assets/illustrations"
    preview = sys.argv[2] if len(sys.argv) > 2 else None
    os.makedirs(out_dir, exist_ok=True)
    all_poses = poses()
    for name, prims in all_poses.items():
        with open(os.path.join(out_dir, f"{name}.svg"), "w") as fh:
            fh.write(svg(prims))
    print(f"wrote {len(all_poses)} illustrations to {out_dir}")

    if preview:
        from PIL import Image, ImageDraw

        names = sorted(all_poses)
        cols, cw, ch = 6, W, H + 24
        rows = math.ceil(len(names) / cols)
        sheet = Image.new("RGB", (cols * cw, rows * ch), (24, 24, 24))
        label = ImageDraw.Draw(sheet)
        for i, name in enumerate(names):
            x, y = (i % cols) * cw, (i // cols) * ch
            sheet.paste(png(all_poses[name], 1), (x, y + 24))
            label.text((x + 6, y + 6), name, fill=(200, 200, 200))
        sheet.save(preview)
        print(f"preview: {preview}")


if __name__ == "__main__":
    main()
