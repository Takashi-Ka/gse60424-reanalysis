# scripts/10_figures_finalize.R
# ------------------------------------------------------------
# 図版の最終仕上げ：
#  - 体裁統一（フォント/余白/凡例）
#  - SVG/PDF/PNG で保存
#  - Figure Legends を自動生成（Top3のpadjも表記）
# 対象：
#  - Monocytes: Reactome ORA
#  - Whole Blood: GO BP ORA
# 依存：
#  - ggplot2, dplyr, readr, stringr, forcats
#  - svglite（SVG出力に推奨・無ければPNG/PDFのみ）
#  - patchwork or cowplot or magick（パネル合成のいずれか）
# ------------------------------------------------------------

suppressPackageStartupMessages({
  library(ggplot2); library(dplyr); library(readr)
  library(stringr); library(forcats)
})

dir.create("figures", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)

# パラメータ
padj_thresh <- 0.05
top_n       <- 10
base_size   <- 12

# SVG対応確認
have_svglite <- requireNamespace("svglite", quietly = TRUE)

# 体裁統一テーマ
theme_pub <- function() {
  theme_bw(base_size = base_size) +
    theme(
      legend.position = "right",
      legend.title = element_text(size = base_size),
      legend.text  = element_text(size = base_size-1),
      plot.title   = element_text(face = "bold", size = base_size+2, hjust = 0),
      axis.title.x = element_text(size = base_size),
      axis.title.y = element_text(size = base_size),
      axis.text    = element_text(size = base_size-1),
      panel.grid.minor = element_blank(),
      plot.margin = margin(8, 12, 8, 12)
    )
}

# ユーティリティ：CSVを読んで列標準化
read_enrich <- function(path){
  if (!file.exists(path)) return(NULL)
  df <- suppressWarnings(read_csv(path, show_col_types = FALSE))
  if (nrow(df) == 0) return(NULL)
  cols <- names(df)
  padj_col <- dplyr::case_when(
    "p.adjust" %in% cols ~ "p.adjust",
    "padj"     %in% cols ~ "padj",
    "qvalue"   %in% cols ~ "qvalue",
    TRUE ~ NA_character_
  )
  desc_col <- if ("Description" %in% cols) "Description" else if ("ID" %in% cols) "ID" else cols[1]
  count_col <- if ("Count" %in% cols) "Count" else if ("GeneRatio" %in% cols) "GeneRatio" else NA_character_
  
  out <- df %>%
    mutate(
      padj = if (!is.na(padj_col)) suppressWarnings(as.numeric(.data[[padj_col]])) else NA_real_,
      Description = .data[[desc_col]],
      Count = if (!is.na(count_col)) suppressWarnings(as.numeric(.data[[count_col]])) else NA_real_
    ) %>%
    filter(is.finite(padj)) %>%
    arrange(padj)
  out
}

# 図保存ヘルパー
save_plot_all <- function(plot, basename_noext, width=8, height=6, dpi=300){
  ggsave(paste0("figures/", basename_noext, ".png"), plot, width=width, height=height, dpi=dpi)
  if (have_svglite) svglite::svglite(paste0("figures/", basename_noext, ".svg"), width=width, height=height); print(plot); dev.off()
  grDevices::pdf(file = paste0("figures/", basename_noext, ".pdf"), width=width, height=height); print(plot); dev.off()
  message("Saved PNG/PDF", if (have_svglite) "/SVG", ": figures/", basename_noext, ".*")
}

# ---- 1) Monocytes — Reactome ORA ----
mono <- read_enrich("results/Monocytes_REACTOME_ORA.csv")
if (!is.null(mono)) {
  df1 <- mono %>%
    filter(padj < padj_thresh) %>%
    slice_head(n = top_n) %>%
    mutate(
      # 表示名整形
      label = Description |> str_remove("^REACTOME_") |> str_replace_all("_", " ") |> str_to_sentence(),
      label = ifelse(nchar(label) > 70, paste0(strtrim(label, 67), "..."), label)
    )
  
  p1 <- ggplot(df1, aes(x = -log10(padj), y = fct_reorder(label, padj, .desc = TRUE))) +
    geom_point(aes(size = Count)) +
    scale_size_continuous(name = "Gene count", range = c(2,6)) +
    labs(
      title = "Monocytes — Reactome ORA (Top 10, padj < 0.05)",
      x = "-log10(adjusted p-value)", y = NULL
    ) +
    theme_pub()
  
  save_plot_all(p1, "Monocytes_REACTOME_ORA_Top10_dotplot_final")
} else {
  message("Monocytes Reactome ORA: file not found or empty.")
}

