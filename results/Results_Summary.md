
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

