=xml
<document title="Math Functions">
    <synopsis>
        Does stuff with numbers.
    </synopsis>
=cut

package math;

=xml
    <function name="floor">
        <synopsis>
            Rounds down
        </synopsis>
        <prototype>
            int = math::floor(int)
        </prototype>
    </function>
=cut

sub floor {
   my $number = shift;
   return int($number);
}

=xml
    <function name="ceil">
        <synopsis>
            Rounds up
        </synopsis>
        <prototype>
            int = math::ceil(int)
        </prototype>
    </function>
=cut

sub ceil {
   my $number = shift;
   return ( ($number == int($number)) ? $number : int($number + 1 * ($number <=> 0)) );
}

=xml
    <function name="round">
        <synopsis>
            Rounds up or down
        </synopsis>
        <prototype>
            int = math::round(int)
        </prototype>
    </function>
=cut

sub round {
   my $number = shift;
   return int($number + .5 * ($number <=> 0));
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2008
