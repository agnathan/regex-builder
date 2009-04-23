#!/usr/bin/perl -w
package Religion::Bible::Regex::Builder;

=head1 NAME

Religion::Bible::Regex::Builder - builds regular expressions that match Bible References 

=head1 VERSION

version 0.9

=cut

our $VERSION = '0.9';

=head1 SYNOPSIS

use warnings;

use Religion::Bible::Regex::Config;
use Religion::Bible::Regex::Builder;

my $configfile = 'config.yml';

my $c = new Religion::Bible::Regex::Config($configfile);
my $r = new Religion::Bible::Regex::Builder($c);                                                                                                                     
my $text = "Ge 1:1, Mt 6:33, see page 4:5 and Jn 3:16";
$text =~ s/$r->{reference_biblique}/<ref id="$&">$&<\/ref>/g;

print $text . "\n";

--------
This prints:
<ref id="Ge 1:1">Ge 1:1</ref>, <ref id="Mt 6:33">Mt 6:33</ref>, see page 4:5 and <ref id="Jn 3:16">Jn 3:16</ref>

=head1 DESCRIPTION
This module builds highly configurable regular expressions for parsing Bible references.
The goal of this project is to make higher level Bible viewing, editing and tagging tools easier to create.
The configuration files are in YAML format.

Also included with this project are configurations files for Bible verses in different languages.
=cut


use strict;
use warnings;
#use Cwd;
use Carp;
use Data::Dumper;
# Input files are assumed to be in the UTF-8 strict character encoding.
use utf8;
binmode(STDOUT, ":utf8");

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

=head2 METHODS

=over 4

=item new($$;$$)

Builds the set of regular expressions for parsing Bible references.

Parameters:
    1. A Religion::Bible::Regex::Config object which gives configurations
       such as the Books and Abbreviations to recognize, key phrases which 
       mark the beginning of a verse or list of verses, etc ... For more, 
       information see the 

=cut

