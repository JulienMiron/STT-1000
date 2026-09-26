#!/bin/sh
# Compile toutes les diapos STT-1000 en deux versions :
#   "Module N - Titre.pdf"             : présentation (avec dévoilements \uncover, \pause…)
#   "Module N - Titre-imprimable.pdf"  : version « handout » (une page par diapo)
# Usage : sh compiler.sh                                        (tous les modules)
#         sh compiler.sh "Module 6 - Statistiques descriptives.tex"   (un seul module)
set -e
cd "$(dirname "$0")"

if [ $# -gt 0 ]; then
  set -- "$@"
else
  set -- Module*.tex
fi

for f in "$@"; do
  echo "=== $f ==="
  latexmk "$f"
  latexmk -usepretex='\PassOptionsToClass{handout}{beamer}' -jobname=%A-imprimable "$f"
  # Supprime les fichiers auxiliaires (garde les PDF)
  latexmk -c "$f" >/dev/null 2>&1
  latexmk -c -jobname=%A-imprimable "$f" >/dev/null 2>&1
done
