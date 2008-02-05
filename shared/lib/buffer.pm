=xml
<document title="Output Buffering Functions">
    <synopsis>
        These functions that allow capturing output.  These were inspired by
        php's ob_* series of functions.
    </synopsis>
    <todo>
        Rename to ob_?  There is more than one kind of buffer.
    </todo>
    <section title="Implementation Details">
        This actually only uses one buffer, but allows for multiple buffers
        by keeping a stack of the length of that buffer each time a new one
        is started.
    </section>
=cut

package buffer;

# variables
my @buffers;     # stack of current buffer positions
my $buffer_fh;   # the buffer filehandle
my $buffer;      # the contents of the entire buffer
my $prev_select; # the previously selected handle before buffers were started

# create a buffer handle to use
open($buffer_fh, '>', \$buffer);

=xml
    <function name="start">
        <synopsis>
            Begins an output buffer
        </synopsis>
        <prototype>
            buffer::start()
        </prototype>
    </function>
=cut

sub start {

    # start the buffer if it is not active
    unless (@buffers) {
        $prev_select = select $buffer_fh;
        seek($buffer_fh, 0, 0);
        $buffer = '';
    }

    # add the current position to the buffer stack
    push(@buffers, tell $buffer_fh);
}

=xml
    <function name="end">
        <synopsis>
            Ends the current output buffer and prints the contents of the buffer
        </synopsis>
        <note>
            Does nothing if no buffers are active
        </note>
        <warning>
            If you call buffer::end() while another buffer is active, the result is printed to that buffer; to circumvent this behavior use print STDOUT buffer::end_clean();
        </warning>
        <prototype>
            buffer::end()
        </prototype>
    </function>
=cut

sub end {
    my $out = end_clean();
    print $out;
}

=xml
    <function name="end_all">
        <synopsis>
            Ends all output buffers and prints their contents
        </synopsis>
        <note>
            Does nothing if no buffers are active
        </note>
        <prototype>
            buffer::end_all()
        </prototype>
    </function>
=cut

sub end_all {
    my $out = end_all_clean();
    print $out;
}

=xml
    <function name="end_clean">
        <synopsis>
            Ends the current output buffer and returns the contents of the buffer
        </synopsis>
        <note>
            Does nothing if no buffers are active
        </note>
        <prototype>
            string buffer_contents = buffer::end_clean()
        </prototype>
        <example>
            $output = buffer::end_clean();
        </example>
    </function>
=cut

sub end_clean {
    return unless @buffers;

    my $start_pos = pop @buffers;

    # get the output of this buffer and remove it from the main buffer
    my $return = substr($buffer, $start_pos, length $buffer, '');

    # move the filehandle back to where this buffer started
    seek($buffer_fh, $start_pos, 0);

    # if this was the last buffer
    unless (@buffers) {
        select $prev_select;
        undef $prev_select;
    }

    # return the output of the buffer
    return $return;
}

=xml
    <function name="end_all_clean">
        <synopsis>
            Ends all output buffers and returns their contents
        </synopsis>
        <note>
            Does nothing if no buffers are active
        </note>
        <prototype>
            string buffer_contents = buffer::end_all_clean()
        </prototype>
        <example>
            $output = buffer::end_all_clean();
        </example>
    </function>
=cut

sub end_all_clean {
    return unless @buffers;

    @buffers = ();

    my $return = $buffer;
    $buffer = '';
    seek($buffer_fh, 0, 0);

    select $prev_select;

    return $return;
}

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
