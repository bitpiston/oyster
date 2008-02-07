package orm::field::type;

sub new {
    my $class       = shift;
    my %args        = @_;
    my $obj         = bless {}, $class;

    # set default value, if any
    $obj->value($args{'default'}) if exists $args{'default'};

    # return the object
    return $obj;
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