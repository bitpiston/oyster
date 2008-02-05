package admin::revisions;

# ----------------------------------------------------------------------------
# Revision 1
# ----------------------------------------------------------------------------

$revision[1]{'up'}{'shared'} = sub {

    # Register the module
    module::register('admin');
};

$revision[1]{'up'}{'site'} = sub {

    # Enable the module
    module::enable('admin');
};

# ----------------------------------------------------------------------------
# Revision 2
# ----------------------------------------------------------------------------

$revision[2]{'up'}{'shared'} = sub {

    # Add permissions
    user::add_permission('admin_config');
    user::add_permission('admin_modules');
    user::add_permission('admin_styles');
    user::add_permission('admin_logs');
};

$revision[2]{'up'}{'site'} = sub {

    # Register URLs
    url::register('url' => 'admin',                   'module' => 'admin', 'function' => 'menu',               'title' => 'Administration Center');
    url::register('url' => 'admin/modules',           'module' => 'admin', 'function' => 'modules',            'title' => 'Manage Modules');
    url::register('url' => 'admin/config',            'module' => 'admin', 'function' => 'config',             'title' => 'Configuration');
    url::register('url' => 'admin/config/navigation', 'module' => 'admin', 'function' => 'config_navigation',  'title' => 'Configure Navigation');
    url::register('url' => 'admin/logs',              'module' => 'admin', 'function' => 'logs',               'title' => 'Logs');
    url::register('url' => 'admin/styles',            'module' => 'admin', 'function' => 'styles',             'title' => 'Manage Styles');
};

1;
