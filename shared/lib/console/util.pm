=xml
<document title="Console Utility Functions">
    <synopsis>
        Functions used by various Oyster console applications
    </synopsis>
=cut

package console::util;

=xml
    <function name="end_all_clean">
        <synopsis>
            Processes command line arguments
        </synopsis>
        <todo>
            Documentation
        </todo>
    </function>
=cut

sub process_args {
    my %args;
    my $key = '';
    for my $arg (@ARGV) {
        if ($arg =~ /^--?(\w+)$/) {
            $key = $1;
            $args{$key} = ''; # ensure that it is defined even if it not given a value
        } else {
            $args{$key} = $arg;
            $key = ''
        }
    }
    return %args;
}

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
