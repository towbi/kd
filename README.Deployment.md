Diese Dokumentation entstand ad hoc aus einem internen und spezialisierten
Programm. Eventuelle Unstimmigkeiten/Unklarheiten können daraus resultieren.

# kd Einrichtung

Die Dokumentation in dieser Datei soll als Vorschlag dienen.

## Verzeichnisstruktur

Die Verzeichnisstruktur ist grob wie folgt:

    kd/                 Wurzelverzeichnis von kd
        bin/                enthält die Programe
            kd/             enthält die ausführbaren Dateien von kd (hg repository)
            dbskripte/      enthält die Einleseskripte
        data/               enthält die sortierten kd-Dateien
            testfarm/
                grufu/           
                im/
                ...
            testfarm2/
        incoming/           enthält die unsortierten kd-Dateien (rsync)
            testfarm/
            testfarm2/
        log/                enthält die Logdateien
            testfarm/
                grufu/
                im/
                ...
            testfarm2/

### kd/bin/

Hierin befinden sich die DB-Einleseskripte und die Programme von 
kd.

### kd/data/

Hier müssen die in den Profilen angegebenen Unterverzeichnisse angelegt 
sein. Alle Verzeichnisse darunter (z.B. _grufu_, _im_, ...) werden automatisch 
angelegt.

### kd/incoming/

Hier müssen wie bei _data/_ die in den Profilen angegebenen 
Unterverzeichnisse angelegt sein.

### kd/log/

Hier müssen mehrere Verzeichnisse angelegt sein. Welche das sind, hängt 
einerseits von dem in einem Profil angegebenen Unterverzeichnis für einen 
bestimmten Dateityp ab.

## Automatische Ausführung (crontab)

Die automatische Ausführung wird durch mehrere Cronjobs bewerkstelligt, 
welche sich grob in die Schritte

 * Dateisynchronisierung
 * Ausführung von _kd_ und der DB-Einleseskripte
 * Archivieren alter Dateien ([drotate](http://movb.de/drotate))
 * Synchronisation mit Backup-Server

gliedern lassen.

