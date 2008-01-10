=xml
<document title="File Move Utility">
    <synopsis>
        Moves/renames a file just like the system command, but in an OS-neutral way.
    </synopsis>
    <section title="Command Line Arguments">
        This utility requires two arguments, the file to move/rename and the destination filename.
    </section>
=cut
package oyster::script::file_move;

use File::Copy;

my ($from, $dest) = @ARGV;

print move($from, $dest) ? "1\n" : "0\n";

=xml
</document>
=cut

1;

# Copyright BitPiston 2008