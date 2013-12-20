#!/perl/bin/perl
#

#
#
#       --queues <queue name> <queue name>...
#
#       --groups <group name> <group name>...
#
#       --rights <right name> <right name>...
#

# {{{ Modules and config

use strict;
use warnings;

use 5.10.0;

use Getopt::Long;

$|++;

use lib '/opt/rt4/lib';

use RT::Interface::CLI qw(CleanEnv GetCurrentUser loc);

CleanEnv();

use RT;
use RT::Util;
use RT::CurrentUser;
use RT::CustomField;
use RT::User;
use RT::Config;

RT::LoadConfig();

RT::Init();


# }}}

# {{{ Handle commandline options
#

my $opts = {};

$opts->{queues}        = [];
$opts->{groups}        = [];
$opts->{rights}        = [];
$opts->{all_queues}    = 1;
$opts->{all_groups}    = 1;
$opts->{all_rights}    = 1;
$opts->{vertical}      = 1;
$opts->{horizontal}    = 0;

GetOptions( $opts,

                    'conf=s',
                    'list=s',
                    'queues=s{,}',
                    'groups=s{,}',
                    'rights=s{,}',
                    'all_groups!',
                    'all_rights!',
                    'all_queues!',
                    'horizontal!',
                    'vertical!',

);


my $QueuesToCheck     = [];
my $PrincipalsToCheck = [];
my $RightsToCheck     = [];

# {{{ Queues to check
#
if ( scalar @{ $opts->{queues} } ) {

    push @$QueuesToCheck, $_
        for @{ $opts->{queues} };

    $opts->{all_queues} = 0;

}

# }}}

# {{{ Groups to check

# We don't want to mess with rights for the groups with
# 'SuperUser' turned on, so we'll build a list of them and
# omit them while we iterate.
#
my $AdmGroups = RT::Groups->new($RT::SystemUser);
$AdmGroups->LimitToUserDefinedGroups;
$AdmGroups->WithRight( Right => 'SuperUser', Object => $RT::System, IncludeSuperusers => 1, IncludeSystemRights => 1 );

my @exclude_groups;

while ( my $AdmGroup = $AdmGroups->Next ) {
    push @exclude_groups, $AdmGroup->Name;
}


if ( scalar @{ $opts->{groups} } ) {

    for ( @{ $opts->{groups} } ) {

        my $Group = RT::Group->new($RT::SystemUser);

        my ( $code, $msg ) = $Group->LoadUserDefinedGroup( $_ );

        if ( $Group->Name ~~ @exclude_groups || $Group->Name ne $_ ) {
            print "Skipping specified group: $_\n";
        } else {
            push @$PrincipalsToCheck, $Group->PrincipalObj;
        }

    }

    $opts->{all_groups} = 0;

}

if ( $opts->{all_groups} ) {

    $PrincipalsToCheck = [];

    my $Groups = RT::Groups->new($RT::SystemUser);
    $Groups->LimitToUserDefinedGroups;

    while ( my $Group = $Groups->Next ) {
        push @$PrincipalsToCheck, $Group->PrincipalObj
            unless $Group->Name ~~ @exclude_groups;
    }
}

die "Nothing to check...\n"
    unless scalar @$PrincipalsToCheck;


# }}}

# {{{ Rights to check

# If we didn't specify any rights to check, turn on
# the all rights flag.
#
if ( scalar @{$opts->{rights} } ) {

    push @$RightsToCheck, $_
        for @{ $opts->{rights} };

    $opts->{all_rights} = 0;

}


my $RightsMatrixVert = {};
my $RightsMatrix     = {};
my $AvailableRights  = {};
my %QGNames;


# }}}

# }}}

my @report_header = ( 'Queue', 'Group' );
my @report;

my @right_report_header = ( 'Right' );
my @right_report;


