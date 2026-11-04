"""Thin database layer: connection, queries, procedure calls with DBMS_OUTPUT, script runner."""
import re
import oracledb
from . import config


class Database:
    def __init__(self):
        self.conn = None
        self.echo = None  # optional callback(text) - shows the SQL/PL-SQL behind each menu option

    # ---- connection -------------------------------------------------------
    def connect(self):
        self.conn = oracledb.connect(user=config.USER, password=config.PASSWORD, dsn=config.DSN)
        return self.conn

    def close(self):
        if self.conn:
            self.conn.close()
            self.conn = None

    # ---- queries ----------------------------------------------------------
    def query(self, sql, params=None):
        """Return (column_names, rows) for a SELECT."""
        self._echo(sql, params)
        with self.conn.cursor() as cur:
            cur.execute(sql, params or {})
            cols = [d[0] for d in cur.description]
            return cols, cur.fetchall()

    def scalar(self, sql, params=None):
        _, rows = self.query(sql, params)
        return rows[0][0] if rows else None

    def execute(self, sql, params=None, commit=True):
        self._echo(sql, params)
        with self.conn.cursor() as cur:
            cur.execute(sql, params or {})
        if commit:
            self.conn.commit()

    # ---- stored procedures + DBMS_OUTPUT ----------------------------------
    def call(self, proc, *args):
        """Call a stored procedure; return the DBMS_OUTPUT lines it printed.
        Oracle errors raised with RAISE_APPLICATION_ERROR are re-raised as DBError
        with the clean message (the ORA-200xx text the report documents)."""
        self._echo("EXEC %s(%s)" % (proc, ", ".join(repr(a) for a in args)), None)
        with self.conn.cursor() as cur:
            cur.callproc("DBMS_OUTPUT.ENABLE", [None])
            try:
                cur.callproc(proc, list(args))
            except oracledb.DatabaseError as exc:
                self.conn.rollback()
                raise DBError(clean_error(exc)) from exc
            return self._drain_output(cur)

    def _echo(self, sql, params):
        if self.echo:
            self.echo(sql, params)

    @staticmethod
    def _drain_output(cur):
        lines = []
        line_var = cur.var(str)
        status_var = cur.var(int)
        while True:
            cur.callproc("DBMS_OUTPUT.GET_LINE", (line_var, status_var))
            if status_var.getvalue() != 0:
                break
            lines.append(line_var.getvalue())
        return lines

    # ---- script runner (SQL*Plus-style files) ------------------------------
    def run_script(self, path, progress=None):
        """Execute a .sql file: plain statements end with ';', PL/SQL units end with a
        line containing only '/'. SQL*Plus commands (SET, PROMPT, @, EXEC...) are skipped.
        Returns (ok_count, errors)."""
        ok, errors = 0, []
        for stmt in split_script(path):
            try:
                with self.conn.cursor() as cur:
                    cur.execute(stmt)
                ok += 1
            except oracledb.DatabaseError as exc:
                errors.append((stmt.strip().splitlines()[0][:70], clean_error(exc)))
            if progress:
                progress(ok, len(errors))
        self.conn.commit()
        return ok, errors


class DBError(Exception):
    """A business-rule or constraint error with a user-friendly message."""


def clean_error(exc):
    """Strip ORA-06512 stack lines; keep the first meaningful ORA- message."""
    msg = str(exc.args[0]) if exc.args else str(exc)
    lines = [l for l in msg.splitlines() if l.strip() and "ORA-06512" not in l]
    return "\n".join(lines[:2]) if lines else msg


_PLSQL_START = re.compile(
    r"^\s*(CREATE\s+(OR\s+REPLACE\s+)?(FUNCTION|PROCEDURE|TRIGGER|PACKAGE)|BEGIN|DECLARE)\b", re.I)
_SKIP = re.compile(r"^\s*(SET|PROMPT|SPOOL|EXEC|EXECUTE|COLUMN|COL|@|ROLLBACK;?\s*(--.*)?$|--)", re.I)


def split_script(path):
    """Yield executable statements from a SQL*Plus-style script."""
    text = open(path, encoding="utf-8").read()
    buf, in_plsql = [], False
    for raw in text.splitlines():
        line = raw.rstrip()
        if not buf:
            if not line.strip() or _SKIP.match(line):
                continue
            in_plsql = bool(_PLSQL_START.match(line))
        if in_plsql:
            if line.strip() == "/":
                yield "\n".join(buf)
                buf, in_plsql = [], False
            else:
                buf.append(line)
        else:
            buf.append(line)
            if _strip_comment(line).endswith(";"):
                stmt = "\n".join(buf).rstrip()
                yield stmt[:-1] if stmt.endswith(";") else stmt
                buf = []
    if buf and not in_plsql:
        yield "\n".join(buf).rstrip(";")


def _strip_comment(line):
    """Drop a trailing -- comment that is outside string literals."""
    out, quote = [], False
    i = 0
    while i < len(line):
        ch = line[i]
        if ch == "'":
            quote = not quote
        elif ch == "-" and line[i:i + 2] == "--" and not quote:
            break
        out.append(ch)
        i += 1
    return "".join(out).rstrip()
