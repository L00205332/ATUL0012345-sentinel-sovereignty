# Test scenarios

This folder is the human-readable index of what is tested and where. The executable tests live next to the policies in [`sentinel/test/<policy>/`](../sentinel/test/), because that is where `sentinel test` discovers them; the results and screenshots are in [README §6](../README.md#6-testing-and-evidence).

## How the testing is layered

| Layer | What runs | Where | When |
|---|---|---|---|
| 1. Policy unit tests | `sentinel test`: each policy against hand-written and **real** HCP mocks (57 cases) | `sentinel/test/<policy>/` | locally, and in CI on every PR |
| 2. Bundle tests | The merged hard-mandatory `atul0012345-guardrails` policy against every mandatory policy's tests (53 cases) | `scripts/build-bundle.ps1` → `sentinel/build/` | before every deploy, and in CI |
| 3. Mutation tests | A policy is deliberately weakened; the tests must fail | manual, results in README §6.10 | when a policy is written |
| 4. Live tests | A PR with one non-compliant change; HCP runs a speculative plan + the real policy check | GitHub PRs, closed without merging | per policy area |
| 5. Out-of-band audit | `scripts/audit-regions.ps1` reads the real AWS account | AWS | after apply/destroy, and for drift |

## Live scenarios

| # | Scenario | Change | Policy / rule exercised | Expected | Result | Replay test | Evidence |
|---|---|---|---|---|---|---|---|
| 1 | Compliant baseline | `main` | all | pass, apply | ✅ applied | `*/pass-real-baseline.hcl` | [§6.3](../README.md#63-scenario-1-compliant-baseline-applied) |
| 2 | DR copy outside the EU (PR #9) | `dr_region = "us-east-1"` | sovereignty: `resources_in_approved_regions`, `sensitive_data_resident` | blocked | ⛔ blocked | `sovereignty/fail-real-offregion.hcl` | [§6.4](../README.md#64-scenario-2-dr-copy-outside-the-eu-pr-9-blocked) |
| 3 | Unencrypted volume (PR #12) | `encrypted = false` | encryption: `ebs_encrypted` | blocked | ⛔ blocked | `encryption/fail-unencrypted-volume.hcl` | [§6.5](../README.md#65-scenario-3-unencrypted-ebs-volume-pr-12-blocked) |
| 4 | IMDSv1 (PR #13) | `http_tokens = "optional"` | metadata: `imdsv2_required` | blocked | ⛔ blocked (float bug found + fixed) | `metadata/fail-imdsv1-optional.hcl`, `metadata/pass-float-hop.hcl` | [§6.6](../README.md#66-scenario-4-imdsv1-allowed-pr-13-blocked-and-a-policy-bug-found) |
| 5 | `t3.large` (PR #17) | `instance_type = "t3.large"` | instance_type (advisory) | warn only | ⚠️ warned, not blocked | `instance_type/fail-t3-large.hcl` | [§6.7](../README.md#67-scenario-5-advisory-t3large) |
| 6 | Manual off-region copy | AWS CLI, outside Terraform | none (Sentinel blind spot) → audit | audit finds `DRIFT` | 🔎 found, remediated | — (not a plan) | [§6.8](../README.md#68-scenario-6-drift-manual-off-region-copy) |
| 7 | Unpinned module (PR #21) | VPC module `6.0.0` → `~> 6.0` | supply_chain: `modules_pinned` | blocked | ⛔ blocked | `supply_chain/fail-module-range.hcl` | [§6.9](../README.md#69-scenario-7-unpinned-module-pr-21-blocked) |

## Unit test coverage per policy

| Policy | Level | Rules | Test cases | Real-plan cases |
|---|---|---|---|---|
| [`sovereignty`](../sentinel/sovereignty.sentinel) | hard-mandatory (bundle) | 5 | 12 | 2 |
| [`network`](../sentinel/network.sentinel) | hard-mandatory (bundle) | 2 | 11 | 1 |
| [`encryption`](../sentinel/encryption.sentinel) | hard-mandatory (bundle) | 2 | 9 | 1 |
| [`metadata`](../sentinel/metadata.sentinel) | hard-mandatory (bundle) | 2 | 8 | 1 |
| [`supply_chain`](../sentinel/supply_chain.sentinel) | hard-mandatory (bundle) | 5 | 13 | 2 |
| [`instance_type`](../sentinel/instance_type.sentinel) | advisory | 1 | 4 | 1 |
| **Total** | | **17** | **57** | **8** |

Every case is listed with its scenario and expected result in [README §6.10](../README.md#610-local-mock-tests-sentinel-test).

## Running the tests

```bash
cd sentinel
sentinel test                    # all policies
sentinel test -run supply_chain  # one policy
cd ..
pwsh ./scripts/build-bundle.ps1  # build the bundle + run the bundle tests
```
