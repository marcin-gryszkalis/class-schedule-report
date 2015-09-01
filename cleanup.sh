#!/bin/sh
find \( \
-name '*.aux' -or \
-name '*.bak' -or \
-name '*.dvi' -or \
-name '*.eps' -or \
-name '*.log' -or \
-name '*.lot' -or \
-name '*.lof' -or \
-name '*.out' -or \
-name '*.pdf' -or \
-name '*.ps' -or \
-name '*.tmp' -or \
-name '*.toc' -or \
-name '*.tex' -or \
-false \) \
-exec rm {} \; -exec echo {} \;
