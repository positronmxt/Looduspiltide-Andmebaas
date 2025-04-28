# GitHub üleslaadimise meelespea

## Samm-sammult protsess muudatuste üleslaadimiseks

1. **Kontrolli staatust enne alustamist**
   ```bash
   git status
   ```
   - Vaata millised failid on muudetud
   - Veendu, et aktiivne haru on 'main'

2. **Lisa muudetud failid Git jälgimisele**
   ```bash
   git add failinimi1 failinimi2 failinimi3
   ```
   või kõik failid korraga:
   ```bash
   git add .
   ```

3. **Tee commit kirjeldava sõnumiga**
   ```bash
   git commit -m "Kirjeldav commit sõnum muudatuste kohta"
   ```

4. **Lae muudatused GitHubi üles**
   ```bash
   ./push_github.sh
   ```
   - Kasuta ainult seda parandatud skripti (mis laadib main→main)
   - Sisesta küsimisel GitHub token

## Olulised tähelepanekud

- Enne üleslaadimist peavad muudatused olema **commititud**
- Muudatused, mida pole lisatud git jälgimisele (`git add`) ega commititud (`git commit`), ei lähe üles
- Veendu, et oled õigel harul (enamasti `main`)
- Token on vajalik autentimiseks - säilita see turvalises kohas

## Kui midagi läheb valesti

- Veendu, et töötad main harul: `git checkout main`
- Kontrolli remote seadistust: `git remote -v`
- Vajadusel lähtesta remote: 
  ```bash
  git remote remove origin
  git remote add origin https://github.com/positronmxt/Looduspiltide-Andmebaas.git
  ```

## Push_github.sh skripti tööpõhimõte

Skript teeb järgmist:
1. Küsib GitHub tokenit
2. Eemaldab olemasoleva remote'i
3. Seadistab uue remote'i koos tokeniga
4. Laadib main haru üles GitHubi main harusse
5. Puhastab tokeni Git konfiguratsioonist