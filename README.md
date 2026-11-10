# ATUL0012345 – Sentinel Policy-as-Code for Digital Sovereignty & IaC Supply Chain Security

> ATU – IaC for DevOps Pipelines – Terraform Sentinel Assignment 2026
> Student: L00205332 · Organisation: ATUL0012345
> Repository: https://github.com/L00205332/ATUL0012345-sentinel-sovereignty

**Status:** 🚧 Work in progress. Sections marked _TODO_ get filled in as each part is designed, built and tested.

---

## 1. Purpose

This repository contains a Policy-as-Code (PaC) framework built with **Terraform** and **HashiCorp Sentinel**, integrated with **HCP Terraform (Free tier)**. It blocks non-compliant AWS infrastructure **before it is applied**, in three areas:

1. **Digital sovereignty:** workloads and data stay in approved (Irish/EU) jurisdictions.
2. **IaC supply chain security:** only trusted, pinned providers and modules are used.
3. **Infrastructure security:** baseline EC2, storage and network hardening.

Context: Ireland signed the *Declaration for European Digital Sovereignty* (2025). In the Dáil debate of 13 May 2026, "Digital Security & Resilience" was named a key priority for Ireland's EU Council presidency.

## 2. Repository structure

✅ = built · ⏳ = planned

```
.
├── README.md                          ✅
├── prompts.md                         ✅ LLM usage log (declared as required by the brief)
├── .github/workflows/                 ⏳ CI checks (fmt / validate / sentinel test)
├── documentation/
│   ├── evidence/                      ⏳ screenshots + test-results.md
│   └── technical-report/              ⏳ ≤ 1 page limitations & recommendations
├── scripts/                           ⏳ destroy.ps1, audit-regions.ps1 (cleanup + off-region drift check)
├── sentinel/
│   ├── sentinel.hcl                   ⏳ the single policy set: policies + enforcement levels
│   ├── network.sentinel               ✅
│   ├── sovereignty.sentinel           ⏳
│   ├── supply_chain.sentinel          ⏳
│   ├── instance_type.sentinel         ⏳
│   ├── encryption.sentinel            ⏳
│   ├── metadata.sentinel              ⏳
│   └── test/<policy>/                 ✅ network · ⏳ others: *.hcl test cases + mock-*.sentinel
├── terraform/                         ⏳ *.tf, .terraform.lock.hcl, tfplan
└── tests/test-scenarios.md            ⏳ scenario → expected result → evidence
```

**Why tests live in `sentinel/test/` and not `tests/`:** `sentinel test` discovers test cases in `test/<policy_name>/` next to the policy file. Keeping them there means `sentinel test` runs with no extra configuration, locally and in CI. The brief's `tests/` folder holds the human-readable scenario list instead.

## 3. Prerequisites

| Tool | Purpose | Verified version |
|------|---------|------------------|
| Terraform CLI | Write and plan infrastructure | 1.17.1 |
| Sentinel CLI | Run policy tests locally against mocks | 0.41.0 |
| AWS CLI | Credentials / account context | 2.13.25 |
| Git + GitHub CLI | Version control, public repo | git 2.56.0 / gh 2.103.3 |
| HCP Terraform (Free) | Remote runs + policy set enforcement | Org `L00205332`, Free tier (1 policy set) |
| AWS account | Real resources (plan + apply) | $10/month budget alert in place |

## 4. Policy design

### 4.1 Digital sovereignty

Agreed region model (policy ⏳):

| Region | Role | Policy result |
|---|---|---|
| `eu-west-1` (Dublin) | Primary: compute, network, data | ✅ Allowed |
| `eu-central-1` (Frankfurt) | EU disaster recovery: **backup copies only** (e.g. EBS snapshot copies) | ✅ Allowed for backups, ❌ for compute |
| `us-east-1` / any other | Outside EU jurisdiction | ❌ Denied (hard-mandatory) |

- **Test case:** an EBS snapshot copy to `us-east-1` must be denied at plan time.
- **Drift demonstration:** the same copy made manually with the AWS CLI (outside Terraform) is *not* seen by Sentinel. `scripts/audit-regions.ps1` detects it and flags it as off-region drift, which shows why sovereignty needs controls beyond plan-time policy.
- **Administrative access:** no SSH. Admin access goes through AWS SSM Session Manager (audited, no open port).

_TODO: data residency for sensitive data (`data_classification` tag), and how jurisdictional restrictions support sovereignty._

### 4.2 IaC supply chain security
_TODO: approved provider sources and versions, trusted pinned modules, provider integrity (lock file and checksums), module provenance, and risks Sentinel cannot address._

### 4.3 Infrastructure security

#### Network: [`sentinel/network.sentinel`](sentinel/network.sentinel) ✅

| Rule | Blocks | Why |
|---|---|---|
| `no_public_ssh` | SSH (22/tcp) reachable from `0.0.0.0/0` or `::/0`, including via port ranges or "all protocols" (`-1`) | Brief requirement: no unrestricted inbound SSH. Admin access uses SSM instead. |
| `public_ingress_restricted` | Any internet-facing ingress that is not a single approved TCP port (default `443`) | "Appropriate network security": blocks RDP, database ports, wide ranges and all-traffic rules. |

