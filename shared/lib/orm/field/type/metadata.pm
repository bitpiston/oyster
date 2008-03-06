package orm::field::type::metadata;

use base 'orm::field::type';

sub value {
    my $obj = shift;
    unless (@_ == 0) {
        $obj->{'updated'} = undef;
        $obj->{'value'}   = \@_;
    }
    return @{$obj->{'value'}};
}

sub get_save_value {
    my $obj      = shift; # this object
    my $values   = shift; # the values to insert/update (hashref)
    my $field_id = shift; # the id of this field (convenience; same as $obj->{'field_id'})
    my $fields   = shift; # an arrayref of fields that save() is iterating over to get values
    $values->{$field_id} = database::compress_metadata($obj->{'value'});
}

1;