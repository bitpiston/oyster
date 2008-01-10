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
use oyster 'launcher';
use exceptions;

# if no module id was specified, assume they want to update all modules
unless (exists $oyster::config::args{'module'}) {
    my $params;
    $params .= " -siteonly" if exists $oyster::config::args{'siteonly'};

    my @update_modules = get_module_update_order();
    for my $module (@update_modules) {
        print `perl ./script/update.pl -module $module$params`;
    }

    exit;
};

# if the user is trying to install/update the oyster module
if ($oyster::config::args{'module'} eq 'oyster') {

    # load a minimal version of the oyster environment
    eval { oyster::load($config, 'load_config' => 0, 'load_modules' => 0, 'load_libs' => 0, 'load_request' => 0) };
    die "Startup Failed: An error occured while loading Oyster:\n$@\n\n" if $@;

    # install/update oyster
    update_module('oyster');
}

# if the user is trying to install/update anything but the oyster module
else {

    # ensure that oyster has been installed
    my $dbconfig = $config->{'database'};
    my $DB = DBI->connect(
        "dbi:$dbconfig->{driver}:dbname=$dbconfig->{db};host=$dbconfig->{host};user=$dbconfig->{user};password=$dbconfig->{pass};port=$dbconfig->{port}", undef, undef,
        {
            'AutoCommit'  => 1,
            'RaiseError'  => 0,
            'HandleError' => sub {
                throw 'db_error' => $DBI::errstr;
            }
        }
    ) or die "Couldn't connect to database: $DBI::errstr";
    my $oyster_revision;
    try {
        $oyster_revision = $DB->query('SELECT revision FROM modules WHERE id = ? LIMIT 1', 'oyster')->fetchrow_arrayref()->[0];
    } catch 'db_error', with {
        $oyster_revision = 0;
        abort(1);
    };
    $DB->disconnect();
    die "The 'oyster' module must be installed before this module can be updated or installed." unless $oyster_revision;

    # load oyster
    eval { oyster::load($config) };
    die "Startup Failed: An error occured while loading Oyster:\n$@\n\n" if $@;

    # ensure oyster is up to date
    die "The 'oyster' module must be updated before this module can be updated or installed." unless get_current_revision('oyster') == load_revisions('oyster');

    # check module dependencies
    my $meta = module::get_meta($oyster::config::args{'module'});
    if ($meta and $meta->{'requires'}) {
        for my $dependency_id (@{$meta->{'requires'}}) {
            die "The '$dependency_id' module must be updated before this module can be updated or installed." unless get_current_revision($dependency_id) == load_revisions($dependency_id);
        }
    }

    # update the selected module
    update_module($oyster::config::args{'module'});
}

sub get_current_revision {
    my $module_id = shift;

    my $rev;
    my $success = try {
        my $query = $oyster::DB->query("SELECT revision FROM modules WHERE id = ? LIMIT 1", $module_id);
        abort(1) unless $query->rows();
        $rev = $query->fetchrow_arrayref()->[0];
    }
    catch 'db_error', with { # no module table exists or something
        abort(1);
    };
    return 0 unless $success;
    return $rev;
}

sub load_revisions {
    my $module_id = shift;

    # import variables into the revisions script
    my $pkg = "${module_id}::revisions";
    ${"${pkg}::SITE_ID"}          = $oyster::CONFIG{'site_id'};
    ${"${pkg}::DB_PREFIX"}        = $oyster::CONFIG{'db_prefix'};
    ${"${pkg}::MODULE_PATH"}      = "$oyster::CONFIG{shared_path}modules/$module_id/";
    ${"${pkg}::MODULE_DB_PREFIX"} = "$oyster::CONFIG{db_prefix}${module_id}_";
    ${"${pkg}::DB"}               = $oyster::DB;

    # load revisions
    try {
        require "./modules/$module_id/revisions.pl";
    }
    catch 'perl_error', with {
        die shift();
    }
    catch 'db_error', with {
        my $error = shift;
        die "Database Error: $error\nQuery: $database::current_query\n";
    };

    return $#{"${pkg}::revision"};
}

sub update_module {
    my $module_id = shift;

    # get current module revision
    my $current_revision = get_current_revision($module_id);

    # load revisions file
    my $latest_revision = load_revisions($module_id);

    # module is up to date
    if ($latest_revision == $current_revision) {
        print "'$module_id' is up to date (revision $current_revision).\n";
    }

    # something weird happened
    elsif ($current_revision > $latest_revision) {
        print "Error: '$module_id' has a current revision ($current_revision) greater than the latest revision ($latest_revision)!\n";
        exit;
    }

    # module needs to be updated
    else {
        print "Updating '$module_id' from revision $current_revision to revision $latest_revision...\n" unless exists $oyster::config::args{'siteonly'};
        for my $rev (@{"${module_id}::revisions::revision"}[ $current_revision + 1 .. $latest_revision ]) {
            $current_revision++;
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
            } else {
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
        print `perl ./script/update.pl -module $module_id -site $oyster::CONFIG{site_id} -siteonly` unless exists $oyster::config::args{'siteonly'};

        module::set_revision($module_id, $latest_revision);
        print "  Done.\n" unless exists $oyster::config::args{'siteonly'};
    }
}

sub get_module_update_order {

    # load module meta data
    my %module_meta;
    for my $file (<./modules/*/meta.pl>) { # find all modules with meta.pl files
        my ($module) = ($file =~ m!^.+/(.+?)/meta\.pl$!);  # extract the module name from the meta.pl file path
        $module_meta{$module} = module::get_meta($module); # get meta data
    }

    # order modules by dependencies
    my @update_modules;
    my @modules = keys %module_meta;
    while (@modules) { # iterate through modules until all have been moved to the @update_modules array
        my $module  = shift @modules;
        my $matched = 1;
        push @{$module_meta{$module}->{'requires'}}, 'oyster' unless $module eq 'oyster';
        for my $dep (@{$module_meta{$module}->{'requires'}}) { # iterate through module dependencies
            unless (grep(/^$dep$/, @update_modules)) { # if this module's dependencies have not already been added to the update stack, put it back in the @modules stack
                $matched = 0;
                push @modules, $module;
                last;
            }
        }
        push @update_modules, $module if $matched; # this module's dependencies are already in the update stack, go ahead and move it over to it
    }

    return @update_modules;
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2008