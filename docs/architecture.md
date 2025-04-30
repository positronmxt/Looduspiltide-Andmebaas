# Looduspiltide Andmebaasi Arhitektuur

## Ülevaade

Looduspiltide Andmebaas on täisfunktsionaalne rakendus, mis võimaldab kasutajatel üles laadida, katalogiseerida ja sirvida looduspilte. Rakendus kasutab Plant.id API teenust, et tuvastada piltidel olevaid taimeliike, ning võimaldab filtreerimist kuude kaupa, mis on eriti kasulik loodusvaatluste puhul.

## Tehnoloogiline Stack

Rakendus koosneb järgmistest komponentidest:

### Backend (API Server)
- **Tehnoloogia**: Python 3.11+ koos FastAPI raamistikuga
- **Andmebaas**: SQLite (arenduseks), PostgreSQL (tootmiskeskkonnale)
- **ORM**: SQLAlchemy asünkroonse tööga
- **API Dokumentatsioon**: Swagger UI (automaatselt genereeritud FastAPI poolt, saadaval aadressil `/docs`)
- **Välised teenused**: Plant.ID API taimetuvastuseks

### Frontend (Kasutajaliides)
- **Tehnoloogia**: React.js
- **Stiilid**: CSS koos komponendipõhise stiilimisega
- **HTTP Klient**: Axios API päringuteks
- **Kuvakomponendid**: Kohandatud komponendid piltide ja filtrite jaoks

## Arhitektuuriline Struktuur

Rakendus järgib mitmekihilist arhitektuuri ja modulaarset disaini, mis võimaldab lihtsat laiendamist ja hooldust:

### Backend Struktuur

1. **API Kiht** (`routers/`)
   - Defineerib HTTP endpointid ja marsruutimine
   - Valideerib sisendandmed Pydantic mudelite abil
   - Suunab päringud teenustele töötlemiseks
   - Jaotatud loogiliste gruppide kaupa:
     - `photo_routes.py` - fotode haldamise endpointid
     - `species_routes.py` - liikide haldamise endpointid
     - `relation_routes.py` - fotode ja liikide vaheliste seoste haldamine
     - `settings_routes.py` - rakenduse seadistuste haldamine
     - `browse_routes.py` - sirvimise ja otsingu funktsionaalsus
     - `plant_id_api.py` - taimetuvastuse funktsioonide endpointid

2. **Teenuskiht** (`services/`)
   - Sisaldab kogu äriloogikat ja on eraldatud API kihi konkreetsetest endpointidest
   - Suhtleb andmebaasiga läbi ORM-i
   - Suhtleb väliste API-dega (Plant.ID)
   - Iga teenus on vastutav konkreetse äriloogika domeeni eest:
     - `photo_service.py` - fotode töötlemine ja haldamine
     - `species_service.py` - liikide info haldamine
     - `relation_service.py` - seoste haldamine fotode ja liikide vahel
     - `settings_service.py` - rakenduse seadistuste haldamine

3. **Andmemudeli Kiht** (`models/`)
   - ORM definitsioonid andmebaasi skeemi jaoks
   - DTO (Andmeedastus objektid) API vastuste jaoks
   - Jaotatud loogilisteks gruppideks:
     - `base_models.py` - jagatud baasmudelid
     - `photo_models.py` - fotode mudelid
     - `species_models.py` - liikide mudelid
     - `relation_models.py` - seoste mudelid
     - `settings_models.py` - seadistuste mudelid

4. **Utiliidid** (`utils/`)
   - Abifunktsioonid ja -klassid, mida kasutatakse mitmes kohas
   - `plant_identification.py` - taimetuvastuse klient (Plant.ID)
   - `exif_reader.py` - fotode EXIF metaandmete lugeja

5. **Andmebaasi Konfiguratsioon** (`database.py`)
   - Andmebaasi ühenduse konfigureerimine
   - ORM sessiooni haldus
   - Migratsiooni tööriist skeemi uuendamiseks