# ---- 2) Whole Blood — GO BP ORA ----
wb_path1 <- "results/Whole Blood_GO_BP_ORA.csv"
wb_path2 <- "results/WholeBlood_GO_BP_ORA.csv"
wb <- read_enrich(if (file.exists(wb_path1)) wb_path1 else wb_path2)
if (!is.null(wb)) {
  df2 <- wb %>%
    filter(padj < padj_thresh) %>%
    slice_head(n = top_n) %>%
    mutate(
      label = Description |> str_to_sentence(),
      label = ifelse(nchar(label) > 70, paste0(strtrim(label, 67), "..."), label)
    )
  
  p2 <- ggplot(df2, aes(x = -log10(padj), y = fct_reorder(label, padj, .desc = TRUE))) +
    geom_point(aes(size = Count)) +
    scale_size_continuous(name = "Gene count", range = c(2,6)) +
    labs(
      title = "Whole Blood — GO BP ORA (Top 10, padj < 0.05)",
      x = "-log10(adjusted p-value)", y = NULL
    ) +
    theme_pub()
  
  save_plot_all(p2, "WholeBlood_GO_BP_ORA_Top10_dotplot_final")
} else {
  message("Whole Blood GO BP ORA: file not found or empty.")
}

# ---- 3) パネル合成（ある場合のみ） ----
panel_done <- FALSE
mono_png <- "figures/Monocytes_REACTOME_ORA_Top10_dotplot_final.png"
wb_png   <- "figures/WholeBlood_GO_BP_ORA_Top10_dotplot_final.png"
if (file.exists(mono_png) && file.exists(wb_png)) {
  if (requireNamespace("magick", quietly = TRUE)) {
    p1 <- magick::image_read(mono_png); p2 <- magick::image_read(wb_png)
    combo <- magick::image_append(c(p1, p2))
    magick::image_write(combo, "figures/TopPathways_panel_final.png")
    panel_done <- TRUE
  } else if (requireNamespace("cowplot", quietly = TRUE) && requireNamespace("png", quietly = TRUE)) {
    library(png); library(cowplot)
    img1 <- ggdraw() + draw_image(mono_png)
    img2 <- ggdraw() + draw_image(wb_png)
    panel <- plot_grid(img1, img2, nrow = 1, rel_widths = c(1,1))
    ggsave("figures/TopPathways_panel_final.png", panel, width=16, height=6, dpi=300)
    panel_done <- TRUE
  }
}
if (panel_done) message("Saved: figures/TopPathways_panel_final.png") else message("Panel skipped (magick or cowplot+png not available).")

# ---- 4) Figure Legends 自動生成 ----
legend_lines <- c("# Figure Legends", "")
# Monocytes legend
if (!is.null(mono)) {
  top3 <- mono %>% filter(padj < padj_thresh) %>% slice_head(n=3) %>%
    transmute(txt = sprintf("- %s (padj = %.2e)", str_remove(Description, "^REACTOME_"), padj))
  legend_lines <- c(legend_lines,
                    "## Figure 1. Monocytes — Reactome ORA (Top 10)",
                    "Dot plot showing the top 10 enriched Reactome pathways (ORA) in Monocytes (Sepsis vs Control).",
                    sprintf("Thresholds: padj < %.2f; displayed = top %d by padj.", padj_thresh, top_n),
                    "Top hits:",
                    if (nrow(top3)>0) paste(top3$txt, collapse = "\n") else "- (none)",
                    ""
  )
}
# Whole Blood legend
if (!is.null(wb)) {
  top3 <- wb %>% filter(padj < padj_thresh) %>% slice_head(n=3) %>%
    transmute(txt = sprintf("- %s (padj = %.2e)", Description, padj))
  legend_lines <- c(legend_lines,
                    "## Figure 2. Whole Blood — GO BP ORA (Top 10)",
                    "Dot plot showing the top 10 enriched GO Biological Process terms (ORA) in Whole Blood (Sepsis vs Control).",
                    sprintf("Thresholds: padj < %.2f; displayed = top %d by padj.", padj_thresh, top_n),
                    "Top hits:",
                    if (nrow(top3)>0) paste(top3$txt, collapse = "\n") else "- (none)",
                    ""
  )
}
if (panel_done) {
  legend_lines <- c(legend_lines,
                    "## Figure 3. Panel — Monocytes & Whole Blood",
                    "Side-by-side panel of Figure 1 and Figure 2 for visual comparison of pathway patterns.", ""
  )
}
writeLines(legend_lines, con = "results/Figure_Legends.md")
message("Saved: results/Figure_Legends.md")

message("==> Done: 10_figures_finalize")