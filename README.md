⸻

GSE60424 再解析パイプライン

プロジェクト概要

本リポジトリは、GSE60424（Sepsis vs Healthy Control, 複数細胞種）RNA-seq 公開データの再解析を行うためのワークフローです。
目的は、Monocytes / Neutrophils / Whole Blood 各細胞種における遺伝子発現変動を明らかにし、JAK-STAT / Prolactin シグナル経路との関連性を探索することです。

⸻

フェーズ構成

フェーズ0 — スキル基盤構築（0〜1か月）
	•	目標: オミクス再解析に必要な環境と基本操作を習得
	•	具体的行動:
	•	R / Bioconductor を Mac または lab PC にセットアップ
	•	Galaxy Japan / Google Colab で GUI ベースの RNA-seq チュートリアルを 2 本実施
	•	GitHub で解析ノートを公開し再現性確保
	•	リソース:
	•	PC, 無料クラウド (Galaxy, Colab)

⸻

フェーズ1 — リポジトリ初期化とデータ取得
	•	scaffold_repo.R により解析ディレクトリ構成を自動生成
	•	GEOquery により GSE60424 の生データとアノテーション取得
	•	出力:
	•	data/raw/ 以下に元データファイル
	•	data/processed/GSE60424_matrix_pheno.rds

⸻

フェーズ2 — 正規化・フィルタリング
	•	raw カウントから低発現遺伝子を除外
	•	正規化後のカウント行列を保存
	•	出力:
	•	data/processed/normalized_counts.txt.gz
	•	data/processed/GSE60424_matrix_pheno.rds（更新）

⸻

フェーズ3 — DE解析（limma）
	•	各細胞種（Monocytes / Neutrophils / Whole Blood）で Sepsis vs Healthy Control を比較
	•	解析ステップ:
	1.	0分散遺伝子除去
	2.	群内分散が0の遺伝子除去（コントロール群・感染群いずれかで分散が0のものを除外）
	•	出力:
	•	results/<Celltype>_Sepsis_vs_Control_DEG.csv
	•	data/processed/DE_results.rds（tt_* をまとめたリスト）

⸻

フィルタリング条件と遺伝子数の推移

Celltype	Before（元データ行数）	After0（全体0分散除去後）	After（群内分散0も除去後）
Monocytes	50,045	16,066	12,986
Neutrophils	50,045	16,825	13,032
Whole Blood	50,045	18,138	14,324


⸻

実行方法（概要）
	1.	初期化

Rscript scripts/scaffold_repo.R


	2.	データ取得

Rscript scripts/01_download_data.R


	3.	正規化とフィルタリング

Rscript scripts/02_normalize_and_filter.R


	4.	DE解析

Rscript scripts/03_DE_limma_by_celltype.R



⸻

フェーズ4 — Wet 実験案（オプション）

公開データで得られた知見を、in vitro 実験で検証します。
	•	モデル細胞: THP-1（ヒト単球系細胞株）
	•	刺激条件例:
	•	LPS（エンドトキシン）刺激
	•	プロラクチン（PRL）添加
	•	± JAK阻害剤（例: Ruxolitinib）
	•	解析項目:
	•	RNA抽出 → RT-qPCR による STAT5A, PRLR, 下流遺伝子の発現測定
	•	参考：GSE60424 の発現変動方向と一致するかを確認
	•	目的:
	•	RNA-seq の再解析結果と生物学的再現性の確認
	•	JAK-STAT / Prolactin 経路活性化の分子証拠取得

⸻

再現性と共有
	•	すべてのスクリプトは scripts/ 以下に配置
	•	実行順は README 記載通り
	•	入力データは GEO から取得（リポジトリには含めない）
	•	解析結果は results/ に保存され、GitHub で共有可能
	**環境再現**  
まず `scripts/00_install_requirements.R` を実行して必要パッケージを揃え、  
その後に `scripts/01_*` から順に実行してください。

⸻

## 結果解釈


# Results Summary

本解析では、GSE60424データセットを細胞種別（Monocytes / Neutrophils / Whole Blood）に分けてSepsis vs Healthy Controlの発現差解析を行い、GO・Reactome経路に対するオーバーリプレゼンテーション解析（ORA）およびGSEAを実施しました。

---

## Monocytes
- 有意（padj < 0.05）に富む経路は、主に免疫応答・感染関連経路。
- 特に「Fcγ受容体依存性食作用（REACTOME_FCGAMMA_RECEPTOR_FCGR_DEPENDENT_PHAGOCYTOSIS）」が最も強く有意（padj = 9.11e-04）。
- 寄生虫感染（Leishmaniaなど）、I型インターフェロンシグナル経路、Rho GTPase関連経路も検出され、単球の病原体応答や細胞骨格再構築が示唆される。

---

## Neutrophils
- 本解析条件ではpadj < 0.05に達する経路は検出されず。
- 有意傾向にある経路はあったが、分散や検出力の制約により統計的有意性は得られなかった。

---

## Whole Blood
- 核酸・リボソーム生合成に関するGO_BP経路が多数有意に富む。
- 特に「リボソーム生合成（ribosome biogenesis）」「rRNA代謝過程（rRNA metabolic process）」などが高い有意性を示した。
- 核輸送（nuclear transport）や核外輸送（nuclear export）など、転写後制御やタンパク質輸送に関わる経路も検出。

---

## Interpretation
- **Monocytes**では感染応答・Fcγ受容体経路・細胞骨格制御が顕著で、病原体処理能やシグナル応答の活性化が示唆される。
- **Whole Blood**では翻訳関連経路が優位で、全身性炎症や高い蛋白合成需要を反映している可能性がある。
- **Neutrophils**では顕著なシグナルは検出されなかったが、今後サンプルサイズ増加や異なる統計手法により新規知見が得られる可能性がある。

