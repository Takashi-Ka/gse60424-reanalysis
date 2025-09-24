
# make.R
# ----------------------------
# プロジェクト全体の解析を順に実行します
# ----------------------------

source("scripts/01_download_data.R")
source("scripts/02_preprocess.R")
source("scripts/03_DEG_analysis.R")
source("scripts/04_enrichment_analysis.R")

