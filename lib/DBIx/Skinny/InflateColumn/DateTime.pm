package DBIx::Skinny::InflateColumn::DateTime;

use strict;
use warnings;
our $VERSION = '0.01';

use DateTime;
use DateTime::Format::Strptime;
use DateTime::Format::MySQL;
use DateTime::TimeZone;

sub import {
    my $timezone = DateTime::TimeZone->new(name => 'local');
    my $schema = caller;
    for my $rule ( qw(^.+_at$ ^.+_on$) ) {
        $schema->inflate_rules->{ $rule }->{ inflate } = sub {
            my $value = shift or return;
            return $value if ref $value eq 'DateTime';
            my $dt = DateTime::Format::Strptime->new(
                pattern   => '%Y-%m-%d %H:%M:%S',
                time_zone => $timezone,
            )->parse_datetime($value);
            return DateTime->from_object( object => $dt );
        };
        $schema->inflate_rules->{ $rule }->{ deflate } = sub {
            my $value = shift;
            return DateTime::Format::MySQL->format_datetime($value);
        };
    }
    my $schema_info = $schema->schema_info;
    my $now = DateTime->now(time_zone => $timezone);
    push @{ $schema->common_triggers->{ pre_insert } }, sub {
        my ($self, $args, $table) = @_;
        my $columns = $schema_info->{ $table }->{ columns };
        for my $key ( qw/created_at created_on updated_at updated_on/ ) {
            $args->{$key} ||= $now if grep {/^$key$/} @$columns;
        }
    };
    push @{ $schema->common_triggers->{ pre_update } }, sub {
        my ($self, $args, $table) = @_;
        my $columns = $schema_info->{ $table }->{ columns };
        for my $key ( qw/updated_at updated_on/ ) {
            $args->{$key} ||= $now if grep {/^$key$/} @$columns;
        }
    };
}

1;
__END__

=head1 NAME

DBIx::Skinny::InflateColumn::DateTime - DateTime inflate/deflate and auto insert update time for DBIx::Skinny

=head1 SYNOPSIS

Use this module in your schema.

  package Your::DB::Schema;
  use DBIx::Skinny::Schema;
  use DBIx::Skinny::InflateColumn::DateTime;

  install_table table1 => {
      pk 'id';
      columns qw/id name created_at updated_at/;
  };

  install_table table2 => {
      pk 'id';
      columns qw/id name booked_on created_on updated_on/;
  };

In your app.

  my $row = Your::DB->single('table1', { id => 1 });
  print $row->created_at->ymd;  # created_at is DateTime object

=head1 DESCRIPTION

DBIx::Skinny::InflateColumn::DateTime provides inflate/deflate settings for *_at/*_on columns.

It also set trigger for pre_insert and pre_update.

Its concept refer to DBIx::Class::InflateColumn::DateTime, and some factor from DBIx::Class::InflateColumn::DateTime::Auto (http://blog.hide-k.net/archives/2006/08/dbixclassauto_i.php).

=head1 INFLATE/DEFLATE

This module installs inflate rule for /_(at|on)$/ columns.

That columns will be inflated as DateTime objects.

=head1 TRIGGERS

=head2 pre_insert

Set current time stamp for created_at, created_on, updated_at and updated_on if column exists.

=head2 pre_update

Set current time stamp for updated_at and updated_on if column exists.

Row object's columns will be updated as well.

=head1 AUTHOR

Ryo Miyake E<lt>ryo.studiom {at} gmail.comE<gt>

=head1 SEE ALSO

DBIx::Skinny, DBIx::Class::InflateColumn::DateTime

http://blog.hide-k.net/archives/2006/08/dbixclassauto_i.php

=head1 AUTHOR

Ryo Miyake  C<< <ryo.studiom@gmail.com> >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
