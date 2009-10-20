use strict;
use lib './t';
use FindBin::libs;
use Test::More tests => 22;

use Mock::SQLite;
use Mock::DB;

note 'inflate/deflate test for created_at';
{
    my $book = Mock::DB->single('books', { id => 1 });
    isa_ok $book->created_at, 'DateTime';
    is $book->created_at->ymd, '2009-01-01', 'inflate ok';

    my $dt = $book->created_at;
    $dt->add(months => 2);
    $book->set({ created_at => $dt });
    isa_ok $book->created_at, 'DateTime';
    is $book->created_at->ymd, '2009-03-01', 'updated';

    ok $book->update({ created_at => $dt }), 'deflate ok';
    isa_ok $book->created_at, 'DateTime';
    is $book->created_at->ymd, '2009-03-01', 'updated';

    my $updated = Mock::DB->single('books', { id => 1 });
    isa_ok $updated->created_at, 'DateTime';
    is $updated->created_at->ymd, '2009-03-01', 'updated';
}

note 'inflate test updated_at/created_on/updated_on';
{
    my $book = Mock::DB->single('books', { id => 2 });
    isa_ok $book->updated_at, 'DateTime';
    is $book->updated_at->ymd, '2009-01-02', 'inflate ok';

    my $author = Mock::DB->single('authors', { id => 1 });
    isa_ok $author->created_on, 'DateTime';
    isa_ok $author->updated_on, 'DateTime';
    is $author->created_on->ymd, '2009-02-01', 'inflate ok';
    is $author->updated_on->ymd, '2009-02-02', 'inflate ok';
}

note 'pre_insert trigger';
{
    my $timezone = DateTime::TimeZone->new(name => 'local');
    my $now = DateTime->now(time_zone => $timezone)->epoch;

    my $params = {
        id        => 4,
        author_id => 1,
        name      => 'book4',
    };
    my $book = Mock::DB->insert('books', $params);
    ok $book->created_at->epoch >= $now, 'created_at auto insert ok';
    ok $book->updated_at->epoch >= $now, 'updated_at auto insert ok';

    $params = {
        id   => 3,
        name => 'Kate',
    };
    my $author = Mock::DB->insert('authors', $params);
    ok $author->created_on->epoch >= $now, 'created_on auto insert ok';
    ok $author->updated_on->epoch >= $now, 'updated_on auto insert ok';
}

note 'pre_update trigger';
{
    my $timezone = DateTime::TimeZone->new(name => 'local');
    my $now = DateTime->now(time_zone => $timezone)->epoch;

    my $book = Mock::DB->single('books', { id => 2 });
    my $old_time = $book->updated_at->epoch;
    ok $old_time < $now, 'record updated in the past ';
    $book->update;
    is $book->updated_at->epoch, $now, 'row updated_at was updated';

    my $new_book = Mock::DB->single('books', { id => 2 });
    ok $new_book->updated_at->epoch >= $now, 'updated_at auto insert ok';
}
