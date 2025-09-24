# scripts/09_update_readme_results.R
# ------------------------------------------------------------
# 目的:
#   README.md に「結果解釈」セクションを自動で追加/更新する
# 使い方:
#   source("scripts/09_update_readme_results.R")
# ------------------------------------------------------------

section_md <- '
## 結果解釈

本解析では、GSE60424 データセットを用い、Monocytes・Neutrophils・Whole Blood における
Sepsis 患者と Healthy Control の遺伝子発現差を比較し、GO/KEGG/Reactome に基づく経路解析を実施した。

### 主な知見
- **Monocytes**  
  - Fcγ受容体依存性貪食経路、寄生虫感染、インターフェロンα/βシグナルなどが有意に富化（Reactome ORA）。
  - 免疫応答と細胞骨格再構成が重要な特徴。
- **Neutrophils**  
  - 有意な経路は検出されず（padj < 0.05）。
- **Whole Blood**  
  - rRNA代謝、リボソーム生合成、核—細胞質間輸送など、タンパク質合成・輸送関連のGO_BP経路が有意に富化。

### 解釈
- Sepsis において Monocytes では**貪食・インターフェロンシグナル活性化**が顕著。
- Whole Blood では**リボソーム関連経路の活性化**が見られ、全身性の翻訳活性変動が示唆される。
- Neutrophils では有意経路が見られず、本条件下での応答は限定的である可能性。

### 関連図
![TopPathways Panel](figures/Monocytes_WholeBlood_panel.png)

解析結果の詳細は [`results/Results_Summary.md`](results/Results_Summary.md) を参照。
'

readme_path <- "README.md"
if (!file.exists(readme_path)) {
  stop("README.md が見つかりません。プロジェクト直下で実行してください。")
}

lines <- readLines(readme_path, warn = FALSE, encoding = "UTF-8")

# 既存の「## 結果解釈」セクションの開始を探す
start_idx <- grep("^##\\s*結果解釈\\s*$", lines)

if (length(start_idx) == 0) {
  # セクションが無ければ末尾に追加
  cat("\n", file = readme_path, append = TRUE)
  cat(section_md, file = readme_path, append = TRUE)
  message("✅ README.md に「結果解釈」セクションを新規追加しました。")
} else {
  # 次の「## 」見出しまでを置換
  next_idx <- grep("^##\\s+", lines)
  next_idx <- next_idx[next_idx > start_idx[1]]
  end_idx <- if (length(next_idx) == 0) length(lines) else (min(next_idx) - 1)
  
  new_lines <- c(
    if (start_idx[1] > 1) lines[1:(start_idx[1]-1)] else character(0),
    strsplit(sub("^\\n*", "", section_md), "\n")[[1]],
    if (end_idx < length(lines)) lines[(end_idx+1):length(lines)] else character(0)
  )
  
  writeLines(new_lines, con = readme_path, useBytes = TRUE)
  message("🔄 README.md の「結果解釈」セクションを更新しました。")
}

invisible(TRUE)