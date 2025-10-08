# GitHub Actions TestFlight Deployment Setup

## Overview
This guide helps you set up automatic TestFlight deployment when pushing to `main` branch.

---

## Option 1: Fastlane Match (Recommended - Automatic)

Match stores your certificates and provisioning profiles in a private Git repository, making them accessible to CI/CD.

### Step 1: Create a Private Certificates Repository
```bash
# On GitHub, create a new PRIVATE repository (e.g., "certificates")
```

### Step 2: Update Matchfile
Edit `fastlane/Matchfile` and replace `YOUR_ORG` with your organization/username:
```ruby
git_url("https://github.com/YOUR_ORG/certificates")
```

### Step 3: Initialize Match (First Time Only)
```bash
# This encrypts and uploads your existing certificates to the repo
bundle exec fastlane match appstore

# You'll be asked to create a passphrase - SAVE IT! You'll need it for GitHub secrets
```

### Step 4: Set Up GitHub Secrets
Go to your repository Settings → Secrets and variables → Actions, and add:

1. **APP_STORE_CONNECT_API_KEY**
   - Content: Base64-encoded API key file
   ```bash
   cat fastlane/keys/AuthKey_XXXXXXXX.p8 | base64
   ```

2. **API_KEY_ID**
   - Content: Your API Key ID (e.g., `SJK53Q9JN8`)

3. **API_ISSUER_ID**
   - Content: Your API Issuer ID (from App Store Connect)

4. **MATCH_PASSWORD**
   - Content: The passphrase you created in Step 3

5. **MATCH_GIT_BASIC_AUTHORIZATION** (if using private repo)
   - Content: Base64-encoded GitHub credentials
   ```bash
   echo -n "your_github_username:your_github_personal_access_token" | base64
   ```
   - Create a Personal Access Token at: https://github.com/settings/tokens
   - Required scope: `repo` (full control of private repositories)

### Step 5: Done! 🎉
Push to `main` branch and the workflow will automatically deploy to TestFlight.

---

## Option 2: Manual Certificate Setup (Simpler, Less Automatic)

If you don't want to set up Match, use this alternative workflow.

### Step 1: Export Your Certificates
```bash
# Open Keychain Access
# Find "Apple Distribution: YOUR_NAME (387UQ56LV7)"
# Right-click → Export → Save as .p12 file with a password
```

### Step 2: Download Provisioning Profile
- Go to https://developer.apple.com/account/resources/profiles/list
- Download the App Store provisioning profile for `com.soulverse.bigbang`

### Step 3: Set Up GitHub Secrets
Add these secrets in GitHub:

1. **APP_STORE_CONNECT_API_KEY** (same as Option 1)
2. **API_KEY_ID** (same as Option 1)
3. **API_ISSUER_ID** (same as Option 1)
4. **CERTIFICATES_P12**
   ```bash
   cat YourCertificate.p12 | base64
   ```
5. **CERTIFICATES_P12_PASSWORD**
   - The password you set when exporting
6. **PROVISIONING_PROFILE**
   ```bash
   cat YourProfile.mobileprovision | base64
   ```

### Step 4: Replace Workflow File
Replace `.github/workflows/deploy-testflight.yml` with:

```yaml
name: Deploy to TestFlight

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: macos-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.0'
          bundler-cache: true

      - name: Install CocoaPods
        run: pod install

      - name: Set up App Store Connect API Key
        run: |
          mkdir -p fastlane/keys
          echo "${{ secrets.APP_STORE_CONNECT_API_KEY }}" | base64 --decode > fastlane/keys/AuthKey_${{ secrets.API_KEY_ID }}.p8

      - name: Import Code Signing Certificates
        uses: apple-actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.CERTIFICATES_P12 }}
          p12-password: ${{ secrets.CERTIFICATES_P12_PASSWORD }}

      - name: Download Provisioning Profile
        run: |
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          echo "${{ secrets.PROVISIONING_PROFILE }}" | base64 --decode > ~/Library/MobileDevice/Provisioning\ Profiles/profile.mobileprovision

      - name: Deploy to TestFlight
        env:
          SCHEME: "Soulverse"
          BUNDLE_IDENTIFIER: "com.soulverse.bigbang"
          API_KEY_ID: ${{ secrets.API_KEY_ID }}
          API_ISSUER_ID: ${{ secrets.API_ISSUER_ID }}
          API_KEY_FILEPATH: "fastlane/keys/AuthKey_${{ secrets.API_KEY_ID }}.p8"
        run: bundle exec fastlane ios release

      - name: Clean up
        if: always()
        run: rm -f fastlane/keys/AuthKey_${{ secrets.API_KEY_ID }}.p8
```

---

## Verification

### Test Locally First
```bash
# Make sure your local build still works
SCHEME="Soulverse" bundle exec fastlane ios release
```

### Monitor GitHub Actions
1. Push a commit to `main`
2. Go to Actions tab in GitHub
3. Watch the workflow run
4. Check TestFlight for the new build

---

## Troubleshooting

### "No matching provisioning profiles found"
- Ensure your Apple Developer account has the provisioning profile
- Run `bundle exec fastlane match appstore` locally to verify

### "Authentication failed"
- Verify API_KEY_ID and API_ISSUER_ID are correct
- Check that the API key has proper permissions in App Store Connect

### "Certificate not found in keychain"
- For Option 1: Verify MATCH_PASSWORD is correct
- For Option 2: Verify CERTIFICATES_P12 is properly encoded

---

## Recommendation

**Use Option 1 (Match)** if you:
- Want automatic certificate management
- Plan to add more CI/CD in the future
- Have multiple developers/machines

**Use Option 2 (Manual)** if you:
- Want a quick setup
- Don't want to manage another repository
- Are the only developer
