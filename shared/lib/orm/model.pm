package orm::model;

use exceptions;

sub new {
    goto &orm::object::new;
}

sub new_from_db {
    goto &orm::object::new_from_db;
}

# this should never be called directly, only via the auto-generated imported get()'s
# is that true? this would work fine as long as it was called as a method

# prototype: get([array columns][, limit => int limit][, offset => int offset][, where => [string where_clause, array where_placeholder_values]])
# note: limit defaults to 1, if it is set to anything else, a result set will be returned instead of a single object
# note: arguments can be specified in any order
# note: if a single argument numeric is passed, it is assumed to be get(where => ['id = ?', int object_id])
# note: the where clause can also be a simple string or hashref (assumed AND, not OR) [NYI hashrefs]
# note: if limit is 0, no limit is assumed (use get_all to achieve this)
sub get {
    my ($class, $limit, $offset, $where, @where_values, @columns) = (shift(), ' LIMIT 1');
    my $model = ${ $class . '::model' };

    # if there is only one argument, and it's a number, they just want to fetch by ID
    $where = ' WHERE id = ' . shift() if (@_ == 1 && $_[0] !~ /[^0-9]/o);

    # parse arguments
    while (@_) {
        my $arg = shift;

        # where clauses
        if ($arg eq 'where') {
            if (ref $_[0] eq 'ARRAY') {
                @where_values = @{ shift() };
                $where        = ' WHERE ' . shift @where_values;
            } elsif (ref $_[0] eq 'HASH') {
                # TODO
            } else {
                $where = ' WHERE ' . shift();
            }
        }

        # offset
        elsif ($arg eq 'offset') {
            $offset = ' OFFSET ' . shift();
        }

        # limit
        elsif ($arg eq 'limit') {
            my $num = shift;
            $limit = $num == 0 ? '' : " LIMIT $num" ;
        }

        # the argument is a column name
        else {
            push @columns, $arg if $arg ne 'id'; # do NOT add the id column here, otherwise we'd have to grep for it later to ensure we don't add it twice
        }
    }
    unshift @columns, 'id' if @columns != 0;

    # prepare and execute the query
    my $columns = @columns == 0 ? '*' : join(', ', @columns) ;
    my $query   = $oyster::DB->query("SELECT $columns FROM $model->{table}$where$limit$offset", @where_values);

    # if no rows were returned
    return if $query->rows() == 0;

    # if limit was not 1 (a result set is expected)
    return orm::object::set::new($class, $model, $query) if $limit ne ' LIMIT 1';

    # a single row object should be returned
    return $class->new_from_db($query->fetchrow_hashref());
}

sub import {
    my $pkg = $_[0] ne 'orm::model' ? $_[0] : caller() ;
    return if $pkg eq 'orm'; # don't import into orm.pm -- it's just pulling in all of the orm stuff

    eval qq~
        sub ${pkg}::get {
            unshift \@_, '$pkg';
            goto &orm::model::get;
        }
        sub ${pkg}::get_all {
            unshift \@_, '$pkg', 'limit', 0;
            goto &orm::model::get;
        }
        push \@${pkg}::object::ISA, 'orm::object';
    ~;
}

sub AUTOLOAD {
    my $obj      = shift;
    my ($method) = ($AUTOLOAD =~ /([^:]+)$/o);

    # dynamic select
    
    # dynamic update

    # dynamic delete

    # nothing matched...
    throw 'perl_error' => "Invalid dynamic method '$method' called on ORM object '" . ref($obj) . "'.";
}

sub DESTROY {

}

1;