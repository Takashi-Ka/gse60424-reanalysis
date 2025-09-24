# scripts/03_DE_limma_by_celltype.R
# ------------------------------------------------------------
# 目的：
#  - celltypeごと（Monocytes / Neutrophils / Whole Blood）に
#    Sepsis vs Healthy Control のDE解析（limma）
#  - 0分散除去・基本的な品質管理を含む
# 出力：
#  - results/<Celltype>_Sepsis_vs_Control_DEG.csv
#  - data/processed/DE_results.rds（tt_* をまとめたリスト）
# ------------------------------------------------------------

message("==> Step 03: Differential expression (limma) by cell type")

suppressPackageStartupMessages({
  library(limma)
  library(matrixStats)
  library(tibble)
})

# 入力（Step 02の成果物）
in_rds <- "data/processed/GSE60424_matrix_pheno.rds"
stopifnot(file.exists(in_rds))
d <- readRDS(in_rds)
mat2 <- d$mat
ph2  <- d$pheno

# 便利関数：1細胞種を解析
analyze_one <- function(celltype,
                        disease_a = "Healthy Control",
                        disease_b = "Sepsis",
                        outfile_prefix = NULL) {
  # サブセット
  keep <- ph2$`celltype:ch1` == celltype &
    ph2$`diseasestatus:ch1` %in% c(disease_a, disease_b)
  X <- mat2[, keep, drop = FALSE]
  P <- droplevels(ph2[keep, , drop = FALSE])
  
  if (ncol(X) < 4) {
    stop(sprintf("Not enough samples for %s (need >= 2 per group).", celltype))
  }
  
  # 群ベクトル
  grp <- factor(ifelse(P$`diseasestatus:ch1` == disease_a, "control", "sepsis"),
                levels = c("control", "sepsis"))
  
  # ===== フィルタ1：全体0分散を除外 =====
  rv <- matrixStats::rowVars(as.matrix(X), na.rm = TRUE)
  genes_before <- nrow(X)           # 生データ（celltypeサブセット後の行数）
  X2 <- X[rv > 0, , drop = FALSE]
  genes_after0 <- nrow(X2)          # 全体0分散除去後
  
  # ===== フィルタ2：群内0分散を除外 =====
  wgvar <- sapply(split(seq_len(ncol(X2)), grp),
                  function(idx) matrixStats::rowVars(as.matrix(X2[, idx, drop = FALSE]),
                                                     na.rm = TRUE))
  keep_wg <- rowSums(wgvar > 0) == ncol(wgvar)
  X2 <- X2[keep_wg, , drop = FALSE]
  genes_after <- nrow(X2)           # 群内0分散除去後（最終）
  
  # --- フィルタ記録（Console & ファイル）---
  cat(sprintf("[Filter] %s: Before=%d, After0=%d, After=%d\n",
              celltype, genes_before, genes_after0, genes_after))
  log_file <- "results/filter_log.txt"
  dir.create("results", showWarnings = FALSE)
  cat(sprintf("%s\tBefore=%d\tAfter0=%d\tAfter=%d\n",
              celltype, genes_before, genes_after0, genes_after),
      file = log_file, append = TRUE)
  
  # デザインとコントラスト：sepsis - control
  design <- model.matrix(~ 0 + grp)
  colnames(design) <- levels(grp)
  
  fit <- lmFit(X2, design)
  fit <- contrasts.fit(fit, makeContrasts(sepsis - control, levels = design))
  fit <- eBayes(fit, robust = TRUE, trend = TRUE)
  
  tt <- topTable(fit, number = Inf)
  tt <- tibble::rownames_to_column(tt, "ensembl")
  
  if (!is.null(outfile_prefix)) {
    write.csv(tt, file = file.path("results", paste0(outfile_prefix, "_DEG.csv")),
              row.names = FALSE)
  }
  tt
}

# 解析実行
tt_mono <- analyze_one("Monocytes",   outfile_prefix = "Monocytes_Sepsis_vs_Control")
tt_neut <- analyze_one("Neutrophils", outfile_prefix = "Neutrophils_Sepsis_vs_Control")
tt_wb   <- analyze_one("Whole Blood", outfile_prefix = "WholeBlood_Sepsis_vs_Control")

# 保存
dir.create("data/processed", showWarnings = FALSE)
saveRDS(list(tt_mono = tt_mono, tt_neut = tt_neut, tt_wb = tt_wb),
        file = "data/processed/DE_results.rds")

message("... saved: results/*_DEG.csv and data/processed/DE_results.rds")
message("==> Done: Step 03")