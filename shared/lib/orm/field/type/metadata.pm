package orm::field::type::metadata;

use base 'orm::field::type';

sub value {
    my $obj         = shift;
    $obj->{'value'} = \@_ if @_;
    return @{$obj->{'value'}};
}

sub get_save_value {
    return database::compress_metadata($_[0]->{'value'});
}

1;