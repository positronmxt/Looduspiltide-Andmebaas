# Looduspiltide andmebaasi sirvimislahenduse arendusplaan

## Ülevaade
Selles arendusetapis lisame olemasolevale rakendusele piltide ja tuvastatud taimeliikide sirvimisfunktsionaalsuse. Taimeliikide tuvastamine ja andmebaasi salvestamine on juba olemas, nüüd on vaja luua elegantne võimalus andmebaasi sirvimiseks.

## Eesmärgid
1. Luua kasutajaliides, mis võimaldab fotosid sirvida ja filtreerida
2. Kuvada fotode detaile koos tuvastatud taimeliikidega
3. Pakkuda filtreerimisvõimalusi liigi, asukoha ja kuupäeva järgi
4. Säilitada olemasolev toimiv taimetuvastuse funktsionaalsus

## Tehnilised komponendid

### Backend API täiendused
Loome uued API endpointid fotode sirvimiseks:
- `GET /photos/` - Kõigi fotode nimekiri 
- `GET /photos/?species={species_id}` - Filtreerimine liigi järgi
- `GET /photos/?location={location}` - Filtreerimine asukoha järgi
- `GET /photos/?date={date}` - Filtreerimine kuupäeva järgi
- `GET /photos/{photo_id}` - Konkreetse foto detailid koos tuvastatud liikidega

### Frontend komponendid
1. **FotodeBrowser** - Põhikomponent fotode sirvimiseks ja filtreerimiseks
2. **FotoDetail** - Detailvaade iga foto jaoks
3. **Navigatsioon** - Liikumine tuvastusvaate ja sirvimisvaate vahel

## Rakendusplaan

### 1. Backend arendus
1. Loo uus failis `backend/routers/browse_routes.py`
2. Täienda olemasolevat `backend/services/photo_service.py` faili
3. Lisa uus marsruuter `main.py` faili

### 2. Frontend arendus
1. Loo uus komponent `frontend/src/components/FotodeBrowser.js`
2. Loo uus CSS fail `frontend/src/components/FotodeBrowser.css`
3. Täienda `App.js` faili navigatsiooniga

### 3. API staatiline failiteenindus
Seadista backend piltide serveerimiseks staatilise failiteeninduse kaudu

## Ajakava
1. Backend API teenused - 1 päev
2. Frontend põhikomponent - 1 päev 
3. Detailvaade ja filtreerimine - 1 päev
4. Testimine ja viimistlus - 1 päev

## Eeldatavad väljakutsed
1. Piltide optimaalne serveerimine
2. Filtrite efektiivne kombineerimine
3. Kasutajaliidese responsiivsus