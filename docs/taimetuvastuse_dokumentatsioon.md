# Taimetuvastuse Dokumentatsioon

## Ülevaade

Käesolev dokument kirjeldab taimetuvastuse funktsionaalsuse tööpõhimõtet Nature Photo DB rakenduses, mis kasutab Plant.ID teenust taimede tuvastamiseks fotodelt. Dokumentatsioon kajastab lahenduse seisu seisuga 30. aprill 2025.

## Arhitektuur

Taimetuvastuse lahendus koosneb kolmest peamisest komponendist:

1. **Backend API** - Vahendab suhtlust Plant.ID API-ga, töötleb andmeid ja salvestab tulemused andmebaasi
2. **Frontend UI** - Võimaldab kasutajal algatada taimetuvastust ja kuvab tulemused
3. **Plant.ID integratsioon** - Tegelik taimetuvastuse teenus, millega suhtlemist haldab `plant_identification.py` moodul

## Backend komponendid

### `utils/plant_identification.py`

See moodul sisaldab `PlantIdClient` klassi, mis vastutab Plant.ID API-ga suhtlemise eest. Klass pakub järgmisi funktsionaalsusi:

1. **Autentimine** - Kasutab API võtit Plant.ID teenusega suhtlemiseks
2. **Päringu koostamine** - Ettevalmistab ja saadab päringud Plant.ID API-le
3. **Vastuste töötlemine** - Töötleb vastused struktureeritud andmeteks

Tähtis osa loogikast on API võtme käitlemine:
- API võti loetakse andmebaasi `app_settings` tabelist
- Kui võti puudub, annab süsteem sellest kasutajale teada, mitte ei kasuta simulatsioonirežiimi
- API võtme saab lisada administreerimisliidese kaudu

### `routers/plant_id_api.py`

See moodul sisaldab FastAPI ruutereid, mis pakuvad järgmisi endpoint'e:

1. **`POST /plant_id/`** - Tuvastab taimed uuel üleslaetud pildil
2. **`POST /plant_id/existing/{photo_id}`** - Tuvastab taimed olemasoleval pildil
3. **`POST /plant_id/batch`** - Tuvastab taimed mitmel pildil korraga

Taimetuvastuse protsess hõlmab järgmisi samme:
1. API võti loetakse andmebaasist või võetakse päringu parameetritest
2. Luuakse `PlantIdClient` instants ilma simulatsioonita
3. Teostatakse taimetuvastus, saates pildi Plant.ID API-le
4. Töödeldakse vastus struktureeritud andmeteks
5. Salvestatakse tuvastatud liigid andmebaasi `species` tabelisse, kui neid veel ei ole
6. Luuakse seosed piltide ja liikide vahel `photo_species_relation` tabelisse
7. Tagastatakse tuvastamise tulemused JSON formaadis

### Andmebaasi mudelid

- **`models/species_models.py`** - Sisaldab `Species` mudelit taimeliikide jaoks
- **`models/relation_models.py`** - Sisaldab `PhotoSpeciesRelation` mudelit piltide ja liikide seoste jaoks
- **`models/settings_models.py`** - Sisaldab `AppSettings` mudelit, mille kaudu hoitakse Plant.ID API võtit

## Frontend komponendid

### `FotodeBrowser.js`

See komponent vastutab taimetuvastuse algatamise ja tulemuste kuvamise eest kasutajaliideses:

1. **Funktsionaalsus**:
   - `handlePhotoClick`: Laadib foto detailid, sh juba tuvastatud liigid
   - `handleAIIdentify`: Saadab päringu taimetuvastuseks ja töötleb tulemusi
   - Olek `identificationSuccess` jälgib tuvastamise õnnestumist

2. **Töövoog taimetuvastuse algatamisel**:
   - Kasutaja vaatab foto detailvaadet
   - Kasutaja klikib "Tuvasta AI-ga taimed" nupul
   - Frontend teeb POST päringu `{API_BASE_URL}/plant_id/existing/{photoId}`
   - Oodatakse vastust ja kuvatakse tulemused otse kasutajaliidesesse
   - Liikides kuvatakse taime teaduslik nimetus, tavanimi ja sugukond

