# Templates Email Supabase - LocaGest

Ces templates HTML sont conçus pour être utilisés avec Supabase Auth.

## Configuration

1. Allez sur [app.supabase.com](https://app.supabase.com)
2. Sélectionnez votre projet
3. Naviguez vers **Authentication > Email Templates**

## Templates disponibles

### Templates d'authentification (OTP)

Ces templates envoient un code OTP à 6 chiffres pour vérification.

| Template | Fichier | Usage |
|----------|---------|-------|
| Confirm signup | `confirm_signup.html` | Confirmation d'inscription |
| Magic Link | `magic_link.html` | Connexion sans mot de passe |
| Reset Password | `reset_password.html` | Réinitialisation mot de passe |
| Change Email Address | `change_email.html` | Changement d'email |

### Templates de notification

Ces templates informent l'utilisateur des modifications apportées à son compte (alertes de sécurité).

| Template | Fichier | Usage |
|----------|---------|-------|
| Password Changed | `password_changed.html` | Notification de changement de mot de passe |
| Email Changed | `email_changed.html` | Notification de changement d'adresse email |
| Phone Changed | `phone_changed.html` | Notification de changement de numéro de téléphone |
| Identity Attached | `identity_attached.html` | Notification de liaison d'une identité externe (OAuth) |
| Identity Removed | `identity_removed.html` | Notification de suppression d'une identité externe |
| MFA Enabled | `mfa_enabled.html` | Notification d'activation de l'authentification multi-facteur |
| MFA Disabled | `mfa_disabled.html` | Notification de désactivation de l'authentification multi-facteur |

## Installation

Pour chaque template :

1. Ouvrez le fichier HTML correspondant
2. Copiez tout le contenu
3. Collez dans le champ "Source" du template correspondant sur Supabase
4. Sauvegardez

## Variables Supabase

### Templates OTP
- `{{ .Token }}` - Code OTP à 6 chiffres
- `{{ .Email }}` - Email de l'utilisateur
- `{{ .SiteURL }}` - URL du site
- `{{ .ConfirmationURL }}` - Lien de confirmation (non utilisé avec OTP)

### Templates de notification
- `{{ .Email }}` - Email de l'utilisateur
- `{{ .SiteURL }}` - URL du site

## Personnalisation

### Couleurs utilisées

| Élément | Usage | Hex |
|---------|-------|-----|
| Primary (Bleu) | En-tête, liens | `#1591DC` |
| Header Background | Fond d'en-tête | `#ccebfc` |
| Success (Vert) | Confirmations, succès | `#28a745` |
| Warning (Orange) | Avertissements | `#F5A623` |
| Danger (Rouge) | Alertes critiques | `#dc3545` |
| Info (Bleu clair) | Informations | `#0d47a1` |

### Logo

Le logo est hébergé sur Supabase Storage :
```
https://uvontlgbwibcybytcfks.supabase.co/storage/v1/object/public/publics/logo-locagest-transparent.png
```

## Test

Pour tester les emails :
1. Configurez un SMTP personnalisé (SendGrid, Resend, etc.) ou utilisez Inbucket en local
2. Effectuez l'action correspondante (inscription, reset password, etc.)
3. Vérifiez l'email reçu
