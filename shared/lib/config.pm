=xml
<document title="Configuration Functions">
    <synopsis>
        Functions for reading configuration options -- mostly used internally.
    </synopsis>
=cut

package config;

use exceptions;

=xml
    <function name="load">
        <synopsis>
            Loads configuration options from the database
        </synopsis>
        <note>
            Modules should rarely need to call this function, Oyster automatically
            takes care of loading module configuration data.
        </note>
        <note>
            If a table name and hashref are absent, they are automatically assumed
            from the caller.  If "foo" called "config::load()", the table would
            default to site_db_prefix_foo_config and the configuration data would be
            stored in %foo::config
        </note>
        <prototype>
            config::load([table => string config_table_name][, config_hash => hashref config_hash]);
        </prototype>
    </function>
=cut

sub load {
    my $pkg = caller();

    # parse options
    my %options = @_;
    $options{'config_hash'} = \%{"${pkg}::config"} unless exists $options{'config_hash'}; 
    unless (exists $options{'table'}) { # only modules should take advantage of table auto-detection!
        my $module = $pkg =~ /^(.+?)::/ ? $1 : $pkg ;
        throw 'perl_error' => "config::load called from $pkg without a table argument.  config::load() cannot determine which table to use." unless exists $module::loaded{$module};
        $options{'table'} = ${"${module}::module_db_prefix"} . 'config' ;
    }

    # append options from the database to the config hash
    try {

        # iterate through config options and add them to the config hash
        my $rows = $oyster::DB->query("SELECT name, value FROM $options{table}");
        while (my $row = $rows->fetchrow_hashref()) {
            $options{'config_hash'}->{$row->{'name'}} = $row->{'value'};
        }
    }
    catch 'db_error', with { # fail silently if the table does not exist
        abort(1);
    };
}

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
