# smart-contracts-unibas
Git Repo for smart contract lecture

Voting on blockchain

Functions:
- Datum setzen (Nur durch Admin möglich)
- Betrag setzen, der für den Event benötigt wird (nur admin)
- Add Admin (Nur durch Owner möglich)
- Member hinzufügen (alle Admin)
- Für den Event anmelden (Für alle Member möglich) mit Geldüberweisung
- Minimum Teilnehmer
- Maximum Teilnehmer
- Get Refund wenn zuwenige eingeschrieben
- Get Refund wenn mehr Geld einbezahlt als benötigt

Offene Fragen:
- Was passiert wenn setEventDetails aufgerufen wird, nachdem bereits Geld einbezahlt wurde? --> abfangen
- Withdraw for owner --> Automatische Auszahlung 
- wenn Betrag nicht erreicht --> withdraw function für member, automatische auszahlung an alle