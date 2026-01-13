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

## 3.7. RTO i RPO metrike

RPO (Recovery Point Objective) u ovom projektu razlikuje se ovisno o vrsti incidenta koji se razmatra. U slučaju slučajnog brisanja datoteka, sigurnosne kopije izrađuju se svakodnevno u obliku inkrementalnih kopija, čime je gubitak podataka ograničen na maksimalno 24 sata. Takav gubitak podataka smatra se prihvatljivim za promatrani sustav, budući da se radi o operativnom incidentu niskog rizika koji ne ugrožava cjelokupnu dostupnost sustava.

RTO (Recovery Time Objective) za scenarij slučajnog brisanja datoteka postavljen je u rasponu od 30 minuta do 1 sata. Ova vrijednost obuhvaća vrijeme potrebno za identifikaciju odgovarajuće sigurnosne kopije te povrat pojedinačnih datoteka bez potrebe za prekidom rada sustava, čime se osigurava brz i učinkovit oporavak uz minimalan utjecaj na korisnike.

Nasuprot tome, ransomware napad predstavlja sigurnosni incident visoke razine, koji zahtijeva znatno složeniji postupak oporavka. U takvom scenariju nužno je izolirati kompromitirani sustav, provesti ponovnu instalaciju operacijskog sustava te vratiti podatke iz provjerenih i neoštećenih sigurnosnih kopija. Zbog složenosti navedenih postupaka, RTO je značajno dulji te iznosi između 4 i 24 sata, što predstavlja maksimalno prihvatljivo vrijeme za potpunu ponovnu uspostavu funkcionalnosti sustava.

RPO za ransomware scenarij je do 24 sata pošto se svakih 24 sata radi backup, jer smatramo da za naš slučaj jedan radni dan izgubljenih podataka nije neka velika šteta. Takav pristup naglašava važnost čestog sigurnosnog kopiranja i pouzdane strategije oporavka, osobito u kontekstu zaštite od zlonamjernih napada koji mogu imati ozbiljne posljedice po integritet i dostupnost podataka.

## 3.8. Scenariji gubitka podataka i oporavka sustava

Kako bi se provjerila učinkovitost odabrane strategije sigurnosnog kopiranja, sustav će se testirati kroz nekoliko mogućih scenarija gubitka podataka. Odabrani scenariji predstavljaju realne situacije koje se mogu pojaviti u stvarnom IT okruženju.

### 3.8.1. Slučajno brisanje podataka

U ovom scenariju dolazi do slučajnog brisanja jedne ili više datoteka iz zajedničkog direktorija. Sustav ostaje funkcionalan, no određeni poslovni podaci postaju nedostupni.

Oporavak se provodi povratom obrisanih datoteka iz zadnje dostupne dnevne inkrementalne sigurnosne kopije. Na taj način gubitak podataka ograničen je unutar definiranog RPO-a od 24 sata, dok se oporavak provodi unutar planiranog RTO vremena.

### 3.8.2. Ransomware napad

U ovom scenariju simulira se ransomware napad pri kojem dolazi do kompromitacije podataka u zajedničkim direktorijima, primjerice šifriranjem ili izmjenom sadržaja datoteka. Iako su podaci fizički prisutni, oni postaju neupotrebljivi.

S obzirom na opseg projekta, simulacija ransomware napada fokusirana je na posljedice napada, a ne na sam proces širenja zlonamjernog softvera. Oporavak sustava provodi se vraćanjem podataka iz zadnje dostupne čiste pune sigurnosne kopije, uz eventualnu primjenu inkrementalnih kopija izrađenih prije incidenta.



