package orm::model;

use exceptions;

sub new {
    my $class = shift;
    my $model = ${ $class . '::model' };
    my $obj   = bless {'model' => $model}, $class;

    # create fields
    my $model_fields = $model->{'fields'};
    for my $field_id (keys %{$model_fields}) {
        my $model_field = $model_fields->{$field_id};
        $obj->{'fields'}->{$field_id} = $model_field->{'type'}->new($obj, $field_id, $model_field);
    }

    # set field values if any were specified
    if (@_) {
        my %values     = @_;
        my $obj_fields = $obj->{'fields'};
        for my $field_id (keys %values) {
            $obj_fields->{$field_id}->value($values{$field_id});
        }
    }

    # return the new orm object
    return $obj;
}

sub get {
    my $where;
    my @where_values;
    my @columns;
    my $offset = 0;

    # parse arguments
    while (@_) {
        my $arg = shift;

        # where clauses
        if ($arg eq 'where') {
            #my $arg = shift;
            #$where = shift @{$arg};
            #@where_values = @{$arg};
            @where_values = @{ shift() };
            $where        = shift @where_values;
        }

        # offset
        elsif ($arg eq 'offset') {
            $offset = shift;
        }

        # the argument is a column name
        else {
            push @columns, $arg;
        }
    }

    # prepare and execute the query
    my $columns = @columns ? join(', ', @columns) : '*' ;
    $oyster::DB->query("SELECT $columns FROM");
}

sub save {
    my $obj = shift;

    my %fields;
    my $obj_fields = $obj->{'fields'};
    for my $field_id (keys %{$obj_fields}) {
        $fields{$field_id} = $obj_fields->{$field_id}->get_save_value();
    }

    # if the object has an ID, just update it
    if (exists $obj->{'id'}) {
        #
    }

    # if the object has no ID, insert it
    else {
        #
    }
}

sub delete {
    my $obj = shift;

    # if the object has been saved, remove it from the database
    $oyster::DB->query("DELETE FROM $obj->{model}->{table} WHERE id = ?", $obj->{'id'}) if exists $obj->{'id'};

    # destroy the object
    undef %{$obj};
}

sub AUTOLOAD {
    my $obj      = shift;
    my ($method) = ($AUTOLOAD =~ /::(.+?)$/o);

    # field objects
    return $obj->{'fields'}->{$method} if exists $obj->{'fields'}->{$method};

    # dynamic select
    
    # dynamic update

    # nothing matched...
    throw 'perl_error' => "Invalid dynamic method '$method' called on ORM object '" . ref($obj) . "'.";
}

sub DESTROY {

}

1;