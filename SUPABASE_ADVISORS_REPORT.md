# Rapport d'Avertissements Supabase - LocaGest

**Date:** 13 janvier 2026
**Source:** Supabase Studio Advisors (http://127.0.0.1:55323/project/default)

---

## Sommaire

| Catégorie | Nombre d'avertissements |
|-----------|------------------------|
| Sécurité | 15 |
| Performance | 126 |
| **Total** | **141** |

---

## Avertissements de Sécurité (15)

### Fonctions avec search_path mutable

Toutes les fonctions suivantes ont un **search_path mutable**, ce qui peut permettre des attaques par injection de schéma. Un attaquant pourrait créer un objet malveillant dans un schéma prioritaire dans le search_path.

| Fonction | Description |
|----------|-------------|
| `public.check_admin_count` | Vérification du nombre d'administrateurs |
| `public.reset_login_attempts` | Réinitialisation des tentatives de connexion |
| `public.check_login_attempt` | Vérification des tentatives de connexion |
| `public.record_failed_login` | Enregistrement des échecs de connexion |
| `public.update_building_total_units` | Mise à jour du nombre total d'unités |
| `public.set_tenant_created_by` | Attribution du créateur de locataire |
| `public.generate_receipt_number` | Génération du numéro de quittance |
| `public.set_payment_receipt_number` | Attribution du numéro de reçu de paiement |
| `public.set_payment_created_by` | Attribution du créateur de paiement |
| `public.update_rent_schedule_on_payment` | Mise à jour de l'échéancier après paiement |
| `public.update_updated_at_column` | Mise à jour du timestamp updated_at |
| `public.is_admin` | Vérification du rôle admin |
| `public.get_my_role` | Récupération du rôle utilisateur |
| `public.handle_new_user` | Gestion des nouveaux utilisateurs |
| `public.set_lease_created_by` | Attribution du créateur de bail |

**Recommandation:**
```sql
-- Pour chaque fonction, ajouter:
SET search_path = public, pg_temp;
-- Ou utiliser des noms de schéma qualifiés complets
```

---

## Avertissements de Performance (126)

### 1. Politiques RLS avec ré-évaluation de fonctions auth (26 avertissements)

Les politiques RLS suivantes utilisent `auth.<function>()` sans sous-requête SELECT, ce qui provoque une ré-évaluation pour chaque ligne et dégrade les performances à grande échelle.

#### Table `public.profiles` (3 politiques)
| Politique | Action |
|-----------|--------|
| `System can insert profiles` | INSERT |
| `Users can update own profile` | UPDATE |
| `Users can view profiles` | SELECT |

#### Table `public.buildings` (3 politiques)
| Politique | Action |
|-----------|--------|
| `admin_full_access` | ALL |
| `assistant_read_only` | SELECT |
| `gestionnaire_own_buildings` | ALL |

#### Table `public.units` (3 politiques)
| Politique | Action |
|-----------|--------|
| `admin_full_access` | ALL |
| `assistant_read_only` | SELECT |
| `gestionnaire_own_units` | ALL |

#### Table `public.tenants` (4 politiques)
| Politique | Action |
|-----------|--------|
| `admin_full_access` | ALL |
| `assistant_create` | INSERT |
| `assistant_read` | SELECT |
| `gestionnaire_own_tenants` | ALL |

#### Table `public.leases` (3 politiques)
| Politique | Action |
|-----------|--------|
| `admin_full_access_leases` | ALL |
| `assistant_read_leases` | SELECT |
| `gestionnaire_own_leases` | ALL |

#### Table `public.rent_schedules` (3 politiques)
| Politique | Action |
|-----------|--------|
| `admin_full_access_rent_schedules` | ALL |
| `assistant_read_rent_schedules` | SELECT |
| `gestionnaire_own_rent_schedules` | ALL |

#### Table `public.payments` (4 politiques)
| Politique | Action |
|-----------|--------|
| `admin_full_access_payments` | ALL |
| `assistant_insert_payments` | INSERT |
| `assistant_read_payments` | SELECT |
| `gestionnaire_own_payments` | ALL |

#### Table `public.receipts` (3 politiques)
| Politique | Action |
|-----------|--------|
| `receipts_insert_policy` | INSERT |
| `receipts_select_policy` | SELECT |
| `receipts_update_policy` | UPDATE |

**Recommandation:**
```sql
-- AVANT (lent):
auth.uid() = user_id

-- APRES (optimisé):
(SELECT auth.uid()) = user_id
```

Documentation: https://supabase.com/docs/guides/database/postgres/row-level-security#call-functions-with-select

---

### 2. Politiques permissives multiples (~100 avertissements)

Plusieurs tables ont des politiques permissives multiples pour les mêmes combinaisons rôle/action. Cela peut être intentionnel mais mérite une revue.

#### Table `public.buildings`
| Rôle | Action | Politiques |
|------|--------|------------|
| anon | SELECT | admin_full_access, assistant_read_only, gestionnaire_own_buildings |
| anon | INSERT | admin_full_access, gestionnaire_own_buildings |
| anon | UPDATE | admin_full_access, gestionnaire_own_buildings |
| anon | DELETE | admin_full_access, gestionnaire_own_buildings |
| authenticated | SELECT | admin_full_access, assistant_read_only, gestionnaire_own_buildings |
| authenticated | INSERT | admin_full_access, gestionnaire_own_buildings |
| authenticated | UPDATE | admin_full_access, gestionnaire_own_buildings |
| authenticated | DELETE | admin_full_access, gestionnaire_own_buildings |
| authenticator | SELECT | admin_full_access, assistant_read_only, gestionnaire_own_buildings |
| dashboard_user | SELECT | admin_full_access, assistant_read_only, gestionnaire_own_buildings |

#### Table `public.leases`
| Rôle | Action | Politiques |
|------|--------|------------|
| anon | SELECT | admin_full_access_leases, assistant_read_leases, gestionnaire_own_leases |
| anon | INSERT | admin_full_access_leases, gestionnaire_own_leases |
| anon | UPDATE | admin_full_access_leases, gestionnaire_own_leases |
| anon | DELETE | admin_full_access_leases, gestionnaire_own_leases |
| authenticated | SELECT | admin_full_access_leases, assistant_read_leases, gestionnaire_own_leases |
| authenticated | INSERT | admin_full_access_leases, gestionnaire_own_leases |
| authenticated | UPDATE | admin_full_access_leases, gestionnaire_own_leases |
| authenticated | DELETE | admin_full_access_leases, gestionnaire_own_leases |

**Note:** Les mêmes patterns s'appliquent aux tables `units`, `tenants`, `payments`, `rent_schedules`, et `receipts`.

---

### 3. Requêtes Lentes

Les requêtes suivantes ont été identifiées comme lentes:

| Requête | Temps moyen | Appels |
|---------|-------------|--------|
| `SELECT name FROM pg_timezone_names` | 0.10s | 1 |
| Requête non identifiée | 0.04s | 1 |
| Requête non identifiée | 0.03s | 1 |
| `CREATE OR REPLACE FUNCTION pg_temp.count_estimate(...)` | 0.02s | 2 |
| Requête non identifiée | 0.02s | 1 |

---

## Métriques de Performance du Frontend

| Métrique | Valeur |
|----------|--------|
| Temps de chargement total | 1616ms |
| DOM Content Loaded | 1616ms |
| DOM Interactive | 365ms |
| Time to First Byte (TTFB) | 90ms |
| Ressources totales chargées | 250 |
| Taille totale transférée | 7.1 MB |

### Ressources volumineuses (>100KB)

| Fichier | Taille | Durée |
|---------|--------|-------|
| editor.main.js (Monaco) | 799 KB | 253ms |
| 3432dc8ff3a87f2b.js | 196 KB | 956ms |
| b02ccfcfec292ef3.js | 153 KB | 963ms |
| + 15 autres fichiers > 100KB | - | - |

---

## Autres Observations

### Protocole HTTP
- **Avertissement:** La page est servie via HTTP (non HTTPS)
- **Impact:** Les données sont transmises sans chiffrement
- **Note:** Acceptable pour le développement local, mais à sécuriser en production

### Stockage Local
- LocalStorage utilisé: 2 clés

---

## Actions Recommandées

### Priorité Haute
1. **Corriger les fonctions avec search_path mutable** - Risque de sécurité
2. **Optimiser les politiques RLS** - Remplacer `auth.uid()` par `(SELECT auth.uid())`

### Priorité Moyenne
3. **Revoir les politiques permissives multiples** - S'assurer que c'est intentionnel
4. **Optimiser les requêtes lentes** si elles sont fréquentes en production

### Priorité Basse
5. **Configurer HTTPS** pour l'environnement de production

---

## Ressources

- [Documentation Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Optimisation des performances RLS](https://supabase.com/docs/guides/database/postgres/row-level-security#call-functions-with-select)
- [Sécurisation du search_path PostgreSQL](https://www.postgresql.org/docs/current/ddl-schemas.html#DDL-SCHEMAS-PATH)