sub new {
    my $class = shift;
    my $config = shift;
    my $self = {};
    bless $self, $class;

    # Get the Configurations for building these regular expressions
    my %bookconfig = $self->process_config($config);

    #################################################################################### 
    #	Définitions par défaut des expressions régulières avec références bibliques
    #  
    # 	La fonction 'set_regex' a trois paramètres.
    #		1. Un nom unique pour cette expression régulière
    #		2. Une experssion régulière
    #		3. Si la paramètre deux est 'undef', une experssion régulière comme defaut 
    #################################################################################### 
    
    my $spaces = qr/([\s ]*)/;

    #################################################################################### 
    #	Définitions des chiffres
    #################################################################################### 
    # chapitre : c'est un nombre qui indique un chapitre
    my $chapitre = qr/\d{1,3}/;
    $self->set_regex(	'chapitre', 
			$bookconfig{'chapitre'}, 
            $chapitre
		    );

    # verset : c'est un nombre qui indique un verset
    my $verset = qr/\d{1,3}[abcdes]?/;
    $self->set_regex(	'verset', 
			$bookconfig{'verset'}, 
            $verset
		    );

    # chiffre : c'est un nombre qui indique un chapitre ou verset 
    my $chiffre = qr/\d{1,3}[abcdes]?/;
    $self->set_regex(	'chiffre', 
			$bookconfig{'chiffre'}, 
            $chiffre
		    );


    #################################################################################### 
    # Définitions de la ponctuation	
    #################################################################################### 
    # cv_separateur : vous pouvez trouver ce entre un chapitre et un verset
    my $cv_separateur = qr/(?::|\.)/;
    $self->set_regex(	'cv_separateur', 
			$bookconfig{'cv_separateur'}, 
		    $cv_separateur	
		    );

    # separateur : cette sépare deux références bibliques
    my $separateur = qr/\bet\b/;
    $self->set_regex(	'separateur', 
			$bookconfig{'separateur'}, 
    		$separateur	
		    );

    # cl_separateur : cette sépare deux références bibliques et que le deuxième référence est un référence d'un chaptire
    my $cl_separateur = qr/;/;
    $self->set_regex(	'cl_separateur', 
			$bookconfig{'cl_separateur'}, 
    		$cl_separateur	
		    );

    # vl_separateur : cette sépare deux références bibliques et que le deuxième référence est un référence d'un verset
    my $vl_separateur = qr/,/;
    $self->set_regex(	'vl_separateur', 
			$bookconfig{'vl_separateur'}, 
	        $vl_separateur		
		    );

    my $intervale = qr/(?:-|–|−)/;
    # tiret : ce correspond à tous les types de tiret
    $self->set_regex(	'intervale', 
			$bookconfig{'intervale'}, 
		    $intervale	
		    );
    # reference_separateurs : ce correspond à tous les types de separateur entre références biblque 
    my $cl_ou_vl_separateur = qr/(?:$self->{cl_separateur}|$self->{vl_separateur}|$self->{separateur})/;
    $self->set_regex(	'cl_ou_vl_separateurs', 
			$bookconfig{'cl_ou_vl_separateurs'}, 
	        $cl_ou_vl_separateur	
		    );


    #################################################################################### 
    # Définitions de les expressions avec intervales 
    #################################################################################### 

    my $intervale_chiffre = qr/
        # Intervale Verset, Ex '-4', '-45'
        $spaces     # Spaces
        $self->{'intervale'} # Interval
        $spaces     # Spaces
        $self->{'chiffre'} # Chiffre
    /x;

    # intervale_chiffre : deux chapitre avec un tiret entre
    # Par exemple: '-2', '–9', ou ' - 4'
    $self->set_regex(	'intervale_chiffre', 
			$bookconfig{'intervale_chiffre'},  
		    $intervale_chiffre	
		    );

    my $cv_separateur_chiffre = qr/
        # CV Separator Verset
        $spaces# Spaces
        $self->{'cv_separateur'} # CV Separator
        $spaces# Spaces
        $self->{'chiffre'}
    /x;

    # cv_separateur_chiffre : deux chapitre avec un tiret entre
    # Par exemple: ':2', '.9', ou ' : 4'
    $self->set_regex(	'cv_separateur_chiffre', 
			$bookconfig{'cv_separateur_chiffre'}, 
		    $cv_separateur_chiffre	
		    );

    #################################################################################### 
    # Définitions de les references numiques 
    #################################################################################### 

    #######################################################################################################
    # Les mots donne contexte aux référence biblique
    # Par Exemple: 
    #   chapitre_mots: 'voir la chapitre'
    #   texte: voir la chapitre 9
    # 
    #   Avec cette texte 'voir la chapitre' comme chapitre_mots le 9 peu être indentifié comme un chapitre
    #######################################################################################################
   
    # reference_contexte_mots_avant : les mots qui indique que le prochain référence est un chapitre référence
    my $reference_mots = qr/(?:dans|voir aussi)/;
    $self->set_regex(	'reference_mots', 
			$bookconfig{'reference_mots'}, 
            $reference_mots			
    );

    # chapitre_contexte_mots_avant : les mots qui indique que le prochain référence est un chapitre référence
    my $chapitre_mots = qr/(?:dans le chapitre)/;
    $self->set_regex(	'chapitre_mots', 
			$bookconfig{'chapitre_mots'}, 
            $chapitre_mots			
    );

    # verset_contexte_mots_avant : les mots qui indique que le prochain référence est un verset référence
    my $verset_mots = qr/(?:vv?\.)/;
    $self->set_regex(	'verset_mots', 
			$bookconfig{'verset_mots'},  
            $verset_mots
    );

    # voir_contexte_mots_avant : les mots qui indique que le prochain référence est un verset référence
    my $voir_mots = qr/(?:voir)/;
    $self->set_regex(	'voir_mots', 
			$bookconfig{'voir_mots'},  
            $voir_mots
    );


    #################################################################################### 
    # Définitions de les expressions avec livres 
    #################################################################################### 

    # livres_numerique : Ceci est une liste de tous les livres qui commencent par un chiffre 
    my $livres_numerique = qr/
        Samuel|S|Rois|R|Chroniques|Ch|Corinthiens|Co|Thessaloniciens|Th|Timothée|Ti|Pierre|P|Jean|Jn|Esras|Es|Maccabees|Ma|Psalm|Ps
    /x;

    $self->set_regex(	'livres_numerique', 
			$bookconfig{'livres_numerique'}, 
            $livres_numerique
    );

    my $livres_numerique_protect = "";
    if (defined($self->{'livres_numerique'})) {
        $livres_numerique_protect = qr/(?!(?:[\s ]*(?:$livres_numerique)))/;
    }
    $self->set_regex(   'livres_numerique_protect',
            $bookconfig{'livres_numerique_protect'},
            $livres_numerique_protect
    );

    
    my $livres = qr/
        Genèse|Genese|Exode|Lévitique|Levitique|Nombres|Deutéronome|Deuteronome|Josué|Josue|Juges|Ruth|1[\s ]*Samuel|2[\s ]*Samuel|1[\s ]*Rois|2[\s ]*Rois|1[\s ]*Chroniques|2[\s ]*Chroniques|Esdras|Néhémie|Nehemie|Esther|Job|Psaume|Psaumes|Proverbes|Ecclésiaste|Ecclesiaste|Cantique[\s ]*des[\s ]*Cantiqu|Ésaïe|Esaie|Jérémie|Jeremie|Lamentations|Ézéchiel|Ezechiel|Daniel|Osée|Osee|Joël|Joel|Amos|Abdias|Jonas|Michée|Michee|Nahum|Habacuc|Sophonie|Aggée|Aggee|Zacharie|Malachie|Matthieu|Marc|Luc|Jean|Actes|Romains|1[\s ]*Corinthiens|2[\s ]*Corinthiens|Galates|Éphésiens|Ephesiens|Philippiens|Colossiens|1[\s ]*Thessaloniciens|2[\s ]*Thessaloniciens|1[\s ]*Timothée|1[\s ]*Timothee|2[\s ]*Timothée|2[\s ]*Timothee|Tite|Philémon|Philemon|Hébreux|Hebreux|Jacques|1[\s ]*Pierre|2[\s ]*Pierre|1[\s ]*Jean|2[\s ]*Jean|3[\s ]*Jean|Jude|Apocalypse
/x;

    # livres : le nom complet de tous les livres, avec et sans accents
    $self->set_regex(	'livres', 
			$bookconfig{'livres'}, 
            $livres
    );

    my $abbreviations = qr/
        Ge|Ex|Lé|No|De|Dt|Jos|Jug|Jg|Ru|1[\s ]*S|2[\s ]*S|1[\s ]*R|2[\s ]*R|1[\s ]*Ch|2[\s ]*Ch|Esd|Né|Est|Job|Ps|Ps|Pr|Ec|Ca|Esa|Esa|És|Jér|Jé|La|Ez|Éz|Da|Os|Joe|Joë|Am|Ab|Jon|Mic|Mi|Na|Ha|Sop|So|Ag|Za|Mal|Ma|Mt|Mc|Mr|Lu|Jn|Ac|Ro|1[\s ]*Co|2[\s ]*Co|Ga|Ep|Ép|Ph|Col|1[\s ]*Th|2[\s ]*Th|1[\s ]*Ti|2[\s ]*Ti|Ti|Tit|Phm|Hé|Ja|1[\s ]*Pi|2[\s ]*Pi|1[\s ]*Jn|2[\s ]*Jn|3[\s ]*Jn|Jude|Jud|Ap|1[\s ]*Es|2[\s ]*Es|Tob|Jdt|Est|Sag|Sir|Bar|Aza|Sus|Bel|Man|1[\s ]*Ma|2[\s ]*Ma|3[\s ]*Ma|4[\s ]*Ma|2[\s ]*Ps
/x;
    
    # abbreviations : le nom complet de tous les abbreviations, avec et sans accents
    $self->set_regex(	'abbreviations', 
			$bookconfig{'abbreviations'}, 
            $abbreviations
    );

    # livres_et_abbreviations : la liste de tous les livres et les abréviations
    my $livres_et_abbreviations = qr/(?:$self->{'livres'}|$self->{'abbreviations'})/;
    $self->set_regex(	'livres_et_abbreviations', 
			$bookconfig{'livres_et_abbreviations'}, 
            $livres_et_abbreviations
		    );

    # contexte_mots : Tous les mots qui viennent avant une référence biblique. Des mots différents peut 
    #                fournir des contextes différents. Par exemple, 'voir le chapitre' fournit une 
    #                contexte et le chapitre 'Matthew' fournit une référence explicite contexte
    my $contexte_mots = qr/
      (?: # Contexte Mots
        $self->{'livres_et_abbreviations'}  # Livres et abbreviations
        |
        $self->{'chapitre_mots'}   # Chapitre mots
        |
        $self->{'verset_mots'}  # Verset mots
        |
        $self->{'reference_mots'} # Voir mots
      )
    /x;

    $self->set_regex(	'contexte_mots', 
			$bookconfig{'contexte_mots'}, 
            $contexte_mots
		    );

    #livre2abre : une table de changement du livre à l'abréviation
    $self->set_hash(	'book2key', 
			$bookconfig{'book2key'}, 
            {}
    );
    
    #abre2livres : une table de changement du abréviation à livre
    $self->set_hash(	'abbr2key', 
			$bookconfig{'abbr2key'}, 
			{}
		    );

    #livre2abre : une table de changement du livre à l'abréviation
    $self->set_hash(	'key2book', 
			$bookconfig{'key2book'}, 
            {}
    );
    
    #abre2livres : une table de changement du abréviation à livre
    $self->set_hash(	'key2abbr', 
			$bookconfig{'key2abbr'}, 
			{}
		    );


    # livres_avec_un_chapitre :  la liste de tous les livres avec un seul chapitre
    my $livres_avec_un_chapitre = qr/Ab|Abdias|2Jn|2Jean|Phm|Philemon|Philémon|Jud|Jude|3Jn|3Jean/;
    $self->set_regex(	'livres_avec_un_chapitre', 
			$bookconfig{'livres_avec_un_chapitre'}, 
            $livres_avec_un_chapitre
		    );

    #######################################################################################################
    # full_reference_protection : Il s'agit d'une expression régulière complexe. Ne pas changer, sauf si vous savez ce que vous faites.
    #$self->set_regex(	'reference_protection', 
	#		$bookconfig{'reference_protection'}, 
	#		"(?<!(>|\"))(?<!(1|2|3))(?<!(1\\s|2\\s|3\\s))(?<!(1 |2 |3 ))(?<!(1\\n|2\\n|3\\n))"
	#	    );

    # reference_biblique : Expression Régulière Important. Cette expression régulière cherche les références bibliques
    # par exemple : 'Jean 1.1', 'Genèse 1', 'Mt 4:2,6', 
    #$self->set_regex(	'reference_biblique', 
	#		$bookconfig{'reference_biblique'}, 

	#	    );

    my $cv_list = qr/
        $self->{'chiffre'} # LC, '22'
        $self->{'livres_numerique_protect'}
        (?: # Choose between CV and Interval
          (?:
            (?:# LCC: Ge 22-24
              $self->{'intervale_chiffre'}
              (?:# LCCV: Ge 22-23:46
                $self->{'cv_separateur_chiffre'}
                (?: # LCCVV:Ge 22-23:46-49
                    $self->{'intervale_chiffre'}
                )?
              )?
            )
          |
            (?:# LCV:Ge 1:1
              $self->{'cv_separateur_chiffre'}
              (?: # LCVV:Ge 22-23:46-49
                $self->{'intervale_chiffre'}
                (?:# LCVCV:Ge 22:23-46:49
                  $self->{'cv_separateur_chiffre'}
                )?
              )?
            )
          )
        )?
    /x; 

    # cv_list : Combines LC, LCC, LCCV, LCCVV and LCV, LCVV, LCVCV
    $self->set_regex(	'cv_list', 
			$bookconfig{'cv_list'},
	        $cv_list	
		    );


    # reference_biblique_list : Cette expression régulière correspond à une liste de références bibliques 
    #				ex. '1 Ti 1.19 ; Ge 1:1, 2:16-18' or '1 Ti 1.19 ; 2Ti 2:16-18'
    my $reference_biblique = qr/
    (?:
      $self->{'contexte_mots'}
      $spaces # Spaces
      (?: # Chapitre Verset liste
        $self->{'cv_list'}
      )
      (?: # Reference List
        $spaces # Spaces
        $self->{'cl_ou_vl_separateurs'}
        $spaces # Spaces
        $self->{'livres_numerique_protect'}
        (?: # Chapitre Verset liste
          $self->{'cv_list'}
        )
      )*
    )
    /x;

    $self->set_regex(	'reference_biblique', 
			$bookconfig{'reference_biblique'}, 
		    $reference_biblique
		    );

    # reference_biblique_list : Cette expression régulière correspond à une liste de références bibliques 
    #				ex. '1 Ti 1.19 ; Ge 1:1, 2:16-18' or '1 Ti 1.19 ; 2Ti 2:16-18'
    my $reference_biblique_list = qr/
    (?:
      $self->{'contexte_mots'}
      $spaces # Spaces
      (?: # Chapitre Verset liste
        $self->{'cv_list'}
      )
      (?: # Reference List
        $spaces # Spaces
        $self->{'cl_ou_vl_separateurs'}
        $spaces # Spaces
        (?:$self->{'contexte_mots'})?
        $spaces # Spaces
        (?: # Chapitre Verset liste
          $self->{'cv_list'}
        )
      )*
    )
    /x;

    $self->set_regex(	'reference_biblique_list', 
			$bookconfig{'reference_biblique_list'}, 
		    $reference_biblique_list
		    );

    return $self;
}


