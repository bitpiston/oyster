package orm::field::type::url;

use base 'orm::field::type';

sub value {
    my $obj         = shift;
    unless (@_ == 0) {
        $obj->{'updated'} = undef;
        $obj->{'value'}   = shift;
    }
    return $obj->{'value'};
}

sub get_save_value {
    return $obj->{'value'} = url::unique(shift()->value());
}

1;