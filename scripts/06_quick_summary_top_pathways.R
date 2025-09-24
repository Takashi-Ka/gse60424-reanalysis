# scripts/06_quick_summary_top_pathways.R
# ------------------------------------------------------------
# Step05 の結果から、padj<0.05 のパスウェイを
# GO/KEGG/Reactome(ORA) と Reactome(GSEA)ごとに抽出し
# 各 celltype で TOP10 を CSV に、全体の md/CSV も作る
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(readr); library(dplyr); library(stringr); library(purrr)
})

dir.create("results", showWarnings = FALSE)

# ユーティリティ：存在すればそのまま、ダメならスペースなし名を探す
find_file <- function(base){
  # base は "results/<Cell>_REACTOME_GSEA.csv" のような形を想定
  if (file.exists(base)) return(base)
  base2 <- gsub("Whole Blood", "WholeBlood", base, fixed = TRUE)
  if (file.exists(base2)) return(base2)
  return(NA_character_)
}

summarize_one_cell <- function(cell){
  # cell は "Monocytes" / "Neutrophils" / "Whole Blood"
  message("... summarizing: ", cell)
  
  # 読み込み対象（Step05の命名）
  files <- list(
    GO_BP_ORA      = find_file(file.path("results", sprintf("%s_GO_BP_ORA.csv", cell))),
    KEGG_ORA       = find_file(file.path("results", sprintf("%s_KEGG_ORA.csv", cell))),
    REACTOME_ORA   = find_file(file.path("results", sprintf("%s_REACTOME_ORA.csv", cell))),
    REACTOME_GSEA  = find_file(file.path("results", sprintf("%s_REACTOME_GSEA.csv", cell)))
  )
  
  read_safe <- function(path){
    if (is.na(path) || !file.exists(path)) return(NULL)
    suppressWarnings(readr::read_csv(path, show_col_types = FALSE))
  }
  
  dfs <- lapply(files, read_safe)
  
  # それぞれ padj (<-> p.adjust) 列名の違いに対応
  clean_tbl <- function(df, source){
    if (is.null(df) || nrow(df) == 0) return(NULL)
    cols <- colnames(df)
    padj_col <- if ("p.adjust" %in% cols) "p.adjust" else if ("p.adjustment" %in% cols) "p.adjustment" else if ("adj_pval" %in% cols) "adj_pval" else if ("p.adj" %in% cols) "p.adj" else if ("qvalue" %in% cols) "qvalue" else if ("padj" %in% cols) "padj" else NA_character_
    pval_col <- if ("pvalue" %in% cols) "pvalue" else if ("p.value" %in% cols) "p.value" else if ("P.value" %in% cols) "P.value" else NA_character_
    desc_col <- if ("Description" %in% cols) "Description" else if ("ID" %in% cols) "ID" else if ("Pathway" %in% cols) "Pathway" else colnames(df)[1]
    
    # NES があれば拾う（GSEA）
    nes_col <- if ("NES" %in% cols) "NES" else NA_character_
    id_col  <- if ("ID" %in% cols) "ID" else desc_col
    
    out <- df %>%
      mutate(
        source = source,
        Description = .data[[desc_col]],
        ID = if (!is.na(id_col)) .data[[id_col]] else NA,
        padj = if (!is.na(padj_col)) suppressWarnings(as.numeric(.data[[padj_col]])) else NA_real_,
        pval = if (!is.na(pval_col)) suppressWarnings(as.numeric(.data[[pval_col]])) else NA_real_,
        NES  = if (!is.na(nes_col)) suppressWarnings(as.numeric(.data[[nes_col]])) else NA_real_
      ) %>%
      # 欄を最小限に整形
      select(source, ID, Description, NES, pval, padj)
    out
  }
  
  tidy <- purrr::imap(dfs, clean_tbl) %>% bind_rows()
  
  if (is.null(tidy) || nrow(tidy) == 0) {
    message("   (no rows)"); return(NULL)
  }
  
  # padj < 0.05 のみ。空なら空のまま。
  tidy_sig <- tidy %>% filter(is.finite(padj), padj < 0.05)
  
  # ソースごとに TOP10（padj 昇順）
  top_by_source <- tidy_sig %>%
    group_by(source) %>%
    arrange(padj, .by_group = TRUE) %>%
    slice_head(n = 10) %>%
    ungroup() %>%
    mutate(celltype = cell, .before = 1)
  
  # 保存（Cell 別）
  out_name <- file.path("results", sprintf("%s_TopPathways_summary.csv", gsub(" ", "", cell)))
  readr::write_csv(top_by_source, out_name)
  message("   saved: ", out_name)
  
  top_by_source
}

cells <- c("Monocytes", "Neutrophils", "Whole Blood")
all_summary <- lapply(cells, summarize_one_cell) %>% bind_rows()

if (!is.null(all_summary) && nrow(all_summary) > 0) {
  # 全体 CSV
  readr::write_csv(all_summary, file.path("results", "TopPathways_summary_all.csv"))
  
  # 簡易 Markdown
  md <- "# Top Pathways Summary (padj < 0.05)\n\n"
  for (cell in cells) {
    sub <- all_summary %>% filter(celltype == cell)
    md <- paste0(md, "## ", cell, "\n\n")
    if (nrow(sub) == 0) {
      md <- paste0(md, "_No significant pathways._\n\n")
    } else {
      # 表（先頭5行だけ見出しとして）
      show <- sub %>%
        mutate(NES = ifelse(is.na(NES), "", sprintf("%.2f", NES)),
               pval = ifelse(is.na(pval), "", formatC(pval, format="e", digits=2)),
               padj = ifelse(is.na(padj), "", formatC(padj, format="e", digits=2))) %>%
        select(source, Description, NES, padj) %>%
        head(10)
      # 簡易markdown表作成
      header <- "| source | Description | NES | padj |\n|---|---|---:|---:|\n"
      rows <- apply(show, 1, function(r) paste0("| ", r["source"], " | ", r["Description"], " | ", r["NES"], " | ", r["padj"], " |"))
      md <- paste0(md, header, paste(rows, collapse = "\n"), "\n\n")
    }
  }
  writeLines(md, con = file.path("results", "TopPathways_summary.md"))
  message("saved: results/TopPathways_summary_all.csv ; results/TopPathways_summary.md")
} else {
  message("No significant pathways at padj < 0.05. CSV/MD not generated.")
}

message("==> Done: 06_quick_summary_top_pathways")