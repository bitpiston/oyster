package orm::object;

use exceptions;

sub new {
    my $class  = shift;
    my $model  = ${ $class . '::model' };
    my $obj    = bless {'model' => $model}, $class . '::object';

    # create field objects
    my %values = @_;
    my $model_fields = $model->{'fields'};
    my $obj_fields;
    for my $field_id (keys %{$model_fields}) {
        my $model_field = $model_fields->{$field_id};

        # if a value was specified
        if (exists $values{$field_id}) {
            $obj_fields->{$field_id} = $model_field->{'type'}->new($obj, $field_id, $model_field, $values{$field_id});
        }

        # if the field has a default value
        elsif (exists $model_field->{'default'}) {
            $obj_fields->{$field_id} = $model_field->{'type'}->new($obj, $field_id, $model_field);
        }
    }

    # return the new orm object
    $obj->{'fields'} = $obj_fields;
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

    # return the new orm object
    $obj->{'fields'} = $obj_fields;
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
    my $obj          = shift;
    my $obj_fields   = $obj->{'fields'};
    my $model        = $obj->{'model'};
    my $model_fields = $model->{'fields'};

    # if the object has an ID, update it
    if (exists $obj->{'id'}) {

        # figure out fields values to update
        my %update;
        for my $field_id (keys %{$obj_fields}) {
            my $model_field = $model_fields->{$field_id};
            my $obj_field;

            # if the field has an object
            if (exists $obj_fields->{$field_id}) {
                $obj_field = $obj_fields->{$field_id};
                next unless $obj_field->was_updated();
            }

            # if the field does not have an object, and was updated, create an object for it
            else {
                next unless $model_field->{'type'}->was_updated($obj, $field_id);
                $obj_field = $obj_fields->{$field_id} = $model_field->{'type'}->new($obj, $field_id, $model_field);
            }

            $update{$field_id} = $obj_field->get_save_value();
        }

        # update the object
        return if keys %update == 0;
        my $fields = join(' = ?, ', keys %update) . ' = ?';
        $oyster::DB->query("UPDATE $obj->{model}->{table} SET $fields WHERE id = ?", values %update, $obj->{'id'});

        # relationships
    }

    # if the object has no ID, insert it
    else {

        # figure out the field values to insert
        my %insert;
        for my $field_id (keys %{$obj_fields}) {
            my $obj_field = $obj_fields->{$field_id};
            next unless $obj_field->was_updated();
            $insert{$field_id} = $obj_field->get_save_value();
        }
        my $query;

        # if there are fields to be inserted
        if (keys %insert != 0) {
            my $fields       = join(', ', keys %insert);
            my $placeholders = join(', ', map '?', values %insert);
            $query           = $oyster::DB->query("INSERT INTO $obj->{model}->{table} $fields VALUES $placeholders", values %insert);
        }

        # if there are no fields to insert, we still need to perform an insert to get an ID
        else {
            $query = $oyster::DB->query("INSERT INTO $obj->{model}->{table}");
        }

        # save the new object ID
        $obj->{'id'} = $query->insert_id($obj->{'model'}->{'table'} . '_id');

        # relationships
    }

    # return the object ID
    return $obj->{'id'};
}

sub delete {
    my $obj = $_[0];

    # if the object has been saved, remove it from the database
    $oyster::DB->do("DELETE FROM $obj->{model}->{table} WHERE id = $obj->{id}") if exists $obj->{'id'};

    # destroy the object
    undef $_[0]; # gogo @_ aliases
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
            my $value = $oyster::DB->selectcol_arrayref("SELECT $method FROM $obj->{model}->{table} WHERE id = $obj->{id}")->[0];
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