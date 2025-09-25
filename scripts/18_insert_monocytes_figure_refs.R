# scripts/18_insert_monocytes_figure_refs.R
# ------------------------------------------------------------
# 目的:
#   docs/manuscript_draft.md の "## Monocytes" 見出し直後に
#   図参照 (Figure 1/2/3) の短文を自動で追記/更新する。
#   マーカーで囲んだ領域のみを置換するため、再実行は安全。
# ------------------------------------------------------------

# --- make WD robust: set repo root automatically ---
this_file <- tryCatch(normalizePath(sys.frames()[[1]]$ofile, mustWork = TRUE),
                      error = function(e) NA)
if (is.na(this_file)) {
  args <- commandArgs(trailingOnly = FALSE)
  this_file <- sub("^--file=", "", args[grep("^--file=", args)])
}
script_dir <- dirname(this_file); repo_root <- normalizePath(file.path(script_dir, ".."))
setwd(repo_root)
# ---------------------------------------------------

md_path <- "docs/manuscript_draft.md"
if (!file.exists(md_path)) {
  stop("docs/manuscript_draft.md が見つかりません。パスをご確認ください。")
}

# 追加する参照テキスト（必要に応じて編集可）
refs_block <- paste0(
  "<!-- BEGIN: Monocytes_Figure_Refs -->\n",
  "\n",
  "Differential expression analysis identified significant changes in Monocytes **(Figure 1)**.\n",
  "GO biological process enrichment highlighted interferon-related pathways **(Figure 2)**.\n",
  "KEGG analysis further confirmed enrichment of immune and signaling pathways **(Figure 3)**.\n",
  "\n",
  "<!-- END: Monocytes_Figure_Refs -->\n"
)

lines <- readLines(md_path, warn = FALSE, encoding = "UTF-8")

# "## Monocytes" の位置を特定
mono_idx <- grep("^##\\s*Monocytes\\s*$", lines)
if (length(mono_idx) == 0) {
  # Monocytes 見出しが無い場合は、Results セクションの末尾 or 文末に追記
  res_idx <- grep("^#\\s*Results\\s*$", lines)
  if (length(res_idx) > 0) {
    # Results セクションの末尾を推定：次のセクション開始まで
    next_sec <- grep("^#", lines)
    next_after_res <- next_sec[next_sec > res_idx[1]]
    insert_pos <- if (length(next_after_res) > 0) next_after_res[1] - 1 else length(lines)
    # 末尾に Monocytes ヘッダを作って挿入
    add <- c("", "## Monocytes", refs_block)
    lines <- append(lines, add, after = insert_pos)
    writeLines(lines, md_path, useBytes = TRUE)
    message("🆕 '## Monocytes' が見つからなかったため、Results 内に新規作成して参照文を挿入しました。")
    quit(save = "no")
  } else {
    # Results も無ければ文末に追加
    add <- c("", "## Monocytes", refs_block)
    lines <- c(lines, add)
    writeLines(lines, md_path, useBytes = TRUE)
    message("🆕 '## Monocytes' と 'Results' が無かったため、文末に作成・挿入しました。")
    quit(save = "no")
  }
}

# 既存の Monocytes セクション直後にマーカー範囲があるか確認
begin_pat <- "<!-- BEGIN: Monocytes_Figure_Refs -->"
end_pat   <- "<!-- END: Monocytes_Figure_Refs -->"

# Monocytes ヘッダ直後（空行を飛ばしつつ）に挿入・更新
insert_after <- mono_idx[1]
# 既存のマーカー領域の開始行と終了行を探す（Monocytes 部分に限定はせず文書全体で検索）
begin_idx <- grep(begin_pat, lines, fixed = TRUE)
end_idx   <- grep(end_pat,   lines, fixed = TRUE)

if (length(begin_idx) > 0 && length(end_idx) > 0) {
  # 既存のマーカー範囲を安全に置換
  b <- begin_idx[1]; e <- end_idx[1]
  if (b <= e) {
    new_lines <- c(lines[1:(b-1)], refs_block, lines[(e+1):length(lines)])
    writeLines(new_lines, md_path, useBytes = TRUE)
    message("🔄 既存の Monocytes 図参照ブロックを更新しました。")
  } else {
    # 万一順序がおかしければ Monocytes 直後に新規挿入
    new_lines <- append(lines, strsplit(refs_block, "\n")[[1]], after = insert_after)
    writeLines(new_lines, md_path, useBytes = TRUE)
    message("⚠️ 既存マーカーの範囲が不正でした。Monocytes 見出し直後に新規挿入しました。")
  }
} else {
  # マーカーが無ければ Monocytes 見出し直後に新規挿入
  new_lines <- append(lines, strsplit(refs_block, "\n")[[1]], after = insert_after)
  writeLines(new_lines, md_path, useBytes = TRUE)
  message("➕ Monocytes 見出し直後に図参照ブロックを追加しました。")
}

invisible(TRUE)