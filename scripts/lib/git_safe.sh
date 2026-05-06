#!/usr/bin/env bash
# Auto-commit safety per spec §18. Operates only on docs/ and adr/ paths.

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
# docs/ or adr/. Returns 1 if anything else is dirty.
git_dirty_outside_docs() {
    local dirty
    dirty="$(git status --porcelain | awk '{print $2}')"
    [ -z "$dirty" ] && return 0
    local p
    while IFS= read -r p; do
        case "$p" in
            docs/*|adr/*) ;;
            *) return 1 ;;
        esac
    done <<<"$dirty"
    return 0
}

# safe_commit_docs <message>
# Commits docs/ and adr/ to the default branch. Refuses if dirty paths exist
# outside those directories. No-op if there are no docs/ or adr/ changes.
safe_commit_docs() {
    local message="$1"
    if ! git_dirty_outside_docs; then
        echo "ERROR: dirty path(s) outside docs/ or adr/ — commit those first:" >&2
        git status --porcelain | grep -vE '^.. (docs/|adr/)' >&2
        return 1
    fi

    local has_changes=0
    if ! git diff --quiet -- docs/ adr/ 2>/dev/null; then
        has_changes=1
    fi
    if ! git diff --cached --quiet -- docs/ adr/ 2>/dev/null; then
        has_changes=1
    fi
    if git ls-files --others --exclude-standard -- docs/ adr/ | grep -q .; then
        has_changes=1
    fi

    if [ "$has_changes" -eq 0 ]; then
        echo "[larv] nothing to commit in docs/ or adr/"
        return 0
    fi

    git add docs/ adr/ 2>/dev/null || true
    # Commit without explicit pathspec: git_dirty_outside_docs already guarantees
    # only docs/ and adr/ are staged, so no other changes can slip in.
    git commit -m "$message"
}
