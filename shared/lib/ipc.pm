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
    $ipc_get_query    = $oyster::DB->server_prepare("SELECT command FROM ipc WHERE ctime > FROM_UNIXTIME(?) and (site_id = '$oyster::CONFIG{site_id}' or site_id = '') and daemon_id != '$oyster::daemon_id' ORDER BY ctime ASC");
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
    #log::status("\$ipc_insert_query->execute($cmd, $oyster::daemon_id, $oyster::CONFIG{site_id})");
    $ipc_insert_query->execute($cmd, $oyster::daemon_id, $oyster::CONFIG{'site_id'});
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
