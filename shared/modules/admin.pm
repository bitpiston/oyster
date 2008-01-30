=xml
<document title="Administration Center">
    <synopsis>
        Provides a central place to manage core administrative functions, as well
        as an API for modules to use to integrate with the administration center.
    </synopsis>
=cut
package admin;

# import oyster libraries
use oyster 'module';
use exceptions;

# import modules
use user;

=xml
    <section title="Actions">

        <function name="menu">
            <synopsis>
                The main administration center menu
            </synopsis>
            <section title="Events">
                <dl>
                    <dt>admin_center_config_menu</dt>
                    <dd>
                        Called to add sub-items to the configuration menu item; passes one argument,
                        the configuration menu item handle to be used as a parent to add menu items to.
                    </dd>
                    <dt>admin_center_modules_menu</dt>
                    <dd>
                        Called to add sub-items to the modules menu item; passes on argument, the
                        modules menu item handle to be used as a parent to add menu items to.
                    </dd>
                </dl>
            </section>
        </function>
=cut

sub menu {

    # create admin center menu
    my $menu = 'admin_center';
    menu::label($menu, 'Administration Center');
    menu::description($menu, 'Some description...');

    # configuration
    my $config_item;
    if ($PERMISSIONS{'admin_config'}) {
        $config_item = menu::add_item('menu' => $menu, 'label' => 'Configuration', 'url' => "${ADMIN_BASE_URL}config/");
        menu::add_item('parent' => $config_item, 'label' => 'Navigation', 'url' => "${ADMIN_BASE_URL}config/navigation/");
    } else {
        $config_item = menu::add_item('menu' => $menu, 'label' => 'Configuration', 'require_children' => 1);
    }
    event::execute('admin_center_config_menu', $config_item);

    # modules
    my $module_item;
    if ($PERMISSIONS{'admin_modules'}) {
        $modules_item = menu::add_item('menu' => $menu, 'label' => 'Modules', 'url' => "${ADMIN_BASE_URL}modules/");
    } else {
        $modules_item = menu::add_item('menu' => $menu, 'label' => 'Modules', 'require_children' => 1);
    }
    event::execute('admin_center_modules_menu', $modules_item);

    # styles
    menu::add_item('menu' => $menu, 'label' => 'Styles', 'url' => "${ADMIN_BASE_URL}styles/") if $PERMISSIONS{'admin_styles'};

    # logs
    menu::add_item('menu' => $menu, 'label' => 'Logs',   'url' => "${ADMIN_BASE_URL}logs/")   if $PERMISSIONS{'admin_logs'};

    # print the admin center menu
    throw 'permission_error' unless menu::print_xml($menu);
}

=xml
        <function name="config">
            <synopsis>
                General site/global configuration options
            </synopsis>
        </function>
=cut

sub config {
    user::require_permission('admin_config');

    my @fields = qw(default_url time_offset default_style site_name error_message navigation_depth);
    my $input_source;

    # the form has been submitted
    if (%INPUT) {
        $input_source = \%INPUT;
        try {

            # validate user input
            throw 'validation_error' => 'A site name is required.'  unless $INPUT{'site_name'};
            $INPUT{'site_name'} = xml::entities($INPUT{'site_name'});
            throw 'validation_error' => 'Invalid default url.'      unless url::is_registered($INPUT{'default_url'});
            throw 'validation_error' => 'Invalid default style.'    unless style::is_valid_style($INPUT{'default_style'});
            throw 'validation_error' => 'Invalid navigation depth.' unless ($INPUT{'navigation_depth'} =~ /^\d+$/ and $INPUT{'navigation_depth'} > 0);
            throw 'validation_error' => 'Invalid time offset.'      unless datetime::is_valid_time_offset($INPUT{'time_offset'});
            $INPUT{'error_message'} = xml::validate_xhtml($INPUT{'error_message'});

            # everything validated, update settings
            my $query_update_site_config = $DBH->prepare("UPDATE ${DB_PREFIX}config SET value = ? WHERE name = ?");
            for my $field (@fields) { $query_update_site_config->execute($INPUT{$field}, $field) }

            # print a confirmation message
            confirmation('Settings have been saved.');

            # reload configuration in all daemons
            ipc::eval('oyster::_load_config()');
        };
    } else {
        $input_source = \%CONFIG;
    }

    # print the edit config form
    my $fields;
    for my $field (@fields) { $fields .= " $field=\"" . xml::entities($input_source->{$field}) . "\"" }
    style::include_template('config');
    print "\t<admin action=\"config\"$fields>\n";
    module::print_modules_xml();
    style::print_enabled_styles_xml();
    print "\t</admin>\n";
}

