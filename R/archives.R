# Regroupe les diapos compilées en deux archives ZIP téléchargeables depuis
# la page Diapositives (boutons « Tout télécharger ») :
#   diapos/STT-1000-diapos-presentation.zip  (toutes les versions présentation)
#   diapos/STT-1000-diapos-imprimable.zip    (toutes les versions imprimables)
#
# Les PDF viennent de diapos/compiler.sh (voir le workflow GitHub). Une
# archive n'est produite que si au moins un PDF de la version correspondante
# existe, et elle n'est refaite que si un PDF est plus récent qu'elle.
#
# Exécuté automatiquement avant chaque rendu (project: pre-render: dans
# _quarto.yml), après R/logo.R. Nécessite l'exécutable « zip » (présent sur
# macOS et sur les machines GitHub Actions).

source("R/diapos.R")

archiver <- function(version) {
  zip_path <- diapos_archive(version)
  pdfs <- diapos_pdfs(version)
  if (length(pdfs) == 0) {
    if (file.exists(zip_path)) file.remove(zip_path)
    cat(sprintf("%s : aucun PDF, archive non produite\n", zip_path))
    return(invisible())
  }
  if (file.exists(zip_path) && file.mtime(zip_path) >= max(file.mtime(pdfs))) {
    cat(sprintf("%s déjà à jour (%d PDF)\n", zip_path, length(pdfs)))
    return(invisible())
  }
  if (file.exists(zip_path)) file.remove(zip_path)
  # -j : pas de dossier dans l'archive ; -X : pas d'attributs système ; -q : silencieux
  statut <- utils::zip(zip_path, pdfs, flags = "-jXq")
  if (statut != 0) stop("Échec de la création de ", zip_path, " (code ", statut, ")")
  cat(sprintf("%s produit (%d PDF)\n", zip_path, length(pdfs)))
}

archiver("presentation")
archiver("imprimable")