################################################################################
# Helper functions
################################################################################
=over 5

=item set_regex 

For internal use only.  Please, do not call this function

=cut
sub set_regex {
    my ($self, $key, $regex, $default_regex) = @_;
	if (defined($regex)) {
        my $result = qr/$regex/;	# Evaluate that line
        if ($@) {                       	# Check for compile or run-time errors.
            croak "Invalid regex:\n $regex";
        } else {
            $self->{$key} = $result;
        }
    } elsif (defined($regex) && $regex eq ''){
       return; 
	} else {
		$self->{$key} = $default_regex; 
	}
}

sub set_hash {
    my ($self, $key, $hash, $default_hash) = @_;
    if (defined($hash)) {
            $self->{$key} = $hash;
    } else {
        $self->{$key} = $default_hash;
    }

}

################################################################################
# les fonctions qui se préoccupe de la configuration
################################################################################
sub process_config {
    my $self = shift;
    my $config = shift;
    my %retval;

    while ( my ($key, $value) = each(%{$config->{mainconfig}{regex}}) ) {
        if ($key =~ m/definitions/) {
            $self->init_data_structures($value, $config, \%retval);
        } elsif ($value =~ m/^(?:fichier|file):/) {
            $retval{$key} = $self->build_regexes_from_file($value);
        } elsif (defined(ref $value) && ref $value eq "HASH") {
            $retval{$key} = $self->process_config($value);
        } else {
            $retval{$key} = $value;    
        }
    }
    return %retval;
}

