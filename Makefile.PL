use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Religion::Bible::Regex::Builder',
    AUTHOR              => 'Daniel Holmlund <holmlund.dev@gmail.com>',
    VERSION_FROM        => 'lib/Religion/Bible/Regex/Builder.pm',
    ABSTRACT_FROM       => 'lib/Religion/Bible/Regex/Builder.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Religion-Bible-Regex-*' },
);
