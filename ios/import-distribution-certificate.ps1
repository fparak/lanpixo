param([string]$CertificatePath = (Join-Path $env:USERPROFILE 'Downloads\distribution.cer'))
$ErrorActionPreference = 'Stop'
$signingDirectory = Join-Path $env:USERPROFILE '.lanpixo\apple-signing'
$keyFile = Join-Path $signingDirectory 'distribution-private-key.pk8.dpapi'
$p12File = Join-Path $signingDirectory 'distribution.p12.dpapi'
$passwordFile = Join-Path $signingDirectory 'distribution-password.dpapi'
if ((Test-Path -LiteralPath $p12File) -or (Test-Path -LiteralPath $passwordFile)) {
    if (!(Test-Path -LiteralPath $p12File) -or !(Test-Path -LiteralPath $passwordFile)) { throw 'Incomplete existing export. Inspect before regenerating.' }
    Write-Output 'Encrypted distribution export already exists.'
    return
}
$privateBytes = $null; $p12Bytes = $null; $passwordBytes = $null
$rsa = [System.Security.Cryptography.RSA]::Create()
$certificate = $null; $withKey = $null
try {
    $privateBytes = [System.Security.Cryptography.ProtectedData]::Unprotect([IO.File]::ReadAllBytes($keyFile), $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
    $bytesRead = 0
    $rsa.ImportPkcs8PrivateKey($privateBytes, [ref]$bytesRead)
    $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new([IO.File]::ReadAllBytes($CertificatePath))
    if ($certificate.Subject -notmatch 'OU=M64GVYHN8L') { throw 'Certificate belongs to a different Apple team.' }
    if ($certificate.NotAfter -le [DateTime]::Now) { throw 'Certificate has expired.' }
    $withKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::CopyWithPrivateKey($certificate, $rsa)
    $password = [Convert]::ToHexString([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
    $p12Bytes = $withKey.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $password)
    $passwordBytes = [Text.Encoding]::UTF8.GetBytes($password)
    [IO.File]::WriteAllBytes($p12File, [System.Security.Cryptography.ProtectedData]::Protect($p12Bytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser))
    [IO.File]::WriteAllBytes($passwordFile, [System.Security.Cryptography.ProtectedData]::Protect($passwordBytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser))
    Copy-Item -LiteralPath $CertificatePath -Destination (Join-Path $signingDirectory 'distribution.cer')
    Write-Output "Certificate/key match verified. Encrypted export prepared outside repository. Expiry: $($certificate.NotAfter.ToString('yyyy-MM-dd'))"
} finally {
    foreach ($buffer in @($privateBytes, $p12Bytes, $passwordBytes)) { if ($null -ne $buffer) { [Array]::Clear($buffer, 0, $buffer.Length) } }
    $password = $null
    if ($null -ne $withKey) { $withKey.Dispose() }
    if ($null -ne $certificate) { $certificate.Dispose() }
    $rsa.Dispose()
}
