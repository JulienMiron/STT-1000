% ============================================================================
% Classe BeamerTemplate.cls
% ============================================================================
%
% Classe LaTeX personnalisée pour les présentations Beamer (16:9).
% Fournit des couleurs, boîtes tcolorbox et un gabarit de page de titre
% adaptés aux cours du Département de mathématiques et de statistique
% de l'Université Laval.
%
% Auteur initial  : Jérôme Soucy (jsoucy@mat.ulaval.ca)
% Modification    : Julien Miron (julien.miron@mat.ulaval.ca)
% Créée le        : 22 décembre 2022
% Dernière version: 26 février 2026
%
% ============================================================================
%
% UTILISATION RAPIDE
% ------------------
%   \documentclass{BeamerTemplate}
%   \title{Mon titre}
%   \subtitle{Sous-titre}
%   \begin{document}
%     \maketitle
%     \begin{frame}{...}
%       ...
%     \end{frame}
%   \end{document}
%
% FICHIERS REQUIS
% ---------------
%   - ligne2.png   : image décorative pour la page de titre
%   - logo_ul.pdf  : logo de l'Université Laval
%
% ============================================================================

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{BeamerTemplate}[2026/02/26 v2.0 Gabarit Beamer ULaval]

% ============================================================================
% CHARGEMENT DE LA CLASSE DE BASE
% ============================================================================

% Beamer : présentations avec diapositives, animations, overlays.
% Options :
%   aspectratio=169 — format 16:9 (standard pour projecteurs modernes)
%   xcolor=table    — couleurs étendues pour les tableaux (\rowcolor, etc.)
%   12pt            — taille de police par défaut
%   handout         — (décommenter) mode impression sans animations
\LoadClass[
  aspectratio=169,
  %handout,
  xcolor=table,
  12pt
]{beamer}

% ============================================================================
% DÉTECTION DU MOTEUR ET POLICES
% ============================================================================

\RequirePackage{iftex}

\ifXeTeX
  % --- XeLaTeX : support natif d'Unicode ---
  \RequirePackage{polyglossia}
  \setdefaultlanguage[frenchpart=false]{french}

  \RequirePackage[math-style=TeX, bold-style=upright]{unicode-math}

  % Polices personnalisées (doivent être installées sur le système)
  \setmainfont{Linux Libertine O}
  \setsansfont{Linux Biolinum O}[Ligatures=TeX, Scale=MatchLowercase]
  \setmathfont{Latin Modern Math}
  \setmathfont[range=\setminus]{XITS Math}  % Beau symbole d'ensemble
\else
  % --- pdfLaTeX : UTF-8 via inputenc ---
  \RequirePackage[french]{babel}
  \RequirePackage[T1]{fontenc}
  \RequirePackage[utf8]{inputenc}

  % Polices classiques
  \RequirePackage{amsmath}
  \RequirePackage{amsfonts}
  \RequirePackage{libertine}                    % Texte : Linux Libertine
  \RequirePackage[frenchmath]{libertinust1math}  % Maths : Libertinus
\fi

% ============================================================================
% DÉFINITION DES COULEURS
% ============================================================================
%
% Les couleurs sont définies ICI, AVANT leur première utilisation.
% Modifier ces valeurs pour adapter le thème à un autre cours.
%
% ============================================================================

% --- Couleurs générales ---
\definecolor{burntorange}{RGB}{242, 96, 53}      % Orange vif (alerte)
\definecolor{Fond}{RGB}{252, 252, 252}            % Arrière-plan des diapos
\definecolor{TitreDiapo}{RGB}{0, 10, 0}           % Titre des diapos

% --- Couleurs thématiques principales ---
\definecolor{Dominante}{RGB}{125, 195, 229}       % Bleu clair (couleur principale)
\definecolor{Accent}{RGB}{239, 131, 84}           % Orange accentué (secondaire)

% --- Couleurs des boîtes \Boite ---
\definecolor{TexteBoite}{RGB}{25, 50, 102}
\definecolor{TitreBoite}{RGB}{25, 50, 102}

% --- Couleurs des théorèmes ---
\definecolor{TexteThm}{RGB}{0, 0, 0}
\definecolor{TitreThm}{RGB}{0, 0, 0}

