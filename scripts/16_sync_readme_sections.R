# scripts/16_sync_readme_sections.R
# ------------------------------------------------------------
# 目的:
#   README.md の以下のセクションを外部ファイルから自動で追加/更新する
#   - 「## 結果解釈」         ← results/Results_Summary.md を取り込み
#   - 「## Methods」          ← docs/Methods.md を取り込み（先頭だけ要約+全文リンク）
#   - 「## Limitations」      ← docs/Limitations.md を取り込み（全文）
# 使い方:
#   source("scripts/16_sync_readme_sections.R")
# 備考:
#   - セクションが存在すれば置換、無ければ末尾に新規追加
#   - 文字コードはUTF-8想定
# ------------------------------------------------------------

readme_path <- "README.md"
res_summary_path <- "results/Results_Summary.md"
methods_path <- "docs/Methods.md"
limits_path <- "docs/Limitations.md"

stopifnot(file.exists(readme_path))

read_md_safe <- function(path) {
  if (!file.exists(path)) return(NULL)
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

# 既存READMEを読み取り
lines <- readLines(readme_path, warn = FALSE, encoding = "UTF-8")

replace_section <- function(all_lines, section_title_regex, new_block) {
  # section_title_regex: 例 "^##\\s*結果解釈\\s*$"
  start_idx <- grep(section_title_regex, all_lines)
  if (length(start_idx) == 0) {
    # 新規追加（末尾に空行+新規ブロック）
    con <- file(readme_path, open = "a", encoding = "UTF-8")
    on.exit(close(con), add = TRUE)
    cat("\n", file = con)
    cat(new_block, file = con)
    message("✅ 新規追加: ", gsub("\\\\", "", section_title_regex))
    return(invisible(TRUE))
  } else {
    # 次の「## ...」までを置換
    next_idx <- grep("^##\\s+", all_lines)
    next_idx <- next_idx[next_idx > start_idx[1]]
    end_idx <- if (length(next_idx) == 0) length(all_lines) else (min(next_idx) - 1)
    new_lines <- c(
      if (start_idx[1] > 1) all_lines[1:(start_idx[1]-1)] else character(0),
      strsplit(new_block, "\n")[[1]],
      if (end_idx < length(all_lines)) all_lines[(end_idx+1):length(all_lines)] else character(0)
    )
    writeLines(new_lines, con = readme_path, useBytes = TRUE)
    message("🔄 置換更新: ", gsub("\\\\", "", section_title_regex))
    return(invisible(TRUE))
  }
}

# ---- 1) 結果解釈（Results_Summary.md をそのまま差し込み） ----
rs <- read_md_safe(res_summary_path)
if (!is.null(rs)) {
  block_results <- paste0(
    "## 結果解釈\n\n",
    rs, "\n\n",
    "[詳細は results/Results_Summary.md を参照](", res_summary_path, ")"
  )
  replace_section(lines <- readLines(readme_path, warn = FALSE, encoding = "UTF-8"),
                  "^##\\s*結果解釈\\s*$",
                  block_results)
} else {
  message("⚠️ results/Results_Summary.md が見つかりません。スキップします。")
}

# 置換後のREADMEを再読込
lines <- readLines(readme_path, warn = FALSE, encoding = "UTF-8")

# ---- 2) Methods（先頭~40行を要約として入れ、全文リンク） ----
m <- read_md_safe(methods_path)
if (!is.null(m)) {
  m_lines <- strsplit(m, "\n")[[1]]
  head_n <- min(length(m_lines), 40)  # 長すぎを回避
  m_head <- paste(m_lines[1:head_n], collapse = "\n")
  block_methods <- paste0(
    "## Methods\n\n",
    m_head, "\n\n",
    "...（全文は ", methods_path, " を参照）"
  )
  replace_section(lines, "^##\\s*Methods\\s*$", block_methods)
} else {
  message("⚠️ docs/Methods.md が見つかりません。スキップします。")
}

# 置換後のREADMEを再読込
lines <- readLines(readme_path, warn = FALSE, encoding = "UTF-8")

# ---- 3) Limitations（全文差し込み） ----
lim <- read_md_safe(limits_path)
if (!is.null(lim)) {
  block_limits <- paste0("## Limitations\n\n", lim)
  replace_section(lines, "^##\\s*Limitations\\s*$", block_limits)
} else {
  message("⚠️ docs/Limitations.md が見つかりません。スキップします。")
}

message("==> Done: README の結果解釈 / Methods / Limitations を同期しました。")