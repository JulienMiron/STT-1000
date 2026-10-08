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
  cat("| Module | Présentation | Imprimable |\n|:--|:--:|:--:|\n")
  for (i in seq_len(nrow(infos))) {
    cat(sprintf(
      "| Module %s – %s | %s | %s |\n",
      infos$numero[i], infos$titre[i],
      diapos_lien(infos$base[i]), diapos_lien(infos$base[i], "-imprimable")
    ))
  }
  invisible()
}
