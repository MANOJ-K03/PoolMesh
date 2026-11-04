"""Connection settings. Values come from environment variables or a .env file."""
import os
from pathlib import Path


def _load_env():
    for candidate in (Path.cwd() / ".env", Path(__file__).resolve().parents[1] / ".env"):
        if candidate.exists():
            for line in candidate.read_text(encoding="utf-8").splitlines():
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))
            break


_load_env()

USER = os.getenv("ORACLE_USER", "poolmesh")
PASSWORD = os.getenv("ORACLE_PASSWORD", "poolmesh")
DSN = os.getenv("ORACLE_DSN", "localhost:1521/XEPDB1")
SQL_DIR = Path(os.getenv("POOLMESH_SQL_DIR", Path(__file__).resolve().parents[2] / "database"))
