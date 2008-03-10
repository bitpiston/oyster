package qdcontent;

# use oyster libraries
use oyster 'module';
use exceptions;

# use modules
use user;

user::add_permission_once('qdcontent_admin');

sub view_page {
    my $filename = shift;

    # if an xsl file exists for this url, use it
    if (-e $module_path . $filename . '-page.xsl') {

        # include the template and print a hook for the xsl
        style::include_template($filename . '-page');
        print qq~\t<qdcontent />\n~;

        # contextual admin menu
        if ($PERMISSIONS{'qdcontent_admin'}) {
            my $item = menu::add_item('menu' => 'admin', 'label' => 'This Page', 'url' => $REQUEST{'url'});
            menu::add_item('parent' => $item, 'label' => 'Edit',   'url' => $module_admin_base_url . 'edit/?page=' . $filename);
            menu::add_item('parent' => $item, 'label' => 'Delete', 'url' => $module_admin_base_url . 'delete/?page=' . $filename);
        }
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

    # if the form was submitted, validate and save the page
    my $success = try {

        # validate url
        $INPUT{'url'} =~ s!^/!!; # trim leading/trailing slashes
        $INPUT{'url'} =~ s!/$!!;
        throw 'validation_error' => 'A url is required.' unless length $INPUT{'url'};
        my $filename = $INPUT{'url'};
        $filename =~ s!/!-!g;

        # validate title
        throw 'validation_error' => 'A title is required.' unless length $INPUT{'title'};

        # everything validated, save it
        file::write($module_path . $filename . '-page.xsl', $INPUT{'template'});

        # register the url to view it
        my ($url_id, $url) = url::register(
            'url'           => $INPUT{'url'},
            'title'         => xml::entities($INPUT{'title'}),
            'show_nav_link' => $INPUT{'show_nav_link'},
            'module'        => 'qdcontent',
            'function'      => 'view_page',
            'params'        => $filename
        );

        # print a confirmation
        confirmation('A new page was successfully created.',
            'View the Page'       => $BASE_URL . $url . '/',
            'Create Another Page' => $module_admin_base_url . 'create/',
        );
    } if $ENV{'REQUEST_METHOD'} eq 'POST';

    # print the create page form
    unless ($success) {
        module::print_start_xml();
        xml::print_var('url',           $INPUT{'url'});
        xml::print_var('show_nav_link', $INPUT{'show_nav_link'});
        xml::print_var('title',         $INPUT{'title'});
        xml::print_var('template',      $INPUT{'template'});
        module::print_end_xml();
    }
}

url::register_once('url' => 'admin/qdcontent/edit', 'function' => 'edit');
sub edit {
    user::require_permission('qdcontent_admin');

}

url::register_once('url' => 'admin/qdcontent/delete', 'function' => 'delete');
sub delete {
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