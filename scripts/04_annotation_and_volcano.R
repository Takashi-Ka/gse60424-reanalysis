# scripts/04_annotation_and_volcano.R
# ------------------------------------------------------------
# 目的：
#  - Ensembl → SYMBOL/ENTREZ のアノテーション付与
#  - 各celltypeのVolcano Plotを自動保存
# 出力：
#  - data/processed/DE_results_annotated.rds
#  - results/*_DEG_annot.csv
#  - figures/*_volcano.png
# ------------------------------------------------------------

message("==> Step 04: Annotate IDs and export Volcano plots")

suppressPackageStartupMessages({
  library(org.Hs.eg.db)
  library(tibble)
  library(dplyr)
  library(ggplot2)
  library(ggrepel)
})

in_rds <- "data/processed/DE_results.rds"
stopifnot(file.exists(in_rds))
res <- readRDS(in_rds)

dir.create("data/processed", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

annot_one <- function(tt){
  tt$SYMBOL   <- AnnotationDbi::mapIds(org.Hs.eg.db, keys = tt$ensembl,
                                       column = "SYMBOL", keytype = "ENSEMBL", multiVals = "first")
  tt$ENTREZID <- AnnotationDbi::mapIds(org.Hs.eg.db, keys = tt$ensembl,
                                       column = "ENTREZID", keytype = "ENSEMBL", multiVals = "first")
  # 補助列
  tt$negLog10P <- -log10(tt$P.Value)
  tt$padj <- tt$adj.P.Val
  tt
}

plot_volcano <- function(tt, title, out_png,
                         fc_thresh = 1.0, padj_thresh = 0.05,
                         top_n_labels = 15){
  if (nrow(tt) == 0) {
    warning("Empty table for ", title); return(invisible(NULL))
  }
  df <- tt %>% mutate(
    sig = ifelse(!is.na(padj) & padj < padj_thresh & abs(logFC) > fc_thresh, "Significant", "NS")
  )
  # ラベル候補
  lab_df <- df %>%
    filter(sig == "Significant") %>%
    arrange(desc(abs(logFC))) %>%
    head(top_n_labels)
  
  p <- ggplot(df, aes(x = logFC, y = negLog10P)) +
    geom_point(aes(color = sig), alpha = 0.6, size = 1.3) +
    scale_color_manual(values = c("Significant" = "#d62728", "NS" = "grey60")) +
    geom_vline(xintercept = c(-fc_thresh, fc_thresh), linetype = "dashed", linewidth = 0.4) +
    geom_hline(yintercept = -log10( ifelse(is.na(padj_thresh), 1, padj_thresh) ), linetype = "dashed", linewidth = 0.4) +
    ggrepel::geom_text_repel(
      data = lab_df,
      aes(label = ifelse(is.na(SYMBOL), ensembl, SYMBOL)),
      size = 3, max.overlaps = 30, box.padding = 0.25, point.padding = 0.2
    ) +
    labs(title = title, x = "log2 Fold Change (Sepsis - Control)", y = "-log10(P-value)", color = "") +
    theme_bw(base_size = 12) +
    theme(legend.position = "top")
  
  ggsave(out_png, p, width = 7.5, height = 5.5, dpi = 300)
  message("... saved: ", out_png)
}

# EnhancedVolcano があればそれも用意（任意）
have_ev <- requireNamespace("EnhancedVolcano", quietly = TRUE)

volcano_ev <- function(tt, title, out_png,
                       fc_thresh = 1.0, padj_thresh = 0.05){
  if (!have_ev) return(FALSE)
  p <- EnhancedVolcano::EnhancedVolcano(
    tt,
    lab = ifelse(is.na(tt$SYMBOL), tt$ensembl, tt$SYMBOL),
    x = 'logFC', y = 'P.Value',
    pCutoff = padj_thresh, FCcutoff = fc_thresh,
    title = title, subtitle = NULL, caption = NULL,
    labSize = 3.5, pointSize = 1.2, legendPosition = 'top'
  )
  ggplot2::ggsave(out_png, plot = p, width = 7.5, height = 5.5, dpi = 300)
  message("... saved (EnhancedVolcano): ", out_png)
  TRUE
}

# ---- 実行（3 celltypes）----
out_list <- list()

# Monocytes
tt_mono <- annot_one(res$tt_mono)
write.csv(tt_mono, "results/Monocytes_DEG_annot.csv", row.names = FALSE)
if (!volcano_ev(tt_mono, "Monocytes: Sepsis vs Control", "figures/Monocytes_volcano.png")) {
  plot_volcano(tt_mono, "Monocytes: Sepsis vs Control", "figures/Monocytes_volcano.png")
}
out_list$tt_mono <- tt_mono

# Neutrophils
tt_neut <- annot_one(res$tt_neut)
write.csv(tt_neut, "results/Neutrophils_DEG_annot.csv", row.names = FALSE)
if (!volcano_ev(tt_neut, "Neutrophils: Sepsis vs Control", "figures/Neutrophils_volcano.png")) {
  plot_volcano(tt_neut, "Neutrophils: Sepsis vs Control", "figures/Neutrophils_volcano.png")
}
out_list$tt_neut <- tt_neut

# Whole Blood
tt_wb <- annot_one(res$tt_wb)
write.csv(tt_wb, "results/WholeBlood_DEG_annot.csv", row.names = FALSE)
if (!volcano_ev(tt_wb, "Whole Blood: Sepsis vs Control", "figures/WholeBlood_volcano.png")) {
  plot_volcano(tt_wb, "Whole Blood: Sepsis vs Control", "figures/WholeBlood_volcano.png")
}
out_list$tt_wb <- tt_wb

saveRDS(out_list, "data/processed/DE_results_annotated.rds")
message("==> Done: Step 04")