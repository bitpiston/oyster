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
user->import();

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
                The main configuration menu
            </synopsis>
        </function>
=cut

sub config {
    user::require_permission('admin_config');

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