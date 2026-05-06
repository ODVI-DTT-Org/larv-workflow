#!/usr/bin/env bats

load helpers

TEMPLATES=(slice-handoff sandbox-runbook pre-flight project-lessons adoption-report ddd-interview-questions)

@test "all 6 templates exist" {
    for t in "${TEMPLATES[@]}"; do
        [ -f "templates/${t}.md" ] || { echo "missing templates/${t}.md"; return 1; }
    done
}

@test "slice-handoff has Plugin Improvement Notes section" {
    run grep -F "Plugin Improvement Notes" templates/slice-handoff.md
    [ "$status" -eq 0 ]
}

@test "sandbox-runbook documents URL, SSH, docker, firewall" {
    run grep -E "App URL|VM|Docker|Firewall" templates/sandbox-runbook.md
    [ "$status" -eq 0 ]
}

@test "project-lessons explains [project] vs [plugin] tagging" {
    run grep -E "\[project\]|\[plugin\]" templates/project-lessons.md
    [ "$status" -eq 0 ]
}

@test "adoption-report has confidence flags guidance" {
    run grep -F "confidence" templates/adoption-report.md
    [ "$status" -eq 0 ]
}

@test "ddd interview question bank documents all required output files" {
    grep -q "business-purpose.md" templates/ddd-interview-questions.md
    grep -q "ubiquitous-language.md" templates/ddd-interview-questions.md
    grep -q "subdomain-candidates.md" templates/ddd-interview-questions.md
}
