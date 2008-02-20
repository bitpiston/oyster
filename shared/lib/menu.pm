=xml
<document title="Menu">
    <synopsis>
        The menu API provides an easy way to create complex menus and print their corresponding XML easily.
    </synopsis>
    <todo>
        Create an OO interface for menus and items.
    </todo>
    <todo>
        Add icons?
    </todo>
=cut
package menu;

my (%menus, %menu_labels, %menu_descriptions, $default_menu);

=xml
    <function name="label">
        <synopsis>
            Sets the corresponding proper label for a menu ID.
        </synopsis>
        <note>
            If no menu ID is specified, the default menu ID is used.
        </note>
        <prototype>
            menu::label([string menu_id], string menu_label)
        </prototype>
    </function>
=cut

sub label {
    my $menu  = scalar @_ == 2 ? shift : $default_menu ;
    $menu_labels{$menu} = shift;
}

=xml
    <function name="description">
        <synopsis>
            Sets the corresponding description for a menu ID.
        </synopsis>
        <note>
            If no menu ID is specified, the default menu ID is used.
        </note>
        <prototype>
            menu::description([string menu_id], string menu_label)
        </prototype>
    </function>
=cut

sub description {
    my $menu  = scalar @_ == 2 ? shift : $default_menu ;
    $menu_descriptions{$menu} = shift;
}

=xml
    <function name="set_default_menu">
        <synopsis>
            Sets the default menu ID to be assumed if none is specified.
        </synopsis>
        <todo>
            Should this return the old default menu ID?
        </todo>
        <prototype>
            menu::set_default_menu(string menu_id)
        </prototype>
    </function>
=cut

sub set_default_menu {
    #my $old_default_menu = $default_menu;
    $default_menu = shift;
    #return $old_default_menu;
}

=xml
    <function name="add_item">
        <synopsis>
            Adds an item to a menu
        </synopsis>
        <note>
            To add sub-items to an existing item, specify the 'parent' argument instead of 'menu'.
        </note>
        <note>
            If no menu ID or item is specified, the default menu ID is used.
        </note>
        <note>
            If the 'require_children' argument is true, this item will ONLY be printed if it contains sub-items.
        </note>
        <note>
            'label' and 'url' are assumed to be xml-safe, if they must be entified, you must call xml::entities() on them yourself
        </note>
        <prototype>
            hashref item = menu::add_item([menu => string menu_id OR parent => hashref item][, require_children => bool], label => string label, url => string url)
        </prototype>
    </function>
=cut

sub add_item {
    my %args = @_;

    my $item_list;
    if (exists $args{'parent'}) {
        $args{'parent'}->{'items'} = [] unless exists $args{'parent'}->{'items'};
        $item_list = $args{'parent'}->{'items'};
        delete $args{'parent'};
    } else {
        my $menu = exists $args{'menu'} ? delete $args{'menu'} : $default_menu ;
        $menus{$menu} = [] unless exists $menus{$menu};
        $item_list = $menus{$menu};
    }

    my $i = push @{$item_list}, \%args;

    return $item_list->[ $i - 1 ];
}

=xml
    <function name="print_xml">
        <synopsis>
            Prints a menu's XML
        </synopsis>
        <note>
            If no menu ID is specified, the default menu ID is used.
        </note>
        <note>
            If the menu contains no items, nothing will be printed.
        </note>
        <todo>
            Possibly allow overriding this behavior.
        </todo>
        <note>
            If the menu does not have a label -- set via menu::label -- the id is printed instead (as id="" instead of label="").
        </note>
        <note>
            Once finished, this deletes all data associated with the printed menu.
        </note>
        <prototype>
            bool was_anything_printed = menu::print_xml([string menu_id])
        </prototype>
    </function>
=cut

sub print_xml {
    my $menu = scalar @_ == 1 ? shift : $default_menu ;

    # do nothing if the menu contained no items
    return unless scalar @{ $menus{$menu} }; # should this delete the menu as well?

    my $xml;

    # iterate through menu items
    for my $item (@{ $menus{$menu} }) {
        $xml .= _get_item_xml($item, 1);
    }

    my $menu_printed = 0;
    if (length $xml) {
        my $attrs;
        $attrs .= exists $menu_labels{$menu} ? qq~ label="$menu_labels{$menu}"~ : qq~ id="$menu"~ ;
        $attrs .= qq~ description="$menu_descriptions{$menu}"~ if exists $menu_descriptions{$menu};
        print qq~\t<menu$attrs>\n$xml\t</menu>\n~;
        $menu_printed = 1;
    }

    delete_menu($menu);

    return $menu_printed;
}

sub _get_item_xml {
    my $item   = shift;
    my $depth  = shift;
    my $indent = "\t" . ("\t" x $depth);
    my $xml;

    my $attrs;
    $attrs .= qq~ id="$item->{id}"~       if exists $item->{'id'};
    $attrs .= qq~ label="$item->{label}"~ if exists $item->{'label'};
    $attrs .= qq~ url="$item->{url}"~     if exists $item->{'url'};

    # if the item has sub-items
    if (exists $item->{'items'}) {
        $xml .= qq~$indent<item$attrs>\n~;
        my $next_depth = $depth + 1;
        for my $item (@{ $item->{'items'} }) {
            $xml .= _get_item_xml($item, $next_depth);
        }
        $xml .= "$indent</item>\n";
    }

    # if the item has no sub-items
    else {
        return if $item->{'require_children'};
        $xml .= qq~$indent<item$attrs />\n~;
    }

    return $xml;
}

sub delete_menu {
    my $menu = scalar @_ == 1 ? shift : $default_menu ;
    delete $menus{$menu};
    delete $menu_labels{$menu};
}

sub delete_menus {
    %menus       = ();
    %menu_labels = ();
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2008