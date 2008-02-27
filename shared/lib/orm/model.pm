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
sub get {
    my ($class, $limit, $offset, $where, @where_values, @columns) = (shift(), ' LIMIT 1');
    my $model = ${ $class . '::model' };

    # parse arguments
    while (@_) {
        my $arg = shift;

        # where clauses
        if ($arg eq 'where') {
            @where_values = @{ shift() };
            $where        = ' WHERE ' . shift @where_values;
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
            push @columns, $arg;
        }
    }

    # prepare and execute the query
    my $columns = @columns == 0 ? '*' : join(', ', @columns) ;
    my $query   = $oyster::DB->query("SELECT $columns FROM $model->{table}$where$limit$offset");

    # if no rows were returned
    return if $query->rows() == 0;

    # if limit was not 1 (a result set is expected)
    return orm::result_set::new($class, $model, $query) if ($limit ne ' LIMIT 1');

    # a single row object should be returned
    return $class->new_from_db($query);
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
        #package ${pkg}::object;
        #use base 'orm::object';
        push @${pkg}::object::ISA, 'orm::object';
    ~;
}

sub AUTOLOAD {
    my $obj      = shift;
    my ($method) = ($AUTOLOAD =~ /::(.+?)$/o);

    # dynamic select
    
    # dynamic update

    # nothing matched...
    throw 'perl_error' => "Invalid dynamic method '$method' called on ORM object '" . ref($obj) . "'.";
}

sub DESTROY {

}

1;