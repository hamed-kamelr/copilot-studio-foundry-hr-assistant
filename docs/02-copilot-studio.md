# 2. Build the Copilot Studio agent

The conversational front door.

## Prerequisites

- A Copilot Studio licence or trial
- **Generative orchestration turned on** (Settings → Generative AI → Orchestration → Yes)

## Steps

### 1. Create the agent

Create an agent named **HR Assistant** with a description such as:

> An internal HR assistant that answers employee questions about benefits, leave policy, payroll, and onboarding. For benefit plan cost comparisons and PTO accrual projections, it hands off to a specialist calculation agent built in Microsoft Foundry.

### 2. Create the topic

Create a topic named **Benefits and PTO Calculator**. Under generative orchestration the trigger becomes a description rather than trigger phrases:

> compare benefit plans, PTO balance, calculate my PTO

### 3. Add the Adaptive Card

Add an **Ask with adaptive card** node and paste in [`../copilot-studio/adaptive-card.json`](../copilot-studio/adaptive-card.json).

Copilot Studio parses the card and exposes each input as a typed output automatically:

| Output | Type |
|---|---|
| `salary` | number |
| `familySize` | number |
| `hireDate` | date |
| `daysUsed` | number |

Bind each one to a topic variable of the same name.

### 4. Build the request string

Add a **Set variable value** node.

- **Set variable**: a new text variable named `EmployeeRequest`
- **To value**: the concatenation formula from [`../copilot-studio/powerfx-snippets.md`](../copilot-studio/powerfx-snippets.md)

The value field must be in **formula mode**, not plain text. If it is stored as text, the topic will pass the literal formula through instead of the evaluated sentence.

### 5. Add the HTTP call and the message

Covered in [03-connecting.md](03-connecting.md).

---

## Things that will bite you

**Do not add the policy documents as Copilot Studio Knowledge.** If the orchestrator can answer from its own knowledge, it will, and it will never call the Foundry agent. The answer it produces is premium-only arithmetic with no scenario modelling, which looks plausible and is wrong.

**Turn off general web knowledge.** Otherwise answers cite unrelated public PTO calculator websites.

**The topic must end with a Message node.** A topic that ends after the HTTP call displays nothing, and generative orchestration, seeing the request as unresolved, re-triggers the same topic and shows the card a second time.

**Do not expose `EmployeeRequest` as a topic Output.** If you do, the orchestrator reads it, decides the tool returned inputs rather than an answer, and writes its own unhelpful message on top of yours.

**Add an End all topics node** after the Message node to stop the orchestrator appending a duplicate follow-up.
