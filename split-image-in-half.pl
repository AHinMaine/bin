#!/opt/local/bin/perl

# {{{ Modules and Variables
#

our $VERSION = sprintf "%d.%d", q$Revision$ =~ /(\d+)/g;

use strict;
use warnings;

use Getopt::Long;
use File::Basename;
use File::Copy 'cp';

use Image::Magick;

# }}}

# {{{ Commandline Options
#


my $opts = {};

$opts->{debug}       = 0;
$opts->{verbose}     = 0;
$opts->{wallpapers}  = '/Users/aharrison/Pictures/Wallpapers/Split/';
$opts->{left}        = $opts->{wallpapers} . 'Left/';
$opts->{right}       = $opts->{wallpapers} . 'right/';
$opts->{compression} = 'LosslessJPEG';
$opts->{file}        = [];

GetOptions( $opts,

                       'debug!',
                       'test!',
                       'verbose!',
                       'file=s@{,}',
                       'left=s',
                       'right=s',
                       'compression=s',
                       'wallpapers=s',

          );

if ( ! -d $opts->{wallpapers} ) {
    die 'Error, wallpapers dir invalid: ' . $opts->{wallpapers} . "\n";
}

if ( ! -d $opts->{left} ) {
    die 'Error, Left wallpapers dir invalid: ' . $opts->{left} . "\n";
}

if ( ! -d $opts->{right} ) {
    die 'Error, Right wallpapers dir invalid: ' . $opts->{right} . "\n";
}

if ( defined $ARGV[0] && $ARGV[0] ) {

    for (@ARGV) {
        if ( -f $_ && -r $_ ) {
            push @{ $opts->{file} }, $_;
        }
    }

}

my @compression_formats = 
    qw/
        None
        BZip
        Fax
        Group4
        JPEG
        JPEG2000
        LosslessJPEG
        LZW
        RLE
        Zip
    /;

unless ( grep $opts->{compression} eq $_, @compression_formats ) {
    die 'Invalid compression format selected: ' 
        . $opts->{compression} 
        . "\nChoose one of the following:\n"
        . join( "\n", @compression_formats )
        ;
}

my $aspect = 1280 / 1024;

#
# }}}

# {{{ main
#


for ( @{$opts->{file}} ) {

    if ( -f $_ ) {

        my @splitname = split( /[.]/, $_ );
        my $suffix = '.' . pop( @splitname );

        my ( $name, $path, $ext ) = fileparse( $_, $suffix );

        my $img = Image::Magick->new;
        my ( $width, $height, $size, $format ) = $img->Ping($_);

        if ( ! $width / $height == $aspect ) {
            warn "Aspect ratio is not fullscreen, image might not split cleanly: $_\n";
        }

        verbose("Image dimensions: $width x $height");
        verbose("Image size:       $size");
        verbose("Image format:     $format");

        my $l_name = $opts->{left}  . $name . '-left'  . $ext;
        my $r_name = $opts->{right} . $name . '-right' . $ext;

        cp( $_, $l_name );
        cp( $_, $r_name );
        
        my $l_img = Image::Magick->new;
        my $r_img = Image::Magick->new;

        my $half_width = $width / 2;

        $l_img->Read($_);
        $r_img->Read($_);

        $l_img->Crop( width => $half_width, x => 0,           y => 0 );
        $r_img->Crop( width => $half_width, x => $half_width, y => 0 );

        $l_img->Set( compression => $opts->{compression} );
        $r_img->Set( compression => $opts->{compression} );

        dump_img_attrs({ image => $l_img });
        dump_img_attrs({ image => $r_img });

        $l_img->Write($l_name);
        $r_img->Write($r_name);

        verbose("Images written:\n$l_name\n$r_name");

        print "Split complete.\n";

    }

}


# }}}

# {{{ subs
#

# {{{ sub verbose {
#

sub verbose {

    return unless $opts->{verbose};
    my $args = shift;
    print $args . "\n";


} # }}}

# {{{ sub dump_img_attrs {
#
sub dump_img_attrs {

    return unless $opts->{debug};

    my $args = shift;

    my $i = $args->{image};

    print "\n\n" . '-' x 20 . "\n"
        . 'Dumping image attributes for '
        . $i->Get( 'filename' )
        . "\n"
        . '-' x 20
        . "\n"
        ;

    for ( qw/   area
                colors
                columns
                comment
                compression
                density
                depth
                disk
                filesize
                format
                geometry
                height
                label
                magick
                memory
                page
                quality
                rows
                taint
                size
                type
                width
                x-resolution
                y-resolution/ ) {

            ddump( $_, $i->Get( $_ ) );

    }
                


} # }}}

# {{{ sub ddump {
#

sub ddump {

    use Data::Dumper;

    $Data::Dumper::Varname  = shift;
    $Data::Dumper::Varname .= '_';

    print Dumper( \@_ );

} # }}}

# }}}

__END__

# {{{ END
#
#


# {{{ Image attributes

