# Liens vers les diapositives LaTeX (dossier diapos/).
#
# Les PDF sont produits par diapos/compiler.sh (voir le workflow GitHub) :
#   diapos/Module N - Titre.pdf             (présentation)
#   diapos/Module N - Titre-imprimable.pdf  (version imprimable)
# Tout nouveau fichier diapos/Module *.tex est détecté automatiquement.
#
# Les archives ZIP « Tout télécharger » (une par version) sont produites par
# R/archives.R avant chaque rendu, à partir des mêmes PDF.

diapos_cours <- "STT-1000"   # préfixe des archives ZIP

# PDF compilés d'une version : "presentation" ou "imprimable"
diapos_pdfs <- function(version = c("presentation", "imprimable"), dossier = "diapos") {
  version <- match.arg(version)
  motif <- if (version == "imprimable") "^Module .*-imprimable\\.pdf$" else "^Module .*\\.pdf$"
  pdfs <- list.files(dossier, pattern = motif, full.names = TRUE)
  if (version == "presentation") pdfs <- pdfs[!grepl("-imprimable\\.pdf$", pdfs)]
  sort(pdfs)
}

# Chemin de l'archive ZIP d'une version
diapos_archive <- function(version = c("presentation", "imprimable"), dossier = "diapos") {
  version <- match.arg(version)
  file.path(dossier, sprintf("%s-diapos-%s.zip", diapos_cours, version))
}

# Nettoie un titre LaTeX pour l'afficher en Markdown
diapos_nettoyer <- function(t) {
  t <- gsub("\\\\texorpdfstring\\{([^}]*)\\}\\{[^}]*\\}", "\\1", t)
  t <- gsub("\\\\textsuperscript\\{([^}]*)\\}", "\\1", t)
  t <- gsub("\\\\(emph|textbf|textit)\\{([^}]*)\\}", "\\2", t)
  t <- gsub("--", "–", t, fixed = TRUE)
  t <- gsub("\\s*:\\s*", " : ", t)
  trimws(t)
}

# Tableau des diapos : fichier, numéro de module, titre, sections
diapos_infos <- function(dossier = "diapos") {
  fichiers <- sort(list.files(dossier, pattern = "^Module [0-9]+(\\.[0-9]+)? - .*\\.tex$"))
  if (length(fichiers) == 0) return(NULL)
  lignes_de <- function(f) readLines(file.path(dossier, f), warn = FALSE, encoding = "UTF-8")
  sections <- function(lignes) {
    s <- grep("^\\\\section", lignes, value = TRUE)
    s <- sub("\\\\label\\{[^}]*\\}\\s*$", "", s)         # retire un \label{...} en fin de ligne
    # \section[court]{long} ou \section{long} : on garde le titre long
    s <- sub("^\\\\section(\\[[^]]*\\])?\\{(.*)\\}\\s*(%.*)?$", "\\2", s)
    s <- sub("^[0-9.]+\\s+", "", s)                   # retire « 2.1 »
    s <- diapos_nettoyer(s)
    s[!grepl("^(Introduction|Synthèse|Quiz)", s)]    # sections sans contenu propre
  }
  base <- sub("\\.tex$", "", fichiers)
  data.frame(
    base    = base,
    module  = as.numeric(sub("^Module ([0-9]+(\\.[0-9]+)?) - .*$", "\\1", base)),
    numero  = sub("^Module ([0-9]+(\\.[0-9]+)?) - .*$", "\\1", base),
    titre   = sub("^Module [0-9]+(\\.[0-9]+)? - (.*)$", "\\2", base),
    contenu = vapply(fichiers, function(f) paste(sections(lignes_de(f)), collapse = " · "), ""),
    stringsAsFactors = FALSE
  )
}

# Lien Markdown vers un PDF s'il existe (sinon un tiret)
diapos_lien <- function(base, suffixe = "", texte = "PDF", dossier = "diapos") {
  pdf <- file.path(dossier, paste0(base, suffixe, ".pdf"))
  if (file.exists(pdf)) sprintf("[%s](%s)", texte, pdf) else "—"
}

