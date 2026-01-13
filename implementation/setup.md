# Postavljanje sustava
## Postavljanje okoline
Za implementaciju okruženja projekta odabran je pristup rada s dva virtualna stroja. Jedna virtualka će predstavljati klijentsko računalo, dok će drugo biti backup poslužitelj. Za klijentsko računalo odabran je Kali Linux VM koji predstavlja prosječno klijentsko Linux računalo. S druge strane, za poslužitelj je odabran stroj sa slikom sustava Ubuntu Server. 

Kako bi virtualni strojevi mogli međusobno komunicirati potrebno je na oba stroja uskladiti mrežne postavke u opcijama VirtualBox-a. Za početak potrebno je kreirati zajedničku NAT mrežu za virtualne strojeve pod File->Tools->Network Manager. Zatim odabrati karticu "NAT Networks", pristisnuti na gumb "Create" i imenovati mrežu po volji.

![vbox kreiranje mreže](https://github.com/HozjanKatarina/SIS_TIM9_Implementing-Testing-and-Assessing-a-Robust-Backup-Strategy/blob/main/implementation/media/mrezne_postavke2.png)

Nakon kreiranja mreže dodati ju na oba virtualna stroja u mrežnim postavkama promjenom opcije "Attached To" na "NAT Network" i zatim odabirom imena kreirane mreže.

![vbox postavke mreže](https://github.com/HozjanKatarina/SIS_TIM9_Implementing-Testing-and-Assessing-a-Robust-Backup-Strategy/blob/main/implementation/media/mrezne_postavke.png)

Nakon toga, zbog čestog korištenja SSH odlučili smo pripremiti SSH ključeve kako bi se eliminirala potreba za unosom lozinke tijekom čestih spajanja. Alatom ssh-keygen generirali smo ssh ključeve i zatim ih alatom ssh-copy-id prenijeli na drugo računalo.

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
Prilikom instalacije Bacule valja paziti na to koja verzija je odabrana jer Bacula podržava tri sustava baza podataka: MySQL, PostgreSQL i SQLite. Bacula koristi jedan od navedenih sustava za vođenje evidencije o provedbi poslova. Prilikom izrade ovog projekta korišten je PostreSQL, pa je i naveden kao jedan od instaliranih alata. Konfiguracija baze podataka je prva stvar koja se pokreće nakon samog preuzimanja. Postavili smo sve po tvorničkim opcijama.

Svaki od alata ima vlastitu konfigruacijsku datoteku koja omogućava cijelu paletu opcija. Najmoćniji od njih je, kao što mu i samo ime govori - bacula-director. On povezuje sve druge alate i njima orkestrira. Osim što može provoditi klasični backup proces, može izvoditi i naredbe na klijentima koji koriste bacula-fd što će se pokazati korisnim u realizaciji ovog sustava. U početku je bilo zahtjevno uskladiti sve te brojne opcije jer se radi o dugim tekstualnim datotekama koje zahtjevaju poznavanje njihove sintakse. Nakon nekoliko krugova pokušaja spajanja konfigurirali smo vezu klijent-poslužitelj između dvije virtualke bez postavljanja TLS-a jer nam je u početku zadavao komplikacije, a smatrali smo da je važnije prvo ostvariti funkcionalnost, a zatim sigurnost.

## Implementacija GFS strategije
Kako u ovom sustavu Bacula ne radi samostalno potrebno je pomoću Bacule zatražiti akciju od Duplicityja. Srećom, Bacula poslužitelj podržava izvršavanje naredbi na svojim klijentima. Za tu svrhu koristit će se skripta ```duplicity.sh``` koja je priložena kao deliverable u repozitoriju. Njome će se smanjiti količina koda koja mora biti sadržana u konfiguracijskoj datoteci Bacula Directora. Tako primjerice jedan Job izgleda ovako:

```
Job {
  Name = "Son-Production-Job"
  Type = Backup
  Level = Incremental
  Client = kali-fd
  FileSet = "DummySet"
  Schedule = "Sched-Son"
  Storage = File1
  Pool = Son
  Messages = Standard
  Client Run Before Job = "/usr/local/bin/duplicity.sh %l Son"
}
```

Definira mu se tip kao backup i ```Level``` kao ```Incremental```. To bi bile prave definicije toga što će se raditi kada bi Bacula sama radila backup, ali ovako je to samo parametar koji mi šaljemo skripti. Osim toga, definira se i ```FileSet``` i ```Storage``` samo zato što Bacula ne pušta dalje bez tih vrijednosti. One nisu postavljene na ništa konkretno. Pool je trebao biti isto više manje samo varijabla koja bi se proslijedila skripti, ali kasnije smo otkrili da se parametar ```%p``` ne može slati klijentima, samo Bacula Directoru. Najvažniji dio Joba u kontekstu ovog projekta je opcija ```Client Run Before Job```. Nakon poziva skripte slijede parametri ```%l``` i hardkodirani tekst ```Son``` koji označava Pool posla, odnosno razinu GFS-a koja se javlja skripti.

Svaka razina GFS strategije biti će pospremljena u svoj direktorij pa moramo znati radi li se o djedu, ocu ili sinu. Za provedbu Duplicity naredbi važno je **razlikovati pune i inkrementalne backupove**. Za svaku opciju Bacula će samo imati definiran zasebni Job i Pool u kojem će se skripti proslijediti drugačiji parametar. U svrhu testiranja i demosntriranja mi smo odlčili implementirati 3 "produkcijske" i 3 "demo" razine GFS-a. Prema tim parametrima skripta određuje gdje će se i kako će se spremiti kopije.

```
case "$LEVEL" in
    "Full")
        run_postgres_dump
        
        echo "Izvršavam glavni Full backup u $BACKUP_DEST..."
        /usr/bin/duplicity full --encrypt-key "$GPG_KEY_ID" "$SSH_OPTS" \
          --archive-dir "$CACHE_DIR" "$BACKUP_SRC" "$BACKUP_DEST"

        if [[ "$POOL" == *"Father"* ]] || [[ "$POOL" == *"Grandfather"* ]]; then
            [[ "$POOL" == *"Demo"* ]] && TARGET="demo-son" || TARGET="son"
            SON_DEST="scp://vbox:vbox@10.0.2.4//home/vbox/backup/$TARGET"
            
            echo "Prepisujem Full backup u $TARGET..."
            /usr/bin/duplicity full --encrypt-key "$GPG_KEY_ID" "$SSH_OPTS" \
              --archive-dir "$CACHE_DIR" "$BACKUP_SRC" "$SON_DEST"
        fi
        ;;

    "Incremental")
        /usr/bin/duplicity incremental --encrypt-key "$GPG_KEY_ID" "$SSH_OPTS" \
          --archive-dir "$CACHE_DIR" "$BACKUP_SRC" "$BACKUP_DEST"
        ;;

    "Restore")
        TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
        RESTORE_PATH="/home/kali/Restore_Test/${POOL}_${TIMESTAMP}"
        mkdir -p "$RESTORE_PATH"
        /usr/bin/duplicity restore --encrypt-key "$GPG_KEY_ID" "$SSH_OPTS" \
          --archive-dir "$CACHE_DIR" "$BACKUP_DEST" "$RESTORE_PATH"
        ;;
esac
```

Također, skripta poziva Duplicity opciju čišćenje starih kopija prema kontekstu posla. Naša politika određuje da se djedovi nikad ne brišu, a očevi i sinovi imaju svoje vlastite kriterije brisanja. Upravo zbog tih kriterija brisanja svaka razina GFS strategije ima svoj direktorij kako bi se primjerice djedovi mogli razlikovati od očeva - oboje su full kopije, što Duplicityju izgleda jednako.

```
echo "--- PROVJERA RETENTION POLITIKE ---"

if [[ "$POOL" == "Demo-Son" ]]; then
    /usr/bin/duplicity remove-all-inc-of-but-n-full 1 --force "$SSH_OPTS" --archive-dir "$CACHE_DIR" "$BACKUP_DEST"
    /usr/bin/duplicity remove-older-than 2m --force "$SSH_OPTS" --archive-dir "$CACHE_DIR" "$BACKUP_DEST"

elif [[ "$POOL" == "Son" ]]; then
    /usr/bin/duplicity remove-all-inc-of-but-n-full 2 --force "$SSH_OPTS" --archive-dir "$CACHE_DIR" "$BACKUP_DEST"
    /usr/bin/duplicity remove-older-than 30D --force "$SSH_OPTS" --archive-dir "$CACHE_DIR" "$BACKUP_DEST"
    
elif [[ "$POOL" == "Demo-Father" ]]; then
    /usr/bin/duplicity remove-older-than 10m --force "$SSH_OPTS" --archive-dir "$CACHE_DIR" "$BACKUP_DEST"
    
elif [[ "$POOL" == "Father" ]]; then
    /usr/bin/duplicity remove-older-than 1Y --force "$SSH_OPTS" --archive-dir "$CACHE_DIR" "$BACKUP_DEST"
fi
```

Važno je napomenuti kako u direktoriju sina neće biti samo inkrementalne kopije. Zbog načina na koji je Duplicity kreiran, Duplicity svoje sigurnosne kopije vidi u lancima koji se nalaze u trenutnom direktoriju. On ne može za inkrementalne kopije gledati neku čitavu kopiju u drugom direktoriju. Zato će se kod svakog full backupa jedna kopija spremiti u direktorij njemu pripadajuće razine (otac ili djed), te još jedna kopija u direktorij sina da se slijedeće inkrementalne kopije nadovezuju na nju. Naravno, tamo će še češće čistiti pa neće doći do tolikog prostornog zasićenja.

Time dobivamo slijedeću strukturu na poslužitelju:
```
/home/vbox/backup/
├── demo-grandfather/             [RAZINA: DJED]
│   ├── duplicity-full.manifest.gpg
│   ├── duplicity-full.20260101T120000Z.vol1.difftar.gpg
│   └── duplicity-full-signatures.sigtar.gpg
│
├── demo-father/                  [RAZINA: OTAC]
│   ├── duplicity-full.manifest.gpg
│   ├── duplicity-full.20260107T120000Z.vol1.difftar.gpg
│   └── duplicity-full-signatures.sigtar.gpg
│
└── demo-son/                     [RAZINA: SIN]
    ├── duplicity-full.manifest.gpg
    ├── duplicity-full.20260113T100000Z.vol1.difftar.gpg
    ├── duplicity-full-signatures.sigtar.gpg
    ├── duplicity-inc.20260113T120000Z.to.20260113T140000Z.vol1.difftar.gpg
    └── duplicity-inc.manifest.gpg
```

## Analiza konfiguracije
Početna konfiguracija sustava temeljila se na korištenju dva alata. Bacula je služila kao glavni alat za upravljanje i pokretanje backup poslova, dok je Duplicity bio zadužen za stvarno izvođenje backupa i restore operacija nad datotekama. U ovom rješenju Bacula Director na poslužitelju pokreće skriptu na klijentskom sustavu. Skripta prima parametre koje joj prosljeđuje Bacula. Na temelju tih parametara određuje radi li se o punom ili inkrementalnom backupu, a istovremeno se definira i GFS sloj kojem backup pripada.

### Uočeni nedostatci 
U nastavku su opisani ključni nedostaci početnog rješenja. Za svaki nedostatak prikazan je konkretan dio konfiguracije ili koda iz kojeg je vidljivo zašto je to problem.

1) **Nezaštićena Bacula komunikacija (TLS isključen na klijentu)**
   
 U konfiguraciji Bacula File Daemona na klijentu TLS je bio isključen, što znači da komunikacija Director ↔ FD nije enkriptirana:
 ```conf
FileDaemon {
  Name = kali-fd
  FDport = 9102
  ...
  TLS Enable = no
  TLS Require = no
}
```
Ovakva konfiguracija predstavlja sigurnosni rizik jer omogućuje potencijalno presretanje ili manipulaciju komunikacijom između komponenti sustava 


2) Backup sadržaj nije enkriptiran
   
  U skripti duplicity.sh backup je izvođen bez enkripicije:
