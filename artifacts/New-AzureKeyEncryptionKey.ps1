param(
    [parameter(Mandatory)]
    [string]$KeyVault
)

if(!(Get-AzKeyVaultKey -Name 'DiskEncryption' -VaultName $KeyVault))
{
    Add-AzKeyVaultKey -Name 'DiskEncryption' -VaultName $KeyVault -Destination 'Software' -KeyType 'RSA' -Size 4096
}
$KeyEncryptionKeyURL = (Get-AzKeyVaultKey -VaultName $KeyVault -Name 'DiskEncryption' -IncludeVersions | Where-Object {$_.Enabled -eq $true}).Id
Write-Output $KeyEncryptionKeyURL
$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['text'] = $KeyEncryptionKeyURL