# sub data {
#     my $self = shift;
#     return $self->{'data'};
# }

sub build_regexes_from_file {
    my $self = shift;
    my $value = shift;
    my @list;

    # Enleve le phrase 'fichier:' ou 'file:'
    $value =~ s/^(?:fichier|file)://g;
    
    open(LIST, "<:encoding(UTF-8)", $value) or croak "Couldn't open \'$value\' for reading: $!\n";
    while(<LIST>) {
        chomp;                  # no newline
        s/[^\\]#.*//;           # no comments si il y a un '\' devant le '#' il n'est pas un commentarie
        s/^\s+//;               # no leading white
        s/\s+$//;               # no trailing white
        next unless length;     # anything left?
        push @list, $_;
    }
    close (LIST);
    return "(?:" . join_regex(\@list) . ")";
}

sub join_regex {
	my $array_ref = shift;
	if (defined($array_ref)) {
		return join("|", @{$array_ref});
	} else { 
		return undef;
	}
}

################################################################################
# init_data_structures
# 
# Creates the following mappings:
#   An array of all match book names (book names to search for in a document)
#   An array of all match abbreviation (abbreviations to search for in a document)
#   An array of all book names that begin with a number
#   A hash mapping from match book name to the primary key
#   A hash mapping from match abbreviation to the primary key
#
#   The primary key is the number which starts the entry in the abbr config file
#   For example with this configuration the primary key is '1'
#    1: 
#      Match:
#        Book: ['Genèse', 'Genese']
#        Abbreviation: ['Ge']
#      Normalized: 
#        Book: Genèse
#        Abbreviation: Ge
#
################################################################################
sub init_data_structures {
    my $self = shift;
    my $path_to_config_file = shift;
    my $config = shift;
    my $retval = shift;

    my $bookconfig = $config->{bookconfig};
    my $regex;
    my (@livres, @livres_numerique, @abbreviations);    # Array for all match books and another for match books starting with a number
    my (%book2key, %abbr2key, %key2abbr, %key2book);    # Mappings between match books and abbreviations and the primary key
    
    # Loop through each number and gather the books
    while( my ($key, $value) = each %{$bookconfig} ) {
        # Loop through 
        foreach my $livre (@{$value->{Match}{Book}}) {
            push @livres, $livre;
            push @livres_numerique, $livre if ($livre =~ m/^\d+/);
            $book2key{$livre} = $key;
        }
        # Loop through 
        foreach my $abbreviation (@{$value->{Match}{Abbreviation}}) {
            push @abbreviations, $abbreviation;
            $abbr2key{$abbreviation} = $key;
        }
        $key2abbr{$key} = $value->{Normalized}{Abbreviation};
        $key2book{$key} = $value->{Normalized}{Book};
    }
     
    $retval->{'livres'} = join_regex(\@livres);
    $retval->{'abbreviations'} = join_regex(\@abbreviations);
    $retval->{'livres_numerique'} = join_regex(\@livres_numerique);

    $retval->{'livres_array'} = \@livres;
    $retval->{'abbreviations_array'} = \@abbreviations;
    $retval->{'livres_numerique_array'} = \@livres_numerique;

    $retval->{'book2key'}   = \%book2key;
    $retval->{'abbr2key'}   = \%abbr2key;
    $retval->{'key2book'}   = \%key2book;
    $retval->{'key2abbr'}   = \%key2abbr;
    $retval->{'bookconfig'} = $bookconfig;
}

