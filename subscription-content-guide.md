# Guide de contenu — Abonnements JUNA

> Ce document est destiné à l'équipe frontend. Pour chaque valeur renvoyée par l'API,
> vous trouverez la valeur exacte, un libellé court à afficher en UI, et une explication
> complète à utiliser dans les descriptions, tooltips ou pages de détail.

---

## 1. Type d'abonnement — champ `type`

Le type décrit **quels repas de la journée** sont couverts par l'abonnement.
Le prestataire prépare et livre (ou met à disposition) les repas correspondants
aux horaires habituels de chaque moment de la journée.

---

### `BREAKFAST`
**Libellé UI :** Petit-déjeuner

**Explication :**
Avec cet abonnement, vous recevez un petit-déjeuner chaque matin.
Le prestataire prépare votre repas du matin — que ce soit du pain, des œufs,
des bouillies, des jus ou des plats locaux du matin — et vous le livre
ou le met à disposition à l'heure du petit-déjeuner.

---

### `LUNCH`
**Libellé UI :** Déjeuner

**Explication :**
Cet abonnement couvre votre repas de midi. Chaque jour ouvré,
un repas complet préparé par le prestataire vous attend à l'heure du déjeuner.
Fini de courir chercher à manger à la pause — votre repas est déjà prêt.

---

### `DINNER`
**Libellé UI :** Dîner

**Explication :**
Avec cet abonnement, c'est le repas du soir qui est pris en charge.
Le prestataire prépare votre dîner et vous le livre ou le met à disposition
chaque soir à l'heure convenue. Vous rentrez chez vous — votre repas vous attend.

---

### `SNACK`
**Libellé UI :** Collation

**Explication :**
Cet abonnement vous fournit une collation quotidienne — un encas,
une petite faim de l'après-midi, un jus, un snack ou un goûter.
Idéal pour tenir entre deux repas sans se soucier de quoi manger.

---

### `BREAKFAST_LUNCH`
**Libellé UI :** Petit-déjeuner + Déjeuner

**Explication :**
Cet abonnement couvre deux repas par jour : le matin et le midi.
Vous commencez la journée avec un petit-déjeuner préparé,
et vous retrouvez un déjeuner complet à la pause de midi.
Votre matinée et votre après-midi sont couvertes — il ne reste que le soir.

---

### `BREAKFAST_DINNER`
**Libellé UI :** Petit-déjeuner + Dîner

**Explication :**
Cet abonnement prend en charge le début et la fin de votre journée.
Le matin, un petit-déjeuner vous est préparé pour démarrer.
Le soir, un dîner vous attend pour terminer. Le déjeuner reste à votre charge.

---

### `LUNCH_DINNER`
**Libellé UI :** Déjeuner + Dîner

**Explication :**
Deux repas par jour couverts : le midi et le soir.
Plus besoin de penser à cuisiner après le travail ni à trouver quelque chose
à manger le midi — le prestataire s'occupe des deux.
Seul le petit-déjeuner reste à votre charge.

---

### `FULL_DAY`
**Libellé UI :** Journée complète

**Explication :**
La formule la plus complète : petit-déjeuner, déjeuner et dîner sont tous inclus.
Trois repas par jour, préparés par le prestataire, sans que vous ayez à vous
soucier de quoi manger du matin au soir. La tranquillité alimentaire totale.

---

### `CUSTOM`
**Libellé UI :** Formule personnalisée

**Explication :**
Le prestataire a composé une formule sur mesure qui ne rentre pas dans
les catégories standard. Les détails exacts des repas inclus sont précisés
dans la description de l'abonnement. Lisez attentivement le contenu
avant de souscrire.

---

## 2. Durée de l'abonnement — champ `duration`

La durée indique **sur combien de jours s'étend l'abonnement** à partir
de la date de début choisie. C'est aussi ce qui détermine le nombre total
de repas que vous recevrez.

---

### `DAY`
**Libellé UI :** 1 jour

