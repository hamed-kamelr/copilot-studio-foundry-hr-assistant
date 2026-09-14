# Troubleshooting

Every failure encountered building this, and what actually caused it. Recorded because most of these produce errors that point somewhere unhelpful.

## Connection and protocol

**`401 Unauthorized` from the MCP server when the agent searches Knowledge**

The Foundry identity lacks access to Azure AI Search. Assign **Search Index Data Reader** on the Search resource to your user account, the Foundry resource's managed identity, and the Foundry project's managed identity.

**`Agent <name> endpoint does not support activity`**

A newly created Foundry agent exposes only the Responses and A2A protocols. The Activity protocol, which the native Copilot Studio connector requires, can only be enabled via REST or SDK, there is no portal option. Run [`../foundry/enable-protocols.ps1`](../foundry/enable-protocols.ps1).

After enabling it, the portal still shows only Responses and A2A. That omission is expected and does not mean the change failed.

**`Could not find agent with name <guid>`**

The connector's Agent Id field takes the agent **name**, not the Entra agent identity GUID or blueprint GUID shown on the Details page.

**`404 Cannot read server response`**

Caused by putting an agent-specific protocol URL into the connection's project endpoint field. That field wants the project endpoint only:

```
https://{account}.services.ai.azure.com/api/projects/{project}
```

**Native connector still returns nothing after all of the above**

The `Add an agent → Microsoft Foundry` connector is in public preview. Tried across two regions, five identifier formats, with and without Knowledge, with Activity and A2A protocols enabled, and with both `Entra` and `BotServiceRbac` authorization schemes. It consistently either errored or returned no result. Calling the Responses endpoint directly is the working path.

## Request and payload

**`Required discriminator 'input' is missing or not a string`**

The `input` field was missing or was not a string.

If you hit this using the native connector's redirect node in a topic: that node forwards the **incoming user activity**, and it has no input mapping for external connected agents, only child agents support configured inputs. An Adaptive Card submit is an activity carrying a data object with no text, so `input` ends up empty. Nothing placed between the card and the node changes this, because Message and Set variable nodes run bot-side and do not alter the incoming activity.

**`HTTP request failed with status code 403 Forbidden`**

Expired Entra token. Regenerate it.

**`HTTP request timed out after 30000 milliseconds`**

Raise the node's request timeout to 90000.

**`SystemError` with no detail after adding a Message node**

Caused by `JSON(Topic.AgentResponse)` on a large nested response. Reference a specific field instead of serialising the whole object.

## Behaviour

**Message node shows blank**

`First(Topic.AgentResponse.output)` returns a reasoning or tool-call item with no `content`. Use `Last()`.

**The agent answers from Copilot Studio's own knowledge instead of delegating**

Remove the policy documents from Copilot Studio's Knowledge. Given the choice, the orchestrator answers directly rather than calling out.

**The card appears twice and the topic runs twice**

The topic ends without displaying anything, so generative orchestration treats the request as unresolved and re-plans. Add a Message node.

**An extra generic message appears after the real answer**

Generative orchestration appends its own response. Add an **End all topics** node, and remove any topic Outputs the orchestrator could editorialise on.

**Answers are extremely long**

The agent's instructions ask it to show its work. Constrain the response format explicitly, the version in [`../foundry/agent-instructions.md`](../foundry/agent-instructions.md) caps answers at two sentences.

**The agent refuses to calculate and asks for missing input**

Correct behaviour if the instructions forbid guessing. Either collect the field in the card or tell the agent what to assume.

## Environment

**`You don't have permission to build agents in this project`**

Assign yourself the **Foundry User** role on the project.

**Azure AI Search creation blocked by capacity**

Region at capacity. Pick another supported region. The Search resource does not have to sit in the same region as the Foundry resource.

**Region cannot be changed after creation**

Correct, Azure resources are fixed to their region. Moving means recreating the resource and its contents.
