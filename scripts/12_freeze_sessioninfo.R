# scripts/11_generate_methods_limitations.R
# ------------------------------------------------------------
# 目的:
#   docs/Methods.md と docs/Limitations.md を自動生成する
# 実行:
#   source("scripts/11_generate_methods_limitations.R")
# ------------------------------------------------------------

dir.create("docs", showWarnings = FALSE)

methods_text <- '
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
'

limitations_text <- '
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
'

writeLines(methods_text, con = "docs/Methods.md")
writeLines(limitations_text, con = "docs/Limitations.md")

message("✅ Saved: docs/Methods.md, docs/Limitations.md")