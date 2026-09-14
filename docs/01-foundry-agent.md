# 1. Build the Foundry agent

The specialist agent that does the actual calculating.

## Prerequisites

- An Azure subscription
- A Microsoft Foundry resource and project
- The **Foundry User** role on the project scope

> **Region matters.** Some agent features, including Routines and parts of the multi-agent surface, are only available in a subset of regions (East US, East US 2, Japan East, North Central US, Sweden Central among them). Check region support before you build, moving later means recreating the resource, since region is fixed at creation.

## Steps

### 1. Create the project and deploy a model

In the Foundry portal, create a project, then deploy a chat model. A standard chat model is required. Reasoning-optimised models were tried first and rejected the tool configuration with `invalid_request_error`, so stick to a general chat model such as GPT-4o or GPT-5 mini.

### 2. Create the agent

Create a new prompt agent named `HR-Benefits-Calculator`.

### 3. Add the instructions

Paste the contents of [`../foundry/agent-instructions.md`](../foundry/agent-instructions.md) into the agent's **Instructions** field.

The instructions embed the benefits and PTO reference data directly rather than using a Knowledge base. This is deliberate, see the note below.

### 4. Enable Code Interpreter

Under **Tools**, enable **Code Interpreter**. This is what makes the arithmetic exact rather than generated. The instructions explicitly require the agent to use it for every calculation.

Do not attach files to the Code Interpreter tool, it only needs to run arithmetic, not analyse uploaded data.

### 5. Test in the Playground

```
I make $70,000 a year with a family of four, compare my total annual cost under the PPO plan versus the HDHP plan.
```

```
I was hired on March 15, 2025, and have used 4 days of PTO. What will my balance be on December 31, 2026?
```

Confirm it uses the correct premiums, applies the mid-month hire rule, and shows a short cited answer.

---

## Why the policy data is in the instructions, not a Knowledge base

The first build used a Foundry IQ Knowledge base backed by Azure AI Search, with the two documents in [`../knowledge-docs/`](../knowledge-docs/) uploaded to it. That works correctly in the Playground.

It was moved into the instructions for two reasons:

1. **A documented bug.** Foundry agents that use Knowledge return error callbacks when invoked over the Activity protocol, while working normally in inline chat. This is tracked publicly and unresolved.
2. **Simplicity.** The reference data here is two short documents. Embedding them removes the Azure AI Search resource, its cost, and its role assignments from the architecture entirely.

If your policy corpus is large, use a Knowledge base instead and accept the extra setup. The documents in `knowledge-docs/` are ready to upload if you go that route.

### If you do use a Knowledge base

Grant **Search Index Data Reader** on the Azure AI Search resource to:

- your own user account, and
- the Foundry resource's system-assigned managed identity, and
- the Foundry project's managed identity

Missing these produces a `401 Unauthorized` from the MCP server when the agent tries to search.
