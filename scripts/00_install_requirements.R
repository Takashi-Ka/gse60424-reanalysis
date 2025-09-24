## scripts/00_install_requirements.R
## 自動生成: 必要パッケージのインストール（Bioc含む）
## 実行方法: source("scripts/00_install_requirements.R")

use_bioc <- function() {
  if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager");
  TRUE
}

cran_pkgs <- c(
  "tibble","dplyr","readr","stringr","purrr","forcats",
  "ggplot2","ggrepel","svglite","magick","cowplot","png",
  "EnhancedVolcano"
)
bioc_pkgs <- c(
  "GEOquery","limma","matrixStats",
  "AnnotationDbi","org.Hs.eg.db",
  "clusterProfiler","msigdbr","enrichplot"
)

# CRAN
inst_cran <- cran_pkgs[!sapply(cran_pkgs, requireNamespace, quietly = TRUE)]
if (length(inst_cran)) install.packages(inst_cran)

# Bioconductor
use_bioc()
inst_bioc <- bioc_pkgs[!sapply(bioc_pkgs, requireNamespace, quietly = TRUE)]
if (length(inst_bioc)) BiocManager::install(inst_bioc, ask = FALSE, update = TRUE)

message("All set. Missing packages (if any) were installed.")

