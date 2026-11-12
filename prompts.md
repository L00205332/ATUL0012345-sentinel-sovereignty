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

### Prompt 10 (2026-11-10)
> [pasted terminal log: terraform init against HCP, validate, providers lock, branch/commit/push/PR #2 merge]
> done, PR merged, let's connect HCP.

**What the AI did:** Wrote the pieces needed before the first HCP run:
- `iam/hcp-terraform-policy.json`: a least-privilege policy for the HCP IAM user. EC2/KMS are allowed only in eu-west-1/eu-central-1, IAM is limited to the project's name prefix, only `AmazonSSMManagedInstanceCore` can be attached, and PassRole works only to EC2.
- `sentinel/sentinel.hcl`: the single policy set, with network as hard-mandatory.
- `scripts/destroy.ps1`: a destroy run via the HCP API, with typed confirmation, then waiting and an audit.
- `scripts/audit-regions.ps1`: leftovers in the EU regions, plus any snapshot, volume or instance in us-east-1 reported as drift.

Parse-checked both scripts, validated the JSON and re-ran `sentinel test` (8/8 PASS). Documented the HCP workspace/policy set settings and the cleanup procedure in the README.

### Prompt 11 (2026-11-11)
> [screenshot: HCP "Create a policy set" page; the VCS provider option is disabled on the Free tier ("no remaining versioned policy sets"); Automated and Individually managed are available]

**What the AI did:** Recommended the Automated (API-managed) policy set over pasting policies into the UI, so that GitHub stays the source of truth. Wrote `scripts/upload-policies.ps1`, which runs `sentinel test`, packages `sentinel.hcl` and the `*.sentinel` files (tests and the local `.sentinel/` cache excluded), creates a policy set version through the HCP API, uploads it and waits until it's ready. Dry-ran the packaging step, added `.sentinel/` to `.gitignore`, and documented the policy deployment flow and the Free-tier constraint in the README.

### Prompt 12 (2026-11-11)
> [pasted output of scripts/upload-policies.ps1: sentinel test 8/8 PASS, policy set found, upload rejected with 403 "The organization has reached the limit of 0 versioned policy sets."]

**What the AI did:** Identified that the Free tier allows no versioned policy sets at all (neither VCS nor folder upload), only individually managed policies. Rewrote `scripts/upload-policies.ps1` to read the policy blocks from `sentinel.hcl` and create or update each policy through the HCP Policies API: attach it to the set, upload the `.sentinel` code, and warn about stale policies. Added a `-ParseOnly` mode and verified the parsing offline. Updated the README with the Free-tier finding and its consequences (drift risk, no shared modules or params, Sentinel 0.40.x on HCP vs 0.41.0 locally).

### Prompt 13 (2026-11-11)
> [screenshots: first HCP run "First compliant run: baseline stack with network policy": plan 23 to create, Sentinel policies passed 1/1, aws_ebs_snapshot.data region "eu-west-1"]
> done, mocks extracted into the folder

**What the AI did:** Moved the real mocks to `sentinel/mocks/compliant-baseline/` (a folder under `test/` would be read as a policy's tests). Scanned them for credentials, the account ID and emails: only variable names and `"sensitive": true`, no values. Analysed the real plan and config:
- `region` is known for every regional resource, and only IAM has none.
- A snapshot's `encrypted` is unknown at plan time.
- `tfconfig/v2` shows only root provider blocks and module calls.

Added `pass-real-baseline.hcl` (network vs the real plan, 9/9 PASS), git-ignored the mock archive, and documented the run and the findings in the README.

### Prompt 14 (2026-11-11)
> [screenshots: run "First compliant run" Apply finished, 23 created; terminal output of the AWS CLI checks and scripts/audit-regions.ps1 -AwsProfile atu listing 8 LEFTOVER items in eu-west-1/eu-central-1 and nothing in us-east-1]
> check now

**What the AI did:** Confirmed the deployed state matches the design: compute and data in eu-west-1, only an encrypted DR snapshot copy and its key alias in eu-central-1, no off-region resources. Recorded the before/after audit and the applied run in the README. Earlier in this step it renamed the audit script's `-Profile` parameter to `-AwsProfile`, because `$PROFILE` is a built-in PowerShell variable.

### Prompt 15 (2026-11-11)
> done, PR merged, let's write the sovereignty policy

**What the AI did:** Wrote `sentinel/sovereignty.sentinel` (hard-mandatory) with five rules, based on the real plan structure:
- approved EU regions, with global services exempted and unknown regions failing safe
- the DR region holding backups only
- sensitive-data residency through the `data_classification` tag
- DLM and AWS Backup copy targets
- IAM trust limited to service principals (administrative access)

The first parse failed because `rule` is a Sentinel keyword used as a variable name, so the loop variables were renamed. Generated 10 hand-written mocks and test cases with a script, and added a test against the real plan. Two tests failed because `main = rule { a and b }` short-circuits, so later rules were never evaluated; `main` now uses `all [ ... ]` in both policies, so every violation is reported. Result: 20/20 tests PASS. A mutation test (adding `us-east-1` to the approved regions) made 4 tests fail, showing the tests catch a weakened policy. Registered the policy in `sentinel.hcl` and documented the rules, design decisions, results and limitations in the README.

### Prompt 16 (2026-11-11)
> [screenshot: upload-policies.ps1 output, 20/20 tests PASS, then 403 "The organization has reached the limit of 1 mandatory policy."]
> [answer to the AI's question "HCP Free allows only 1 mandatory policy. How should we enforce the policies?"]: Bundle into 1 policy (Recommended)

**What the AI did:** Wrote `scripts/build-bundle.ps1`, which merges every mandatory policy from `sentinel.hcl` into one hard-mandatory policy `atul0012345-guardrails`:
- deduplicates imports and moves `param`s to the top (the first build failed because Sentinel needs params before statements)
- checks for name clashes
- generates one `main` over all rules
- generates and runs bundle tests derived from each policy's own tests (20/20 PASS)

Rewrote `scripts/upload-policies.ps1`: it refuses uncommitted changes, records the git commit in the policy description, tests, builds, deletes stale policies only with `-RemoveStale`, deploys the bundle plus advisory policies, and has a `-DryRun` mode (verified). Git-ignored `sentinel/build/`. Documented the three Free-tier limits, the bundling design and its trade-offs (one enforcement level, `instance_type` moved to advisory) in the README.

### Prompt 17 (2026-11-11)
> [screenshots: HCP speculative run for PR #9 "TEST - non-compliant: DR snapshot copy to us-east-1": plan +3/-3, "Sentinel policies hard failed", atul0012345-guardrails output with 3× resources_in_approved_regions and 1× sensitive_data_resident FAIL lines, run Errored]
> check as PR created and run kicked off on HCP

**What the AI did:** Confirmed on GitHub that PR #9's HCP Terraform check failed ("1 failed"). Interpreted the run:
- the region change forces replacement of the DR key, alias and copy
- every violation is listed in one run
- deletes are correctly ignored
- the plan succeeded despite the IAM region restriction, because plans make no create calls, so Sentinel stopped it before the IAM layer would have

Recorded the run, the policy output and the explanation of how enforcement prevents the deployment in the README evidence section.

### Prompt 18 (2026-11-11)
> [screenshot: GitHub pull requests list, PR #9 with "All checks have failed: Terraform Cloud/L00205332/… 1 failed"]
> check git hub screenshot, I have also downloaded sentinel mocks to .\sentinel\mocks\offregion-snapshot and did Close the PR without merging

**What the AI did:** Confirmed PR #9 is closed without merging and `main` is unchanged. Scanned the new mocks: no credentials, but the plan and state contained the AWS account ID (330×) and the instance's public IP/DNS, because the stack was running. Redacted them with AWS documentation values, since no policy reads them. Added `fail-real-offregion.hcl`, which reproduces the same 4 FAIL lines as the HCP run (21/21 PASS, bundle tests PASS). Documented the result and the mock-redaction lesson in the README.

### Prompt 19 (2026-11-11)
> yes, go ahead and write an unencrypted volume, IMDSv1 and t3.large (advisory: the run continues, with a warning) policies

**What the AI did:** Inspected the real plan and config first. `kms_key_id` is unknown in the plan both when it references a new key and when it isn't set, so key checks must read `tfconfig/v2`. Wrote three policies, all with `enc_`/`md_`/`it_`-prefixed names so they can be bundled:
- `encryption.sentinel` (hard-mandatory): `ebs_encrypted` from tfplan, `ebs_customer_managed_key` from tfconfig, covering volumes, instance root/extra disks, launch templates and snapshot copies, with a fail-safe for an unconfigured root disk
- `metadata.sentinel` (hard-mandatory): `imdsv2_required`, `imds_hop_limit_restricted`, with a missing `metadata_options` failing
- `instance_type.sentinel` (advisory): approved list, unknown type fails safe

Generated 17 hand-written tfplan+tfconfig mocks with a script, and added real-plan tests. `strings.contains` doesn't exist in Sentinel, so the `contains` operator is used instead. Added the real config mock to the existing real-plan tests. Extended `build-bundle.ps1` with empty mocks for imports a test doesn't mock, and with a name-clash check for loop variables. Result: 40/40 policy tests and 36/36 bundle tests (4 policies, 11 rules). Mutation tests on metadata and encryption were caught. Updated `sentinel.hcl` (instance_type advisory) and the README.

### Prompt 20 (2026-11-12)
> [screenshots: HCP run for PR #12 "TEST - non-compliant: unencrypted EBS volume": plan +4/-4, policy checks 1 of 2 passed, atul0012345-guardrails hard failed with "FAIL ebs_encrypted: aws_ebs_volume.data is not encrypted", run Errored; GitHub PR #12 "All checks have failed" with the Merge pull request button still enabled]
> here is the failures from HCP and GitHub, now let's move to test B (allow IMDSv1) once done will provide the screenshot for our own readme

**What the AI did:** Interpreted the result:
- the volume replacement cascades to its attachment, snapshot and DR copy
- only `ebs_encrypted` fails, since the key is still configured
- the advisory policy passed separately

Spotted that GitHub still allowed merging a PR with a failed check, and explained the gap: policy checks gate the apply, not the merge. Recommended branch protection requiring the HCP check. Recorded the run, the finding and a new limitation in the README.

### Prompt 21 (2026-11-12)
> [screenshots: PR #13 "TEST - non-compliant: IMDSv1 allowed" with all checks failed; HCP run: 1 to change (aws_instance.app), guardrails hard failed with "FAIL imdsv2_required: … http_tokens = optional" AND "FAIL imds_hop_limit_restricted: aws_instance.app has http_put_response_hop_limit = 1, maximum allowed is 1"]
> please check the evidences for Test B

**What the AI did:** Spotted that the second failure is a false positive: hop limit 1 is allowed. Diagnosed the cause as HCP passing plan numbers as floats while the downloaded mocks store ints, so the `type_of(...) is "int"` check passed all local tests but failed every HCP run, including compliant ones. Fixed it to accept int or float. Added float regression tests for metadata and for network, which compares ports; network already handled floats. Confirmed that reverting the fix reproduces HCP's exact message. 44/44 tests. Documented the bug, the fix and the lesson ("mocks are not the platform") in the README.

### Prompt 22 (2026-11-12)
> [screenshots: PR #13 re-run after the fix: GitHub check failed; HCP run-Am7V2uCBV3XFgcYm with 1 to change and only "FAIL imdsv2_required"]
> check the screenshots after fixing the float number issue:

**What the AI did:** Confirmed the re-run shows only the correct violation, proving that the fixed bundle is live on HCP. Recorded the re-run in the README.

### Prompt 23 (2026-11-12)
> why can't i find any evidence screenshots inside git hub readme?

**What the AI did:** Explained that the screenshots had only been shared in the chat and never added to the repo, and that the README evidence section was still text-only with a TODO. Proposed building `documentation/evidence/` from the screenshots already shared: leave out the ones showing IAM access key IDs, and redact the AWS account ID.

### Prompt 24 (2026-11-12)
> yes, go ahead and build the evidence folder

**What the AI did:** Copied 27 screenshots into `documentation/evidence/` with numbered names. Redacted the account ID line in the two audit screenshots using Windows' System.Drawing (checked visually), and excluded the access-key and setup-only screenshots. Wrote `documentation/evidence/test-results.md`: a summary table, the HCP Free limits, the integration, and scenarios 1–4 with their screenshots, expected vs actual results and findings, with placeholders for test C and the drift demo. Checked that every image link resolves, and linked the page from README §6.

### Prompt 25 (2026-11-12)
> done, PR merged but why i can't see the evidences inside the readme.md?

**What the AI did:** Explained that the README only linked to the evidence page and embedded no images. Added a "Key evidence at a glance" section to README §6 that embeds 9 screenshots as clickable thumbnails:
- the compliant applied run
- the three blocked policy outputs side by side
- the two failed GitHub PR checks
- the post-apply audit (redacted)
- the float bug before the fix
- the policy set

The full set stays in `test-results.md`. Checked that every embedded path exists.

### Prompt 26 (2026-11-12)
> i think we need to migrate whole tests and test-results inside readme.md

**What the AI did:** Rebuilt README §6 as "Testing and evidence" containing everything:
- 6.1 a summary and how prevention works
- 6.2 the platform limits and HCP integration
- 6.3–6.8 one subsection per scenario, with its run table, policy output, embedded screenshots and findings
- 6.9 the full 44-test table, bundle tests and mutation tests as a table
- 6.10 the real-mock findings

All 27 screenshots are embedded as clickable thumbnails. Fixed a rendering bug: blank lines inside three tables had made rows display as raw text on GitHub. Verified every image path and internal anchor. Reduced `documentation/evidence/test-results.md` to an index that links into README §6, keeping the brief's folder structure without duplicated content.

---

<!-- Add new prompts below in the same format: number, date, verbatim prompt, short note on what the AI did. -->
