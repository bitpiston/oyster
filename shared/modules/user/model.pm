package user;

use orm 'model';

our $model = {
    'table'  => 'users',
    'fields' => {
        'name' => {
            'type'   => 'orm::field::type::sql::varchar',
            'length' => 30,
        },
        'name_hash' => {
            'type'  => 'orm::field::type::hash_fast',
            'field' => 'name',
        },
        'password' => {
            'type'   => 'orm::field::type::sql::varchar',
            'length' => 64,
        },
        'email' => {
            'type'   => 'orm::field::type::sql::varchar',
            'length' => 255,
        },
        'session' => {
            'type'   => 'orm::field::type::sql::varchar',
            'length' => 32,
        },
        'ip' => {
            'type'   => 'orm::field::type::sql::varchar',
            'length' => 255,
        },
        'time_offset' => {
            'type'     => 'orm::field::type::sql::int',
            'length'   => 4,
            'unsigned' => 0,
            'default'  => 0,
        },
        'date_format' => {
            'type'   => 'orm::field::type::sql::varchar',
            'length' => 255,
        },
        'restrict_ip' => {
            'type'   => 'orm::field::type::sql::bool',
        },
        'style' => {
            'type'   => 'orm::field::type::sql::varchar',
            'length' => 255,
        },
    },
};

1;