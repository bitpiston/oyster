package orm::field::type::hash_fast;

use base 'orm::field::type';

use Scalar::Util;

sub new {
    my $class       = shift;
    my $orm_obj     = shift;
    my $field_id    = shift;
    my $model_field = shift;
    my $obj         = bless {
        'field_id'   => $field_id,
        'orm_obj'    => $orm_obj,
        'hash_field' => $model_field->{'field'},
    }, $class;
    Scalar::Util::weaken($obj->{'orm_obj'});

    # return the object
    return $obj;
}

sub value {
    my $obj = shift;
    hash::fast( $obj->{'orm_obj'}->{'fields'}->{ $obj->{'hash_field'} }->value() );
}

sub get_save_value {
    return $_[0]->value();
}

sub was_updated {

    # if this being called OO
    if (ref $_[0]) {
        my $obj = shift;
        return unless exists $obj->{'orm_obj'}->{'fields'}->{ $obj->{'hash_field'} };
        return $obj->{'orm_obj'}->{'fields'}->{ $obj->{'hash_field'} }->was_updated();
    }

    # if this being called without an object
    else {
        my $orm_obj        = shift;
        my $field_id       = shift;
        my $orm_obj_fields = $orm_obj->{'fields'};
        my $hash_field     = $orm_obj->{'model'}->{'fields'}->{$field_id}->{'field'};
        return unless exists $orm_obj_fields->{ $hash_field };
        return $orm_obj_fields->{ $hash_field }->was_updated();
    }
}

1;