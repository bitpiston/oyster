package orm::field::type::sql::bool;

use base 'orm::field::type';

sub value {
    my $obj         = shift;
    $obj->{'value'} = shift ? '1' : '0' if @_;
    return $obj->{'value'};
}

1;