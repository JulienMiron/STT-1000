#!/usr/bin/env bash
# Reporte les diapos de STT-1000 vers le dépôt Global (archive maîtresse,
# synchronisée avec Overleaf). Utilisé par l'action GitHub
# .github/workflows/sync-global.yml ; peut aussi se tester à la main.
#
# Usage :
#   bash scripts/sync-global-action.sh DEPOT_STT DEPOT_GLOBAL AVANT APRES [tout]
#     DEPOT_STT     clone de STT-1000 (avec l'historique du push)
#     DEPOT_GLOBAL  clone de Global (branche master)
#     AVANT, APRES  commits qui délimitent le push (github.event.before, github.sha)
#     tout          reporter tous les fichiers de diapos/, pas seulement ceux modifiés
#                   (aussi utilisé quand AVANT est vide ou introuvable)
#   DRY_RUN=1 : simulation (affiche ce qui serait reporté, sans commit ni push).
#
# Correspondance des fichiers :
#   diapos/BeamerTemplate.cls, ligne2.png, logo_ul.pdf -> racine de Global (partagés par les cours)
#   diapos/compiler.sh, diapos/latexmkrc               -> ignorés (propres au site)
#   tout autre fichier de diapos/                      -> Global/STT-1000/Diapos/
# Les suppressions ne sont pas reportées.
set -euo pipefail

STT="$1"; GLOBAL="$2"; AVANT="${3:-}"; APRES="${4:-HEAD}"; MODE="${5:-}"
DRY_RUN="${DRY_RUN:-0}"

cd "$STT"
fichiers=()
if [ "$MODE" = tout ] || [ -z "$AVANT" ] || [[ "$AVANT" =~ ^0+$ ]] \
   || ! git cat-file -e "${AVANT}^{commit}" 2>/dev/null; then
  echo "[sync-global] Tous les fichiers de diapos/ sont reportés."
  while IFS= read -r -d '' f; do fichiers+=("$f"); done \
    < <(git ls-files -z -- diapos/)
  plage=""
else
  while IFS= read -r -d '' f; do fichiers+=("$f"); done \
    < <(git diff --name-only -z --diff-filter=ACMRT "$AVANT" "$APRES" -- diapos/)
  plage="$AVANT..$APRES"
fi

if [ "${#fichiers[@]}" -eq 0 ]; then
  echo "[sync-global] Aucun fichier de diapos/ modifié : rien à faire."
  exit 0
fi

for f in "${fichiers[@]}"; do
  [ -f "$STT/$f" ] || continue                     # fichier supprimé ou renommé depuis
  base="$(basename "$f")"
  case "$base" in
    compiler.sh|latexmkrc) continue ;;
    BeamerTemplate.cls|ligne2.png|logo_ul.pdf) dest="$base" ;;
    *) dest="STT-1000/Diapos/${f#diapos/}" ;;
  esac
  mkdir -p "$GLOBAL/$(dirname "$dest")"
  cp "$STT/$f" "$GLOBAL/$dest"
  git -C "$GLOBAL" add -- "$dest"
done

cd "$GLOBAL"
if git diff --cached --quiet; then
  echo "[sync-global] Global est déjà à jour : rien à reporter."
  exit 0
fi

echo "[sync-global] Fichiers reportés vers Global :"
git -c core.quotepath=false diff --cached --stat | sed 's/^/  /'

court="$(git -C "$STT" rev-parse --short "$APRES")"
{
  echo "Reporte des diapos depuis STT-1000 ($court)"
  echo
  if [ -n "$plage" ]; then
    git -C "$STT" log --format='- %s' "$plage" -- diapos/ | head -20
  else
    echo "- synchronisation complète de diapos/"
  fi
} > /tmp/message-sync-global.txt

if [ "$DRY_RUN" = 1 ]; then
  echo "[sync-global] Simulation : aucun commit ni push. Message prévu :"
  sed 's/^/  | /' /tmp/message-sync-global.txt
  exit 0
fi

# Identité du commit (et d'un éventuel rebase), sans toucher à la config git
export GIT_AUTHOR_NAME="github-actions[bot]" GIT_COMMITTER_NAME="github-actions[bot]"
export GIT_AUTHOR_EMAIL="41898282+github-actions[bot]@users.noreply.github.com"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
git commit -q -F /tmp/message-sync-global.txt

# Si Global a bougé entre-temps (Overleaf, autre push), on se replace par-dessus.
for essai in 1 2 3; do
  if git push origin HEAD:master; then
    echo "[sync-global] Poussé sur Global (master)."
    exit 0
  fi
  echo "[sync-global] Push refusé (essai $essai) : récupération de Global et nouvel essai."
  git pull --rebase origin master
done
echo "[sync-global] ERREUR : impossible de pousser sur Global après 3 essais." >&2
exit 1
