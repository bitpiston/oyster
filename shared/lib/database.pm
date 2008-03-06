=xml
<document title="Database Functions">
    <synopsis>
        Extensions to DBI functionality (mostly driver neutral access to insert_ids
        and prepared statements)
    </synopsis>
=cut

package database;

use exceptions;

push(@DBI::db::ISA, 'oyster::database::dbi::db');
#push(@DBI::st::ISA, 'oyster::database::dbi::st');

sub handle_error {
    throw 'db_error' => $DBI::errstr;
}

=xml
    <function name="connect">
        <synopsis>
            Establishes a database connection and tells it to use Oyster exceptions.
        </synopsis>
        <prototype>
            obj = database::connect(, driver => string driver, host => string hostname, user => string username, password => string password, database => string database)
        </prototype>
    </function>
=cut

sub connect {
    my %args = @_;
    my $DB = DBI->connect(
        "dbi:$args{driver}:dbname=$args{database};host=$args{host};port=$args{port}", $args{'user'}, $args{'password'},
        {
            'RaiseError'  => 0,
            'HandleError' => \&database::handle_error,
        }
    ) or throw 'db_error' => "Could not establish database connection: $DBI::errstr";
    return $DB;
}

=xml
    <function name="compress_metadata">
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

sub compress_metadata {
    return '' if @_ == 0; # sql will expect an empty string

    local $" = "\0"; # use tricky string interpolation instead of join

    return "@{$_[0]}"      if ref $_[0] eq 'ARRAY';
    return "@{[%{$_[0]}]}" if ref $_[0] eq 'HASH';
    return "@_";
}

=xml
    <function name="expand_metadata">
        <synopsis>
            
        </synopsis>
        <note>
            
        </note>
        <prototype>
            
        </prototype>
        <example>
            
        </example>
        <todo>
            
        </todo>
    </function>
=cut

sub expand_metadata {
    return split(/\0/o, $_[0]);
}

=xml
    <section title="Extensions to Database Handles">
=cut

package oyster::database::dbi::db;

use exceptions;

=xml
        <function name="insert_id">
            <synopsis>
                Returns the unique ID of the last row inserted into the database.
            </synopsis>
            <prototype>
                int = $DB->insert_id(string sequence_name)
            </prototype>
        </function>
=cut

sub insert_id {
    my ($DB, $seq) = @_;
    my $driver = $DB->{'Driver'}->{'Name'};

    # MySQL
    return $DB->{'mysql_insertid'}                                              if $driver eq 'mysql';

    # PostgreSQL
    return $DB->last_insert_id(undef, undef, undef, undef, { sequence=> $seq }) if $driver eq 'Pg';
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
                object statement_handle = $DB->server_prepare(string statement)
            </prototype>
        </function>
=cut

sub server_prepare {
    my ($DB, $sql) = @_;
    my $driver = $DB->{'Driver'}->{'Name'};

    # MySQL
    #return $DBH->prepare($sql, { 'mysql_server_prepare' => 1 }) if $driver eq 'mysql';
    return $DB->prepare($sql) if $driver eq 'mysql';

    # PostgreSQL
    return $DB->prepare($sql, { 'pg_server_prepare' => 1 }) if $driver eq 'Pg';
}

=xml
    <function name="query">
        <synopsis>
            Prepares and executes a query in one command, returns the query object
        </synopsis>
        <prototype>
            object statement_handle = $DB->query(string statement[, bind variables]);
        </prototype>
    </function>
=cut

sub query {
    my ($DB, $sql, @args) = @_;
    my $query = $DB->prepare($sql);
    $query->execute(@args);
    return $query;
}

=xml
    </section>
    
    <section title="Extensions to Statement Handles">
=cut

#package oyster::database::dbi::st;

=xml2
    <function name="insert_id">
        <synopsis>
            An alias to $DB->insert_id()
        </synopsis>
    </function>
=cut

#sub insert_id {
#    goto &oyster::database::dbi::db::insert_id;
#}

=xml
    </section>
=cut

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
