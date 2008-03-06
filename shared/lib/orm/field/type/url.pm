package orm::field::type::url;

use base 'orm::field::type';

sub get_save_value {
    my $obj      = shift; # this object
    my $values   = shift; # the values to insert/update (hashref)
    my $field_id = shift; # the id of this field (convenience; same as $obj->{'field_id'})
    my $fields   = shift; # an arrayref of fields that save() is iterating over to get values

    # uniquify the url
    my $url = url::unique($obj->{'value'});;

    # determine the parent id
    my $parent_id;
    my $last_slash_pos = rindex($url, '/');

    # the url contains no /'s
    if ($last_slash_pos == -1) {
        $parent_id = 0;
    }

    # the url contains /'s
    else {
        my $parent_url = substr($url, 0, $last_slash_pos);
        my $query      = $oyster::DB->query("SELECT id FROM $oyster::CONFIG{db_prefix}urls WHERE url_hash = ? LIMIT 1", hash::fast($parent_url));
        $parent_id     = $query->rows() == 1 ? $query->fetchrow_arrayref()->[0] : -1 ; # -1 = not top level but no parent id
    }

    # set the parent id field
    # TODO: this is specific to the url model!
    # this WORKS but sets the parent id too late! object.pm has already inserted its value into %insert/update
    $obj->{'orm_obj'}->parent_id->value($parent_id);
    push @{$fields}, 'parent_id';

    # return the uniqified url
    $values->{$field_id} = $url;
}

1;