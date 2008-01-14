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
