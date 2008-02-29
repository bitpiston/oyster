package orm::field::type::url;

use base 'orm::field::type';

sub get_save_value {
    my $obj = shift;
    return $obj->{'value'} = url::unique($obj->{'value'});
}

1;