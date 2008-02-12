package qdcontent;

# use oyster libraries
use oyster 'module';
use exceptions;

# use modules
use user;

# use ORM models
use url_model;

#my $url = url->new('url' => 'foo');
#use Data::Dumper;
#print Dumper($url);
#print Dumper($url->{'fields'}->{'url_hash'}->value());

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

url::register_once('url' => 'admin/qdcontent', 'function' => 'admin');
sub admin {
    user::require_permission('qdcontent_admin');

    # create admin center menu
    my $menu = 'qdcontent_admin';
    menu::label($menu, 'Quick and Dirty Content Administration');
    menu::description($menu, 'Some description...');

    # populate the admin menu
    menu::add_item('menu' => $menu, 'label' => 'Create a Page', 'url' => $module_admin_base_url . 'create/');

    menu::print_xml($menu);
}

url::register_once('url' => 'admin/qdcontent/create', 'function' => 'create');
sub create {
    user::require_permission('qdcontent_admin');
    style::include_template('create');

    module::print_start_xml();
    xml::print_var('url',     $INPUT{'url'});
    xml::print_var('title',   $INPUT{'title'});
    xml::print_var('content', $INPUT{'content'});
    module::print_end_xml();
}

url::register_once('url' => 'admin/qdcontent/edit', 'function' => 'edit');
sub edit {
    user::require_permission('qdcontent_admin');
}

#
# Contextual Admin Menu
#

# called when this module's admin menu is printed
event::register_hook('module_admin_menu', 'hook_module_admin_menu');
sub hook_module_admin_menu {
    return unless $PERMISSIONS{'qdcontent_admin'};
    my $item = menu::add_item('menu' => 'admin', 'label' => 'Static Content', 'url' => $module_admin_base_url);
    menu::add_item('parent' => $item, 'label' => 'Create a Page', 'url' => $module_admin_base_url . 'create/');
}

# called when the admin menu is printed (after the module admin menu)
event::register_hook('admin_menu', 'hook_admin_menu');
sub hook_admin_menu {
    return unless ($REQUEST{'module'} ne 'qdcontent' and $PERMISSIONS{'qdcontent_admin'});
    menu::add_item('parent' => $_[0], 'label' => 'Static Content', 'url' => $module_admin_base_url)
}

#
# Administration Center Menus
#

# modules menu
event::register_hook('admin_center_modules_menu', 'hook_admin_center_modules_menu');
sub hook_admin_center_modules_menu {
    menu::add_item('parent' => $_[0], 'label' => 'Static Content', 'url' => $module_admin_base_url) if $PERMISSIONS{'user_admin_config'};
}


1;