=xml
<document title="Exception Handling Functions">
    <synopsis>
        Functions that allow errors to be handled and trapped.
    </synopsis>
    <todo>
        Handle modules that throw stringifiable objects (use Error;)
    </todo>
    <todo>
        FIXME! If an exception is thrown from a catch block, it should NOT be thrown from the same level it was caught, but one below
    </todo>
=cut

package exceptions;

# override perl's die() with something that logs the error
*CORE::GLOBAL::die = sub {
    my $error = @_ ? shift : $@ ; # for some reason certain deaths don't pass their error string (base::import... aka a problem during use module;)
    chomp($error);
    if (%REQUEST) {
        require Data::Dumper;
        $error .= "\nREQUEST:\n" . Data::Dumper::Dumper(%REQUEST);
    }
    log::error('Died: '  . $error);
    print STDERR "Fatal Error:\n$error\n";
    CORE::exit;
};

# ensure the launcher's temporary die() function is overridden
# TODO: is this necessary? does it work?
*launcher::die = \&CORE::GLOBAL::die;

our @stack; # stores a handlers for try blocks

=xml
    <function name="throw">
        <synopsis>
            Throws an exception to be caught by a catch handler.
        </synopsis>
        <note>
            The perl here is can be pretty tough to understand, it is heavily
            documented!
        </note>
        <note>
            "=&gt;" is just syntactic sugar, you can use "," too.
        </note>
        <note>
            Handlers are executed in the scope of where the exception was thrown
            from, this is a byproduct of how the exception system works (handlers
            can choose to abort or not)
        </note>
        <note>
            Exceptions thrown from inside handlers are treated as if the exception
            was thrown from the same scope that the original exception came from.
        </note>
        <prototype>
            throw(string exception_type[ =&gt; arguments to be passed to exception handler])
        </prototype>
        <example>
            throw('validation_error', 'Title is too short') if length($INPUT{'title'}) &lt; 5;
        </example>
        <example>
            throw 'validation_error' =&gt; 'Title is too short' if length $INPUT{'title'} &lt; 5;
        </example>
    </function>
=cut

sub throw {
    my $exception = shift;   # the name of the exception thrown
    my $i         = $#stack; # iterator for stack
    my $caught    = 0;       # true if the exception has been caught
    my @args      = @_;      # any args to be passed to the exception handler

#print ">> Exception Thrown: $exception '$args[0]'\n";

    # die if an exception is thrown outside of any try blocks
    CORE::die("Exception thrown outside of a try block:\n$exception\n@args\n") unless @stack;

    # iterate through the stack of try block handlers (starting at the top of the stack)
    while (my $handlers = $stack[$i]) {

        # skip try blocks that do not have a handler for the thrown exception
        next unless $handlers->{$exception};

        # register that the exception was caught
        $caught = 1;

        # execute the handler
        eval { $handlers->{$exception}->(@args) };

        # if an exception was raised while the handler was executing
        if ($@) {

            # if an oyster abort hash was thrown
            if (ref($@) eq 'HASH' and $@->{'oyster'}) {

                # set the 'die until' stack level unless abort(1) was called
                $@->{'until'} = $i unless exists $@->{'until'};

                # forward exception to the try block
                CORE::die($@);
            }

            # if any other error was thrown
            else {
                throw('perl_error', $@); # TODO: is this how we should handle perl errors in handlers?
            }
        }
        last;
    } continue { $i-- }

    # if the error was not caught
    unless ($caught) {

        # if a perl error was not caught, die
        die($args[0]) if $exception eq 'perl_error';

        # error if the exception was not caught
        throw('perl_error', "Exception '$exception' thrown and not caught.");
    }
}

