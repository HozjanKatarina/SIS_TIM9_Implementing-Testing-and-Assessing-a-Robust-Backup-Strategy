# Postavljanje sustava
## Postavljanje okoline
Za implementaciju okruženja projekta odabran je pristup rada s dva virtualna stroja. Jedna virtualka će predstavljati klijentsko računalo, dok će drugo biti backup poslužitelj. Za klijentsko računalo odabran je Kali Linux VM koji predstavlja prosječno klijentsko Linux računalo. S druge strane, za poslužitelj je odabran stroj sa slikom sustava Ubuntu Server. 

Kako bi virtualni strojevi mogli međusobno komunicirati potrebno je na oba stroja uskladiti mrežne postavke u opcijama VirtualBox-a. Za početak potrebno je kreirati zajedničku NAT mrežu za virtualne strojeve pod File->Tools->Network Manager. Zatim odabrati karticu "NAT Networks", pristisnuti na gumb "Create" i imenovati mrežu po volji.

![vbox kreiranje mreže](https://github.com/HozjanKatarina/SIS_TIM9_Implementing-Testing-and-Assessing-a-Robust-Backup-Strategy/blob/main/implementation/media/mrezne_postavke2.png)

Nakon kreiranja mreže dodati ju na oba virtualna stroja u mrežnim postavkama promjenom opcije "Attached To" na "NAT Network" i zatim odabirom imena kreirane mreže.

![vbox postavke mreže](https://github.com/HozjanKatarina/SIS_TIM9_Implementing-Testing-and-Assessing-a-Robust-Backup-Strategy/blob/main/implementation/media/mrezne_postavke.png)

Nakon toga, zbog čestog korištenja SSH odlučili smo pripremiti SSH ključeve kako bi se eliminirala potreba za unosom lozinke tijekom čestih spajanja. Alatom ssh-keygen generirali smo ssh ključeve i zatim ih alatom ssh-copy-id prenijeli na drugo računalo.

KONFIGURACIJA FOLDERA?? IL TO POSLE MOŽDA NAPISAT...
DODAT OPIS O POVEZIVANJU SSL TLS CERTIFIKATOM

## Instalacija alata
Prema uputama teme, odabrali smo slijedeće alate i ovako ih rasporedili po strojevima:
 - Klijent
   - Bacula-FD
   - Duplicity
 - Poslužitelj
   - Bacula-Console
   - Bacula-SD
   - Bacula-FD
   - Bacula-Director
   - PostgreSQL

Bacula sama po sebi može provoditi proces sigurnosnog kopiranja, ali prema opisu teme u ovome sustavu Bacula služi samo kao orkestrator nekog drugog backup alata (ovdje Duplicity). Kao alat, Bacula je mnogo kompleksniji od Duplicityja, što je očito već iz same činjenice da je zapravo riječ o sustavu koji se sastoji od više alata.
 - bacula-director - alat koji upravlja poslovima, rasporedima, logikom...
 - bacula-sd (StorageDaemon) - alat koji piše na disk računala
 - bacula-fd (FileDaemon) - nekaj
 - bacula-console - terminalski alat
Prilikom instalacije Bacule valja paziti na to koja verzija je odabrana jer Bacula podržava tri sustava baza podataka: MySQL, PostgreSQL i SQLite. Prilikom izrade ovog projekta korišten je PostreSQL, pa je i naveden kao jedan od instaliranih alata. Konfiguracija baze podataka je prva stvar koja se pokreće nakon samog preuzimanja.

Svaki od alata ima vlastitu konfigruacijsku datoteku koja omogućava cijelu paletu opcija. Najmoćniji od njih je, kao što mu i samo ime govori - bacula-director. On povezuje sve druge alate i njia orkestrira. Osim što može provoditi klasični backup proces, može izvoditi i naredbe na klijentima koji koriste bacula-fd.

PISAT O KONFIGURACIJI BACULE

## Povezivanje Bacule i Duplicityja
Kako u ovom sustavu Bacula ne radi samostalno potrebno je pomoću Bacule zatražiti akciju od Duplicityja. Srećom, Bacula poslužitelj podržava izvršavanje naredbi na svojim klijentima. Za tu svrhu koristit će se skripta run_duplicity.sh koja je priložena kao deliverable u repozitoriju. Njome će se smanjiti količina koda koja mora biti sadržana u konfiguracijskoj datoteci Bacula Directora. S obzirom na to kako je odabrana GFS strategija, važno je razlikovati pune i inkrementalne backupove, te to radi li se o djedu, ocu ili sinu. Time će upravljati logika skripte, a za svaku opciju Bacula će samo imati definiran drugi Job u kojem će se skripti proslijediti drugačiji parametar.
