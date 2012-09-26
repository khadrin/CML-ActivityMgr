use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name => 'CML::ActivityMgr',
    license  => 'perl',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        #'Config::YAML' => 0,
        'DateTime::Format::Strptime' => 0,
        'DateTime' => 0,
        'Email::MIME::CreateHTML' => 0,
        'Email::Sender' => 0,
        'File::ShareDir' => 0,
        'File::Slurp' => 0,
        'Getopt::Long' => 0,
        'HTML::Entities' => 0,
        'HTML::TableContentParser' => 0,
        'Moose' => 0,
        'Template' => 0,
        'WWW::Mechanize' => 0,
    },
    script_files => 'bin/cml-activity-mgr',
    share_dir => 'share',
);
$build->create_build_script;

exit;
