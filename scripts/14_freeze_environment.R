# scripts/14_freeze_environment.R
# ------------------------------------------------------------
# 目的:
#   解析再現のための環境情報を固定化する
# 生成物:
#   - docs/sessionInfo.txt
#   - docs/package_versions.csv
#   - scripts/00_install_requirements.R（自動生成）
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(utils)
})

dir.create("docs", showWarnings = FALSE)
dir.create("scripts", showWarnings = FALSE)

# 1) sessionInfo を固定化
sink("docs/sessionInfo.txt")
cat("== R session info ==\n")
print(sessionInfo())
sink()
message("✅ Saved: docs/sessionInfo.txt")

# 2) このプロジェクトで想定する主要パッケージ（必要に応じて追加/削除OK）
required_pkgs <- c(
  # Core / IO
  "tibble","dplyr","readr","stringr","purrr","forcats",
  # GEO / stats
  "GEOquery","limma","matrixStats",
  # Annotation
  "AnnotationDbi","org.Hs.eg.db",
  # Enrichment
  "clusterProfiler","msigdbr","enrichplot",
  # Viz
  "ggplot2","ggrepel","svglite","magick","cowplot","png",
  # Volcano
  "EnhancedVolcano"
)

ip <- as.data.frame(installed.packages(), stringsAsFactors = FALSE)
col_keep <- intersect(c("Package","Version","LibPath","Priority","Built"), names(ip))
ip_small <- ip[ip$Package %in% required_pkgs, col_keep, drop = FALSE]
ip_small <- ip_small[order(ip_small$Package), ]
utils::write.csv(ip_small, file = "docs/package_versions.csv", row.names = FALSE)
message("✅ Saved: docs/package_versions.csv")

# 3) 再現用のインストーラスクリプトを自動生成
install_lines <- c(
  '## scripts/00_install_requirements.R',
  '## 自動生成: 必要パッケージのインストール（Bioc含む）',
  '## 実行方法: source("scripts/00_install_requirements.R")',
  '',
  'use_bioc <- function() {',
  '  if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager");',
  '  TRUE',
  '}',
  '',
  'cran_pkgs <- c(',
  '  "tibble","dplyr","readr","stringr","purrr","forcats",',
  '  "ggplot2","ggrepel","svglite","magick","cowplot","png",',
  '  "EnhancedVolcano"',
  ')',
  'bioc_pkgs <- c(',
  '  "GEOquery","limma","matrixStats",',
  '  "AnnotationDbi","org.Hs.eg.db",',
  '  "clusterProfiler","msigdbr","enrichplot"',
  ')',
  '',
  '# CRAN',
  'inst_cran <- cran_pkgs[!sapply(cran_pkgs, requireNamespace, quietly = TRUE)]',
  'if (length(inst_cran)) install.packages(inst_cran)',
  '',
  '# Bioconductor',
  'use_bioc()',
  'inst_bioc <- bioc_pkgs[!sapply(bioc_pkgs, requireNamespace, quietly = TRUE)]',
  'if (length(inst_bioc)) BiocManager::install(inst_bioc, ask = FALSE, update = TRUE)',
  '',
  'message("All set. Missing packages (if any) were installed.")',
  ''
)

writeLines(install_lines, con = "scripts/00_install_requirements.R")
message("✅ Generated: scripts/00_install_requirements.R")

message("==> Done: 14_freeze_environment")