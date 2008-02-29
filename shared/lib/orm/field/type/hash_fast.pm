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
    my $obj = shift;
    return $obj->{'orm_obj'}->{'fields'}->{ $obj->{'hash_field'} }->was_updated();
}

1;