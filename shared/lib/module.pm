=xml
<document title="Module Management Functions">
    <synopsis>
        Functions associated with module management
    </synopsis>
=cut

package module;

use exceptions;

our %loaded; # currently loaded modules

=xml
    <function name="print_start_xml">
        <synopsis>
            A convenience function to print "\t&lt;module_id&gt;\n"
        </synopsis>
        <note>
            If the optional 'module_id' argument is not defined, the calling package will be assumed.
        </note>
        <note>
            If the optional 'action_id' argument is not defined, the calling sub routine will be assumed.
        </note>
        <note>
            If only one optional argument is present, it is assumed to be the module name
        </note>
        <prototype>
            module::print_start_xml([string module_id][, string action_id]);
        </prototype>
    </function>
    <function name="print_end_xml">
        <synopsis>
            A convenience function to print "\t&lt;/module_id&gt;\n"
        </synopsis>
        <note>
            This uses the module name of the last call to module::print_start_xml()
        </note>
        <prototype>
            module::print_end_xml();
        </prototype>
    </function>
=cut

{
my $module;
sub print_start_xml {
    my $action;
    if (@_ == 1) {
        $module = shift;
        $action = (caller(1))[3];
        substr($action, 0, rindex($action, ':') + 1, '');
    } elsif (@_ == 2) {
        $module = shift;
        $action = shift;
    } else {
        $module = (caller(0))[0];
        $action = (caller(1))[3];
        substr($action, 0, rindex($action, ':') + 1, '');
    }
    print qq~\t<$module action="$action">\n~;
}

sub print_end_xml {
    print "\t</$module>\n";
    undef $module;
}
}

=xml
    <function name="get_available">
        <synopsis>
            Retreives a list of all available modules.
        </synopsis>
        <prototype>
            array = module::get_available()
        </prototype>
    </function>
=cut

