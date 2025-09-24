# scripts/05_pathways_and_signatures.R
# ------------------------------------------------------------
# 目的：
#  - Monocytes / Neutrophils / Whole Blood のDE結果に対して
#    * ORA: GO BP / KEGG / Reactome
#    * GSEA: Reactome（t統計 or logFCの順位付け）
#    * Signature-Z: JAK–STAT / Prolactin（Reactome & WikiPathways）
#  - 図と表を自動保存（空結果でも落ちない設計）
# 出力（例）：
#  - results/<cell>_GO_BP_ORA.csv, <cell>_KEGG_ORA.csv, <cell>_REACTOME_ORA.csv
#  - figures/<cell>_*_ORA_dotplot.png
#  - results/<cell>_REACTOME_GSEA.csv, figures/<cell>_REACTOME_GSEA_dotplot.png
#  - results/<cell>_signatureZ_JAK-PRL_stats.csv
# 依存：
#  - clusterProfiler, org.Hs.eg.db, msigdbr, enrichplot, ggplot2
# ------------------------------------------------------------

message("==> Step 05: Pathway analyses & signature Z")

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(stringr)
  library(clusterProfiler)
  library(org.Hs.eg.db)
  library(msigdbr)
  library(enrichplot)
  library(ggplot2)
})

dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

# ---- パラメータ（必要に応じて変更） -------------------------
padj_cut   <- 0.05
logfc_cut  <- 1.0      # |log2FC| ≥ 1
top_n_dot  <- 20       # dotplot の最大行数
gsea_minGS <- 10
gsea_maxGS <- 500

# ---- 入力：Step 04（注釈済み） -----------------------------
in_rds <- "data/processed/DE_results_annotated.rds"
stopifnot(file.exists(in_rds))
res <- readRDS(in_rds)

# ---- ユーティリティ ----------------------------------------
sym2entrez <- function(symbols){
  unname(AnnotationDbi::mapIds(org.Hs.eg.db, keys=symbols,
                               column="ENTREZID", keytype="SYMBOL", multiVals="first"))
}

ens2entrez <- function(ensembl){
  unname(AnnotationDbi::mapIds(org.Hs.eg.db, keys=ensembl,
                               column="ENTREZID", keytype="ENSEMBL", multiVals="first"))
}

safe_write <- function(df, path){
  if (is.null(df) || nrow(df) == 0) {
    message("... empty: ", path)
    write.csv(data.frame(), path, row.names = FALSE)
  } else {
    write.csv(df, path, row.names = FALSE)
  }
}

safe_dotplot <- function(edo, out_png, title){
  if (is.null(edo) || nrow(as.data.frame(edo)) == 0) {
    message("... empty plot: ", out_png)
    return(invisible(NULL))
  }
  p <- dotplot(edo, showCategory = min(top_n_dot, nrow(as.data.frame(edo)))) +
    ggtitle(title) + theme_bw(base_size=12)
  ggsave(out_png, p, width=8, height=6, dpi=300)
  message("... saved: ", out_png)
}

# ---- シグネチャZ用パスウェイ（JAK–STAT / Prolactin） -------
get_jak_prl_sets <- function(){
  react <- msigdbr(species = "Homo sapiens", collection = "C2", subcollection = "CP:REACTOME")
  wikip <- msigdbr(species = "Homo sapiens", collection = "C2", subcollection = "CP:WIKIPATHWAYS")
  paths <- bind_rows(
    react %>% filter(grepl("JAK.*STAT|STAT.*JAK|PROLACTIN", gs_name, ignore.case = TRUE)) %>%
      select(gs_name, gene_symbol),
    wikip %>% filter(grepl("JAK.*STAT|PROLACTIN", gs_name, ignore.case = TRUE)) %>%
      select(gs_name, gene_symbol)
  ) %>% distinct()
  paths$ENTREZID <- sym2entrez(paths$gene_symbol)
  paths <- paths %>% filter(!is.na(ENTREZID))
  split(paths$ENTREZID, paths$gs_name)
}

