=xml
<document title="URL Functions">
    <synopsis>
        Functions dealing with Oyster's url handling as well as external url
        utilities.
    </synopsis>
=cut

package url;

use exceptions;
use event;
use hash;

our (%regex_urls, $fetch_by_hash, $fetch_nav_urls_by_parent_id);
event::register_hook('load_lib', '_load');
sub _load {

    # prepare queries
    $fetch_by_hash               = $oyster::DB->server_prepare("SELECT * FROM $oyster::CONFIG{db_prefix}urls WHERE url_hash = ? and regex = 0 LIMIT 1");
    $fetch_nav_urls_by_parent_id = $oyster::DB->server_prepare("SELECT id, url, title FROM $oyster::CONFIG{db_prefix}urls WHERE parent_id = ? and show_nav_link = 1 ORDER BY nav_priority DESC");

    # load regex urls
    %regex_urls = %{$oyster::DB->selectall_hashref("SELECT id, parent_id, url, title, module, function, regex FROM $oyster::CONFIG{db_prefix}urls WHERE regex = 1", 'url')};

    # load navigation
    load_navigation();
}

our (%cache, %cache_last_hit_time);

sub update_cache {
    my $url = $oyster::REQUEST{'url'};

    # if the current url is not cached, cache it
    $cache{ $url } = $oyster::REQUEST{'current_url'} unless exists $cache{ $url };

    # update the url's last hit time
    $cache_last_hit_time{ $url } = time();

    # if the cache list is at it's limit, remove the last-used item
    if (keys %cache == 15) {
        my @sorted_urls = sort {
            $cache_last_hit_time{ $a } <=> $cache_last_hit_time{ $b }
        } keys %cache_last_hit_time;
        delete $cache{ $sorted_urls[0] };
        delete $cache_last_hit_time{ $sorted_urls[0] };
    }
}

=xml
    <section title="General URL Functions">

        <function name="is_valid">
            <synopsis>
                Returns true if a given string is a valid url.
            </synopsis>
            <prototype>
                bool = url::is_valid(string url)
            </prototype>
        </function>
=cut
sub is_valid {
    $_[0] =~ m!^http://(?:[a-zA-Z](?:[a-zA-Z\-]+\.)+(?:[a-zA-Z]{2,5}))(?::(?:\d+))?(?:(?:/[\S\s]+?)/?)?$!o;
    #$_[0] =~ m!^(?:ht|f)tps?://[a-zA-Z](?:[a-zA-Z\-]+\.)+(?:[a-zA-Z]{2,5})(?::\d+)?(?:/[\S\s]+?)?/?$!o
}

=xml
    </section>

    <section title="Oyster URL Registration/Dispatching Functions">
    
        <function name="unique">
            <synopsis>
                Finds a unique url
            </synopsis>
            <note>
                If the url passed to url::unique is taken, unique_url will generate an
                alternative.
            </note>
            <prototype>
                url::unique(string url)
            </prototype>
            <todo>
                Implement with url::is_registered()? slight memory vs cpu optimization
            </todo>
            <todo>
                rename to uniqify or make_unique?
            </todo>
        </function>
=cut

sub unique {
    my $url       = shift;
    my $orig_url  = $url;
    my $x         = 0;
    my $query     = $oyster::DB->prepare("SELECT COUNT(*) FROM $oyster::CONFIG{db_prefix}urls WHERE url_hash = ? LIMIT 1");

    FIND_UNIQUE_URL: while (1) {
        $query->execute(hash::fast($url));
        last FIND_UNIQUE_URL if $query->fetchrow_arrayref()->[0] == 0;
        $url = $orig_url . ++$x;
    }

    return $url;
}

