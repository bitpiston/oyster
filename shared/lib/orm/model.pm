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

sub new_from_db {
    my $class  = shift;
    my $rowobj = shift;
}

# this should never be called directly, only via the auto-generated imported get()'s
sub get {
    my ($class, $limit, $offset, $where, @where_values, @columns) = (shift(), ' LIMIT 1');
    my $model = ${ $class . '::model' };

    # parse arguments
    while (@_) {
        my $arg = shift;

        # where clauses
        if ($arg eq 'where') {
            @where_values = @{ shift() };
            $where        = ' WHERE ' . shift @where_values;
        }

        # offset
        elsif ($arg eq 'offset') {
            $offset = ' OFFSET ' . shift();
        }

        # limit
        elsif ($arg eq 'limit') {
            my $num = shift;
            $limit = $num == 0 ? '' : " LIMIT $num" ;
        }

        # the argument is a column name
        else {
            push @columns, $arg;
        }
    }

    # prepare and execute the query
    my $columns = @columns == 0 ? '*' : join(', ', @columns) ;
    my $query   = $oyster::DB->query("SELECT $columns FROM $model->{table}$where$limit$offset");

    # if limit was not 1 (a result set is expected)
    if ($limit ne ' LIMIT 1') {
        return orm::result_set::new($class, $model, $query);
    }

    # a single row object should be returned
    else {
        return $class->new_from_db($query);
    }
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

sub import {
    my $pkg = $_[0] ne 'orm::model' ? $_[0] : caller() ;
    return if $pkg eq 'orm'; # don't import into orm.pm -- it's just pulling in all of the orm stuff

    eval qq~
        sub ${pkg}::get {
            unshift \@_, '$pkg';
            goto &orm::model::get;
        }
        sub ${pkg}::get_all {
            unshift \@_, '$pkg', 'limit', 0;
            goto &orm::model::get;
        }
    ~;
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