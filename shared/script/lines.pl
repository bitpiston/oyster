=xml
<document title="Line Counter (aka, epeen measurer)">
    <synopsis>
        Counts the total number of lines in pl, pm, and xsl files in the shared directory.
    </synopsis>
=cut
our @exts = qw(pl pm xsl);
our @exclude = qw(perllib);
our $total_lines;

sub lines_dir {
    my $path = shift;
    opendir(my $dh, $path) or die $!;
    while (my $filename = readdir($dh)) {
        next if $filename =~ /^\./;
        next if grep(/^$filename$/, @exclude);
        if (-d $path . $filename) {
            lines_dir("$path$filename/");
            next;
        }
        my ($ext) = ($filename =~ /\.(.+?)$/);
        next unless grep(/^$ext$/i, @exts);
        open(my $fh, '<', $path . $filename) or die $!;
        my $lines = 0;
        while (<$fh>) {
            $lines++;
        }
        print "[$lines] $path$filename\n";
        $total_lines += $lines;
    }
}

lines_dir('./');

print "\nTotal Lines: $total_lines\n";

=xml
</document>
=cut

1;

# Copyright BitPiston 2008