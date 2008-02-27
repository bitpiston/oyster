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
    return $set->{'class'}->new_from_db($set->{'query'});
}

1;