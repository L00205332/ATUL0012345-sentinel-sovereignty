# LLM Prompt Log

This log is kept because the assignment brief requires it: *"Where LLM tools are used, it is important to state the LLM name, version and prompt used. Never hide the use of tools."*

| Item | Detail |
|------|--------|
| Tool | Claude Code (Anthropic), Claude desktop app, Code tab |
| Model | Claude Opus 5.5 (`claude-opus-5-5`) |
| Scope | Only prompts that shaped the assignment are logged (design, code, testing, analysis). Confirmations ("done"), troubleshooting, explanation questions and housekeeping (about this log, the README or the git workflow) are left out. Prompts are copied verbatim (typos kept). |

---

## Session 1: Project kickoff

### Prompt 1 (2026-11-08)
> That's where we will apply Terraform sentinel assignment

**What the AI did:** Listed the project folder, read the assignment brief (PDF) and summarised the scope. It checked which tools were installed locally (Terraform 1.6.1, git, GitHub CLI and AWS CLI were present; Sentinel CLI was missing at that point), then proposed a structure and asked clarifying questions.

### Prompt 2 (2026-11-10)
> ok first we will create readme.md and prompts.md for all prompts we have here in this chat (will focus on project/assignment related). for all git commands i will be doing it myself, you can share the related commands, for now what i have is terraform , sentinel , AWS CLI , github public repo called ATUL0012345-sentinel-sovereignty (https://github.com/L00205332/ATUL0012345-sentinel-sovereignty ) which you should have access to. now i want you to review Terraform Sentinel Assignment 2026.pdf and let's have a discussion about what are we gonna do. you can start also with perquisites verfication set of commands

**What the AI did:** Created a skeleton `README.md` (sections mapped to the brief's deliverables, with an AI-usage declaration) and this `prompts.md`. It reviewed the brief for a design discussion and provided prerequisite verification commands for the student to run. All git operations are done by the student.

### Prompt 3 (2026-11-10)
> [screenshot: HCP Terraform org L00205332, Policy sets page, "You have 1 policy set left in your plan"]
> as we are using free tier HCP account we only have 1 policy set. for this assignment i prefer using real resources on AWS but for every stack we build we need to have a cleanup/destroy script, we are going to use eu-west-1 as our main region and for testing/validation let's try to have some sort of data stored outside for example instance snapshot in frankfurt. how i am thinking we can proceed is: [the six-step plan: Sentinel basics on the network policy → Terraform code → connect HCP → remaining policies → evidence → README and report]
> remind me of the needed screenshots for evidences for the testing and validations of sentinel policies. also do you think we need screenshots for all git commands i execute?

**What the AI did:** Confirmed that one policy set can hold all the policies. Discussed the design implications of the student's decisions: real AWS resources with a destroy script per stack, `eu-west-1` as the main region, and an EBS snapshot copy to Frankfurt as the sovereignty test case. Recommended OIDC dynamic credentials instead of static AWS keys. Produced an evidence/screenshot checklist and advised that git commands don't need screenshots, because the GitHub commit history is the evidence.

### Prompt 4 (2026-11-10)
> ok you are right let's use frankfurt for approved DR still in EU, and us-east-1 for the off regions snapshot test which should be denied and marked as a drift now tell me what will you build

**What the AI did:** Clarified the difference between a Sentinel denial (plan-time) and drift (real infrastructure diverging from the Terraform state), and proposed a manual out-of-band `us-east-1` snapshot copy as a genuine drift demonstration of what Sentinel cannot see. Laid out the full build plan (Terraform stack, six Sentinel policies with enforcement levels, mocks/tests, PR-based non-compliant testing, destroy/audit scripts, CI, documentation) for the student to approve.

### Prompt 5 (2026-11-10)
> [screenshot: AWS Budgets, "My Monthly Cost Budget" $10.00, status OK / Healthy]
> how HCP gets AWS credentials let's go with Static access keys saved as workspace variables also i have AWS budget in place

**What the AI did:** Accepted the static-keys decision and listed the controls that make it acceptable: a dedicated least-privilege IAM user, keys stored as sensitive env variables, never committed, deleted at the end. Noted this as a trade-off to justify in the README. Then gave Lesson 1 on Sentinel concepts (where policy checks sit in a run, the `tfplan/v2` / `tfconfig/v2` imports, `resource_changes`, rules and `main`, mocks and test cases) with an exercise for the student to write the first `network.sentinel` rule.

### Prompt 6 (2026-11-10)
> create the network test files and let me know when to run the test

**What the AI did:** Created the Sentinel test cases and hand-written `tfplan/v2` mocks for the network policy under `sentinel/test/network/`: one compliant scenario and four non-compliant ones (IPv4 SSH open, IPv6 SSH open, a wide port range including 22, `ip_protocol = "-1"`). Checked them with `sentinel fmt -check`. The policy itself (`network.sentinel`) is left for the student to write, test-first.

### Prompt 7 (2026-11-10)
> write the whole code, i won't write any code, update sentinel/network.sentinel

**What the AI did:** Wrote `sentinel/network.sentinel` with two rules: `no_public_ssh`, and `public_ingress_restricted` (only 443/tcp may be internet-facing, configurable via `param`). The policy normalises ingress from all three AWS resource types (`aws_vpc_security_group_ingress_rule`, inline `aws_security_group` ingress, legacy `aws_security_group_rule`) so that switching resource type can't bypass it. Added test cases for public RDP, an inline-SG bypass and a legacy-rule IPv6 bypass, and extended the pass mock to cover false positives. Result: `sentinel test -run network` 8/8 PASS.

### Prompt 8 (2026-11-10)
> [screenshot: PR #1 "Network policy: block public SSH and unapproved public ingress" merged into main; pasted git log of the branch/commit/push/PR steps]
> done, PR merged, log:

**What the AI did:** Following the agreed plan (next step after the network policy), wrote the Terraform stack in `terraform/`:
- `versions.tf`: Terraform `>= 1.17.0, < 2.0.0`, `hashicorp/aws ~> 6.0`, HCP cloud block for org `L00205332`.
- `providers.tf`: eu-west-1 plus default tags.
- `network.tf`: VPC module `terraform-aws-modules/vpc/aws` pinned to `6.0.0`, a security group with no ingress and only 443 egress.
- `main.tf`: customer-managed KMS key, SSM role, t3.micro EC2 with IMDSv2 and an encrypted root disk.
- `storage.tf`: a sensitive data volume.
- `backup.tf`: a snapshot plus an encrypted DR copy in eu-central-1, using the AWS provider v6 per-resource `region`.
- `.gitignore` and `.gitattributes` (LF endings).

Checked with `terraform fmt -check`, and updated the README design and supply-chain sections.

### Prompt 9 (2026-11-10)
> looks good now let's validate terraform code before we push and merge.

**What the AI did:** Ran `terraform init -backend=false` (VPC module 6.0.0 downloaded; `hashicorp/aws` v6.72.0 installed, signed by HashiCorp), then `terraform validate` (configuration valid) and `terraform providers lock -platform=linux_amd64 -platform=windows_amd64`. Noted in the README that the VPC module adds its own `>= 5.79.0` provider constraint.

---

<!-- Add new prompts below in the same format: number, date, verbatim prompt, short note on what the AI did. -->
