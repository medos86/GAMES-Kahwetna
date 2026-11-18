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

**Décision (18/11/2026) : contrôle par question « As-tu 13 ans ou plus ? » (oui / non) au premier lancement.**
- Réponse « oui » : réglage 13+ (pubs personnalisées possibles après consentement UMP).
- Réponse « non » : pubs non personnalisées (`AdAudience.allAges`).
- Limite connue : une question déclarative n'est pas une vérification. Elle est peu fiable, et le seuil français (15 ans, art. 45 LIL) est plus élevé que 13. Cette décision doit être confirmée par le juriste (question 1 de la section 4).

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