|adjoin         |{True, False}                                                                                                                           |join images into a single multi-image file                                               |
|alpha          |{On, Off, Opaque, Transparent, Copy, Extract, Set}                                                                                      |control of and special operations involving the alpha/matte channel                      |
|antialias      |{True, False}                                                                                                                           |remove pixel aliasing                                                                    |
|area-limit     |integer                                                                                                                                 |set pixel area resource limit.                                                           |
|attenuate      |double                                                                                                                                  |lessen (or intensify) when adding noise to an image.                                     |
|authenticate   |string                                                                                                                                  |decrypt image with this password.                                                        |
|background     |color name                                                                                                                              |image background color                                                                   |
|blue-primary   |x-value, y-value                                                                                                                        |chromaticity blue primary point (e.g. 0.15, 0.06)                                        |
|bordercolor    |color name                                                                                                                              |set the image border color                                                               |
|clip-mask      |image                                                                                                                                   |associate a clip mask with the image.                                                    |
|colormap[i]    |color name                                                                                                                              |color name (e.g. red) or hex value (e.g. #ccc) at position i                             |
|comment        |string                                                                                                                                  |set the image comment                                                                    |
|compression    |{None, BZip, Fax, Group4, JPEG, JPEG2000, LosslessJPEG, LZW, RLE, Zip}                                                                  |type of image compression                                                                |
|debug          |{All, Annotate, Blob, Cache, Coder, Configure, Deprecate, Draw, Exception, Locale, None, Resource, Transform, X11}                      |display copious debugging information                                                    |
|delay          |integer                                                                                                                                 |this many 1/100ths of a second must expire before displaying the next image in a sequence|
|density        |geometry                                                                                                                                |vertical and horizontal resolution in pixels of the image                                |
|depth          |integer                                                                                                                                 |image depth                                                                              |
|disk-limit     |integer                                                                                                                                 |set disk resource limit                                                                  |
|dispose        |{Undefined, None, Background, Previous}                                                                                                 |layer disposal method                                                                    |
|dither         |{True, False}                                                                                                                           |apply error diffusion to the image                                                       |
|display        |string                                                                                                                                  |specifies the X server to contact                                                        |
|extract        |geometry                                                                                                                                |extract area from image                                                                  |
|file           |filehandle                                                                                                                              |set the image filehandle                                                                 |
|filename       |string                                                                                                                                  |set the image filename                                                                   |
|fill           |color                                                                                                                                   |The fill color paints any areas inside the outline of drawn shape.                       |
|font           |string                                                                                                                                  |use this font when annotating the image with text                                        |
|fuzz           |integer                                                                                                                                 |colors within this distance are considered equal                                         |
|gamma          |double                                                                                                                                  |gamma level of the image                                                                 |
|Gravity        |{Forget, NorthWest, North, NorthEast, West, Center, East, SouthWest, South, SouthEast}                                                  |type of image gravity                                                                    |
|green-primary  |x-value, y-value                                                                                                                        |chromaticity green primary point (e.g. 0.3, 0.6)                                         |
|index[x, y]    |string                                                                                                                                  |colormap index at position (x, y)                                                        |
|interlace      |{None, Line, Plane, Partition, JPEG, GIF, PNG}                                                                                          |the type of interlacing scheme                                                           |
|iterations     |integer                                                                                                                                 |add Netscape loop extension to your GIF animation                                        |
|label          |string                                                                                                                                  |set the image label                                                                      |
|loop           |integer                                                                                                                                 |add Netscape loop extension to your GIF animation                                        |
|magick         |string                                                                                                                                  |set the image format                                                                     |
|map-limit      |integer                                                                                                                                 |set map resource limit                                                                   |
|mask           |image                                                                                                                                   |associate a mask with the image.                                                         |
|matte          |{True, False}                                                                                                                           |enable the image matte channel                                                           |
|mattecolor     |color name                                                                                                                              |set the image matte color                                                                |
|memory-limit   |integer                                                                                                                                 |set memory resource limit                                                                |
|monochrome     |{True, False}                                                                                                                           |transform the image to black and white                                                   |
|option         |string                                                                                                                                  |associate an option with an image format (e.g. option=>'ps:imagemask'                    |
|orientation    |{top-left, top-right, bottom-right, bottom-left, left-top, right-top, right-bottom, left-bottom}                                        |image orientation                                                                        |
|page           |{ Letter, Tabloid, Ledger, Legal, Statement, Executive, A3, A4, A5, B4, B5, Folio, Quarto, 10x14} or geometry                           |preferred size and location of an image canvas                                           |
|pixel[x, y]    |string                                                                                                                                  |hex value (e.g. #ccc) at position (x, y)                                                 |
|pointsize      |integer                                                                                                                                 |pointsize of the Postscript or TrueType font                                             |
|quality        |integer                                                                                                                                 |JPEG/MIFF/PNG compression level                                                          |
|red-primary    |x-value, y-value                                                                                                                        |chromaticity red primary point (e.g. 0.64, 0.33)                                         |
|sampling-factor|geometry                                                                                                                                |horizontal and vertical sampling factor                                                  |
|scene          |integer                                                                                                                                 |image scene number                                                                       |
|server         |string                                                                                                                                  |specifies the X server to contact                                                        |
|size           |string                                                                                                                                  |width and height of a raw image                                                          |
|stroke         |color                                                                                                                                   |The stroke color paints along the outline of a shape.                                    |
|texture        |string                                                                                                                                  |name of texture to tile onto the image background                                        |
|tile-offset    |geometry                                                                                                                                |image tile offset                                                                        |
|time-limit     |integer                                                                                                                                 |set time resource limit in seconds                                                       |
|type           |{Bilevel, Grayscale, GrayscaleMatte, Palette, PaletteMatte, TrueColor, TrueColorMatte, ColorSeparation, ColorSeparationMatte, Optimize }|image type                                                                               |
|units          |{ Undefined, PixelsPerInch, PixelsPerCentimeter}                                                                                        |units of image resolution                                                                |
|verbose        |{True, False}                                                                                                                           |print detailed information about the image                                               |
|virtual-pixel  |{Background Black Constant Dither Edge Gray Mirror Random Tile Transparent White}                                                       |the virtual pixel method                                                                 |
|white-point    |x-value, y-value                                                                                                                        |chromaticity white point (e.g. 0.3127, 0.329)                                            |

# }}}





#
# }}}