### Frontend Struktuur

1. **Komponendid** (`src/components/`)
   - Taaskasutatavad UI komponendid
   - Lehekomponendid (vaated)
   - Jaotatud funktsionaalsuse järgi:
     - `PhotoGrid.js` - fotode kuvamiseks ruudustikus
     - `PhotoDetail.js` - ühe foto detailvaade
     - `UploadForm.js` - fotode üleslaadimise vorm
     - `MonthFilter.js` - kuufiltrid sirvimiseks
     - jne.

2. **Konfiguratsioon** (`src/config/`)
   - API URL-id ja endpointid
   - Keskkonna seadistused

3. **Teenused** (`src/services/`)
   - API kliendid backend endpointide jaoks
   - Andmete töötlemine ja vahemällu salvestamine
   - Jagatud loogika API päringute jaoks

4. **Ühised komponendid** (`src/common/`)
   - Nupud, vormielemendid, modaalaknad jms
   - Kasutatud mitmes vaates 

5. **Utiliidid** (`src/utils/`)
   - Kuupäeva formaatimise funktsioonid
   - Filtreerimise ja sorteerimise abifunktsioonid
   - Pilditöötluse abifunktsioonid

## Andmevoog

Rakenduses liiguvad andmed järgnevalt:

### Fotode Üleslaadimine ja Töötlemine
1. Kasutaja laadib üles pildifaili(d) läbi kasutajaliidese
2. Frontend saadab pildid backend API-le
3. Backend teostab järgmised operatsioonid:
   - Salvestab pildid failisüsteemi `file_storage` kausta
   - Loeb EXIF metaandmed (kuupäev, asukoht, kaamera info)
   - Salvestab metaandmed andmebaasi
   - Saadab pildi(d) Plant.ID API-le analüüsimiseks (kui see on lubatud)
   - Plant.ID tagastab tuvastatud taimeliikide info
   - Salvestab taimeliikide info andmebaasi ja seob selle pildiga
4. Kasutajale näidatakse üleslaadimise tulemust ja tuvastatud liike

### Piltide Sirvimine ja Filtreerimine
1. Kasutaja avab sirvimise vaate
2. Frontend pärib backend API-lt fotode nimekirja (võimalike filtritega)
3. Backend kogub andmed andmebaasist ja tagastab need JSON formaadis
4. Frontend kuvab pildid ruudustikus koos filtreerimise võimalustega
5. Kasutaja saab filtreerida pilte kuude järgi, klõpsates kuude filtritel
6. Filtreerimise toimub API päringutega, mis saadavad valitud filtrid serverile
7. Server tagastab filtreeritud fotode nimekirja

### Andmete Muutmine
1. Kasutaja muudab andmeid (pildi metaandmed, liikide info)
2. Frontend saadab muudatused API-le
3. Backend valideerib muudatused ja uuendab andmebaasi
4. Backend tagastab uuendatud andmed või veateate
5. Frontend uuendab kasutajaliidest vastavalt

## Andmebaasi Skeem

Andmebaasis on järgmised põhitabelid:

1. **photos** - Piltide metaandmed
   - `id` (UUID, PK) - pildi unikaalne identifikaator
   - `file_name` - salvestatud faili nimi
   - `file_path` - faili asukoht failisüsteemis
   - `original_file_name` - algne üleslaaditud faili nimi
   - `date_taken` - pildistamise kuupäev (EXIF-ist)
   - `upload_date` - üleslaadimise kuupäev
   - `location` - asukoha kirjeldus
   - `gps_latitude` - GPS laius (EXIF-ist)
   - `gps_longitude` - GPS pikkus (EXIF-ist)
   - `gps_altitude` - GPS kõrgus (EXIF-ist)
   - `camera_make` - kaamera tootja (EXIF-ist)
   - `camera_model` - kaamera mudel (EXIF-ist)
   - `exposure` - säriaeg (EXIF-ist)
   - `aperture` - ava (EXIF-ist)
   - `iso` - ISO (EXIF-ist)
   - `focal_length` - fookuskaugus (EXIF-ist)
   - `notes` - kasutaja märkmed
   - `month` - kuunumber (1-12), indekseeritud kiireks filtreerimiseks

