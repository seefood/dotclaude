# NFR Analyst

A Claude Code skill that analyzes software artifacts for Non-Functional Requirements (NFRs) - the quality attributes that determine whether a system holds up in production.

## Purpose

Functional requirements describe what a system does. Non-functional requirements describe how well it does it: fast enough, secure enough, available enough, maintainable enough. These are the requirements most often left implicit, and the ones most expensive to discover late.

This skill reads an artifact and produces a structured, auditable NFR analysis. It distinguishes what the artifact actually states from what a reader would infer, flags what a system of this type should cover but doesn't, and checks whether quality claims are backed by real mechanisms. The output is meant to be actionable - findings you can act on and generated requirements you can paste back into the design.

It handles partial or incomplete artifacts gracefully. If an artifact is too thin for meaningful analysis, the skill says so and explains what's missing rather than manufacturing a misleading report.

## Artifacts it handles

- Architecture diagrams (images, ASCII art, described topologies, draw.io exports)
- Design documents (specs, RFCs, ADRs, READMEs, wiki pages)
- Code (microservices, libraries, infrastructure-as-code, scripts)
- API specifications (OpenAPI/Swagger, GraphQL schemas, gRPC `.proto` files, RAML)
- User stories (feature descriptions, epics, acceptance criteria, Gherkin)

## NFR categories

| Category | What it looks for |
|---|---|
| Performance | Response time targets, throughput, latency budgets, resource limits |
| Scalability | Horizontal/vertical scaling, elasticity, load distribution, capacity planning |
| Security | AuthN/AuthZ, encryption, threat model, attack surface, data classification |
| Reliability | Availability SLAs, fault tolerance, error handling, recovery, redundancy |
| Maintainability | Modularity, testability, versioning, deployment, dependency management |
| Observability | Logging, metrics, distributed tracing, alerting, dashboards, runbooks |

## Process

The analysis runs in six phases:

1. **Ingest and classify** - identify the artifact type and domain, then check whether it contains enough to analyze. Insufficient artifacts stop here with an explanation.
2. **Extract explicit NFRs** - identify every NFR the artifact states directly, with a citation to the specific section or line.
3. **Infer implicit NFRs** - derive NFRs from design choices (a load balancer implies scalability; retry logic implies reliability; a payment flow implies security and auditability). Each inference is marked as such and its reasoning explained.
4. **Identify missing NFRs** - for each category, name what should be covered given the domain and scale but isn't. Calibrated, not exhaustive: a payment API warrants stricter security than an internal admin tool.
5. **Validate compliance** - for each stated or inferred NFR, check whether the artifact actually addresses it. Catches claims without backing, design choices that contradict stated goals, and vague, unverifiable targets.
6. **Generate output** - assemble the report.

Compliance is scored with four codes: ✓ addressed, ⚠ partial, ✗ unaddressed, - cannot determine from the artifact alone.

## Output

- **Artifact summary** - what it is, what it describes, and the analyst's confidence level.
- **NFR coverage matrix** - one row per category, summarizing explicit / inferred / missing / compliance.
- **Detailed findings** - per category: what's stated, what's inferred, what's missing and why it matters.
- **Compliance issues** - NFRs claimed or expected but not backed by the artifact, with what it would take to close each gap.
- **Generated NFR documentation** - a ready-to-use requirements section with measurable criteria where the artifact provides enough signal, written to be inserted directly into the design.

## Repository layout

```
SKILL.md          The skill definition and full analysis protocol
evals/
  evals.json      Evaluation cases with prompts, expected output, and assertions
  files/          Sample artifacts used by the evals
README.md         This file
```

The evals cover three representative situations: a rich architecture document, a payment API spec with real security gaps, and a design doc too thin to analyze - verifying the skill produces thorough analysis when there's substance and refuses to fabricate one when there isn't.

## Usage

The skill triggers automatically in Claude Code when you share an artifact and ask about NFRs, quality attributes, or architecture gaps - for example "review NFRs", "check quality attributes", "find gaps in the architecture", or "validate non-functional requirements". You can also invoke it directly with `/nfr-analyst`.