---

**解析条件**
- DE解析：limma、群内分散0遺伝子を除外
- ORA/GSEA：padj < 0.05を有意基準とし、ReactomeおよびGO Biological Processを対象

---

**次のステップ**
- MonocytesでのFcγ受容体経路・I型IFN経路の上流遺伝子や共発現ネットワーク解析
- Whole Bloodでの翻訳関連経路と臨床指標（炎症マーカー等）の関連評価


[詳細は results/Results_Summary.md を参照](results/Results_Summary.md)
## 参考ドキュメント

- [Methods](docs/Methods.md)
- [Limitations](docs/Limitations.md)

## 実行順（再現手順）

1. 依存パッケージを準備  
   ```r
   source("scripts/00_install_requirements.R")
   ```

2. 解析を順に実行  
   ```text
   1) scripts/01_download_data.R
   2) scripts/02_normalize_and_filter.R
   3) scripts/03_DE_limma_by_celltype.R
   4) scripts/04_annotation_and_volcano.R
   5) scripts/05_pathways_and_signatures.R
   6) scripts/06_quick_summary_top_pathways.R
   7) scripts/07_figures_publication.R
   8) scripts/08_save_results_summary.R
   9) scripts/09_update_readme_results.R
   10) scripts/10_figures_finalize.R
   11) scripts/11_generate_methods_limitations.R
   12) scripts/12_freeze_sessioninfo.R
   13) scripts/13_update_readme_links.R
   14) scripts/14_freeze_environment.R
   15) scripts/15_update_readme_runorder.R   
   16) scripts/16_sync_readme_sections.R # ← 本スクリプト（README更新）
   ```

3. 出力確認  
   - results/: DE/ORA/GSEA/シグネチャ要約、Figure_Legends.md、Results_Summary.md  
   - figures/: Volcano、Top10 dotplot、最終版 PNG/SVG/PDF、パネル図  
   - docs/: Methods.md、Limitations.md、sessionInfo.txt、package_versions.csv

**メモ**  
- Whole Blood の出力ファイル名は、環境により `Whole Blood_*.csv` / `WholeBlood_*.csv` の両方があり得ます。本リポジトリのスクリプトは両表記を自動で拾うよう実装済みです。

## Methods


# Methods

## Data source
- Public RNA-seq dataset: **GSE60424** (Sepsis vs Healthy Control; multiple cell types).
- Acquisition via GEOquery. Raw matrices and phenodata integrated.

## Preprocessing
- Low-variance genes filtered:
  - **Filter1**: global row variance > 0.
  - **Filter2**: group-wise variance > 0 in both control and sepsis.
- NA rows removed in normalization step.
- Gene counts/log-intensities as per original series matrix (see scripts).

## Differential Expression (by cell type)
- Packages: **limma**, **matrixStats**.
- Design: `sepsis - control` (no intercept).
- Empirical Bayes: `eBayes(fit, robust=TRUE, trend=TRUE)`.
- Outputs: `results/<Celltype>_Sepsis_vs_Control_DEG.csv`.

## Annotation & Visualization
- IDs: **ENSEMBL → SYMBOL / ENTREZ** via **org.Hs.eg.db**.
- Volcano plots: **EnhancedVolcano**（fallback to ggplot2+ggrepel）.
- Outputs: `figures/*_volcano.png`.

## Enrichment Analyses (Step 05)
- **ORA**: GO BP (`enrichGO`), KEGG (`enrichKEGG`), Reactome (`msigdbr` + `enricher`).
- **GSEA**: Reactome preranked (`GSEA`), stats = `t`（fallback: `logFC`), ties resolved by tiny jitter.
- Multiple testing: BH, significance at padj < 0.05.
- Outputs: CSV in `results/`, dotplots in `figures/`.

## Signature Z Scoring
- JAK–STAT / Prolactin sets collected via **msigdbr** (Reactome & WikiPathways namesearch).
- Row-wise Z-score per gene, mean aggregated per sample; t-test between groups.
- Output: `results/<Celltype>_signatureZ_JAK-PRL_stats.csv`.

## Reproducibility
- Scripts: `scripts/01–10_*`.
- Key inputs/outputs stored under `data/` and `results/`.
- Software environment recorded via `results/sessionInfo_*.txt`.

...（全文は docs/Methods.md を参照）
## Limitations


# Limitations

1. **Platform & normalization heterogeneity**  
   - GSE60424 由来の行列は元処理（TMMなど）の影響を受けます。再処理なしの再解析である点を明示。

2. **群バランスと分散**  
   - 細胞種によって有意経路が出づらい（Neutrophils）可能性。サンプル数・効果量の影響が残存。

3. **Pathway database bias**  
   - Reactome/GO/KEGG 間で経路定義が異なり、富化結果に依存性。名称マッピングの更新頻度にも注意。

4. **GSEAのties・極小p値**  
   - 同点解消のため微小ノイズを加算、`eps=0` を設定。順位境界付近の結果は頑健性を再確認する。

5. **PRL/JAK-STATの弱シグナル**  
   - MonocytesではPRL/STAT5Aの強い偏りは得られず。細胞種特性・刺激条件非一致の可能性（wet実験で検証予定）。

6. **Whole Bloodの解釈**  
   - 多細胞種混合のため、リボソーム関連の富化は構成比変動・系統的バイアスの影響があり得る。

## Citation

If you use this pipeline, please cite:
Kajitani T. (2025). GSE60424 reanalysis pipeline (Phase 1).  
https://doi.org/10.5281/zenodo.17196511	
