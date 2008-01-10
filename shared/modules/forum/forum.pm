package module::forum;

use orm2;
use base 'orm2::model';

use exceptions;

#
# Meta Data / Model Definition
#

meta {
    #name     'Forum'; # really don't like using this function name, or the idea of having a function associated with every possible meta attribute (although has_* and field are ok)

    #has_many 'module::forum::thread';
    #has_many 'module::forum::permission';
    #has_one  'module::forum::parent';

    field 'name' => {
        type       => 'orm2::field::text',
        validators => {required => 1},
    };
};

#
# Inheritable Methods
#


# returns xml representing this object
sub xml {

}
sub print_xml { print shift()->xml() }

#
# Custom Methods
#

#
# Examples
#

my $id = $forum->get_id_by_name('General');
my @threads = $forum->forum::thread::get(limit => 10, offset => 20); # this would not work.. no inheritance there...  would it be possible to fake it by importing?
my @threads = forum::thread->get($forum, limit => 10, offset => 20);

1;