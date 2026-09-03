#!/usr/bin/env python3
"""Strict 4-column formatter for GNU ARM assembly (.s) files.

Every non-blank, non-comment-only line is laid out on a fixed grid:

    column 1: label (only labels ever appear here)
    column 2: instruction mnemonic or directive keyword
    column 3: operands / values
    column 4: trailing '@' comment

Column widths are derived from the widest content each column holds in the
file, so a line with nothing for a column (e.g. a directive with no label)
still leaves that column's space blank rather than shifting left.

Usage: asmfmt.py FILE [FILE ...]   (rewrites each file in place)
       asmfmt.py - < input          (reads stdin, writes formatted text to stdout)
"""
import re
import sys

LABEL_RE = re.compile(r"^([A-Za-z_.$][\w.$]*):\s*(.*)$")
ASSIGNMENT_RE = re.compile(r"^([A-Za-z_.$][\w.$]*)\s*=\s*(.+)$")


def split_comment(line):
    """Return (code, comment) splitting on the first unquoted '@'."""
    in_string = False
    for i, ch in enumerate(line):
        if ch == '"' and (i == 0 or line[i - 1] != "\\"):
            in_string = not in_string
        elif ch == "@" and not in_string:
            code = line[:i].rstrip()
            comment = "@ " + line[i + 1:].strip()
            return code, comment
    return line.rstrip(), None


def collapse_whitespace(text):
    """Collapse runs of whitespace outside quoted strings to a single space."""
    out = []
    in_string = False
    prev_space = False
    for i, ch in enumerate(text):
        if ch == '"' and (i == 0 or text[i - 1] != "\\"):
            in_string = not in_string
            out.append(ch)
            prev_space = False
            continue
        if not in_string and ch.isspace():
            if not prev_space:
                out.append(" ")
            prev_space = True
        else:
            out.append(ch)
            prev_space = False
    return "".join(out).strip()


def split_primary_value(text):
    parts = text.split(None, 1)
    primary = parts[0]
    value = collapse_whitespace(parts[1]) if len(parts) > 1 else ""
    return primary, value


def format_text(text):
    raw_lines = text.splitlines()
    parsed = []

    for raw in raw_lines:
        if raw.strip() == "":
            parsed.append({"kind": "blank"})
            continue

        code, comment = split_comment(raw)
        code = code.strip()

        if code == "":
            parsed.append({"kind": "comment_only", "comment": comment})
            continue

        m = LABEL_RE.match(code)
        if m:
            label = m.group(1) + ":"
            remainder = m.group(2).strip()
            if remainder == "":
                primary, value = None, None
            else:
                primary, value = split_primary_value(remainder)
        else:
            m = ASSIGNMENT_RE.match(code)
            if m:
                label = m.group(1)
                primary, value = "=", collapse_whitespace(m.group(2))
            else:
                label = None
                primary, value = split_primary_value(code)

        parsed.append({"kind": "row", "label": label, "primary": primary, "value": value, "comment": comment})

    col1_width = max((len(p["label"]) for p in parsed if p["kind"] == "row" and p["label"]), default=0)
    col2_width = max((len(p["primary"]) for p in parsed if p["kind"] == "row" and p["primary"]), default=0)

    for p in parsed:
        if p["kind"] in ("blank", "comment_only"):
            p["code_part"] = "" if p["kind"] == "comment_only" else None
            continue

        segments = []
        if col1_width > 0:
            segments.append((p["label"] or "").ljust(col1_width))
        elif p["label"]:
            segments.append(p["label"])

        if col2_width > 0:
            segments.append((p["primary"] or "").ljust(col2_width))
        elif p["primary"]:
            segments.append(p["primary"])

        if p["value"]:
            segments.append(p["value"])

        p["code_part"] = " ".join(segments).rstrip()

    comment_col = 0
    for p in parsed:
        if p.get("comment") and p["code_part"] is not None:
            comment_col = max(comment_col, len(p["code_part"]) + 2)

    out_lines = []
    for p in parsed:
        if p["kind"] == "blank":
            out_lines.append("")
            continue
        line = p["code_part"]
        if p.get("comment"):
            line = line.ljust(comment_col) + p["comment"] if line else p["comment"]
        out_lines.append(line)

    result = "\n".join(out_lines)
    if not result.endswith("\n"):
        result += "\n"
    return result


def main(argv):
    if len(argv) < 2:
        sys.stderr.write(__doc__)
        return 1
    if argv[1] == "-":
        sys.stdout.write(format_text(sys.stdin.read()))
        return 0
    for path in argv[1:]:
        with open(path, "r") as f:
            text = f.read()
        formatted = format_text(text)
        if formatted != text:
            with open(path, "w") as f:
                f.write(formatted)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