# Bouton « Tout télécharger » d'une version, si son archive ZIP existe
diapos_bouton <- function(version, texte, classe = "") {
  zip_path <- diapos_archive(version)
  if (!file.exists(zip_path)) return(NULL)
  mo <- file.size(zip_path) / 1024^2
  taille <- if (mo < 1) "moins de 1 Mo" else sprintf("%.0f Mo", mo)
  sprintf('<a class="portal-button%s" href="%s" download>%s <small>(ZIP, %s)</small></a>',
          classe, zip_path, texte, taille)
}

# Page « Diapositives » : boutons « Tout télécharger » puis un tableau
# Module / Présentation / Imprimable
diapos_page <- function() {
  infos <- diapos_infos()
  if (is.null(infos)) {
    cat("*Aucune diapositive disponible pour le moment.*\n")
    return(invisible())
  }
  boutons <- c(
    diapos_bouton("presentation", "Tout télécharger – version présentation"),
    diapos_bouton("imprimable", "Tout télécharger – version imprimable", " secondary")
  )
  if (length(boutons) > 0) {
    cat('<p class="diapos-archives">', paste(boutons, collapse = "\n"), '</p>\n\n', sep = "\n")
  }
  infos <- infos[order(infos$module), ]
  infos$code <- diapos_codes(infos$numero)
  lect <- diapos_lectures(infos$code)
  cat("| Module | Présentation | Imprimable | Manuel |\n|:--|:--:|:--:|:--|\n")
  for (i in seq_len(nrow(infos))) {
    cat(sprintf(
      "| Module %s – %s | %s | %s | %s |\n",
      infos$numero[i], infos$titre[i],
      diapos_lien(infos$base[i]), diapos_lien(infos$base[i], "-imprimable"),
      lect$cellule[i]
    ))
  }
  # Titres complets des sections (lisibles aussi sur téléphone, sans survol)
  if (any(nzchar(lect$detail))) {
    cat("\n<details class=\"diapos-lectures\"><summary>Titres des sections du manuel, module par module</summary>\n<ul>\n")
    for (i in which(nzchar(lect$detail)))
      cat(sprintf("<li><strong>Module %s – %s</strong>%s</li>\n", infos$numero[i],
                  diapos_html(infos$titre[i]), lect$detail[i]))
    cat("</ul></details>\n")
  }
  invisible()
}

# ---------------------------------------------------------------------------
# Lectures dans le manuel (colonne « Manuel »)
#   manuel/sections.tsv : numéros et titres des chapitres et sections du livre
#   manuel/lectures.tsv : sections à lire pour chaque module (« 6.1-6.3, 9.1.1 »)
# ---------------------------------------------------------------------------

# Échappement HTML
diapos_html <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub("|", "&#124;", x, fixed = TRUE)   # pas de | dans une cellule de tableau
  gsub("\"", "&quot;", x, fixed = TRUE)
}

# Code d'un module, comme dans exercices/avancement.tsv : le numéro du fichier
# (« 3 », « 8.1 ») ; deux fichiers de même numéro deviennent N.1, N.2.
# `numeros` doit être dans l'ordre d'enseignement.
diapos_codes <- function(numeros) {
  code <- numeros
  for (n in unique(numeros[duplicated(numeros)])) {
    k <- which(numeros == n)
    code[k] <- paste0(n, ".", seq_along(k))
  }
  code
}

# Fichier TSV ; les lignes qui commencent par # sont des commentaires
diapos_lire_tsv <- function(fichier) {
  if (!file.exists(fichier)) return(NULL)
  l <- readLines(fichier, warn = FALSE, encoding = "UTF-8")
  l <- l[!grepl("^\\s*#", l) & nzchar(trimws(l))]
  if (length(l) < 2) return(NULL)
  utils::read.delim(text = l, colClasses = "character", quote = "", comment.char = "",
                    na.strings = character(), strip.white = TRUE, fill = TRUE)
}

