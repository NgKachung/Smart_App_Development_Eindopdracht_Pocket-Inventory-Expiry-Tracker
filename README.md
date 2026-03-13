# Smart Inventory & Expiry Tracker

## Projectomschrijving
De **Smart Inventory Tracker** is een app die ik bouw om mensen te helpen hun voorraadkast beter te beheren. Het doel is simpel: zorgen dat er minder eten in de vuilnisbak belandt door precies bij te houden wat je in huis hebt en wanneer het vervalt.

### Waarom een App en geen Website?
Ik heb bewust voor een mobiele app gekozen omdat dit een paar grote voordelen heeft voor in de keuken:
* **Camera-integratie:** Je kunt barcodes super snel scannen met je camera, wat op een website vaak traag of onhandig werkt.
* **Notificaties:** De app stuurt je proactief een seintje als er iets bijna over datum gaat, zelfs als je de app niet gebruikt.
* **Firebase Offline:** In een kelder of voorraadkast is de wifi vaak slecht. Met deze app kun je gewoon blijven scannen; de data synchroniseert pas als je weer verbinding hebt.

---

## Kernfunctionaliteiten
* **Eigen Accounts:** Via Firebase Auth maak je een account aan. Zo krijg je alleen je eigen "virtuele koelkast" te zien en blijven je gegevens privé.
* **Barcode Scanner:** Ik koppel de camera aan de Open Food Facts API. Scan een product en de app zoekt meteen de naam en informatie op.
* **Live Voorraad:** Je voorraadlijst staat in de cloud. Als je iets aanpast op je telefoon, zie je dat meteen op al je andere apparaten.
* **Houdbaarheidssysteem:** De app werkt met een overzichtelijk kleurensysteem (groen/oranje/rood) zodat je ziet wat je als eerste moet opeten.
* **Push-meldingen:** Je krijgt automatisch een berichtje wanneer een product in jouw lijst de houdbaarheidsdatum nadert.

---

## IoT Integratie (Meerwaarde)
De app fungeert als de centrale hub voor je slimme keuken. Omdat ik **Firebase Cloud Firestore** gebruik, wordt de data in real-time gedeeld. 

**Scenario:** Zodra je een product toevoegt, wordt de database bijgewerkt. Je zou dan bijvoorbeeld een schermpje in de keuken kunnen hangen (zoals een tablet of Raspberry Pi) dat hetzelfde account gebruikt. Dat scherm toont dan altijd de actuele voorraad zonder dat je iets handmatig hoeft te vernieuwen.

---

## Technische Stack
* **Frontend:** Flutter (Dart)
* **Backend & Auth:** Firebase Cloud Firestore & Firebase Authentication.
* **State Management:** [Vul hier in: bijv. Provider of Riverpod]
* **API's:** Open Food Facts voor de productgegevens.
* **Packages:** firebase_auth, cloud_firestore, mobile_scanner, flutter_local_notifications.

---

## Database Structuur (Firestore)
Ik beveilig de data met Firebase Rules, zodat je alleen bij je eigen producten kunt.

**Collection: inventory**
| Veld | Type | Wat doet het? |
| :--- | :--- | :--- |
| userId | String | De unieke ID van de gebruiker (om de lijst te filteren). |
| name | String | De naam van het gescande product. |
| barcode | String | De barcode (EAN-code) van het item. |
| expiryDate | Timestamp | De datum waarop het product vervalt. |
| status | String | Of het product nog 'op voorraad' is of al 'opgebruikt'. |

---

## Roadmap & Updates
* **Updates:** Ik wil kijken of ik Shorebird kan gebruiken om de app te updaten zonder een nieuwe installatie te forceren.
* **Feedback:** Ik hou de GitHub Issues bij voor opmerkingen van de docenten.
* **Security:** Ik stel regels in op Firebase zodat je nooit de koelkast van een andere gebruiker kunt inzien.