=xml
        <function name="register">
            <synopsis>
                Associates a URL with an action in the database
            </synopsis>
            <note>
                This function performs no error checking to make sure your arguments
                are valid.
            </note>
            <note>
                The optional 'params' argument is polymorphic and will properly save
                your parameters based on what type of variable you pass.
            </note>
            <note>
                The optional 'parent_id' argument allows you to skip a query if you
                already know the parent id of the URL.
            </note>
            <note>
                The second return value is necessary because the URL you requested may
                not have been available and may have been changed.
            </note>
            <prototype>
                int url_id, string url = url::register(
                   'url'            => string url,
                   'module'         => string module_id,
                   'function'       => string function_name,
                   'title'          => string url_title,
                   ['show_nav_link' => bool show_nav_link,]
                   ['nav_priority'  => int navigation_priority,]
                   ['params'        => arrayref parameters or hashref parameters or string parameter,]
                   ['parent_id'     => int parent_id,]
                   ['regex'         => bool is_regex,]
                )
            </prototype>
            <todo>
                Should it perform error checking? (possibly create an alternative
                register_safe for that)
            </todo>
        </function>
=cut

sub register_once {
    my %args = @_;
    return if url::is_registered($args{'url'});
    goto &register;
}

sub register {
    my %args = @_;

    my $url_table = $oyster::CONFIG{'db_prefix'} . 'urls';

    # prepare columns to update, and only update them if necessary
    my %update;

    # optional arguments
    for my $field (qw(title show_nav_link nav_priority parent_id)) {
        $update{$field} = $args{$field} if exists $args{$field};
    }
    #$update{'show_nav_link'} .= '' if exists $update{'show_nav_link'}; # Pg requires strings for bools
    $update{'show_nav_link'} = '1' if $update{'show_nav_link'}; # Pg requires strings for bools
    $update{'params'}        = _parse_params_arg($args{'params'});

    # required arguments
    $args{'module'} = caller() unless exists $args{'module'};
    @update{ 'module', 'function' } = @args{ 'module', 'function' };
    $update{'url'}      = url::unique($args{'url'});
    $update{'url_hash'} = hash::fast($update{'url'});

    # if this is a regex url
    if ($args{'regex'}) {
        delete $update{'url_hash'};
        delete $update{'show_nav_link'};
        delete $update{'nav_priority'};
        delete $update{'params'};
        $args{'parent_id'} = 0; # should regex urls be -1?
        $update{'regex'} = '1';
    }

    # figure out parent id, if necessary
    if (exists $args{'parent_id'}) {
        $update{'parent_id'} = $args{'parent_id'};
    } else {
        my $last_slash_pos = rindex($update{'url'}, '/');

        # the url contains no /'s
        if ($last_slash_pos == -1) {
            $update{'parent_id'} = 0;
        }

        # the url contains /'s
        else {
            my $parent_url       = substr($update{'url'}, 0, $last_slash_pos);
            my $query            = $oyster::DB->query("SELECT id FROM $url_table WHERE url_hash = ? LIMIT 1", hash::fast($parent_url));
            $update{'parent_id'} = $query->rows() == 1 ? $query->fetchrow_arrayref()->[0] : -1 ; # -1 = not top level but no parent id
        }
    }

    # perform the insert
    my $columns = join(', ', keys %update);
    my $values  = join(', ', map('?', values %update));
    my $query   = $oyster::DB->query("INSERT INTO $url_table ($columns) VALUES ($values)", values %update);

    # reload navigation if necessary
    if ($update{'show_nav_link'}) {
        my $tmp_url = $update{'url'};
        my $num_slashes = ($tmp_url =~ s!/!!g);
        ipc::do('url', 'load_navigation') if $oyster::CONFIG{'navigation_depth'} <= $num_slashes + 1;
    }

    # return url id and url
    return $query->insert_id($url_table . '_id'), $update{'url'};
}

=xml
        <function name="update">
            <synopsis>
                Updates a registered URL
            </synopsis>
            <note>
                This function performs no error checking to make sure your arguments
                are valid.
            </note>
            <note>
                The optional 'params' argument is polymorphic and will properly save
                your parameters based on what type of variable you pass.
            </note>
            <note>
                The second return value is necessary because the URL you requested may
                not have been available and may have been changed.
            </note>
            <note>
                If you change the URL you should NOT change anything but the last part.
                This may be changed later, but it would require significant remapping of
                many URLs.
            </note>
            <prototype>
                int url_id, string url = url::update(
                   'url' or 'id'    => string url_to_update or int url_id_to_update,
                   ['url'           => string new_url,]
                   ['module'        => string new_module_id,]
                   ['function'      => string new_function_name,]
                   ['title'         => string new_url_title,]
                   ['show_nav_link' => bool new_show_nav_link,]
                   ['nav_priority'  => int new_navigation_priority,]
                   ['params'        => arrayref parameters or hashref parameters or string parameter]
                )
            </prototype>
            <todo>
                Should it perform error checking? (possibly create an alternative
                update_safe for that)
            </todo>
            <todo>
                this doesn't handle regex urls
            </todo>
        </function>
