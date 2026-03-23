# Required GitHub Secrets

## Android Release Signing
- `STORE_FILE` - Base64 encoded keystore file
- `STORE_PASSWORD` - Keystore password
- `KEY_ALIAS` - Key alias
- `KEY_PASSWORD` - Key password

## Google Play Publishing
- `GOOGLE_PLAY_SERVICE_ACCOUNT` - JSON key for Google Play Developer API service account

## Generate keystore for local testing
```bash
cd android/app
keytool -genkey -v -keystore sundeefundee.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sundeefundee
```

## Encode keystore for GitHub secret
```bash
base64 -i sundeefundee.jks -o store_file_base64.txt
# Use contents of store_file_base64.txt as STORE_FILE secret value
```

## Google Play Service Account Setup
1. Go to Google Cloud Console > APIs & Services > Credentials
2. Create new Service Account
3. Grant "Firebase App Distribution Admin" role
4. Go to Google Play Console > Settings > Developer > Users & permissions
5. Add service account email with "Admin" permissions
6. Generate JSON key for the service account
7. Encode and add as `GOOGLE_PLAY_SERVICE_ACCOUNT` secret
