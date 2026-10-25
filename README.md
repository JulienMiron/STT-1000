# STT-1000 Probabilités et statistique

Ce dépôt contient le site Quarto du cours : les **diapositives**
(LaTeX/Beamer, classe `BeamerTemplate.cls`) dans `diapos/` et le **recueil
d'exercices** (LaTeX, classe `Evaluation.cls`) dans `recueil/`. Les deux ont
été repris tels quels depuis `Global/`.

À chaque `push` sur `main`, GitHub Actions compile les diapos et le recueil,
régénère le site et le publie sur GitHub Pages. Les PDF ne sont **pas**
versionnés : ils sont produits par la compilation.

## Structure

| Chemin | Contenu |
|---|---|
| `index.qmd` | Page d'accueil du site (bandeau + liens vers les autres pages) |
| `diapos.qmd` | Page *Diapositives* : lien vers le recueil d'exercices, boutons « Tout télécharger » (ZIP), liste automatique des PDF des diapos et sections du manuel à lire |
| `diapos/Module *.tex` | Sources des diapos (un fichier par module) |
| `diapos/compiler.sh` | Compile les diapos (version présentation + version imprimable) |
| `diapos/latexmkrc` | Configuration de `latexmk` pour les diapos |
| `recueil/recueil-STT-1000.tex` | Source du recueil d'exercices |
| `recueil/Evaluation.cls`, `recueil/logo_ul.pdf` | Dépendances de compilation du recueil (classe d'examen, logo) |
| `recueil/compiler.sh` | Compile le recueil d'exercices |
| `recueil/latexmkrc` | Configuration de `latexmk` pour le recueil |
| `exercices.qmd` | Page *Exercices* : exercices du manuel selon l'avancement du cours (voir plus bas) |
| `exercices/correspondance.tsv` | Diapo à partir de laquelle chaque exercice du manuel est faisable |
| `exercices/avancement.tsv` | Avancement du cours en classe (à mettre à jour chaque semaine) |
| `manuel/lectures.tsv`, `manuel/sections.tsv` | Sections du manuel à lire pour chaque module (colonne *Manuel* de la page Diapositives) |
| `R/` | Fonctions R utilisées par les pages Diapositives (`diapos.R`) et Exercices (`exercices.R`), et scripts lancés avant chaque rendu (`logo.R`, `archives.R`) |
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
sh recueil/compiler.sh                                     # recueil d'exercices
quarto preview                                            # aperçu du site avec les PDF
```

Prérequis : une distribution TeX complète (TeX Live ou MiKTeX) avec
`latexmk`, Quarto et R (paquets `knitr`, `rmarkdown`, `png`).

## Synchronisation automatique vers Global (diapos)

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

## Synchronisation automatique depuis Global (recueil)

Pour le recueil, la direction est inversée : `Global/STT-1000/Examens/recueil-STT-1000.tex`
est la référence (modifiée directement ou via `maj_recueil.py`), et
`recueil/recueil-STT-1000.tex` dans ce dépôt n'en est qu'une copie publiée.
Un hook Git **dans le dépôt Global** reporte automatiquement toute
modification du recueil vers ce dépôt (copie + commit + push), ce qui
déclenche la recompilation et la republication du site. Voir
`Global/scripts/sync-recueil-to-sites.sh`.

Ne pas modifier `recueil/recueil-STT-1000.tex` directement dans ce dépôt :
les changements seraient écrasés par la prochaine synchronisation depuis
Global.

## Page *Exercices* : exercices du manuel selon l'avancement

La page *Exercices* (`exercices.qmd`, code dans `R/exercices.R`) indique, pour
chaque exercice de fin de chapitre du manuel (ou chaque sous-question), la diapo
à partir de laquelle toute la matière nécessaire a été vue en classe. On y trouve :

- **Où en est le cours ?** — la dernière ligne de `exercices/avancement.tsv` et
  la liste des exercices faisables à ce jour (ceux qui se sont ajoutés depuis la
  mise à jour précédente sont en gras) ; n'apparaît que si le fichier contient au
  moins une ligne ;
- **Quels exercices puis-je faire ?** — un sélecteur *module + diapo*. Par
  défaut, le choix « Tout » affiche tous les exercices au programme ; en
  choisissant un module et une diapo, on ne voit que les exercices faisables
  jusqu'à ce point. L'adresse se met à jour et peut être partagée :
  `exercices.html#module=3&d=24` ;
- **Exercices par module** — pour chaque module, les exercices qui deviennent
  faisables à chaque diapo ;
- les exercices du manuel **hors programme** (notions non vues dans le cours).

### Mettre à jour l'avancement (chaque semaine)

Ajouter une ligne à `exercices/avancement.tsv` (colonnes séparées par des
**tabulations**) : la date, le code du module, le numéro affiché au bas de la
dernière diapo vue (ou `fin`) et une remarque facultative, par exemple

```
2026-10-20	3	24	
```

puis `git commit` et `git push`. Le code du module est le numéro qui figure dans
le nom du fichier de diapos (`1`, `2`, …, `10`) ; si deux fichiers portent le même
numéro, ils deviennent `N.1`, `N.2` dans l'ordre alphabétique (ici `9.1` et `9.2`
pour les deux parties du module 9).

