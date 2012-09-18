use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CML::ActivityMgr',
    AUTHOR              => q{Stephen J. Smith <sjs@khadrin.com>},
    VERSION_FROM        => 'lib/CML/ActivityMgr.pm',
    ABSTRACT_FROM       => 'lib/CML/ActivityMgr.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => { bin/cml-activity-mgr },
    PREREQ_PM => {
        'Test::More' => 0,
        'Moose' => 0,
        'WWW::Mechanize' => 0,
        'HTML::TableContentParser' => 0,
        'DateTime' => 0,
        'DateTime::Format::Strptime' => 0,
        'HTML::Entities' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CML-ActivityMgr-*' },
);
