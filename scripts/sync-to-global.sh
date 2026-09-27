#!/usr/bin/env bash
# Reporte les corrections des diapos (diapos/*.tex) vers le dépôt Global,
# qui sert d'archive maîtresse et est aussi synchronisé avec Overleaf.
#
# Les noms de fichiers diffèrent entre ce dépôt et Global (voir
# scripts/global-mapping.tsv : "Module N - Titre.tex" -> "STT-1000-Module N.tex").
#
# Appelé automatiquement par le hook .githooks/post-commit à chaque commit
# touchant diapos/*.tex. Peut aussi être lancé à la main :
#   bash scripts/sync-to-global.sh            (fichiers changés au dernier commit)
#   bash scripts/sync-to-global.sh --dry-run  (simulation, aucune écriture/commit/push)
#   bash scripts/sync-to-global.sh --all      (tous les diapos/*.tex, pas seulement HEAD)
set -euo pipefail

COURSE="STT-1000"
REPO_DIR="$(git rev-parse --show-toplevel)"
GLOBAL_REPO="/Users/jmiron/Documents/GitHub/Global"
GLOBAL_DIAPOS="$GLOBAL_REPO/$COURSE/Diapos"
MAPPING_FILE="$REPO_DIR/scripts/global-mapping.tsv"

DRY_RUN=0
ALL=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --all) ALL=1 ;;
    *) echo "Argument inconnu : $arg" >&2; exit 2 ;;
  esac
done

cd "$REPO_DIR"

if [ "$ALL" -eq 1 ]; then
  changed="$(ls diapos/Module*.tex 2>/dev/null || true)"
else
  changed="$(git -c core.quotepath=false diff-tree --no-commit-id --name-only -r HEAD -- diapos | grep '\.tex$' || true)"
fi

if [ -z "$changed" ]; then
  exit 0
fi

echo "[sync-to-global] Fichier(s) diapos concerné(s) :"
echo "$changed" | sed 's/^/  - /'

if [ ! -d "$GLOBAL_DIAPOS" ]; then
  echo "[sync-to-global] ERREUR : dossier Global introuvable : $GLOBAL_DIAPOS" >&2
  exit 1
fi

cd "$GLOBAL_REPO"

if [ "$DRY_RUN" -eq 0 ]; then
  if ! git pull --ff-only origin master; then
    echo "[sync-to-global] ERREUR : impossible de faire un fast-forward pull de Global" >&2
    echo "  (des changements distants existent, p. ex. depuis Overleaf)." >&2
    echo "  Synchronisation ANNULÉE. Résous manuellement :" >&2
    echo "    cd '$GLOBAL_REPO' && git pull" >&2
    echo "  puis relance : bash '$REPO_DIR/scripts/sync-to-global.sh' --all" >&2
    exit 1
  fi
fi

staged=()
while IFS= read -r f; do
  [ -z "$f" ] && continue
  base="$(basename "$f")"

  target_name="$base"
  if [ -f "$MAPPING_FILE" ]; then
    mapped="$(awk -F'\t' -v b="$base" '$1==b{print $2}' "$MAPPING_FILE")"
    if [ -n "$mapped" ]; then
      target_name="$mapped"
    fi
  fi

  target="$GLOBAL_DIAPOS/$target_name"
  if [ ! -f "$target" ]; then
    echo "[sync-to-global] ATTENTION : aucun fichier correspondant dans Global pour '$base' (cherché '$target_name') — ignoré." >&2
    echo "[sync-to-global]   Ajoute une ligne à $MAPPING_FILE si ce fichier a un nom différent dans Global." >&2
    continue
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    if diff -q "$REPO_DIR/$f" "$target" >/dev/null 2>&1; then
      echo "[sync-to-global] (dry-run) identique, rien à faire : $base -> $target_name"
    else
      echo "[sync-to-global] (dry-run) serait copié : $base -> $target"
    fi
    continue
  fi

  cp "$REPO_DIR/$f" "$target"
  staged+=("$COURSE/Diapos/$target_name")
done <<< "$changed"

if [ "$DRY_RUN" -eq 1 ] || [ "${#staged[@]}" -eq 0 ]; then
  exit 0
fi

git add "${staged[@]}"

if git diff --cached --quiet; then
  echo "[sync-to-global] Rien à committer (fichiers déjà identiques dans Global)."
  exit 0
fi

SHORT_SHA="$(git -C "$REPO_DIR" rev-parse --short HEAD)"
LAST_MSG="$(git -C "$REPO_DIR" log -1 --pretty=%s)"

git commit -m "Reporte des corrections de diapos depuis $COURSE ($SHORT_SHA)

$LAST_MSG"
git push origin master
echo "[sync-to-global] Synchronisation terminée et poussée sur Global."
