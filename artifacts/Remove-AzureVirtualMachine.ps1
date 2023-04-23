Param(
    [string]$ResourceGroupName,
    [string]$VirtualMachineName
)

$ErrorActionPreference = 'Stop'

try
{
    Remove-AzVM `
        -ResourceGroupName $ResourceGroupName `
        -Name $VirtualMachineName `
        -ForceDeletion $true `
        -Force
}
catch 
{
    Write-Host $_ | Select-Object *
    throw
}