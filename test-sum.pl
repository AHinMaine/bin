#!/usr/bin/env perl


use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use File::Basename;
use Digest::CRC;
use Digest::MD5 qw/md5 md5_hex md5_base64/;
use String::CRC32;
use File::Checksum;
use Benchmark ':all';


# Stolen from BrowserUK
# http://www.perlmonks.org/?node_id=767001
#
use Inline C => Config => BUILD_NOISY => 1;
use Inline C => <<'END_C',  NAME => '_test_sum_pl', CLEAN_AFTER_BUILD => 0;

U32 checksum( U32 sum, SV *buf ) {
    int i;
    int n = SvCUR( buf ) >> 2;
    U32 *p = (U32 *)SvPVX( buf );

    for( i = 0; i < n; ++i ) {
            sum ^= p[ i ];
        sum = ( ( sum & 0x7fffffff ) << 1 ) | ( sum >> 31 );
    }
    return sum;
}

END_C

use constant BUFSIZE => 64 * 1024;


my $opts = {};

$opts->{count} = 100;
$opts->{verbose} = 0;

GetOptions( $opts,
    'filename=s',
    'count=i',
);


die "File not found or not readable... ( --filename )" . $opts->{filename} . "\n"
    unless defined $opts->{filename} && -f $opts->{filename} && -r $opts->{filename};

my $bench = cmpthese(
        $opts->{count},
        {
            test_Inline_C             => sub {   ic_sum( $opts->{filename}            ) },
            test_String_CRC32         => sub { sc32_sum( $opts->{filename}            ) },
            test_File_Checksum        => sub {   fc_sum( $opts->{filename}            ) },
            test_Digest_MD5_digest    => sub {    d_md5( $opts->{filename}, 'md5'     ) },
            test_Digest_MD5_hexdigest => sub {    d_md5( $opts->{filename}, 'hex'     ) },
            test_Digest_MD5_b64digest => sub {    d_md5( $opts->{filename}, 'b64'     ) },
            test_Digest_CRC_crc16     => sub {   dc_sum( $opts->{filename}, 'crc16'   ) },
            test_Digest_CRC_crc32     => sub {   dc_sum( $opts->{filename}, 'crc32'   ) },
            test_Digest_CRC_crc64     => sub {   dc_sum( $opts->{filename}, 'crc64'   ) },
            test_Digest_CRC_crcccit   => sub {   dc_sum( $opts->{filename}, 'crcccit' ) },

        }
    );


# {{{ dc_sum
#
sub dc_sum {

    my $f    = shift;
    my $type = shift;

    print "begin Digest::CRC, type = $type\n" if $opts->{verbose};

    open my $fh, '<:raw', $f
        or die "error opening file for computing sum: $!\n";

    my $crc = Digest::CRC->new( type => $type );

    $crc->addfile(*$fh);

    my $result = $crc->digest;

    if ( $opts->{verbose} ) {
        print "filename = $f\n"
            . "type = $type\n"
            . "result = $result\n"
            . "\n\n";
    }

    close $fh;

    return $result;

} # }}}

# {{{ d_md5
#
sub d_md5 {

    my $f    = shift;
    my $type = shift;

    print "begin Digest::MD5, type = $type\n" if $opts->{verbose};

    open my $fh, '<:raw', $f
        or die "error opening file for computing sum: $!\n";

    my $crc = Digest::MD5->new();

    $crc->addfile(*$fh);

    my $result;

    if ( $type eq 'hex' ) {
        $result = $crc->hexdigest;
    } elsif ( $type eq 'b64' ) {
        $result = $crc->b64digest;
    } else {
        $result = $crc->digest;
    }

    if ( $opts->{verbose} ) {
        print "filename = $f\n"
            . "type = $type\n"
            . "result = $result\n"
            . "\n\n";
    }

    close $fh;

    return $result;

} # }}}

# {{{ fc_sum
#
sub fc_sum {

    my $f = shift;

    print "begin fc_sum\n" if $opts->{verbose};

    my $crc = Checksum( $f, BUFSIZE );

    my $result = $crc;

    if ( $opts->{verbose} ) {
        print "filename = $f\n"
            . "type = File::Checksum\n"
            . "result = $result\n"
            . "\n\n";
    }

    return $result;

} # }}}

# {{{ sc32_sum
#
sub sc32_sum {

    my $f = shift;

    print "begin String::CRC32\n" if $opts->{verbose};

    open my $fh, '<:raw', $f
        or die "error opening file for computing sum: $!\n";

    my $crc = String::CRC32::crc32( *$fh );

    my $result = $crc;

    if ( $opts->{verbose} ) {
        print "filename = $f\n"
            . "type = String::CRC32\n"
            . "result = $result\n"
            . "\n\n";
    }

    close $fh;

    return $result;

} # }}}

# {{{ ic_sum
#
sub ic_sum {

    my $f = shift;

    print "begin Inline::C...\n" if $opts->{verbose};

    open my $fh, "<:raw", $f 
        or die "error opening file for computing sum: $!\n";

    my $result = 0;
    my $buf;

    while( read( $fh, $buf, BUFSIZE ) ) {
        $result = checksum( $result, $buf );
    }

    if ( $opts->{verbose} ) {
        print "filename = $f\n"
            . "type = Inline::C\n"
            . "result = $result\n"
            . "\n\n";
    }

    close $fh;

    return $result;

} # }}}

__END__

#  vim: set et ff=unix ft=perl sts=4 sw=4 ts=4 : 