=cut

sub update {
    my $update_by_field = shift; # the field to search the url by
    my $update_by_value = shift; # the value for that field
    if ($update_by_field eq 'url') {
        $update_by_field = 'url_hash';
        $update_by_value = hash::fast($update_by_value);
    }
    my %args = @_;

    my $url_table = $oyster::CONFIG{'db_prefix'} . 'urls';

    # fetch the current url's data
    my %url = %{$oyster::DB->selectrow_hashref("SELECT * FROM $url_table WHERE $update_by_field = ? LIMIT 1", {}, $update_by_value)};

    # prepare columns to update, and only update them if necessary
    my %update;
    for my $field (qw(title module function show_nav_link nav_priority)) {
        $update{$field} = $args{$field} if exists $args{$field} and $args{$field} ne $url{$field};
    }
    $update{'show_nav_link'} = '1' if $update{'show_nav_link'}; # Pg requires strings for bools
    if (exists $args{'params'}) {
        $update{'params'} = _parse_params_arg($args{'params'});
        delete $update{'params'} if $update{'params'} eq $url{'params'};
    }
    if (exists $args{'url'} and $args{'url'} ne $url{'url'}) {
        $update{'url'}      = url::unique($args{'url'});
        $update{'url_hash'} = hash::fast($update{'url'});
    }

    # do nothing more if no fields required updating
    return $url{'id'}, $url{'url'} unless %update;

    # perform the update
    my $set = join(', ', map("$_ = ?", keys %update));
    $oyster::DB->do("UPDATE $url_table SET $set WHERE $update_by_field = ? LIMIT 1", {}, values %update, $update_by_value);

    # if the url was changed, update all sub pages to the new url
    if (exists $update{'url'}) {
        my @parent_ids                 = ($url{'id'});
        my $select_url_id_by_parent_id = $oyster::DB->prepare("SELECT id, url FROM $url_table WHERE parent_id = ? LIMIT 1");
        my $set_url_by_id              = $oyster::DB->prepare("UPDATE $url_table SET url = ?, url_hash = ? WHERE id = ? LIMIT 1");
        while (@parent_ids) {
            $select_url_id_by_parent_id->execute(pop @parent_ids);
            while (my $row = $select_url_id_by_parent_id->fetchrow_arrayref()) {
                my ($sub_id, $sub_url) = @{$row};
                substr($sub_url, 0, length $url{'url'}, $update{'url'} . '/');
                $set_url_by_id->execute($sub_url, hash::fast($sub_url), $sub_id);
                push(@parent_ids, $sub_id);
            }
        }
    }

    # reload navigation if necessary
    if ($update{'show_nav_link'} or $url{'show_nav_link'}) {
        my $tmp_url = $url{'url'};
        my $num_slashes = ($tmp_url =~ s!/!!g);
        ipc::do('url', 'load_navigation') if $oyster::CONFIG{'navigation_depth'} <= $num_slashes + 1;
    }

    # return the url id and url
    return $url{'id'}, ( exists $update{'url'} ? $update{'url'} : $url{'url'} );
}

=xml
        <function name="_parse_params_arg">
            <synopsis>
                This is what allows the optional 'params' argument on register and update
                to be polymorphic.
            </synopsis>
            <prototype>
                hashref = _parse_params_arg(hashref or arrayref or string params)
            </prototype>
        </function>
=cut

sub _parse_params_arg {
    my $params = shift;

    if (ref $params eq 'ARRAY') {
        return '' . join("\0", @{$params}); # stringified
    }

    if (ref $params eq 'HASH') {
        my @params;
        push(@params, $_, $params->{$_}) for keys %{$params};
        return '' . join("\0", @params); # stringified
    }

    return '' . $params; # stringified
}

