# ExpiryEase - Smart Inventory & Expiry Tracker

ExpiryEase is een geavanceerde Flutter-applicatie ontworpen om je voorraad te beheren en verspilling tegen te gaan door de vervaldatums van je producten nauwkeurig bij te houden.

## Speciale Integraties

### 1. Barcode Scanning (Google ML Kit)
De app maakt gebruik van **Google ML Kit Barcode Scanning**. Hiermee kun je razendsnel producten toevoegen door simpelweg de barcode te scannen met de camera van je telefoon. De scanner herkent verschillende formaten, waaronder EAN-8 en EAN-13.

### 2. Productinformatie (OpenFoodFacts API)
Zodra een barcode is gescand, koppelt de app deze aan de **OpenFoodFacts database**. Hierdoor worden productgegevens zoals de naam, het merk, de hoeveelheid en een afbeelding automatisch opgehaald en ingevuld, wat handmatige invoer tot een minimum beperkt.

### 3. Cloud Opslag & Authenticatie (Firebase)
*   **Firebase Auth:** Zorgt voor een veilige login- en registratieprocedure, inclusief wachtwoordherstel.
*   **Cloud Firestore:** Slaat al je inventarisgegevens in real-time op in de cloud. Dit betekent dat je gegevens veilig zijn en gesynchroniseerd blijven over verschillende apparaten.
*   **Firebase Storage:** Wordt gebruikt voor het veilig hosten van door de gebruiker geüploade productfoto's.

### 4. Lokale Notificaties (Flutter Local Notifications)
De app bevat een slim notificatiesysteem dat je proactief waarschuwt:
*   **Bijna over datum:** Je ontvangt een melding 3 dagen voordat een product verloopt.
*   **Vervallen:** Je ontvangt een melding op de dag van de vervaldatum zelf.
*   **Achtergrond ondersteuning:** Dankzij speciale Android-receivers werken deze meldingen ook als de app volledig is afgesloten of als de telefoon opnieuw is opgestart.

### 5. Adaptieve Gebruikersinterface
De app is ontworpen om zich aan te passen aan het platform:
*   **Android/iOS Dialogen:** Pop-ups en datumkiezers zien eruit als native Android (Material) of iOS (Cupertino) elementen, afhankelijk van je toestel.
*   **Dark Mode:** De volledige interface, inclusief de login- en navigatieschermen, past zich automatisch aan aan de donkere modus van je systeem voor een rustige kijkervaring in de avond.

### 6. IoT Meerwaarde: Open Kitchen Mode (Tablet)
ExpiryEase gaat verder dan alleen een smartphone-app. Met de speciale **Open Kitchen Mode** fungeert de app als een centraal IoT-dashboard voor in de keuken.
*   **Tablet Optimalisatie:** De interface past zich aan voor grotere schermen, waarbij een overzichtelijk grid van je volledige voorraad wordt getoond.
*   **Real-time Monitoring:** Hang een tablet aan je koelkast of muur om in één oogopslag de tijd, datum en de status van je voorraad te zien (waaronder kritieke waarschuwingen voor bijna verlopen producten en lage voorraad).
*   **Smart Home Hub:** Deze modus transformeert je apparaat in een slimme keukenassistent die verspilling helpt minimaliseren zonder dat je actief je telefoon hoeft te pakken.

### 7. Over-the-Air Updates (Shorebird)
Deze app is voorbereid op **Shorebird**, wat betekent dat kritieke bugfixes en Dart-code updates direct naar de gebruikers kunnen worden gepusht zonder dat er een nieuwe versie in de App Store of Play Store hoeft te worden geüpload.

---

## Installatie & Gebruik
1. Voer `flutter pub get` uit om alle afhankelijkheden te installeren.
2. Zorg voor een werkende Firebase-configuratie (`google-services.json` voor Android en `GoogleService-Info.plist` voor iOS).
3. Gebruik `flutter run` om de app te starten.