```conf
/usr/bin/duplicity full --no-encryption \
  --archive-dir "$CACHE_DIR" "$BACKUP_SRC" "$BACKUP_DEST"

/usr/bin/duplicity incremental --no-encryption \
  --archive-dir "$CACHE_DIR" "$BACKUP_SRC" "$BACKUP_DEST"
```
Problem: backup datoteke pohranjene na poslužitelju su čitljive. Ako netko dobije pristup backup lokaciji (ili disk bude kompromitiran), kompromitirani su i svi podaci koji su trebali biti sigurnosna kopija.

3) SSH identitet poslužitelja se ne provjerava
   Skripta koristi SSH opcije koje eksplicitno isključuju provjeru identiteta poslužitelja:
   ```conf
   SSH_OPTS='--ssh-options=-o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
   ```
Problem: klijent se može spojiti na “lažni” poslužitelj bez upozorenja. To je tipična konfiguracija koja olakšava demo/testiranje, ali je nepoželjna u stvarnom sustavu jer otvara prostor za MITM napade. 
 
 4) Tajne vrijednosti i pristup bazi u skripti (operativni i sigurnosni rizik)
    
U početnoj verziji skripte korištene su tvrdo zadane vrijednosti (primjer lozinki/passphrase)
Problem: lozinke u skripti ili u okruženju mogu završiti u logovima, povijesti naredbi ili kroz procese. Osim sigurnosti, to otežava održavanje jer se vrijednosti moraju ručno mijenjati u kodu.

