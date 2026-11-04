"""Console helpers: colours, tables, prompts."""
import os
import sys
from datetime import datetime
from decimal import Decimal

os.system("")  # enables ANSI escape codes on Windows 10+ terminals

USE_COLOUR = sys.stdout.isatty() and os.getenv("NO_COLOR") is None


def _c(code, text):
    return f"\033[{code}m{text}\033[0m" if USE_COLOUR else text


def teal(t): return _c("36;1", t)
def green(t): return _c("32;1", t)
def red(t): return _c("31;1", t)
def yellow(t): return _c("33", t)
def dim(t): return _c("2", t)
def bold(t): return _c("1", t)


SHOW_SQL = False


def sql_echo(sql, params):
    if SHOW_SQL:
        body = "\n".join("    " + l for l in sql.strip().splitlines())
        print(dim("  +-- SQL / PL-SQL sent to Oracle " + "-" * 30))
        print(dim(body))
        if params:
            print(dim(f"    binds: {params}"))
        print(dim("  +" + "-" * 56))


def banner(text):
    line = "=" * 64
    print("\n" + teal(line))
    print(teal("  " + text))
    print(teal(line))


def section(text):
    print("\n" + bold(text))
    print(dim("-" * len(text)))


def fmt(v):
    if v is None:
        return "-"
    if isinstance(v, Decimal):
        return str(int(v)) if v == v.to_integral() else f"{v:.2f}"
    if isinstance(v, float):
        return f"{v:.2f}"
    if isinstance(v, datetime):
        return v.strftime("%Y-%m-%d %H:%M")
    return str(v)


def table(cols, rows, max_width=38):
    if not rows:
        print(yellow("  (no rows)"))
        return
    data = [[fmt(v) for v in r] for r in rows]
    widths = [min(max_width, max(len(str(c)), *(len(r[i]) for r in data))) for i, c in enumerate(cols)]
    trunc = lambda s, w: s if len(s) <= w else s[: w - 1] + "…"
    head = " | ".join(str(c).ljust(w) for c, w in zip(cols, widths))
    print("  " + bold(head))
    print("  " + "-+-".join("-" * w for w in widths))
    for r in data:
        print("  " + " | ".join(trunc(v, w).ljust(w) for v, w in zip(r, widths)))
    print(dim(f"  {len(rows)} row{'s' if len(rows) != 1 else ''} returned."))


def ok(msg): print(green("  ✔ ") + msg)
def fail(msg): print(red("  ✘ ") + msg)
def info(msg): print(yellow("  • ") + msg)


def ask(prompt, default=None):
    suffix = f" [{default}]" if default is not None else ""
    val = input(f"  {prompt}{suffix}: ").strip()
    return val if val else (str(default) if default is not None else "")


def ask_int(prompt, lo=None, hi=None, default=None):
    while True:
        raw = ask(prompt, default)
        try:
            n = int(raw)
            if (lo is not None and n < lo) or (hi is not None and n > hi):
                raise ValueError
            return n
        except ValueError:
            rng = f" between {lo} and {hi}" if lo is not None and hi is not None else ""
            fail(f"Please enter a whole number{rng}.")


def ask_float(prompt, lo=None, default=None):
    while True:
        raw = ask(prompt, default)
        try:
            n = float(raw)
            if lo is not None and n <= lo:
                raise ValueError
            return n
        except ValueError:
            fail("Please enter a positive number.")


def confirm(prompt):
    return ask(prompt + " (y/n)", "y").lower().startswith("y")


def pause():
    input(dim("\n  Press Enter to continue..."))
