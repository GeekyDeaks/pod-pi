---
name: container-tools
description: Catalog of CLI tools installed in this pi-podman container for search, extraction, document/media inspection, OCR, web lookup, and CSV/data wrangling. Use when deciding how to inspect or transform files without writing custom scripts.
compatibility: pi-podman image with Debian-based CLI tools installed.
---

# Container Tools

Prefer these purpose-built tools before writing ad-hoc scripts. Check availability with `command -v <tool>` if unsure.

For web lookup tasks, do not start by writing Python. First try the dedicated CLI tools in the Web lookup section (`ddgr`, `w3m`, `curl | html2text`). Use Python only as a fallback when the CLI tools cannot retrieve or parse the needed information.

## Development and project tools

```bash
lightdash --help                     # Lightdash CLI for Lightdash/dbt project workflows
npm --version                        # JavaScript/TypeScript package tooling
node --version
```

## File and code search

```bash
rg "pattern"                         # fast text search
rga "pattern"                        # search PDFs, Office docs, ebooks, archives, compressed files
fd "name-or-regex"                   # find files by name; Debian symlink provided
ctags -R .                            # build symbol index for codebases
```

## Quick inspection

```bash
file path
exiftool path
mediainfo media-file
bat path                              # readable preview; Debian symlink provided
jq . data.json
xmlstarlet fo file.xml
sqlite3 database.db '.tables'
tree -a -L 3
```

## PDFs and documents

```bash
pdftotext file.pdf -                  # PDF text to stdout
pdfinfo file.pdf
qpdf --check file.pdf
docx2txt file.docx -
odt2txt file.odt
antiword file.doc
catdoc file.doc
xls2csv file.xls
unrtf --text file.rtf
pandoc input.html -t markdown
```

## Images, OCR, and media

```bash
identify image.png
magick image.png -resize 50% out.png
tesseract image.png stdout
ffprobe -hide_banner media.mp4
ffmpeg -i input.mp4 output.wav
```

## Web lookup and page extraction

Use this order for web lookup:

1. Search with `ddgr`.
2. Read pages with `w3m -dump`.
3. If needed, fetch HTML with `curl` and convert with `html2text`.
4. Only use Python for complex parsing, retries, pagination, or when the CLI tools fail.

```bash
ddgr "search query"
w3m -dump https://example.com
curl -fsSL https://example.com | html2text
```

Python fallback only:

```bash
python3 - <<'PY'
import requests
from bs4 import BeautifulSoup
html = requests.get('https://example.com', timeout=20).text
print(BeautifulSoup(html, 'lxml').get_text('\n'))
PY
```

## CSV and tabular data

```bash
mlr --csv head file.csv
mlr --csv filter '$status == "active"' file.csv
mlr --csv stats1 -a count,mean -f amount file.csv
csvlook file.csv
csvcut -n file.csv
csvcut -c col1,col2 file.csv
csvgrep -c status -m active file.csv
csvsql --query 'select * from file limit 5' file.csv
python3 - <<'PY'
import pandas as pd
print(pd.read_csv('file.csv').head())
PY
```

## Archives and compressed data

```bash
7zz l archive.7z
7zz x archive.7z
unzip -l archive.zip
tar -tf archive.tar.gz
zstd -d file.zst
xz -d file.xz
```
