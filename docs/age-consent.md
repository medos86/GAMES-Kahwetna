# Âge de consentement et contrôle d'âge (issue #481)

Date de vérification : 18/11/2026. Document de travail, **ce n'est pas un avis juridique**.
Un juriste doit valider les points marqués « à valider ».

## 1. Tableau pays / seuil / source

| Pays | Seuil de consentement numérique | Source | Statut |
|---|---|---|---|
| France | 15 ans (en dessous : consentement conjoint mineur + titulaire de l'autorité parentale) | Loi Informatique et Libertés, art. 45 (cité par donneespersonnelles.fr) | Vérifié sur source secondaire ; à confirmer sur Légifrance |
| UE (RGPD) | 16 par défaut ; chaque État peut descendre jusqu'à 13 | RGPD art. 8 | Vérifié sur source secondaire ; à confirmer sur EUR-Lex |
| Suède, Belgique | 13 | RGPD art. 8 (national) | Source secondaire (sota.io) |
| Danemark, Finlande, Portugal | 13 | Idem (cité dans le code de l'article, non vérifié) | **À valider** |
| Autriche, Espagne, Italie | 14 | Idem | Source secondaire |
| Tchéquie | 15 | Idem (non vérifié) | **À valider** |
| Allemagne, Pays-Bas, Irlande, Pologne, Luxembourg | 16 | Idem | Source secondaire |
| Royaume-Uni | 13 | UK GDPR art. 8 | Source secondaire |
| États-Unis | Règle COPPA : moins de 13 ans | COPPA | Source secondaire |
| Tunisie | Non trouvé | Loi 2004-63 : aucun seuil d'âge dans la page consultée | **À valider** (texte officiel, INPDP) |
| Algérie | Non trouvé | Loi 18-07 : consentement exprès (art. 7), rien sur les mineurs dans la page consultée | **À valider** (texte officiel, ANPDP) |
| Maroc | Non trouvé | Loi 09-08 : consentement (art. 4), rien sur les mineurs dans la page consultée (source de 2012) | **À valider** (texte officiel, CNDP) |

Point d'attention : le seuil français ne s'applique pas à toute l'Europe. Pour un service accessible dans plusieurs pays, il faut retenir le seuil du pays de chaque utilisateur, ou le plus strict si l'on ne peut pas le déterminer.

## 2. Décision proposée sur le contrôle d'âge (à valider)

Contexte : le public est déclaré 13+ (décision #467).

Proposition :
- **Pas de date de naissance demandée** : elle ajoute de la donnée personnelle sensible à collecter, sans fiabilité réelle.
- **Pas de contrôle d'âge au premier lancement pour le jeu**, car le jeu ne collecte pas de données nominatives.
- **Consentement pub personnalisée** : affiché via UMP ; l'utilisateur n'est proposé pour la pub personnalisée que si le public retenu (13+) et le consentement le permettent.
- **Point de bascule** : si la classification Google Play ou une revue montre un public enfant, passer en « tous âges » avec pubs non personnalisées (voir `lib/core/services/ad_audience.dart`).

**Décision du 18/11/2026 (tous âges, pubs non personnalisées) : remplacée.**

**Décision du 19/11/2026 : public 13+ demandé par le responsable du projet.** Le code la met en place (voir section 5) ; le réglage `AdAudience.current` est passé à 13+ le 19/11/2026, sur demande du responsable du projet, **sans avis juridique** (#575 ouverte).
- Question d'âge « As-tu 13 ans ou plus ? » au premier lancement, réponse non bloquante.
- Pubs personnalisées seulement pour : réponse 13+, public 13+, consentement UMP accordé.
- Retour à « tous âges » : une ligne dans `lib/core/services/ad_audience.dart`.

## 3. Traçabilité du consentement

- Stocker localement le choix de consentement (`ad_consent.dart`, `SharedPreferences`) avec date et version du texte affiché.
- Aucune donnée d'identité envoyée : seul le statut de consentement est conservé.
- Réinitialisable depuis les réglages.
- À valider : la durée de conservation et la prise en charge par UMP.

## 4. Avis juridique (critère d'acceptation non rempli)

Non obtenu. Questions à poser à un juriste :
1. Le seuil à retenir pour un public 13+ hébergé en France est-il 15 ans (art. 45 LIL) ou 13 ans compte tenu de la décision de public ?
2. Une question « 13 ans ou plus ? » suffit-elle comme contrôle, ou faut-il une vérification plus forte ?
3. Quel seuil appliquer aux utilisateurs de Tunisie, d'Algérie et du Maroc ?
4. La traçabilité du consentement local est-elle suffisante, ou faut-il la conserver côté serveur ?

## 5. Implémentation (état au 19/11/2026)

| Issue | Sujet | État |
|---|---|---|
| #565 | Décision et choix à trancher | Ouverte : forme du contrôle et seuil France |
| #566 | Modèle et persistance de la réponse | Mergée (PR #576) |
| #567 | Écran « As-tu 13 ans ou plus ? » | Mergée (PR #579) |
| #568 | Changer la réponse dans les Paramètres | Mergée (PR #585) |
| #569 | Requête pub personnalisée seulement pour 13+ consentant | Mergée (PR #586) |
| #570 | Revoir les choix UMP, réinitialiser l'âge | Mergée (PR #604) |
| #571 | Textes FR et AR, relecture | Mise en page testée (PR #606) ; relecture AR par une personne arabophone ouverte |
| #572 | Tests widget et goldens | Tests widget et mise en page faits ; goldens à générer dans la CI |
| #573 | Ce document | En cours |
| #574 | Questionnaire Play Console et classification Apple | Ouverte (action manuelle) |
| #575 | Avis juridique | Ouverte : non attendu pour le passage à 13+ (demande du 19/11) ; toujours requis avant production |

Points non couverts par le code, à vérifier dans le SDK :
- Non-transmission de l'identifiant publicitaire (AAID) quand l'âge est inconnu (politique Families). Non implémentée.
- Pubs récompensées ou opt-in : fermeture après 5 secondes, si le public inclut les enfants.
