# Title
Transcriptome reanalysis of GSE60424 highlights STAT5A/PRLR axis in monocyte response to sepsis

# Abstract
**Background:** Sepsis is a life-threatening syndrome caused by dysregulated host responses to infection. Although transcriptome analyses have provided insights into immune dysregulation, the involvement of the prolactin (PRL)–STAT5 axis in human sepsis remains poorly understood.
**Objectives:** This study aimed to establish a reproducible reanalysis workflow of a public RNA-seq dataset and to explore potential dysregulation of PRL/PRLR/STAT5-related signaling in immune cells during sepsis.
**Methods:** We reanalyzed the GEO dataset GSE60424, which includes RNA-seq profiles of purified immune cell subsets and whole blood samples from healthy controls and patients with sepsis. Using a standardized R/Bioconductor pipeline, we performed differential expression analysis (limma), functional enrichment (GO, KEGG, Reactome), and gene set enrichment analysis (GSEA). Pathway-level activity of JAK–STAT and prolactin signaling was further evaluated by signature z-scoring.
**Results:** In monocytes, we identified enrichment of Fcγ receptor–mediated phagocytosis, type I interferon signaling, and cytoskeletal regulation pathways. Whole blood showed strong enrichment of ribosome biogenesis and rRNA metabolic processes, reflecting systemic inflammatory responses. Neutrophils displayed no pathways reaching statistical significance. While the PRL/PRLR/STAT5 axis was not robustly enriched, modest alterations in STAT5A and PRLR expression were observed in monocytes. All scripts, intermediate results, and figures were deposited to GitHub and Zenodo for reproducibility.
**Conclusions:** This reproducible reanalysis highlights cell type–specific transcriptional responses in sepsis and provides a publicly accessible workflow. Although the PRL/STAT5 axis did not show strong transcriptomic signals under baseline conditions, the findings motivate targeted wet-lab experiments to assess its role in monocyte activation during sepsis.

# Introduction
- 公共データ再解析の意義
- プロラクチン/STAT5A 経路と免疫細胞応答との関連に関心があること
- 本研究の目的（GSE60424 の再解析と Monocyte におけるシグナル経路の同定）
Sepsis is a life‐threatening condition characterized by dysregulated host responses to infection. Despite intensive research, the molecular mechanisms that drive sepsis pathophysiology remain incompletely understood, and reliable biomarkers to stratify patients or guide therapy are still lacking. Transcriptome profiling has provided valuable insights into immune cell behavior during sepsis, highlighting the contribution of both innate and adaptive immunity.
Prolactin (PRL) is a pleiotropic hormone best known for its role in lactation, but it also exerts immunomodulatory effects. Through binding to the prolactin receptor (PRLR) and activation of the JAK–STAT pathway, particularly STAT5A, prolactin has been implicated in the regulation of lymphocyte proliferation, cytokine secretion, and immune tolerance. However, the relevance of the PRL/PRLR/STAT5 axis in human sepsis remains poorly defined. Experimental studies have suggested potential links, but direct transcriptome evidence across immune cell subsets is limited.
Publicly available RNA sequencing (RNA-seq) datasets provide an opportunity to revisit these questions using reproducible computational pipelines. The GEO dataset **GSE60424** includes RNA-seq profiles from multiple purified immune cell types and whole blood samples collected from healthy individuals and patients with sepsis, as well as other conditions. This dataset represents a valuable resource for assessing cell type–specific transcriptional alterations in sepsis.
In the present study, we reanalyzed GSE60424 with a focus on differential expression and pathway enrichment across monocytes, neutrophils, and whole blood. We further examined whether the PRL/PRLR/STAT5 axis or related signaling pathways show evidence of dysregulation in sepsis. Our goal was to establish a reproducible reanalysis workflow, publicly available via GitHub and Zenodo, and to identify candidate pathways that may guide future mechanistic or experimental investigations.

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
 [oai_citation:0‡Methods.md](file-service://file-WaesQE4HkztmqAos4AZZV5)

# Results
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
 [oai_citation:1‡Results_Summary.md](file-service://file-1m8mHT9Fc8hRv6kiHJq854)

# Discussion
本研究は公共RNA-seqデータセット GSE60424 を対象に、SepsisとHealthy Controlの差を細胞種別に再解析した。MonocytesでのFcγ受容体経路・I型IFN経路の富化、Whole Bloodでの翻訳関連経路の優位性が見えた一方、Neutrophilsでは有意経路が得られなかった。これらは細胞種ごとの応答性やサンプルサイズの制約を反映していると考えられる。

また、PRL/STAT5A軸についてはMonocytesで弱い傾向が確認されたのみであり、今後はwet実験による刺激条件下の検証が望まれる。

## Limitations
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
 [oai_citation:2‡Limitations.md](file-service://file-SYRRnakCSRUdQafFi8a8fd)

# Data availability
All code, processed results, and figures are available at:  
GitHub: https://github.com/Takashi-Ka/gse60424-reanalysis  
Zenodo (Phase 1 release): https://doi.org/xxxxx  （実際のDOIを挿入）

# References
(必要に応じて後で整備)

<!-- BEGIN: Monocytes_Figure_Legends -->
## Figure legends

**Figure 1. Volcano plot of differential expression in Monocytes (Sepsis vs Healthy Controls).**  
Volcano plot showing differentially expressed genes (DEGs) in Monocytes between sepsis patients and healthy controls.  
The x-axis represents log2 fold change and the y-axis represents –log10 adjusted p-value (FDR).  
Significant DEGs (FDR < 0.05) are highlighted.

**Figure 2. GO biological process enrichment in Monocytes (Sepsis vs Healthy Controls).**  
Dot plot of enriched Gene Ontology biological process (GO BP) terms for DEGs in Monocytes.  
Dot size reflects the number of DEGs annotated to each term, and color represents adjusted p-value.  
Enrichment analysis was performed using clusterProfiler with all detected genes as background.

**Figure 3. KEGG pathway enrichment in Monocytes (Sepsis vs Healthy Controls).**  
Dot plot of enriched KEGG pathways for DEGs in Monocytes.  
Top significantly enriched pathways are displayed, with dot size corresponding to the number of DEGs and color to adjusted p-value.  
Pathway enrichment was performed using clusterProfiler with FDR < 0.05 as significance threshold.
<!-- END: Monocytes_Figure_Legends -->

