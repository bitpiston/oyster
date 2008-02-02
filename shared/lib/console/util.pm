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
            Quick and dirty command line argument processing.  This treats any string prefixed with - or -- as a 'key' and any string directly after it as a value for that key.  If no key is available, the value is stored with the key ''.
        </synopsis>
        <note>
            If you include config.pl (or it was included for you), you do not need to call this, the results will be stored in %oyster::config::args.
        </note>
        <prototype>
            hash = console::util::process_args()
        </prototype>
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
