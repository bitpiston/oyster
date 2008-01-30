=xml
<document title="IPC Functions">
    <synopsis>
        Functions that allow daemons to communicate.  These are mainly used to force
        daemons to reload cached data when one of them updates it.
    </synopsis>
    <todo>
      Investigate, is there a double-eval going on for the daemon that issues
      the command? -- possibly just store the value of time() instead of using
      sql NOW()  
    </todo>
=cut

package ipc;

our ($ipc_insert_query, $ipc_get_query, $ipc_last_do);

event::register_hook('load_lib', '_ipc_load');
sub _ipc_load {
    $ipc_insert_query = $oyster::DB->server_prepare("INSERT INTO ipc (ctime, command, daemon_id, site_id) VALUES (UTC_TIMESTAMP(), ?, ?, ?)");
    $ipc_get_query    = $oyster::DB->server_prepare("SELECT command FROM ipc WHERE ctime > FROM_UNIXTIME(?) and (site_id = '$oyster::CONFIG{site_id}' or site_id = '') and daemon_id != '$oyster::CONFIG{daemon_id}' ORDER BY ctime ASC");
    $ipc_last_do      = datetime::gmtime();
}

=xml
    <function name="eval">
        <synopsis>
            Issues a command for all daemons of the current site to execute
        </synopsis>
        <note>
            The command is executed in the 'ipc' package.  Be sure to use
            fully-qualified names for functions and variables.
        </note>
        <prototype>
            ipc::eval(string command)
        </prototype>
        <example>
            ipc::eval('news::_load_labels()');
        </example>
        <example>
            ipc::eval('user::_load_groups()');
        </example>
        <todo>
            this should throw a perl error
        </todo>
    </function>
=cut

sub eval {
    my $cmd = shift;

    # execute the command in the current process
    eval "$cmd";
    # TODO: this should throw a perl error
    log::error("Error executing IPC command '$cmd': $@") if $@;

    # do no more unless running in fastcgi mode
    return if ($@ or $oyster::CONFIG{'mode'} ne 'fastcgi');

    # insert this task into the ipc queue
    #log::status("\$ipc_insert_query->execute($cmd, $oyster::CONFIG{daemon_id}, $oyster::CONFIG{site_id})");
    $ipc_insert_query->execute($cmd, $oyster::CONFIG{'daemon_id'}, $oyster::CONFIG{'site_id'});
}

=xml
    <function name="do">
        <synopsis>
            Executes all waiting tasks in the ipc queue
        </synopsis>
        <note>
            This function is not exported by default, to use it you must call it by
            its fully qualified name.
        </note>
        <note>
            Modules should not need to call this function, Oyster performs this
            task automatically.
        </note>
        <prototype>
            ipc::do()
        </prototype>
    </function>
=cut

sub do {

    # do no more unless running in fastcgi mode
    return unless $oyster::CONFIG{'mode'} eq 'fastcgi';

    # fetch and execute any waiting ipc tasks
    $ipc_get_query->execute($ipc_last_do);
    $ipc_last_do = datetime::gmtime();
    while ($task = $ipc_get_query->fetchrow_arrayref()) {
        my $cmd = $task->[0];
        eval "$cmd";
        # TODO: this should throw an exception if the eval fails
    }
}

# Copyright BitPiston 2008
1;
=xml
</document>
=cut

__END__

ipc
    ctime
    module
    args
    daemon
    global
    site

sub _parse_message_args {
    local $" = "\0"; # use tricky string interpolation instead of join

    return "@{$_[0]}"      if ref $_[0] eq 'ARRAY';
    return "@{[%{$_[0]}]}" if ref $_[0] eq 'HASH';
    return "@_"; # this isn't actually used atm...
}

# ipc::message(string module => string message[, 'global' => bool][, 'args' => arrayref])

my $last_fetch_time = $DB->query("SELECT UTC_TIMESTAMP()")->fetchrow_arrayref()->[0];
my $insert_ipc      = $DB->prepare("INSERT INTO ipc (ctime, module, args, daemon, global, site) VALUES (UTC_TIMESTAMP(), ?, ?, '$oyster::daemon_id', ?, '$oyster::CONFIG{site_id}')");
my $fetch_ipc       = $DB->prepare("SELECT module, args, UTC_TIMESTAMP() as now FROM ipc WHERE ctime > ? and (global = '1' or site = '$oyster::CONFIG{site_id}') and daemon != '$oyster::daemon_id'");

sub message {

    # parse arguments
    my %args = @_;
    my $global = $args{'global'} ? '1' : '0' ; # Pg expects a string
    my $args = "";
    $args = _parse_message_args($args{'args'}) if exists $args{'args'};

    # ensure that the destination module is prepared to accept ipc
    throw 'perl_error' => "IPC failure: destination module '$args{module}' cannot handle IPC." unless UNIVERSAL::can($args{'module'}, 'ipc');

    # execute it immediately in this daemon
    &{"$args{module'}::ipc"}(split("\0", $args));

    # insert the request into the database
    $insert_ipc->execute($args{'module'}, $args, $global);
}

sub do {
    $fetch_ipc->execute($last_fetch_time);
    while (my $msg = $fetch_ipc->fetchrow_arrayref()) {
        my ($module, $args) = @{$msg};
        &{"$args{module'}::ipc"}(split("\0", $args));
        $last_fetch_time = $msg->[2];
    }
}


