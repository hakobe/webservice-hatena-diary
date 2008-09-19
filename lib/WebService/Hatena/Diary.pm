package WebService::Hatena::Diary;
use strict;
use warnings;

use XML::Atom::Entry;
use XML::Atom::Client;
use HTTP::Request;
use DateTime;
use DateTime::Format::W3CDTF;
use DateTime::Format::Strptime;

our $VERSION = '0.01';

sub new {
    my ($class, $args) = @_;

    my $self = bless {
        username  => $args->{username},
        dusername => $args->{dusername} || $args->{username},
        password  => $args->{password},
        mode      => $args->{mode}      || 'blog',
    }, $class;

    my $client = XML::Atom::Client->new;
    $client->username($self->{username});
    $client->password($self->{password});
    $self->{client} = $client;

    return $self;
}

sub api_uri { 
    my ($self) = @_;
    my $api_uri_base = "http://d.hatena.ne.jp/$self->{dusername}/atom/";
    return +{
        blog  => $api_uri_base . "blog/",
        draft => $api_uri_base . "draft/",
    }->{$self->{mode}};
}
sub client  { shift->{client};       }
sub errstr  { shift->client->errstr; }
sub ua      { shift->client->{ua};   }

sub list {
    my ($self) = @_;

    my @entries = map {
        _to_result($_);
    } $self->client->getFeed($self->api_uri)->entries;

    return @entries;
}

sub create {
    my ($self, $args) = @_;

    my $entry = _to_entry($args);

    my $edit_uri = $self->client->createEntry($self->api_uri, $entry);
    return if $self->errstr;

    return $edit_uri;
}

sub retrieve {
    my ($self, $edit_uri) = @_;

    my $entry = $self->client->getEntry($edit_uri);
    return if $self->errstr;

    return _to_result($entry);
}

sub update {
    my ($self, $edit_uri, $args) = @_;

    my $entry = _to_entry($args);

    $self->client->updateEntry($edit_uri, $entry);
    return if $self->errstr;

    return 1;
}

sub delete {
    my ($self, $edit_uri) = @_;

    $self->client->deleteEntry($edit_uri);
    return if $self->errstr;

    return 1;
}

sub publish {
    my ($self, $edit_uri) = @_;
    return if $self->{mode} ne 'draft';

    my $req = HTTP::Request->new(PUT => $edit_uri);
    $req->header('X-HATENA-PUBLISH' => 1);
    my $res = $self->client->make_request($req);
    if ($res->code != 200) {
        $self->client->error("Error on PUT $edit_uri: " . $res->status_line);
        return;
    }
    return 1;
}

my $formatter = DateTime::Format::W3CDTF->new;
my $parser = DateTime::Format::Strptime->new(
    pattern   => '%F',
    time_zone => 'local',
);

sub _to_entry {
    my ($args) = @_;

    my $entry = XML::Atom::Entry->new;
    $entry->title($args->{title})     if $args->{title};
    $entry->content($args->{content}) if $args->{content};
    if ($args->{date}) {
        $entry->updated( 
            $formatter->format_datetime($parser->parse_datetime($args->{date}))
        );
    }

    return $entry;
}

sub _to_result {
    my ($entry) = @_;

    my $result = {};

    $result->{title}    = $entry->title         if $entry->title;;
    $result->{content}  = $entry->content->body if $entry->content;
    $result->{date}     = $parser->parse_datetime($entry->updated)->ymd if $entry->updated;

    my $hatena_syntax = $entry->get('http://www.hatena.ne.jp/info/xmlns#', 'syntax');
    $result->{hatena_syntax} = $hatena_syntax if $hatena_syntax;

    my ($link) = grep { $_->rel eq 'edit' } $entry->link;
    $result->{edit_uri} = $link->href if $link;

    return $result;
}

1;
__END__

=head1 NAME

WebService::Hatena::Diary -

=head1 SYNOPSIS

  use WebService::Hatena::Diary;

=head1 DESCRIPTION

WebService::Hatena::Diary is

=head1 AUTHOR

Yohei Fushii E<lt>hakobe@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
