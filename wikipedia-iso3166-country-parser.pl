#!/usr/bin/env perl 
#===============================================================================
#
#         File: wikipedia-iso3166-country-parser.pl
#
#  Description:
#               Simple script to pull the ISO 3166 two character country codes
#               and their corresponding country names from Wikipedia.
#
# Requirements: JSON, WWW::Mechanize, HTML::TableExtract
#       Author: Andy Harrison {tld => 'com', domain => 'gmail', user => 'aharrison'
#      Version: 1.0
#      Created: 10/04/2019 09:16:31 AM
#     Revision: ---
#===============================================================================

use strict;
use warnings;

use utf8;
use Encode;

use Data::Dumper;

use URI;
use JSON;
use WWW::Mechanize;
use HTML::TableExtract;



my $mech = WWW::Mechanize->new();


# The title of the wiki page and the section name.
#
my $page_name    = 'ISO_3166-1_alpha-2';
my $section_name = 'Officially assigned code elements';


my $uri = URI->new();

$uri->scheme('https');
$uri->host('en.wikipedia.org');
$uri->path_segments('w', 'api.php');

$uri->query_form(
    'action'             => 'parse',
    'format'             => 'json',
    'page'               => $page_name,
    'prop'               => 'sections',
    'contentmodel'       => 'text',
    'contentformat'      => 'text/x-wiki',
    'disabletoc'         => '1',
    'disablelimitreport' => '1',
    'disableeditsection' => '1',
);



# First we grab the details of all the sections.
#
$mech->get($uri)
    or die "Error fetching sections url: $!\n";



# The output comes back from wikipedia as json.  Need to encode the content
# because of the 'wide' characters that come back due to foreign characters.
#
my $json = decode_json(Encode::encode_utf8($mech->content))
    or die "Error parsing json: $!\n";


die "Error, no sections found.\n"
    unless 
        defined     $json->{parse}
        and defined $json->{parse}->{sections}
        and ref     $json->{parse}->{sections} eq 'ARRAY';



my $sections = $json->{parse}->{sections};

my $section_number = 0;

for (@$sections)
{

    if (defined $_->{line} and $_->{line} and $_->{line} eq $section_name)
    {
        $section_number = $_->{index};
    }

    die "Error, no section index number found.\n"
        unless defined $_->{index} and $_->{index};

}


$uri->query_form(
    'action'             => 'parse',
    'format'             => 'json',
    'page'               => $page_name,
    'section'            => $section_number,
    'prop'               => 'text',
    'contentmodel'       => 'text',
    'contentformat'      => 'text/x-wiki',
    'disabletoc'         => '1',
    'disablelimitreport' => '1',
    'disableeditsection' => '1',
);


$mech->get($uri)
    or die "Error fetching page url: $!\n";


# The output comes back from wikipedia as json.  Need to encode the content
# because of the 'wide' characters that come back due to foreign characters.
#
$json = decode_json(Encode::encode_utf8($mech->content));


die "Error, no page text found.\n"
    unless 
            defined $json->{parse}
        and defined $json->{parse}->{text}
        and defined $json->{parse}->{text}->{'*'};


my $te = HTML::TableExtract->new();

$te->parse($json->{parse}->{text}->{'*'});



# Since we took the time to figure out the exact page section needed, we're ok
# to just grab that first table that's found in the html output.
#
my $table  = $te->first_table_found;
my $rows   = $table->rows;
my @header = map { chomp $_; $_; } @{ shift @$rows };

#print Dumper(\@header);

my $countries = {};

for (@$rows)
{
    # It's weird how every damn thing needs to be chomped.
    #
    chomp(my $CC   = $_->[0]);
    chomp(my $Name = $_->[1]);

    #chomp(my $tld  = $_->[2]);
    #chomp(my $iso  = $_->[3]);
    #chomp(my $note = $_->[4]);


    # It was just the first row, but it had this weird style-related leader
    # tacked on that didn't get parsed correctly.
    #
    if ($CC =~ m/.mw-parser-output .monospaced\{font-family:monospace,monospace\}(\S+)$/)
    {
        $CC = $1;
    }

    $countries->{$CC} = $Name;

}

print Dumper($countries);

