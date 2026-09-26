# Liens vers les diapositives LaTeX (dossier diapos/).
#
# Les PDF sont produits par diapos/compiler.sh (voir le workflow GitHub) :
#   diapos/Module N - Titre.pdf             (présentation)
#   diapos/Module N - Titre-imprimable.pdf  (version imprimable)
# Tout nouveau fichier diapos/Module *.tex est détecté automatiquement.

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

# Page « Diapositives » : un module par section, avec ses liens PDF
diapos_page <- function() {
  infos <- diapos_infos()
  if (is.null(infos)) {
    cat("*Aucune diapositive disponible pour le moment.*\n")
    return(invisible())
  }
  infos <- infos[order(infos$module), ]
  for (i in seq_len(nrow(infos))) {
    cat(sprintf("\n## Module %s – %s {.unnumbered}\n\n", infos$numero[i], infos$titre[i]))
    cat("| Présentation | Imprimable |\n|:--:|:--:|\n")
    cat(sprintf("| %s | %s |\n", diapos_lien(infos$base[i]), diapos_lien(infos$base[i], "-imprimable")))
  }
  invisible()
}