### Les données : `exercices/correspondance.tsv`

Une ligne par exercice, ou par groupe de sous-questions quand elles deviennent
faisables à des moments différents. Colonnes : `exercice`, `parties` (vide = tout
l'exercice), `sujet` (notion travaillée, affichée au survol), `module` (code, ou
`hors` si la matière n'est pas vue dans le cours), `diapo`, `titre` et `note`
(justification du classement). Règle suivie : la diapo retenue est celle où la
**dernière** notion nécessaire est présentée (définition, formule ou méthode),
dans le module le plus avancé dont l'exercice a besoin.

Le classement initial couvre les exercices des chapitres 1, 2, 4 à 10 et 12 du
manuel. Pour ajouter un chapitre, ajouter des lignes au fichier.

**Numéros de diapos.** Ce sont ceux de la version présentation (le numéro affiché
au bas de la diapo). Ils sont recalculés à chaque rendu à partir des sources
`diapos/Module *.tex`, avec la même règle que Beamer (chaque `\section` produit
une diapo de titre ; les diapos commentées ou dans un environnement `comment` ne
comptent pas ; une diapo dans `\only<beamer>{...}` n'existe que dans la version
présentation, et la page le signale). Si on ajoute ou retire une diapo, la
colonne `titre` sert d'ancrage : l'exercice suit la diapo qui porte ce titre, et
le journal du rendu (onglet *Actions*) l'indique par une ligne `[exercices]`.
**Pour corriger une ligne à la main**, changer `diapo` et `titre` ensemble (ou
vider `titre` : le numéro est alors pris tel quel).

## Colonne *Manuel* de la page Diapositives

La page *Diapositives* indique, pour chaque module, les sections du manuel à lire
(colonne *Manuel* ; les titres apparaissent au survol et dans la liste dépliable
sous le tableau). Deux fichiers, colonnes séparées par des **tabulations** :

- `manuel/lectures.tsv` : pour chaque code de module (`1`, `2`, …, le même code
  que dans `exercices/avancement.tsv`), les sections à lire, par exemple
  `6.1-6.3, 9.1.1` (`a-b` = de a à b, sections de même niveau). Laisser vide
  s'il n'y a aucune lecture ;
- `manuel/sections.tsv` : numéros et titres des chapitres et sections du manuel
  (identique dans STT-1000 et STT-1900).

Le code est dans `R/diapos.R` (`diapos_lectures()`). Une section ou un module
inconnu est signalé par une ligne `[lectures]` dans le journal du rendu.

## Archives ZIP des diapos

La page *Diapositives* propose deux boutons « Tout télécharger » : l'un
regroupe toutes les versions présentation, l'autre toutes les versions
imprimables. Les archives `diapos/STT-1000-diapos-presentation.zip` et
`diapos/STT-1000-diapos-imprimable.zip` sont produites par `R/archives.R`,
lancé automatiquement avant chaque rendu (`project: pre-render:` dans
`_quarto.yml`), à partir des PDF compilés. Elles ne sont pas versionnées ;
un bouton n'apparaît que si son archive existe (donc si au moins un PDF de
cette version a été compilé). Le script nécessite l'exécutable `zip`.

## Logo généré automatiquement

`images/logo.png` (repris sur la page d'accueil) est régénéré à chaque rendu
à partir de `images/logo-source.png` (la silhouette) et de la couleur
`--purple` définie dans `styles.css` — voir `R/logo.R`, lancé automatiquement
par `project: pre-render:` dans `_quarto.yml`. Cette couleur est la même que
celle de STT-4300, SitePerso, STT-1920 et STT-1900 ; pour changer la couleur
du logo, il suffit donc de changer `--purple` dans `styles.css` ; ne pas
modifier `images/logo.png` directement (il sera écrasé au prochain rendu).

## À faire

- Ajouter les notes de cours (chapitres Quarto), sur le même modèle que
  [STT-1920](https://github.com/JulienMiron/STT-1920).