=xml
        <function name="unregister ">
            <synopsis>
                Deletes a URL
            </synopsis>
            <note>
                This doesn't care if the url has any children!
            </note>
            <prototype>
                bool = url::unregister(string url)
            </prototype>
            <todo>
                his should return success/failure -- does Pg allow ->rows() on a delete query?
            </todo>
        </function>
=cut

sub unregister {
    my $url = shift;
    $oyster::DB->do("DELETE FROM $oyster::CONFIG{db_prefix}urls WHERE url_hash = ?", {}, hash::fast($url));
}

=xml
        <function name="unregister_by_id">
            <synopsis>
                Deletes a URL, by id
            </synopsis>
            <note>
                This doesn't care if the url has any children!
            </note>
            <prototype>
                bool = url::unregister_by_id(int url_id)
            </prototype>
            <todo>
                This should return success/failure -- does Pg allow ->rows() on a delete query?
            </todo>
        </function>
=cut

sub unregister_by_id {
    my $id = shift;
    $oyster::DB->do("DELETE FROM $oyster::CONFIG{db_prefix}urls WHERE id = ?", {}, $id);
}

=xml
        <function name="is_registered">
            <synopsis>
                Checks if a URL is registered
            </synopsis>
            <prototype>
                bool is_taken = url::is_registered(string url)
            </prototype>
        </function>
=cut

sub is_registered {
    my $url = shift;
    return $oyster::DB->selectrow_arrayref("SELECT COUNT(*) FROM $oyster::CONFIG{db_prefix}urls WHERE url_hash = ? LIMIT 1", {}, hash::fast($url))->[0];
}

=xml
        <function name="is_registered_by_id">
            <synopsis>
                Checks if a URL is taken, by id
            </synopsis>
            <prototype>
                bool is_taken = url::is_registered_by_id(int url_id)
            </prototype>
        </function>
=cut

sub is_registered_by_id {
    my $id = shift;
    return $oyster::DB->selectrow_arrayref("SELECT COUNT(*) FROM $oyster::CONFIG{db_prefix}urls WHERE id = ? LIMIT 1", {}, $id)->[0];
}

=xml
        <function name="get">
            <synopsis>
                Retreives data associated with a url from the database
            </synopsis>
            <note>
                Returns undef if no urls matched
            </note>
            <prototype>
                hashref url_data = url::get(string url)
            </prototype>
        </function>
=cut

sub get {
    my $url = shift;
    $fetch_by_hash->execute(hash::fast($url));
    return $fetch_by_hash->rows() == 1 ? $fetch_by_hash->fetchrow_hashref() : undef ;
}

=xml
        <function name="get_by_id">
            <synopsis>
                Retreives all data associated with a URL from the database, by id
            </synopsis>
            <note>
                Returns undef if no urls matched
            </note>
            <prototype>
                hashref url_data = url::get_by_id(int url_id)
            </prototype>
        </function>
=cut

sub get_by_id {
    my $url_id = shift;
    my $query = $oyster::DB->query("SELECT * FROM $oyster::CONFIG{db_prefix}urls WHERE id = ? LIMIT 1", $url_id);
    return $query->rows() ? $query->fetchrow_hashref() : undef ;
}

=xml
        <function name="get_url_by_id">
            <synopsis>
                Retreives only the URL from the database, by id
            </synopsis>
            <note>
                Returns undef if no urls matched
            </note>
            <prototype>
                string url = url::get_url_by_id(int url_id)
            </prototype>
        </function>
=cut

sub get_url_by_id {
    my $url_id = shift;
    my $query = $oyster::DB->query("SELECT url FROM $oyster::CONFIG{db_prefix}urls WHERE id = ? LIMIT 1", $url_id);
    return $query->rows() ? $query->fetchrow_arrayref()->[0] : undef ;
}

=xml
        <function name="get_parent">
            <warning>
                Incomplete
            </warning>
            <todo>
                Everything
            </todo>
        </function>
=cut

sub get_parent {

}

=xml
        <function name="get_parent_by_id">
            <synopsis>
                Incomplete
            </synopsis>
            <todo>
                Everything
            </todo>
        </function>
