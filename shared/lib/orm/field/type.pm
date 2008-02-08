package orm::field::type;

use Scalar::Util;

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

    # set default value, if any
    $obj->value($model_field->{'default'}) if exists $model_field->{'default'};

    # return the object
    return $obj;
}

sub value {
    my $obj         = shift;
    $obj->{'value'} = shift if @_;
    return $obj->{'value'};
}

sub get_save_value {
    return $_[0]->value();
}

1;