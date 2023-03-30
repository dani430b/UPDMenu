# UPDMenu

Krav:

Ingen Excel

Automatisk udtræk fra CMDB

Ingen lokal Admin installation

Udtræk af password fra 1password
Der skal være installeret PSWindowsUpdate på serveren, ellers virker scriptet ikke.
Dette kan gøre ved at skrive Install-Module -Name PSWindowsUpdate -Force inde i terminalen

En menu:

Nr1 opdatere alle SQL servere

Nr2 opdatere alle andre servere

Nr4 laver en get-windowsupdate, og vender tilbage med en status for at se hvilke installationer ikke er gået igennem
Nr5 laver en status på de resterende servere som ikke er blevet opdateret eller der var en fejl på

Nr9 rebooter alle SQL servere

Nr0 rebooter alle andre servere
P printer custom patch server til en fil

q afslutter

![image](https://user-images.githubusercontent.com/95855777/228765958-c2bd9e07-21da-4a1c-8a2c-e1a781de2a94.png)

Når du har valgt hvilke servere der skal opdateres, skal du klikke ja ved popup vinduet. 

![image](https://user-images.githubusercontent.com/95855777/228766016-a9d1d9d0-6387-467b-b794-2e56309da404.png)

Serverne bliver automatisk udtrukket fra CMDB, samt password fra 1password. Der er en tekst fil med en undtagelses liste, de bliver ikke opdateret. Der bliver sendt en invoke-job command til serverne, som starter et scheduled job med installationerne. Hvis ikke alle opdateringerne er downloadet på serveren, bliver der først sendt et schedjuled-job omkring en download, og derefter installere den Windows opdateringerne.

Man skal selv køre en status på serverne efter man har sat dem til. Hvis du vælger valgmulighed 3, laver du en get-windowsupdate til alle serverne. Indtil videre kommer der en logfil med de servere som ikke har fået installeret opdateringerne endnu. Hvilket vil sige at der er gået noget galt på de servere. Indtil videre kan man kun se om det er en downloading af opdateringer som har fejlet

Når serverne er klar til en genstart kan man enten vælge 9 eller 0, 9 for sql servere og 0 for alle andre. Når du har valgt hvilke servere der skal genstarte, skal du klikke ja ved pop up vinduet, derefter laves der et udtræk fra CMDB, og rebooter de server der er valgt


[kode_information.docx](https://github.com/dani430b/UPDMenu/files/11109071/kode_information.docx)
