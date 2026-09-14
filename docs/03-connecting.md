# 3. Connect the two agents

Copilot Studio calls the Foundry agent's **Responses API** endpoint directly from a Send HTTP request node.

## The endpoint

```
https://{account}.services.ai.azure.com/api/projects/{project}/agents/{agent-name}/endpoint/protocols/openai/responses?api-version=v1
```

Replace `{account}`, `{project}`, and `{agent-name}` with your own values.

## Authentication

Foundry agent endpoints **do not accept API keys**. They require a Microsoft Entra ID token.

Get one from Azure Cloud Shell:

```powershell
az account get-access-token --resource https://ai.azure.com --query accessToken -o tsv
```

The caller needs the **Foundry User** role (or **Foundry Agent Consumer**) on the project.

> Access tokens last roughly 60 to 90 minutes. For a demo, refresh before you present. For anything longer lived, register an Entra application and use a Power Automate HTTP action with Entra OAuth so the token refreshes automatically, rather than pasting a token into a header.

## The node

Add **Add node → Advanced → Send HTTP request** after your Set variable node.

| Field | Value |
|---|---|
| **Method** | `POST` |
| **URL** | the endpoint above |
| **Header key** | `Authorization` |
| **Header value** | `Bearer <token>` |
| **Body** | JSON content, formula mode: `{ input: Topic.EmployeeRequest }` |
| **Response data type** | From sample data, using the sample in [powerfx-snippets.md](../copilot-studio/powerfx-snippets.md) |
| **Save response as** | `AgentResponse` |
| **Request timeout** | `90000` |

The default 30 second timeout is not enough. Code Interpreter runs take 25 to 45 seconds routinely, and the node fails with `HttpRequestTimeout` before the agent finishes.

`input` must be a **string**. Passing anything else returns:

```
Required discriminator 'input' is missing or not a string
```

## Display the answer

Add a **Message** node after the HTTP node, in formula mode:

```
Text(First(Last(Topic.AgentResponse.output).content).text)
```

`Last()` matters. When the agent uses Code Interpreter, the `output` array contains reasoning and tool-call items first, with the assistant message last. `First(output)` returns an item with no `content` field, which evaluates to blank.

Finish with an **End all topics** node.

## Verify

Start a new test session, trigger the topic, fill the card, submit. You should see the card, then a single answer from the Foundry agent, and nothing else.
