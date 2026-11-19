# Run only after the owner approves this exact repository as a credential destination.
# The browser reads and immediately deletes the short-lived transfer file without logging values.
param([string]$ProfilePath = (Join-Path $env:USERPROFILE 'Downloads\Lanpixo_AppStore_2026.mobileprovision'))
$ErrorActionPreference = 'Stop'
$signingDirectory = Join-Path $env:USERPROFILE '.lanpixo\apple-signing'
Copy-Item -LiteralPath $ProfilePath -Destination (Join-Path $signingDirectory 'Lanpixo_AppStore_2026.mobileprovision') -Force
$p12Bytes = $null; $passwordBytes = $null
try {
    $p12Bytes = [System.Security.Cryptography.ProtectedData]::Unprotect([IO.File]::ReadAllBytes((Join-Path $signingDirectory 'distribution.p12.dpapi')), $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    $passwordBytes = [System.Security.Cryptography.ProtectedData]::Unprotect([IO.File]::ReadAllBytes((Join-Path $signingDirectory 'distribution-password.dpapi')), $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    $payload = @{
        APPLE_DISTRIBUTION_P12_BASE64 = [Convert]::ToBase64String($p12Bytes)
        APPLE_DISTRIBUTION_P12_PASSWORD = [Text.Encoding]::UTF8.GetString($passwordBytes)
        APPLE_PROVISIONING_PROFILE_BASE64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($ProfilePath))
    }
    $transferPath = Join-Path $signingDirectory 'github-signing-transfer.json'
    [IO.File]::WriteAllText($transferPath, ($payload | ConvertTo-Json -Compress), [Text.UTF8Encoding]::new($false))
    Write-Output 'Approved signing transfer prepared outside repository; values are not printed.'
} finally {
    foreach ($buffer in @($p12Bytes, $passwordBytes)) { if ($null -ne $buffer) { [Array]::Clear($buffer, 0, $buffer.Length) } }
    $payload = $null
}
