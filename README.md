# Skripta main.ps1

## Opis
Ova skripta je razvijena u PowerShell-u i koristi se za generisanje kompletanog dnevnog izvoda.

## Parametri
Skripta prihvata sledeći parametar:

- **RootReportPath:** Putanja do korenskog direktorijuma gde će biti smešteni izveštaji. Ovaj parametar je obavezan.

## Generisanje logova
Skripta generiše logove u fajl sa formatom `yyyy-MM-dd.HH-mm-ss.log`

## Verzija PowerShell-a
Testirano na PowerShell-u verzije 7.4.1.


# Skripta mock.ps1

## Opis
Ova skripta je razvijena u PowerShell-u i koristi se za generisanje mock podataka na fajl sistemu.

## Parametri
Skripta prihvata sledeće parametre:

- **Destination:** Lokacija odredišta gde će skripta generisati mock podatke. Ovaj parametar je obavezan.
- **NumberOfOrganizations:** Broj organizacija koji će biti kreirani. Podrazumevana vrednost je nasumičan broj između 1 i 20.
- **NumberOfPartiesPerOrganization:** Broj partija po organizaciji. Podrazumevana vrednost je nasumičan broj između 1 i 20.
- **NumberOfExternalPartiesPerOrganization:** Broj eksternih partija po organizaciji. Podrazumevana vrednost je nasumičan broj između 0 i broja partija po organizaciji.
- **NumberOfDatesPerParty:** Broj datuma po partiji. Podrazumevana vrednost je nasumičan broj između 1 i 10.

## Verzija PowerShell-a
Testirano na PowerShell-u verzije 7.4.1.