=xml
        <function name="modules">
            <synopsis>
                Allows you to manage installed modules
            </synopsis>
        </function>
=cut

sub modules {
    user::require_permission('admin_modules');
    style::include_template('modules');

    my %modules;

    # assemble module data
    for my $module (<./modules/*/>) {
        my ($module_id) = ($module =~ m!^\./modules/(.+?)/$!);
        $modules{$module_id}->{'latest_rev'} = module::get_latest_revision($module_id);
        $modules{$module_id}->{'rev'}        = module::get_revision($module_id);
        $modules{$module_id}->{'meta'}       = module::get_meta($module_id);
    }

    my @ordered_modules = module::order_by_dependencies(keys %modules);

    print qq~\t<admin action="modules">\n~;
    for my $module_id (@ordered_modules) {
        my $module   = $modules{$module_id};
        my $meta     = $module->{'meta'};
        my $requires = $meta->{'requires'};

        my $attrs = qq~ id="$module_id"~;
        $attrs .= qq~ rev="$module->{rev}"~;
        $attrs .= qq~ latest_rev="$module->{latest_rev}"~;
        $attrs .= qq~ version="$meta->{version}"~;
        $attrs .= ' name="' . xml::entities($meta->{'name'}) . '"';
        $attrs .= ' description="' . xml::entities($meta->{'description'}) . '"' if length $meta->{'description'};
        $attrs .= ' required="1"' if $meta->{'required'};
        $attrs .= ' loaded="1"'   if exists $module::loaded{$module_id};
        $attrs .= ' enabled="1"'  if module::is_enabled($module_id);
        if ($meta->{'requires'}) {
            print "\t\t<module$attrs>\n";
            for my $dep (@{ $meta->{'requires'} }) {
                print qq~\t\t\t<requires id="$dep" />\n~;
            }
            print "\t\t</module>\n";
        } else {
            print "\t\t<module$attrs />\n";
        }
    }
    print "\t</admin>\n";
}

=xml
        <function name="logs">
            <synopsis>
                Allows you to view the error and status logs
            </synopsis>
        </function>
=cut

sub logs {
    user::require_permission('admin_logs');

    # contextual admin menu
    my $item = menu::add_item('menu' => 'admin', 'label' => 'Logs', 'url' => "${ADMIN_BASE_URL}logs/");
    menu::add_item('parent' => $item, 'label' => 'Error',  'url' => "${ADMIN_BASE_URL}logs/?view=error");
    menu::add_item('parent' => $item, 'label' => 'Status', 'url' => "${ADMIN_BASE_URL}logs/?view=status");

    # clear a log
    if ($INPUT{'clear'} eq 'error' or $INPUT{'clear'} eq 'status') {
        confirm("Are you sure you want to clear the $INPUT{clear} log?");
        $DB->do("DELETE FROM ${DB_PREFIX}logs WHERE type = '$INPUT{clear}'");
        confirmation("The $INPUT{clear} log has been cleared.");
    }

    # view a log
    elsif ($INPUT{'view'} eq 'error' or $INPUT{'view'} eq 'status') {

        # include logs.xsl
        style::include_template('logs');
        
        # fetch log entries
        my $offset = (exists $INPUT{'offset'} and $INPUT{'offset'} =~ /^[0-9]+$/) ? $INPUT{'offset'} : 0;
        my $query = $DB->query("SELECT id, time, message, trace FROM ${DB_PREFIX}logs WHERE type = '$INPUT{view}' ORDER BY time DESC LIMIT 25 OFFSET $offset");

        # list log entries
        my $attrs;
        $attrs .= ' next_offset="' . ($offset + 25) . '"' if $query->rows() == 25;
        $attrs .= ' prev_offset="' . ($offset - 25) . '"' if $offset >= 25;
        print qq~\t<admin action="logs" log="$INPUT{view}"$attrs>\n~;
        while (my $entry = $query->fetchrow_hashref()) {
            print qq~\t\t<entry id="$entry->{id}" time="$entry->{time}">\n~;
            chomp($entry->{'message'});
            print "\t\t\t<message>" . xml::entities($entry->{'message'}) . "</message>\n";
            print "\t\t\t<trace>" . xml::entities($entry->{'trace'}) . "</trace>\n" if length $entry->{'trace'};
            print "\t\t</entry>\n";
        }
        print "\t</admin>\n";
    }

    # display a menu of logs
    else {
        my $menu = 'admin_logs';
        menu::label($menu, 'Logs');
        menu::description($menu, 'Logs can contain useful information about your site including simple status messages or fatal errors.');
        menu::add_item('menu' => $menu, 'label' => 'Error',  'url' => "${ADMIN_BASE_URL}logs/?view=error");
        menu::add_item('menu' => $menu, 'label' => 'Status', 'url' => "${ADMIN_BASE_URL}logs/?view=status");
        menu::print_xml($menu);
    }
}

=xml
        <function name="styles">
            <synopsis>
                Allows you to manage installed styles
            </synopsis>
        </function>
=cut

sub styles {
    user::require_permission('admin_styles');

}

=xml
    </section>

    <section title="Event Hooks">
=cut

# called after the module controller/action
event::register_hook('request_end', 'hook_request_end', 100);
sub hook_request_end {

    # call the current module's admin menu hook
    event::execute_by_module('module_admin_menu', $REQUEST{'module'});

    # call the general admin menu
    my $item = menu::add_item('menu' => 'admin', 'id' => 'other', 'require_children' => 1);
    event::execute('admin_menu', $item);

    # print the admin menu
    menu::print_xml('admin');
}

# called when this module's admin menu is printed
event::register_hook('module_admin_menu', 'hook_module_admin_menu');
sub hook_module_admin_menu {
    my $item = menu::add_item('menu' => 'admin', 'label' => 'Admin', 'url' => $ADMIN_BASE_URL, 'require_children' => 1);
    menu::add_item('parent' => $item, 'label' => 'Configuration',    'url' => "${ADMIN_BASE_URL}config/")  if $PERMISSIONS{'admin_config'};
    menu::add_item('parent' => $item, 'label' => 'Modules',          'url' => "${ADMIN_BASE_URL}modules/") if $PERMISSIONS{'admin_modules'};
    menu::add_item('parent' => $item, 'label' => 'Styles',           'url' => "${ADMIN_BASE_URL}styles/")  if $PERMISSIONS{'admin_styles'};
    menu::add_item('parent' => $item, 'label' => 'Logs',             'url' => "${ADMIN_BASE_URL}logs/")    if $PERMISSIONS{'admin_logs'};
}

# called when the admin menu is printed (after the module admin menu)
event::register_hook('admin_menu', 'hook_admin_menu');
sub hook_admin_menu {
    menu::add_item('parent' => $_[0], 'label' => 'Admin', 'url' => $ADMIN_BASE_URL)
        if ($REQUEST{'module'} ne 'admin' and
            ($PERMISSIONS{'admin_config'} or $PERMISSIONS{'admin_modules'} or $PERMISSIONS{'admin_styles'} or $PERMISSIONS{'admin_logs'}));
}

=xml
    </section>

    <section title="Helper Functions">
=cut

=xml
    </section>

    <section title="Public API">
=cut

=xml
    </section>
</document>
=cut

1;

# Copyright BitPiston 2008