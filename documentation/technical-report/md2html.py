"""Minimal Markdown -> print HTML for the one-page technical report
(headings, paragraphs, one table, ordered lists, **bold**, `code`)."""
import html, re, sys

src, dst = sys.argv[1], sys.argv[2]
text = re.sub(r"<!--.*?-->", "", open(src, encoding="utf-8").read(), flags=re.S)


def inline(s):
    s = html.escape(s, quote=False)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)
    return s


out, lines, i = [], text.strip().splitlines(), 0
while i < len(lines):
    line = lines[i].rstrip()
    if not line:
        i += 1
        continue
    if line.startswith("## "):
        out.append(f"<h2>{inline(line[3:])}</h2>")
    elif line.startswith("# "):
        out.append(f"<h1>{inline(line[2:])}</h1>")
    elif line.startswith("|"):
        rows = []
        while i < len(lines) and lines[i].startswith("|"):
            rows.append([c.strip() for c in lines[i].strip().strip("|").split("|")])
            i += 1
        head, body = rows[0], [r for r in rows[2:]]
        out.append("<table><thead><tr>" + "".join(f"<th>{inline(c)}</th>" for c in head) + "</tr></thead><tbody>" +
                   "".join("<tr>" + "".join(f"<td>{inline(c)}</td>" for c in r) + "</tr>" for r in body) + "</tbody></table>")
        continue
    elif re.match(r"^\d+\. ", line):
        items = []
        while i < len(lines) and re.match(r"^\d+\. ", lines[i]):
            items.append(inline(re.sub(r"^\d+\. ", "", lines[i].rstrip())))
            i += 1
        out.append("<ol>" + "".join(f"<li>{x}</li>" for x in items) + "</ol>")
        continue
    else:
        para = [line]
        while i + 1 < len(lines) and lines[i + 1].strip() and not re.match(r"^(#|\||\d+\. )", lines[i + 1]):
            i += 1
            para.append(lines[i].rstrip())
        out.append(f"<p>{inline(' '.join(para))}</p>")
    i += 1

css = """
@page { size: A4; margin: 14mm 15mm; }
body { font-family: Calibri, 'Segoe UI', Arial, sans-serif; font-size: 9.6pt; line-height: 1.28; color: #111; }
h1 { font-size: 13.5pt; margin: 0 0 3pt; color: #12355b; }
h2 { font-size: 11pt; margin: 7pt 0 3pt; color: #12355b; border-bottom: 1px solid #c8d3e0; padding-bottom: 1pt; }
p { margin: 3pt 0; text-align: justify; }
table { border-collapse: collapse; width: 100%; margin: 3pt 0; font-size: 8.9pt; }
th, td { border: 1px solid #c8d3e0; padding: 2pt 4pt; vertical-align: top; text-align: left; }
th { background: #eaf0f6; }
td:first-child { width: 14pt; text-align: center; }
td:last-child { width: 62pt; }
ol { margin: 2pt 0 3pt 15pt; padding: 0; }
li { margin: 1.5pt 0; }
code { font-family: Consolas, monospace; font-size: 8.6pt; background: #f2f4f7; padding: 0 1.5pt; }
"""
open(dst, "w", encoding="utf-8").write(
    f"<!doctype html><html><head><meta charset='utf-8'><title>Technical Report – ATUL0012345</title>"
    f"<style>{css}</style></head><body>{''.join(out)}</body></html>")
print("html written")
