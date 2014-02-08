Diese Dokumentation entstand ad hoc aus einem internen und spezialisierten
Programm. Eventuelle Unstimmigkeiten/Unklarheiten können daraus resultieren.

# kd Profil

Ein Profil von kd ist eine Konfigurationsdatei, die 
definiert, wie mit den Dateien eines Betriebes verfahren werden 
soll.

Da ein Profil direkt von Perl geparst wird (mit `do`), hat die 
Datenstruktur Perl-Syntax. Wenn das Profil Syntaxfehler aufweist, endet 
die Programmausführung sofort und eine Perl-Fehlermeldung erscheint. Alle 
Programme (kd-process, kd-process-file, kd-list und kd-unmark) müssen mit 
einem Profil aufgerufen werden.

Folgendes Profil enthält alle möglichen Schlüsselwörter. Im 
Folgenden wird dieses Profil daher kommentiert.

Kommentare werden mit # eingeleitet:

    # Testfarms Profil für kd

Das Profil wird in einer Hashreferenz `$profile` gespeichert. Darin kommen 
die Schlüsselwörter `name`, `db_app_path`, `db_log_path`, `source`, 
`destination`, `status_file`, `keep_state`, und `mapping` vor.

    $profile = {
      name        => 'Testfarm',                                # der Name des Profils
      shortname   => 'testfarm',
      farmid      => '9',
      db_app_path => '/home/suatt256/kd/apps/kd',     # Pfad zu den Einelseskripten
      db_log_path => '/home/suatt256/kd/logs/kd',     # Wurzelverzeichnis für die Logdateien
                                                                  #   der Einleseskripte
      source      => '/home/suatt256/kd/incoming/kd', # Quellverzeichnis, in dem die neuen 
                                                                  #   kd-Dateien ankommen
      destination => '/home/suatt256/kd/data/kd/',    # Wurzelverzeichnis für sortierte Dateien
      dbi_connect        => [ # database for kd
          'dbi:SQLite:dbname=/home/user/kd/state.db',
          '', # no user
          '', # no pass
          { RaiseError => 1, PrintError => 0, AutoCommit => 1 }
      ],
      keep_state  => 50, # days                                   # Zeitraum für die Speicherung des
                                                                  #   Bearbeitungszustands einer Datei
      verbose     => 0,
      date_from_filename => 0,

`mapping` selbst ist nun wieder eine Hashreferenz auf die Regeln, die 
vorgeben, wie die einzelnen Dateitypen zu verarbeiten sind. Eine 
Erklärung der Regeln erfolgt unter dem Beispiel.

      mapping => {
          'xt \d{6}\.(txt|TXT)' => {
              priority => 600,
              dir     => 'tag',
              prefix  => 'xt ',
              ext     => '.txt',
              dbinput => 'tagesdaten.pl' },
          '*.\.cab$' => {
              dir     => 'cab',
              prefix  => 'kiel-',
              ext     => '.cab',
              date_from_filename => 1,
              date_regex => '(\d{6})\d*\.cab$',
          },
          ...

`mapping` zeigt auf Hashes (die Regeln) der Form

    regex => {
      priority => int,
      dir      => string,
      prefix   => string,
      ext      => string,
      dbinput  => string,
    }

* `regex` ist ein regulärer Ausdruck, der den Aufbau des Dateinamens als 
  regulären Ausdruck beschreibt.
* `priority` gibt die Priorität dieses Dateityps gegenüber den anderen 
  Dateitypen an. Wenn keine Priorität für einen Dateityp explizit 
  definiert wird, wird ein Wert von 500 angenommen.
* `dir` gibt das Verzeichnis unterhalb des in `destination` definierten 
  Verzeichnisses an, in das die Datei einsortiert werden soll.
* `prefix` und `ext` geben das Präfix bzw. das Suffix des sortierten 
  Dateinamens an. Jeder sortierte Dateiname wird umbenannt in 
  `$prefix$yymmdd$ext`, wobei `$yymmdd` der Zeitstempel der Datei (zwei 
  Stunden vor deren Erstellung, vgl. `get_date_from_mtime` in 
  source:/kd/KD/Aux.pm) ist.
* `dbinput` gibt an, welches Programm in `db_app_path` für das Einlesen 
  zuständig ist. Wenn hier kein Programm angegeben wird, dann wird nicht 
  versucht die Datei einzulesen.

