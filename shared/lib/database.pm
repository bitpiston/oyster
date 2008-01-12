=xml
<document title="Database Functions">
    <synopsis>
        Extensions to DBI functionality (mostly driver neutral access to insert_ids
        and prepared statements)
    </synopsis>
=cut

package database;

use exceptions;

our $current_query;

=xml
    <function name="connect">
        <synopsis>
            Establishes a database connection and tells it to use Oyster exceptions.
        </synopsis>
        <note>
            If any arguments are undefined, they will be assumed from the Oyster
            configuration.
        </note>
        <note>
            If a ref is passed, will use that as the $DB object instead of creating
            a new one.
        </note>
        <prototype>
            obj = database::connect([, driver => string driver][, host => string hostname][, user => string username][, password => string password][, database => string database])
        </prototype>
    </function>
=cut

sub connect {
    my %args = @_;
    my $DB = DBI->connect(
           "dbi:$args{driver}:dbname=$args{database};host=$args{host};port=$args{port}", $args{'user'}, $args{'password'}, {            'AutoCommit'  => 1,
            'RaiseError'  => 0,
            'HandleError' =>
                sub {
                    my $error = $DBI::errstr;
                    $error .= "\nQuery [$database::current_query]\n" if defined $database::current_query;
                    #throw 'db_error' => $DBI::errstr;
                    throw 'db_error' => $error;
                }
        }
    ) or throw 'db_error' => "Could not establish database connection: $DBI::errstr";
    return $DB;
}

#use event;

# import stuff into the right places in DBI
# REMOVED: otherwise scripts that do not 'load_libs' do not get these methods!
#event::register_hook('load_lib', '_load', 200);
#sub _load {
    push(@DBI::db::ISA, 'oyster::database::dbi::db');
    push(@DBI::st::ISA, 'oyster::database::dbi::st');
#}

=xml
    <section title="Extensions to Database Handle">
=cut

package oyster::database::dbi::db;

use exceptions;

=xml
        <function name="insert_id">
            <synopsis>
                Returns the unique ID of the last row inserted into the database.
            </synopsis>
            <prototype>
                int = $DBH->insert_id(string sequence_name)
            </prototype>
        </function>
=cut

sub insert_id {
    my ($DB, $seq) = @_;

    # MySQL
    return $DB->{'mysql_insertid'}                                              if $oyster::CONFIG{'database'}->{'driver'} eq 'mysql';

    # PostgreSQL
    return $DB->last_insert_id(undef, undef, undef, undef, { sequence=> $seq }) if $oyster::CONFIG{'database'}->{'driver'} eq 'Pg';
}

=xml
        <function name="server_prepare">
            <synopsis>
                Prepares a query and caches it server side.
            </synopsis>
            <note>
                This calls ordinary prepare() on mysql, its DB driver does not allow
                specifying it per-query, only per connection.
            </note>
            <prototype>
                object statement_handle = $DBH->server_prepare(string statement)
            </prototype>
        </function>
=cut

sub server_prepare {
    my ($DB, $sql) = @_;

    # MySQL
    #return $DBH->prepare($sql, { 'mysql_server_prepare' => 1 }) if $oyster::CONFIG{'database'}->{'driver'} eq 'mysql';
    return $DB->prepare($sql) if $oyster::CONFIG{'database'}->{'driver'} eq 'mysql';

    # PostgreSQL
    return $DB->prepare($sql, { 'pg_server_prepare' => 1 }) if $oyster::CONFIG{'database'}->{'driver'} eq 'Pg';
}

=xml
    <function name="query">
        <synopsis>
            Prepares and executes a query in one command, returns the query object
        </synopsis>
        <prototype>
            object statement_handle = $DBH->query(string statement[, bind variables]);
        </prototype>
    </function>
=cut

sub query {
    my ($DB, $sql, @args) = @_;
    $database::current_query = $sql;
    my $query = $DB->prepare($sql);
    $query->execute(@args);
    undef $database::current_query;
    return $query;
}

=xml
    </section>
    
    <section title="Extensions to Statement Handles">
=cut

package oyster::database::dbi::st;

=xml
    <function name="insert_id">
        <synopsis>
            An alias to $DBH->insert_id()
        </synopsis>
    </function>
=cut

sub insert_id {
    goto &oyster::database::dbi::db::insert_id;
}

=xml
    </section>
=cut

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
