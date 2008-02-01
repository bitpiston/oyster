=xml
<document title="XML Parser">
    <warning>
        This library is considered pre-alpha.
    </warning>
    <synopsis>
        A quick and dirty XML parser inspired by PHP's xml_ functions.
    </synopsis>
=cut
package xml::parser;

use exceptions;

sub new {
    bless {
        'handlers' => {},
    }, shift;
}

sub set_node_start_handler { $_[0]->{'handlers'}{'node_start'} = $_[1] }
sub set_node_end_handler   { $_[0]->{'handlers'}{'node_end'} = $_[1] }
sub set_directive_handler  { $_[0]->{'handlers'}{'directive'} = $_[1] }
# TODO: deprecate above three methods in favor of the one below
sub set_handler  { $_[0]->{'handlers'}{$_[1]} = $_[2] }

sub parse_file {
    my $self = shift;
    my $file = shift;
    $self->parse_string(file::slurp($file));
}

# TODO:
#   * Ensure that there is only one root node
#   * Require/validate xml version?
sub parse_string {
    my $self   = shift;
    my $string = shift;

    $self->parse_chunk($string);
    $self->parse_chunk(); # signal eof
    
    return 1;
}

sub parse_chunk {
    my $self   = shift;
    my $string = shift;
    my $eof    = length $string ? 0 : 1 ; # set to true if the end of file has been reached

    # prepend anything in the buffer to the string
    $string = delete($self->{'buffer'}) . $string if exists $self->{'buffer'}; # have to have ()'s for precedence

    # iterate over the string
    while (length $string) {

        # node start          # namespace      # node        # attrs# namespace       # attr              # attr value    # node end
        if ($string =~ s/^<(?:([a-zA-z0-9]+):)?([a-zA-z0-9]+)((?:\s+(?:[a-zA-z0-9]+:)?[a-zA-z0-9]+\s*=\s*"[\s\S]*?")*)?\s*(\/)?>//o) {
            my $namespace    = $1; # <_________:
            my $node         = $2; # <namespace:____
            my $attrs        = $3; # <namespace:node _____
            my $is_singleton = $4; # <namespace:node attrs _>

            # add the node to the stack unless it contained its own end tag
            push @{$self->{'stack'}}, $node unless $is_singleton;

            # execute handler (if any)
            $self->{'handlers'}{'node_start'}->($self, lc $namespace, lc $node, _parse_attrs($attrs)) if exists $self->{'handlers'}{'node_start'};

            # execute end handler (if any) if this was a singleton node
            $self->{'handlers'}{'node_end'}->($self, lc $namespace, lc $node) if $is_singleton and exists $self->{'handlers'}{'node_end'};
        }

        # node end
        elsif ($string =~ s/^<\/(?:([a-zA-z0-9]+):)?([a-zA-z0-9]+)>//o) {
            my $namespace   = $1;
            my $node        = $2;
            my $popped_node = pop @{$self->{'stack'}};

            throw 'validation_error' => "Unmatched end tag '$node', expecting '$popped_node'." unless $node eq $popped_node;

            # execute handler (if any)
            $self->{'handlers'}{'node_end'}->($self, lc $namespace, lc $node) if exists $self->{'handlers'}{'node_end'};
        }

        # doctype declarations (must come first)
        # TODO: error if not first?
        elsif ($string =~ s/^(<!DOCTYPE[\s\S]+?>)//o) {
            ${$self->{'data_pointer'}} .= $1 if exists $self->{'data_pointer'} and @{$self->{'stack'}};
        }

        # xml directives (must come first)
        elsif ($string =~ s/^<\?([a-zA-z0-9\-]+)((?:\s+[a-zA-z0-9]+\s*=\s*["'][\s\S]*?["'])*)?\s*\?>//o) {
            my $directive = $1;
            my $attrs     = $2;

            # ensure that these come first
            throw 'validation_error' => 'XML directive inside of node.' if @{$self->{'stack'}};

            # execute handler (if any)
            $self->{'handlers'}{'directive'}->($self, lc $directive, _parse_attrs($attrs)) if exists $self->{'handlers'}{'directive'};
        }

        # comments
        elsif ($string =~ s/^<!--([\s\S]+?)-->//o) {
            my $comment = $1;

            # execute handler (if any)
            $self->{'handlers'}{'comment'}->($self, $comment) if exists $self->{'handlers'}{'comment'};
        }

        # CDATA sections
        elsif ($string =~ s/^<!\[CDATA\[([\s\S]*?)\]\]>//o) {
            my $data = $1;

            # execute handler (if any)
            ${$self->{'data_pointer'}} .= $data if exists $self->{'data_pointer'};
        }

        # data
        else {

            # locate the first <
            my $index = index($string, '<');

            # if the text contains no <'s
            if ($index == -1) {
                throw 'validation_error' => "Data outside of a node." if $eof and $string =~ /\S/;
                $self->{'buffer'} = $string;
                last;
            }

            # < is the first character (usually this means the chunk ended mid-node, but it could also be a parse error if you are at the eof)
            elsif ($index == 0) {
                throw 'validation_error' => "Unexpected '<'." if $eof;
                $self->{'buffer'} = $string;
                last;
            }

            # execute handler (if any)
            if (exists $self->{'data_pointer'}) {
                ${$self->{'data_pointer'}} .= substr($string, 0, $index, '');
            } else {
                substr($string, 0, $index, '');
            }
        }

        # stop looping if the parser was ordered to finish
        # TODO: more efficient to only check this if a handler was called?
        #  * could remove ->finish() and pass handlers $string, they could modify it using the alias in @_
        #last if $self->{'finish'};
        return -1 if $self->{'finish'}; # -1 tells http::get to close the connection
    }

    # if this is the eof
    if ($eof) {

        # check for unended nodes
        throw 'validation_error' => 'Unended nodes: ' . join(', ', @{$self->{'stack'}}) . '.' if @{$self->{'stack'}} and !$self->{'finish'};
    }

    return 1; # success
}

# should attributes w/ namespaces pass the namespace separately?
sub _parse_attrs {
    return unless @_;
    my $attrs = shift;
    my %attrs;
    while (length $attrs) {
        #allows escaped "s in attributes # if ($attrs =~ s/^\s+((?:[a-zA-z0-9]+:)?[a-zA-z0-9]+)\s*=\s*"((?:[\s\S])*?(?!\\))"//o) {
        if ($attrs =~ s/^\s+((?:[a-zA-z0-9]+:)?[a-zA-z0-9]+)\s*=\s*"([\s\S]*?)"//o) {
           $attrs{lc $1} = $2;
        } else {
            throw 'validation_error' => "Attribute parse error.";
        }
    }
    return %attrs;
}

sub finish {
    my $self = shift;

    $self->{'finish'} = 1;
}

# Copyright BitPiston 2008
1;
=xml
</document>
=cut