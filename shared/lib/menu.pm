package menu;

my %menus;
my %menu_labels;
my %menu_descriptions;
my $default_menu;

sub label {
    my $menu  = scalar @_ == 2 ? shift : $default_menu ;
    $menu_labels{$menu} = shift;
}

sub description {
    my $menu  = scalar @_ == 2 ? shift : $default_menu ;
    $menu_descriptions{$menu} = shift;
}

sub set_default_menu {
    #my $old_default_menu = $default_menu;
    $default_menu = shift;
    #return $old_default_menu;
}

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

=comment
sub print_xml {
    my $menu = scalar @_ == 1 ? shift : $default_menu ;

    # do nothing if the menu contained no items
    return unless scalar @{ $menus{$menu} };

    my $menu_printed;

    # iterate through menu items
    for my $item (@{ $menus{$menu} }) {

        # skip items that require children but have none
        unless ($item->{'require_children'} and scalar @{ $item->{'items'} } == 0) {

            # print the menu header if it hasn't been printed yet
            unless ($menu_printed) {
                my $label = exists $menu_labels{$menu}       ? qq~ label="$menu_labels{$menu}"~ : '' ;
                my $desc  = exists $menu_descriptions{$menu} ? qq~ description="$menu_descriptions{$menu}"~ : '' ;
                my $id    = exists $menu_labels{$menu}       ? '' : qq~ id="$menu"~ ;
                print qq~\t<menu$id$label$desc>\n~;
                $menu_printed = 1;
            }

            # print this item's xml
            _print_item_xml($item, 1);
        }
    }
    print "\t</menu>\n" if $menu_printed;

    delete_menu($menu);

    return $menu_printed;
}

sub _print_item_xml {
    my $item   = shift;
    my $depth  = shift;
    my $indent = "\t" . ("\t" x $depth);

    my $attrs;
    $attrs .= qq~ id="$item->{id}"~       if exists $item->{'id'};
    $attrs .= qq~ label="$item->{label}"~ if exists $item->{'label'};
    $attrs .= qq~ url="$item->{url}"~     if exists $item->{'url'};

    # if the item has no sub-items
    if (exists $item->{'items'}) {
        print qq~$indent<item$attrs>\n~;
        for my $item (@{ $item->{'items'} }) {
            _print_item_xml($item, $depth + 1);
        }
        print "$indent</item>\n";
    }

    # if the item has sub-items
    else {
        print qq~$indent<item$attrs />\n~;
    }
}
=cut

sub print_xml {
    my $menu = scalar @_ == 1 ? shift : $default_menu ;

    # do nothing if the menu contained no items
    return unless scalar @{ $menus{$menu} };

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

1;