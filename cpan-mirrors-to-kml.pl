#!/usr/bin/perl 

use strict;
use warnings;

use Data::Dumper;
use Parse::CPAN::MirroredBy;
use XML::Writer;
use IO::File;

my $mirror_file = '/tmp/MIRRORED.BY';
my $kml_file    = '/tmp/MIRRORED.BY.kml';

print "Output file = $kml_file\n";

my $parse  = [];
my $parser = Parse::CPAN::MirroredBy->new();

@$parse = $parser->parse_file( $mirror_file );

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

my $mirrors = {};

for (@$parse) {

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

    $mirrors->{ $_->{hostname} }->{hostname}    = $_->{hostname};
    $mirrors->{ $_->{hostname} }->{description} = "$city, $state, $country";
    $mirrors->{ $_->{hostname} }->{coordinates} = "$lat, $long";

}

my $OUT    = IO::File->new( ">" . $kml_file );
my $schema = 'http://www.opengis.net/kml/2.2';
my $writer = XML::Writer->new(
                               OUTPUT      => $OUT,
                               DATA_INDENT => 4,
                               DATA_MODE   => "true"
                             );


$writer->xmlDecl("UTF-8");
$writer->startTag( 'kml', xmlns => $schema );
$writer->startTag('Document');

for my $cur_mirror ( keys %$mirrors ) {

    $writer->startTag('Placemark');

    $writer->startTag('name');
    $writer->characters( $mirrors->{$cur_mirror}->{hostname} );
    $writer->endTag('name');

    $writer->startTag('description');
    $writer->characters( $mirrors->{$cur_mirror}->{description} );
    $writer->endTag('description');

    $writer->startTag('Point');
    $writer->startTag('coordinates');
    $writer->characters( $mirrors->{$cur_mirror}->{coordinates} );
    $writer->endTag('coordinates');
    $writer->endTag('Point');

    $writer->endTag('Placemark');

}


$writer->endTag('Document');
$writer->endTag('kml');
$writer->end();
$OUT->close();

