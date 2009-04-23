package Religion::Bible::Test::FixtureHelper;

use strict;
use warnings;
use utf8;
require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $FIXTURES = 0;

# Preloaded methods go here.
binmode DATA, ":utf8";
binmode STDOUT, ":utf8";

sub new {
    my $class = shift;
    my $file = shift || *DATA;
    my $current = undef;
    my $key;
    my $value;
    my $self = {} ;
    while ( <$file> ) {
        chomp;
        last if /__END__/;
        s/#.*$//g;
        if (m/^(\d+):/) {
                $current = $1;
        }
        elsif (m/^  (\w+):(.*)$/) {
                $self->{fixtures}{$current}{$1} = $2;
        }
    }
    bless $self, $class;
    return $self;
}

sub all_fixtures {

    my $self = shift;

    keys % { $self->{fixtures} } ;
}

1;

__DATA__
__END__
