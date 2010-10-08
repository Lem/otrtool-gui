#!/usr/bin/perl 
# 
# Control PyroPeters otrtool by a GUI
#
#
use Tk;
use Tk::FileSelect;
require Tk::ProgressBar;
use File::HomeDir;
$version = "OTRtool-GUI 0.01";
$home    = File::HomeDir->my_home; #Homedir des Users
my %prefvalue;
my $file;
my $chk_value=1;
my $fenster = MainWindow->new();
my $foldero;
my $progress;
my $prozent = 0;

$fenster->title ("$version"); #Titel des Fensters

&pref_prase(); #~/.otrtool auslesen

sub pref_prase () {
        open(IN,"< $home/.otrtool") || die;
        @Datei = <IN>;
        foreach $line (@Datei) {
                if ($line =~ /(\w+)=(.*)/i) {
                        $prefvalue{$1}=$2; #Alle Werte auslesen und setzten
                }
        }
}


sub pref_save () {
		open SAVE, "> $home/.otrtool"; # open...

        $settings="bin=$prefvalue{'bin'}\n".
				  "mail=".$mailentry->get()."\n".
				  "password=".$passentry->get()."\n";
        print SAVE $settings;  #Schreibe Pfad zu binary
		close SAVE; #Close...

        #Bestaetigung
        my $popup = $fenster->Toplevel();
        $popup->title ("Einstellungen gespeichert");
        $popup->Label(-text    => 'Einstellungen wurden gespeichert' )->pack();
        $popup->Button(-text    => 'OK',-command => sub { $popup->destroy(); } )->pack; #Alles OK.
}

sub pref_del () {
        #Bestaetigung
        my $popup = $fenster->Toplevel();
        $popup->title ("Einstellungen löschen?");
        $popup->Label(-text    => 'Einställungen wirklich löschen?' )->pack();
        $popup->Button(-text    => 'Ja',
                   -command => sub { unlink "$home/.otrtool";$popup->destroy(); } )->pack(-side=>'left'); #Loesche .otrtool
        $popup->Button(-text    => 'Nein',
                   -command => sub { $popup->destroy() } )->pack(-side=>'left'); #Fenster zerstoeren
}



sub pref_change () {
		&pref_prase();
        my $pref_w = $fenster->Toplevel();
        $pref_w->title ("Einstellungen");

		$pref_w->Label(-text => "Daten werden unverschluesselt in ~/.otrtool gespeichert!",)->pack(-side => 'top'); #Hinweiß!!

		#Frames
        $binframe=$pref_w->Frame()->pack () ; #Frame fuer Binary-Stuff
        $mailframe=$pref_w->Frame()->pack (-fill => 'x') ; #Fuer E-Mail-Stuff
        $passframe=$pref_w->Frame()->pack (-fill => 'x') ; #Fuer Passwort-Stuff

		#Binary-Frame: Text, Anzeige, Button
		$binframe->Label(-text => "Binary:",)->pack(-side => 'left');
		$binpath=$binframe->Label(-text => $prefvalue{'bin'}, -relief => 'groove',-width =>30)->pack(-side => 'left',-fil => 'x',-padx => 2);
		$binframe->Button(-text => 'Auswählen', -command => sub {$prefvalue{'bin'} = $fileselect->Show; $binpath->configure (-text => $prefvalue{'bin'});})->pack(-side => 'left',-fill => 'x');

		#Mail-Frame: Text, Eingabe
		$mailframe->Label(-text => "E-Mail:",)->pack(-side => 'left');
		$mailentry=$mailframe->Entry(-text => $prefvalue{'mail'},-width => 30)->pack(-side => 'left',-fill => 'x');

		#Password-Frame: Text, Eingabe
		$passframe->Label(-text => "Passwort:",)->pack(-side => 'left');
        $passentry=$passframe->Entry(-text => $prefvalue{'password'},-width =>27)->pack(-side => 'left',-fill => 'x');

		#Loveley Buttons: Speichern, Abbrechen
        $pref_w->Button(-text => 'Speichern', -command => sub { \&pref_save(); $pref_w->destroy();}, )->pack(-side => 'left');
        $pref_w->Button(-text => 'Abbrechen', -command => sub { $pref_w->destroy(); } )->pack(-side => 'left');
}

sub about () { #...
        my $popup = $fenster->Toplevel();
        $popup->title ("Über");
        $popup->Label(-text    => "$version\n\nVeröffentlicht unter GPLv2.\nLizenz ist im Ordner zu finden.\n\nBugs bitte via Issue-Tab von github melden." )->pack();
}

sub pop_error ($) { #Pop einen Fehler
	$error = shift;
	$popup = $fenster->Toplevel();
	$popup->title ("ERROR");
	$popup->Label(-text => "$error" )->pack();
	$popup->Button(-text    => 'OK',-command => sub { $popup->destroy(); } )->pack;
}
	


