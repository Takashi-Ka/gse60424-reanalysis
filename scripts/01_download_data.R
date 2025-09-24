# scripts/01_download_data.R
# ------------------------------------------------------------
# GSE60424 のデータ取得：
#  - 補足ファイル（normalized_counts.txt.gz）を data/raw/GSE60424/ に保存
#  - SeriesMatrix（eset）を data/processed/GSE60424_eset.rds に保存
#  - ついでにサンプル情報を results/GSE60424_pheno.csv として保存
# ------------------------------------------------------------

message("==> Step 01: Download GSE60424 data")

# 必要パッケージ
if (!requireNamespace("GEOquery", quietly = TRUE)) install.packages("GEOquery")
if (!requireNamespace("data.table", quietly = TRUE)) install.packages("data.table")

library(GEOquery)
library(data.table)

# フォルダ用意
dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("results", recursive = TRUE, showWarnings = FALSE)

gse_id <- "GSE60424"
raw_dir <- file.path("data", "raw", gse_id)
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

# 1) 補足ファイルダウンロード（normalized_counts.txt.gz のみ取得）
message("... downloading supplementary files (this may take a minute)")
getGEOSuppFiles(
  gse_id,
  baseDir = "data/raw",
  makeDirectory = TRUE,
  filter_regex = "normalized_counts\\.txt\\.gz$"
)

# 2) SeriesMatrix（GSEMatrix）取得 → RDS保存
message("... fetching series matrix (ExpressionSet)")
eset_list <- getGEO(gse_id, GSEMatrix = TRUE)
# 複数プラットフォームが返る可能性を考慮し、最初の要素を採用
eset <- eset_list[[1]]
saveRDS(eset_list, file = file.path("data/processed", "GSE60424_eset.rds"))
message("... saved: data/processed/GSE60424_eset.rds")

# 3) サンプル情報（phenotype）をCSVで保存（便利）
ph <- Biobase::pData(eset)
# 列名にスペースや記号が多いので、そのまま保存します
fwrite(as.data.frame(ph), file.path("results", "GSE60424_pheno.csv"))

# 4) 取得ファイルの存在チェック
supp_files <- list.files(raw_dir, full.names = TRUE, pattern = "normalized_counts\\.txt\\.gz$")
if (length(supp_files) == 0) {
  warning("normalized_counts.txt.gz が見つかりませんでした。GEOの構成変更か、ネットワーク要因の可能性があります。")
} else {
  message("... found supplementary file(s):")
  print(basename(supp_files))
}

message("==> Done: Step 01")