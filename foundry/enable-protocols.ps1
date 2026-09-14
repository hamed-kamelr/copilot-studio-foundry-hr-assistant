<#
    Enables additional protocols on a Microsoft Foundry agent endpoint.

    A newly created Foundry agent exposes only the Responses and A2A protocols.
    The Activity protocol, required by Copilot Studio's native connector, can
    only be enabled programmatically. There is no portal option for it.

    Run this in Azure Cloud Shell (PowerShell) or locally with Azure CLI signed in.

    Note: after running this, the Foundry portal will still display only
    Responses and A2A under Endpoints. That is a known UI omission and does
    not mean the change failed. Verify with the GET call at the bottom.
#>

# ---- configure these -------------------------------------------------------
$Account   = "your-foundry-account"      # e.g. contoso-foundry
$Project   = "your-project"              # e.g. proj-default
$AgentName = "HR-Benefits-Calculator"
# ----------------------------------------------------------------------------

$BaseUri = "https://$Account.services.ai.azure.com/api/projects/$Project/agents/$AgentName`?api-version=v1"

$Token = az account get-access-token --resource https://ai.azure.com --query accessToken -o tsv

$Body = @{
    agent_endpoint = @{
        protocol_configuration = @{
            responses = @{}   # already enabled by default, included so the merge keeps it
            activity  = @{}   # required by Copilot Studio's native connector
            a2a       = @{}   # agent-to-agent protocol
            mcp       = @{}   # Model Context Protocol endpoint
        }
        authorization_schemes = @(
            @{ type = "Entra" }
            @{ type = "BotServiceRbac" }   # required for Teams / M365 / bot-channel style callers
        )
    }
} | ConvertTo-Json -Depth 6

Invoke-RestMethod -Method Patch `
    -Uri $BaseUri `
    -Headers @{ Authorization = "Bearer $Token" } `
    -ContentType "application/merge-patch+json" `
    -Body $Body

# ---- verify ----------------------------------------------------------------
Write-Host "`nEnabled protocols:" -ForegroundColor Cyan

Invoke-RestMethod -Method Get `
    -Uri $BaseUri `
    -Headers @{ Authorization = "Bearer $Token" } |
    Select-Object -ExpandProperty agent_endpoint |
    Select-Object -ExpandProperty protocol_configuration