sub dekode () { 
		
	if ($chk_value == 1) {	
		if (!-f $prefvalue{'bin'}) {&pop_error("$prefvalue{'bin'} ist keine Datei!");} #Ist Binary eine Datei?
		elsif ($file !~ m/\.otrkey/i) { &pop_error("Kein OTRKEY!?");} #Ist file otrkey-extension?
		elsif (!-d $foldero) { &pop_error("$foldero ist kein Ordner!");} #Zielordner ein Ordner?
		elsif ((!-e $file) && (!-f $file)) { &pop_error("OTRKEY ist keine Datei oder existiert nicht!");} #Existent und eine Datei?
		else { #Sollte alles OK sein
			
			$file =~ m/([a-z0-9:_\-\.]*)$/i; #Dateinamen suchen
			$foldero = "$foldero/$1"; #Dateinamen an Zielordner
			$foldero =~ s/\.otrkey$//i; #Extension entfernen
			open OTRTOOL, $prefvalue{'bin'}." -x -e $prefvalue{'mail'} -p $prefvalue{'password'} -g -O $foldero $file|"; #Oeffne Filehandle zum lesen von Ausgabe
			print "DEBUG: $_";
			while (<OTRTOOL>) { #Note to myself: While besser als foreach
				if ($_ =~ m/gui>\s+(\d+)/) { #Regex Prozent
					$prozent=$1; #Setze Prozent 
					$progress->update; #Update ProgressBar
				}
				elsif ($_ =~ m/gui> Finished.*/) {
					$prozent="100"; #Wenn Finish dann alles geschaft!
					$progress->update;
				}
			}		
		}
	}
	elsif (chk_value == 2) {
		&pop_error("NICHT IMPLEMENTIERT!"); #Nicht implementiert
	}
}


#Menue: 
$mb = $fenster->Frame(-bd => 5)->pack(-anchor => 'nw');

$m_opts = $mb->Menubutton(-text      => "Einstellungen")->pack(-side => 'left');
$m_help = $mb->Menubutton(-text      => "Hilfe")->pack(-side => 'left');

$m_opts->command(-label   => "Einstellungen", -command => [\&pref_change, "einstellungen"]);
$m_opts->command(-label   => "Einstellungen löschen", -command => [\&pref_del, "loeschen"]);
$m_help->command(-label   => "Über", -command => [\&about, "ueber"]);


# Ich werde auf keinen Fall diese unsaubere GUI kommentieren :/

#Checkbox-Choice
$chkbox = $fenster->Frame()->pack(-anchor => 'w');
$chkfile = $chkbox->Radiobutton(-text => "Dekode Datei", -variable => \$chk_value,-value => "1")->pack(-side => 'left');
$chkfolder = $chkbox->Radiobutton(-text => "Dekode Ordner", -variable => \$chk_value,-value => "2", -command => sub { $chkfolder_value=0;})->pack(-side => 'left');

#Select file
$sf= $fenster->Frame()->pack;
$file = $home;
$sf->Label(-text => "Datei:",-width =>15)->pack(-side => 'left',-fill => 'x',-padx =>2);
$label_selected_file=$sf->Label(-text => $file, -relief => 'groove',-width =>20)->pack(-side => 'left',-fil => 'x',-padx => 2);
$fileselect = $fenster->FileSelect(-directory => $home); #Set ~/
$fileselect->configure(-verify => ['-f']);
$sf->Button(-text => 'Auswählen', -command => sub {$file = $fileselect->Show; $label_selected_file->configure (-text => $file);})->pack(-side => 'left',-fill => 'x');

#Select folder
$sff= $fenster->Frame()->pack;
my $folder = $home;
$sff->Label(-text => "Ordner:",-width =>15)->pack(-side => 'left',-fill => 'x',-padx => 2);
$label_selected_folder=$sff->Label(-text => $folder, -relief => 'groove',-width => 20)->pack(-side => 'left',-fill =>'x',-padx => 2);
$folderselect = $fenster->FileSelect(-directory => $home); #Set ~/
$folderselect->configure(-verify => ['-d']);
$sff->Button(-text => 'Auswählen', -command => sub {$folder = $folderselect->Show; $label_selected_folder->configure (-text => $folder);})->pack(-side => 'left',-fill => 'x');

#Select outpudfolder
$sfo= $fenster->Frame()->pack;
$foldero = $home;
$sfo->Label(-text => "Speichern in:",-width =>15)->pack(-side => 'left',-fill => 'x',-padx => 2);
$label_selected_foldero=$sfo->Label(-text => $foldero, -relief => 'groove',-width => 20)->pack(-side => 'left',-fill => 'x',-padx => 2);
$folderselecto = $fenster->FileSelect(-directory => $home); #Set ~/
$folderselecto->configure(-verify => ['-d']);
$sfo->Button(-text => 'Auswählen', -command => sub {$foldero = $folderselecto->Show; $label_selected_foldero->configure (-text => $foldero);})->pack(-side => 'left',-fill => 'x');

#Listbox
$listb= $fenster->Frame()->pack;
$listbox = $listb->Listbox(-width => 40, -height => 2)->pack;

#Processbar
$progress = $fenster->ProgressBar(-padx=>2, -pady=>2, -borderwidth=>2,
			  -troughcolor=>'#BFEFFF', -colors=>[ 0, '#104E8B' ], -variable => \$prozent,
			  -length=>100 )->pack();

#Footer
$fenster->Button(-text => 'Schließen', -command => sub { exit;}, )->pack(-side => 'right');  
$fenster->Button(-text => 'Dekodieren', -command => sub { \&dekode(); } )->pack(-side => 'right');

MainLoop(); # Call GUI