## Poboljšanja konfiguracije 

Nakon uočenih slabosti provedene su izmjene kako bi sustav bio sigurniji i pouzdaniji. Poboljšanja su ciljano adresirala komunikacijsku sigurnost, zaštitu backup sadržaja i pouzdanost oporavka. 

Komunikacija između klijenta i servera osigurana je TLS-om. Alatom OpenSSL kreirani su certifikati i ključevi koji su postavljeni u direktorije Bacule. Korisniku "bacula" dana su prava za pristup tim ključevima. Omogućene su sve opcije vezane uz TLS u konfiguracijskim datotekama.

Na strani Bacula backup poslužitelja potrebno je definirati njegov certifikatorski autoritet, certifikat i ključ u postavkama klijenta (bacula-dir.conf):
```
Client {
  Name = kali-fd
  Address = 10.0.2.15
  FDPort = 9102
  Password = "kali"
  Catalog = MyCatalog

  TLS Enable = Yes
  TLS Require = Yes
  TLS CA Certificate File = /etc/bacula/ssl/bacula-ca.crt
  TLS Certificate = /etc/bacula/ssl/ubuntu-server.crt
  TLS Key = /etc/bacula/ssl/ubuntu-server.key
}
```

A na strani Bacula klijenta postaviti njegov certifikatorski autoritet, certifikat i ključ u postavkama FileDaemona (bacula-fd.conf):
```
FileDaemon {                          
  Name = kali-fd
  FDport = 9102                 
  WorkingDirectory = /var/lib/bacula
  Pid Directory = /run/bacula
  Maximum Concurrent Jobs = 20
  Plugin Directory = /usr/lib/bacula

  TLS Enable = Yes
  TLS Require = Yes
  TLS CA Certificate File = /etc/bacula/ssl/bacula-ca.crt
  TLS Certificate = /etc/bacula/ssl/kali-fd.crt
  TLS Key = /etc/bacula/ssl/kali-fd.key
}
```

