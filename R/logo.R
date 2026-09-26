# Régénère images/logo.png dans la couleur --accent définie dans styles.css.
#
# images/logo-source.png est le gabarit (silhouette) : sa forme et son canal
# alpha ne doivent jamais être modifiés. Ce script se contente d'y appliquer
# la couleur d'accent courante et d'écrire le résultat dans images/logo.png,
# le fichier réellement utilisé par le site (sidebar: logo: dans _quarto.yml).
#
# Exécuté automatiquement avant chaque rendu (project: pre-render: dans
# _quarto.yml), donc le logo reste toujours synchronisé avec --accent.

if (!requireNamespace("png", quietly = TRUE)) {
  stop("Le paquet R 'png' est requis pour générer le logo (install.packages(\"png\")).")
}

extraire_accent <- function(fichier_css = "styles.css") {
  lignes <- readLines(fichier_css, warn = FALSE)
  ligne <- grep("--accent\\s*:", lignes, value = TRUE)[1]
  if (is.na(ligne)) stop("Aucune variable --accent trouvée dans ", fichier_css)
  hex <- regmatches(ligne, regexpr("#[0-9a-fA-F]{6}", ligne))
  if (length(hex) == 0) stop("Valeur de --accent introuvable dans : ", ligne)
  hex
}

genere_logo <- function(source = "images/logo-source.png", sortie = "images/logo.png") {
  accent <- extraire_accent()
  rgb <- grDevices::col2rgb(accent) / 255

  img <- png::readPNG(source)
  img[, , 1] <- rgb[1]
  img[, , 2] <- rgb[2]
  img[, , 3] <- rgb[3]
  # Le canal alpha (4e tranche) est laissé tel quel : c'est lui qui porte la forme.

  png::writePNG(img, sortie)
  cat(sprintf("%s régénéré avec l'accent %s\n", sortie, accent))
}

genere_logo()
