param (
    [string]$tag_name,
    [string]$tag_value
)

try {
    # Disables inheriting an Azure context in your runbook
    Disable-AzContextAutosave -Scope Process

    # Connects to Azure with system-assigned managed identity
    $AzureContext = Connect-AzAccount -Identity

    # Checks if the connection was successfully established
    if ($AzureContext -ne $null) {
        Write-Output "Connection to Azure account established successfully."

        # Defines the TAG that will be validated when starting VMs
        $azVMs = Get-AzVM | Where-Object {$_.Tags[$tag_name] -eq $tag_value}

        # Print the list of VMs that will be stopped
        Write-Output "The following VMs will be stopped:"
        $azVMs | ForEach-Object { Write-Output $_.Name }

        # Stops the VMs
        $azVMs | Stop-AzVM -Force
    } else {
        throw "Failed to connect to Azure account. Please check your credentials or managed identity configuration."
    }
} catch {
    Write-Error "An error occurred: $_"
    throw # Re-throw the exception
}
