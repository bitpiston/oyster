package qdcontent::revisions;

$revision[1]{'up'}{'shared'} = sub {
    module::register('qdcontent');
};

$revision[1]{'up'}{'site'} = sub {
    module::enable('qdcontent');
};

1;