if ( defined $opts->{list} ) {

    if ( $opts->{list} =~ m/queue/i ) {

        # Iterate all RT Queues
        #
        my $Qs = RT::Queues->new($RT::SystemUser);

        $Qs->FindAllRows;
        $Qs->UnLimit;

        my @QNames;
        while ( my $Q = $Qs->Next ) {
            push @QNames, $Q->Name;
        }

        print join( "\n", sort @QNames );
        print "\n";
        
    }

} else {

    # Iterate all RT Queues
    #
    my $Qs = RT::Queues->new($RT::SystemUser);

    $Qs->FindAllRows;
    $Qs->UnLimit;

    while ( my $Q = $Qs->Next ) {

        # Skip the current queue if we manually specified
        # queue names to check and the current one isn't on
        # the list.
        #
        if ( ! $opts->{all_queues} ) {
            next unless $Q->Name ~~ @$QueuesToCheck;
        }

        # If we haven't already populated the
        # AvailableRights hashref, do it now.  It's done
        # here because it's easier to do when you've got a
        # queue object ready with a queue loaded.
        #
        unless ( scalar keys %$AvailableRights ) {

            $AvailableRights = $Q->AvailableRights;

            die "Error reading available rights!"
                unless scalar keys %$AvailableRights;

        }

        # If we haven't already populated the list of
        # RightsToCheck from the --rights option, and it
        # hasn't already been populated, with all the
        # available right names, do so now.  It's done here
        # because it's easier to do when you've got a queue
        # object ready with a queue loaded.
        #
        if ( $opts->{all_rights} && scalar @$RightsToCheck != scalar keys %$AvailableRights ) {

            $RightsToCheck = [];
            push @$RightsToCheck, $_ for sort keys %$AvailableRights;

        }

        my $G = RT::Group->new($RT::SystemUser);

        for my $CurPrincipalObj ( @$PrincipalsToCheck ) {

            my $CurGroupName = $CurPrincipalObj->Object->Name;

            my @report_line = ( $Q->Name, $CurGroupName );

            for my $CurRightName ( @$RightsToCheck ) {

                my $HasRight = $CurPrincipalObj->HasRight(Right => $CurRightName, Object => $Q );

                $HasRight ||= ' ';

                $RightsMatrix->{$Q->Name}->{$CurGroupName}->{$CurRightName} = $HasRight;
                $RightsMatrixVert->{$CurRightName}->{ $Q->Name . ':' . $CurGroupName } = $HasRight;

                push @report_line, $HasRight;

            }

            push @report, \@report_line;

        }

    }


    if ( $opts->{vertical} ) {

        push @report_header, $_ for @$RightsToCheck;

        my $report =
            tabulator({    rows => \@report,
                        columns => \@report_header });

        print $$report;

        for my $CurRightName ( sort keys %$RightsMatrixVert ) {

            my @right_report_line = ( $CurRightName );

            my @CurQueueGroupNames = keys %{ $RightsMatrixVert->{$CurRightName} };

            for my $CurQGName ( sort @CurQueueGroupNames ) {

                push @right_report_line, $RightsMatrixVert->{$CurRightName}->{$CurQGName};
                $QGNames{$CurQGName} = undef;

            }

            push @right_report, \@right_report_line;

        }

    } elsif ( $opts->{horizontal} ) {

        push @right_report_header, $_
            for sort keys %QGNames;

        my $right_report =
            tabulator({ rows    => \@right_report,
                        columns => \@right_report_header });

        print $$right_report;

    }

}


# {{{ tabulator
#
# Pretty print some rows in a dynamic width table...
#
# Use an anon hashref to pass in an arrayref of rows and a corresponding
# arrayref of column names.
#
# returns a scalar ref of the rows of the table.
#
sub tabulator {

    my $args = shift;

    my $rows    = $args->{rows};
    my $columns = $args->{columns};

    my $header  =
        defined $args->{header} && $args->{header}
        ? $args->{header}
        : ''
        ;

    my $cols    = scalar(@$columns);
    my $pad     = 2;
    my $widths  = [];

    my @tabbed;

    # Dynamically calculate column widths for our list of messages
    #
    for my $row ( @$rows ) {
        for ( 0..$#$columns ) {
            $widths->[$_] = max( $widths->[$_],  length $row->[$_] );
        }
    }

    # Loop through one more time in case any of our column
    # names are wider than the column data...
    #
    for my $col ( @$columns ) {
        for ( 0..$#$columns ) {
            $widths->[$_] = max( $widths->[$_],  length $columns->[$_] );
        }
    }

    # Create our format string to feed to sprintf...
    #
    my $format = '';
    for ( @$widths ) {
        $format .= "%-${_}s";
        $format .= ' ' x $pad;
    }
    $format .= "\n";

    my $dashes = [];

    # Underline the column names.
    #
    for ( 0..$#$columns ) {
        push @$dashes, '-' x $widths->[$_];
    }

    unshift( @$rows, $dashes );
    unshift( @$rows, $columns );

    # Now turn each row into a dynamically constructed
    # tabular report and pass it back...
    #
    my $formatted_text;
    for ( @$rows ) {
        $formatted_text .= sprintf( $format, @$_ );
    }

    return \$formatted_text;

} # }}}

# {{{ max
#
sub max {

    my ( $a, $b ) = @_;

    $a = 0 unless $a;

    return $a > $b
        ? $a
        : $b;

} # }}}



__END__



#  vim: set et ft=perl sts=4 sw=4 ts=4 : 
