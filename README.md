# STT-1000 Probabilités et statistique

Ce dépôt contient le site Quarto du cours. Pour l'instant, seules les
**diapositives** (LaTeX/Beamer, classe `BeamerTemplate.cls`) dans `diapos/`
y sont intégrées ; elles ont été reprises telles quelles depuis `Global/`.

À chaque `push` sur `main`, GitHub Actions compile les diapos, régénère le
site et le publie sur GitHub Pages. Les PDF ne sont **pas** versionnés : ils
sont produits par la compilation.

## Structure

| Chemin | Contenu |
|---|---|
| `index.qmd` | Page d'accueil du site |
| `diapos.qmd` | Page du site qui liste automatiquement les PDF des diapos |
| `diapos/Module *.tex` | Sources des diapos (un fichier par module) |
| `diapos/compiler.sh` | Compile les diapos (version présentation + version imprimable) |
| `diapos/latexmkrc` | Configuration de `latexmk` |
| `R/` | Fonctions R utilisées par la page Diapositives |
| `.github/workflows/publish.yml` | Compilation et publication automatiques |

## Mise en place (une seule fois)

1. Créer un dépôt vide sur GitHub (ex. `stt1000`).
2. Dans ce dossier :
   ```bash
   git init -b main
   git add .
   git commit -m "Diapos STT-1000"
   git remote add origin git@github.com:VOTRE-UTILISATEUR/stt1000.git
   git push -u origin main
   ```
3. Sur GitHub : *Settings → Pages → Build and deployment → Source :*
   **GitHub Actions**.
4. Remplacer `VOTRE-UTILISATEUR` dans `_quarto.yml`.

Le site sera ensuite à `https://VOTRE-UTILISATEUR.github.io/stt1000/`, avec
les diapos sous l'onglet *Diapositives*.

## Travailler au quotidien

Modifier un `.tex`, puis :

```bash
git commit -am "Module 6 : correction de l'exemple 4"
git push
```

Le suivi se fait dans l'onglet **Actions** du dépôt (environ 3 à 5 minutes).
Si la compilation LaTeX échoue, rien n'est publié et le journal de l'étape
« Compiler les diapos » indique la ligne fautive.

**Ajouter un module :** créer `diapos/Module 12 - Titre.tex`. Il est compilé
et ajouté à la page *Diapositives* automatiquement (le titre vient du nom du
fichier).

## Compiler localement

```bash
sh diapos/compiler.sh                                     # tous les modules
sh diapos/compiler.sh "Module 6 - Statistiques descriptives.tex"  # un seul module
quarto preview                                            # aperçu du site avec les PDF
```

Prérequis : une distribution TeX complète (TeX Live ou MiKTeX) avec
`latexmk`, Quarto et R (paquets `knitr`, `rmarkdown`, `png`).

## Synchronisation automatique vers Global

Ce dépôt est une copie de travail des diapos ; `Global/STT-1000/Diapos`
(archive maîtresse, aussi synchronisée avec Overleaf) reste la référence à
long terme. Un hook Git reporte automatiquement toute correction de
`diapos/*.tex` vers `Global` à chaque commit (copie + commit + push). Les
noms de fichiers diffèrent entre les deux dépôts ; la correspondance est
dans `scripts/global-mapping.tsv`.

**Après un clone frais, l'activer une seule fois** (la config des hooks
n'est pas clonée par Git) :

```bash
git config core.hooksPath .githooks
```

Détails et mode d'emploi manuel : voir l'en-tête de
`scripts/sync-to-global.sh` (`--dry-run` pour simuler, `--all` pour tout
resynchroniser).

## Logo généré automatiquement

`images/logo.png` (utilisé par `sidebar: logo:`) est régénéré à chaque rendu
à partir de `images/logo-source.png` (la silhouette) et de la couleur
`--accent` définie dans `styles.css` — voir `R/logo.R`, lancé automatiquement
par `project: pre-render:` dans `_quarto.yml`. Pour changer la couleur du
logo, il suffit donc de changer `--accent` dans `styles.css` ; ne pas modifier
`images/logo.png` directement (il sera écrasé au prochain rendu).

## À faire

- Ajouter les notes de cours (chapitres Quarto), sur le même modèle que
  [STT-1920](https://github.com/JulienMiron/STT-1920).
