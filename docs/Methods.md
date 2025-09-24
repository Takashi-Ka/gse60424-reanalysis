
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

