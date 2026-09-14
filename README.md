# Multi-Agent HR Assistant: Copilot Studio + Microsoft Foundry

A working multi-agent setup where **Microsoft Copilot Studio** acts as the conversational front door and a **Microsoft Foundry** agent acts as the specialist that performs the actual calculations.

An employee asks about their benefit plan costs or paid time off balance. Copilot Studio collects the inputs through an Adaptive Card, then hands the request to a Foundry agent that runs the math with Code Interpreter and cites the policy rule it applied.

---

## Architecture

```
Employee
   │
   ▼
┌─────────────────────────────────────────┐
│  Copilot Studio — "HR Assistant"        │
│                                         │
│  Topic: Benefits and PTO Calculator     │
│   1. Adaptive Card collects inputs      │
│   2. Set variable builds the request    │
│   3. HTTP Request calls Foundry         │
│   4. Message displays the answer        │
└──────────────────┬──────────────────────┘
                   │  POST /protocols/openai/responses
                   │  Authorization: Bearer <Entra token>
                   ▼
┌─────────────────────────────────────────┐
│  Microsoft Foundry — HR-Benefits-       │
│  Calculator (prompt agent)              │
│                                         │
│   • Code Interpreter for exact math     │
│   • Benefits + PTO policy in context    │
│   • Returns a short, cited answer       │
└─────────────────────────────────────────┘
```

**Why split it this way?** Copilot Studio is good at conversation, forms, channels, and governance. It is not good at precise arithmetic. The Foundry agent runs real Python through Code Interpreter, so accrual dates and plan costs are computed rather than predicted, and every figure is traceable to a policy line.

---

## What it does

| Capability | Example |
|---|---|
| Benefit plan cost comparison | Annual PPO vs HDHP total cost for a given salary, family size, and expected out-of-pocket spend |
| PTO accrual projection | Balance today and projected year-end balance from hire date, tenure tier, and days already used |
| Policy grounding | Every number cites the Benefits Guide or PTO Accrual Policy rule that produced it |

---

## Repository contents

```
.
├── docs/
│   ├── 01-foundry-agent.md      Build the specialist agent
│   ├── 02-copilot-studio.md     Build the front-door agent and topic
│   ├── 03-connecting.md         Wire the two together
│   └── troubleshooting.md       Problems hit during the build and their causes
├── foundry/
│   ├── agent-instructions.md    Instruction set for the Foundry agent
│   └── enable-protocols.ps1     Enable Activity / A2A / MCP protocols via REST
├── copilot-studio/
│   ├── adaptive-card.json       The input form
│   └── powerfx-snippets.md      Formulas used in the topic
└── knowledge-docs/
    ├── benefits_guide.txt       Sample benefits data
    └── pto_accrual_policy.txt   Sample PTO policy
```

---

## Quick start

1. **Foundry**: create a project, deploy a chat model, create a prompt agent, enable Code Interpreter, and paste in [`foundry/agent-instructions.md`](foundry/agent-instructions.md). See [docs/01-foundry-agent.md](docs/01-foundry-agent.md).
2. **Copilot Studio**: create an agent, add a topic, add the Adaptive Card from [`copilot-studio/adaptive-card.json`](copilot-studio/adaptive-card.json). See [docs/02-copilot-studio.md](docs/02-copilot-studio.md).
3. **Connect**: add a Send HTTP request node pointing at the Foundry agent's Responses endpoint. See [docs/03-connecting.md](docs/03-connecting.md).

---

## A note on the integration approach

Copilot Studio ships a native **"Add an agent → Microsoft Foundry"** connector. It is in public preview, and at the time of building it did not complete the round trip in this scenario, failing regardless of agent identifier format, region, protocol configuration, or authorization scheme.

This project therefore calls the Foundry agent's **Responses API endpoint** directly from a Send HTTP request node. That path is stable, gives full control over the request payload, and returns the agent's answer intact.

[docs/troubleshooting.md](docs/troubleshooting.md) documents what was tried and why each approach behaved the way it did, which may save someone else the same afternoon.

---

## Sample data

The benefits and PTO figures in this repository are **synthetic sample data** created for demonstration. They are not the policies of any real organisation.
