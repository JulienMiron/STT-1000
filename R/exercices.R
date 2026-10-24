# Page « Exercices » : exercices du manuel que l'on peut faire selon
# l'avancement du cours en classe.
#
# Données (dossier exercices/, fichiers TSV séparés par des tabulations) :
#   correspondance.tsv : pour chaque exercice du manuel (ou groupe de
#                        sous-questions), la diapo à partir de laquelle toute
#                        la matière nécessaire a été vue en classe ;
#   avancement.tsv     : où le cours est rendu, séance après séance (à mettre
#                        à jour au fil de la session).
#
# Les numéros de diapos sont ceux de la version présentation, c'est-à-dire le
# numéro affiché au bas de chaque diapo. Ils sont recalculés à chaque rendu à
# partir des sources diapos/Module *.tex (voir exo_diapos_module()) : si on
# ajoute ou retire une diapo, la colonne « titre » de correspondance.tsv sert
# d'ancrage et l'exercice suit sa diapo. Les ajustements sont signalés dans le
# journal du rendu.

source("R/diapos.R")   # diapos_nettoyer()

# Diagnostics : écrits dans le journal du rendu (onglet Actions), jamais dans la page
exo_signaler <- function(...) cat("[exercices]", ..., "\n", file = stderr())

# ---------------------------------------------------------------------------
# Lecture des diapos d'un module à partir de la source LaTeX
# ---------------------------------------------------------------------------

# Argument entre accolades qui commence à la position pos (pos = « { »)
exo_accolades <- function(s, pos) {
  car <- strsplit(substr(s, pos, min(nchar(s), pos + 5000)), "")[[1]]
  if (length(car) == 0 || car[1] != "{") return(NA_character_)
  prof <- 0
  for (k in seq_along(car)) {
    echappe <- k > 1 && car[k - 1] == "\\"
    if (car[k] == "{" && !echappe) prof <- prof + 1
    if (car[k] == "}" && !echappe) prof <- prof - 1
    if (prof == 0) return(if (k > 2) paste(car[2:(k - 1)], collapse = "") else "")
  }
  NA_character_
}

# Version visée par une spécification <...> de Beamer
exo_version_spec <- function(spec) {
  pres <- grepl("beamer|presentation", spec)
  impr <- grepl("handout", spec)
  if (pres && !impr) "presentation" else if (impr && !pres) "imprimable" else "les deux"
}

