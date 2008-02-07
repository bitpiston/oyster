=xml
<document title="Installation Utility">
    <warning>
        INCOMPLETE! DONT RUN THIS!
    </warning>
    <synopsis>
        This will create a new config.pl for you and then run the update utility.
    </synopsis>
=cut
package oyster::script::update;

# configuration
BEGIN {
    our $config = eval { require './config.pl' };
    die "Could not read ./config.pl, are you sure you are executing this script from your shared directory:\n$@\n\n" if $@;
}

# load oyster libraries
use oyster 'launcher';
use exceptions;
#use module;
#use database;

my %new_config;
$| = 1; # disable output buffering

# print the welcome message
print "Welcome to Oyster's Installer.\n\n";

# get their site ID
my $site_id;
until ($site_id) {
    print "Your site ID must contain only lowercase letters and underscores.\n";
    print "Site ID: ";
    $site_id = <STDIN>;
    chomp($site_id);
    if ($site_id =~ /[^a-z_]/) {
        print "! Invalid site ID.\n";
        undef $site_id;
    }
}

# get their environment
my $environment;
until ($environment) {
    print "Your environment must contain only lowercase letters and underscores.\n";
    print "Environment [development]:";
    $environment = <STDIN>;
    chomp($environment);
    $environment = 'development' unless length $environment;
    if ($environment =~ /[^a-z_]/) {
        print "! Invalid environment.\n";
        undef $environment;
    }
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2008
