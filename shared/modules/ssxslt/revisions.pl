package ssxslt::revisions;

# ----------------------------------------------------------------------------
# Revision 1
# ----------------------------------------------------------------------------

$revision[1]{'up'}{'shared'} = sub {

    # Register the module
    module::register('ssxslt');
};

$revision[1]{'up'}{'site'} = sub {

    # Enable the module
    module::enable('ssxslt');
};

# ----------------------------------------------------------------------------
# Revision 2
# ----------------------------------------------------------------------------

$revision[2]{'up'}{'site'} = sub {

    # Add permissions
    #user::add_permission('ssxslt_admin');
    #user::add_permission('ssxslt_admin_config');
};

1;
