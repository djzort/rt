#!/usr/bin/perl

use Test::More tests => 36;
use RT;
RT::LoadConfig();
RT::Init();

use strict;
use warnings;

use RT::Tickets;
use RT::Queue;
use RT::CustomField;

# Test Sorting by FreeformSingle custom field.

diag "Create a queue to test with.";
my $queue_name = "CFSortQueue$$";
my $queue;
{
    $queue = RT::Queue->new( $RT::SystemUser );
    my ($ret, $msg) = $queue->Create(
        Name => $queue,
        Description => 'queue for custom field sort testing'
    );
    ok($ret, "$queue test queue creation. $msg");
}

diag "create a CF\n";
my $cf_name = "Order$$";
my $cf;
{
    $cf = RT::CustomField->new( $RT::SystemUser );
    my ($ret, $msg) = $cf->Create(
        Name  => $cf_name,
        Queue => $queue->id,
        Type  => 'FreeformSingle',
    );
    ok($ret, "Custom Field Order created");
}

my ($total, @data, @tickets, @test) = (0, ());

sub add_tix_from_data {
    my @res = ();
    @data = sort { rand(100) <=> rand(100) } @data;
    while (@data) {
        my $t = RT::Ticket->new($RT::SystemUser);
        my %args = %{ shift(@data) };
        my @values = ();
        if ( exists $args{'CF'} && ref $args{'CF'} ) {
            @values = @{ delete $args{'CF'} };
        } elsif ( exists $args{'CF'} ) {
            @values = (delete $args{'CF'});
        }
        $args{ 'CustomField-'. $cf->id } = \@values
            if @values;
        my $subject = join(",", sort @values) || '-';
        my ( $id, undef $msg ) = $t->Create(
            %args,
            Queue => $queue->id,
            Subject => $subject,
        );
        ok( $id, "ticket created" ) or diag("error: $msg");
        push @res, $t;
        $total++;
    }
    return @res;
}

sub run_tests {
    my $query_prefix = join ' OR ', map 'id = '. $_->id, @tickets;
    foreach my $test ( @test ) {
        my $query = join " AND ", map "( $_ )", grep defined && length,
            $query_prefix, $test->{'Query'};

        foreach my $order (qw(ASC DESC)) {
            my $error = 0;
            my $tix = RT::Tickets->new( $RT::SystemUser );
            $tix->FromSQL( $query );
            $tix->OrderBy( FIELD => $test->{'Order'}, ORDER => $order );

            ok($tix->Count, "found ticket(s)")
                or $error = 1;

            my ($order_ok, $last) = (1, $order eq 'ASC'? '-': 'zzzzzz');
            while ( my $t = $tix->Next ) {
                my $tmp;
                if ( $order eq 'ASC' ) {
                    $tmp = ((split( /,/, $last))[0] cmp (split( /,/, $t->Subject))[0]);
                } else {
                    $tmp = -((split( /,/, $last))[-1] cmp (split( /,/, $t->Subject))[-1]);
                }
                if ( $tmp > 0 ) {
                    $order_ok = 0; last;
                }
                $last = $t->Subject;
            }

            ok( $order_ok, "$order order of tickets is good" )
                or $error = 1;

            if ( $error ) {
                diag "Wrong SQL query:". $tix->BuildSelectQuery;
                $tix->GotoFirstItem;
                while ( my $t = $tix->Next ) {
                    diag sprintf "%02d - %s", $t->id, $t->Subject;
                }
            }
        }
    }
}

@data = (
    { },
    { CF => 'a' },
    { CF => 'b' },
);
@tickets = add_tix_from_data();
@test = (
    { Order => "CF.{$cf_name}" },
    { Order => "CF.$queue_name.{$cf_name}" },
);
run_tests();

@data = (
    { },
    { CF => 'aa' },
    { CF => 'ab' },
);
@tickets = add_tix_from_data();
@test = (
    { Query => "CF.{$cf_name} LIKE 'a'", Order => "CF.{$cf_name}" },
    { Query => "CF.{$cf_name} LIKE 'a'", Order => "CF.$queue_name.{$cf_name}" },
);
run_tests();

@data = (
    { Subject => '-', },
    { Subject => 'a', CF => 'a' },
    { Subject => 'b', CF => 'b' },
    { Subject => 'c', CF => 'c' },
);
@tickets = add_tix_from_data();
@test = (
    { Query => "CF.{$cf_name} != 'c'", Order => "CF.{$cf_name}" },
    { Query => "CF.{$cf_name} != 'c'", Order => "CF.$queue_name.{$cf_name}" },
);
run_tests();
