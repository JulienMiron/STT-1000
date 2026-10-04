#!/bin/sh
# Compile le recueil d'exercices STT-1000 en PDF.
# Usage : sh compiler.sh
set -e
cd "$(dirname "$0")"

latexmk recueil-STT-1000.tex
# Supprime les fichiers auxiliaires (garde le PDF)
latexmk -c recueil-STT-1000.tex >/dev/null 2>&1
