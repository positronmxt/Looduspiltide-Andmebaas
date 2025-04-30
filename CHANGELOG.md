# Muudatuste logi (CHANGELOG)

Selles failis dokumenteeritakse projekti olulisemad muudatused versioonide kaupa.

## 0.1.0 - 30. aprill 2025

### Lisatud
- Taimetuvastuse funktsionaalsus, mis integreerib Plant.ID API-ga
- Täielik taimetuvastuse dokumentatsioon

### Muudetud
- Eemaldatud automaatne simulatsioonirežiim taimetuvastuses
- Täiustatud UI, et kuvada taimetuvastuse tulemusi otse, sõltumata andmebaasi salvestusest

### Parandatud
- Lahendatud probleem, kus taimetuvastuse eduteade jäi nähtavaks ka peale uue foto valimist
- Parandatud API võtme korrektne käitlemine
- API tagastab nüüd selge veateate, kui Plant.ID API võti puudub

### Tehnilised muudatused
- Täiendatud `plant_identification.py` moodulit simulatsioonirežiimi korrektseks käitlemiseks
- Täiustatud `plant_id_api.py` endpoint'e, et tagada veateadete korrektne kuvamine
- Muudetud `FotodeBrowser.js` komponenti taimetuvastuse tulemuste otse kuvamiseks