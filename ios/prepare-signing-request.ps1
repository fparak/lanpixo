# Windows-only preparation. Creates no Apple credential until Apple issues a certificate.
# Private key stays outside the repository, encrypted for this Windows user with DPAPI.
$ErrorActionPreference = 'Stop'
$signingDirectory = Join-Path $env:USERPROFILE '.lanpixo\apple-signing'
New-Item -ItemType Directory -Path $signingDirectory -Force | Out-Null
$keyFile = Join-Path $signingDirectory 'distribution-private-key.pk8.dpapi'
$csrFile = Join-Path $signingDirectory 'Lanpixo-Distribution.certSigningRequest'
if ((Test-Path -LiteralPath $keyFile) -or (Test-Path -LiteralPath $csrFile)) {
    if (!(Test-Path -LiteralPath $keyFile) -or !(Test-Path -LiteralPath $csrFile)) { throw 'Incomplete existing signing request; inspect before regenerating.' }
    Write-Output "Existing CSR: $csrFile"
    return
}
$rsa = [System.Security.Cryptography.RSA]::Create(2048)
$privateBytes = $null
try {
    $subject = [System.Security.Cryptography.X509Certificates.X500DistinguishedName]::new('CN=Lanpixo Distribution, O=EPX Studio, C=TR')
    $request = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new($subject, $rsa, [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
    $privateBytes = $rsa.ExportPkcs8PrivateKey()
    $protectedBytes = [System.Security.Cryptography.ProtectedData]::Protect($privateBytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    [IO.File]::WriteAllBytes($keyFile, $protectedBytes)
    [IO.File]::WriteAllText($csrFile, $request.CreateSigningRequestPem(), [Text.UTF8Encoding]::new($false))
    Write-Output "Prepared CSR: $csrFile"
    Write-Output 'Private key is DPAPI-encrypted outside the repository; no Apple certificate has been issued.'
} finally {
    if ($null -ne $privateBytes) { [Array]::Clear($privateBytes, 0, $privateBytes.Length) }
    $rsa.Dispose()
}
