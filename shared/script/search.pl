=xml
<document title="Source Search">
    <synopsis>
        Searches for a given (regular expression) string in the pl, pm, and xsl files.
    </synopsis>
    <section title="Command Line Arguments">
        This utility requires one argument and can optionally take two.  The first is the regular expression to search for, the second is the directory to search.  If no directory is specified, the current directory is assumed.
    </section>
    <todo>
    	Update this utility to use console::util to parse arguments so more options can be specified, such as extensions to search or ignore and whether to be case sensitive or not (maybe the option to do a non-regex search too)
    </todo>
=cut
package oyster::script::search;

our $search      = $ARGV[0];
our $search_path = './';
our @exts        = qw(pl pm xsl);
our @exclude     = qw(perllib modules-old .svn);
our $results     = 0;

if (length $ARGV[1]) {
    $search_path = $ARGV[1];
    $search_path .= '/'                unless $search_path =~ m!/$!;
    $search_path = './' . $search_path unless $search_path =~ m!^\./!;
}

sub search_dir {
    my $path = shift;
    opendir(my $dh, $path) or die $!;
    while (my $filename = readdir($dh)) {
        next if $filename =~ /^\./;
        next if grep(/^$filename$/, @exclude);
        if (-d $path . $filename) {
            search_dir("$path$filename/");
            next;
        }
        my ($ext) = ($filename =~ /\.(.+?)$/);
        next unless grep(/^$ext$/i, @exts);
        open(my $fh, '<', $path . $filename) or die $!;
        my $matches = 0;
        my $line = 0;
        while (<$fh>) {
            $line++;
            if (/$search/i) {
                my $file = "$path$filename";
                $file =~ s/^$search_path//;
                print "$file\n" unless $matches;
                my $string = $_;
                $string =~ s/^\s+(.+)\s+$/$1/g;
                chomp($string);
                print "  $line:\t$string\n";
                $results++;
                $matches++;
            }
        }
    }
}

search_dir($search_path);
print "\n$results total matches\n";

=xml
</document>
=cut

1;

# Copyright BitPiston 2008