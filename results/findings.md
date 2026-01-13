Zaključak i interpretacija rezultata validacije

Na temelju provedenih testova i prikazanih rezultata validacije moguće je donijeti zaključke o pouzdanosti procesa sigurnosnog kopiranja i oporavka podataka.

![rezultat testa validacije1](https://github.com/HozjanKatarina/SIS_TIM9_Implementing-Testing-and-Assessing-a-Robust-Backup-Strategy/blob/main/results/logs/Rezultat%20provjere%20integriteta%20sigurnosne%20kopije%20%E2%80%93%20uspje%C5%A1na%20validacija.png)

Kako bi se ispitala ispravnost procesa, izvršen je restore postupak bez naknadnih izmjena nad podacima. Rezultat te validacije prikazan je na slici iznad. Vidljivo je da su gotovo sve datoteke vraćene u identičnom obliku. Od ukupno 31 datoteke, 30 datoteka odgovara izvornom sadržaju prema veličini i SHA-256 sažetku, dok je zabilježeno jedno nepodudaranje koje se odnosi na dump baze podataka. Takav rezultat je očekivan s obzirom na prirodu dump datoteka, koje se mogu razlikovati na razini binarnog zapisa iako sadrže iste logičke podatke. Između ostalog, dump sadrži i metapodatke koji se mogu razlikovati ovisno o tome kada je proveden.

![rezultat_testa_validacije2](https://github.com/HozjanKatarina/SIS_TIM9_Implementing-Testing-and-Assessing-a-Robust-Backup-Strategy/blob/main/results/logs/Rezultat%20provjere%20integriteta%20sigurnosne%20kopije%20%E2%80%93%20detektirane%20promjene.png)

Na drugoj slici prikazan je rezultat provjere integriteta i cjelovitosti sigurnosne kopije uspoređen sa nekoliko promijenenih dokumenata iz originalnog ksupa podataka. Uočeno je više nepodudaranja između izvornog i vraćenog sadržaja. Validacijska skripta detektirala je promijenjene datoteke (hash mismatch i size mismatch), jednu dodatnu datoteku te jednu datoteku koja nedostaje. Ovakav rezultat ukazuje na to da vraćeni skup podataka ne odgovara u potpunosti izvornom stanju, što potvrđuje ispravnost implementirane validacije jer uspješno detektira čak i manje promjene u sadržaju, veličini ili strukturi datoteka.

![validacija_podataka_u_bazi](https://github.com/HozjanKatarina/SIS_TIM9_Implementing-Testing-and-Assessing-a-Robust-Backup-Strategy/blob/main/results/logs/Rezultat%20provjere%20integriteta%20sigurnosne%20kopije%20%E2%80%93%20detektirane%20promjene.png)

Dodatna provjera sigurnosne kopije baze podataka provedena je pomoću posebne validacijske skripte, čiji je rezultat prikazan na slici. Skripta je potvrdila tehničku ispravnost dumpa, uspješan restore baze u testnu instancu te semantičku ispravnost podataka, uključujući očekivani broj zapisa i vremenski raspon podataka. Time je potvrđeno da, unatoč razlikama u hash vrijednosti dump datoteke, sigurnosna kopija baze podataka omogućuje ispravan i pouzdan oporavak podataka.

Na temelju prikazanih rezultata može se zaključiti da implementirani sustav sigurnosnog kopiranja, u kombinaciji s dodatnim mehanizmima validacije, omogućuje pouzdano otkrivanje neispravnih ili nepotpunih oporavaka podataka. Validacija datotečnog sustava i baze podataka pokazala se ključnom komponentom procesa, jer omogućuje razlikovanje između uspješnog i potencijalno problematičnog restore postupka. Time sustav ne osigurava samo izradu sigurnosnih kopija, već i dokaz njihove stvarne iskoristivosti u slučaju incidenta poput ransomware napada.
