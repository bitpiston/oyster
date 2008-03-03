package orm::object;

use exceptions;

sub new {
    my $class  = shift;
    my $model  = ${ $class . '::model' };
    my $obj    = bless {'model' => $model}, $class . '::object';

    # create fields from any values passed
    unless (@_ == 0) {
        my $model_fields = $model->{'fields'};
        my $obj_fields;
        my $i = 0;
        while (exists $_[$i]) {
            my ($field_id, $value) = ($_[$i++], $_[$i++]);
            next unless my $model_field = $model_fields->{$field_id};
            $obj_fields->{$field_id} = $model_field->{'type'}->new($obj, $field_id, $model_field, $value);
        }
        $obj->{'fields'} = $obj_fields;
    }

    # return the new orm object
    return $obj;
}

sub new_from_db {
    my $class  = shift;
    my $values = shift()->fetchrow_hashref();
    my $model  = ${ $class . '::model' };
    my $obj    = bless {'id' => delete $values->{'id'}, 'model' => $model}, $class . '::object';

    # create fields from any values retreived
    my $model_fields = $model->{'fields'};
    my $obj_fields;
    for my $field_id (keys %{$values}) {
        next unless my $model_field = $model_fields->{$field_id};
        $obj_fields->{$field_id} = $model_field->{'type'}->new($obj, $field_id, $model_field, $values->{$field_id}, 'from_db');
    }
    $obj->{'fields'} = $obj_fields;

    # return the new orm object
    return $obj;
}

sub fetch_fields {
    my $obj = shift;

    # do nothing if this object has not been saved
    return unless exists $obj->{'id'};

    # assume all fields if none were specified
    push @_, '*' if @_ == 0;

    # use interpolation instead of join
    local $" = ', ';

    # fetch fields
    my @values = $oyster::DB->query("SELECT @_ FROM $obj->{model}->{table} WHERE id = ?", $obj->{'id'})->fetchrow_array();

    # put field values into the object's fields
    my $obj_fields = $obj->{'fields'};
    my $i = 0;
    for my $field_id (@_) {
        $obj_fields->{$field_id}->value_from_db($values[ $i++ ]);
    }
}

sub save {
    my $obj = shift;

    my %fields;
    my $obj_fields = $obj->{'fields'};
    for my $field_id (keys %{$obj_fields}) {
        $fields{$field_id} = $obj_fields->{$field_id}->get_save_value();
    }

    # if the object has an ID, update it
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
    $oyster::DB->do("DELETE FROM $obj->{model}->{table} WHERE id = $obj->{id}") if exists $obj->{'id'};

    # destroy the object
    undef %{$obj};
}

sub id { $_[0]->{'id'} }

sub AUTOLOAD {
    my $obj      = shift;
    my ($method) = ($AUTOLOAD =~ /([^:]+)$/o);

    # existing field objects
    return $obj->{'fields'}->{$method} if exists $obj->{'fields'}->{$method};

    # unfetched/created field objects
    my $model        = $obj->{'model'};
    my $model_fields = $model->{'fields'};
    if (exists $model_fields->{$method}) {
        my $model_field = $model_fields->{$method};

        # if this is a database-based object
        if (exists $obj->{'id'}) {
            my $value = $oyster::DB->query("SELECT $method FROM $obj->{model}->{table} WHERE id = ?", $obj->{'id'})->fetchrow_arrayref()->[0];
            return $obj->{'fields'}->{$method} = $model_field->{'type'}->new($obj, $method, $model_field, $value, 'from_db');
        }

        # if this is a new object
        return $obj->{'fields'}->{$method} = $model_field->{'type'}->new($obj, $method, $model_field);
    }

    # nothing matched...
    throw 'perl_error' => "Invalid dynamic method '$method' called on ORM object '" . ref($obj) . "'.";
}

sub DESTROY {

}

1;