#!/usr/bin/perl -w
package Religion::Bible::Regex::Config;

use strict;
use warnings;

use YAML::Loader;
use Carp;
use Data::Dumper;

# Input files are assumed to be in the UTF-8 strict character encoding.
use utf8;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

sub new {
	my $class = shift;
    my $self = {};
    my $configs = shift;
    my $defaults = shift;
    bless ($self, $class);

    if (ref $configs eq '') {
        croak "Configuration file is not found:$configs\n" unless (-e $configs);

        $self->{mainconfig} = $self->read_yaml_file($configs);
        if (defined($self->{mainconfig}{regex}{definitions})) {
            $self->{bookconfig} = $self->read_yaml_file($self->{mainconfig}{regex}{definitions});
        }
    } elsif (ref $configs eq 'HASH') {
       $self->{mainconfig} = $configs; 
       $self->process_defaults($defaults);
    } else {
        confess "ReferenceBiblique::Config::new initialized with bad argument\n";
    }
    return $self;
} 

sub process_defaults {
    my $self = shift; 
    my $defaults = shift; 

    while ( my ($key, $value) = each(%{$defaults}) ) {    
       $self->set($key, $value) unless defined($self->{mainconfig}{$key});  
    }
}

sub get {
    my $self = shift;
    my @keys = @_;

    my $ret = $self->{mainconfig};
    foreach my $key (@keys) {
        carp "Configuration not found: {$key}" unless defined($ret->{$key});
        $ret = $ret->{$key};
    }
    return $ret;
}

# This is kinda a dumb function
sub set {
    my $self = shift;
    my $key = shift; 
    my $value = shift; 
    $self->{mainconfig}{$key} = $value;
}

sub gethash {
	my $self = shift;
	return $self->{'config'}; 
}

sub get_reference {
	my $self = shift;
	return $self->{'reference'}; 
}

sub get_regex {
	my $self = shift;
	return $self->{'regex'}; 
}

sub get_versification {
	my $self = shift;
	return $self->{'versification'}; 
}

sub read_yaml_file {
    my $self = shift;
    my $path_to_config_file = shift;
    my $config;

    my $yaml_loader = YAML::Loader->new();
    my $yaml_text;

    # Vous ouvrez le fichier de configuration 
    if(open(CONFIG, "<:encoding(UTF-8)", $path_to_config_file)) { 
        {
            local( $/, *FH );
            $yaml_text = <CONFIG>;  # slurp it
        }
        $config = $yaml_loader->load($yaml_text);
    	close (CONFIG);
    }

    return $config;
}



1;
