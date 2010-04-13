#!/bin/sh
eval 'exec `which perl` -x -S $0 ${1+"$@"}'
    if $runningUnderSomeShell;

#!perl

use strict;
use warnings;

use File::Temp qw/tempfile tempdir/;

# {{{ Exceptions
# 
# Add pipe separated values to this list to exclude items
# from the block list.
#
my $exceptions = 
        qr/
            feedburner|
            tkqlhce|
            apmebf|
            emjcd|
            jdoqocy|
            eloqua|
            cc-dt|
            anrdoezrs
        /x;
# }}}

# {{{ Inclusions
#
# Add names to this list to manually add something to the
# blocklist.
#
my @inclusions = 
    qw/
        ad.au.doubleclick.net
    /;

# }}}

my $URL    = 'http://www.mvps.org/winhelp2002/hosts.zip';
my $ZIP    = 'hosts.zip';
my $BLOCKS = 'HOSTS';

my $MALFILE = 'malwaredomains_full.txt';
my $MALURL = 'http://malwaredomains.lanik.us/' . $MALFILE;


# {{{ Create tmp dir and file
#

my $dir = tempdir( CLEANUP => 1 );
my $fh  = File::Temp->new( TEMPLATE => 'XXXXXXXXX',
                           DIR      => $dir );

my $new_block_file = $dir . '/' . $BLOCKS;
my $filename       = $fh->filename;

my $mal_in = $dir . '/' . $MALFILE;

chdir $dir;

# }}}

# {{{ Fetch and extract the updated hosts file...
#
system("wget -q $URL");
system("unzip -q $ZIP");
system("wget -q $MALURL");

# }}}

# {{{ Backup the current hosts file

chdir '/etc';

system('sudo cp hosts hosts.`date +%Y%m%d%H%M%S`');

# }}}

# {{{ Start building a new hosts file out of the old one,
# but also stripping out the previous block entries along
# the way.
#
open my $hostsfile, '<', 'hosts'
    or die "Unable to open hosts file: $!\n";

for ( <$hostsfile> ) {
    print $fh  $_ unless m/BLOCKLIST_ENTRY/;
}

close $hostsfile;

# }}}

# {{{ Open up the downloaded blocks file and starting adding
# the lines to the new hosts file, appending the
# BLOCKLIST_ENTRY tag to each line along the way (and also
# stripping out the DOS carriage return).

open my $blocks, '<', $new_block_file
    or die "Unable to open new blocks file: $!\n";

for ( <$blocks> ) {

    chomp;

    # fix the dos formatting
    s/\r//;

    print $fh $_ . "\t\t#BLOCKLIST_ENTRY\n"
        unless m/$exceptions/;

}

open my $malblocks, '<', $mal_in
    or die "Unable to open new malblocks file: $!\n";

for (<$malblocks>) {

    next if m/^(\[|[!]|\/|&|\?|[.]|_|#|[+]|[@]|[;])/s;
   #next if m/[[:cntrl:]]/;

    chomp;

    # Get rid of comments
    s/^(.*)([\$]|#).*$/$1/;

    # massage the data down to just the hostnames.
    s/\r//;
    s/^\|\|//;
    s/^[.]//;
    s/^\///;
    s/\/$//;

    # Skip entries that, after massaging, still have a slash
    next if m/\//;
    next if m/$exceptions/;

    print $fh "127.0.0.1\t" . $_ . "\t\t#BLOCKLIST_ENTRY\n"
        unless m/$exceptions/;

}

print $fh "127.0.0.1\t" . $_ . "\t\t#BLOCKLIST_ENTRY\n" for @inclusions;

close $blocks;
close $malblocks;
close $fh;

# }}}

# {{{ Copy in the new hosts file
#
system( "sudo cp $filename hosts" );

# }}}

1;

__END__