=xml
    <function name="catch">
        <synopsis>
            Executes a block of code, trapping exceptions.  Returns true if the block
            executed successfully without exceptions, false otherwise.
        </synopsis>
        <note>
            If an exception of an unknown type is encountered, it is rethrown as a
            perl_error.
        </note>
        <note>
            Exceptions *must* be caught!  An uncaught exception raises a perl_error.
        </note>
        <note>
            If multiple catch blocks are defined for the same exception type, the
            innermost takes precedence.
        </note>
        <note>
            If an exception is caught further up the stack than it was thrown, the
            handler can either abort at the level it was caught at or the level it
            was thrown at.  See abort() for more information.
        </note>
        <prototype>
            bool success = try { block } [ catch string exception_type, with { block } ... ];
        </prototype>
        <example>
        try {
            print "Hello";
                throw 'error' =&gt; 'something went terribly wrong' if $armageddon;
                print " World\n";
            }
        </example>
        <example>
            catch 'error', with {
               my $msg = shift;
               print "Error: $msg\n";
               abort();
            };
        </example>
    </function>
=cut
  
sub catch     { @_ } # catch and with simply return whatever they were given, and that becomes %handlers in try
sub with(&;@) { @_ }
sub try(&;@)  {
    my($block, %handlers) = @_;

    # add new try block to stack
    push(@stack, \%handlers);

    # execute the try block
    eval { $block->() };

    # if an exception was thrown
    if ($@) {

        # if a perl error was thrown, replace the eval block's result with the result of a thrown perl error
        if (ref $@ ne 'HASH' or !exists $@->{'oyster'}) {
             my $err = $@; # $@ gets reset before the eval {} is executed, need to save it before
             eval { throw('perl_error', $err) };
        }
        # TODO: what happens if another perl error (not a oyster exception) is thrown during that eval?

        # if try blocks are being aborted
        if (defined $@->{'until'}) {

            # if this is the destination try block
            if ($@->{'until'} == $#stack) {
                pop @stack;
                return;
            }

            # this try block is inside the destination try block, pass the exception to the outer try
            elsif ($@->{'until'} < $#stack) {
                pop @stack;
                CORE::die($@);
            }

            # if this is reached, something terribly wrong has happened
            else {
                die("Oyster exception thrown with invalid abort level.  From [$#stack] to [$@->{until}].");
            }
        }

        # abort() was called outside of an exception handler
        else {
            pop @stack;
            return;
        }
    }

    # the block executed successfully
    else {
        pop @stack;
        return 1;
    }
}

=xml
    <function name="abort">
        <synopsis>
            Ends execution of a try block.
        </synopsis>
        <note>
            Calling abort() with no arguments will end all blocks up to where the
            error was caught.
        </note>
        <note>
            Calling abort(1) ends only the most recent try block, regardless of
            where the error was caught.
        </note>
        <note>
            If no try blocks are active, returns false and does nothing.
        </note>
        <note>
            If called outside of a catch block, this will always act as abort(1).
        </note>
        <prototype>
            abort([bool only_current_block])
        </prototype>
    </function>
=cut

sub abort {
    return unless @stack; # do nothing if no try blocks are active
    my $exception = {'oyster' => 1, 'from' => $#stack}; # construct oyster abort hash
    $exception->{'until'} = $#stack if $_[0]; # the optional argument to abort that tells throw() to only abort the current try block, regardless of which caught the exception
    CORE::die($exception);
}


=xml
    <function name="trace">
        <synopsis>
            
        </synopsis>
        <note>
            
        </note>
        <prototype>
            
        </prototype>
        <example>
            
        </example>
    </function>
=cut

sub trace {
    my @stack;
    my $i = 1;
    my $trace = "File                          Line Subroutine\n";
    while (my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller($i)) {
        $filename =~ s!//+!/!g;
        if ($subroutine eq '(eval)' and @stack) {
            my $last_call_frame = pop @stack;
            $subroutine .= ' ' . $last_call_frame->[1];
        }
        push @stack, [$filename, $subroutine, $line];
    } continue { $i++ }
    for my $call_frame (@stack) {
        $trace .= string::pad($call_frame->[0], 29) . ' ' . string::pad($call_frame->[2], 5) . $call_frame->[1]. "\n";
    }

    return $trace;
}

# export exception functions
sub import {
    my $pkg = $_[0] ne 'exceptions' ? $_[0] : caller();

    *{ $pkg . '::try' }     = \&try;
    *{ $pkg . '::catch' }   = \&catch;
    *{ $pkg . '::with' }    = \&with;
    *{ $pkg . '::throw' }   = \&throw;
    *{ $pkg . '::abort' }   = \&abort;
}

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
