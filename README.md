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

_TODO: finalise once the structure is built._

```
.
├── README.md
├── prompts.md                     # LLM usage log (declared as required by the brief)
├── .github/workflows/             # CI checks (fmt / validate / sentinel test)
├── documentation/
│   ├── evidence/                  # screenshots + pass/fail results
│   └── technical-report/          # ≤ 1 page limitations & recommendations
├── sentinel/                      # *.sentinel policies + sentinel.hcl
├── terraform/                     # *.tf, .terraform.lock.hcl, tfplan
└── tests/                         # Sentinel mocks + test cases per policy
```

## 3. Prerequisites

| Tool | Purpose | Verified version |
|------|---------|------------------|
| Terraform CLI | Write and plan infrastructure | 1.17.1 |
| Sentinel CLI | Run policy tests locally against mocks | 0.41.0 |
| AWS CLI | Credentials / account context (optional) | 2.13.25 |
| Git + GitHub CLI | Version control, public repo | git 2.56.0 / gh 2.103.3 |
| HCP Terraform (Free) | Remote runs + policy set enforcement | _TODO_ |

## 4. Policy design

### 4.1 Digital sovereignty
_TODO: approved regions, data residency for sensitive data, replication / backups / admin access, and how jurisdictional restrictions support sovereignty._

### 4.2 IaC supply chain security
_TODO: approved provider sources and versions, trusted pinned modules, provider integrity (lock file and checksums), module provenance, and risks Sentinel cannot address._

### 4.3 Infrastructure security
_TODO: approved EC2 instance types, encrypted EBS, mandatory IMDSv2, network security configuration, no unrestricted inbound SSH._

### 4.4 Enforcement levels
_TODO: advisory / soft-mandatory / hard-mandatory choice per policy, with justification._

## 5. How to run

_TODO: local `sentinel test`, HCP Terraform workspace and policy set setup, generating `tfplan`._

## 6. Evidence

_TODO: link to `documentation/evidence/`, covering passing and failing plans, policy check screenshots, and mock test output._

## 7. Decision justification

### 7.1 Effectiveness of Policy-as-Code for digital sovereignty
_TODO_

### 7.2 Limitations of region-based data residency controls
_TODO_

### 7.3 Importance of supply chain integrity
_TODO_

### 7.4 Limitations of Sentinel and plan-time enforcement
_TODO_

### 7.5 Maintaining policies as cloud environments evolve
_TODO_

## 8. Declaration of AI tool usage

As the brief requires, any use of LLM tools is declared here.

| Item | Detail |
|------|--------|
| Tool | Claude Code (Anthropic), desktop app |
| Model | Claude Opus 5.5 (`claude-opus-5-5`) |
| Used for | _TODO: summarise (e.g. reviewing the brief, explaining Sentinel concepts, reviewing code)_ |
| Prompts | Full prompt log in [`prompts.md`](prompts.md) |

**My own contribution:** _TODO: describe the design decisions, code, testing and analysis carried out by the student._

## 9. References

- Ireland signs Declaration for European Digital Sovereignty (2025)
- Dáil Éireann Debate, Telecommunications Infrastructure, 13 May 2026, Question 75
- HashiCorp Sentinel documentation: https://developer.hashicorp.com/sentinel
- HCP Terraform policy enforcement: https://developer.hashicorp.com/terraform/cloud-docs/policy-enforcement
