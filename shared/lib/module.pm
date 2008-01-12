=xml
<document title="Module Management Functions">
    <synopsis>
        Functions associated with module management
    </synopsis>
=cut

package module;

use exceptions;

our %loaded; # currently loaded modules

sub is_enabled {
    my $module_id = shift;
    #my $query = $oyster::DB->query("SELECT COUNT(*) FROM modules WHERE site_$oyster::CONFIG{site_id} = '1' WHERE id = ?", $module_id);
    #return $query->rows() == 0 ? '1' : '0' ;
    return $oyster::DB->query("SELECT COUNT(*) FROM modules WHERE site_$oyster::CONFIG{site_id} = '1' and id = ?", $module_id)->fetchrow_arrayref()->[0];

}

# note: this is susceptible to infinte looping if modules have circular dependencies
sub order_by_dependencies {
    my @modules = @_;

    # load module require metadata
    my %module_requires;
    for my $module (@modules) {
        $module_requires{$module} = module::get_meta($module)->{'requires'};
        push @{ $module_requires{$module} }, 'oyster' unless $module eq 'oyster';
    }

    # iterate through modules until all have been moved to @ordered_modules
    my @ordered_modules;
    while (@modules) {
        my $module  = shift @modules;
        my $matched = 1;
        for my $dep (@{ $module_requires{$module} }) { # iterate through module dependencies
            unless (grep(/^$dep$/, @ordered_modules)) { # if this module's dependencies have not already been added to the update stack, put it back in the @modules stack
                $matched = 0;
                push @modules, $module;
                last;
            }
        }
        push @ordered_modules, $module if $matched; # this module's dependencies were satisfied, go ahead and move it over to @ordered_modules
    }

    return @ordered_modules;
}

sub get_latest_revision {
    my $module_id = shift;
    my $rev_file  = "./modules/$module_id/revisions.pl";
    throw 'perl_error' => "File does not exist '$rev_file'" unless -e $rev_file;
    ${ $module_id . '::revisions::just_getting_revs' } = 1;
    require $rev_file;
    my $latest_rev = $#{ $module_id . '::revisions::revision' };
    undef @{ $module_id . '::revisions::revision' };
    return $latest_rev;
}

=xml
    <function name="enable">
        <synopsis>
            Enables and loads a module
        </synopsis>
        <note>
            This does nothing if the module is already enabled and loaded.
        </note>
        <prototype>
            module::enable(string module_id)
        </prototype>
        <todo>
            Validate that module exists before attempting this!
        </todo>
    </function>
=cut

sub enable {
    my $module_id = shift;
    return if exists $loaded{$module_name};
    $oyster::DB->query("UPDATE modules SET site_$oyster::CONFIG{site_id} = '1' WHERE id = ?", $module_id);
    #load($module_id); # removed because this could cause revision files to load the module before it is finished installing/updating, maybe make it an arg?
}

=xml
    <function name="disable">
        <synopsis>
            Disables and unloads a module
        </synopsis>
        <note>
            This does nothing if the module is not enabled.
        </note>
        <prototype>
            module::disable(string module_id)
        </prototype>
        <todo>
            Validate that module exists before attempting this!
        </todo>
    </function>
=cut

sub disable {
    my $module_id = shift;
    return unless exists $loaded{$module_id};
    $oyster::DB->query("UPDATE modules SET site_$oyster::CONFIG{site_id} = '0' WHERE id = ?", $module_id);
    unload($module_id);
}

=xml
    <function name="set_revision">
        <synopsis>
            Sets a module's current revision
        </synopsis>
        <prototype>
            module::set_revision(string module_id, int revision)
        </prototype>
        <todo>
            Validate that module exists before attempting this!
        </todo>
    </function>
=cut

sub set_revision {
    my ($module_id, $revision) = @_;
    $oyster::DB->query("UPDATE modules SET revision = ? WHERE id = ?", $revision, $module_id);
}

=xml
    <function name="get_revision">
        <synopsis>
            Gets a module's revision number
        </synopsis>
        <prototype>
            int revision = module::get_revision(string module_name)
        </prototype>
        <todo>
            Validate that module exists before attempting this!
        </todo>
    </function>
=cut

sub get_revision {
    my $module_id = shift;
    my $query = $oyster::DB->query("SELECT revision FROM modules WHERE id = ? LIMIT 1", $module_id);
    return $query->rows() == 1 ? $query->fetchrow_arrayref()->[0] : 0 ;
}

