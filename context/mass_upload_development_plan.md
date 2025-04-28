# Massilise Piltide Üleslaadimise Arendusplaan

## Eesmärk
Luua funktsionaalsus, mis võimaldab kasutajatel üles laadida mitmeid looduspilte korraga, parandades oluliselt piltide andmebaasi lisamise kiirust ja mugavust.

## Nõuded
1. Võimalus valida mitu faili korraga
2. Drag & Drop tugi piltide lohistamiseks
3. Üleslaadimise progressi ja staatuse kuvamine
4. Võimalus lisada ühised metaandmed (kuupäev, asukoht) kõigile piltidele
5. Eelvaadete kuvamine enne üleslaadimist
6. Võimalus eemaldada faile üleslaadimise nimekirjast
7. Teade üleslaadimise õnnestumise/ebaõnnestumise kohta

## Komponendid

### Frontend
1. **MassPhotoUploader** komponent
   - Drag & Drop ala
   - Mitme faili valimise tugi
   - Failide eelvaade ja nimekiri
   - Üleslaadimise progressi indikaator
   - Ühiste metaandmete sisestusväljad

2. **Navigatsiooni** täiendus
   - Lisada uus navigatsioonivalik "Massiline Üleslaadimine"
   - Integreerida komponent App.js failis

### Backend
1. **API optimeerimised**
   - Välja selgitada, kas vaja teha optimeerimisi paljude piltide üleslaadimiseks
   - Kaaluda mitmelõimelisust või asünkroonsete ülesannete kasutamist piltide töötlemiseks

## Teostuse sammud

### 1. Frontend arendus
- [x] Luua `MassPhotoUploader.js` komponent
- [x] Luua `MassPhotoUploader.css` stiilileht
- [ ] Täiendada `App.js` uue vaatega
- [ ] Testida mitme pildi üleslaadimist

### 2. Backend kontroll
- [ ] Kontrollida olemasoleva API sobivust massiliseks üleslaadimiseks
- [ ] Vajadusel optimeerida serverit paljude paralleelsete päringute käsitlemiseks

### 3. Testimine
- [ ] Testida väikese arvu piltidega (5-10)
- [ ] Testida suure arvu piltidega (50+)
- [ ] Veenduda, et metaandmed ekstraheeritakse ja salvestatakse korrektselt

### 4. Dokumenteerimine
- [ ] Uuendada projekti dokumentatsiooni
- [ ] Lisada kasutusjuhend kasutajatele

## Tehnilised märkused
- Kasutajaliides peab olema reageeriv ja näitama selgelt üleslaadimise protsessi
- Tuleb arvestada võimaliku serverikoormusega, kui samaaegselt laaditakse üles palju pilte
- Veatöötlus peab olema põhjalik, näitamaks kasutajale, millised pildid õnnestus üles laadida ja millised mitte

## Ajakava
- Frontend arendus: 1-2 päeva
- Backend kontroll ja optimeerimised: 1 päev
- Testimine ja vigade parandamine: 1 päev
- Dokumenteerimine: 0.5 päeva

**Orienteeruv arendusaeg kokku: 3-4 päeva**