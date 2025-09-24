# scripts/07_figures_publication.R
# ------------------------------------------------------------
# 目的：
#  - Step05 のCSVから有意（padj<0.05）の上位経路 Top10 を dotplot で保存
#  - Monocytes(Reactome ORA), Whole Blood(GO BP ORA) を優先的に図化
#  - 有意パスウェイ本数の要約図（celltype x source）も作成
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(readr); library(dplyr); library(stringr)
  library(ggplot2); library(forcats)
})

dir.create("figures", showWarnings = FALSE)

# 便利関数：あれば読む
read_if_exists <- function(path) {
  if (file.exists(path)) suppressWarnings(readr::read_csv(path, show_col_types = FALSE)) else NULL
}

# ====== 1) Monocytes: Reactome ORA Top10 ======
mono_react <- read_if_exists("results/Monocytes_REACTOME_ORA.csv")
if (!is.null(mono_react) && nrow(mono_react) > 0) {
  # 列名の標準化
  df <- mono_react %>%
    mutate(
      padj = coalesce(!!(if ("p.adjust" %in% names(.)) sym("p.adjust") else sym("padj")), NA_real_),
      Description = coalesce(!!(if ("Description" %in% names(.)) sym("Description") else sym("ID")), NA_character_),
      Count = coalesce(!!(if ("Count" %in% names(.)) sym("Count") else sym("GeneRatio")), NA)
    ) %>%
    filter(is.finite(padj)) %>%
    arrange(padj) %>%
    slice_head(n = 10)
  
  # 説明の整形（接頭辞削除・短縮）
  df$Description <- df$Description |>
    str_remove("^REACTOME_") |>
    str_replace_all("_", " ") |>
    str_to_sentence()
  
  p1 <- ggplot(df, aes(x = -log10(padj), y = fct_reorder(Description, padj, .desc = TRUE))) +
    geom_point(aes(size = Count)) +
    scale_size_continuous(name = "Count") +
    labs(title = "Monocytes — Reactome (ORA) Top 10",
         x = "-log10(adjusted p-value)", y = NULL) +
    theme_bw(base_size = 13) +
    theme(panel.grid.minor = element_blank())
  ggsave("figures/Monocytes_REACTOME_ORA_Top10_dotplot.png", p1, width = 8, height = 6, dpi = 300)
  message("saved: figures/Monocytes_REACTOME_ORA_Top10_dotplot.png")
} else {
  message("Monocytes Reactome ORA: no rows or file missing.")
}

# ====== 2) Whole Blood: GO BP ORA Top10 ======
wb_go <- read_if_exists("results/Whole Blood_GO_BP_ORA.csv")
if (is.null(wb_go)) wb_go <- read_if_exists("results/WholeBlood_GO_BP_ORA.csv")  # スペース無し対応

if (!is.null(wb_go) && nrow(wb_go) > 0) {
  df2 <- wb_go %>%
    mutate(
      padj = coalesce(!!(if ("p.adjust" %in% names(.)) sym("p.adjust") else sym("padj")), NA_real_),
      Description = coalesce(!!(if ("Description" %in% names(.)) sym("Description") else sym("ID")), NA_character_),
      Count = coalesce(!!(if ("Count" %in% names(.)) sym("Count") else sym("GeneRatio")), NA)
    ) %>%
    filter(is.finite(padj)) %>%
    arrange(padj) %>%
    slice_head(n = 10)
  
  df2$Description <- df2$Description |>
    str_to_sentence()
  
  p2 <- ggplot(df2, aes(x = -log10(padj), y = fct_reorder(Description, padj, .desc = TRUE))) +
    geom_point(aes(size = Count)) +
    scale_size_continuous(name = "Count") +
    labs(title = "Whole Blood — GO BP (ORA) Top 10",
         x = "-log10(adjusted p-value)", y = NULL) +
    theme_bw(base_size = 13) +
    theme(panel.grid.minor = element_blank())
  ggsave("figures/WholeBlood_GO_BP_ORA_Top10_dotplot.png", p2, width = 8, height = 6, dpi = 300)
  message("saved: figures/WholeBlood_GO_BP_ORA_Top10_dotplot.png")
} else {
  message("Whole Blood GO BP ORA: no rows or file missing.")
}