2. **species** - Taimeliikide info
   - `id` (UUID, PK) - liigi unikaalne identifikaator
   - `scientific_name` - teaduslik nimi (ladina keeles)
   - `common_name` - tavanimetus (eesti keeles)
   - `family` - sugukond
   - `taxonomy` - taksonoomia info
   - `description` - kirjeldus
   - `source` - andmete allikas (nt. "Plant.ID API", "Manual")

3. **photo_species_relations** - Seosed piltide ja liikide vahel
   - `id` (UUID, PK) - seose unikaalne identifikaator
   - `photo_id` (FK) - viide fotole
   - `species_id` (FK) - viide liigile
   - `probability` - tõenäosus (Plant.ID API puhul)
   - `is_main` - kas see on pildi peamine liik
   - `verified` - kas kasutaja on liigi tuvastuse kinnitanud
   - `created_at` - seose loomise aeg

4. **app_settings** - Rakenduse seadistused
   - `id` (UUID, PK) - seadistuse unikaalne identifikaator
   - `key` - seadistuse võti
   - `value` - seadistuse väärtus
   - `description` - seadistuse kirjeldus

## Rakenduse Seadistamine ja Konfigureerimine

Rakenduse seadistamiseks saab kasutada järgmisi võimalusi:

1. **Keskkonna Muutujad**
   - `DATABASE_URL` - andmebaasi ühenduse URL
   - `PLANT_ID_API_KEY` - Plant.ID API võti
   - `FILE_STORAGE_PATH` - piltide salvestamise asukoht
   - `DEBUG` - silurežiimi lubamine (True/False)

2. **Andmebaasi Seadistused** (`app_settings` tabel)
   - `enable_plant_id` - Plant.ID API kasutamise lubamine
   - `default_language` - vaikimisi keel liikide tavanimedeks
   - `max_upload_size` - maksimaalne lubatud faili suurus (baitides)
   - `thumbnail_size` - pisipiltide suurus (pikslites)

## Täiendamine ja Laiendamine

Rakenduse laiendamiseks ja uute funktsioonide lisamiseks soovitame järgida neid põhimõtteid:

1. **Uue Marsruuteri Lisamine**
   - Looge uus fail `backend/routers/` kaustas
   - Registreerige uus marsruuter failis `main.py`

2. **Uue Teenuse Lisamine**
   - Looge uus teenusefail `backend/services/` kaustas
   - Järgige olemasolevate teenuste struktuuri

3. **Andmebaasi Skeemi Laiendamine**
   - Lisage uus mudel `backend/models/` kausta
   - Uuendage andmebaasi skeemi, käivitades `python update_schema.py`

4. **Frontend Komponentide Lisamine**
   - Järgige React komponendipõhist struktuuri
   - Kasutage olemasolevaid ühiskomponente

## Projektile Kaasa Aitamine

1. Kloonige repositoorium
2. Seadistage arenduskeskkond
3. Looge oma muudatuste jaoks uus haru (`git checkout -b feature/minu-uus-funktsioon`)
4. Tehke oma muudatused
5. Viige läbi testid (kui need on olemas)
6. Esitage pull request

## Paigaldamine ja Seadistamine

Vaata täpsemaid juhiseid järgmistest dokumentidest:
- [Paigaldusjuhend](installation_guide.md)
- [Administreerimise dokumentatsioon](administreerimine_dokumentatsioon.md)

## Arenduskeskkonna Seadistamine

Vaata [Koodi organiseerimise reeglid](code_organization_rules.md).