
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

