package qdcontent;

# use oyster libraries
use oyster 'library';
use exceptions

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

url::register_once('url' => 'admin/dqcontent', 'module' => 'qdcontent', 'function' => 'admin');
sub admin {
    
}

url::register_once('url' => 'admin/dqcontent/create', 'module' => 'qdcontent', 'function' => 'create');
sub create {
    
}

url::register_once('url' => 'admin/dqcontent/edit', 'module' => 'qdcontent', 'function' => 'edit');
sub edit {
    
}

1;