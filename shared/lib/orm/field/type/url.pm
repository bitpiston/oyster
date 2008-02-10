package orm::field::type::url;

use base 'orm::field::type';

sub value {
    my $obj         = shift;
    $obj->{'value'} = shift if @_;
    return $obj->{'value'};
}

sub get_save_value {
    my $obj   = shift;
    my $value = $obj->value();
    my $url   = url::unique($value);
    $obj->{'value'} = $url;
    return $url;
}

1;