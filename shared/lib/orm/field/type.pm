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
        $obj->value_from_db($_[0]);
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
    $_[0]->{'value'} = $_[1];
}

# used to perform any processing necessary to get the value to insert into the database
sub get_save_value {
    my $obj      = shift; # this object
    my $values   = shift; # the values to insert/update (hashref)
    my $field_id = shift; # the id of this field (convenience; same as $obj->{'field_id'})
    my $fields   = shift; # an arrayref of fields that save() is iterating over to get values
    $values->{$field_id} = $obj->value();
}

# returns true if the field needs to be updated/inserted
sub was_updated {

    # if this being called OO
    if (ref $_[0]) {
        return exists $_[0]->{'updated'};
    }
    
    # if this being called without an object
    else {
        return;
    }
}

1;