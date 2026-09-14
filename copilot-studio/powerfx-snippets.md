# Power Fx snippets

Formulas used in the **Benefits and PTO Calculator** topic. Each must be entered in **formula mode**, not as plain text. A formula stored as text is passed through literally, which is silent and confusing to debug.

---

## 1. Build the request string

**Node:** Set variable value
**Set variable:** `EmployeeRequest` (text)
**To value:**

```
"I make " & Text(Topic.salary) & " a year with a family of " & Text(Topic.familySize) & ". I was hired on " & Text(Topic.hireDate) & " and have used " & Text(Topic.daysUsed) & " days of PTO. Compare my benefit plan costs and project my PTO balance."
```

`Text()` around each variable matters for `hireDate`, which is a date type and will not concatenate directly.

---

## 2. HTTP request body

**Node:** Send HTTP request
**Body:** JSON content, formula mode

```
{ input: Topic.EmployeeRequest }
```

The Responses API requires `input` to be a **string**. Anything else returns `Required discriminator 'input' is missing or not a string`.

---

## 3. Response schema sample

**Node:** Send HTTP request
**Response data type:** From sample data → Get schema from sample JSON

```json
{
  "id": "resp_abc123",
  "object": "response",
  "created_at": 1234567890,
  "status": "completed",
  "model": "gpt-4o",
  "output": [
    {
      "type": "message",
      "id": "msg_abc",
      "status": "completed",
      "role": "assistant",
      "content": [
        {
          "type": "output_text",
          "text": "This is the answer",
          "annotations": []
        }
      ]
    }
  ],
  "usage": {
    "input_tokens": 10,
    "output_tokens": 20,
    "total_tokens": 30
  }
}
```

---

## 4. Display the answer

**Node:** Message, formula mode

```
Text(First(Last(Topic.AgentResponse.output).content).text)
```

`Last()` rather than `First()`. When the agent runs Code Interpreter, the `output` array holds reasoning and tool-call items before the assistant message. Taking the first item returns something with no `content` field, which renders blank.

---

## Diagnostics

Useful while wiring this up, swap into the Message node temporarily.

Confirm the response object is valid at all:

```
Text(Topic.AgentResponse.id)
```

Returns something like `resp_0ddd5554d086012c...` if the call succeeded.

Count the items in the output array:

```
Text(CountRows(Topic.AgentResponse.output))
```

Avoid `JSON(Topic.AgentResponse)`. On a full Code Interpreter response it is large and deeply nested enough to fail with a generic `SystemError`.
