# scripts/13_update_readme_links.R
# ------------------------------------------------------------
# 目的:
#   README.md に「参考ドキュメント」セクションを自動で追加/更新する
#   - docs/Methods.md, docs/Limitations.md へのリンク
# 使い方:
#   source("scripts/13_update_readme_links.R")
# ------------------------------------------------------------

section_title <- "## 参考ドキュメント"
section_md <- sprintf('
%s

- [Methods](docs/Methods.md)
- [Limitations](docs/Limitations.md)
', section_title)

readme_path <- "README.md"
if (!file.exists(readme_path)) {
  stop("README.md が見つかりません。プロジェクト直下で実行してください。")
}

# 既存 README を読み込み
lines <- readLines(readme_path, warn = FALSE, encoding = "UTF-8")

# 既存の「参考ドキュメント」セクションを探す
start_idx <- grep(paste0("^", gsub("#", "\\\\#", section_title), "\\s*$"), lines)

if (length(start_idx) == 0) {
  # 末尾に追記（すでに同一リンクが本文にある場合も重複を気にせず末尾にまとめる）
  cat("\n", file = readme_path, append = TRUE)
  cat(section_md, file = readme_path, append = TRUE)
  message("✅ README.md に「参考ドキュメント」セクションを新規追加しました。")
} else {
  # 次の「## 」見出しまでの範囲を置換
  next_idx <- grep("^##\\s+", lines)
  next_idx <- next_idx[next_idx > start_idx[1]]
  end_idx <- if (length(next_idx) == 0) length(lines) else (min(next_idx) - 1)
  
  new_lines <- c(
    if (start_idx[1] > 1) lines[1:(start_idx[1]-1)] else character(0),
    strsplit(sub("^\\n*", "", section_md), "\n")[[1]],
    if (end_idx < length(lines)) lines[(end_idx+1):length(lines)] else character(0)
  )
  
  writeLines(new_lines, con = readme_path, useBytes = TRUE)
  message("🔄 README.md の「参考ドキュメント」セクションを更新しました。")
}

invisible(TRUE)