=xml
    <function name="register">
        <synopsis>
            Adds an entry to the modules table
        </synopsis>
        <prototype>
            module::register(string module_id[, revision])
        </prototype>
        <todo>
            error if module is already installed? (or just update revision?)
        </todo>
    </function>
=cut

sub register {
    my ($module_id, $revision) = @_;
    return if $oyster::DB->query('SELECT COUNT(*) FROM modules WHERE id = ? LIMIT 1', $module_id)->fetchrow_arrayref()->[0];
    $revision = 0 unless defined $revision;
    $oyster::DB->query('INSERT INTO modules (id, revision) VALUES (?, ?)', $module_id, $revision);
}

=xml
    <function name="unregister">
        <synopsis>
            Removes a module's entry in the modules table
        </synopsis>
        <prototype>
            module::unregister(string module_id)
        </prototype>
        <todo>
            rename?
        </todo>
    </function>
=cut

sub unregister {
    my $module_id = shift;
    $oyster::DB->query("DELETE FROM modules WHERE id = ?", $module_id);
}

=xml
    <function name="get_meta">
        <synopsis>
            Fetches meta information about a module
        </synopsis>
        <note>
            Returns undef if no meta information is available, although that should
            never happen.
        </note>
        <prototype>
            hashref = module::get_meta(string module_name)
        </prototype>
        <todo>
           try {} ?
        </todo>
    </function>
=cut

sub get_meta {
    my $module_name = shift;
    my $filename = "$oyster::CONFIG{shared_path}modules/${module_name}/meta.pl";
    return unless -e $filename;
    return do $filename;
}

=xml
    <function name="get_permissions">
        <synopsis>
            Fetches permissions information about a module
        </synopsis>
        <note>
            Returns undef if no permission information is available
        </note>
        <prototype>
            hashref = module::get_permissions(string module_id)
        </prototype>
    </function>
=cut

sub get_permissions {
    my $module_id = shift;
    my $filename = "$oyster::CONFIG{shared_path}modules/${module_id}/permissions.pl";
    return unless -e $filename;
    return do $filename;
}

=xml
    <function name="load">
        <synopsis>
            Loads a module
        </synopsis>
        <note>
            If the module is already loaded, it is unloaded first.
        </note>
        <prototype>
            module::load(string module_id);
        </prototype>
    </function>
=cut

sub load {
    my $module_id = shift;

    # if the module is currently loaded, unload it
    module::unload($module_id) if exists $loaded{$module_id};

    # load module configuration
    config::load('table' => "${oyster::DB_PREFIX}${module_id}_config", 'config_hash' => \%{"${module_id}::CONFIG"});

    # load module's perl source
    eval { require "$oyster::CONFIG{shared_path}modules/${module_id}/${module_id}.pm" };
    die("Error loading $module_id: $@") if $@;

    # add to oyster loaded module hash
    $loaded{$module_id} = undef;
}

=xml
    <function name="reload_config">
        <todo>
            Documentate this function
        </todo>
    </function>
=cut
sub reload_config {
    my $module_id = shift;

    # clear current config
    %{"${module_id}::CONFIG"} = ();

    # load module configuration
    config::load('table' => "${oyster::DB_PREFIX}${module_id}_config", 'config_hash' => \%{"${module_id}::config"});
}

=xml
    <function name="unload">
        <synopsis>
            Unloads a module
        </synopsis>
        <note>
            This is not gauranteed to work -- and when it does, it may break other things.
        </note>
        <prototype>
            module::unload(string module_id);
        </prototype>
    </function>
=cut

sub unload {
    my $module_id = shift;

    # delete all variables from the package's namespace
    for my $var (keys %{"${module_id}::"}) {
        undef *{"${module_id}::$var"};
    }

    # remove any hooks associated to this module
    event::delete_module_hooks($module_id);

    # delete the entry from oyster's loaded module list
    delete $loaded{$module_id};
}

=xml
    <function name="print_modules_xml">
        <synopsis>
            Print modules in an xml-friendly manner.
        </synopsis>
        <prototype>
            print_module_xml()
        </prototype>
        <todo>
            Should this be in SIMS?
        </todo>
    </function>
=cut

sub print_modules_xml {
    print "\t\t<modules>\n";
    for my $module_name (keys %loaded) {
        my $meta = get_meta($module_name);
        my $can_be_default = $meta->{'can_be_default'} ? ' can_be_default="1"' : '' ;
        print "\t\t\t<module id=\"$module_name\" name=\"$meta->{name}\"$can_be_default />\n";
    }
    print "\t\t</modules>\n";
}

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
