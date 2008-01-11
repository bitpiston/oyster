=xml
<document title="Miscellaneous Functions">
    <synopsis>
        Various functions that don't (yet) warrant their own categories
    </synopsis>
    <todo>
        Document the functions without docs
    </todo>
=cut

package misc;

require Exporter;
@ISA = qw(Exporter);

=xml
    <function name="get_first_words">
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
# with punctuation...
sub get_first_words {
    my $string    = length $_[0] ? $_[0]: '' ;
    my $num_words = $_[1];
    my @words;
    while (length $string) {
        my $replace_len;
        if ($string =~ /(^(["'\.,;\:\-\w]+))/) {
            $replace_len = length $1;
            push @words, $2;
            last if @words == $num_words;
        } elsif ($string =~ /(^[^"'\.,;\:\-\w]+)/) {
            $replace_len = length $1;
        }
        substr($string, 0, $replace_len, '');
    }
    push @words, '...' if length $string;
    return join(' ', @words);
}

=xml
    <function name="dump">
        <synopsis>
            
        </synopsis>
        <note>
            
        </note>
        <prototype>
            
        </prototype>
    </function>
=cut
sub dump {
    require Data::Dumper;
    return Data::Dumper::Dumper(@_);
}

=xml
    <function name="proper_caps">
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
sub proper_caps {
    my $string = lc(shift());
    $string =~ s/\b([a-z])/uc $1/eg;
    return $string;
}

=xml
    <function name="compress_metadata">
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
sub compress_metadata {
    return '' unless @_; # sql will expect an empty string

    if (ref $_[0] eq 'HASH') {
        my @pairs;
        for my $name (keys %{@_}) {
            push @pairs, "$name\0$_[0]->{$name}";
        }
        return join "\0\0", @pairs;
    }

    my %meta = @_;
    my @pairs;
    for my $name (keys %meta) {
        push @pairs, "$name\0$meta{$name}";
    }
    return join "\0\0", @pairs;
}

=xml
    <function name="">
        <synopsis>
            
        </synopsis>
        <note>
            
        </note>
        <prototype>
            
        </prototype>
        <example>
            
        </example>
        <todo>
            
        </todo>
    </function>
=cut
sub expand_metadata {
    return () unless length $_[0]; # a hash will expect an empty list (TODO: would return; be sufficient?)
    my %meta;
    my @pairs = split /\0\0/, shift;
    for my $pair (@pairs) {
        my ($name, $value) = split /\0/, $pair;
        $meta{$name} = $value;
    }
    return %meta;
}

=xml
    <function name="trace">
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
push(@EXPORT, 'trace');
sub trace {
    #my $trace;
    my @stack;
    my $i = 1;
    my $trace = "File                          Line Subroutine\n";
    while (my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i)) {
        $filename =~ s!//+!/!g;
        if ($subroutine eq '(eval)' and @stack) {
            my $last_call_frame = pop @stack;
            $subroutine .= ' ' . $last_call_frame->[1];
        }
        push @stack, [$filename, $subroutine, $line];
    } continue { $i++ }
    for my $call_frame (@stack) {
        #$trace .= pad(substr($call_frame->[0], -29), 30) . pad($call_frame->[2], 5) . $call_frame->[1]. "\n";
        $trace .= pad($call_frame->[0], 29) . ' ' . pad($call_frame->[2], 5) . $call_frame->[1]. "\n";
    }

    return $trace;
}

=xml
    <function name="pad">
        <synopsis>
            If the string is too long, chops the beginning off and prepends with ...
        </synopsis>
        <note>
            
        </note>
        <prototype>
            
        </prototype>
        <example>
            
        </example>
    </function>
=cut

sub pad {
    my $string = shift;
    my $pad_to = shift;
    $string = '...' . substr($string, -1 * $pad_to + 3) if length $string > $pad_to;
    return $string . (' ' x ($pad_to - length $string));
}

=xml
    <function name="confirmation">
        <synopsis>
            Prints a confirmation message.
        </synopsis>
        <prototype>
            confirmation(string confirmation_message[, forward_options])
        </prototype>
        <example>
            confirmation('Something happened.', $BASE_URL => 'Return to the home page.');
        </example>
    </function>
=cut

push(@EXPORT, 'confirmation');
sub confirmation {
    my ($message, %options) = @_;
    if (%options) {
        print "\t<confirmation>\n";
        print "\t\t$message\n";
        print "\t\t<options>\n";
        foreach (keys %options) {
            print "\t\t\t<option url=\"$options{$_}\">$_</option>\n";
        }
        print "\t\t</options>\n";
        print "\t</confirmation>\n";
    } else {
        print "\t<confirmation>$message</confirmation>\n";
    }
}

=xml
    <function name="shell_escape">
        <synopsis>
            Escapes characters to avoid injection when executing shell commands.
        </synopsis>
        <note>
            Currently only escapes double quotes.  The data passed to this function
            assumes that it will be placed inside double quotes when it is passed to
            the shell.
        </note>
        <prototype>
            string escaped_string = misc::shell_escape(string)
        </prototype>
        <todo>
            Make this better, should have different mechanics for different shells.
        </todo>
    </function>
=cut

sub shell_escape {
    my $string = shift;
    $string =~ s/"/\"/g;
    return $string;
}

=xml
    <function name="urlify_string">
        <synopsis>
             Takes a string and turns it into something url-friendly
        </synopsis>
        <prototype>
            string url_friendly_string = urlify_string(string)
        </prototype>
        <todo>
            Deprecate in favor or something in the url package
        </todo>
    </function>
=cut

push(@EXPORT, 'urlify_string');
sub urlify_string {
    my $string = lc(shift()); # get the first arg and lowercase it
    
    # replace @ and & with their plaintext counterparts
    $string =~ s/\@/ at /og;
    $string =~ s/&/ and /og;

    # replace whitespace and puncutation with underscores
    #$string =~ s/\s+/_/og;
    $string =~ s/[,.!""''\s]+/_/og;

    # replace multiple underscores with a single one
    $string =~ s/_+/_/og;

    # replaced non word/ascii characters with encoded equivalents
    $string =~ s/([^a-z0-9_])/sprintf('%%%02X', ord $1)/oge;

    return $string;
}

=xml
    <function name="random_string">
        <synopsis>
            Generate a random alphanumeric string
        </synopsis>
        <note>
            The default length is 32 characters
        </note>
        <prototype>
            string random_string = random_string([int length])
        </prototype>
        <example>
            print random_string(100);
        </example>
        <todo>
            Possible to do this via chr and just using a random int &lt; 62
        </todo>
    </function>
=cut

push(@EXPORT, 'random_string');
{
    my @chars = (a..z, A..Z, 0..9);
    sub random_string {
        return join( '', map { $chars[ rand @chars ] } ( 1 .. ( $_[0] ? $_[0] : 32 ) ) );
    }
}

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
