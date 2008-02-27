
package orm;

use orm::object;
use orm::object::set;
use orm::model;
use orm::field::type;
use orm::field::type::hash_fast;
use orm::field::type::metadata;
use orm::field::type::url;
use orm::field::type::sql::bool;
use orm::field::type::sql::int;
use orm::field::type::sql::varchar;

sub import {
    return unless $_[1] eq 'model';
    my $pkg = $_[0] ne 'orm' ? $_[0] : caller() ;
    orm::model::import($pkg);
    push @{ $pkg . '::ISA' }, 'orm::model';
}

1;

__END__

#
# Base ORM Class
#

# Note: the meta datastructure is full of circ refs, need to do something for gc

package orm;

use exceptions;

require Exporter;
@ISA = qw(Exporter);

our %meta;

push @EXPORT, 'meta';
sub meta(&) {
    my $model = (caller())[0];

    # clear this model's meta data
    delete $meta{$model};

    # execute the meta definition block
    $_[0]->();

    # create cache tables and whatnot

    # created a list of field names ordered from longest to shortest -- for AUTOLOAD matching
    cache_autoload_column_list($model);

    # validate meta data
    validate_relations($model);
}

push @EXPORT, 'has_one';
sub has_one {
    my $has_one = shift;
    my $model = (caller())[0];
    throw 'validation_error' => "Model '$model' meta: has_one must provide a model name." unless length $has_one;
    $meta{$model}->{'has_one'}->{$has_one} = 1;
    $meta{$has_one}->{'relations'}->{$model} = $meta{$model}; # this ref is probably unnecessary...
}

push @EXPORT, 'has_many';
sub has_many {
    my $has_many = shift;
    my $model = (caller())[0];
    throw 'validation_error' => "Model '$model' meta: has_many must provide a model name." unless length $has_many;
    $meta{$model}->{'has_many'}->{$has_many} = 1;
    $meta{$has_many}->{'relations'}->{$model} = $meta{$model};
}

push @EXPORT, 'field';
sub field {
    my $attrs = shift;
    my $model = (caller())[0];
    my $id    = $attrs->{'id'};
    throw 'validation_error' => "Model '$model' attempted to create a field without an ID."     unless length $id;
    throw 'validation_error' => "Model '$model' cannot have two fields with the same ID '$id'." if exists $meta{$model}->{'fields'}->{$id};
    $meta{$model}->{'fields'}->{$id} = $attrs;
    push @{$meta{$model}->{'ordered_fields'}}, $attrs;
}

sub validate_relations {
    my $model = shift;


}

sub cache_autoload_column_list {
    my $model = shift;
    $meta{$model}->{'autoload_column_list'} = [sort { length $a <=> length $b } keys %{ $meta{$model}->{'fields'} }];
}

#
# Base ORM Model Class
#

package orm::model;

use exceptions;

require Exporter;
@ISA = qw(Exporter);

sub new {
    my $class = shift;
    return bless {
        
    }, $class;
}

push @EXPORT, 'get';
sub get {
    my $where;
    my @where_values;
    my @columns;
    my $offset = 0;

    # parse arguments
    while (@_) {
        my $arg = shift;

        # where clauses
        if ($arg eq 'where') {
            my $arg = shift;
            $where = shift @{$arg};
            @where_values = @{$arg};
        }

        # offset
        elsif ($arg eq 'offset') {
            $offset = shift;
        }

        # the argument is a column name
        else {
            push @columns, $arg;
        }
    }

    # prepare and execute the query
    my $columns = @columns ? join(', ', @columns) : '*' ;
    $DB->query("SELECT $columns FROM");

}

sub save {
    
}

sub delete {
    
}

sub xml {

}

sub print_xml {

}

sub AUTOLOAD {
    my $obj   = shift;
    my @args  = @_;
    my $model = ref $obj;
    my ($method) = ($AUTOLOAD =~ /::(.+?)$/);
    my $model_meta = $meta{$model};

    # if this method has been autoloaded already
    if (exists $model_meta->{'autoload_cache'}->{$method}) {
        #
    }

    # figure out wtf to do with this dynamic method dispatch
    else {
        my $string = $method;

        # SELECT
        if ($string =~ s/^(get_|get_all_)//) {
            my @columns; # columns to select

            # figure out which fields they want to fetch (or if they mean *)
            if ($words[1] eq 'where') { # go straight to the where clause
                #noop, fetch all columns
            } else {
                my $string = join('_', @words[ 1 .. $#words ]);
                # TODO: algorithm here!
                # Note: longest-match is ideal for ambiguities, but it will be more computationally expensive (however, autoload caching should make that fairly irrelevant)
                FIND_COLUMNS: while(1) {
                    my $matched = 0;
                    for my $col (@{$model_meta->{'autoload_column_list'}}) {
                        if ($string =~ s/^${col}_//) {
                            $matched = 1;
                            push @columns, $col;
                            last;
                        }
                    }
                    unless ($matched) {
                        throw 'validation_error' => "AUTOLOAD could not figure out how to dispatch dynamic method call '$method' on model '$model' (error matching column list).";
                    }
                    #last FIND_COLUMNS;
                }
            }
        }

        # error
        else {
            throw 'validation_error' => "Invalid dynamic method call '$method' on model '$model'.";
        }
    }
}

1;

__END__

$meta{model_name} = {
    'has_one' => {},
    'has_many' => {},
    'relations' => {},
    'fields' => {},
    'ordered_fields' => [],
    'autoload_cache' => {},
    'autoload_column_list' => [],
};
