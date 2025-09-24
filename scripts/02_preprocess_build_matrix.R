# scripts/02_preprocess_build_matrix.R
# ------------------------------------------------------------
# 目的：
#  - 発現行列（mat2）とサンプル情報（ph2）を作成して保存
#  - 補足ファイル(.txt/.txt.gz)があれば優先使用
#  - 無ければ SeriesMatrix (ExpressionSet) から exprs() を抽出
#  - 欠損や非有限値の安全対処を実施
# 出力：
#  - data/processed/GSE60424_matrix_pheno.rds  (list(mat=..., pheno=...))
#  - results/GSE60424_dimensions.txt          (次工程の見取り表)
# ------------------------------------------------------------

message("==> Step 02: Preprocess & build expression matrix")

suppressPackageStartupMessages({
  library(GEOquery)
  library(data.table)
  library(stringr)
  library(Biobase)
})

# 必要フォルダ
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("results", recursive = TRUE, showWarnings = FALSE)

# SeriesMatrix（Step01で保存済みのはず）
eset_list_path <- "data/processed/GSE60424_eset.rds"
stopifnot(file.exists(eset_list_path))
eset_list <- readRDS(eset_list_path)
eset <- eset_list[[1]]
pheno <- Biobase::pData(eset)

# --- 1) 補足ファイルの探索（任意で存在） ---
supp_dir <- "data/raw/GSE60424"
supp_files <- character(0)
if (dir.exists(supp_dir)) {
  supp_files <- list.files(supp_dir, full.names = TRUE, pattern = "\\.(txt|txt\\.gz)$")
  # 正規化行列っぽいファイル名を優先
  prio <- grepl("normalized|norm|count|expression|expr", basename(supp_files), ignore.case = TRUE)
  supp_files <- c(supp_files[prio], supp_files[!prio])
}
use_supp <- length(supp_files) > 0

# --- 2) 行列の読み込み ---
if (use_supp) {
  message("... supplementary file detected: using ", basename(supp_files[1]))
  dt <- tryCatch(
    suppressWarnings(fread(supp_files[1])),
    error = function(e) NULL
  )
  if (is.null(dt) || ncol(dt) < 2) {
    warning("Supplementary file could not be parsed. Fallback to ExpressionSet.")
    use_supp <- FALSE
  } else {
    gene_col <- names(dt)[1]
    mat <- as.matrix(dt[, -1, with = FALSE])
    mode(mat) <- "numeric"
    rownames(mat) <- dt[[gene_col]]
    # 列名をGSMに寄せる（title一致）
    match_idx <- match(colnames(mat), pheno$title)
    gsm <- rownames(pheno)[match_idx]
    colnames(mat) <- ifelse(is.na(gsm), colnames(mat), gsm)
  }
}

if (!use_supp) {
  message("... using ExpressionSet(exprs) from SeriesMatrix")
  mat <- Biobase::exprs(eset)  # 行=遺伝子, 列=GSMになる想定
  # 念のため列名をGSM整形（すでにGSMならそのまま）
  # phenoの行名がGSMなので、マッチするものだけ使う
  common <- intersect(colnames(mat), rownames(pheno))
  if (length(common) == 0) {
    # 稀なケース: 列名がtitleのとき
    match_idx <- match(colnames(mat), pheno$title)
    gsm <- rownames(pheno)[match_idx]
    colnames(mat) <- ifelse(is.na(gsm), colnames(mat), gsm)
  } else {
    mat <- mat[, common, drop = FALSE]
    pheno <- pheno[common, , drop = FALSE]
  }
}

# --- 3) 欠損・非有限値の安全対処 ---
# 列方向で全てNAの列は除外
keep_cols <- colSums(is.finite(mat)) > 0
mat <- mat[, keep_cols, drop = FALSE]
pheno <- droplevels(pheno[keep_cols, , drop = FALSE])

# 行方向で全てNAの行は除外
keep_rows <- rowSums(is.finite(mat)) > 0
mat <- mat[keep_rows, , drop = FALSE]

# 各サンプル列のNAを中央値で穴埋め（中央値が非有限の場合は0）
for (j in seq_len(ncol(mat))) {
  if (anyNA(mat[, j])) {
    med <- suppressWarnings(median(mat[, j], na.rm = TRUE))
    if (!is.finite(med)) med <- 0
    mat[is.na(mat[, j]), j] <- med
  }
}

# --- 4) 簡単な見取り表を出力 ---
dim_info <- capture.output({
  cat("Matrix dim: ", paste(dim(mat), collapse = " x "), "\n", sep = "")
  cat("Phenotype rows: ", nrow(pheno), "\n", sep = "")
  # サンプルの疾病・細胞種の分布確認
  if ("diseasestatus:ch1" %in% colnames(pheno)) {
    cat("\n--- Disease status ---\n")
    print(table(pheno[["diseasestatus:ch1"]]))
  }
  if ("celltype:ch1" %in% colnames(pheno)) {
    cat("\n--- Cell type ---\n")
    print(table(pheno[["celltype:ch1"]]))
  }
})
writeLines(dim_info, "results/GSE60424_dimensions.txt")

# --- 5) 保存 ---
saveRDS(list(mat = mat, pheno = pheno), "data/processed/GSE60424_matrix_pheno.rds")
message("... saved: data/processed/GSE60424_matrix_pheno.rds")
message("==> Done: Step 02")