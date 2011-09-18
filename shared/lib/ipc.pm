=xml
<document title="IPC Functions">
    <synopsis>
        Functions that allow daemons to communicate.  These are mainly used to force
        daemons to reload cached data when one of them updates it.
    </synopsis>
    <todo>
        Clean up old IPC jobs.
    </todo>
=cut

package ipc;

use exceptions;

our ($last_fetch_id, $insert_ipc, $fetch_ipc, $exists_ipc_periodic, $insert_ipc_periodic, $fetch_ipc_periodic, $update_ipc_periodic, $last_sync_time);

event::register_hook('load_lib', '_ipc_load');
sub _ipc_load {
    my $query = $oyster::DB->query("SELECT id FROM ipc ORDER BY id DESC LIMIT 1");
    $last_fetch_id          = $query->rows() == 1 ? $query->fetchrow_arrayref()->[0] : 0 ;
    $insert_ipc             = $oyster::DB->prepare("INSERT INTO ipc (module, function, args, daemon, site) VALUES (?, ?, ?, '$oyster::CONFIG{daemon_id}', ?)");
    $fetch_ipc              = $oyster::DB->prepare("SELECT id, module, function, args FROM ipc WHERE id > ? and (site = '' or site = '$oyster::CONFIG{site_id}') and daemon != '$oyster::CONFIG{daemon_id}'");
    $exists_ipc_periodic    = $oyster::DB->prepare("SELECT id FROM ipc_periodic WHERE module = ? and function = ? and args = ? and site = ? and `interval` = ? LIMIT 1");
    $insert_ipc_periodic    = $oyster::DB->prepare("INSERT INTO ipc_periodic (module, function, args, site, `interval`, last_exec_time) VALUES (?, ?, ?, ?, ?, ?)");
    $fetch_ipc_periodic     = $oyster::DB->prepare("SELECT id, module, function, args FROM ipc_periodic WHERE (site = '' or site = '$oyster::CONFIG{site_id}') and `interval` <= ? - last_exec_time");
    $update_ipc_periodic    = $oyster::DB->prepare("UPDATE ipc_periodic SET last_exec_time = ? WHERE id = ? LIMIT 1");
    
    # remove old ipc jobs
    #ipc::do_periodic(86400, 'ipc', '_clean_ipc');
}

=xml
    <function name="do">
        <synopsis>
            Issues a command for all daemons of the current site to execute
        </synopsis>
        <note>
            'args' must be simple scalars, refs/objects/filehandles/etc cannot be passed
        </note>
        <prototype>
            ipc::do(string module, string function[, array args])
        </prototype>
        <example>
            ipc::do('news', 'load_category', $category_id);
        </example>
    </function>
=cut

sub do {
    my $site     = ($_[0] eq '~global' and shift) ? '' : $oyster::CONFIG{'site_id'} ;
    my $module   = shift;
    my $function = shift;
    my $args     = join("\0", @_);

    # validate the module and function
    throw 'perl_error' => "IPC failure: destination module '$module' cannot handle function '$function'." unless UNIVERSAL::can($module, $function);

    # execute it immediately in this daemon
    &{ $module . '::' . $function }(@_);

    # insert the request into the database
    $insert_ipc->execute($module, $function, $args, $site);
}

=xml
    <function name="global_do">
        <synopsis>
            Issues a command for all daemons to execute
        </synopsis>
        <note>
            'args' must be simple scalars, refs/objects/filehandles/etc cannot be passed
        </note>
        <prototype>
            ipc::global_do(string module, string function[, array args])
        </prototype>
        <example>
            ipc::global_do('oyster', '_load_config');
        </example>
    </function>
=cut

sub global_do {
    unshift @_, '~global';
    goto &do;
}

=xml
    <function name="do_periodic">
        <synopsis>
            Issues a command for all daemons of the current site to execute at regular intervals (like crontabs or periodic)
        </synopsis>
        <note>
            Intervals are a minimum of every x seconds - not guaranteed every x seconds.
        </note>
        <note>
            Intervals must be specified in seconds.
        </note>
        <note>
            'args' must be simple scalars, refs/objects/filehandles/etc cannot be passed
        </note>
        <prototype>
            ipc::do_periodic(int interval, string module, string function[, array args])
        </prototype>
        <example>
            ipc::do_periodic(86400, 'user', '_clean_sessions');
        </example>
    </function>
=cut

sub do_periodic {
    my $site     = ($_[0] eq '~global' and shift) ? '' : $oyster::CONFIG{'site_id'} ;
    my $interval = shift;
    my $module   = shift;
    my $function = shift;
    my $args     = join("\0", @_);

    # validate the module and function
    throw 'perl_error' => "IPC failure: destination module '$module' cannot handle function '$function'." unless UNIVERSAL::can($module, $function);

    # check if this periodic job is already in the database
    $exists_ipc_periodic->execute($module, $function, $args, $site, $interval);

    # insert the request into the database unless it exists already
    $insert_ipc_periodic->execute($module, $function, $args, $site, $interval, datetime::gmtime) unless $exists_ipc_periodic->rows();
}

=xml
    <function name="update">
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
        <note>
            This uses event::register_hook() to execute at the right times.
        </note>
        <prototype>
            ipc::update()
        </prototype>
        <todo>
            try {}
        </todo>
    </function>
=cut

event::register_hook('request_pre', 'update', 90);
sub update {
    return if $last_sync_time == -1 or time() - $last_sync_time < $oyster::CONFIG{'sync_time'};
    $fetch_ipc->execute($last_fetch_id);
    while (my $task = $fetch_ipc->fetchrow_arrayref()) {
        my ($id, $module, $function, $args) = @{$task};
        &{ $module . '::' . $function }(split("\0", $args));
        $last_fetch_id = $id;
    }
    $last_sync_time = time();
}

=xml
    <function name="update_periodic">
        <synopsis>
            Executes tasks past their scheduled interval
        </synopsis>
        <note>
            This function is not exported by default, to use it you must call it by
            its fully qualified name.
        </note>
        <note>
            Modules should not need to call this function, Oyster performs this
            task automatically.
        </note>
        <note>
            This uses event::register_hook() to execute at the right times.
        </note>
        <prototype>
            ipc::update_periodic()
        </prototype>
        <todo>
            try {}
        </todo>
    </function>
=cut

event::register_hook('request_cleanup', 'update_periodic', 90);
sub update_periodic {
    $fetch_ipc_periodic->execute(datetime::gmtime);
    while (my $task = $fetch_ipc_periodic->fetchrow_arrayref()) {
        my ($id, $module, $function, $args) = @{$task};
        
        # update the last_exec_time before executing the job to prevent other daemons from doing the same thing
        $update_ipc_periodic->execute(datetime::gmtime, $id); 
        
        &{ $module . '::' . $function }(split("\0", $args));
    }
}

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
