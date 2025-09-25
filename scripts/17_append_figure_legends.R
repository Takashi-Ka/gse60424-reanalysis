# scripts/17_append_figure_legends.R
# ------------------------------------------------------------
# 目的:
#   docs/manuscript_draft.md に Monocytes 用 Figure legends を追記/更新
#   （マーカーで囲んだ範囲のみ置換。無ければ新規追加）
# ------------------------------------------------------------
# --- make WD robust: set repo root automatically ---
this_file <- tryCatch(normalizePath(sys.frames()[[1]]$ofile, mustWork = TRUE),
                      error = function(e) NA)
if (is.na(this_file)) {
  args <- commandArgs(trailingOnly = FALSE)
  this_file <- sub("^--file=", "", args[grep("^--file=", args)])
}
script_dir <- dirname(this_file); repo_root <- normalizePath(file.path(script_dir, ".."))
setwd(repo_root)
# -------------------
md_path <- "docs/manuscript_draft.md"
if (!file.exists(md_path)) {
  stop("docs/manuscript_draft.md が見つかりません。パスをご確認ください。")
}

# 追記する本文（Monocytes・3図）。マーカーで囲って管理します。
legends_block <- paste0(
  "<!-- BEGIN: Monocytes_Figure_Legends -->\n",
  "## Figure legends\n\n",
  "**Figure 1. Volcano plot of differential expression in Monocytes (Sepsis vs Healthy Controls).**  \n",
  "Volcano plot showing differentially expressed genes (DEGs) in Monocytes between sepsis patients and healthy controls.  \n",
  "The x-axis represents log2 fold change and the y-axis represents –log10 adjusted p-value (FDR).  \n",
  "Significant DEGs (FDR < 0.05) are highlighted.\n\n",
  "**Figure 2. GO biological process enrichment in Monocytes (Sepsis vs Healthy Controls).**  \n",
  "Dot plot of enriched Gene Ontology biological process (GO BP) terms for DEGs in Monocytes.  \n",
  "Dot size reflects the number of DEGs annotated to each term, and color represents adjusted p-value.  \n",
  "Enrichment analysis was performed using clusterProfiler with all detected genes as background.\n\n",
  "**Figure 3. KEGG pathway enrichment in Monocytes (Sepsis vs Healthy Controls).**  \n",
  "Dot plot of enriched KEGG pathways for DEGs in Monocytes.  \n",
  "Top significantly enriched pathways are displayed, with dot size corresponding to the number of DEGs and color to adjusted p-value.  \n",
  "Pathway enrichment was performed using clusterProfiler with FDR < 0.05 as significance threshold.\n",
  "<!-- END: Monocytes_Figure_Legends -->\n"
)

lines <- readLines(md_path, warn = FALSE, encoding = "UTF-8")
txt    <- paste(lines, collapse = "\n")

begin_pat <- "<!-- BEGIN: Monocytes_Figure_Legends -->"
end_pat   <- "<!-- END: Monocytes_Figure_Legends -->"

has_markers <- grepl(begin_pat, txt, fixed = TRUE) && grepl(end_pat, txt, fixed = TRUE)
has_section <- grepl("^##\\s*Figure legends\\s*$", lines)

if (has_markers) {
  # 既存ブロックを置換
  new_txt <- sub(paste0(begin_pat, ".*?", end_pat),
                 legends_block,
                 txt, perl = TRUE)
  writeLines(new_txt, md_path, useBytes = TRUE)
  message("🔄 既存の Monocytes Figure legends を更新しました。")
} else {
  if (any(has_section)) {
    # 既存の「## Figure legends」があれば末尾にブロックを追記（重複回避のためマーカー併用）
    new_txt <- paste0(txt, "\n\n", legends_block)
    writeLines(new_txt, md_path, useBytes = TRUE)
    message("➕ 既存の Figure legends セクションに Monocytes 用ブロックを追記しました。")
  } else {
    # セクション自体が無ければ、文末にセクション+ブロックを新規追加
    new_txt <- paste0(txt, "\n\n", legends_block)
    writeLines(new_txt, md_path, useBytes = TRUE)
    message("🆕 Figure legends セクションを新規追加し、Monocytes 用ブロックを挿入しました。")
  }
}

invisible(TRUE)