% --- Couleur des puces de listes ---
\definecolor{itemizecolor}{RGB}{0, 0, 0}

% --- Couleurs institutionnelles (Université Laval) ---
\definecolor{rougelaval}{RGB}{237, 28, 36}
\definecolor{jaunelaval}{RGB}{251, 199, 7}

% --- Alias de couleurs pour les boîtes tcolorbox ---

% Définitions
\colorlet{DefnColorBar}{Dominante}        % Barre latérale
\colorlet{DefnColorBG}{Dominante!10}      % Fond

% Théorèmes
\colorlet{ThmColorBar}{Accent}
\colorlet{ThmColorBG}{Accent!20}

% Propositions
\colorlet{PropColorBar}{Accent}
\colorlet{PropColorBG}{Accent!20}

% ============================================================================
% HYPERLIENS
% ============================================================================

\RequirePackage{hyperref}
\hypersetup{
  pdfencoding=auto,
  breaklinks=true,
  colorlinks=true,
  linkcolor=.,           % Liens internes : couleur du texte courant
  filecolor=blue,
  urlcolor=blue,
  anchorcolor=.,
  citecolor=blue
}

% Apparence des URLs (police plus petite)
\RequirePackage{url}
\renewcommand{\UrlFont}{\scriptsize}

% Guillemets français intelligents
\RequirePackage{csquotes}

% ============================================================================
% PACKAGES SUPPLÉMENTAIRES
% ============================================================================

% --- Boîtes et dessins ---
\RequirePackage[many]{tcolorbox}   % Boîtes colorées (théorèmes, définitions)
\RequirePackage{pgfplots}          % Graphiques de fonctions (charge tikz + pgf)
\pgfplotsset{compat=1.17}         % Compatibilité pgfplots
\RequirePackage{mathrsfs}          % Police calligraphique : \mathscr{L}

% Bibliothèques TikZ (une seule déclaration regroupée)
\usetikzlibrary{
  patterns,                % Hachures, motifs de remplissage
  shapes,                  % Formes : ellipse, diamond, etc.
  arrows.meta,             % Pointes de flèches personnalisées
  positioning,             % Positionnement relatif entre noeuds
  calc,                    % Coordonnées calculées
  intersections,           % Points d'intersection de chemins
  decorations.pathreplacing, % Accolades, annotations le long d'un chemin
  backgrounds,             % Couche d'arrière-plan
  fit,                     % Ajuster un noeud autour d'autres noeuds
  plotmarks,               % Marqueurs pour les tracés
  pgfplots.fillbetween     % Remplir entre deux courbes
}

% --- Icônes et symboles ---
\RequirePackage{fontawesome5}      % Icônes : \faIcon{github}, \faEnvelope

% --- Unités SI ---
\RequirePackage{siunitx}           % \SI{5}{\kilogram}, \num{1234}

% --- Logique et symboles ---
\RequirePackage{centernot}         % Négation centrée : \centernot\in

% --- Sous-fichiers et texte verbatim ---
\RequirePackage{subfiles}          % Compilation de sous-fichiers indépendants
\RequirePackage{verbatim}          % Environnement verbatim amélioré
\RequirePackage{fancyvrb}          % Verbatim avec options (numérotation, etc.)

% --- Tableaux ---
\RequirePackage{tabularx}          % Tableaux à largeur fixe avec colonne X
\RequirePackage{booktabs}          % Filets horizontaux élégants (\toprule, etc.)
\RequirePackage{array}             % Colonnes personnalisées
\RequirePackage{multirow}          % Cellules fusionnées verticalement

% ============================================================================
% CONFIGURATION VISUELLE DE BEAMER
% ============================================================================

% Utilise les vraies polices installées (pas les polices sans-serif de Beamer)
\usefonttheme{professionalfonts}

% Désactive la barre latérale gauche
\setbeamersize{sidebar width left=0pt}

% Supprime les icônes de navigation en bas à droite
\setbeamertemplate{navigation symbols}{}

% Affiche seulement le numéro de diapositive en bas
\setbeamertemplate{footline}[frame number]

% Affiche automatiquement une diapositive de section au début de chaque \section
\AtBeginSection{\frame{\sectionpage}}

