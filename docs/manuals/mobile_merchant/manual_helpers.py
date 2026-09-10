# -*- coding: utf-8 -*-
"""Shared markup helpers for the Cartivo Merchant manual content modules."""
import html


def esc(s):
    return html.escape(str(s), quote=False)


def p(text):
    return f"<p>{text}</p>"


def lead(text):
    return f"<p class='lead'>{text}</p>"


def h3(text):
    return f"<h3>{esc(text)}</h3>"


def h4(text):
    return f"<h4>{esc(text)}</h4>"


def steps(items):
    return "<ol class='steps'>" + "".join(f"<li>{x}</li>" for x in items) + "</ol>"


def ol(items):
    return "<ol>" + "".join(f"<li>{x}</li>" for x in items) + "</ol>"


def ul(items):
    return "<ul>" + "".join(f"<li>{x}</li>" for x in items) + "</ul>"


def note(text, kind="note", label=None):
    label = label or {"note": "Note", "warn": "Important", "ok": "Tip"}[kind]
    return f"<div class='box {kind}'><b>{label}</b> &nbsp;{text}</div>"


def table(headers, rows):
    h = "".join(f"<th>{c}</th>" for c in headers)
    b = "".join("<tr>" + "".join(f"<td>{c}</td>" for c in r) + "</tr>" for r in rows)
    return f"<table><thead><tr>{h}</tr></thead><tbody>{b}</tbody></table>"


def pre(text):
    return "<pre>" + text.replace("&", "&amp;").replace("<", "&lt;") + "</pre>"
