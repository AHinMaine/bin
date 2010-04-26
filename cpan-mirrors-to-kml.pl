#!/opt/local/bin/perl

use strict;
use warnings;

use URI;
use IO::File;
use XML::Writer;
use Data::Dumper;
use Getopt::Long;
use HTTP::Request;
use LWP::UserAgent;
use Parse::CPAN::MirroredBy;

my $opts = {};
$opts->{force} = 0;

$opts->{mirrored_by_url} = 'ftp://ftp.funet.fi/pub/languages/perl/CPAN/MIRRORED.BY';
$opts->{mirror_file}     = '/tmp/MIRRORED.BY';
$opts->{kml_file}        = '/tmp/MIRRORED.BY.kml';

GetOptions( $opts,
                    'force!',
                    'kml_file=s',
                    'mirror_file=s',
                    'mirrored_by_url=s',
);

fetch_mirrors_file({ mirrored_by_url => $opts->{mirrored_by_url},
                     mirror_file     => $opts->{mirror_file} });

my $parse  = [];
my $parser = Parse::CPAN::MirroredBy->new();

@$parse = $parser->parse_file( $opts->{mirror_file} );

my $KMLOUT = IO::File->new( ">" . $opts->{kml_file} );
my $schema = 'http://www.opengis.net/kml/2.2';
my $writer = XML::Writer->new(
                               OUTPUT      => $KMLOUT,
                               DATA_INDENT => 4,
                               DATA_MODE   => "true"
                             );


$writer->xmlDecl("UTF-8");
$writer->startTag( 'kml', xmlns => $schema );
$writer->startTag('Document');

for (@$parse) {

    # Sample
    #
    #  {
    #    'dst_ftp' => 'ftp://mirrors.localhost.net.ar/pub/mirrors/CPAN',
    #    'dst_contact' => 'localhost.net.ar;mirrors',
    #    'hostname' => 'localhost.net.ar',
    #    'frequency' => 'daily',
    #    'dst_timezone' => '-3',
    #    'dst_location' => 'Buenos Aires, Argentina, South America (-34.6 -58.45)',
    #    'dst_http' => 'http://cpan.localhost.net.ar',
    #    'dst_src' => 'ftp.funet.fi',
    #    'dst_organisation' => 'LocalHost',
    #    'dst_bandwidth' => '100Mbit'
    #  },


    $writer->startTag('Placemark');

    my $loc = $_->{dst_location};

    $loc =~ m/^(.*?),\s+(.*?),\s+(.*?)\s+\((.*)\)/;

    my $city    = $1;
    my $state   = $2;
    my $country = $3;
    my $coord   = $4;

    $coord =~ s/^\s+//;
    $coord =~ s/\s+$//;

    $coord =~ m/^(\S+)\s+(\S+)$/;

    my $long = $1;
    my $lat  = $2;

    $writer->startTag('name');
    $writer->characters( $_->{hostname} );
    $writer->endTag('name');

    $writer->startTag('description');
    $writer->characters("$city, $state, $country");
    $writer->endTag('description');

    $writer->startTag('Point');
    $writer->startTag('coordinates');
    $writer->characters("$lat, $long");
    $writer->endTag('coordinates');
    $writer->endTag('Point');

    $writer->endTag('Placemark');

}

$writer->endTag('Document');
$writer->endTag('kml');
$writer->end();
$KMLOUT->close();

print 'Output file = ' . $opts->{kml_file} . "\n";

# {{{ Fetch the file...
#
sub fetch_mirrors_file {

    my $args = shift;

    my $url = $args->{mirrored_by_url};
    my $out = $args->{mirror_file};

    if ( ! $opts->{force} && -f $out ) {

        my $timestamp = ( stat($out) )[10];

        my $age = time - $timestamp;

        # If file is less than 3 days old, skip the fetch.
        #
        if ( $age <= 259200 ) {
            print "Mirrors file is less than three days old, skipping fetch.\n";
            return;
        }

    }

    print "Fetching fresh MIRRORED.BY file...\n";

    my $fetcher = LWP::UserAgent->new;
    my $request = HTTP::Request->new( GET => $url );
    my $fetched = $fetcher->request($request);

    my $OUT = IO::File->new(">$out")
        or die "Error writing to output file: $!\n";

    print $OUT $fetched->content;

    $OUT->close();

} # }}}

__END__

