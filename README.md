Diese Dokumentation entstand ad hoc aus einem internen und spezialisierten
Programm. Eventuelle Unstimmigkeiten/Unklarheiten können daraus resultieren.

# kd

Dateibasiertes Sortieren und Einspielen von Forschungsdaten.

Die Synchronisation erfolgt mittels rsync über SSH, die periodische
Ausführung mittels Cronjobs.

* [Download](download.html)
* [Einrichtung](deployment.html)
* [Profile](profile.html)

kd besteht aus mehreren Programmen. Die Programme, die für das 
manuelle und automatische Sortieren und Einlesen zuständig sind, heißen 
`kd-process` bzw. `kd-process-file`. Weitere Programme sind `kd-list` und 
`kd-unmark`, welche bei Diagnosen und Fehlerfällen nützlich sind. 

Alle Programme können auch äquivalent als `kd process`, `kd 
process-file`, `kd list` und `kd unmark` aufgerufen werden. Das ist die 
Form, die im Folgenden benutzt wird. 

Die Hilfe zu einem Befehl gibt es mit 

    kd help Befehl

also etwa `kd help process` um die Hilfe zu `kd-process` aufzurufen. 

Wenn im Folgenden von _Sortieren_ die Rede ist, meint dies den Prozess, 
die Datei in dem im Profil angegebenen Verzeichnis zu speichern und, falls 
nötig, eine Umbenennung vorzunehmen. _Einlesen_ steht für das Einlesen 
in die Zieldatenbank mit Hilfe der Einleseskripte. 

## Benutzung von `process` und `process-file` 

Die Aufrufsyntax und eine kure Beschreibung der Befehle liefert `kd help 
process` bzw. `kd help process-file`. 

### Profil

Jeder Aufruf benötigt die Übergabe des passenden Profils (vgl. 
[Profile](profile.html)). Ein Profil _pro_ ist eine Datei, die zunächst im 
aktuellen Verzeichnis gesucht wird. Wird sie im aktuellen Verzeichnis 
nicht gefunden, wird nach der Datei _$HOME/.kdprofile.pro_ gesucht. Dies 
ist der Ort, wo die Profile derzeit gespeichert sind. Wenn das Profil in 
_$HOME/.kdprofile.testfarm_ liegt, lautet der entsprechende Aufruf für 
`kd process` bspw.

    kd process testfarm

### Dateien sortieren und Einleseskripte starten 

#### Sortieren 

Wenn das Profil erfolgreich gelesen werden konnte, werden mit dem Aufruf 
von `kd process pro` alle im Quellverzeichnis befindlichen Dateien
bearbeitet. Eine Datei wird nur dann 
sortiert und eingelesen, wenn sie nicht schon in einem früheren lauf von 
`process` oder `process-file` erfolgreich bearbeitet wurde. 

Wenn `kd process` auf eine zu bearbeitende Datei stößt, dann wird für 
diese Datei `kd process-file` aufgerufen: 

    kd process-file betrieb datei

also bspw. `kd process-file testfarm "xt 100225.txt"`. Anhand der im 
Profil angegebenen Regeln wird die Datei dann bearbeitet, dass heißt sie 
wird in ein entsprechenden Verzeichnis kopiert und umbenannt. 

#### Einlesen 

Wenn die Dateien in die Datenbank eingelesen werden sollen, dann muss 
`process` bzw. `process-file` der Parameter `--input` oder kurz `-i` 
übergeben werden: 

    kd process-file -i betrieb datei

## Diagnosen und Fehlerfälle 

Für Diagnosen und Fehlerfälle können die Programm `kd list` und `kd 
unmark` zum Einsatz kommen. 

### `kd-list` 

Mit `kd list` kann man sich die Datensätze der Statusdatenbank von 
kd anzeigen lassen: Das sind die Dateien, die schon bearbeitet 
wurden. Ein Datensatz ist von der Form: 

    |oldfilename|farmid|newfilename|timestamp|

* _oldfilename_ ist der ursprüngliche Name einer bearbeiteten Datei 
* _farmid_ ist die Betriebsnummer des Betriebs
* _newfilename_ ist der neue Name, den die Datei nach dem Sortiervorgang 
erhalten hat 
* _timestamp_ ist der Zeitpunkt, zu dem die Datei von kd bearbeitet 
wurde 

Ohne weitere Parameter listet `kd list` sämtliche Datensätze zu einem 
Profil/Betrieb auf: 

    kd list betrieb

Die Ausgabe kann mit `grep` gefiltert werden. Beispiel:

    $ kd list testfarm | grep 100729
             20100729.dpb  |        6  |       kiel-100728.dpb  |  2010-07-29
       kiel-ta 100729.txt  |        6  |    kiel-ta-100729.txt  |  2010-08-02
             20100730.dpb  |        6  |       kiel-100729.dpb  |  2010-08-02
       Kiel-se 100729.txt  |        6  |    kiel-se-100729.txt  |  2010-08-02
             VB100729.DAT  |        6  |          VB100729.DAT  |  2010-08-02
             VG100729.DAT  |        6  |          VG100729.DAT  |  2010-08-02
             VR100729.DAT  |        6  |          VR100729.DAT  |  2010-08-02
             VW100729.DAT  |        6  |          VW100729.DAT  |  2010-08-02
     ...

`kd list` können Bedingungen in SQL-Syntax übergeben werden, um die 
Datensätze zu filtern. Beispiel: 

    kd list testfarm "WHERE newfilename LIKE 'pe%' AND timestamp > 
      '2010-02-25' ORDER BY timestamp DESC"

Der gesamte SQL-Ausdruck muss in Anführungszeichen stehen. Darin 
vorkommende Strings müssen in einfache Anführungszeichen gesetzt werden. 

### `kd unmark` 

Wenn nach dem Bearbeiten einer Datei _XYZ_ festegestellt wird, dass sie 
falsch sortiert oder eingelesen wurde und der Fehler von kd nicht 
erkannt wurde, dann wird sich selbst ein explizit aufgerufenes 

    kd process-file testfarm XYZ

weigern, die Datei erneut zu bearbeiten. In diesem Fall muss die Datei als 
_unbearbeitet_ markiert werden. Oder, mit anderen Worten: Die Markierung, 
dass sie bearbeitet wurde, muss entfernt werden. Dies macht man mit dem 
Befehl 

    kd mark -u testfarm XYZ

Beim erneuten Aufruf von `kd process-file testfarm XYZ` wird die Datei 
_XYZ_ nun eingelesen. Man kann mehrere Dateien auf einmal übergeben.

## Lizenz

kd, Copyright (C) 2009-2014  Tobias M.-Nissen <<tn@movb.de>>

Dieses Programm ist freie Software. Sie können es unter den Bedingungen
der GNU General Public License, wie von der Free Software Foundation
veröffentlicht, weitergeben und/oder modifizieren, entweder gemäß Version
3 der Lizenz oder (nach Ihrer Option) jeder späteren Version.

Die Veröffentlichung dieses Programms erfolgt in der Hoffnung, daß es Ihnen
von Nutzen sein wird, aber OHNE IRGENDEINE GARANTIE, sogar ohne die
implizite Garantie der MARKTREIFE oder der VERWENDBARKEIT FÜR EINEN
BESTIMMTEN ZWECK. Details finden Sie in der GNU General Public License.

Die GNU General Public License kann unter
[http://www.gnu.org/licenses/](http://www.gnu.org/licenses/)
abgerufen werden.

