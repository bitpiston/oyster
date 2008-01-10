
# an attempt to port Digest::JHash to perl... doesn't currently work...

package Digest::JHash;

use bigint;

our $DEBUG = 0;

# returns a value as if it were an unsigned long int
sub _unsigned_long {
    my $int = shift;
    return $int % (2**32);
}

# returns a value as if it were an unsigned short int
sub _unsigned_short {
    my $int = shift;
    return $int % (2**16);
}

# makes a perl scalar into its unsigned long int equivalent
sub _unsign_long {
    ${$_[0]} = _unsigned_long(${$_[0]});
}

# TODO: there's gotta be a better way than all these unsign_long() calls...
sub _mix { # WORKING! i think.
    my ($a, $b, $c) = @_;

    _unsign_long(\$a, \$b, \$c); # necessary?

    print "MIXING: $a, $b, $c\n";

    print "1. ";
    $a -= $b; _unsign_long(\$a); $a -= $c; _unsign_long(\$a); $a ^= ($c>>13); _unsign_long(\$a);
    printf("%s, ", $a);
    $b -= $c; _unsign_long(\$b); $b -= $a; _unsign_long(\$b); $b ^= ($a<<8); _unsign_long(\$b);
    printf("%s, ", $b);
    $c -= $a; _unsign_long(\$c); $c -= $b; _unsign_long(\$c); $c ^= ($b>>13); _unsign_long(\$c);
    printf("%s\n", $c);

    print "2. ";
    $a -= $b; _unsign_long(\$a); $a -= $c; _unsign_long(\$a); $a ^= ($c>>12); _unsign_long(\$a);
    printf("%s, ", $a);
    $b -= $c; _unsign_long(\$b); $b -= $a; _unsign_long(\$b); $b ^= ($a<<16); _unsign_long(\$b);
    printf("%s, ", $b);
    $c -= $a; _unsign_long(\$c); $c -= $b; _unsign_long(\$c); $c ^= ($b>>5); _unsign_long(\$c);
    printf("%s\n", $c);

    print "3. ";
    $a -= $b; _unsign_long(\$a); $a -= $c; _unsign_long(\$a); $a ^= ($c>>3); _unsign_long(\$a);
    printf("%s, ", $a);
    $b -= $c; _unsign_long(\$b); $b -= $a; _unsign_long(\$b); $b ^= ($a<<10); _unsign_long(\$b);
    printf("%s, ", $b);
    $c -= $a; _unsign_long(\$c); $c -= $b; _unsign_long(\$c); $c ^= ($b>>15); _unsign_long(\$c);
    printf("%s\n", $c);

    return $a, $b, $c;
}

sub jhash {
    my $str = shift;
    my (@p, $len, $length, $a, $b, $c);

    # extract the string data and string length from the perl scalar
    my $str2 = $str; # TODO: re-write this algorithm... dont like this temp variable
    while (length($str2)) { push(@p, ord(substr($str2, 0, 1, ''))) }
    $length = $len = length($str);

    # Test for undef or null string case and return 0
    unless ($length) {
        print "Digest::Jhash - Received a null or undef string!\n" if $DEBUG;
        return 0;
    }

# all of the unsigned_* calls below don't change anything

    $a = $b = 0x9e3779b9; # golden ratio suggested by Jenkins
    $c = 0;
    while ($len >= 12) {
        $a += (_unsigned_long($p[0]) + (_unsigned_long($p[1])<<8) + (_unsigned_long($p[2])<<16) + (_unsigned_long($p[3])<<24));
        $b += (_unsigned_long($p[4]) + (_unsigned_long($p[5])<<8) + (_unsigned_long($p[6])<<16) + (_unsigned_long($p[7])<<24));
        $c += (_unsigned_long($p[8]) + (_unsigned_long($p[9])<<8) + (_unsigned_long($p[10])<<16) + (_unsigned_long($p[11])<<24));
        $a, $b, $c = _mix($a, $b, $c);
        splice(@p, 0, 12);
        $len -= 12;
    }
    $c += $length;
    if    ($len == 11) { $c += _unsigned_short($p[10])<<24 }
    elsif ($len == 10) { $c += _unsigned_short($p[9])<<16 }
    elsif ($len == 9)  { $c += _unsigned_short($p[8])<<8 }
    elsif ($len == 8)  { $c += _unsigned_short($p[7])<<24 }
    elsif ($len == 7)  { $c += _unsigned_short($p[6])<<16 }
    elsif ($len == 6)  { $c += _unsigned_short($p[5])<<8 }
    elsif ($len == 5)  { $c += _unsigned_short($p[4]) }
    elsif ($len == 4)  { $c += _unsigned_short($p[3])<<24 }
    elsif ($len == 3)  { $c += _unsigned_short($p[2])<<16 }
    elsif ($len == 2)  { $c += _unsigned_short($p[1])<<8 }
    elsif ($len == 1)  { $c += _unsigned_short($p[0]) }
    $a, $b, $c = _mix($a, $b, $c);

    print "Digest::Jhash - Hash value is $c.\n" if $DEBUG;

    return $c;
}

#use Data::Dumper;
#print Dumper(_mix(100, 200, 300));
#_mix 178907440, 362670365, 1919119969;

print jhash('t');

# Digest::JHash::jhash('t')
# 1732427376

# Digest::JHash::jhash('worldofwarcraftpwnzall')
# 3939028952

1;