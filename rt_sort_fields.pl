#!/usr/bin/perl
#===============================================================================
#
#         File: rt_sort_fields.pl
#
#        Usage: ./rt_sort_fields.pl
#
#  Description:
#
#       Easier CustomField sort order management for RT Request Tracker
#
#      Options: --dump, --load, --yaml_file
# Requirements: YAML::Any
#       Author: Andy Harrison <aharrison@gmail.com>
# Organization: 
#      Version: 1.0
#      Created: 12/18/2012 01:41:38 PM
#     Revision: ---
#===============================================================================


# {{{ Modules and config

use strict;
use warnings;

use 5.10.0;

use Data::Dumper;

use Getopt::Long;

use YAML::Any qw/LoadFile DumpFile/;

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

$opts->{debug}         = 0;
$opts->{verbose}       = 0;
$opts->{test}          = 0;
$opts->{dump}          = 0;
$opts->{load}          = 0;
$opts->{yaml_file}     = 'rt-cf-sort.yaml';

GetOptions( $opts,

                    'conf=s',
                    'debug!',
                    'verbose!',
                    'test!',
                    'load!',
                    'dump!',
                    'yaml_file=s',

);

# }}}


if ( $opts->{dump} ) {

    # {{{ create a yaml file from the existing Queue names and custom fields.
    #

    # The hashref where we'll store all the details
    #
    my $yaml = {};

    # Iterate all RT Queues
    #
    my $Qs = RT::Queues->new($RT::SystemUser);
    $Qs->FindAllRows;
    $Qs->UnLimit;

    while ( my $Q = $Qs->Next ) {
        
        # Within every queue, Load the associated CustomFields
        #
        my $CFs = RT::CustomFields->new($RT::SystemUser);
        $CFs->LimitToQueue($Q->Id);

        my $temp = {};

        # For each custom field, grab the associated ObjectCustomField object so that we
        # can get the appropriate value for its SortOrder.
        #
        while ( my $CF = $CFs->Next ) {

            my $record = RT::ObjectCustomField->new($RT::SystemUser);

            my ( $ok, $msg ) = $record->LoadByCols( ObjectId    => $Q->Id,
                                                    CustomField => $CF->Id );

            if ( $ok ) {

                # This hashref will be made of the CustomField Name for the key and the
                # SortOrder for the value.
                #

                $temp->{$CF->Name} = $record->SortOrder;

            } else {
                print "Skipping " . $CF->Name . ": $msg\n";
                next;
            }

        }

        # The key of the Queue name will refer to the list of CustomFields, in order by
        # the SortOrder value.
        #
        push @{$yaml->{$Q->Name}}, $_
            for sort { $temp->{$a} <=> $temp->{$b} } keys %$temp;

    }

    $Data::Dumper::Varname = 'yaml';
    print Dumper( $yaml ) if $opts->{debug};

    DumpFile($opts->{yaml_file}, $yaml)
        or die "Error writing yaml file: $!\n";

    print 'Wrote file: ' . $opts->{yaml_file} . "\n";

    # }}}

} elsif ( $opts->{load} ) {

    # {{{ Read the yaml file and order the custom fields for each queue to match
    #

    my $yaml = LoadFile($opts->{yaml_file})
        or die "Error loading yaml file: $!\n";

    # From the yaml file, for each queue, we take the list of custom field
    # names and build a hash of the custom field name for the key and the new
    # SortOrder for the value.
    #
    my $field_sort = {};

    for my $qname ( keys %$yaml ) {

        my $counter = 1;

        my $cflist = $yaml->{$qname};

        $field_sort->{$qname}->{$_} = $counter++ for @$cflist;

        my $Q = RT::Queue->new($RT::SystemUser);
        $Q->LoadByCol( Name => $qname );

        print "\n\nFrom yaml, current queue: " . $Q->Name . "\n";

        my $CF = RT::CustomField->new($RT::SystemUser);

        # Read from our hashref of queues and custom fields and apply the new SortOrder
        #
        for my $cfname ( keys %{$field_sort->{$qname}} ) {

            my ( $ok, $msg ) =
                $CF->LoadByName( Queue => $Q->Id,
                                 Name  => $cfname );

            if ( $ok ) {

                print 'Found Queue "' . $Q->Name . '" with CustomField "' . $CF->Name . "\"\n"
                    if $opts->{verbose};

                my $record = RT::ObjectCustomField->new($RT::SystemUser);

                my ( $rok, $rmsg ) =
                    $record->LoadByCols( ObjectId    => $Q->Id,
                                         CustomField => $CF->Id );

                if ( $rok ) {

                    if ( $field_sort->{$Q->Name}->{$CF->Name} == $record->SortOrder ) {

                        print "SortOrder is correct\n" if $opts->{verbose};
                        next;

                    } else {

                        print "\tCustom Field: "
                            . $CF->Name
                            . "\n\t\tDesired SortOrder: "
                            . $field_sort->{ $Q->Name }->{ $CF->Name }
                            . ', Actual SortOrder: '
                            . $record->SortOrder . "\n";

                        # This is a test of the emergency broadcast system...
                        next if $opts->{test};

                        my ( $setok, $setmsg ) =
                            $record->SetSortOrder(
                                     $field_sort->{ $Q->Name }->{ $CF->Name } );

                        if ($setok) {
                            print "\t\tSuccess: ${setmsg}\n";
                        } else {
                            print "\n\nERROR: Failed to update SortOrder for "
                                . $CF->Name
                                . ": ${setmsg}\n\n";
                        }

                    }

                } else {

                    print "Loading failed for Queue '"
                        . $Q->Id
                        . "' Custom Field '"
                        . $CF->Id
                        . ": ${rmsg}'\n";

                    next;

                }

            } else {
                print "Failed to load custom field ${cfname}: ${msg}\n";
            }

        }

    }

    $Data::Dumper::Varname = 'field_sort_from_yaml';
    print Dumper( $field_sort ) if $opts->{debug};

    # }}}

}

__END__

# {{{ POD


=pod

=head1 NAME

rt_sort_fields - More easily change the order of your Ticket CustomFields.

=head1 SCRIPT CATEGORIES

Misc

=head1 README

Help simplify changing the order if ticket custom fields so they're in the correct order for the ticket creation form.

First, dump the current state of Queues and the current order of the CustomFields. (--dump)

Next, Edit the dumped yaml file and change the order of the custom fields to your liking.

Last, load the edited yaml file.  (--load)

Profit!

=head1 OSNAMES

any

=head1 PREREQUISITES

 YAML::Any

=head1 SYNOPSIS

=head2 OPTIONS AND ARGUMENTS

ACTIONS

=over 15

=item B<--dump>

Read RT for existing queue names and custom fields and create the yaml file.

=item B<--load>

Load the yaml file and modify the SortOrder values in RT accordingly.

=back

OPTIONS

=over 15

=item B<--yaml_file> I<filename>

Specify the name of the yaml file to dump or load.

(default: rt-cf-sort.yaml)

=back