Design decisions:
1. **Three resource types checked.** AWS ingress can be written as `aws_vpc_security_group_ingress_rule`, as an inline `ingress` block on `aws_security_group`, or as a legacy `aws_security_group_rule`. Checking only one would let a change of resource type bypass the policy. All three are normalised into one shape before evaluation.
2. **Fail safe.** A TCP rule with missing ports, or protocol `-1`/`all`, is treated as "all ports".
3. **Deletes ignored.** Removing a rule can only reduce exposure, and its planned `after` value is `null`.
4. **Unknown values.** A CIDR not known at plan time (computed from another resource) is not treated as the internet. This is a known limitation of plan-time checks (see 7.4).
5. **Configurable.** `param public_ingress_ports` can be changed in `sentinel.hcl` without editing the policy.
6. **Egress out of scope.** Outbound allow-all is the AWS default, and the brief targets inbound access.

#### EC2 instance types, EBS encryption, IMDSv2
_TODO_

### 4.4 Enforcement levels

Planned (final values set in `sentinel.hcl`):

| Policy | Level | Reason |
|---|---|---|
| sovereignty | hard-mandatory | Legal/jurisdictional requirement, no override |
| supply_chain | hard-mandatory | An untrusted provider or module can compromise everything |
| encryption | hard-mandatory | Data protection baseline |
| metadata (IMDSv2) | hard-mandatory | Blocks credential theft via SSRF |
| network | hard-mandatory | Public SSH is a direct attack surface |
| instance_type | soft-mandatory | Cost/standards control. An admin may override a justified exception, and every override is logged in HCP. |

## 5. How to run

### Run the Sentinel tests locally

```bash
cd sentinel
sentinel test -verbose          # all policies
sentinel test -run network      # one policy
```

A test case passes when the policy returns the result the test expects. So `fail.hcl` **passing** means the policy correctly **rejected** the non-compliant mock.

### Git workflow
- Feature work: branch → PR → review → merge to `main`. Once HCP is connected, a merge to `main` triggers a real plan → policy check → apply.
- Non-compliant tests: a branch + PR per violation. HCP runs a speculative plan, the policy check fails (❌ on the PR), and the PR is closed without merging.

_TODO: HCP Terraform workspace and policy set setup, generating `tfplan`, destroy/cleanup._

## 6. Evidence

### Mock-based test results

| Policy | Test case | Scenario | Expected `main` | Result |
|---|---|---|---|---|
| network | `pass.hcl` | SSH from VPC only, public HTTPS (v4+v6), inline SG internal-only, legacy egress-all, deleted open SSH rule | true | ✅ PASS |
| network | `fail.hcl` | SSH from `0.0.0.0/0` | false | ✅ PASS |
| network | `fail-ipv6.hcl` | SSH from `::/0` | false | ✅ PASS |
| network | `fail-port-range.hcl` | TCP 0–65535 from internet | false | ✅ PASS |
| network | `fail-all-protocols.hcl` | `ip_protocol = "-1"` from internet | false | ✅ PASS |
| network | `fail-public-rdp.hcl` | RDP 3389 from internet (SSH rule passes, ingress rule fails) | false | ✅ PASS |
| network | `fail-inline-sg.hcl` | SSH via inline `aws_security_group` ingress | false | ✅ PASS |
| network | `fail-legacy-rule.hcl` | SSH on IPv6 via legacy `aws_security_group_rule` | false | ✅ PASS |

_TODO: screenshots in `documentation/evidence/`, HCP policy check runs (compliant + non-compliant), real downloaded mocks._

## 7. Decision justification

### 7.1 Effectiveness of Policy-as-Code for digital sovereignty
_TODO_

### 7.2 Limitations of region-based data residency controls
_TODO_

Points identified so far:
- A region check only sees what Terraform deploys. A manual CLI/console copy to `us-east-1` bypasses it (drift demo, see 4.1).
- The EU region is still operated by a US-headquartered provider (US CLOUD Act exposure).

### 7.3 Importance of supply chain integrity
_TODO_

### 7.4 Limitations of Sentinel and plan-time enforcement
_TODO_

Points identified so far:
- Values computed during apply (e.g. a CIDR taken from another resource) are unknown at plan time, so a policy can only partially judge them (see network decision 4).
- Sentinel cannot see changes made outside Terraform (drift).

### 7.5 Maintaining policies as cloud environments evolve
_TODO_

## 8. Declaration of AI tool usage

As the brief requires, any use of LLM tools is declared here.

| Item | Detail |
|------|--------|
| Tool | Claude Code (Anthropic), desktop app |
| Model | Claude Opus 5.5 (`claude-opus-5-5`) |
| Used for | Reviewing the brief, explaining Terraform/Sentinel concepts, writing the code (Sentinel policies, mocks, tests, Terraform, scripts, CI) and keeping this README up to date |
| Prompts | Full prompt log in [`prompts.md`](prompts.md) |

**My own contribution:** I made the design decisions (region model with Frankfurt as EU DR and `us-east-1` as the denied test region, real AWS resources with a cleanup script per stack, static HCP credentials as an accepted trade-off, PR-based testing), walked through the assignment step by step, read and reviewed all generated code, ran the tests, and performed all git operations, PRs and merges myself.

_TODO: add the analysis in section 7 and the technical report._

## 9. References

- Ireland signs Declaration for European Digital Sovereignty (2025)
- Dáil Éireann Debate, Telecommunications Infrastructure, 13 May 2026, Question 75
- HashiCorp Sentinel documentation: https://developer.hashicorp.com/sentinel
- HCP Terraform policy enforcement: https://developer.hashicorp.com/terraform/cloud-docs/policy-enforcement
