"""Loads the 20 review queries straight from database/06_queries.sql so the CLI
and the report always show exactly the same SQL."""
import re
from . import config

_HEADER = re.compile(r"^--\s*Q(\d+)\.\s*(.*?)\s*(?:\[(.*)\])?\s*$")


def load():
    path = config.SQL_DIR / "06_queries.sql"
    queries, cur = [], None
    for line in path.read_text(encoding="utf-8").splitlines():
        m = _HEADER.match(line)
        if m:
            cur = {"no": int(m.group(1)), "title": m.group(2), "desc": m.group(3) or "", "sql": []}
            queries.append(cur)
        elif cur is not None and not line.startswith("-- ==="):
            cur["sql"].append(line)
    for q in queries:
        q["sql"] = "\n".join(q["sql"]).strip().rstrip(";").strip()
    return queries


# Reports menu -> query numbers (names follow the Review I report list)
REPORTS = [
    ("Driver earnings", 3),
    ("Route demand analysis", 4),
    ("Top eco-riders (Green Points leaderboard)", 5),
    ("Low-trust alert list", 6),
    ("Overall cancellation rate", 7),
    ("Vehicle occupancy per ride", 13),
    ("Payment mode & status summary", 14),
    ("Average star rating per driver", 15),
    ("Campus-hub route statistics", 16),
    ("CO2 saved by fuel type", 17),
    ("Driver revenue ranking (RANK)", 20),
]
