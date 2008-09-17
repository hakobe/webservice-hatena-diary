use strict;
use warnings;
use Test::More;
use FindBin::libs;
use UNIVERSAL::require;

sub p ($) {
    return unless ($ENV{DEBUG});
    Data::Dumper->use;
    Perl6::Say->use;

    say(Dumper(@_));
}

# From WWW::HatenaDiary's test
my $username  = $ENV{WEBSERVICE_HATENA_DIARY_TEST_USERNAME};
my $dusername = $ENV{WEBSERVICE_HATENA_DIARY_TEST_DUSERNAME} || $username;
my $password  = $ENV{WEBSERVICE_HATENA_DIARY_TEST_PASSWORD};

if ($username && $password) {
    plan tests => 16;
}
else {
    plan skip_all => "Set ENV:WEBSERVICE_HATENA_DIARY_TEST_USERNAME/PASSWORD";
}

use_ok qw(WebService::Hatena::Diary);

my $client = WebService::Hatena::Diary->new({
    username  => $username,
    dusername => $dusername,
    password  => $password,
    mode      => 'draft',
});

isa_ok($client, qw(WebService::Hatena::Diary));

my $now = DateTime->now(time_zone => 'local');
my $edit_uri;
my $entry;
my $input_data = {
    title   => 'test title',
    content => 'test content',
};

# create
$edit_uri = $client->create({
    title   => $input_data->{title},
    content => $input_data->{content},
});
# retrieve
$entry = $client->retrieve($edit_uri);

is($entry->{title},   $input_data->{title});
is($entry->{content}, $input_data->{content});
is($entry->{date},    $now->ymd);


# update
$input_data->{title}   .= ' updated';
$input_data->{content} .= ' updated';
$client->update($edit_uri, {
    title   => $input_data->{title},
    content => $input_data->{content},
});
$entry = $client->retrieve($edit_uri);

is($entry->{title},   $input_data->{title});
is($entry->{content}, $input_data->{content});
is($entry->{date},    $now->ymd);


# list
sleep 3; # wait for create
my @entries = $client->list;
$entry = $entries[0];
is($entry->{edit_uri}, $edit_uri);
is($entry->{title},    $input_data->{title});
is($entry->{content},  $input_data->{content});
is($entry->{date},     $now->ymd);


# delete
$client->delete($edit_uri);
$entry = $client->retrieve($edit_uri);
ok(!$entry);
$client->client->{_errstr} = ''; # errorをクリア


# create for publish
$edit_uri = $client->create({
    title   => $input_data->{title},
    content => $input_data->{content},
});

# publish
$client->publish($edit_uri);
$client->{mode} = 'blog'; # blogモード

$entry = ($client->list)[0];
is($entry->{title},     $input_data->{title});
like($entry->{content}, qr/$input_data->{content}/);
is($entry->{date},      $now->ymd);

$client->{mode} = 'draft'; # draftモード