# Profondeur d'un numéro de section : « 6 » -> 0, « 6.2 » -> 1, « 6.2.1 » -> 2
diapos_profondeur <- function(n) nchar(gsub("[^.]", "", n))

# « 6.1-6.3, 9.1.1 » -> c("6.1", "6.2", "6.3", "9.1.1") selon l'ordre du livre
diapos_developper <- function(spec, sections) {
  items <- trimws(strsplit(spec, ",")[[1]])
  items <- items[nzchar(items)]
  out <- character()
  for (it in items) {
    if (grepl("-", it)) {
      ab <- trimws(strsplit(it, "-")[[1]])
      i <- match(ab[1], sections$numero)
      j <- match(ab[2], sections$numero)
      if (length(ab) != 2 || is.na(i) || is.na(j) || j < i) {
        cat("[lectures] intervalle non reconnu dans manuel/lectures.tsv :", it, "\n", file = stderr())
        out <- c(out, ab)
        next
      }
      cand <- sections$numero[i:j]
      out <- c(out, cand[diapos_profondeur(cand) == diapos_profondeur(ab[1])])
    } else {
      out <- c(out, it)
    }
  }
  out
}

# Pour chaque module (codes dans l'ordre du tableau) : contenu de la cellule
# « Manuel » (compact, titres au survol) et détail avec les titres complets
diapos_lectures <- function(codes, fichier = "manuel/lectures.tsv", fichier_sections = "manuel/sections.tsv") {
  vide <- data.frame(cellule = rep("", length(codes)), detail = rep("", length(codes)),
                     stringsAsFactors = FALSE)
  lect <- diapos_lire_tsv(fichier)
  sections <- diapos_lire_tsv(fichier_sections)
  if (is.null(lect) || is.null(sections)) return(vide)
  titre_de <- function(n) {
    t <- sections$titre[match(n, sections$numero)]
    ifelse(is.na(t), "", t)
  }
  inconnus <- setdiff(lect$module, codes)
  if (length(inconnus) > 0)
    cat("[lectures] module(s) inconnu(s) dans manuel/lectures.tsv :", paste(inconnus, collapse = ", "), "\n", file = stderr())
  res <- vide
  for (i in seq_along(codes)) {
    spec <- lect$sections[match(codes[i], lect$module)]
    if (is.na(spec) || !nzchar(trimws(spec))) { res$cellule[i] <- "—"; next }
    items <- trimws(strsplit(spec, ",")[[1]])
    items <- items[nzchar(items)]
    chap_item <- sub("\\..*$", "", items)
    tout <- diapos_developper(spec, sections)
    inconnues <- setdiff(tout, sections$numero)
    if (length(inconnues) > 0)
      cat("[lectures] section(s) absente(s) de manuel/sections.tsv :", paste(inconnues, collapse = ", "), "\n", file = stderr())
    chap_tout <- sub("\\..*$", "", tout)
    cell <- character(); det <- character()
    for (ch in unique(chap_item)) {
      lib <- paste(sprintf("<span class=\"diapos-item\">%s</span>", gsub("-", "–", items[chap_item == ch])),
                   collapse = ", ")
      secs <- tout[chap_tout == ch]
      titres <- paste(secs, titre_de(secs))
      bulle <- paste(c(sprintf("Chapitre %s : %s", ch, titre_de(ch)), titres), collapse = "&#10;")
      cell <- c(cell, sprintf("<span class=\"diapos-manuel\" title=\"%s\">Chap. %s : %s</span>",
                              gsub("&amp;#10;", "&#10;", diapos_html(bulle)), ch, lib))
      det <- c(det, sprintf("<li>Chapitre %s – %s<ul>%s</ul></li>", ch, diapos_html(titre_de(ch)),
                            paste(sprintf("<li>%s</li>", diapos_html(titres)), collapse = "")))
    }
    res$cellule[i] <- paste(cell, collapse = "<br>")
    res$detail[i] <- sprintf("<ul>%s</ul>", paste(det, collapse = ""))
  }
  res
}
