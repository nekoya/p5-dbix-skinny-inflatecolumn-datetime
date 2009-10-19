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

DBIx::Skinny::InflateColumn::DateTime -

=head1 SYNOPSIS

  use DBIx::Skinny::InflateColumn::DateTime;

=head1 DESCRIPTION

DBIx::Skinny::InflateColumn::DateTime is

=head1 AUTHOR

Default Name E<lt>default {at} example.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
