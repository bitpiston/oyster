package url;

use base 'orm::model';

our $model = {
    'table'  => 'site_urls',
    'fields' => {
        'parent_id'   => {
            'type'     => 'orm::field::type::sql::int',
            'length'   => 32, # bits
            'unsigned' => 1,
            'default'  => 0,
        },
        'url' => {
            'type' => 'orm::field::type::url',
        },
        'url_hash' => {
            'type'  => 'orm::field::type::hash_fast',
            'field' => 'url',
        },
        'title' => {
            'type'   => 'orm::field::type::sql::varchar',
            'length' => 255,
        },
        'module' => {
            'type'   => 'orm::field::type::sql::varchar',
            'length' => 255,
            # need to figure out how to add validator methods here to ensure the module is valid
        },
        'function' => {
            'type'   => 'orm::field::type::sql::varchar',
            'length' => 255,
            # need to figure out how to add validator methods here to ensure the module has that function
        },
        'args' => {
            'type' => 'orm::field::type::metadata',
        },
        'show_nav_link' => {
            'type' => 'orm::field::type::sql::bool',
        },
        'nav_priority' => {
            'type'     => 'orm::field::type::sql::int',
            'length'   => 8, # bits
            'unsigned' => 1,
        },
        'show_nav_link' => {
            'type' => 'orm::field::type::sql::bool',
        },
    },
    'relationships' => {
        'has_many' => {
            'url' => {
                # map of url fields to this ones
                'parent_id' => {'this'  => 'id'},
            },
        },
    },
};

1;