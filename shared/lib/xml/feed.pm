=xml
<document title="XML Feed Functions">
    <warning>
        This library is considered pre-alpha.
    </warning>
    <synopsis>
        Provides an object to parse and read from rss/atom feeds.
    </synopsis>
    <note>
        This is not meant to be a perfect, deep, feed parser.  It is meant to
        quickly scan feeds and retreive basic information from them, not necessarily
        every little detail in the feed's xml.
    </note>
    <note>
        This is implemented as a subclass to xml::parser.  If you are interested
        in learning how to subclass xml::parser to parse specific types of
        documents, check this module's source out.
    </note>
    <todo>
        Documentation
    </todo>
=cut
package xml::feed;
use base 'xml::parser';

use xml::parser;
use exceptions;

=xml
    <section title="Object Properties">
        <ul>
            <li><code>arrayref items</code></li>
            <li><code>string feed_type</code></li>
            <li><code>string title</code></li>
        </ul>
    </section>

    <function name="new">
        <synopsis>
            Creates a new xml::feed object.
        </synopsis>
        <note>
            'until_url_hash' is used by imfeedr.  If anything, imfeedr should
            subclass this instead of having its hacks hard coded in.
        </note>
        <note>
            If 'num_items' is specified, the parser will stop parsing after the
            specified number of items.
        </note>
        <prototype>
            $feed = xml::feed->new(['num_items' => int max_num_of_items][, 'until_url_hash' => string title_hash])
        </prototype>
    </function>
=cut

sub new {
    my $class = shift;
    my %options = @_;
    my $self = bless {
        'items' => [],
        'handlers' => {
            'node_start' => \&_node_start_handler,
        },
    }, $class;
    $self->{'num_items'}      = $options{'num_items'} if exists $options{'num_items'};
    $self->{'until_url_hash'} = $options{'until_url_hash'} if exists $options{'until_url_hash'};
    return $self;
}

=xml
    <function name="parse_url">
        <synopsis>
            
        </synopsis>
        <note>
            
        </note>
        <prototype>
            
        </prototype>
        <example>
            
        </example>
    </function>
=cut

sub parse_url {
    my $self = shift;
    my $url  = shift;
    http::get($url, 'data_handler' => sub { $self->parse_chunk(@_) });
    return 1;
}

=xml
    <function name="_node_start_handler">
        <synopsis>
            Catches root node and analyzes it to detect the feed type and implement
            the proper handlers.
        </synopsis>
        <note>
            
        </note>
        <prototype>
            
        </prototype>
        <example>
            
        </example>
    </function>
=cut

sub _node_start_handler {
    my $self       = shift;
    my $namespace  = shift;
    my $node       = shift;
    my %attributes = @_;

    # rss 0.91
    if ($node eq 'rss' and $attributes{'version'} == 0.91) {
        $self->{'feed_type'} = 'rss';
        $self->{'handlers'}{'node_start'} = \&_rss_node_start_handler;
        $self->{'handlers'}{'node_end'}   = \&_rss_node_end_handler;
        $self->{'handlers'}{'data'}       = \&_rss_data_handler;
    }

    # rss 1.0
    elsif ($attributes{'xmlns'} eq 'http://purl.org/rss/1.0/') {
        $self->{'feed_type'} = 'rdf';
        $self->{'handlers'}{'node_start'} = \&_rss_node_start_handler;
        $self->{'handlers'}{'node_end'}   = \&_rss_node_end_handler;
        $self->{'handlers'}{'data'}       = \&_rss_data_handler;
    }

    # rss 2.0
    elsif ($node eq 'rss' and $attributes{'version'} == 2) {
        $self->{'feed_type'} = 'rss';
        $self->{'handlers'}{'node_start'} = \&_rss_node_start_handler;
        $self->{'handlers'}{'node_end'}   = \&_rss_node_end_handler;
        $self->{'handlers'}{'data'}       = \&_rss_data_handler;
    }

    # atom
    elsif ($attributes{'xmlns'} eq 'http://www.w3.org/2005/Atom' or $attributes{'xmlns'} =~ m!^http://purl.org/atom/ns!) {
        $self->{'feed_type'} = 'atom';
        $self->{'handlers'}{'node_start'} = \&_atom_node_start_handler;
        $self->{'handlers'}{'node_end'}   = \&_atom_node_end_handler;
        $self->{'handlers'}{'data'}       = \&_atom_data_handler;
    }

    # unknown type/not a feed
    else {
        throw 'validation_error' => 'XML is not a known feed type.';
    }
}