score_signature <- function(expr_mat, genes_entrez, min_genes=5){
  present_rows <- intersect(rownames(expr_mat), genes_entrez)
  if (length(present_rows) < min_genes) return(rep(NA_real_, ncol(expr_mat)))
  z <- t(scale(t(expr_mat[present_rows, , drop=FALSE])))
  colMeans(z, na.rm = TRUE)
}

signature_compare <- function(celltype, expr_entrez, pheno, gene_sets){
  keep <- pheno$`celltype:ch1`==celltype & pheno$`diseasestatus:ch1` %in% c("Healthy Control","Sepsis")
  X <- expr_entrez[, keep, drop=FALSE]; P <- droplevels(pheno[keep, , drop=FALSE])
  if (ncol(X) < 4) return(NULL)
  grp <- ifelse(P$`diseasestatus:ch1`=="Healthy Control","control","sepsis")
  scores <- sapply(gene_sets, \(g) score_signature(X, g))
  df <- as.data.frame(scores); df$group <- grp
  out <- lapply(colnames(scores), function(nm){
    v <- df[[nm]]; ok <- is.finite(v)
    p <- tryCatch(t.test(v[ok] ~ df$group[ok])$p.value, error=function(e) NA_real_)
    data.frame(set=nm,
               p.value=p,
               mean_ctrl=mean(v[df$group=="control"], na.rm=TRUE),
               mean_sepsis=mean(v[df$group=="sepsis"], na.rm=TRUE))
  })
  out <- bind_rows(out); out$padj <- p.adjust(out$p.value, "BH")
  out$mean_diff <- out$mean_sepsis - out$mean_ctrl
  out
}

