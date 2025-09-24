# scripts/15_update_readme_runorder.R
# ------------------------------------------------------------
# 目的:
#   README.md に「実行順（再現手順）」セクションを自動で追加/更新する
# ------------------------------------------------------------

section_title <- "## 実行順（再現手順）"
section_md <- paste0(
  section_title, "\n\n",
  "1. 依存パッケージを準備  \n",
  "   ```r\n",
  "   source(\"scripts/00_install_requirements.R\")\n",
  "   ```\n\n",
  "2. 解析を順に実行  \n",
  "   ```text\n",
  "   1) scripts/01_download_data.R\n",
  "   2) scripts/02_normalize_and_filter.R\n",
  "   3) scripts/03_DE_limma_by_celltype.R\n",
  "   4) scripts/04_annotation_and_volcano.R\n",
  "   5) scripts/05_pathways_and_signatures.R\n",
  "   6) scripts/06_quick_summary_top_pathways.R\n",
  "   7) scripts/07_figures_publication.R\n",
  "   8) scripts/08_save_results_summary.R\n",
  "   9) scripts/09_update_readme_results.R\n",
  "   10) scripts/10_figures_finalize.R\n",
  "   11) scripts/11_generate_methods_limitations.R\n",
  "   12) scripts/12_freeze_sessioninfo.R\n",
  "   13) scripts/13_update_readme_links.R\n",
  "   14) scripts/14_freeze_environment.R\n",
  "   15) scripts/15_update_readme_runorder.R   # ← 本スクリプト（README更新）\n",
  "   ```\n\n",
  "3. 出力確認  \n",
  "   - results/: DE/ORA/GSEA/シグネチャ要約、Figure_Legends.md、Results_Summary.md  \n",
  "   - figures/: Volcano、Top10 dotplot、最終版 PNG/SVG/PDF、パネル図  \n",
  "   - docs/: Methods.md、Limitations.md、sessionInfo.txt、package_versions.csv\n\n",
  "**メモ**  \n",
  "- Whole Blood の出力ファイル名は、環境により `Whole Blood_*.csv` / `WholeBlood_*.csv` の両方があり得ます。本リポジトリのスクリプトは両表記を自動で拾うよう実装済みです。\n"
)

readme_path <- "README.md"
if (!file.exists(readme_path)) {
  stop("README.md が見つかりません。プロジェクト直下で実行してください。")
}

lines <- readLines(readme_path, warn = FALSE, encoding = "UTF-8")

start_idx <- grep("^##\\s*実行順（再現手順）\\s*$", lines)

if (length(start_idx) == 0) {
  cat("\n", file = readme_path, append = TRUE)
  cat(section_md, file = readme_path, append = TRUE)
  message("✅ README.md に「実行順（再現手順）」セクションを新規追加しました。")
} else {
  next_idx <- grep("^##\\s+", lines)
  next_idx <- next_idx[next_idx > start_idx[1]]
  end_idx <- if (length(next_idx) == 0) length(lines) else (min(next_idx) - 1)
  
  new_lines <- c(
    if (start_idx[1] > 1) lines[1:(start_idx[1]-1)] else character(0),
    strsplit(section_md, "\n")[[1]],
    if (end_idx < length(lines)) lines[(end_idx+1):length(lines)] else character(0)
  )
  
  writeLines(new_lines, con = readme_path, useBytes = TRUE)
  message("🔄 README.md の「実行順（再現手順）」セクションを更新しました。")
}

invisible(TRUE)