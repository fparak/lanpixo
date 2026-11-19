# Lanpixo signing and upload

Apple team: `M64GVYHN8L`. App Store Connect app: `6836586066`. Bundle: `com.netora.scanner`.

The owner explicitly authorized creating a new Apple Distribution certificate and storing this app's signing inputs only in the `fparak/lanpixo` repository Actions Secrets on 19 November 2026. Certificate `8Y94H39C63` was issued, expiry 19 November 2027. Existing certificates were not revoked.

On the Windows workstation, private material is outside this repository under `%USERPROFILE%\.lanpixo\apple-signing`, encrypted with DPAPI for the current Windows user. `prepare-signing-request.ps1` creates the public CSR; `import-distribution-certificate.ps1` verifies that the issued certificate matches the key and exports an encrypted P12 and encrypted random export password. These encrypted local backups need a secure, recoverable owner-managed backup; DPAPI is tied to this Windows identity.

Required repository secrets for `.github/workflows/ios-testflight.yml`:

| Name | Contents |
| --- | --- |
| `APPLE_DISTRIBUTION_P12_BASE64` | Base64 P12 certificate and private key |
| `APPLE_DISTRIBUTION_P12_PASSWORD` | Export password |
| `APPLE_PROVISIONING_PROFILE_BASE64` | Base64 App Store distribution profile for this exact bundle and team |
| `APP_STORE_CONNECT_KEY_ID` | Upload API key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | Upload API issuer ID |
| `APP_STORE_CONNECT_PRIVATE_KEY` | Upload API key PEM content |

The API key is a separate credential; creation/access must be explicitly authorized before enabling uploads. No secret values belong in source, issues, logs or chat. Local DPAPI ciphertext is not the secret value to paste into GitHub.

The signed workflow is manual only, defaults to **no upload**, validates profile identity/type/expiry, imports credentials into a temporary keychain and removes job-specific credentials afterward. It can export an IPA without an upload API key. Upload requires the three App Store Connect secrets and `upload=true`. A successful upload still requires Apple processing and TestFlight configuration; it is not App Review approval.

The owner separately approved the Developer-role App Store Connect API key creation and storage on 19 November 2026. Key `8S5ZK8J8JZ` is named Lanpixo TestFlight Upload. Team API keys are not limited to one app; that scope was disclosed before approval. The private key is encrypted locally with DPAPI and stored in the approved repository's Secrets. All six secrets are configured. Signed archive/export and build-2 and build-3 uploads passed; see `RELEASE-PREPARATION.md` for the current evidence and remaining physical-device/App Review checks.
