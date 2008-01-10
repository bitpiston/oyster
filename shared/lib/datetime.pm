=xml
<document title="Date &amp; Time Functions">
    <synopsis>
        Functions associated with retreiving, calculating, or formatting the date
        and time.
    </synopsis>
    <todo>
        add a wrapper for Time::HiRes so that it can be made optional (just
        fallback to time() if Time::HiRes isn't available, and put 'less than one
        second' for times less than a second)
    </todo>
=cut

package datetime;

our @formats;
event::register_hook('load_lib', '_load');
sub _load {

    # reset data structure
    @formats = ();

    # fetch formats from the db and store them
    my $query = $oyster::DB->query("SELECT format FROM date_formats");
    while (my $format = $query->fetchrow_arrayref()) {
        push @formats, $format->[0];
    }
}

=xml
    <function name="is_valid_format">
        <synopsis>
            Checks if a given string is a valid date format
        </synopsis>
        <todo>
            bool = datetime::is_valid_format(string format)
        </todo>
    </function>
=cut

sub is_valid_format {
    my $format = shift;
    return grep(/^\Q$format\E$/, @formats) ? 1 : 0 ;
}

=xml
    <function name="print_date_formats_xml">
        <synopsis>
            Prints available date formats in an xml-friendly manner
        </synopsis>
        <prototype>
            datetime::print_date_formats_xml()
        </prototype>
    </function>
=cut

sub print_date_formats_xml {
    print "\t\t<date_formats>\n";
    for my $format (@formats) {
        print "\t\t\t<format>$format</format>\n";
    }
    print "\t\t</date_formats>\n";
}

=xml
    <function name="days_in_month">
        <synopsis>
            Returns the number of days in a given month
        </synopsis>
        <note>
            Month is 1-12, NOT 0-11.
        </note>
        <prototype>
            int num_days = datetime::days_in_month(int year, int month)
        </prototype>
        <example>
            my $num_days = datetime::days_in_month(2006, 5);
        </example>
    </function>
=cut

sub days_in_month {
    my ($self, $year, $month) = @_;
    if ($month == 2) {
        return (($year % 4) == 0 and (($year % 400) == 0 or ($year % 100) != 0)) ? 29 : 28;
    } elsif ($month >= 8) {
        return $month % 2 == 1 ? 30 : 31;
    } else {
        return $month % 2 == 1 ? 31 : 30;
    }
}

=xml
    <function name="utctime">
        <synopsis>
            Returns the unix epoch time in GMT
        </synopsis>
        <note>
            * gmtime is the ideal name for this but it is taken by perl
        </note>
        <prototype>
            int = datetime::utctime()
        </prototype>
        <example>
            my $gmtime = datetime::utctime();
        </example>
        <todo>
            deprecate in favor of gm_time() or even datetime::gmtime()
        </todo>
    </function>
=cut

sub utctime {
    return ( time() - ( $oyster::CONFIG{'time_offset'} * 3600) );
}

=xml
    <function name="is_valid_time_offset">
        <synopsis>
            Returns true if a given string is a valid time offset, false otherwise
        </synopsis>
        <prototype>
            bool = datetime::is_valid_time_offset(int time_offset)
        </prototype>
    </function>
=cut

sub is_valid_time_offset {
    my $time_offset = shift;
    return if ($time_offset < -12 or $time_offset > 13 or $time_offset !~ /^-?\d\d?$/); # Most sites seem to only allow +-12, but I saw +13 on some random tiny region
    return 1;
}

=xml
    <function name="get_gmt_offset">
        <synopsis>
            Calculates the GMT offset of the server
        </synopsis>
        <prototype>
            int time_offset = datetime::get_gmt_offset()
        </prototype>
        <todo>
            Possibly allow the passing of the time to perform the check at instead
            #     of just using the return value of time().  This would be useful to test
            #     cases where days or years may be different.
        </todo>
    </function>
=cut

sub get_gmt_offset {
    my $time = time(); # ensure that both localtime() and gmtime() are given the same time, in case the second switches between calls
    my ($local_hour, $local_year, $local_yday, $local_is_dst) = (localtime($time))[2, 5, 7, 8];
    my ($gm_hour, $gm_year, $gm_yday)                         = (gmtime($time))[2, 5, 7];

    # compensate for dst (gmt doesn't have it)
    $local_hour-- if $local_is_dst;

    # compensate for different days and years
    if ($local_year == $gm_year) {
        if ($local_yday > $gm_yday) {
            $local_hour += 24;
        } elsif ($local_yday < $gm_yday) {
            $local_hour -= 24;
        }
    } elsif ($local_year > $gm_year) {
        $local_hour += 24;
    } elsif ($local_year < $gm_year) {
        $local_hour -= 24;
    }

    return $local_hour - $gm_hour;
}

=xml
    <function name="from_unixtime">
        <synopsis>
            emulates mysql's FROM_UNIXTIME() function
        </synopsis>
        <note>
            This expects a unix epoch timestamp with the server's current offset
        </note>
        <prototype>
            string mysql_datetime = datetime::from_unixtime(int unix_time)
        </prototype>
    </function>
=cut

sub from_unixtime {
    my ($sec, $min, $hour, $day, $mon, $year) = gmtime(shift());
    $mon++;
    $year += 1900;
    $mon  = '0' . $mon  unless length $mon  == 2;
    $day  = '0' . $day  unless length $day  == 2;
    $hour = '0' . $hour unless length $hour == 2;
    $min  = '0' . $min  unless length $min  == 2;
    $sec  = '0' . $sec  unless length $sec  == 2;
    return "$year-$mon-$day $hour:$min:$sec";
}

=xml
    <function name="from_unixtime_gmt">
        <synopsis>
            emulates mysql's FROM_UNIXTIME() function
        </synopsis>
        <note>
            This expects a unix epoch timestamp in gmt
        </note>
        <prototype>
            string mysql_datetime = datetime::from_unixtime_gmt(int unix_time)
        </prototype>
    </function>
=cut

sub from_unixtime_gmt {
    my ($sec, $min, $hour, $day, $mon, $year) = localtime(shift());
    $mon++;
    $year += 1900;
    $mon  = '0' . $mon  unless length $mon  == 2;
    $day  = '0' . $day  unless length $day  == 2;
    $hour = '0' . $hour unless length $hour == 2;
    $min  = '0' . $min  unless length $min  == 2;
    $sec  = '0' . $sec  unless length $sec  == 2;
    return "$year-$mon-$day $hour:$min:$sec";
}

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
