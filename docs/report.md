## Konfiguracijske datoteke i automatizacijske skripte sustava 

Tijekom izrade i testiranja sustava za sigurnosno kopiranje uočeno je da bi bilo poželjno provoditi sigurnosno kopiranje konfiguracijskih datoteka i automatizacijskih skripti sustava. U slučaju ozbiljnog incidenta, poput ransomware napada ili gubitka sustava, ponovno uspostavljanje backup infrastrukture zahtijeva ručnu rekonfiguraciju Bacula komponenti, definiranih rasporeda poslova i pripadajućih skripti, što značajno produljuje vrijeme oporavka.

Uključivanjem konfiguracijskih datoteka i automatizacijskih skripti u sigurnosne kopije omogućila bi se brža i pouzdanija obnova backup sustava. Time bi se smanjila potreba za ručnim unosom konfiguracije, umanjio rizik od pogrešaka te skratilo ukupno vrijeme potrebno za ponovno uspostavljanje potpuno funkcionalnog sustava.

## Backup na trećoj lokaciji 
Iako sustav koristi GFS (Grandfather–Father–Son) strategiju sigurnosnog kopiranja, sigurnosne kopije se trenutačno pohranjuju na jedan backup poslužitelj. Kao moguće unapređenje sustava, preporučuje se razmotriti primjenu pravila 3-2-1 ili hibridnog pristupa, primjerice kombinacijom postojećeg GFS modela s pohranom sigurnosnih kopija na dodatnu, fizički odvojenu lokaciju. Takva lokacija može biti drugi poslužitelj ili cloud okruženje, čime bi se dodatno povećala otpornost sustava na fizičke kvarove, sigurnosne incidente i ransomware napade.

## Procjena sigurnosti 

