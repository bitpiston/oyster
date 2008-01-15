=xml
<document title="String Functions">
    <synopsis>
        String related stuff -- some general, some Oyster specific.
    </synopsis>
=cut

package string;

=xml
    <function name="get_first_words">
        <synopsis>
            Given a string and a number of words, returns the first X words from a string.
        </synopsis>
        <note>
            This does include punctuation, but it does not count towards the word count.
        </note>
        <note>
            If your string contains xml, be sure to use xml::strip_elements first.
        </note>
        <prototype>
            string = string::get_first_words(string, int num_words)
        </prototype>
    </function>
=cut

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
    <function name="proper_caps">
        <synopsis>
            Takes a string and capitalizes the first letter of each word.
        </synopsis>
        <prototype>
            string = string::proper_caps(string)
        </prototype>
        <todo>
            This should be more intelligent; aka, dont caps things like 'a', 'the', etc
        </todo>
    </function>
=cut

sub proper_caps {
    my $string = lc(shift());
    $string =~ s/\b([a-z])/uc $1/eg;
    return $string;
}

=xml
    <function name="pad">
        <synopsis>
            Pads a string with spaces to a given length.
        </synopsis>
        <note>
            If the string is too long, chops the beginning off and prepends with ...
        </note>
        <prototype>
            string = string::pad(string, int length)
        </prototype>
        <todo>
            This should have a flag/option to chop off the beginning OR end
        </todo>
    </function>
=cut

sub pad {
    my $string = shift;
    my $pad_to = shift;
    $string = '...' . substr($string, -1 * $pad_to + 3) if length $string > $pad_to;
    return $string . (' ' x ($pad_to - length $string));
}

=xml
    <function name="urlify">
        <synopsis>
             Takes a string and turns it into something url-friendly
        </synopsis>
        <prototype>
            string = string::urlify(string)
        </prototype>
    </function>
=cut

sub urlify {
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
    <function name="random">
        <synopsis>
            Generate a random alphanumeric string
        </synopsis>
        <note>
            The default length is 32
        </note>
        <prototype>
            string = string::random([int length])
        </prototype>
        <example>
            print string::random(100);
        </example>
        <todo>
            Possible to do this via chr and just using a random int &lt; 62
        </todo>
    </function>
=cut

sub random {
    my @chars = (a..z, A..Z, 0..9);
    return join( '', map { $chars[ rand @chars ] } ( 1 .. ( $_[0] ? $_[0] : 32 ) ) );
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2008
