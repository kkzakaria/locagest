# Templates Email Supabase - LocaGest

Ces templates HTML sont conçus pour être utilisés avec Supabase Auth.

## Configuration

1. Allez sur [app.supabase.com](https://app.supabase.com)
2. Sélectionnez votre projet
3. Naviguez vers **Authentication > Email Templates**

## Templates disponibles

| Template | Fichier | Usage |
|----------|---------|-------|
| Confirm signup | `confirm_signup.html` | Confirmation d'inscription |
| Magic Link | `magic_link.html` | Connexion sans mot de passe |
| Reset Password | `reset_password.html` | Réinitialisation mot de passe |
| Change Email Address | `change_email.html` | Changement d'email |

## Installation

Pour chaque template :

1. Ouvrez le fichier HTML correspondant
2. Copiez tout le contenu
3. Collez dans le champ "Source" du template correspondant sur Supabase
4. Sauvegardez

## Variables Supabase

Ces templates utilisent la variable `{{ .Token }}` pour afficher le code OTP à 6 chiffres.

Autres variables disponibles :
- `{{ .Email }}` - Email de l'utilisateur
- `{{ .SiteURL }}` - URL du site
- `{{ .ConfirmationURL }}` - Lien de confirmation (non utilisé avec OTP)

## Personnalisation

### Couleurs utilisées

| Élément | Couleur | Hex |
|---------|---------|-----|
| Primary (Bleu) | Header signup/magic link | `#1591DC` |
| Secondary (Orange) | Header reset password | `#F5A623` |
| Success (Vert) | Header change email | `#28a745` |

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
