## Procjena sigurnosti 
Cilj implementiranog sustava za sigurnosno kopiranje je osigurati povjerljivost, integritet i dostupnost podataka u slučaju incidenta poput ransomware napada, kvara sustava ili gubitka podataka. Procjena sigurnosti sustava provedena je analizom komunikacije između komponenti, zaštite pohranjenih sigurnosnih kopija te upravljanja pristupima i kriptografskim ključevima.

Sigurnost komunikacije između Bacula Director-a i Bacula File Daemona poboljšana je uvođenjem TLS enkripcije. Time je osigurana povjerljivost i integritet podataka koji se razmjenjuju tijekom izvođenja backup i restore operacija, čime se smanjuje rizik od presretanja prometa ili neovlaštene manipulacije naredbama.

Sigurnost pohranjenih sigurnosnih kopija dodatno je osigurana enkripcijom podataka pomoću GPG-a. Backup arhive koje generira Duplicity pohranjuju se u enkriptiranom obliku, što znači da u slučaju neovlaštenog pristupa backup poslužitelju napadač ne može pristupiti sadržaju podataka bez odgovarajućih kriptografskih ključeva. Time se značajno smanjuje rizik od kompromitacije povjerljivih podataka.

Posebna pažnja posvećena je upravljanju pristupima i privilegijama. Bacula File Daemon i pripadajuće skripte izvršavaju se pod korisnikom bacula, kojemu su dodijeljena isključivo potrebna prava za pristup direktorijima koji sadrže certifikate i kriptografske ključeve. Time se primjenjuje princip najmanjih privilegija, čime se smanjuje površina napada u slučaju kompromitacije sustava.

U kontekstu ransomware napada, sustav omogućuje oporavak podataka bez potrebe za plaćanjem otkupnine. Sigurnosne kopije nalaze se na zasebnom poslužitelju, zaštićene su enkripcijom te se mogu pouzdano vratiti korištenjem definiranih restore postupaka i dodatnih mehanizama validacije.

## Konfiguracijske datoteke i automatizacijske skripte sustava 

Tijekom izrade i testiranja sustava za sigurnosno kopiranje uočeno je da bi bilo poželjno provoditi sigurnosno kopiranje konfiguracijskih datoteka i automatizacijskih skripti sustava. U slučaju ozbiljnog incidenta, poput ransomware napada ili gubitka sustava, ponovno uspostavljanje backup infrastrukture zahtijeva ručnu rekonfiguraciju Bacula komponenti, definiranih rasporeda poslova i pripadajućih skripti, što značajno produljuje vrijeme oporavka.

Uključivanjem konfiguracijskih datoteka i automatizacijskih skripti u sigurnosne kopije omogućila bi se brža i pouzdanija obnova backup sustava. Time bi se smanjila potreba za ručnim unosom konfiguracije, umanjio rizik od pogrešaka te skratilo ukupno vrijeme potrebno za ponovno uspostavljanje potpuno funkcionalnog sustava.

## Backup na trećoj lokaciji 
Iako sustav koristi GFS (Grandfather–Father–Son) strategiju sigurnosnog kopiranja, sigurnosne kopije se trenutačno pohranjuju na jedan backup poslužitelj. Kao moguće unapređenje sustava, preporučuje se razmotriti primjenu pravila 3-2-1 ili hibridnog pristupa, primjerice kombinacijom postojećeg GFS modela s pohranom sigurnosnih kopija na dodatnu, fizički odvojenu lokaciju. Takva lokacija može biti drugi poslužitelj ili cloud okruženje, čime bi se dodatno povećala otpornost sustava na fizičke kvarove, sigurnosne incidente i ransomware napade.


