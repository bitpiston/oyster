package qdcontent;

# use oyster libraries
use oyster 'library';
use exceptions;

# use modules
use user;

user::add_permission_once('qdcontent_admin');

sub view_page {
    my $url = shift;

    # if an xsl file exists for this url, use it!
    if (-e $module_path . $url . '.xsl') {
        style::include_template($url);
        print qq~\t<qdcontent />\n~;
    }

    # otherwise, throw a 404
    else {
        throw 'request_404';
    }
}

url::register_once('url' => 'admin/dqcontent', 'function' => 'admin');
sub admin {
    user::require_permission('qdcontent_admin');

    # create admin center menu
    my $menu = 'qdcontent_admin';
    menu::label($menu, 'Quick and Dirty Content Administration');
    menu::description($menu, 'Some description...');

    # populate the admin menu
    menu::add_item('menu' => $menu, 'label' => 'Create a Page', 'url' => $module_admin_base_url . 'create/');
}

url::register_once('url' => 'admin/dqcontent/create', 'function' => 'create');
sub create {
    user::require_permission('qdcontent_admin');
    
}

url::register_once('url' => 'admin/dqcontent/edit', 'function' => 'edit');
sub edit {
    user::require_permission('qdcontent_admin');
    
}

1;