=xml
    <section title="RDF/RSS Handlers">
    
        <function name="_rss_node_start_handler">
            <synopsis>
                
            </synopsis>
            <note>
                
            </note>
            <prototype>
                
            </prototype>
            <example>
                
            </example>
        </function>
=cut

sub _rss_node_start_handler {
    my $self       = shift;
    my $namespace  = shift;
    my $node       = shift;
    my %attributes = @_;

    # each feed item
    if ($node eq 'item') {
        push(@{$self->{'items'}}, {});
        $self->{'in_item'}++;
    }

    # a title, link, or description in an item
    elsif (($node eq 'title' or $node eq 'link' or $node eq 'description') and $self->{'in_item'}) {
        $self->{'data_pointer'} = \$self->{'items'}->[$#{$self->{'items'}}]->{$node};
    }

    # the first <title> node encountered
    elsif ($node eq 'title' and !$self->{'in_item'} and !exists $self->{'title'}) {
        $self->{'data_pointer'} = \$self->{'title'}; # autovivifies $self->{'title'} into existence
    }

    # the first <link> node encountered
    elsif ($node eq 'link' and !$self->{'in_item'} and !exists $self->{'link'}) {
        $self->{'data_pointer'} = \$self->{'link'}; # autovivifies $self->{'link'} into existence
    }
}

=xml
        <function name="_rss_node_end_handler">
            <synopsis>
                
            </synopsis>
            <note>
                
            </note>
            <prototype>
                
            </prototype>
            <example>
                
            </example>
        </function>
=cut

sub _rss_node_end_handler {
    my $self      = shift;
    my $namespace = shift;
    my $node      = shift;


    if ($node eq 'item') {
        $self->{'in_item'}--;
        $self->finish() if exists $self->{'num_items'} and scalar @{$self->{'items'}} == $self->{'num_items'};
    }

    elsif ($node eq 'link' and exists $self->{'until_url_hash'} and $self->{'in_item'} and hash::fast(${$self->{'data_pointer'}}) eq $self->{'until_url_hash'}) {
        pop @{$self->{'items'}};
        $self->finish();
    }

    delete $self->{'data_pointer'} if exists $self->{'data_pointer'};
}

=xml
    </section>
    
    <section title="Atom Handlers">
    
        <function name="_atom_node_start_handler">
            <synopsis>
                
            </synopsis>
            <note>
                
            </note>
            <prototype>
                
            </prototype>
            <example>
                
            </example>
        </function>
=cut

sub _atom_node_start_handler {
    my $self       = shift;
    my $namespace  = shift;
    my $node       = shift;
    my %attributes = @_;

    if ($node eq 'entry') {
        push(@{$self->{'items'}}, {});
        $self->{'in_item'}++;
    }
    
    elsif (($node eq 'title' or $node eq 'link' or $node eq 'summary') and $self->{'in_item'}) {
        $node = 'description' if $node eq 'summary'; # rdf/rss data structure compatibility
        $self->{'data_pointer'} = \$self->{'items'}->[$#{$self->{'items'}}]->{$node};
        ${$self->{'data_pointer'}} .= $attributes{'href'} if $node eq 'link' and length $attributes{'href'}; # google's atom use href (they also use the purl xmlns)
    }

    elsif ($node eq 'title' and !$self->{'in_item'} and !exists $self->{'title'}) {
        $self->{'data_pointer'} = \$self->{'title'};
    }

    # the first <link> node encountered
    elsif ($node eq 'link' and !$self->{'in_item'} and !exists $self->{'link'}) {
        $self->{'link'} = $attributes{'href'};
    }
}

=xml
        <function name="_atom_node_end_handler">
            <synopsis>
                
            </synopsis>
            <note>
                
            </note>
            <prototype>
                
            </prototype>
            <example>
                
            </example>
        </function>
=cut

sub _atom_node_end_handler {
    my $self      = shift;
    my $namespace = shift;
    my $node      = shift;

    if ($node eq 'entry') {
        $self->{'in_item'}--;
        $self->finish() if exists $self->{'num_items'} and scalar @{$self->{'items'}} == $self->{'num_items'};
    }

    elsif ($node eq 'link' and exists $self->{'until_url_hash'} and $self->{'in_item'} and hash::fast(${$self->{'data_pointer'}}) eq $self->{'until_url_hash'}) {
        pop @{$self->{'items'}};
        $self->finish();
    }

    delete $self->{'data_pointer'} if exists $self->{'data_pointer'};
}

=xml
    </section>
=cut

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