Sigurnost samih datoteka omogućena je enkripcijom arhiva koje kreira Duplicity. Pri samom pozivu alata Duplicity definira se identifikator ključa kojim se datoteke kriptiraju alatom GPG. Time se na server u konačnici prenose datoteke s .gpg ekstenzijom. U skripti ```duplicity.sh``` definirani su ```PASSPHRASE``` i ```GPG_KEY_ID```. Preko identifikatora se određuje koji ključ se koristi, a passphrase je lozinka za ključ.
```
export PASSPHRASE="kali-backup"
export GPG_KEY_ID="01116997692469C7"
...

case "$LEVEL" in
    "Full")
        run_postgres_dump
        /usr/bin/duplicity full --encrypt-key "$GPG_KEY_ID" "$SSH_OPTS" \
          --archive-dir "$CACHE_DIR" "$BACKUP_SRC" "$BACKUP_DEST"
        ;;
    "Incremental")
        /usr/bin/duplicity incremental --encrypt-key "$GPG_KEY_ID" "$SSH_OPTS" \
          --archive-dir "$CACHE_DIR" "$BACKUP_SRC" "$BACKUP_DEST"
        ;;
```

Ti ključevi su iznimno važni jer bez njih mi možemo imati sigurnosnu kopiju ali ju ne možemo otključati pa je praktički beskorisna. Ključeve je važno exportati i pohraniti na vanjsku memoriju. U slučaju katastrofe u kojoj treba ponovno dizati sustav ti ključevi se ponovno uvoze u njega i zato moramo imati portabilne kopije.

Za implementaciju TLS-a i GPG enkripcije važno je napomenuti kako ih bacula-fd pokreće kao korisnik bacula. Zato je potrebno isključivo tom korisniku dati pristup za rad s direktorijima u kojima se nalaze certifikati i ključevi. U našem slučaju to su direktoriji ```/var/lib/bacula/.gnupg``` i ```/var/lib/bacula/.ssh``` kojima su prava postavljena na 700 i 600, te je njihov vlasnik korisnik bacula.