**Explication :**
Un abonnement d'une seule journée. Vous recevez les repas prévus
pour une journée uniquement — idéal pour tester un prestataire
ou pour un besoin ponctuel sans engagement.

---

### `THREE_DAYS`
**Libellé UI :** 3 jours

**Explication :**
L'abonnement court sur 3 jours consécutifs. Vous recevez vos repas
pendant 3 jours à partir de la date de début choisie.
Pratique pour un début de semaine, une courte période ou un premier essai prolongé.

---

### `WEEK`
**Libellé UI :** 1 semaine

**Explication :**
L'abonnement s'étend sur 7 jours complets, week-end inclus.
Vous êtes couvert du lundi au dimanche sans interruption.
Le prestataire livre ou met à disposition vos repas chaque jour
de la semaine, y compris le samedi et le dimanche.

---

### `TWO_WEEKS`
**Libellé UI :** 2 semaines

**Explication :**
Deux semaines complètes, soit 14 jours consécutifs sans interruption.
Week-end inclus. Une bonne option pour tester un prestataire
sur une durée significative avant de s'engager sur un mois.

---

### `MONTH`
**Libellé UI :** 1 mois

**Explication :**
Un mois complet de repas, soit environ 30 jours consécutifs,
week-end inclus. L'engagement le plus long dans la formule classique.
Vous bénéficiez de vos repas chaque jour du mois,
sans exception, du premier au dernier jour.

---

### `WORK_WEEK`
**Libellé UI :** Semaine de travail (5 jours)

**Explication :**
Cet abonnement couvre exactement une semaine de travail : du lundi au vendredi,
soit 5 jours. Le week-end n'est pas inclus — vous ne recevez rien le samedi
ni le dimanche. Parfait pour être bien nourri pendant la semaine active
sans payer pour les jours de repos.

---

### `WORK_WEEK_2`
**Libellé UI :** 2 semaines de travail (10 jours)

**Explication :**
Deux semaines de travail consécutives, soit 10 jours ouvrés (lundi à vendredi,
deux fois). Les week-ends sont exclus. Vous recevez vos repas pendant
10 jours de travail répartis sur deux semaines calendaires.

---

### `WORK_MONTH`
**Libellé UI :** Mois de travail (20 jours)

**Explication :**
Un mois entier de jours de travail, soit 20 jours ouvrés — 5 jours par semaine
pendant 4 semaines. Les week-ends et jours non ouvrés ne sont pas inclus.
C'est la formule idéale pour les actifs qui veulent être couverts
tout au long du mois de travail, sans payer les jours où ils ne travaillent pas.

---

### `WEEKEND`
**Libellé UI :** Week-end (2 jours)

**Explication :**
Cet abonnement couvre uniquement le week-end : le samedi et le dimanche.
Les jours de semaine ne sont pas inclus. Idéal pour ceux qui cuisinent
en semaine mais veulent profiter d'un service traiteur le week-end,
ou simplement se faire plaisir les jours de repos.

---

## 3. Catégorie culinaire — champ `category`

La catégorie indique le **style de cuisine** proposé par le prestataire
dans cet abonnement. Elle permet à l'utilisateur de filtrer
selon ses goûts et ses habitudes alimentaires.

---

### `AFRICAN`
**Libellé UI :** Cuisine africaine

**Explication :**
Des plats inspirés des traditions culinaires africaines —
riz, sauces, attiéké, igname, plantain, viandes et poissons préparés
selon les recettes locales. Une cuisine authentique, généreuse et savoureuse.

---

### `EUROPEAN`
**Libellé UI :** Cuisine européenne

**Explication :**
Des plats d'inspiration européenne — pâtes, grillades, salades composées,
sandwichs élaborés, soupes. Un style de cuisine occidental,
adapté aux palais habitués aux saveurs d'Europe.

---

### `ASIAN`
**Libellé UI :** Cuisine asiatique

**Explication :**
Des spécialités d'Asie — riz cantonnais, nouilles, plats sautés,
soupes asiatiques, rouleaux. Des saveurs umami, épicées ou sucrées-salées
selon les spécialités proposées par le prestataire.

