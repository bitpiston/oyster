package orm::field::type::sql::bool;

use base 'orm::field::type';

sub value {
    my $obj = shift;
    unless (@_ == 0) {
        my $value = shift;
        $obj->{'updated'} = undef;
        # should false/true be case-intensitive?
        $obj->{'value'} = ($value and $value ne 'false') ? '1' : '0' ;
    }
    return $obj->{'value'};
}

1;