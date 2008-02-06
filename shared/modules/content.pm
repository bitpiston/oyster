package content;

sub view_page {

}

package content::page;

use base 'orm::model';

our $meta = {
    'table'  => 'site_content_pages',
    'fields' => {
        'title'   => {
            'type' => 'orm::field::type::text',
            'size' => 'full',
        },
        'content' => {
            'type' => 'orm::field::type::textarea::transformed',
            'size' => 'full',
        },
        'ctime' => {
            'type' => 'orm::field::type::datetime::creationtime',
        },
        'mtime' => {
            'type' => 'orm::field::type::datetime::modifiedtime',
        },
        'url' => {
            'type'  => 'orm::field::type::url',
        },
    },
    'relationships' => {
        'has_one' => {
            'url' => {
                # map of url fields to this ones
                'url'           => {'this'  => 'url'},
                'title'         => {'this'  => 'title'},
                'args'          => {'this'  => 'id'},
                'show_nav_link' => {'this'  => 'url', 'method' => 'show_nav_link'}, # run ->show_nav_link() on this url field to get the value
                'module'        => {'value' => 'content'},
                'function'      => {'value' => 'view_page'},
                #'meta'          => {'method' => 'some_model_method'},
            },
        },
    },
};

#content::page->setup();

1;