# ====== 3) 有意パスウェイ本数の要約（celltype x source） ======
# 利用するファイル候補
files <- list(
  Monocytes_GO    = "results/Monocytes_GO_BP_ORA.csv",
  Monocytes_KEGG  = "results/Monocytes_KEGG_ORA.csv",
  Monocytes_REACT = "results/Monocytes_REACTOME_ORA.csv",
  WB_GO    = "results/Whole Blood_GO_BP_ORA.csv",
  WB_GO2   = "results/WholeBlood_GO_BP_ORA.csv",
  WB_KEGG  = "results/Whole Blood_KEGG_ORA.csv",
  WB_KEGG2 = "results/WholeBlood_KEGG_ORA.csv",
  WB_REACT = "results/Whole Blood_REACTOME_ORA.csv",
  WB_REACT2= "results/WholeBlood_REACTOME_ORA.csv",
  Neu_GO   = "results/Neutrophils_GO_BP_ORA.csv",
  Neu_KEGG = "results/Neutrophils_KEGG_ORA.csv",
  Neu_REACT= "results/Neutrophils_REACTOME_ORA.csv"
)

read_tag <- function(path, cell, source){
  if (!file.exists(path)) return(NULL)
  df <- suppressWarnings(readr::read_csv(path, show_col_types = FALSE))
  if (nrow(df) == 0) return(NULL)
  padj_col <- intersect(c("p.adjust","padj","qvalue","p.adj"), names(df))
  if (length(padj_col) == 0) return(NULL)
  tibble(celltype = cell, source = source,
         n_sig = sum(suppressWarnings(as.numeric(df[[padj_col[1]]])) < 0.05, na.rm = TRUE))
}

counts <- bind_rows(
  read_tag(files$Monocytes_GO,    "Monocytes","GO BP ORA"),
  read_tag(files$Monocytes_KEGG,  "Monocytes","KEGG ORA"),
  read_tag(files$Monocytes_REACT, "Monocytes","Reactome ORA"),
  read_tag(files$WB_GO,           "Whole Blood","GO BP ORA"),
  read_tag(files$WB_GO2,          "Whole Blood","GO BP ORA"),
  read_tag(files$WB_KEGG,         "Whole Blood","KEGG ORA"),
  read_tag(files$WB_KEGG2,        "Whole Blood","KEGG ORA"),
  read_tag(files$WB_REACT,        "Whole Blood","Reactome ORA"),
  read_tag(files$WB_REACT2,       "Whole Blood","Reactome ORA"),
  read_tag(files$Neu_GO,          "Neutrophils","GO BP ORA"),
  read_tag(files$Neu_KEGG,        "Neutrophils","KEGG ORA"),
  read_tag(files$Neu_REACT,       "Neutrophils","Reactome ORA")
) %>% group_by(celltype, source) %>% summarise(n_sig = sum(n_sig), .groups = "drop")

if (!is.null(counts) && nrow(counts) > 0) {
  p3 <- ggplot(counts, aes(x = source, y = n_sig, fill = celltype)) +
    geom_col(position = position_dodge(width = 0.7), width = 0.6) +
    labs(x = NULL, y = "Number of significant pathways (padj < 0.05)",
         title = "Significant pathways by source and cell type") +
    theme_bw(base_size = 12) +
    theme(panel.grid.minor = element_blank(), axis.text.x = element_text(angle=20, hjust=1))
  ggsave("figures/TopPathways_counts_by_source.png", p3, width = 9, height = 5, dpi = 300)
  message("saved: figures/TopPathways_counts_by_source.png")
}

# ====== 4) パネル図（Monocytes + Whole Blood） ======
# patchwork があれば横並び保存（任意）
if (requireNamespace("patchwork", quietly = TRUE) &&
    file.exists("figures/Monocytes_REACTOME_ORA_Top10_dotplot.png") &&
    file.exists("figures/WholeBlood_GO_BP_ORA_Top10_dotplot.png")) {
  
  p1 <- magick::image_read("figures/Monocytes_REACTOME_ORA_Top10_dotplot.png")
  p2 <- magick::image_read("figures/WholeBlood_GO_BP_ORA_Top10_dotplot.png")
  # 画像を横に並べる（magickで合成）
  combo <- magick::image_append(c(p1, p2))
  magick::image_write(combo, "figures/Monocytes_WholeBlood_panel.png")
  message("saved: figures/Monocytes_WholeBlood_panel.png")
} else {
  message("panel skipped (patchwork/magick not available or source images missing).")
}

message("==> Done: 07_figures_publication")