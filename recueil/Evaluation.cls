% ============================================================================
% Classe Evaluation.cls
% ============================================================================
%
% Classe LaTeX personnalisée pour la création d'examens universitaires.
% Basée sur la classe « exam » (https://ctan.org/pkg/exam).
%
% Auteur  : Julien Miron (julien.miron@mat.ulaval.ca)
% Version : 26 février 2026
%
% ============================================================================
%
% UTILISATION RAPIDE
% ------------------
%   Dans le fichier .tex de l'examen :
%
%     \def\SigleNumero{STT-1900}
%     \def\NomCours{Méthodes statistiques pour ingénieurs}
%     \def\DateEvaluation{20 décembre 2025}
%     ...
%     \documentclass{Evaluation}
%     \begin{document}
%       ...
%     \end{document}
%
%   Les métadonnées sont définies avec \def AVANT \documentclass.
%   La couverture est générée automatiquement à \begin{document}.
%
% OPTIONS CONTRÔLÉES DANS LE FICHIER .TEX
% ----------------------------------------
%   \def\Gradescope{.}     -> Mode Gradescope (recto seulement)
%   \def\Gradescope{}      -> Mode impression (recto-verso, par défaut)
%
%   \newcommand{\affichepoints}{}    -> Affiche no exercice + points (défaut)
%   \renewcommand{\affichepoints}{.} -> Masque no et points (ex: recueil)
%
%   \documentclass[answers]{Evaluation}  -> Affiche les solutions
%   \printanswers / \noprintanswers      -> Idem, après \documentclass
%
% ============================================================================

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{Evaluation}[2026/02/26 v2.0 Classe pour examens universitaires]

% ============================================================================
% TRAITEMENT DES OPTIONS DE CLASSE
% ============================================================================
%
% Les options inconnues (ex : « answers ») sont transmises à la classe
% « exam ». Cela permet d'écrire :
%   \documentclass[answers]{Evaluation}
% pour afficher automatiquement les solutions.
%
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{exam}}
\ProcessOptions\relax

% ============================================================================
% CHARGEMENT DE LA CLASSE DE BASE
% ============================================================================
%
% La classe « exam » fournit :
%   - l'environnement questions / parts / subparts
%   - les commandes de points (\addpoints, \totalpoints, etc.)
%   - les en-têtes / pieds de page configurables
%   - les checkbox pour les QCM
%
\LoadClass{exam}

% ============================================================================
% MODE GRADESCOPE
% ============================================================================
%
% Gradescope nécessite un PDF en recto seulement (une question par page).
% Le mode est contrôlé par la variable \Gradescope :
%   - vide  {}  -> recto-verso (impression classique)
%   - non vide {.} -> recto seulement (Gradescope)
%
% Définir \def\Gradescope{.} dans le .tex AVANT \documentclass.
% Si non défini, la valeur par défaut est vide (recto-verso).
%
\providecommand{\Gradescope}{}

% ============================================================================
% CHARGEMENT DES PACKAGES
% ============================================================================
%
% Note : dans un fichier .cls, on utilise \RequirePackage au lieu de
% \usepackage. Les deux fonctionnent, mais \RequirePackage est la norme
% pour les classes et packages (permet un chargement avant \documentclass).
%
% ============================================================================

% --- Détection du moteur TeX ---
\RequirePackage{iftex}             % \ifPDFTeX, \ifXeTeX, \ifLuaTeX

% --- Mise en page ---
\RequirePackage{geometry}          % Marges : \newgeometry, \restoregeometry
\RequirePackage{afterpage}         % Exécuter du code après la page courante

% --- Listes ---
\RequirePackage{enumitem}          % Personnalisation : [label=\alph*)]

% --- Mathématiques ---
\RequirePackage{mathtools}         % Charge automatiquement amsmath + extensions
                                   % (dcases, \coloneqq, \DeclarePairedDelimiter)
\RequirePackage{amssymb}           % Symboles AMS : \mathbb, \therefore, etc.
                                   % (charge automatiquement amsfonts)
\RequirePackage{xfrac}             % Fractions diagonales : \sfrac{a}{b}
\RequirePackage{icomma}            % Virgule intelligente : pas d'espace après ,

