# Claude Code Deep Review After Implementation

Use when the user asks OMC Claude Code to "deep review", "deep interaction", "再跑一遍", "看看遗漏", or "可重构的地方" after an implementation/commit.

## Purpose

This is not another implementation pass. It is a review/refactor-opportunity pass that should inspect the task/spec, previous verification, the committed diff, and key code paths, then write a durable report. Run it in the verification lane (`verifier` or `code-reviewer`), separate from any spec-authoring context.

## Default Inputs

- task note or approved spec from the selected documentation surface.
- Previous implementation/verification report, if present.
- Repo path and commit SHA or branch.
- Existing project orchestration folder, e.g. `<project>/AI编排/Reports/`.

## Command Shape

Prefer a native subagent (`code-reviewer`/`verifier`, `model=opus` for large/security work) when the user asks from chat and does not need a separate process. Give it a prompt like:

```text
Run a deep code review for <task-id> after commit <sha>. This is a review/refactor opportunity pass, not implementation. Read task note: <task-path>. Read previous verification: <verification-path>. Inspect commit diff with git show --stat and targeted git show. Focus on omissions, semantic gaps, bugs, over-complexity, refactor opportunities, and missing tests. Pay special attention to: <risk areas>. Do not modify source code. Write a concise Markdown report to: <report-path>. Required sections: Verdict, Must Fix, Should Improve, Refactor Opportunities, Test Gaps, Release Recommendation, Exact Commands Reviewed. Use bullets, no markdown tables.
```

If you need an isolated brain process (clean context, parallel review, or a second opinion that must not see the current context), run the same prompt through headless `claude -p --permission-mode plan` so the review lane cannot modify source.

## Report Requirements

Write to the selected documentation surface, not just stdout. For local markdown projects, use:

```text
<project>/AI编排/Reports/<task-id>-claude-deep-review.md
```

Required sections:

- `Verdict`: PASS / REQUEST CHANGES / BLOCK and why.
- `Must Fix`: release-blocking semantic, correctness, security, or data-integrity issues.
- `Should Improve`: non-blocking but important correctness/product gaps.
- `Refactor Opportunities`: simplifications, boundary cleanup, commit splitting, generated-artifact handling.
- `Test Gaps`: missing scenarios and blocked tests.
- `Release Recommendation`: whether to ship, demo only, or block.
- `Exact Commands Reviewed`: commands the review lane ran or reviewed.

## Review Focus Areas

- Product semantics, not only static acceptance mapping. Example: a tag named `coupon_received` does not prove "coupon received but unused" unless coupon-use facts are modeled.
- Snapshot fidelity. If a snapshot only stores count/query/explanation but not members, call out that it is not replayable/auditable.
- Pagination and total-hit correctness. Fixed `size=100` queries are often not valid audience-package snapshots.
- Tenant boundaries. Be suspicious of admin APIs that accept `tenantId` in request body and then set tenant context directly.
- Workflow contract shape. Prefer stable snapshot/customer references over returning live query result lists as workflow input.
- Commit hygiene. Flag when task logic is mixed with unrelated hardening, generated graph files, large docs/images, or migration/tooling changes.

## Pitfalls

- Do not let "static coverage looks OK" become `PASS` if tests are blocked or core semantics are approximate.
- Do not modify source code during a deep review unless the user explicitly changes the task from review to fix.
- Avoid Markdown tables in chat-relayed summaries and durable reports that will be relayed through chat gateways; bullets survive formatting better.
- If the user asks for "deep interaction" from chat, a native review-lane subagent or a one-shot headless `claude -p` review prompt is acceptable unless they explicitly need live interactive participation.