3. **Võimalikud veaolukorrad ja nende käsitlemine**:
   - Kui API võti on puudu: Kuvatakse vastav veateade, mis juhendab kasutajat API võtit lisama
   - Kui taimetuvastuse API tagastab tühja vastuse: Kuvatakse teade, et liike ei tuvastatud
   - Kui taimetuvastuse API vastus on edukas: Kuvatakse teade "Taimed edukalt tuvastatud!"

## Oluline täiustus: otse kuvamine

Lahenduse oluline osa on **tulemuste vahetu kuvamine**. Frontend ei sõltu taimetuvastuse tulemuste andmebaasi salvestamisest, vaid:

1. Saadab päringu tuvastuse API-le
2. Saab vastuseks struktureeritud andmed tuvastatud taimede kohta
3. Kuvab need andmed otse kasutajaliideses, ilma uut päringut andmebaasi tegemata
4. Paralleelselt proovib küll andmebaasi värskendada, kuid kasutaja ei pea ootama andmebaasi salvestuse õnnestumist

See lahendus tagab, et kasutaja näeb tuvastustulemusi sõltumata andmebaasi operatsioonide õnnestumisest.

## API võtme haldus

Plant.ID API võtme haldus käib läbi administreerimisliidese:

1. API võti salvestatakse andmebaasi `app_settings` tabelisse võtmega `PLANT_ID_API_KEY`
2. Kui API võti puudub, kuvatakse kasutajale teade "Taimetuvastuse jaoks on vaja seadistada Plant.ID API võti administreerimislehel."
3. Võtme lisamiseks tuleb minna administreerimislehele ja sisestada võti vastavasse vormisse

## Simulatsioonirežiim

Lahendus ei kasuta simulatsioonirežiimi, nagu oli algselt. Põhjused:
- Simulatsioon ei anna realistlikke tulemusi
- Simulatsiooniga on risk, et lõppkasutaja arvab, et süsteem töötab, kuigi tegelikult mitte
- Selge veateade on parem kui simuleeritud tulemused

## Edaspidiseks arenduseks

1. Leida lahendus andmebaasi salvestusprobleemidele, et tuvastatud liigid säiliksid kindlalt
2. Lisada võimalus täiendada tuvastustulemusi käsitsi
3. Parandada andmebaasi salvestuse töökindlust
4. Optimeerida API võtme lugemist, et vältida liigseid päringuid

## Näidis API vastused

Õnnestunud vastus Plant.ID API-lt (fragment):
```json 
[
  {
    "scientific_name": "Phalaenopsis",
    "common_names": ["Moth orchids", "Phals"],
    "probability": 0.7336,
    "family": "Orchidaceae",
    "description": "Phalaenopsis (), also known as moth orchids, is a genus of about seventy species of plants in the family Orchidaceae..."
  },
  {
    "scientific_name": "Hemerocallis fulva",
    "common_names": ["orange daylily", "ditch lily"],
    "probability": 0.1117,
    "family": "Asphodelaceae",
    "description": "Hemerocallis fulva, the orange day-lily, tawny daylily, corn lily, tiger daylily..."
  }
]
```

## Veaotsing

Kui taimetuvastus ei tööta oodatult:

1. Kontrolli logisid veateadete osas (`backend.log`)
2. Veendu, et Plant.ID API võti on lisatud ja kehtiv
3. Testi API-t otse (nt: `curl -X POST http://localhost:8000/plant_id/existing/<photo_id>`)
4. Kontrolli, kas foto on korrektselt salvestatud ja kättesaadav

## Kokkuvõte

Taimetuvastuse lahendus töötab täielikult integreeritud Plant.ID API-ga, ilma simulatsioonita. Frontend kuvab tuvastustulemused kasutajale olenemata andmebaasi salvestuse õnnestumisest. API võti on vajalik eeldus funktsionaalsuse toimimiseks ja seda tuleb hallata läbi administreerimisliidese.