% --- Tableaux ---
\RequirePackage{multirow}          % Cellules fusionnées verticalement
\RequirePackage{array}             % Colonnes personnalisées : >{}, m{}, p{}
% Type de colonne P{largeur} : comme p{largeur}, mais centré horizontalement
% et verticalement. Utilisé dans plusieurs examens.
\newcolumntype{P}[1]{>{\centering\arraybackslash}p{#1}}
\RequirePackage{diagbox}           % Cellules diagonales : \diagbox{X}{Y}

% --- Boîtes et couleurs ---
\RequirePackage[many]{tcolorbox}   % Boîtes colorées (si besoin dans un examen)
\RequirePackage{xcolor}            % Couleurs avancées : RGB, HTML, mixing

% --- Typographie française ---
\RequirePackage[french]{babel}     % Espacement, guillemets, titres en français

% --- Programmation LaTeX ---
\RequirePackage{etoolbox}          % \ifdefempty, \pretocmd, \providecommand
\RequirePackage{calc}              % Calculs : \textwidth - 5.5cm

% --- Graphiques et dessins ---
\RequirePackage{graphicx}          % \includegraphics (logo, figures, etc.)
\RequirePackage{tikz}              % Dessins vectoriels

% --- Police et encodage (pdfLaTeX) ---
\RequirePackage[9pt]{extsizes}     % Taille de police 9pt
\RequirePackage[T1]{fontenc}       % Encodage T1 : accents, ligatures
\RequirePackage{arev}              % Police sans-serif Arev (texte + maths)

% --- Divers ---
\RequirePackage{comment}           % Masquer de grands blocs : \begin{comment}
\RequirePackage{ifsym}             % Symboles variés : dés, horloges, etc.
\RequirePackage{pdfpages}          % Inclure des pages PDF : \includepdf
\RequirePackage{listings}          % Code source formaté : \begin{lstlisting}

% Configuration par défaut de listings pour le langage R
\lstset{
  language=R,
  basicstyle=\ttfamily
}

% ============================================================================
% CONFIGURATION DE TIKZ
% ============================================================================

% Bibliothèques TikZ utilisées dans les examens
\usetikzlibrary{
  arrows.meta,              % Pointes de flèches personnalisées (Latex, Stealth)
  calc,                     % Coordonnées calculées : ($(A)!0.5!(B)$)
  positioning,              % Positionnement relatif : right=5mm of nodeA
  decorations.markings      % Marques le long d'un chemin (flèche au milieu)
}

% --- Styles TikZ globaux ---
\tikzset{
  % Pointe de flèche par défaut
  >={Latex[length=2.2mm]},
  % Point fermé (valeur incluse sur un graphique de fonction)
  dot/.style  = {circle, draw, fill=white, inner sep=1.1pt, minimum size=3.8pt},
  % Point ouvert (valeur exclue sur un graphique de fonction)
  open/.style = {circle, draw, fill=white, inner sep=1.1pt, minimum size=4pt},
  % Étiquette compacte pour un point
  pt/.style   = {font=\small},
}

% Style pour dessiner une flèche au milieu d'un segment
% Usage : \draw[mid arrow] (A) -- (B);
\tikzset{
  mid arrow/.style={
    postaction={decorate},
    decoration={markings, mark=at position 0.5 with {\arrow{Latex}}}
  }
}

% ============================================================================
% COMMANDES PERSONNALISÉES — SYMBOLES ET DESSINS
% ============================================================================

% Case à cocher TikZ pour les QCM (remplace le symbole par défaut de « exam »)
\checkboxchar{%
  \raisebox{-0.1cm}{%
    \begin{tikzpicture}
      \draw (0,0) -- (0.5,0) -- (0.5,0.5) -- (0,0.5) -- cycle;
    \end{tikzpicture}}}

% Symbole de crochet (checkmark) dessiné avec TikZ
\def\checkmark{%
  \tikz\fill[scale=0.4](0,.35) -- (.25,0) -- (1,.7) -- (.25,.15) -- cycle;%
}

% \Mypm — Symbole plus-ou-moins personnalisé, centré verticalement
\newcommand{\Mypm}{%
  \mathbin{\tikz [x=1.4ex,y=1.4ex,line width=.1ex]
    \draw (0.0,0) -- (1.0,0) (0.5,0.08) -- (0.5,0.92) (0.0,0.5) -- (1.0,0.5);}%
}

% \rouge{texte} — Texte en rouge (corrections, annotations)
\newcommand{\rouge}[1]{\textcolor{red}{#1}}

% \boite{largeur}{hauteur} — Rectangle vide (zone de réponse)
%   Exemple : \boite{5}{2} dessine un rectangle de 5 cm x 2 cm
\newcommand{\boite}[2]{%
  \raisebox{-.4cm}{%
    \begin{tikzpicture}
      \draw (0,0) -- (#1,0) -- (#1,#2) -- (0,#2) -- cycle;
    \end{tikzpicture}%
  }%
}

% \myline{longueur} — Ligne horizontale en mode math (blancs à remplir)
%   Exemple : $x = \myline{2}$
\newcommand{\myline}[1]{%
  \mathrel{\raisebox{-.7ex}{%
    \begin{tikzpicture}
      \draw (0,0) -- (#1,0);
    \end{tikzpicture}}}%
}

% \carresection{Nom} — Case à cocher + nom d'enseignant (page couverture)
%   Dessine un carré coché suivi du texte à droite.
%   Usage dans la couverture : \carresection{\SectionA}
\newcommand{\carresection}[1]{%
  \begin{tikzpicture}
    \draw (0,0) -- (0.5,0) -- (0.5,0.5) -- (0,0.5) -- cycle;
    \draw (0.5,0.25) node[align=left, right]{#1};
  \end{tikzpicture}%
}

% \separation — Séparateur décoratif (courbe ondulée + point central)
\newcommand{\separation}{%
  \centering
  \begin{tikzpicture}[scale=0.33]
    \draw (0,0) .. controls (1,1) and (2,-1) .. (3,0);
    \draw[fill=black] (3.5,0) circle (0.3cm);
    \draw (4,0) .. controls (5,-1) and (5,1) .. (7,0);
  \end{tikzpicture}%
}

% ============================================================================
% COMMANDES PERSONNALISÉES — GESTION DES PAGES
% ============================================================================

% \pageblanche — Saut de page intelligent selon le mode.
%   - Recto-verso (\Gradescope vide) : simple \newpage
%   - Gradescope  (\Gradescope non vide) : \newpage + page blanche + \newpage
%     Cela garantit que la question suivante tombe sur une page recto.
\newcommand{\pageblanche}{%
  \ifdefempty{\Gradescope}{\newpage}{%
    \newpage
    \thispagestyle{empty}%
    \null
    \newpage
  }%
}

% \blankpage — Page blanche sans numérotation (recule le compteur)
\newcommand{\blankpage}{%
  \null
  \thispagestyle{empty}%
  \addtocounter{page}{-1}%
  \newpage
}

% \pagesuivante{\ref{label}} — Annonce la suite d'un exercice.
%   Insère un \pageblanche puis affiche « Suite de l'exercice X ».
\newcommand{\pagesuivante}[1]{%
  \begingroup
  \vfill
    \large
    \emph{\textbf{Suite de l'exercice #1 sur la feuille suivante}}%
    \medskip
    \pageblanche
    \large \emph{\textbf{Suite de l'exercice #1}}%
    \medskip
  \endgroup
}

% \suite{\ref{label}} — Affiche seulement « Suite de l'exercice X »
%   (pas de saut de page, utile après un saut manuel)
\newcommand{\suite}[1]{%
  \begingroup
    \large \emph{\textbf{Suite de l'exercice #1}}%
  \endgroup
}

% ============================================================================
% VARIABLES DU DOCUMENT (métadonnées de l'évaluation)
% ============================================================================
%
% Ces commandes ont un défaut vide.
% Elles sont redéfinies dans le préambule du .tex via \def :
%
%   \def\SigleNumero{STT-1900}
%   \def\NomCours{Méthodes statistiques}
%   ...
%
% \providecommand ne fait rien si la commande est déjà définie.
% Comme \def est exécuté AVANT le chargement de la classe, les
% valeurs de l'utilisateur sont préservées.
%
% ============================================================================

% --- Identification du cours ---
\providecommand{\SigleNumero}{}       % Sigle du cours (ex: STT-1000)
\providecommand{\NomCours}{}          % Nom complet du cours

% --- Informations sur l'évaluation ---
\providecommand{\NomEvaluation}{}     % Titre (ex: Examen final)
\providecommand{\Ponderation}{}       % Pondération en % (ex: 40)
\providecommand{\DateEvaluation}{}    % Date (ex: 20 décembre 2025)
\providecommand{\HeureEvaluation}{}   % Heure (ex: 13h30 à 16h20)
\providecommand{\Session}{}           % Session (ex: Automne 2025)

% --- Personnel ---
\providecommand{\Coordonnateur}{}     % Coordonnateur (masculin)
\providecommand{\Coordonnatrice}{}    % Coordonnatrice (féminin)
\providecommand{\Enseignant}{}        % Enseignant (section unique, masculin)
\providecommand{\Enseignante}{}       % Enseignante (section unique, féminin)

% --- Sections (cours multisection) ---
\providecommand{\SectionA}{}          % Enseignant — section A
\providecommand{\SectionB}{}          % Enseignant — section B
\providecommand{\SectionC}{}          % Enseignant — section C
\providecommand{\SectionD}{}          % Enseignant — section D

% --- Identification de l'étudiant ---
\providecommand{\Matricule}{}         % Matricule de l'étudiant

% --- Contenu de la couverture ---
\providecommand{\Directives}{}        % Directives affichées en bas de couverture

% --- Options d'affichage ---
\providecommand{\NombreLignes}{}      % Nb de lignes de réponse (si applicable)
\providecommand{\PapierLegal}{}       % Non vide -> format légal (14 po)
\providecommand{\EnLigne}{}           % Non vide -> déclaration d'honneur
\providecommand{\Solutions}{}         % Non vide -> afficher les solutions
\providecommand{\affichepoints}{}     % Vide -> affiche no exercice + points
                                      % Non vide -> masque (utile pour le recueil)

% ============================================================================
% MISE EN FORME DES QUESTIONS (classe « exam »)
% ============================================================================

% Espacement vertical (1 ligne) avant chaque question
\pretocmd{\question}{\vspace{1\baselineskip}}{}{}

% Hauteur des lignes de réponse (\fillwithlines, etc.)
\setlength\linefillheight{1cm}

% Active le comptage automatique des points
\addpoints

% Format d'affichage des questions selon \affichepoints :
%   vide     -> « Exercice 3 (12 points) »
%   non vide -> « Exercice » (sans numéro ni points, utile pour le recueil)
\ifdefempty{\affichepoints}{%
  % --- Avec numéro et points ---
  \qformat{\hspace{.58cm}{\sc\textbf{Exercice~\thequestion}}%
           ~{\small(\,\totalpoints~points)}~\hfill}%
  \bonusqformat{\hspace{.58cm}{\sc\textbf{Exercice~\thequestion{} BONUS}}%
                ~{\small(\,\totalbonuspoints~points)}~\hfill}%
  \bonuspointpoints{bonus point}{points}%
}{%
  % --- Sans numéro ni points ---
  \qformat{\vspace{1cm}\hspace{.58cm}{\sc\textbf{Exercice}}~\hfill}%
  \bonusqformat{\hspace{.58cm}{\sc\textbf{Exercice~\thequestion{} BONUS}}~\hfill}%
}

% ============================================================================
% EN-TÊTES ET PIEDS DE PAGE
% ============================================================================

% Première page : pas d'en-tête (la couverture gère tout)
\firstpageheader{}{}{}

% Pages suivantes : pas d'en-tête
\runningheader{}{}{}

% Pied de page courant :
%   Gauche : « Page X / N »
%   Centre : « STT-1900 -- Examen final »
%   Droite : (vide)
\runningfooter{%
  \small Page \thepage~/~\numpages%
}{%
  \small\ifdefempty{\SigleNumero}{}{%
    \hspace{.58cm}\SigleNumero%
    \small\ifdefempty{\NomEvaluation}{}{~--~\NomEvaluation}%
  }%
}{%
}

% ============================================================================
% PAGE COUVERTURE
% ============================================================================

% \couverture — Génère automatiquement la page de titre de l'évaluation.
%   Appelée via \AtBeginDocument (voir fin du fichier).
%   Contient : logo ULaval, champs d'identification, titre, directives.
\newcommand{\couverture}{%
  % --- Marges temporaires pour la couverture ---
  \newgeometry{margin=2cm}

  % -----------------------------------------------------------------------
  % En-tête : logo ULaval (gauche) + champs d'identification (droite)
  % -----------------------------------------------------------------------
  \begin{minipage}[t]{7cm}
    \begin{flushleft}
      \hspace{-.5cm}\includegraphics[width=5cm]{logo_ul.pdf}\\
      \hspace{-.5cm}{\sf\scriptsize \textbf{Faculté des sciences et génie}}\\[-0.2cm]
      \hspace{-.5cm}{\sf\scriptsize Département de mathématiques et statistique}\\[2cm]
    \end{flushleft}
  \end{minipage}~~~
  \begin{minipage}[t]{\textwidth-5.5cm}
    % Champ « Prénom et nom »
    \begin{tikzpicture}
      \draw (0,0) -- (10,0) -- (10,1.5) -- (0,1.5) -- cycle;
      \draw (0,0) node[below right]{\scriptsize Prénom et nom};
    \end{tikzpicture}\\[0.4cm]
    % Champ « NI (9 chiffres) »
    \begin{tikzpicture}
      \draw (0,0) -- (9,0) -- (9,1) -- (0,1) -- cycle;
      \draw (0,0) node[below right]{\scriptsize NI (9 chiffres)};
    \end{tikzpicture}\\[0.4cm]
    % Cases à cocher pour la section (si cours multisection)
    \ifdefempty{\SectionA}{}{\carresection{\SectionA}\\}
    \ifdefempty{\SectionB}{}{\carresection{\SectionB}\\}
    \ifdefempty{\SectionC}{}{\carresection{\SectionC}\\}
    \ifdefempty{\SectionD}{}{\carresection{\SectionD}}
    \ifdefempty{\SectionA}{}{\scriptsize Cochez le nom de votre enseignant}
  \end{minipage}

  \vfill

  % -----------------------------------------------------------------------
  % Centre : titre, cours, date, heure, enseignant
  % -----------------------------------------------------------------------
  \begin{center}
    % Nom de l'évaluation + pondération
    {\huge\textbf{%
      \ifdefempty{\NomEvaluation}{}{\NomEvaluation}%
      \ifdefempty{\Ponderation}{}{~(\Ponderation~\%)}%
    }}~\\
    % Nom du cours + sigle
    {\Large%
      \ifdefempty{\NomCours}{}{\NomCours}%
      \ifdefempty{\SigleNumero}{}{~(\SigleNumero)}%
    }~\\
    % Date
    {\Large\ifdefempty{\DateEvaluation}{}{\DateEvaluation}}~\\
    \smallskip
    % Heure
    {\LARGE\ifdefempty{\HeureEvaluation}{}{\HeureEvaluation}}~\\
    % Enseignant / Enseignante
    \ifdefempty{\Enseignant}{}{Enseignant : \Enseignant}%
    \ifdefempty{\Enseignante}{}{Enseignante : \Enseignante}~\\
    % Coordonnateur / Coordonnatrice
    \ifdefempty{\Coordonnateur}{}{Coordonnateur : \Coordonnateur}%
    \ifdefempty{\Coordonnatrice}{}{Coordonnatrice : \Coordonnatrice}
  \end{center}

  \vfill

  % -----------------------------------------------------------------------
  % Bas : directives de l'évaluation
  % -----------------------------------------------------------------------
  \ifdefempty{\Directives}{}{%
    {\noindent\textbf{Directives de l'évaluation} \Directives}%
  }
  \medskip

  % --- Rétablir les marges pour le contenu de l'examen ---
  % footskip=0.5cm laisse un petit espace entre les derniers caractères
  % possibles d'une page et le pied de page.
  \newgeometry{margin=1.7cm, left=0.7cm, bottom=1.5cm, footskip=0.5cm}
}

% ============================================================================
% DÉCLENCHEMENT AUTOMATIQUE
% ============================================================================

% La couverture est générée automatiquement à \begin{document}.
\AtBeginDocument{\couverture}
