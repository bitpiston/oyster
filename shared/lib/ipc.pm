=xml
<document title="IPC Functions">
    <synopsis>
        Functions that allow daemons to communicate.  These are mainly used to force
        daemons to reload cached data when one of them updates it.
    </synopsis>
=cut

package ipc;

use exceptions;

our ($last_fetch_id, $insert_ipc, $fetch_ipc, $last_sync_time);

event::register_hook('load_lib', '_ipc_load');
sub _ipc_load {
    my $query = $oyster::DB->query("SELECT id FROM ipc ORDER BY id DESC LIMIT 1");
    $last_fetch_id = $query->rows() == 1 ? $query->fetchrow_arrayref()->[0] : 0 ;
    $insert_ipc    = $oyster::DB->prepare("INSERT INTO ipc (module, function, args, daemon, site) VALUES (?, ?, ?, '$oyster::CONFIG{daemon_id}', ?)");
    $fetch_ipc     = $oyster::DB->prepare("SELECT id, module, function, args FROM ipc WHERE id > ? and (site = '' or site = '$oyster::CONFIG{site_id}') and daemon != '$oyster::CONFIG{daemon_id}'");
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
        <prototype>
            ipc::update()
        </prototype>
        <todo>
            try {}
        </todo>
    </function>
=cut

sub update {
    return if $last_sync_time == -1 or time() - $last_sync_time < $oyster::CONFIG{'sync_time'};
    $fetch_ipc->execute($last_fetch_id);
    while (my $task = $fetch_ipc->fetchrow_arrayref()) {
        my ($id, $module, $func, $args) = @{$task};
        &{ $module . '::' . $func }(split("\0", $args));
        $last_fetch_id = $id;
    }
    $last_sync_time = time();
}

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