sub get_available {
    my @modules;
    for my $file (<./modules/*/meta.pl>) { # find all modules with meta.pl files
        my ($module) = ($file =~ m!^.+/(.+?)/meta\.pl$!); # extract the module name from the meta.pl file path
        push @modules, $module;
    }
    return @modules;
}

=xml
    <function name="get_enabled">
        <synopsis>
            Retreives a list of enabled modules
        </synopsis>
        <prototype>
            array = module::get_enabled()
        </prototype>
    </function>
=cut

sub get_enabled {
    return @{$oyster::DB->selectcol_arrayref("SELECT id FROM modules WHERE site_$oyster::CONFIG{site_id} = '1'")};
}

=xml
    <function name="order_by_dependencies">
        <synopsis>
            Given a list of modules, orders them based on their dependencies
        </synopsis>
        <note>
            This is susceptible to infinte looping if modules have circular dependencies
        </note>
        <prototype>
            array = module::order_by_dependencies(array)
        </prototype>
    </function>
=cut

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
        push @ordered_modules, $module if $matched == 1; # this module's dependencies were satisfied, go ahead and move it over to @ordered_modules
    }

    return @ordered_modules;
}

=xml
    <function name="get_latest_revision">
        <synopsis>
            Retreives the latest revision available for a module
        </synopsis>
        <note>
            returns 0 if no revisions.pl file is available
        </note>
        <note>
            throws a 'perl_error' exception on failure
        </note>
        <prototype>
            int = module::get_latest_revision(string module_id)
        </prototype>
    </function>
=cut

sub get_latest_revision {
    my $module_id = shift;
    my $filename  = "./modules/$module_id/revisions.pl";
    #throw 'perl_error' => "Revision file does not exist '$filename'." unless -e $filename;
    return 0 unless -e $filename;
    my $ret = do $filename;
    unless ($ret) {
        throw 'perl_error' => "Couldn't parse revision file '$filename': $@" if $@;
        throw 'perl_error' => "Couldn't do revision file '$filenamee': $!"   unless defined $ret;
        throw 'perl_error' => "Couldn't run revision file '$filename'."      unless $ret;
    }
    my $latest_rev = $#{ $module_id . '::revisions::revision' };
    undef @{ $module_id . '::revisions::revision' };
    return $latest_rev;
}

=xml
    <function name="enable">
        <synopsis>
            Enables a module
        </synopsis>
        <note>
            This does not load the module
        </note>
        <note>
            This does nothing if passed a non-existant module ID.
        </note>
        <prototype>
            module::enable(string module_id)
        </prototype>
    </function>
=cut

sub enable {
    $oyster::DB->do("UPDATE modules SET site_$oyster::CONFIG{site_id} = '1' WHERE id = '$_[0]'");
}

=xml
    <function name="disable">
        <synopsis>
            Disables a module
        </synopsis>
        <note>
            This does not unload the module if it is currently loaded.
        </note>
        <note>
            This does nothing if passed a non-existant module ID.
        </note>
        <prototype>
            module::disable(string module_id)
        </prototype>
    </function>
=cut

sub disable {
    $oyster::DB->do("UPDATE modules SET site_$oyster::CONFIG{site_id} = '0' WHERE id = '$_[0]'");
}

=xml
    <function name="is_enabled">
        <synopsis>
            Checks if a given module is enabled
        </synopsis>
        <prototype>
            bool = module::is_enabled(string module_id)
        </prototype>
    </function>
=cut

sub is_enabled {
    return $oyster::DB->selectcol_arrayref("SELECT COUNT(*) FROM modules WHERE site_$oyster::CONFIG{site_id} = '1' and id = '$_[0]' LIMIT 1")->[0];
}

=xml
    <function name="is_registered">
        <synopsis>
            Checks if a given module is registered
        </synopsis>
        <prototype>
            bool = module::is_registered(string module_id)
        </prototype>
    </function>
=cut

sub is_registered {
    return $oyster::DB->selectcol_arrayref("SELECT COUNT(*) FROM modules WHERE id = '$_[0]' LIMIT 1")->[0];
}

=xml
    <function name="register">
        <synopsis>
            Adds an entry to the modules table
        </synopsis>
        <prototype>
            module::register(string module_id[, revision])
        </prototype>
        <note>
            This does nothing and returns undef if the given module ID is already registered.
        </note>
        <todo>
            error if module is already installed? (or just update revision?)
        </todo>
    </function>
=cut

sub register {
    my ($module_id, $revision) = @_;
    return if $oyster::DB->selectcol_arrayref("SELECT COUNT(*) FROM modules WHERE id = '$module_id' LIMIT 1")->[0] == 1;
    $revision = 0 unless defined $revision;
    $oyster::DB->do("INSERT INTO modules (id, revision) VALUES ('$module_id', $revision)");
}

=xml
    <function name="unregister">
        <synopsis>
            Removes a module's entry in the modules table
        </synopsis>
        <note>
            This does nothing if passed a non-existant module ID.
        </note>
        <prototype>
            module::unregister(string module_id)
        </prototype>
    </function>
=cut

sub unregister {
    $oyster::DB->do("DELETE FROM modules WHERE id = '$_[0]'");
}

=xml
    <function name="set_revision">
        <synopsis>
            Sets a module's current revision
        </synopsis>
        <note>
            Does nothing if the module is not registered
        </note>
        <prototype>
            module::set_revision(string module_id, int revision)
        </prototype>
    </function>
=cut

sub set_revision {
    $oyster::DB->do("UPDATE modules SET revision = $_[1] WHERE id = '$_[0]'");
}

=xml
    <function name="get_revision">
        <synopsis>
            Gets a module's revision number
        </synopsis>
        <note>
            Returns 0 if a module is not registered
        </note>
        <prototype>
            int revision = module::get_revision(string module_name)
        </prototype>
        <todo>
            Should probably throw a perl error or something if a module is not registered
        </todo>
    </function>
=cut

sub get_revision {
    return $oyster::DB->selectcol_arrayref("SELECT revision FROM modules WHERE id = '$_[0]' LIMIT 1")->[0];
    #my $module_id = shift;
    #my $rev       = 0;
    #try {
    #    my $query = $oyster::DB->query("SELECT revision FROM modules WHERE id = ? LIMIT 1", $module_id);
    #    abort(1) unless $query->rows() == 1;
    #    $rev = $query->fetchrow_arrayref()->[0];
    #}
    #catch 'db_error', with {
    #    abort(1);
    #};
    #return $rev;
}

=xml
    <function name="get_meta">
        <synopsis>
            Fetches meta information about a module
        </synopsis>
        <note>
            throws a 'perl_error' exception on failure
        </note>
        <prototype>
            hashref = module::get_meta(string module_name)
        </prototype>
    </function>
=cut

sub get_meta {
    my $module_id = shift;
    my $filename = "./modules/${module_id}/meta.pl";
    throw 'perl_error' => "Metafile does not exist for module '$module_id'." unless -e $filename;
    my $meta = do $filename;
    unless ($meta) {
        throw 'perl_error' => "Couldn't parse metadata file '$filename': $@" if $@;
        throw 'perl_error' => "Couldn't do metadata file '$filename': $!"    unless defined $meta;
        throw 'perl_error' => "Couldn't run metadata file '$filename'."      unless $meta;
    }
    return $meta;
}

=xml
    <function name="load">
        <synopsis>
            Loads a module
        </synopsis>
        <note>
            If the module is already loaded, it is unloaded first.
        </note>
        <note>
            dies on failure
        </note>
        <prototype>
            module::load(string module_id);
        </prototype>
    </function>
=cut

sub load {
    my $module_id = shift;

    return if $module_id eq 'oyster'; # do nothing if you are trying to load the oyster module

    # if the module is currently loaded, unload it
    module::unload($module_id) if exists $loaded{$module_id};

    # load module configuration
    module::load_config($module_id);

    # load module's perl source
    my $filename = "./modules/${module_id}.pm";
    my $ret      = do $filename; # do instead of require since if unload is called, require wouldn't re-include it!
    unless ($ret) {
        die "Couldn't parse module file '$filename': $@" if $@;
        die "Couldn't do module file '$filenamee': $!"   unless defined $ret;
        die "Couldn't run module file '$filename'."      unless $ret;
    }

    # add to oyster loaded module hash
    $loaded{$module_id} = undef;
}

=xml
    <function name="load_config">
        <todo>
            Document this function
        </todo>
    </function>
=cut

sub load_config {
    my $module_id = shift;

    # clear current config
    %{"${module_id}::config"} = ();

    # load module configuration
    config::load('table' => "$oyster::CONFIG{db_prefix}${module_id}_config", 'config_hash' => \%{"${module_id}::config"});
    config::load('table' => "${module_id}_config", 'config_hash' => \%{"${module_id}::config"});
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
