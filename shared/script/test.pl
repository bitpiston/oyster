=xml
<document title="Oyster Testing Framework">
    <synopsis>
        This script runs all test scripts and returns the totalled test results.
    </synopsis>
    <todo>
        Add a way to pack multiple tests into one .test file (test if .test
        returns an array ref, if so, treat each item like an individual test)
    </todo>
    <todo>
        A 'how to' doc for creating tests.
    </todo>
=cut
package oyster::script::test;

# variables
our @tests; # hashref with meta data of each test with some extra variables
            # added

# introduction
print "Beginning Test Suite...\n";

# iterate through directories and populate test data
iter_dir('');

# print totals
print_totals();

# functions

# prints a summary of test results
sub print_totals {
    print "\nTest Results:\n";

    # assemble variables
    my $num_tests  = scalar @tests; # total number of tests
    my $num_tested = 0;             # number of tests actually run (not skipped)
    my @failures;                   # an array of failed tests (each value is an index in @tests)
    my $i = 0;
    for my $test (@tests) {
        next if $test->{'skip'};
        $num_tested++;
        push(@failures, $i) unless $test->{'result'};
        $i++;
    }
    my $num_skipped   = $num_tests - $num_tested;
    my $num_failures  = scalar @failures;
    my $num_successes = $num_tested - $num_failures;

    # print results
    print "  $num_tests total tests\n\n";
    print "  $num_tested (" . (sprintf('%.2f', $num_tested / $num_tests) * 100) . "\%) tests run\n";
    print "  $num_skipped (" . (sprintf('%.2f', $num_skipped / $num_tests) * 100) . "\%) tests skipped \n";
    print "  $num_successes (" . (sprintf('%.2f', $num_successes / $num_tested) * 100) . "\%) successes\n";
    print "  $num_failures (" . (sprintf('%.2f', $num_failures / $num_tested) * 100) . "\%) failures\n";
    for my $i (@failures) {
        my $test = $tests[$i];
        print "    $test->{path}tests/$test->{file}\n";
    }
    print "\nTo debug a particular test type: perl (path to test listed above).pl\n" if @failures;
    # might want to reset @tests here in case some day a script runs more than one sequence of tests
}

# iterates through a directory and all sub-directories, testing as necessary and adding data to @tests
sub iter_dir {
    my $path = shift;

    # open directory to iterate over
    my $full_path = "./$path";
    opendir(my $dir, $full_path) or die "Error reading directory './$path':\n$!\n";

    # check if this directory has tests in it, add them to @tests
    my $tests_path = "${full_path}tests/";
    if (-d $tests_path) {
        opendir(my $tests_dir, $tests_path) or die "Error reading test directory '$tests_path':\n$!\n";
        print "\nTesting Directory: $path\n\n";
        while (my $file = readdir($tests_dir)) {
            next unless $file =~ /\.test$/;
            my $test = eval { require "$tests_path$file" };
            die "Error reading test meta data file for test '${path}tests/$file':\n$@\n" if $@;
            $test->{'path'} = $path;                # the relative path of the directory that owns this test
            $test->{'file'} = substr($file, 0, -5); # the name of the file minus the extension
            print "  Running '$test->{name}'...\n";
            print "    $test->{description}\n" if $test->{'description'};
            if ($test->{'skip'}) {
                print "    [ Skipped ]\n";
            } else {
                my $output = `perl $tests_path$test->{file}.pl$test->{args}`;
                $test->{'result'} = $output eq $test->{'output'} ? 1 : 0 ;
                print $test->{'result'} ? "    [ Success ]\n" : "    ! Failure !\n" ;
            }
            push(@tests, $test);
        }
    }

    # iterate through directories in the current directory
    while (my $file = readdir($dir)) {
        next if ($file eq '.' or $file eq '..' or $file eq 'tests' or $file eq '.svn');
        iter_dir("$path$file/") if -d "$full_path$file/";
    }
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2008