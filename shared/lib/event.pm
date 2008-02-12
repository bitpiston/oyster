=xml
<document title="Event Functions">
    <synopsis>
        These functions allow the creation of events that modules can hook into.
    </synopsis>
    <todo>
        The execute* functions are called a lot! Could possibly gain significant speed
        if we used AUTOLOAD and generated a function to run each event dynamically
        with only the code necessary for that event.
    </todo>
=cut

package event;

my %events;
my %hooks;

=xml
    <function name="register_hook">
        <synopsis>
            Registers a sub routine to be called when a certain event is triggered
        </synopsis>
        <note>
            Priority defaults to 50.
        </note>
        <note>
            Use default priority where possible.  Only define an explicit priority
            if absolutely necessary.
        </note>
        <prototype>
            event::register_hook(string event_name, string sub_name[, int priority])
        </prototype>
        <example>
            event::register_hook('load', 'do_some_stuff', 64);
        </example>
        <example>
            sub do_some_stuff {
                log::status('Did some stuff...');
            }
        </example>
        <todo>
            Rename register_hook
        </todo>
    </function>
=cut

sub register_hook {
    my ($event, $sub, $priority) = @_;
    $priority ||= 50;
    my $pkg = caller();

    # add/update hook priority
    $hooks{$event}->{$pkg}->{$sub} = $priority;

    # rebuild $events{$event}
    _rebuild($event);
}

=xml
    <function name="_rebuild">
        <synopsis>
            Rebuilds an event table based on priority
        </synopsis>
        <note>
            This is used internally by the Oyster library, modules should never need
            to call this function.
        </note>
    </function>
=cut

sub _rebuild {
    my $event = shift;
    my %hook_priorities;
    my @hooks;
    for my $pkg (keys %{$hooks{$event}}) {
        for my $sub (keys %{$hooks{$event}->{$pkg}}) {
            $hook_priorities{ $pkg . '::' . $sub } = $hooks{$event}->{$pkg}->{$sub};
            push(@hooks, $pkg . '::' . $sub);
        }
    }
    @hooks = sort {
        $hook_priorities{$b} <=> $hook_priorities{$a}
    } @hooks;
    $events{$event} = \@hooks;
}

=xml
    <function name="destroy">
        <synopsis>
            Destroys a lookup table for a particular event
        </synopsis>
        <note>
            This can be used to free up some memory for events that are only
            signalled once.
        </note>
        <note>
            Once destroyed, the table cannot be restored without reloading Oyster,
            or at the very least, all code that registered any hooks.
        </note>
        <prototype>
            event::destroy(string event_name)
        </prototype>
        <example>
            event::destroy('load');
        </example>
    </function>
=cut

sub destroy {
    my $event = shift;
    delete $hooks{$event};
    delete $events{$event};
}

=xml
    <function name="execute">
        <synopsis>
            Executes all handlers associated with a particular event
        </synopsis>
        <note>
            Any extra arguments are passed to the hook functions.
        </note>
        <note>
            Returns an array containing the return values of all hook functions
            called.
        </note>
        <prototype>
            array return_values = event::execute(string event_name)
        </prototype>
        <example>
            event::execute('load');
        </example>
        <example>
            my @return_values = event::execute('load', 'some argument');
        </example>
        <todo>
            Remove the check that prevents events from executing multiple times per
            request -- it is an artificial limitation created before events were
            expanded so much, replace it with excecute_once().
        </todo>
    </function>
=cut

sub execute {
    my $event = shift;
    return if (exists $oyster::REQUEST{"events_$event"} and $event =~ /^request_/); # dont execute the same event twice in the same request
    my @args  = @_;
    my @return_values;
    for my $func (@{$events{$event}}) {
        push @return_values, &{$func}(@args);
    }
    $oyster::REQUEST{"events_$event"} = undef;
    return @return_values;
}

=xml
    <function name="execute_by_module">
        <synopsis>
            Executes handlers associated with a particular event owned by a particular
            module
        </synopsis>
        <note>
            Any extra arguments are passed to the hook functions.
        </note>
        <note>
            Returns an array containing the return values of all hook functions
            called.
        </note>
        <prototype>
            array return_values = event::execute_by_module(string event_name, string module_id)
        </prototype>
        <example>
            my @return_values = event::execute_by_module('load', 'news', 'some argument');
        </example>
        <todo>
            If the second argument is an array ref, execute the event in multiple
            modules.
        </todo>
    </function>
=cut

sub execute_by_module {
    my $event     = shift;
    my $module_id = shift;
    my @args      = @_;
    my @return_values;
    for my $func (@{$events{$event}}) {
        push @return_values, &{$func}(@args) if $func =~ /^${module_id}::/;
    }
    return @return_values;
}

=xml
    <function name="execute_one">
        <warning>
            Untested
        </warning>
        <prototype>
            array return_values = event::execute_one(string event_name)
        </prototype>
        <todo>
            Documentation
        </todo>
    </function>
=cut

sub execute_one {
    my $event = shift;
    my @args  = @_;
    for my $func (@{$events{$event}}) {
        my @return_values = &{$func}(@args);
        return @return_values if @return_values;
    }
}

=xml
    <function name="module_handles_event">
        <synopsis>
            Returns true if a module has one or more handlers for a particular event
        </synopsis>
        <note>
            If event::destroy() has been called on the specified event, this will
            return false even if the module implements a handler.
        </note>
        <prototype>
            bool = event::module_handles_event(string module_name, string event_name)
        </prototype>
        <example>
            $result = event::module_handles_event('news', 'load');
        </example>
    </function>
=cut

sub module_handles_event {
    my ($module, $event) = @_;
    return $hooks{$event}->{$module} ? 1 : 0 ;
}

=xml
    <function name="delete_module_hooks">
        <synopsis>
            Removes all hooks created by a particular module.
        </synopsis>
        <note>
            Users should rarely need to call this, it is used when unloading or
            reloading a module.
        </note>
        <prototype>
            event::delete_module_hooks(string module_id)
        </prototype>
    </function>
=cut

sub delete_module_hooks {
    my $module_id = shift;
    my %events_to_rebuild;
    for my $event (keys %hooks) {
        for my $pkg (%{$hooks{$event}}) { # TODO: test: is it ok to delete hash entries while iterating over them?
            if ($pkg =~ /^$module_id/) {
                delete $hooks{$event}->{$pkg};
                $events_to_rebuild{$event} = 1;
            }
        }
    }
    _rebuild($_) for keys %events_to_rebuild;
}

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
