param(
    [string]$KeyId = '8S5ZK8J8JZ',
    [string]$IssuerId = '69a6de80-2ff1-47e3-e053-5b8c7c11a4d1'
)
# Owner-approved App Store Connect key -> fparak/lanpixo Actions Secrets only.
$ErrorActionPreference = 'Stop'
if ($KeyId -notmatch '^[A-Z0-9]+$') { throw 'Invalid key ID.' }
$signingDirectory = Join-Path $env:USERPROFILE '.lanpixo\apple-signing'
$downloadPath = Join-Path $env:USERPROFILE "Downloads\AuthKey_$KeyId.p8"
$protectedPath = Join-Path $signingDirectory "AuthKey_$KeyId.p8.dpapi"
$keyBytes = $null; $verificationBytes = $null
try {
    if (Test-Path -LiteralPath $protectedPath) {
        $keyBytes = [System.Security.Cryptography.ProtectedData]::Unprotect([IO.File]::ReadAllBytes($protectedPath), $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    } else {
        $keyBytes = [IO.File]::ReadAllBytes($downloadPath)
        $pem = [Text.Encoding]::UTF8.GetString($keyBytes)
        if (!$pem.StartsWith('-----BEGIN PRIVATE KEY-----')) { throw 'Unexpected API key file format.' }
        [IO.File]::WriteAllBytes($protectedPath, [System.Security.Cryptography.ProtectedData]::Protect($keyBytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser))
        $verificationBytes = [System.Security.Cryptography.ProtectedData]::Unprotect([IO.File]::ReadAllBytes($protectedPath), $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
        if ([Convert]::ToBase64String($keyBytes) -ne [Convert]::ToBase64String($verificationBytes)) { throw 'Encrypted backup verification failed.' }
        Remove-Item -LiteralPath $downloadPath
    }
    $payload = @{
        APP_STORE_CONNECT_KEY_ID = $KeyId
        APP_STORE_CONNECT_ISSUER_ID = $IssuerId
        APP_STORE_CONNECT_PRIVATE_KEY = [Text.Encoding]::UTF8.GetString($keyBytes)
    }
    [IO.File]::WriteAllText((Join-Path $signingDirectory 'github-upload-transfer.json'), ($payload | ConvertTo-Json -Compress), [Text.UTF8Encoding]::new($false))
    Write-Output 'Upload key encrypted outside repository; approved GitHub transfer prepared without printing values.'
} finally {
    foreach ($buffer in @($keyBytes, $verificationBytes)) { if ($null -ne $buffer) { [Array]::Clear($buffer, 0, $buffer.Length) } }
    $payload = $null; $pem = $null
}