# Liste des diapos d'un fichier Beamer, dans l'ordre :
#   pres    numéro dans la version présentation (NA si absente de cette version)
#   impr    numéro dans la version imprimable (NA si absente de cette version)
#   titre   titre LaTeX de la diapo ("" si aucun)
#   type    "frame" ou "section" (diapo de titre produite par \section via
#           \AtBeginSection dans BeamerTemplate.cls)
#   section titre de la section en cours
# Reproduit la numérotation de Beamer pour la façon dont les diapos du cours
# sont écrites : commentaires %, environnements comment, \section (non étoilé),
# \begin{frame}, \frame{...}, option noframenumbering, \only<beamer>{...}.
exo_diapos_module <- function(fichier) {
  lignes <- readLines(fichier, warn = FALSE, encoding = "UTF-8")
  lignes <- sub("(^|[^\\\\])%.*$", "\\1", lignes)        # commentaires
  dans <- FALSE
  garder <- logical(length(lignes))
  for (i in seq_along(lignes)) {                           # environnements comment
    if (!dans && grepl("\\\\begin\\{comment\\}", lignes[i])) dans <- TRUE
    garder[i] <- !dans
    if (dans && grepl("\\\\end\\{comment\\}", lignes[i])) dans <- FALSE
  }
  txt <- paste(lignes[garder], collapse = "\n")
  txt <- sub("\\\\end\\{document\\}.*$", "", txt)
  # \AtBeginSection{\frame{\sectionpage}} : définition, pas une diapo
  repeat {
    p <- regexpr("\\\\AtBegin(Sub)*[Ss]ection\\s*(\\[[^]]*\\])?\\s*\\{", txt, perl = TRUE)
    if (p < 0) break
    a <- p + attr(p, "match.length") - 1
    corps <- exo_accolades(txt, a)
    fin <- if (is.na(corps)) a else a + nchar(corps) + 1
    txt <- paste0(substr(txt, 1, p - 1), substr(txt, fin + 1, nchar(txt)))
  }
  # Zones propres à une version : \only<beamer>{...}, \mode<handout>{...}
  zones <- data.frame(debut = integer(), fin = integer(), version = character())
  mz <- gregexpr("\\\\(only|mode)\\s*<([^>]*)>\\s*\\{", txt, perl = TRUE)[[1]]
  if (mz[1] != -1) for (j in seq_along(mz)) {
    a <- mz[j] + attr(mz, "match.length")[j] - 1
    spec <- sub("^.*<([^>]*)>.*$", "\\1", substr(txt, mz[j], a))
    corps <- exo_accolades(txt, a)
    v <- exo_version_spec(spec)
    if (!is.na(corps) && v != "les deux")
      zones <- rbind(zones, data.frame(debut = a, fin = a + nchar(corps) + 1, version = v))
  }
  version_a <- function(pos) {
    z <- zones[zones$debut <= pos & zones$fin >= pos, , drop = FALSE]
    if (nrow(z) == 0) "les deux" else z$version[nrow(z)]
  }
  motif <- "\\\\section(\\*?)\\s*(\\[[^]]*\\])?\\s*\\{|\\\\begin\\{frame\\}|\\\\frame\\s*\\{"
  m <- gregexpr(motif, txt, perl = TRUE)[[1]]
  titres <- character(); types <- character(); versions <- character()
  if (m[1] != -1) for (j in seq_along(m)) {
    debut <- m[j]
    long <- attr(m, "match.length")[j]
    tok <- substr(txt, debut, debut + long - 1)
    if (startsWith(tok, "\\section")) {
      if (grepl("^\\\\section\\*", tok)) next
      titre <- exo_accolades(txt, debut + long - 1)
      type <- "section"
      version <- version_a(debut)
    } else if (startsWith(tok, "\\frame")) {
      titre <- ""
      type <- "frame"
      version <- version_a(debut)
    } else {
      reste <- substr(txt, debut + long, debut + long + 5000)
      opts <- ""
      version <- version_a(debut)
      repeat {                                  # <spéc.> et [options] du frame
        if (grepl("^[ \t]*\n[ \t]*\n", reste)) break   # ligne vide : pas de titre
        reste <- sub("^\\s+", "", reste)
        if (startsWith(reste, "<")) {
          version <- exo_version_spec(sub("^<([^>]*)>.*$", "\\1", reste))
          reste <- sub("^<[^>]*>", "", reste)
        } else if (startsWith(reste, "[")) {
          o <- regmatches(reste, regexpr("^\\[[^]]*\\]", reste))
          if (length(o) == 0) break
          opts <- paste(opts, o)
          reste <- substring(reste, nchar(o) + 1)
        } else break
      }
      titre <- if (startsWith(reste, "{")) exo_accolades(reste, 1) else NA_character_
      if (!is.na(titre) && grepl("\\\\begin\\{", titre)) titre <- NA_character_   # contenu, pas un titre
      if (is.na(titre) || !nzchar(trimws(titre))) {        # sinon \frametitle{...}
        fin <- regexpr("\\\\end\\{frame\\}", reste)[1]
        p <- regexpr("\\\\frametitle\\s*\\{", reste)
        titre <- if (p > 0 && (fin < 0 || p < fin))
          exo_accolades(reste, p + attr(p, "match.length") - 1) else ""
      }
      if (grepl("noframenumbering", opts)) next
      type <- "frame"
    }
    titres <- c(titres, ifelse(is.na(titre), "", titre))
    types <- c(types, type)
    versions <- c(versions, version)
  }
  titres <- trimws(gsub("\\s+", " ", titres))
  sections <- titres
  sections[types != "section"] <- NA
  if (length(sections) > 0 && is.na(sections[1])) sections[1] <- ""
  for (i in seq_along(sections)) if (is.na(sections[i])) sections[i] <- sections[i - 1]
  data.frame(
    pres = ifelse(versions == "imprimable", NA, cumsum(versions != "imprimable")),
    impr = ifelse(versions == "presentation", NA, cumsum(versions != "presentation")),
    titre = titres, type = types, section = sections, stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------
# Modules (fichiers de diapos), dans l'ordre d'enseignement
# ---------------------------------------------------------------------------

# Code d'un module = numéro dans le nom du fichier (« 3 », « 8.1 »). Si deux
# fichiers portent le même numéro (« Module 9 - ..., partie 1 » et « partie 2 »),
# ils reçoivent les codes 9.1, 9.2 dans l'ordre alphabétique.
exo_modules <- function(dossier = "diapos") {
  fichiers <- sort(list.files(dossier, pattern = "^Module [0-9]+(\\.[0-9]+)? - .*\\.tex$"))
  if (length(fichiers) == 0) return(NULL)
  base <- sub("\\.tex$", "", fichiers)
  numero <- sub("^Module ([0-9]+(\\.[0-9]+)?) - .*$", "\\1", base)
  d <- data.frame(base = base, numero = numero,
                  titre = sub("^Module [0-9]+(\\.[0-9]+)? - (.*)$", "\\2", base),
                  stringsAsFactors = FALSE)
  d <- d[order(as.numeric(d$numero), d$base), ]
  d$code <- d$numero
  for (n in unique(d$numero[duplicated(d$numero)])) {
    k <- which(d$numero == n)
    d$code[k] <- paste0(n, ".", seq_along(k))
  }
  d$ordre <- seq_len(nrow(d))
  d$diapos <- lapply(file.path(dossier, fichiers[match(d$base, sub("\\.tex$", "", fichiers))]),
                     exo_diapos_module)
  rownames(d) <- NULL
  d
}

# ---------------------------------------------------------------------------
# Mise en forme
# ---------------------------------------------------------------------------

# Échappement HTML
exo_html <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub("\"", "&quot;", x, fixed = TRUE)
}

# Titre de diapo LaTeX -> texte lisible (formules simples en Unicode)
exo_titre_affiche <- function(t) {
  if (is.na(t) || !nzchar(t)) return("")
  t <- diapos_nettoyer(t)
  t <- gsub("\\\\mathcal\\{N\\}", "N", t)
  t <- gsub("\\\\(overline|bar)\\{([A-Za-z])\\}", "\\2\u0304", t)
  grec <- c(alpha = "\u03b1", beta = "\u03b2", chi = "\u03c7", delta = "\u03b4",
            epsilon = "\u03b5", lambda = "\u03bb", mu = "\u03bc", nu = "\u03bd",
            pi = "\u03c0", rho = "\u03c1", sigma = "\u03c3", theta = "\u03b8",
            Sigma = "\u03a3", Delta = "\u0394")
  for (g in names(grec)) t <- gsub(paste0("\\\\", g, "(?![A-Za-z])"), grec[[g]], t, perl = TRUE)
  t <- gsub("\\^\\{?2\\}?", "\u00b2", t)
  t <- gsub("_\\{?([0-9])\\}?", "\\1", t)
  t <- gsub("\\\\\\\\", " ", t)                       # \\ (saut de ligne)
  t <- gsub("\\\\(it|bf|rm|small|footnotesize|large|Large)\\b\\s*", "", t, perl = TRUE)
  t <- gsub("\\\\[A-Za-z]+\\s*", "", t)     # autres commandes
  t <- gsub("[{}$]", "", t)
  trimws(gsub("\\s+", " ", t))
}

# Comparaison de titres insensible aux espaces
exo_titre_cle <- function(t) gsub("\\s+", "", ifelse(is.na(t), "", t))

# Étiquette d'un exercice : « 4.3 » ou « 4.3 (a, b) »
exo_etiquette <- function(exercice, parties) {
  p <- gsub("\\(([^)]*)\\)", "-\\1", parties)
  ifelse(nzchar(p), sprintf("%s (%s)", exercice, p), exercice)
}

# Clé de tri numérique d'un exercice « 12.4 »
exo_tri <- function(exercice) {
  ch <- as.numeric(sub("\\..*$", "", exercice))
  no <- as.numeric(sub("^[^.]*\\.", "", exercice))
  ch * 1000 + no
}

# Date ISO -> « 20 octobre 2026 »
exo_date <- function(d) {
  mois <- c("janvier", "février", "mars", "avril", "mai", "juin", "juillet",
            "août", "septembre", "octobre", "novembre", "décembre")
  d <- as.Date(d)
  j <- as.integer(format(d, "%d"))
  sprintf("%s %s %s", ifelse(j == 1, "1er", as.character(j)),
          mois[as.integer(format(d, "%m"))], format(d, "%Y"))
}

# ---------------------------------------------------------------------------
# Lecture des données
# ---------------------------------------------------------------------------

# Fichier TSV : les lignes qui commencent par # sont des commentaires ; un #
# ailleurs dans une ligne (par exemple dans un titre de diapo) est conservé.
exo_lire_tsv <- function(fichier, colonnes) {
  lignes <- readLines(fichier, warn = FALSE, encoding = "UTF-8")
  lignes <- lignes[!grepl("^\\s*#", lignes) & nzchar(trimws(lignes))]
  if (length(lignes) == 0) stop(fichier, " : fichier vide (il manque la ligne d'en-tête)")
  n <- lengths(strsplit(paste0(lignes, "\tx"), "\t", fixed = TRUE)) - 1
  if (any(n[-1] > n[1]))
    stop(fichier, " : une ligne a plus de colonnes que l'en-tête (", n[1],
         ") ; vérifier les tabulations de la ligne de données no ", which(n[-1] > n[1])[1])
  d <- utils::read.delim(text = lignes, colClasses = "character", quote = "", comment.char = "",
                         row.names = NULL, fill = TRUE, na.strings = character(),
                         encoding = "UTF-8", strip.white = TRUE)
  manquantes <- setdiff(colonnes, names(d))
  if (length(manquantes) > 0)
    stop(fichier, " : colonne(s) manquante(s) : ", paste(manquantes, collapse = ", "))
  d
}

# Retrouve la diapo d'un exercice dans la version actuelle du module :
# la diapo enregistrée si son titre n'a pas changé, sinon la diapo de même
# titre la plus proche (une diapo a été ajoutée ou retirée plus haut).
exo_resoudre <- function(diapo, titre, diapos, contexte) {
  pres <- diapos[!is.na(diapos$pres), ]
  n <- nrow(pres)
  if (!nzchar(titre)) return(min(diapo, n))
  cles <- exo_titre_cle(pres$titre)
  cle <- exo_titre_cle(titre)
  if (diapo >= 1 && diapo <= n && cles[diapo] == cle) return(diapo)
  cand <- which(cles == cle)
  if (length(cand) > 0) {
    nouveau <- cand[which.min(abs(cand - diapo))]
    exo_signaler(sprintf("%s : diapo %d -> %d (titre « %s »)", contexte, diapo, nouveau, titre))
    return(nouveau)
  }
  exo_signaler(sprintf("ATTENTION %s : aucune diapo intitulée « %s » ; diapo %d conservée",
                       contexte, titre, diapo))
  min(diapo, n)
}

# Correspondance exercices -> (module, diapo), résolue sur les diapos actuelles
exo_correspondance <- function(modules, fichier = "exercices/correspondance.tsv") {
  d <- exo_lire_tsv(fichier, c("exercice", "parties", "sujet", "module", "diapo", "titre"))
  if (is.null(d$note)) d$note <- ""
  d$hors <- d$module == "hors"
  d$ordre <- match(d$module, modules$code)
  inconnus <- !d$hors & is.na(d$ordre)
  if (any(inconnus)) {
    exo_signaler(sprintf("ATTENTION module inconnu pour %s : %s (lignes ignorées)",
                         paste(d$exercice[inconnus], collapse = ", "),
                         paste(unique(d$module[inconnus]), collapse = ", ")))
    d <- d[!inconnus, ]
  }
  d$diapo_actuelle <- NA_integer_
  for (i in which(!d$hors)) {
    m <- d$ordre[i]
    d$diapo_actuelle[i] <- exo_resoudre(as.integer(d$diapo[i]), d$titre[i], modules$diapos[[m]],
                                        sprintf("exercice %s, module %s", exo_etiquette(d$exercice[i], d$parties[i]), d$module[i]))
  }
  d$etiquette <- exo_etiquette(d$exercice, d$parties)
  d$tri <- exo_tri(d$exercice)
  d$chapitre <- sub("\\..*$", "", d$exercice)
  d
}

# Avancement en classe : date, module, diapo (« fin » = tout le module), remarque
exo_avancement <- function(modules, fichier = "exercices/avancement.tsv") {
  if (!file.exists(fichier)) return(NULL)
  a <- exo_lire_tsv(fichier, c("date", "module", "diapo"))
  if (nrow(a) == 0) return(NULL)
  if (is.null(a$remarque)) a$remarque <- ""
  a$ordre <- match(a$module, modules$code)
  if (any(is.na(a$ordre))) {
    exo_signaler("ATTENTION avancement.tsv : module inconnu ignoré :",
                 paste(a$module[is.na(a$ordre)], collapse = ", "))
    a <- a[!is.na(a$ordre), ]
  }
  if (nrow(a) == 0) return(NULL)
  n <- vapply(a$ordre, function(m) sum(!is.na(modules$diapos[[m]]$pres)), 0)
  a$diapo <- ifelse(tolower(a$diapo) == "fin", n, pmin(suppressWarnings(as.integer(a$diapo)), n))
  a <- a[!is.na(a$diapo), ]
  a[order(as.Date(a$date), a$ordre, a$diapo), ]
}

# Exercices faisables à un point (ordre du module, diapo)
exo_faisables <- function(d, ordre, diapo) {
  !d$hors & (d$ordre < ordre | (d$ordre == ordre & d$diapo_actuelle <= diapo))
}

# Liste HTML compacte d'exercices regroupés par chapitre du manuel. Un exercice
# dont toutes les sous-questions sont faisables est affiché sans parties.
exo_liste_html <- function(d, faisable, nouveau = rep(FALSE, nrow(d))) {
  if (!any(faisable)) return("<p class=\"exo-vide\">Aucun exercice pour l'instant.</p>")
  lignes <- character()
  for (ch in unique(d$chapitre[order(d$tri)])) {
    items <- character()
    sel <- d[d$chapitre == ch, , drop = FALSE]
    f <- faisable[d$chapitre == ch]
    nv <- nouveau[d$chapitre == ch]
    for (ex in unique(sel$exercice[order(sel$tri)])) {
      k <- sel$exercice == ex
      if (!any(f[k])) next
      tout <- all(f[k]) && !any(sel$hors[k])
      parts <- sort(trimws(unlist(strsplit(sel$parties[k & f], ","))))
      lib <- if (tout) ex else exo_etiquette(ex, paste(parts, collapse = ", "))
      sujet <- sel$sujet[k][1]
      classe <- if (any(nv[k] & f[k])) " class=\"exo-nouveau\"" else ""
      items <- c(items, sprintf("<li%s title=\"%s\">%s</li>", classe, exo_html(sujet), exo_html(lib)))
    }
    if (length(items) > 0)
      lignes <- c(lignes, sprintf("<div class=\"exo-chapitre\"><span class=\"exo-chapitre-titre\">Chapitre %s</span><ul class=\"exo-liste\">%s</ul></div>",
                                  ch, paste(items, collapse = "")))
  }
  paste(lignes, collapse = "\n")
}

# ---------------------------------------------------------------------------
# Page
# ---------------------------------------------------------------------------

exercices_page <- function() {
  modules <- exo_modules()
  if (is.null(modules) || !file.exists("exercices/correspondance.tsv")) {
    cat("*Aucun exercice disponible pour le moment.*\n")
    return(invisible())
  }
  d <- exo_correspondance(modules)
  a <- exo_avancement(modules)
  titres_aff <- lapply(modules$diapos, function(x) unname(vapply(x$titre[!is.na(x$pres)], exo_titre_affiche, "")))
  sections_aff <- lapply(modules$diapos, function(x) unname(vapply(x$section[!is.na(x$pres)], exo_titre_affiche, "")))
  # Diapo sans titre : on indique la section où elle se trouve
  diapo_txt <- function(m, n) {
    t <- titres_aff[[m]][n]
    s <- sections_aff[[m]][n]
    if (nzchar(t)) sprintf("diapo %d (« %s »)", n, exo_html(t))
    else if (nzchar(s)) sprintf("diapo %d (section « %s »)", n, exo_html(s))
    else sprintf("diapo %d", n)
  }
  nom_module <- function(m) sprintf("Module %s – %s", modules$numero[m], modules$titre[m])

  # --- Où en est le cours ? ---
  if (!is.null(a)) {
    der <- a[nrow(a), ]
    cat("## Où en est le cours ?\n\n")
    cat("<div class=\"quick-panel exo-avancement\">\n")
    cat(sprintf("<p>Au <strong>%s</strong>, la matière a été vue jusqu'à la <strong>%s</strong> du <strong>%s</strong>.%s</p>\n",
                exo_date(der$date), diapo_txt(der$ordre, der$diapo), exo_html(nom_module(der$ordre)),
                if (nzchar(der$remarque)) paste0(" ", exo_html(der$remarque)) else ""))
    f <- exo_faisables(d, der$ordre, der$diapo)
    prec <- if (nrow(a) > 1) exo_faisables(d, a$ordre[nrow(a) - 1], a$diapo[nrow(a) - 1]) else rep(FALSE, nrow(d))
    cat(sprintf("<p>Vous pouvez faire <strong>%d</strong> exercices (ou parties d'exercices) du manuel. Ceux qui se sont ajoutés depuis la mise à jour précédente sont en gras.</p>\n",
                sum(f)))
    cat(exo_liste_html(d, f, f & !prec), "\n</div>\n\n", sep = "")
    if (nrow(a) > 1) {
      cat("<details class=\"exo-historique\"><summary>Mises à jour précédentes</summary>\n<ul>\n")
      for (i in rev(seq_len(nrow(a) - 1) + 1)) {
        f1 <- exo_faisables(d, a$ordre[i], a$diapo[i])
        f0 <- exo_faisables(d, a$ordre[i - 1], a$diapo[i - 1])
        nouveaux <- f1 & !f0
        cat(sprintf("<li><strong>%s</strong> : jusqu'à la %s du module %s — nouveaux : %s</li>\n",
                    exo_date(a$date[i]), diapo_txt(a$ordre[i], a$diapo[i]), modules$numero[a$ordre[i]],
                    if (any(nouveaux)) exo_html(paste(d$etiquette[nouveaux][order(d$tri[nouveaux])], collapse = ", ")) else "aucun"))
      }
      cat(sprintf("<li><strong>%s</strong> : jusqu'à la %s du module %s</li>\n",
                  exo_date(a$date[1]), diapo_txt(a$ordre[1], a$diapo[1]), modules$numero[a$ordre[1]]))
      cat("</ul></details>\n\n")
    }
  }

  # --- Sélecteur interactif ---
  donnees <- list(
    modules = lapply(seq_len(nrow(modules)), function(m) list(
      code = modules$code[m], nom = nom_module(m), titres = titres_aff[[m]], sections = sections_aff[[m]])),
    exercices = lapply(which(!d$hors), function(i) list(
      e = d$exercice[i], p = d$parties[i], s = d$sujet[i], c = d$chapitre[i], t = d$tri[i],
      m = d$ordre[i], d = d$diapo_actuelle[i])),
    complets = as.list(tapply(!d$hors, d$exercice, all))
  )
  json <- jsonlite::toJSON(donnees, auto_unbox = TRUE, null = "null")
  cat("## Quels exercices puis-je faire ?\n\n")
  cat("<div class=\"exo-selecteur\">\n")
  cat("<p>Par défaut, la liste montre tous les exercices du manuel au programme du cours. Pour ne voir que ceux dont la matière a été vue, choisissez un module et indiquez la dernière diapo vue en classe (le numéro affiché au bas de la diapo) ; ceux qui portent sur le module choisi sont alors en gras.</p>\n")
  cat("<form class=\"exo-form\" onsubmit=\"return false;\">\n")
  cat("<label>Module <select id=\"exo-module\" class=\"form-select\">\n")
  cat("<option value=\"0\">Tout</option>\n")
  for (m in seq_len(nrow(modules)))
    cat(sprintf("<option value=\"%d\">%s</option>\n", m, exo_html(nom_module(m))))
  cat("</select></label>\n")
  cat("<label id=\"exo-diapo-label\">Diapo <input id=\"exo-diapo\" class=\"form-control\" type=\"number\" min=\"1\" step=\"1\" inputmode=\"numeric\"></label>\n")
  cat("</form>\n<p id=\"exo-resume\" class=\"exo-resume\" aria-live=\"polite\"></p>\n<div id=\"exo-resultat\"></div>\n</div>\n\n")
  cat("<script id=\"exo-donnees\" type=\"application/json\">", gsub("</", "<\\/", json, fixed = TRUE), "</script>\n", sep = "")
  cat(exo_script(), "\n\n")

  # --- Tableau de référence par module ---
  cat("## Exercices par module\n\n")
  cat("Pour chaque module, les exercices du manuel qui deviennent faisables une fois la diapo indiquée vue en classe (ils restent faisables pour la suite du cours).\n\n")
  ecarts <- vapply(modules$diapos, function(x) any(is.na(x$pres) | is.na(x$impr)), FALSE)
  for (m in seq_len(nrow(modules))) {
    sel <- d[!d$hors & d$ordre == m, , drop = FALSE]
    cat(sprintf("### %s\n\n", nom_module(m)))
    if (nrow(sel) == 0) {
      cat("*Aucun exercice du manuel ne s'ajoute dans ce module.*\n\n")
      next
    }
    if (ecarts[m]) {
      x <- modules$diapos[[m]]
      k <- which(is.na(x$impr))
      cat(sprintf("<p class=\"exo-note\">Dans la version imprimable de ce module, la numérotation est décalée d'une diapo à partir de la diapo %d.</p>\n\n",
                  min(x$pres[k], na.rm = TRUE) + 1))
    }
    cat("<table class=\"table exo-table\">\n<thead><tr><th>Diapo</th><th>Titre de la diapo</th><th>Exercices qui deviennent faisables</th></tr></thead>\n<tbody>\n")
    for (n in sort(unique(sel$diapo_actuelle))) {
      s <- sel[sel$diapo_actuelle == n, , drop = FALSE]
      s <- s[order(s$tri, s$parties), ]
      t <- titres_aff[[m]][n]
      t <- if (nzchar(t)) exo_html(t) else if (nzchar(sections_aff[[m]][n]))
        sprintf("<em>section « %s »</em>", exo_html(sections_aff[[m]][n])) else ""
      cat(sprintf("<tr><td class=\"exo-num\">%d</td><td class=\"exo-titre\">%s</td><td>%s</td></tr>\n", n, t,
                  paste(sprintf("<span title=\"%s\">%s</span>", exo_html(s$sujet), exo_html(s$etiquette)), collapse = ", ")))
    }
    cat("</tbody>\n</table>\n\n")
  }

  # --- Hors programme ---
  h <- d[d$hors, , drop = FALSE]
  if (nrow(h) > 0) {
    h <- h[order(h$tri, h$parties), ]
    cat("<details class=\"exo-hors\"><summary>Exercices du manuel qui portent sur de la matière non vue dans ce cours</summary>\n")
    cat("<p>Ces exercices (ou parties d'exercices) demandent des notions qui ne sont pas au programme du cours.</p>\n<ul>\n")
    for (ch in unique(h$chapitre))
      cat(sprintf("<li><strong>Chapitre %s</strong> : %s</li>\n", ch,
                  paste(sprintf("<span title=\"%s\">%s</span>", exo_html(ifelse(nzchar(h$note[h$chapitre == ch]), paste0(h$sujet[h$chapitre == ch], " — ", h$note[h$chapitre == ch]), h$sujet[h$chapitre == ch])),
                                exo_html(h$etiquette[h$chapitre == ch])), collapse = ", ")))
    cat("</ul></details>\n")
  }
  invisible()
}

# Script du sélecteur (aucune dépendance externe). L'état est conservé dans
# l'adresse (#module=3&d=24), ce qui permet de partager un lien vers une liste.
exo_script <- function() {
  '<script>
(function () {
  var D = JSON.parse(document.getElementById("exo-donnees").textContent);
  var selM = document.getElementById("exo-module");
  var inD = document.getElementById("exo-diapo");
  var labD = document.getElementById("exo-diapo-label");
  var resume = document.getElementById("exo-resume");
  var sortie = document.getElementById("exo-resultat");
  function esc(s) { return String(s).replace(/[&<>"]/g, function (c) {
    return {"&": "&amp;", "<": "&lt;", ">": "&gt;", "\\"": "&quot;"}[c]; }); }
  function nbDiapos(m) { return D.modules[m - 1].titres.length; }
  function lireAdresse() {
    var h = window.location.hash.replace(/^#/, ""), r = {};
    h.split("&").forEach(function (kv) { var p = kv.split("="); if (p.length === 2) r[p[0]] = p[1]; });
    var m = NaN, code = decodeURIComponent(r.module || "");
    if (code === "tout") return {m: 0, d: 0};
    D.modules.forEach(function (x, i) { if (x.code === code) m = i + 1; });
    var d = parseInt(r.d, 10);
    return (m >= 1 && m <= D.modules.length) ? {m: m, d: d >= 1 ? d : nbDiapos(m)} : null;
  }
  function afficher(majAdresse) {
    var m = parseInt(selM.value, 10), tout = !(m >= 1), d = 0;
    labD.style.display = tout ? "none" : "";          // « Tout » : pas de diapo à choisir
    if (!tout) {
      var n = nbDiapos(m);
      inD.max = n;
      d = parseInt(inD.value, 10);
      if (!(d >= 1)) d = n;
      if (d > n) { d = n; inD.value = n; }
    }
    function dans(y) { return tout || y.m < m || (y.m === m && y.d <= d); }
    var ok = D.exercices.filter(dans);
    var parEx = {};
    D.exercices.forEach(function (x) { (parEx[x.e] = parEx[x.e] || []).push(x); });
    var vus = {}, groupes = {}, ordreCh = [];
    ok.sort(function (a, b) { return a.t - b.t; });
    ok.forEach(function (x) {
      if (vus[x.e]) return;
      vus[x.e] = true;
      var faits = parEx[x.e].filter(dans);
      var lib = (faits.length === parEx[x.e].length && D.complets[x.e]) ? x.e :
        x.e + " (" + [].concat.apply([], faits.map(function (y) { return y.p.split(/,\\s*/); }))
          .filter(function (q) { return q; }).sort(function (a, b) { return a.localeCompare(b); })
          .map(function (q) { return q.replace(/\\(([^)]*)\\)/g, "-$1"); }).join(", ") + ")";
      var nouveau = !tout && faits.some(function (y) { return y.m === m; });
      if (!groupes[x.c]) { groupes[x.c] = []; ordreCh.push(x.c); }
      groupes[x.c].push("<li" + (nouveau ? " class=\\"exo-nouveau\\"" : "") + " title=\\"" + esc(x.s) + "\\">" + esc(lib) + "</li>");
    });
    var nb = Object.keys(vus).length, nbTxt = "<strong>" + nb + "</strong> exercice" + (nb > 1 ? "s" : "") + " du manuel";
    if (tout) {
      resume.innerHTML = "Tous les exercices au programme du cours : " + nbTxt + ".";
    } else {
      var titre = D.modules[m - 1].titres[d - 1], sect = D.modules[m - 1].sections[d - 1];
      resume.innerHTML = "Jusqu\\u2019à la diapo <strong>" + d + "</strong>" +
        (titre ? " (« " + esc(titre) + " »)" : (sect ? " (section « " + esc(sect) + " »)" : "")) +
        " du " + esc(D.modules[m - 1].nom) + " : " + nbTxt + ".";
    }
    sortie.innerHTML = ordreCh.length === 0 ? "<p class=\\"exo-vide\\">Aucun exercice pour l\\u2019instant.</p>" :
      ordreCh.map(function (c) {
        return "<div class=\\"exo-chapitre\\"><span class=\\"exo-chapitre-titre\\">Chapitre " + esc(c) +
          "</span><ul class=\\"exo-liste\\">" + groupes[c].join("") + "</ul></div>";
      }).join("");
    if (majAdresse && window.history && history.replaceState)
      history.replaceState(null, "", tout ? window.location.pathname + window.location.search :
        "#module=" + encodeURIComponent(D.modules[m - 1].code) + "&d=" + d);
  }
  // Point de départ : le lien partagé (#module=3&d=24), sinon tout
  var depart = lireAdresse() || {m: 0, d: 0};
  function placer(p) { selM.value = p.m; inD.value = p.d >= 1 ? p.d : ""; }
  placer(depart);
  selM.addEventListener("change", function () {
    var m = parseInt(selM.value, 10);
    inD.value = m >= 1 ? nbDiapos(m) : "";
    afficher(true);
  });
  inD.addEventListener("input", function () { afficher(true); });
  window.addEventListener("hashchange", function () {
    var p = lireAdresse(); if (p) { placer(p); afficher(false); }
  });
  afficher(false);
})();
</script>'
}
