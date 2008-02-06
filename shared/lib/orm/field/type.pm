package orm::field::type;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub value {
    my $obj         = shift;
    $obj->{'value'} = shift if @_;
    return $obj->{'value'};
}

sub get_save_value {
    return $_[0]->{'value'};
}

1;