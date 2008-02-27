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
    #
}

1;