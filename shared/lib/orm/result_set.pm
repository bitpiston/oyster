package orm::result_set;

sub new {
    my $class = shift;
    return bless {
        'class' => $class,
        'model' => shift,
        'query' => shift,
    }, $class;
}

sub num {
    return shift()->{'query'}->rows();
}

sub next {
    #
}

1;