=item abbreviation($key)

Returns a string representing the normalized abbreviation for a given 
book or key.

Parameters:
    Key - Maybe a number or a book name
          The key is defined in the abbreviation configuration file.
        
          For example, '1' probably corresponds to "Genesis"
          and the abbreviation "Ge" probably go with "Genesis" as well.

=cut

sub abbreviation {
    my $self = shift;
    my $key = shift;
    # try a lookup just in case $key eq 'Pr' or 'Genèse'    
    my $foundkey = $self->key($key);

    # if we found a key then use it as the index
    return undef unless (non_empty($foundkey));
    return $self->{key2abbr}{$foundkey};
}

sub non_empty {
    my $value = shift;
    return (defined($value) && $value ne '');
}  

=item book($key)

Returns a string representing the normalized book name for a given 
book or key.

Parameters:
    Key - Maybe a number or a book name
          The key is defined in the abbreviation configuration file.
        
          For example, '1' probably corresponds to "Genesis"
          and the abbreviation "Ge" probably go with "Genesis" as well.

=cut
sub book {
    my $self = shift;
    my $key = shift;

    # try a lookup just in case $key eq 'Pr' or 'Genèse'    
    my $foundkey = $self->key($key);

    # if we found a key then use it as the index
    return undef unless (non_empty($foundkey));
    return $self->{key2book}{$foundkey};
}

