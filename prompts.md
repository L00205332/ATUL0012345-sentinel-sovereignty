# LLM Prompt Log

This log is kept because the assignment brief requires it: *"Where LLM tools are used, it is important to state the LLM name, version and prompt used. Never hide the use of tools."*

| Item | Detail |
|------|--------|
| Tool | Claude Code (Anthropic), Claude desktop app, Code tab |
| Model | Claude Opus 5.5 (`claude-opus-5-5`) |
| Scope | Only prompts that shaped the assignment are logged (design, code, testing, analysis). Pure confirmations ("done", etc.) and housekeeping about this log are left out. Prompts are copied verbatim (typos kept). |

---

## Session 1: Project kickoff

### Prompt 1 (2026-11-08)
> That's where we will apply Terraform sentinel assignment

**What the AI did:** Listed the project folder, read the assignment brief (PDF) and summarised the scope. It checked which tools were installed locally (Terraform 1.6.1, git, GitHub CLI and AWS CLI were present; Sentinel CLI was missing at that point), then proposed a structure and asked clarifying questions.

### Prompt 2 (2026-11-10)
> ok first we will create readme.md and prompts.md for all prompts we have here in this chat (will focus on project/assignment related). for all git commands i will be doing it myself, you can share the related commands, for now what i have is terraform , sentinel , AWS CLI , github public repo called ATUL0012345-sentinel-sovereignty (https://github.com/L00205332/ATUL0012345-sentinel-sovereignty ) which you should have access to. now i want you to review Terraform Sentinel Assignment 2026.pdf and let's have a discussion about what are we gonna do. you can start also with perquisites verfication set of commands

**What the AI did:** Created a skeleton `README.md` (sections mapped to the brief's deliverables, with an AI-usage declaration) and this `prompts.md`. It reviewed the brief for a design discussion and provided prerequisite verification commands for the student to run. All git operations are done by the student.

### Prompt 3 (2026-11-10)
> [pasted output of the prerequisite checks: Terraform v1.6.1 (out of date, latest 1.17.1), Sentinel v0.41.0, aws-cli/2.13.25, git 2.56.0, gh logged in as L00205332]
> looks like we need to update Terraform

**What the AI did:** Explained why the local Terraform version should match the HCP workspace version and the lock file. Gave upgrade options, including a manual install that checks the binary's SHA256 checksum against HashiCorp's published `SHA256SUMS`. That check is an example of the supply-chain integrity principle the assignment covers. The student upgraded to Terraform 1.17.1.

---

<!-- Add new prompts below in the same format: number, date, verbatim prompt, short note on what the AI did. -->
