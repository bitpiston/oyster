package orm::field::type;

use Scalar::Util;

# creates a new object of a particular type
sub new {
    my $class       = shift;
    my $orm_obj     = shift;
    my $field_id    = shift;
    my $model_field = shift;
    my $obj         = bless {
        'field_id' => $field_id,
        'orm_obj'  => $orm_obj,
    }, $class;
    Scalar::Util::weaken($obj->{'orm_obj'});

    # if a value was specified
    if (@_ == 1) {
        $obj->value($_[0]);
    }
    
    # if this is being populated from the database
    elsif (@_ == 2) {

        # if this field's value was fetched
        if (length $_[1] == 0) {
            $obj->value_from_db($_[0]);
        }

        # this field was not fetched
        else {
            $obj->{'not_fetched'} = undef;
        }
    }

    # if a default value exists
    elsif (exists $model_field->{'default'}) {
        $obj->value($model_field->{'default'});
    }

    # return the object
    return $obj;
}

# sets/gets the object's value
sub value {
    my $obj = shift;
    unless (@_ == 0) {
        $obj->{'updated'} = undef;
        $obj->{'value'}   = shift;
    }
    return $obj->{'value'};
}

# used to set the value when an object is created from a database entry
sub value_from_db {
    my $obj = shift;
    $obj->{'value'} = shift;
}

# used to perform any processing necessary to get the value to insert into the database
sub get_save_value {
    return $_[0]->value();
}

# returns true if the field needs to be updated/inserted
sub was_updated {
    return exists $_[0]->{'updated'};
}

# returns true if the column represents the actual value stored in the database (if any -- returns true for unsaved objects)
sub was_fetched {
    return !exists $obj->{'not_fetched'};
}

1;