---

### `AMERICAN`
**Libellé UI :** Cuisine américaine

**Explication :**
Un style inspiré de la cuisine américaine — burgers, wraps,
poulet frit, frites, plats généreux et comfort food.
Des portions copieuses et des saveurs directes.

---

### `FUSION`
**Libellé UI :** Cuisine fusion

**Explication :**
Un mélange créatif entre plusieurs traditions culinaires.
Le prestataire combine des influences africaines, asiatiques, européennes
ou autres pour créer des plats originaux qui ne se limitent pas à un seul style.
Idéal pour ceux qui aiment la variété et la découverte.

---

### `VEGETARIAN`
**Libellé UI :** Végétarien

**Explication :**
Tous les plats de cet abonnement sont sans viande ni poisson.
Des légumes, légumineuses, œufs et produits laitiers composent les repas.
Idéal pour les personnes qui ont fait le choix de ne pas consommer de chair animale.

---

### `VEGAN`
**Libellé UI :** Vegan

**Explication :**
Aucun produit d'origine animale dans ces repas — ni viande, ni poisson,
ni œufs, ni produits laitiers. Une alimentation 100 % végétale,
pour ceux qui ont adopté un mode de vie vegan.

---

### `HALAL`
**Libellé UI :** Halal

**Explication :**
Tous les repas de cet abonnement sont préparés selon les règles alimentaires halal.
Les viandes sont abattues et traitées conformément aux prescriptions islamiques.
Les ingrédients non conformes sont exclus. Idéal pour les personnes
qui suivent un régime alimentaire halal.

---

### `OTHER`
**Libellé UI :** Autre

**Explication :**
Le prestataire propose une cuisine qui ne rentre pas dans les catégories listées.
Consultez la description de l'abonnement pour connaître le style exact des repas proposés.

---

## Récapitulatif rapide — tableau de référence

### Types

| Valeur API | Libellé court | Repas couverts |
|------------|---------------|----------------|
| `BREAKFAST` | Petit-déjeuner | Matin |
| `LUNCH` | Déjeuner | Midi |
| `DINNER` | Dîner | Soir |
| `SNACK` | Collation | Entre les repas |
| `BREAKFAST_LUNCH` | Petit-déjeuner + Déjeuner | Matin + Midi |
| `BREAKFAST_DINNER` | Petit-déjeuner + Dîner | Matin + Soir |
| `LUNCH_DINNER` | Déjeuner + Dîner | Midi + Soir |
| `FULL_DAY` | Journée complète | Matin + Midi + Soir |
| `CUSTOM` | Formule personnalisée | Voir description |

### Durées

| Valeur API | Libellé court | Nombre de jours |
|------------|---------------|-----------------|
| `DAY` | 1 jour | 1 jour |
| `THREE_DAYS` | 3 jours | 3 jours consécutifs |
| `WEEK` | 1 semaine | 7 jours (week-end inclus) |
| `TWO_WEEKS` | 2 semaines | 14 jours (week-end inclus) |
| `MONTH` | 1 mois | ~30 jours (week-end inclus) |
| `WORK_WEEK` | Semaine de travail | 5 jours (lun–ven) |
| `WORK_WEEK_2` | 2 semaines de travail | 10 jours ouvrés |
| `WORK_MONTH` | Mois de travail | 20 jours ouvrés |
| `WEEKEND` | Week-end | 2 jours (sam–dim) |

### Catégories

| Valeur API | Libellé court |
|------------|---------------|
| `AFRICAN` | Cuisine africaine |
| `EUROPEAN` | Cuisine européenne |
| `ASIAN` | Cuisine asiatique |
| `AMERICAN` | Cuisine américaine |
| `FUSION` | Cuisine fusion |
| `VEGETARIAN` | Végétarien |
| `VEGAN` | Vegan |
| `HALAL` | Halal |
| `OTHER` | Autre |
