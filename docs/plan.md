# 3. Plan strategije sigurnosne kopije 

## 3.1. Cilj praktičnog dijela

Cilj praktičnog dijela ovog projekta je prikazati kako se teorijski koncepti sigurnosnog kopiranja i oporavka mogu primijeniti u stvarnom okruženju kroz izradu i testiranje robusne hibridne backup strategije. Fokus je na pouzdanosti, sigurnosti i mjerljivim metrikama oporavka.

## 3.2. Odabrana strategija sigurnosnog kopiranja

Za potrebe praktičnog dijela odabrana je GFS strategija, odnosno pristup hibridnog kopiranja. Navedena strategija kombinira inkrementalne i pune (engl. full) sigurnosne kopije. Ovaj pristup odabran je jer se u praktičnom dijelu projekta koristi sustav manjeg opsega. Prilikom odabira strategije uzete su u obzir i samostalno definirane RTO i RPO metrike.

## 3.3. Testno okruženje i korišteni alati

Strategija sigurnosnog kopiranja testirat će se unutar testnog VM okruženja koje se sastoji od klijenata i backup poslužitelja. Za implementaciju backup poslužitelja koristit će se alat Bacula, dok će se alat Duplicity koristiti za izradu inkrementalnih i punih sigurnosnih kopija predviđenih GFS strategijom. Klijenti će s poslužiteljem komunicirati putem OpenSSL-a.

## 3.4. Testiranje i scenariji oporavka

Testiranjem implementacije mjerit će se RTA i RPA vrijednosti te će se usporediti s predviđenim RTO i RPO vrijednostima. Također će se provoditi validacija integriteta sigurnosnih kopija korištenjem hash funkcija. Sustav će se provesti kroz nekoliko mogućih scenarija gubitka podataka, poput slučajnog brisanja dokumenta, elementarne nepogode i ransomware napada. Testirat će se i sigurnost implementacije kroz pokušaje neautoriziranog pristupa sigurnosnim kopijama.

## 3.5. Očekivani izazovi i dokumentacija

Tijekom provedbe mogu se pojaviti izazovi poput poteškoća u konfiguraciji alata Bacula i Duplicity te problema s komunikacijom putem OpenSSL-a, s obzirom na ograničeno iskustvo tima s navedenim alatima. Očekuje se i sporije izvođenje punih sigurnosnih kopija, kao i ograničenja prostora i performansi unutar virtualnog okruženja. Poseban izazov predstavlja procjena razumnog RTO i RPO vremena. Tijek rada, detalji konfiguracije i skripte korištene u implementaciji strategije bit će dokumentirani na GitHub repozitoriju.


## 3.6. Strategija sigurnosnih kopija i odabir podataka

Odabrani pristup sigurnosnog kopiranja obuhvaća samo ključne podatke sustava, dok se sigurnosne kopije cijelog sustava ne izrađuju. Takav pristup omogućuje jasnu demonstraciju učinkovitosti sustava sigurnosnog kopiranja bez nepotrebnog povećavanja složenosti implementacije. Kao osnovni model primijenjena je strategija **Grandfather–Father–Son (GFS)**, jer kombinira inkrementalne i pune sigurnosne kopije, čime se postiže dobar omjer između učestalosti sigurnosnog kopiranja, vremena oporavka i zauzeća prostora za pohranu.

Strategija sigurnosnog kopiranja temelji se na tri ključne skupine podataka tipičnog IT okruženja:

- **Zajednički poslovni podaci**  
  U ovu skupinu ubrajaju se dokumenti i datoteke koje se svakodnevno koriste i često mijenjaju, poput tekstualnih dokumenata, izvještaja i ostalih poslovnih materijala pohranjenih u zajedničkim direktorijima. Gubitak ovih podataka imao bi izravan i značajan utjecaj na poslovne procese, zbog čega se smatraju najkritičnijima.

- **Baza podataka (logička sigurnosna kopija – dump)**  
  Drugu skupinu podataka čini baza podataka pohranjena u obliku logičke sigurnosne kopije (dump), odnosno datoteke koja sadrži izvezene podatke i strukturu baze. Umjesto kopiranja fizičkih datoteka baze, izrađuje se logički izvoz podataka, što olakšava postupak oporavka i testiranje povrata podataka.

- **Konfiguracijske datoteke i automatizacijske skripte**  
  Treću skupinu čine konfiguracijske datoteke sustava za izradu sigurnosnih kopija i pripadajuće automatizacijske skripte. Njihovo sigurnosno kopiranje omogućuje lakšu i bržu ponovnu konfiguraciju backup sustava u slučaju kvara ili gubitka konfiguracije.

Za sve navedene skupine podataka primjenjuje se sljedeća politika izrade i zadržavanja sigurnosnih kopija:
- **dnevne inkrementalne sigurnosne kopije**, koje se čuvaju **30 dana**
- **tjedne pune sigurnosne kopije**, koje se zadržavaju **365 dana**
- **mjesečne arhivske pune sigurnosne kopije**, koje se pohranjuju na **neograničeno razdoblje**

