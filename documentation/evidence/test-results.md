# Evidence: Test Results

All test results and screenshots are presented in the main README, so there is a single source of truth:
**[README §6 – Testing and evidence](../../README.md#6-testing-and-evidence)**

| Section | Content | Screenshots in this folder |
|---|---|---|
| [6.1 Summary](../../README.md#61-summary) | All scenarios, expected vs actual; how a non-compliant change is prevented | — |
| [6.2 Platform limits and HCP integration](../../README.md#62-platform-limits-and-hcp-integration) | HCP Free limits, workspace, policy set, policy deployment, budget | 01–11, 32 |
| [6.3 Scenario 1: Compliant baseline](../../README.md#63-scenario-1-compliant-baseline-applied) | Plan, policy passed, applied, audit before/after | 12–16 |
| [6.4 Scenario 2: DR copy outside the EU (PR #9)](../../README.md#64-scenario-2-dr-copy-outside-the-eu-pr-9-blocked) | Blocked by sovereignty rules | 17–19 |
| [6.5 Scenario 3: Unencrypted volume (PR #12)](../../README.md#65-scenario-3-unencrypted-ebs-volume-pr-12-blocked) | Blocked by `ebs_encrypted`; merge-button finding | 20–22 |
| [6.6 Scenario 4: IMDSv1 (PR #13)](../../README.md#66-scenario-4-imdsv1-allowed-pr-13-blocked-and-a-policy-bug-found) | Blocked by `imdsv2_required`; float bug found and fixed | 23–27 |
| [6.7 Scenario 5: Advisory `t3.large`](../../README.md#67-scenario-5-advisory-t3large) | Warn, not blocked; unpinned-AMI replacement finding | 28–31 |
| [6.8 Scenario 6: Drift](../../README.md#68-scenario-6-drift-manual-off-region-copy) | Manual off-region copy: invisible to Terraform/Sentinel, caught by the audit, remediated | 33–35 |
| [6.9 Local mock tests](../../README.md#69-local-mock-tests-sentinel-test) | All 44 `sentinel test` cases, bundle tests, mutation tests | — |
| [6.10 What the real mocks showed](../../README.md#610-what-the-real-mocks-showed) | Findings from real HCP plan data; mock redaction | — |

The screenshots are numbered in the order they appear in the README. In audit screenshots 12 and 16 the AWS account ID is redacted; screenshots showing IAM access key IDs were not included.
