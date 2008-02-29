package orm::object::set;

sub new {
    return bless {
        'class' => shift,
        'model' => shift,
        'query' => shift,
    };
}

sub num {
    return shift()->{'query'}->rows();
}

sub next {
    my $set = shift;
    my $row = $set->{'query'}->fetchrow_hashref();
    return unless $row;
    return $set->{'class'}->new_from_db($row);
}

sub all {
    my $set = shift;
    my @objects;
    while (my $row = $set->{'query'}->fetchrow_hashref()) {
        push @objects, $set->{'class'}->new_from_db($row);
    }
    return @objects;
}

1;