=item key($book_or_abbreviation)

Returns a string representing the key book name or abbreviations
for a given book or key.

Parameters:
    Book_or_abbreviation: is a string defined in the abbreviation
                          configuration file under Key.Match.Book
                          or Key.Match.Abbreviation 

=cut
sub key {
    my $self = shift;
    my $book_or_abbr = shift || '';
    return $self->{book2key}{$book_or_abbr} || $self->{abbr2key}{$book_or_abbr};
}

=item bookname_type($book)

Takes a string representing a normalized book or abbreviation 
and returns :
    CANONICAL_NAME - if the book matches a Key.Normalized.Book value
                     defined in the abbreviation config file.
                    
                     This also means that given a Builder object
                     $book =~ m/$builder->{livres}/ is true.
                     
    ABBREVIATION   - if the book matches a Key.Normalized.Abbreviation
                     value defined in the abbreviation config file.
                    
                     This also means that given a Builder object
                     $book =~ m/$builder->{abbreviations}/ is true.

=cut
sub bookname_type {
    my $self = shift;
    my $book = shift || '';
    return('NONE') unless non_empty($book);
    return('CANONICAL_NAME') if ($book =~ m/$self->{livres}/);
    return('ABBREVIATION') if ($book =~ m/$self->{abbreviations}/);
    return('UNKNOWN');
}

sub is_canonical_name {
    my $self = shift;
    my $book = shift || '';
    return ($self->bookname_type($book) eq 'CANONICAL_NAME') ? 1 : undef;
}

sub is_abbreviation {
    my $self = shift;
    my $abbr = shift || '';
    return ($self->bookname_type($abbr) eq 'ABBREVIATION') ? 1 : undef;
}

=head1 AUTHOR

Daniel Holmlund<< <holmlund.dev at gmail.com> >>

=head1 SPONSORSHIP

Development sponsored by Editions Clé <http://editionscle.com/>.


1;
