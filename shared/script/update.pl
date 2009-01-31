=xml
<document title="Oyster Update/Installation Utility">
    <synopsis>
        This utility runs module installation routines and brings their revisions up to date.
    </synopsis>
    <todo>
        Document how to create revision files.
    </todo>
    <todo>
        Document arguments
    </todo>
=cut
package oyster::script::update;

# configuration
BEGIN {
    our $config = eval { require './config.pl' };
    die "Could not read ./config.pl, are you sure you are executing this script from your shared directory:\n$@\n\n" if $@;
}

# load oyster libraries
use oyster 'script';
use exceptions 'nolog';
use module;
use database;

my @update_modules;

#
# get Oyster's revision and established a temporary DB connection to use until Oyster is loaded
#

#my $oyster_rev;
#unless (exists $oyster::config::args{'is_installed'}) {
    my $dbconfig = $config->{'database'};
    my $DB = database::connect(
        'driver'   => $dbconfig->{'driver'},
        'host'     => $dbconfig->{'host'},
        'user'     => $dbconfig->{'user'},
        'password' => $dbconfig->{'pass'},
        'database' => $dbconfig->{'db'},
        'port'     => $dbconfig->{'port'},
    );
    $oyster::DB     = $DB;     # necessary for module::stuff
    *oyster::CONFIG = $config;
    my $oyster_rev = module::get_revision('oyster');
#}

#
# if no module id was specified, assume all modules should be updated
#

unless (exists $oyster::config::args{'module'}) {

    # if oyster has been installed, only update installed modules, otherwise, install all available modules
    my @update_modules = $oyster_rev ? module::get_enabled() : module::get_available() ;

    # order modules by dependencies
    my @update_modules = module::order_by_dependencies(@update_modules);

    # update 'em
    my $params;
    $params .= " -siteonly" if exists $oyster::config::args{'siteonly'};
    for my $module (@update_modules) {
        print `perl ./script/update.pl -module $module$params`;
    }

    # do no more
    exit;
}

#
# a specific module was specified
#

my $module = $oyster::config::args{'module'};

# if oyster is not installed/updated, ensure that it is being installed first
die "The 'oyster' module must be updated before this module can be updated or installed." if ($oyster_rev != module::get_latest_revision('oyster') and $module ne 'oyster');

# load the Oyster environment
$DB->disconnect(); # ensure the temporary database connection is replaced by oyster::load's
my %load_args = ('skip_outdated_modules' => 1);
unless ($oyster_rev) { # if oyster is not installed, load a minimal environment
    $load_args{'load_config'}  = 0;
    $load_args{'load_modules'} = 0;
    $load_args{'load_libs'}    = 0;
    $load_args{'load_request'} = 0;
}
eval { oyster::load($config, %load_args) };
die "Startup Failed: An error occured while loading Oyster: $@" if $@;

# check module dependencies
my $meta = module::get_meta($module);
for my $dependency_id (@{$meta->{'requires'}}) {
    die "The '$dependency_id' module must be updated before this module can be updated or installed." unless module::get_revision($dependency_id) == module::get_latest_revision($dependency_id);
}

# get current module revision
my $current_revision = module::get_revision($module);

# get the module's latest revision
my $latest_revision = module::get_latest_revision($module);

# module is up to date
if ($latest_revision == $current_revision) {
    print "'$module' is up to date (revision $current_revision).\n";
}

# something weird happened
elsif ($current_revision > $latest_revision) {
    print "Error: '$module' has a current revision ($current_revision) greater than the latest revision ($latest_revision)!\n";
}

# module needs to be updated
else {

    # import variables into the revisions script
    my $pkg = "${module}::revisions";
    *{"${pkg}::SITE_ID"}          = \$oyster::CONFIG{'site_id'};
    *{"${pkg}::DB_PREFIX"}        = \$oyster::CONFIG{'db_prefix'};
    ${"${pkg}::MODULE_PATH"}      = "./modules/$module/";
    ${"${pkg}::MODULE_DB_PREFIX"} = "$oyster::CONFIG{db_prefix}${module}_";
    ${"${pkg}::DB"}               = $oyster::DB;
    *{"${pkg}::CONFIG"}           = \%oyster::CONFIG;

    # load revisions file
    try {
        my $filename = "./modules/$module/revisions.pl";
        my $ret = do $filename;
        unless ($ret) {
            die "Couldn't parse revisions file '$filename': $@" if $@;
            die "Couldn't do revisions file '$filenamee': $!"   unless defined $ret;
            die "Couldn't run revisions file '$filename'."      unless $ret;
        }
    }
    catch 'perl_error', with {
        die shift();
    }
    catch 'db_error', with {
        my $error = shift;
        die "Database Error: $error\nQuery: $database::current_query\n";
    };

    # update the module
    print "Updating '$module' from revision $current_revision to revision $latest_revision...\n" unless exists $oyster::config::args{'siteonly'};
    for my $rev (@{"${module}::revisions::revision"}[ $current_revision + 1 .. $latest_revision ]) {
        $current_revision++;
        
        # perform the site update
        if (exists $oyster::config::args{'siteonly'}) {
            if (ref $rev->{'up'}->{'site'} eq 'CODE') {
                print "  Revision $current_revision site '$oyster::CONFIG{site_id}' update...\n";
                try {
                    $rev->{'up'}->{'site'}->();
                }
                catch 'perl_error', with {
                    die shift();
                }
                catch 'db_error', with {
                    my $error = shift;
                    die "Database Error: $error\nQuery: $database::current_query\n";
                };
            }
        }

        # perform the shared update
        else {
            if (ref $rev->{'up'}->{'shared'} eq 'CODE') {
                print "  Revision $current_revision shared update...\n";
                try {
                    $rev->{'up'}->{'shared'}->();
                }
                catch 'perl_error', with {
                    die shift();
                }
                catch 'db_error', with {
                    my $error = shift;
                    die "Database Error: $error\nQuery: $database::current_query\n";
                };
            }
        }
    }

    # if the shared update was performed
    unless (exists $oyster::config::args{'siteonly'}) {

        # perform the site update
        print `perl ./script/update.pl -module $module -site $oyster::CONFIG{site_id} -siteonly`;

        # update the module revision
        module::set_revision($module, $latest_revision);

        print "  Done.\n";
    }
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2008
