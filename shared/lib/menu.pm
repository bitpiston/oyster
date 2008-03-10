=xml
<document title="Menu">
    <synopsis>
        The menu API provides an easy way to create complex menus and print their corresponding XML easily.
    </synopsis>
    <todo>
        Add icons?
    </todo>
    <section title="Implementation Details">
        As a side effect of allowing both OO and procedural syntaxes, this actually uses inside-out objects for menus (although items are still self-contained, since they were a hash ref anyways).
    </section>
=cut
package menu::item;

sub add_item {
    goto &menu::add_item;
}

package menu;

my (%menus, %menu_labels, %menu_descriptions, %menu_urls, $default_menu);

=xml
    <function name="new">
        <synopsis>
            Allows OO-style access to the menu API.
        </synopsis>
        <prototype>
            obj = menu->new(string label[, string description])
        </prototype>
    </function>
=cut

sub new {
    my $class = shift;
    my $id    = string::random();
    menu::label($id, shift)       if @_;
    menu::description($id, shift) if @_;
    return bless \$id, $class;
}

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
        <prototype>
            obj->label(string menu_label)
        </prototype>
    </function>
=cut

sub label {
    my $menu  = scalar @_ == 2 ? shift : $default_menu ;
    $menu = ${$menu} if ref $menu; # allow OO syntax
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
            menu::description([string menu_id], string menu_description)
        </prototype>
        <prototype>
            obj->description(string menu_description)
        </prototype>
    </function>
=cut

sub description {
    my $menu  = scalar @_ == 2 ? shift : $default_menu ;
    $menu = ${$menu} if ref $menu; # allow OO syntax
    $menu_descriptions{$menu} = shift;
}

=xml
    <function name="url">
        <synopsis>
            Sets the corresponding url for a menu ID.
        </synopsis>
        <note>
            If no menu ID is specified, the default menu ID is used.
        </note>
        <prototype>
            menu::url([string menu_id], string menu_url)
        </prototype>
        <prototype>
            obj->description(string menu_url)
        </prototype>
    </function>
=cut

sub url {
    my $menu  = scalar @_ == 2 ? shift : $default_menu ;
    $menu = ${$menu} if ref $menu; # allow OO syntax
    $menu_urls{$menu} = shift;
}

=xml
    <function name="set_default_menu">
        <synopsis>
            Sets the default menu ID to be assumed if none is specified.
        </synopsis>
        <todo>
            Should this return the old default menu ID?
        </todo>
        <todo>
            This should probably either be removed or hard coded to navigation;  or at least have a warning that changing it is probably a bad idea.
        </todo>
        <prototype>
            menu::set_default_menu(string menu_id)
        </prototype>
        <prototype>
            obj->set_default_menu()
        </prototype>
    </function>
=cut

sub set_default_menu {
    #my $old_default_menu = $default_menu;
    my $menu = shift;
    $menu = ${$menu} if ref $menu; # allow OO syntax
    $default_menu = $menu;
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
        <note>
            If OO syntax is used, an object is returned instead of a normal hash reference.  add_item() can be called on that object to add sub items.
        </note>
        <prototype>
            hashref item = menu::add_item([menu => string menu_id OR parent => hashref item][, require_children => bool], label => string label, url => string url)
        </prototype>
        <prototype>
            obj = obj->add_item([, require_children => bool], label => string label, url => string url)
        </prototype>
    </function>
=cut

sub add_item {
    my %args;

    # allow OO syntax
    my ($is_oo);
    if (ref $_[0]) {
        $is_oo = 1;
        my $obj  = shift;
        my $type = ref $obj;
        if ($type eq 'menu') { # menu
            %args = ('menu' => ${$obj}, @_);
        } else {                 # item
            %args = ('parent' => $obj, @_);
        }
    }

    # procedural syntax
    else {
        %args = @_;
    }

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

    return $is_oo == 1 ? bless $item_list->[ $i - 1 ], 'menu' : $item_list->[ $i - 1 ] ;
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
        <prototype>
            bool was_anything_printed = obj->print_xml()
        </prototype>
    </function>
=cut

sub print_xml {
    my $menu = scalar @_ == 1 ? shift : $default_menu ;
    $menu = ${$menu} if ref $menu; # allow OO syntax

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
        $attrs .= qq~ url="$menu_urls{$menu}"~ if exists $menu_urls{$menu};
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
    delete $menu_urls{$menu};
}

sub delete_menus {
    %menus       = ();
    %menu_labels = ();
    %menu_urls   = ();
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2008