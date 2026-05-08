#!/usr/bin/env bash
# Auto-commit safety per spec §18. Operates only on documentation and generated AI starting-point paths.

# git_default_branch
# Detects the default branch. Tries: origin/HEAD symbolic ref, then init.defaultBranch.
git_default_branch() {
    local ref
    ref="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || true)"
    if [ -n "$ref" ]; then
        echo "${ref##*/}"
        return 0
    fi
    local init_default
    init_default="$(git config --get init.defaultBranch 2>/dev/null || true)"
    [ -n "$init_default" ] && { echo "$init_default"; return 0; }
    echo "main"
}

# git_dirty_outside_docs
# Returns 0 if all dirty paths (staged, unstaged, untracked) are inside
# docs/, adr/, root docs index, or generated AI starting-point files.
# Returns 1 if anything else is dirty.
git_is_allowed_generated_doc_path() {
    local p="$1"
    case "$p" in
        docs/*|adr/*|DOCS.md|CLAUDE.md|AGENTS.md|GEMINI.md|.codex/AGENTS.md|.cursor/rules/larv.mdc) return 0 ;;
        *) return 1 ;;
    esac
}

git_dirty_outside_docs() {
    local dirty
    dirty="$(git status --porcelain -uall | awk '{print $2}')"
    [ -z "$dirty" ] && return 0
    local p
    while IFS= read -r p; do
        git_is_allowed_generated_doc_path "$p" || return 1
    done <<<"$dirty"
    return 0
}

# safe_commit_docs <message>
# Commits docs/ plus generated AI documentation entry points to the default branch.
# Refuses if dirty paths exist outside the allowlist. No-op if there are no allowed changes.
safe_commit_docs() {
    local message="$1"
    if ! git_dirty_outside_docs; then
        echo "ERROR: dirty path(s) outside generated docs allowlist — commit those first:" >&2
        git status --porcelain -uall | while read -r status path; do
            git_is_allowed_generated_doc_path "$path" || printf "%s %s\n" "$status" "$path"
        done >&2
        return 1
    fi

    local allowed_paths=(docs/ adr/ DOCS.md CLAUDE.md AGENTS.md GEMINI.md .codex/AGENTS.md .cursor/rules/larv.mdc)
    if [ -z "$(git status --porcelain -uall)" ]; then
        echo "[larv] nothing to commit in generated docs"
        return 0
    fi

    local p
    for p in "${allowed_paths[@]}"; do
        [ -e "$p" ] && git add "$p"
    done
    # Commit without explicit pathspec: git_dirty_outside_docs already guarantees
    # only generated docs allowlist paths are staged, so no other changes can slip in.
    git commit -m "$message"
}
