"""
Generate a clean dependency graph for bd issues.
"""

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

# ── Issue data ────────────────────────────────────────────────────────────────

issues = {
    "e5v": {"label": "e5v", "title": "Create branch\nsubstack-historical-analysis", "priority": 1},
    "7i5": {"label": "7i5", "title": "Adapter FA (03)\npour 191 team-seasons",         "priority": 1},
    "ynq": {"label": "ynq", "title": "Adapter clustering\n(03b + 04) sur 191 ts",       "priority": 1},
    "np9": {"label": "np9", "title": "Assigner 2025-26\naux clusters historiques",       "priority": 1},
    "93z": {"label": "93z", "title": "Figures 1–5\n(dimensions + archétypes)",           "priority": 2},
    "9yx": {"label": "9yx", "title": "Figures 6–8\n(performance + régression)",          "priority": 2},
    "yn3": {"label": "yn3", "title": "Figures 9–10\n(évolution temporelle)",             "priority": 2},
    "5s4": {"label": "5s4", "title": "Mettre à jour\n00_run_all.R",                      "priority": 2},
    "sjm": {"label": "sjm", "title": "Créer le README\n(branche historique)",            "priority": 3},
}

# Edges: (from, to) meaning "from" must complete before "to"
edges = [
    ("e5v", "7i5"),
    ("7i5", "ynq"),
    ("ynq", "np9"),
    ("ynq", "yn3"),
    ("np9", "93z"),
    ("np9", "9yx"),
    ("93z", "5s4"),
    ("9yx", "5s4"),
    ("yn3", "5s4"),
    ("5s4", "sjm"),
]

# ── Layout: manual (x, y) positions ──────────────────────────────────────────
# x = column (0..4), y = row (0 = top)

pos = {
    "e5v": (2.0, 0.0),
    "7i5": (2.0, 1.0),
    "ynq": (2.0, 2.0),
    "np9": (1.0, 3.0),
    "yn3": (3.0, 3.0),
    "93z": (0.0, 4.0),
    "9yx": (2.0, 4.0),
    "5s4": (1.5, 5.0),
    "sjm": (1.5, 6.0),
}

# ── Priority styling ──────────────────────────────────────────────────────────

priority_colors = {
    1: ("#1a1a2e", "#e8e8f0"),   # dark bg, light text
    2: ("#2d6a4f", "#e8f5ee"),
    3: ("#5c4a1e", "#fdf3dc"),
}

priority_labels = {1: "P1", 2: "P2", 3: "P3"}

# ── Figure setup ──────────────────────────────────────────────────────────────

fig, ax = plt.subplots(figsize=(9, 12))
ax.set_xlim(-0.8, 4.8)
ax.set_ylim(-0.6, 6.8)
ax.axis("off")
ax.set_aspect("equal")
ax.invert_yaxis()

fig.patch.set_facecolor("#fafafa")

BOX_W = 1.55
BOX_H = 0.62

def draw_node(ax, key, x, y, issue):
    p = issue["priority"]
    bg, fg = priority_colors[p]

    fancy = FancyBboxPatch(
        (x - BOX_W / 2, y - BOX_H / 2),
        BOX_W, BOX_H,
        boxstyle="round,pad=0.04",
        linewidth=1.2,
        edgecolor=bg,
        facecolor=bg,
        zorder=3,
    )
    ax.add_patch(fancy)

    # ID badge
    ax.text(
        x - BOX_W / 2 + 0.13, y,
        issue["label"],
        ha="left", va="center",
        fontsize=7.5, fontweight="bold",
        color=fg, zorder=4,
        fontfamily="monospace",
    )

    # Priority pill
    pill = FancyBboxPatch(
        (x + BOX_W / 2 - 0.30, y - BOX_H / 2 + 0.06),
        0.26, 0.20,
        boxstyle="round,pad=0.02",
        linewidth=0,
        facecolor="#ffffff22",
        zorder=4,
    )
    ax.add_patch(pill)
    ax.text(
        x + BOX_W / 2 - 0.17, y - BOX_H / 2 + 0.16,
        priority_labels[p],
        ha="center", va="center",
        fontsize=6, fontweight="bold",
        color=fg, zorder=5,
    )

    # Title (right side of ID)
    ax.text(
        x - BOX_W / 2 + 0.38, y,
        issue["title"],
        ha="left", va="center",
        fontsize=7, color=fg,
        zorder=4,
        linespacing=1.4,
    )


def draw_edge(ax, from_key, to_key):
    x0, y0 = pos[from_key]
    x1, y1 = pos[to_key]

    # Start at bottom of source, end at top of dest
    start = (x0, y0 + BOX_H / 2)
    end   = (x1, y1 - BOX_H / 2)

    ax.annotate(
        "",
        xy=end,
        xytext=start,
        arrowprops=dict(
            arrowstyle="-|>",
            color="#888888",
            lw=1.2,
            connectionstyle="arc3,rad=0.0",
            mutation_scale=10,
        ),
        zorder=2,
    )


# Draw edges first (behind nodes)
for src, dst in edges:
    draw_edge(ax, src, dst)

# Draw nodes
for key, issue in issues.items():
    x, y = pos[key]
    draw_node(ax, key, x, y, issue)

# ── Legend ────────────────────────────────────────────────────────────────────

legend_items = [
    mpatches.Patch(facecolor=priority_colors[1][0], label="P1 — critique (bloque tout)"),
    mpatches.Patch(facecolor=priority_colors[2][0], label="P2 — figures"),
    mpatches.Patch(facecolor=priority_colors[3][0], label="P3 — documentation"),
]
ax.legend(
    handles=legend_items,
    loc="lower center",
    bbox_to_anchor=(0.5, -0.01),
    fontsize=8,
    frameon=False,
    ncol=3,
)

# ── Title ─────────────────────────────────────────────────────────────────────

ax.set_title(
    "Dependency graph — substack-historical-analysis",
    fontsize=11, fontweight="bold", pad=10,
    color="#1a1a1a",
)

plt.tight_layout()
plt.savefig("outputs/figures/bd_issues_graph.png", dpi=180, bbox_inches="tight",
            facecolor=fig.get_facecolor())
print("Saved: outputs/figures/bd_issues_graph.png")
