# SIS_TIM9_Implementing-Testing-and-Assessing-a-Robust-Backup-Strategy (Implementacija, testiranje i procjena otporne backup strategije)

## Pregled projekta
Ovaj projekt bavi se implementacijom, testiranjem i procjenom robusne strategije sigurnosnog kopiranja i oporavka podataka. Cilj projekta je prikazati kako se teorijski koncepti backupa i oporavka mogu primijeniti u simuliranom poslovnom IT okruženju, uz naglasak na pouzdanost, sigurnost i mjerljive metrike oporavka.

Projekt obuhvaća analizu različitih vrsta i strategija sigurnosnog kopiranja, definiranje metrika RTO i RPO, implementaciju hibridne GFS strategije te testiranje sustava kroz različite scenarije gubitka podataka, uključujući slučajna brisanja, kvarove sustava i sigurnosne incidente.

---

## Članovi tima
Projekt je izrađen u sklopu kolegija **Sigurnost informacijskih sustava**.

- Lovro Balent  
- Vedran Bogdanović  
- Katarina Hozjan  
- Ivana Hranj  

Mentori:
- Izv. prof. dr. sc. Petra Grd  
- Izv. prof. dr. sc. Igor Tomičić  

---

## Korišteni alati i tehnologije
- **Bacula** – upravljanje sigurnosnim kopijama i oporavkom podataka  
- **Duplicity** – izrada punih i inkrementalnih sigurnosnih kopija  
- **OpenSSL** – sigurna i šifrirana komunikacija  
- **VirtualBox / VMware** – virtualno okruženje za testiranje  
- **Python** – automatizacija, testiranje i analiza

---

## Kako pokrenuti projekt
Projekt je primarno namijenjen demonstraciji i dokumentiranju implementirane backup strategije.

Za pokretanje praktičnog dijela potrebno je:
1. Postaviti virtualno okruženje s klijentima i backup poslužiteljem.
2. Instalirati i konfigurirati alate Bacula, Duplicity i OpenSSL.
3. Postaviti strategiju sigurnosnog kopiranja prema definiranim RTO i RPO vrijednostima.
4. Izvršiti testne scenarije gubitka i oporavka podataka.
5. Analizirati rezultate i usporediti planirane i stvarno izmjerene metrike (RTA i RPA).

Detaljne upute nalaze se u direktoriju `implementation/`.

---