=cut

sub get_parent_by_id {

}

=xml
        <function name="has_children">
            <warning>
                Unimplemented
            </warning>
            <synopsis>
                Checks if a url has any children
            </synopsis>
            <prototype>
                bool = url::has_children(string url)
            </prototype>
            <todo>
                bugged, this checks if a url exists! not if it has childeren, have it fetch the url then use has_children_by_id
            </todo>
        </function>
=cut

#sub has_children {
#    my $url = shift;
#    return $oyster::DB->query("SELECT COUNT(*) FROM $oyster::CONFIG{db_prefix}urls WHERE url_hash = ? LIMIT 1", hash::fast($url))->fetchrow_arrayref()->[0];
#}

=xml
        <function name="has_children_by_id">
            <synopsis>
                Checks if a url has any children, by id
            </synopsis>
            <prototype>
                bool = url::has_children_by_id(int url_id)
            </prototype>
        </function>
=cut

sub has_children_by_id {
    my $id = shift;
    return $oyster::DB->selectrow_arrayref("SELECT COUNT(*) FROM $oyster::CONFIG{db_prefix}urls WHERE parent_id = ? LIMIT 1", {}, $id)->[0];
}

=xml
        <function name="print_subpage_xml">
            <synopsis>
                Prints subpage xml for a given url id.
            </synopsis>
            <prototype>
                url::print_subpage_xml(int url_id)
            </prototype>
            <todo>
                Assume current url if none is specified?
            </todo>
            <todo>
                Add depth argument
            </todo>
        </function>
=cut

sub print_subpage_xml {
    my $url_id = shift;

    my $query = $oyster::DB->query("SELECT url, title FROM $oyster::CONFIG{db_prefix}urls WHERE parent_id = ?", $url_id);
    return unless $query->rows();
    print qq~\t<menu id="subpages">\n~;
    while (my $url = $query->fetchrow_arrayref()) {
        my ($url, $title) = @{$url};
        print qq~\t\t<item url="$oyster::CONFIG{url}$url/" label="$title" />\n~;
    }
    print "\t</menu>\n";
}

=xml
    </section>

    <section title="Navigation Functions">
        <synopsis>
            Functions related to the navigation menu, modules should rarely need
            to call these.  Oyster does it automatically.
        </synopsis>

=cut

our (@nav_url_xml, $nav_xml);

sub load_navigation {

    # begin reloading data, starting at parent id 0 with depth 1
    _load_nav_urls_by_parent_id(0, 1);

    # save nav xml
    $nav_xml = join('', @nav_url_xml);

    # clear data structures
    @nav_url_xml = ();
}

sub _load_nav_urls_by_parent_id {
    my $parent_id = shift;
    my $depth     = shift;
    my $indent    = "\t" . ("\t" x $depth);

    # fetch urls with this parent id
    $fetch_nav_urls_by_parent_id->execute($parent_id);

    # save a list of matching urls -- this is necessary because the same $query object may be executed again before this function finishes
    my @urls;
    while (my $url = $fetch_nav_urls_by_parent_id->fetchrow_hashref()) {
        push @urls, $url;
    }

    # iterate through urls
    for my $url (@urls) {

        # save url data
        push @nav_url_xml, qq~$indent<item label="$url->{title}" url="$oyster::CONFIG{url}$url->{url}/"~;

        # populate any child urls
        my $url_index = $#nav_url_xml;
        _load_nav_urls_by_parent_id($url->{'id'}, $depth + 1) unless $depth == $oyster::CONFIG{'navigation_depth'};

        # if sub items were added
        if ($url_index != $#nav_url_xml) {
            $nav_url_xml[ $url_index ] .= ">\n";
            push @nav_url_xml, "$indent</item>\n";
        }

        # this url had no children
        else {
            $nav_url_xml[ $url_index ] .= " />\n";
        }
    }
}

sub print_navigation_xml {
    return if length $nav_xml == 0;
    print qq~\t<menu id="navigation">\n~;
    print $nav_xml;
    print "\t</menu>\n";
}

=xml
    </section>
=cut

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