# ---- ORA / GSEA 本体 ----------------------------------------
do_celltype <- function(cell_name, tt){
  message("... ", cell_name)
  
  # 背景・遺伝子集合
  universe_ens <- tt$ensembl
  universe_ent <- ens2entrez(universe_ens)
  bg <- unique(na.omit(universe_ent))
  
  # DE遺伝子（閾値）
  tt$ENTREZID <- ens2entrez(tt$ensembl)
  de_up   <- unique(na.omit(tt$ENTREZID[ tt$padj < padj_cut & tt$logFC >=  logfc_cut ]))
  de_down <- unique(na.omit(tt$ENTREZID[ tt$padj < padj_cut & tt$logFC <= -logfc_cut ]))
  de_all  <- unique(c(de_up, de_down))
  
  # ---- ORA: GO BP ----
  go_ora <- tryCatch(enrichGO(gene = de_all, OrgDb = org.Hs.eg.db,
                              keyType = "ENTREZID", ont = "BP",
                              qvalueCutoff = 0.2, pAdjustMethod="BH",
                              universe = bg, readable = TRUE), error=function(e) NULL)
  safe_write(as.data.frame(go_ora), file.path("results", paste0(cell_name, "_GO_BP_ORA.csv")))
  safe_dotplot(go_ora, file.path("figures", paste0(cell_name, "_GO_BP_ORA_dotplot.png")),
               paste0(cell_name, " — GO BP (ORA)"))
  
  # ---- ORA: KEGG ----
  kegg_ora <- tryCatch(enrichKEGG(gene = de_all, organism = "hsa",
                                  universe = bg, pAdjustMethod = "BH",
                                  qvalueCutoff = 0.2), error=function(e) NULL)
  # readableに変換（記号表示）
  if (!is.null(kegg_ora) && nrow(as.data.frame(kegg_ora))>0) {
    kegg_ora <- setReadable(kegg_ora, OrgDb = org.Hs.eg.db, keyType="ENTREZID")
  }
  safe_write(as.data.frame(kegg_ora), file.path("results", paste0(cell_name, "_KEGG_ORA.csv")))
  safe_dotplot(kegg_ora, file.path("figures", paste0(cell_name, "_KEGG_ORA_dotplot.png")),
               paste0(cell_name, " — KEGG (ORA)"))
  
  # ---- ORA: Reactome（via msigdbr）----
  react <- msigdbr(species="Homo sapiens", collection="C2", subcollection="CP:REACTOME") %>%
    select(gs_name, gene_symbol)
  react$ENTREZID <- sym2entrez(react$gene_symbol)
  react <- react %>% filter(!is.na(ENTREZID))
  geneset_list <- split(react$ENTREZID, react$gs_name)
  react_ora <- tryCatch(enricher(gene = de_all, TERM2GENE = react %>% select(gs_name,ENTREZID),
                                 universe = bg, pAdjustMethod="BH"), error=function(e) NULL)
  safe_write(as.data.frame(react_ora), file.path("results", paste0(cell_name, "_REACTOME_ORA.csv")))
  safe_dotplot(react_ora, file.path("figures", paste0(cell_name, "_REACTOME_ORA_dotplot.png")),
               paste0(cell_name, " — Reactome (ORA)"))
  
  # ---- GSEA: Reactome（順位付け）----
  # 順位付けスコアは t が推奨。無ければ logFC をfallback。
  stat <- tt$t; if (is.null(stat) || all(!is.finite(stat))) stat <- tt$logFC
  names(stat) <- tt$ENTREZID
  stat <- stat[is.finite(stat) & !is.na(names(stat))]
  # 重複ENTREZは平均で集約
  stat <- tapply(stat, names(stat), mean)
  stat <- sort(stat, decreasing = TRUE)
  
  # ties解消用の極小ノイズ（順位だけを安定させる目的）
  set.seed(123)  # 再現性のため固定
  stat <- stat + rnorm(length(stat), mean = 0, sd = 1e-6)
  
  react_t2g <- react %>% select(gs_name,ENTREZID) %>% distinct()
  react_t2g <- react_t2g[react_t2g$ENTREZID %in% names(stat), ]
  gsea <- tryCatch(GSEA(stat, TERM2GENE = react_t2g,
                        minGSSize = gsea_minGS, maxGSSize = gsea_maxGS,
                        pAdjustMethod = "BH", verbose = FALSE,
                        eps = 0),   # ★ これを追加
                   error=function(e) NULL)
  gsea_df <- as.data.frame(gsea)
  safe_write(gsea_df, file.path("results", paste0(cell_name, "_REACTOME_GSEA.csv")))
  if (!is.null(gsea) && nrow(gsea_df)>0) {
    p <- enrichplot::dotplot(gsea, showCategory = min(top_n_dot, nrow(gsea_df))) +
      ggtitle(paste0(cell_name, " — Reactome (GSEA)")) + theme_bw(base_size=12)
    ggsave(file.path("figures", paste0(cell_name, "_REACTOME_GSEA_dotplot.png")),
           p, width=8, height=6, dpi=300)
    message("... saved: figures/", cell_name, "_REACTOME_GSEA_dotplot.png")
  } else {
    message("... GSEA empty for ", cell_name)
  }
  
  # ---- Signature-Z: JAK/PRL ----
  # 発現行列の準備（ENTREZ行名にする）
  # Step02のマトリクスを再読込（Ensembl行名→ENTREZへ変換）
  mp <- readRDS("data/processed/GSE60424_matrix_pheno.rds")
  mat <- mp$mat; ph <- mp$pheno
  rownames(mat) <- ens2entrez(rownames(mat))
  mat <- mat[!is.na(rownames(mat)), , drop=FALSE]
  # 正規化（対数スケールでZ化を想定、既に正規化されているならそのままでもOK）
  # ここでは行ごとZ化→平均をスコアにする
  gene_sets <- get_jak_prl_sets()
  sig_stat <- signature_compare(cell_name, expr_entrez = mat, pheno = ph, gene_sets = gene_sets)
  safe_write(sig_stat, file.path("results", paste0(cell_name, "_signatureZ_JAK-PRL_stats.csv")))
  
  invisible(list(go=go_ora, kegg=kegg_ora, react=react_ora, gsea=gsea, sig=sig_stat))
}

# ---- 実行 ---------------------------------------------------
out <- list(
  Monocytes   = do_celltype("Monocytes",   res$tt_mono),
  Neutrophils = do_celltype("Neutrophils", res$tt_neut),
  `Whole Blood` = do_celltype("Whole Blood", res$tt_wb)
)

message("==> Done: Step 05. See results/ and figures/")