% ============================================================================
% POLICES BEAMER
% ============================================================================

% Titre des diapos : gros + gras
\setbeamerfont{frametitle}{size=\large, series=\bfseries}

% Titre de la présentation : encore plus gros + gras
\setbeamerfont{title}{size=\Large, series=\bfseries}

% ============================================================================
% COMMANDES PERSONNALISÉES
% ============================================================================

% \notrightarrow — Symbole « ne tend pas vers » (flèche barrée)
%   Usage : $X_n \notrightarrow X$
\newcommand{\notrightarrow}{%
  \mathrel{\tikz[scale = 0.3]{
    \draw[->,thick] (0,0) -- (1,0);
    \draw[thick] (0.15,-0.35) -- (1,0.35);
  }}%
}

% \alerter{texte} — Texte en orange brûlé (mise en valeur)
\newcommand{\alerter}[1]{%
  \textcolor{burntorange}{#1}%
}

% ============================================================================
% APPLICATION DES COULEURS DANS BEAMER
% ============================================================================

% Texte d'alerte (utilisé par \alert{...})
\setbeamercolor{alerted text}{fg=burntorange}

% Arrière-plan
\setbeamercolor{background canvas}{bg=Fond}
\setbeamercolor{normal text}{bg=Fond, fg=black}

% Titres de diapos
\setbeamercolor{frametitle}{fg=TitreDiapo, bg=Fond}

% Blocs standards
\setbeamercolor{block body}{bg=normal text.bg!90!black}
\setbeamercolor{block title}{bg=black!60, fg=white}
\setbeamercolor{block title example}{fg=example text.fg!75!normal text.fg, bg=Fond}

% Structure (titres de sections, numérotation)
\setbeamercolor{structure}{bg=black, fg=white}

% Listes à puces et numérotées
\setbeamercolor{itemize item}{fg=itemizecolor}
\setbeamercolor{enumerate item}{fg=itemizecolor}
\setbeamercolor{itemize subitem}{fg=itemizecolor}
\setbeamercolor{itemize subsubitem}{fg=itemizecolor}

% Table des matières (\tableofcontents) : sinon héritée de « structure » (blanc)
\setbeamercolor{section in toc}{fg=TexteBoite}
\setbeamercolor{subsection in toc}{fg=TexteBoite}
\setbeamercolor{section number projected}{bg=Dominante, fg=white}

% ============================================================================
% STYLES DES LISTES
% ============================================================================

\setbeamertemplate{itemize item}[circle]          % Puce principale : cercle
\setbeamertemplate{itemize subitem}[square]       % Sous-puce : carré
\setbeamertemplate{itemize subsubitem}[triangle]  % Sous-sous-puce : triangle

% ============================================================================
% PAGE DE SECTION PERSONNALISÉE
% ============================================================================

% Couleur de la boîte de section (texte clair sur fond Dominante)
\setbeamercolor{colsection}{fg=Dominante!20, bg=Dominante}

% Modèle affiché automatiquement à chaque \section (via \AtBeginSection)
\setbeamertemplate{section page}{%
  \begin{centering}
    \begin{beamercolorbox}[sep=12pt, center]{colsection}
      \usebeamerfont{section title}\insertsection\par
    \end{beamercolorbox}
  \end{centering}
}

% ============================================================================
% BOÎTES PERSONNALISÉES (tcolorbox)
% ============================================================================

% --- Définition ---
% Boîte avec barre bleue à gauche, fond bleu pâle.
% Usage : \begin{defn} Texte de la définition. \end{defn}
\newtcolorbox[auto counter]{defn}[1][]{
  boxrule=0pt,
  boxsep=0pt,
  colback=DefnColorBG,
  enhanced jigsaw,
  detach title,
  fonttitle=\bfseries,
  coltitle=black,
  title=Définition.~,
  before upper={\tcbtitle},
  borderline west={2pt}{0pt}{DefnColorBar},
  sharp corners,
  before skip=10pt,
  after skip=10pt,
  breakable,
}

% --- Théorème ---
% Boîte avec barre orange à gauche, fond orange pâle.
% Usage : \begin{thm} Énoncé du théorème. \end{thm}
\newtcolorbox[auto counter]{thm}[1][]{
  boxrule=0pt,
  boxsep=0pt,
  colback=ThmColorBG,
  enhanced jigsaw,
  detach title,
  fonttitle=\bfseries,
  coltitle=TitreThm,
  coltext=TexteThm,
  title=Théorème.~,
  before upper={\tcbtitle},
  borderline west={2pt}{0pt}{ThmColorBar},
  sharp corners,
  before skip=10pt,
  after skip=10pt,
  breakable,
}

% --- Proposition ---
% Même style que les théorèmes.
% Usage : \begin{prp} Énoncé de la proposition. \end{prp}
\newtcolorbox[auto counter]{prp}[1][]{
  boxrule=0pt,
  boxsep=0pt,
  colback=PropColorBG,
  enhanced jigsaw,
  detach title,
  fonttitle=\bfseries,
  coltitle=black,
  title=Proposition.~,
  before upper={\tcbtitle},
  borderline west={2pt}{0pt}{PropColorBar},
  sharp corners,
  before skip=10pt,
  after skip=10pt,
  breakable,
}

% --- Boîte informative ---
% Boîte avec titre personnalisé (fond Dominante).
% Usage : \begin{Boite}{Mon titre} Contenu. \end{Boite}
\newtcolorbox[auto counter]{Boite}[2][]{
  boxrule=0pt,
  boxsep=0pt,
  colback=Dominante!20,
  collower=Fond,
  enhanced jigsaw,
  fonttitle=\medskip\bfseries,
  coltitle=TitreBoite,
  coltext=TexteBoite,
  title={#2},
  colbacktitle=Dominante,
  before upper={\tcbtitle},
  borderline west={2pt}{0pt}{Dominante},
  sharp corners,
  before skip=10pt,
  after skip=10pt,
  bottomtitle=1mm,
  toptitle=1mm,
  breakable,
}

% ============================================================================
% GABARIT DE PAGE DE TITRE
% ============================================================================

% Page de titre personnalisée avec ligne décorative et logo ULaval.
% Fichiers requis : ligne2.png, logo_ul.pdf
\defbeamertemplate*{title page}{titlepage}{%
  \thispagestyle{empty}

  % Ligne décorative en arrière-plan (centrée verticalement)
  \begin{tikzpicture}[remember picture, overlay]
    \node[anchor=center, inner sep=0pt] at ([yshift=0cm]current page.center)
      {\includegraphics[width=\paperwidth]{ligne2.png}};
  \end{tikzpicture}

  \vspace*{0.5cm}

  \begin{center}
    % Titre et sous-titre
    {\Large \color{black} \inserttitle\par}
    \vspace{0.2cm}
    {\color{black!67} \insertsubtitle\par}

    \vspace{2cm}

    % Institut (défini ci-dessous)
    \insertinstitute

    \vspace{1cm}

    % Logo ULaval
    \includegraphics[width=4cm]{logo_ul.pdf}
  \end{center}
}

% ============================================================================
% BIBLIOGRAPHIE (biblatex + biber)
% ============================================================================

\RequirePackage[
  backend=biber,         % Moteur de tri et de traitement
  style=authoryear,      % Style auteur-année, adapté aux commandes existantes
  natbib=true,           % Active les commandes de compatibilité natbib
  sorting=nyt            % Tri nom, année, titre
]{biblatex}

% Alias pour compatibilité avec des commandes historiques utilisées dans les cours
\providecommand{\citeN}{\citet}
\providecommand{\citeNP}{\citealt}

% Note : chaque fichier .tex doit charger son propre .bib via
%   \addbibresource{monfichier.bib}
% dans le préambule (après \documentclass).

% Couleurs des entrées de bibliographie (toutes en noir)
\setbeamercolor{bibliography entry author}{fg=black}
\setbeamercolor{bibliography entry location}{fg=black}
\setbeamercolor{bibliography entry note}{fg=black}
\setbeamercolor{bibliography item}{fg=black}

% ============================================================================
% MÉTADONNÉES PAR DÉFAUT
% ============================================================================

% Institut affiché sur la page de titre (peut être redéfini dans le .tex)
\institute{Département de mathématiques et de statistique}
