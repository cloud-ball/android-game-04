#!/usr/bin/env python3
"""Cup Dash Rush tuning report from tools/golf_selfplay.gd CSVs (one per golfer type).

Head-to-head: every pairing of a CPU tier's plays with the baseline's plays on the same hole; the
first ball in wins (then fewer strokes), neither in = no winner. Rush: bootstrapped 3-hole matches,
the baseline ("you") against three CPU golfers of one tier, with RushMatch's rules (hole: first in,
then fewer strokes, then player order; match: most holes, then fewest total strokes, else draw).
Targets: CPU vs baseline Easy ~25 %, Medium ~50 %, Hard ~70 %.

Usage: python3 tools/golf_selfplay_report.py <dir with sp_<who>.csv> [matches]
"""
import csv
import random
import statistics
import sys
from collections import defaultdict


def load(path):
    plays = defaultdict(list)
    with open(path) as f:
        for row in csv.DictReader(f):
            plays[int(row["hole"])].append(
                (int(row["holed"]), float(row["time"]), int(row["strokes"]))
            )
    return plays


def hole_winner(outcomes):
    """outcomes: list of (holed, time, strokes) in player order -> winner index or -1."""
    best = -1
    for i, (holed, t, s) in enumerate(outcomes):
        if not holed:
            continue
        if best < 0:
            best = i
            continue
        _, bt, bs = outcomes[best]
        if t < bt or (t == bt and s < bs):
            best = i
    return best


def head_to_head(cpu, base):
    win = lose = none = 0
    for h in cpu:
        for c in cpu[h]:
            for b in base[h]:
                w = hole_winner([b, c])
                if w == 1:
                    win += 1
                elif w == 0:
                    lose += 1
                else:
                    none += 1
    n = win + lose + none
    return 100.0 * win / n, 100.0 * lose / n, 100.0 * none / n


def rush(cpu, base, matches, rng):
    holes = sorted(base)
    you_win = draws = 0
    for _ in range(matches):
        order = rng.sample(holes, min(3, len(holes)))
        wins = [0, 0, 0, 0]
        total = [0, 0, 0, 0]
        for h in order:
            outs = [rng.choice(base[h])] + [rng.choice(cpu[h]) for _ in range(3)]
            for i, o in enumerate(outs):
                total[i] += o[2]
            w = hole_winner(outs)
            if w >= 0:
                wins[w] += 1
        rank = sorted(range(4), key=lambda i: (-wins[i], total[i], i))
        a, b = rank[0], rank[1]
        if wins[a] == wins[b] and total[a] == total[b]:
            draws += 1
        elif a == 0:
            you_win += 1
    return 100.0 * you_win / matches, 100.0 * draws / matches


def summary(plays):
    all_plays = [p for h in plays for p in plays[h]]
    holed = [p for p in all_plays if p[0]]
    aces = sum(1 for p in holed if p[2] == 1)
    return (
        100.0 * len(holed) / len(all_plays),
        statistics.mean(p[2] for p in all_plays),
        statistics.mean(p[1] for p in holed) if holed else float("nan"),
        100.0 * aces / len(all_plays),
    )


def main():
    folder = sys.argv[1]
    matches = int(sys.argv[2]) if len(sys.argv) > 2 else 20000
    rng = random.Random(1)
    data = {w: load(f"{folder}/sp_{w}.csv") for w in ("baseline", "easy", "medium", "hard")}
    print("golfer    holed%  strokes  drop_s  ace%")
    for w, plays in data.items():
        h, s, t, a = summary(plays)
        print(f"{w:9s} {h:6.1f}  {s:7.2f}  {t:6.1f}  {a:4.1f}")
    print()
    print("tier     cpu_wins_vs_you%  you_win%  neither%   rush_you_win%  rush_draw%   target_cpu%")
    targets = {"easy": 25, "medium": 50, "hard": 70}
    for w in ("easy", "medium", "hard"):
        cw, yw, nw = head_to_head(data[w], data["baseline"])
        rw, rd = rush(data[w], data["baseline"], matches, rng)
        print(f"{w:8s} {cw:16.1f}  {yw:8.1f}  {nw:8.1f}   {rw:13.1f}  {rd:10.1f}   {targets[w]:>10d}")


if __name__ == "__main__":
    main()
