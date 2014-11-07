#!/usr/bin/perl -w
use strict;

# test with eg
# ./grepimage.pl 20 00 00 54 00 00 60 1827+00_ha-r_mosaic.fit
# or
# ./grepimage.pl 18 55 00 13 00 00 60 1850+14_ha-r_mosaic.fit
#

#use Astro::FITS::CFITSIO;
#use Astro::FITS::CFITSIO qw( :longnames );

#use Astro::WCS::LibWCS;                  # export nothing by default
use Astro::WCS::LibWCS qw( :functions ); # export function names
use Astro::WCS::LibWCS qw( :constants ); # export constant names

use Astro::FITS::CFITSIO;
use Astro::FITS::CFITSIO qw( :constants :longnames );

use PGPLOT;

# do I need this?
use Carp;

use Data::Dumper;

use List::Util qw( min max );

use Image::Magick;

require "check_status.pl";

if ($#ARGV < 7){
print "program usage\n";
print "grepimage  HH mm ss\.s dd mm ss\.s \<image size in arcsec\> \<regex\>\n";
exit;
}

#print "ARGV[1] is ",$ARGV[0],"\n";

# Check RA hours input number formats
if ($ARGV[0] < 0 || $ARGV[0] > 24){
print "Check RA hours. Program usage\n";
print "coordgrep  HH mm ss\.s dd mm ss\.s \<regex\>\n";
exit;
}

# Check RA minutes input number formats
if ($ARGV[1] < 0 || $ARGV[1] > 60){
print "Check RA minutes. Program usage\n";
print "coordgrep  HH mm ss\.s dd mm ss\.s \<regex\>\n";
exit;
}

# Check RA seconds input number formats
if ($ARGV[2] < 0 || $ARGV[2] > 60){
print "Check RA seconds. Program usage\n";
print "coordgrep  HH mm ss\.s dd mm ss\.s \<regex\>\n";
exit;
}

# Check Dec degrees input number formats
if ($ARGV[3] < -90 || $ARGV[3] > 90){
print "Check Dec degrees. Program usage\n";
print "coordgrep  HH mm ss\.s dd mm ss\.s \<regex\>\n";
exit;
}

# Check Dec minutes input number formats
if ($ARGV[4] < 0 || $ARGV[4] > 60){
print "Check Dec minutes. Program usage\n";
print "coordgrep  HH mm ss\.s dd mm ss\.s \<regex\>\n";
exit;
}

# Check Dec seconds input number formats
if ($ARGV[5] < 0 || $ARGV[5] > 60){
print "Check Dec seconds. Program usage\n";
print "coordgrep  HH mm ss\.s dd mm ss\.s \<regex\>\n";
exit;
}

# Check image size input number formats
if ($ARGV[6] < 0 ){
print "Check image size (arcsecs). Program usage\n";
print "coordgrep  HH mm ss\.s dd mm ss\.s \<regex\>\n";
exit;
}
my $imsize_arcsec = $ARGV[6];

print "\nInput parameters appear to be valid\n\n";


my @infiles = ();

my $fname=" ";
my $i = 0;
my $nfiles = $#ARGV +1 -7;

#print "nfiles is $nfiles \n\n";

foreach $i (0..$nfiles-1){
$infiles[$i] = $ARGV[$i+7];
}

print "Checking the following files for input coordinates \n";
map { print "$_\n" } @infiles;
print "\n";

my $filename = " ";
my $header_length=0;
my $bytes_before_data=0;

#my $rastr = " ";
my $wcs = " ";
my $fitsheader = " ";

# Concatenate ARGV strings to make ra string
my $rastr = $ARGV[0]." ".$ARGV[1]." ".$ARGV[2];

# Concatenate ARGV strings to make dec string
my $decstr = $ARGV[3]." ".$ARGV[4]." ".$ARGV[5];

#print "ra string is $rastr and dec string is $decstr\n";

# Convert ra and dec strings to angles
my $ra = str2ra($rastr);
my $dec = str2dec($decstr);

#print "ra angle is $ra and dec angle is $dec\n";


foreach $i (0..$nfiles-1){

#print "start of loop\n";

    $filename = $infiles[$i];
#    print "opening $filename \n";

    $fitsheader = " ";
    $fitsheader = fitsrhead($filename, $header_length, $bytes_before_data);
    $wcs=" ";
    $wcs = wcsinitn ($fitsheader, 0);
    
#    print "wcs structure is \@wcs \n";

    my $retval=0;
    my $xpixpos = 0;
    my $ypixpos = 0;
    my $offscl=0;

    $retval=wcs2pix($wcs,$ra,$dec,$xpixpos,$ypixpos,$offscl);

# offscl should be zero if we're within the bounds of the image
#    print "offscl is ",$offscl,"\n";

    if ($offscl == 0) {
	print "Coordinates $rastr $decstr are in $filename\n";

	my $status = 0;
	my $fptr = Astro::FITS::CFITSIO::open_file($filename,Astro::FITS::CFITSIO::READONLY(),$status);

#print "a\n";
	check_status($status) or die;

	#
	# read dimensions of image
	#
	my $naxes;
	$fptr->get_img_parm(undef,undef,$naxes,$status);
	my ($naxis1,$naxis2) = @$naxes;

#
# read image into $array, close file

	print "Reading ${naxis2}x${naxis1} image...";

# Find pixel coordinate corresponding to input ra and dec



# Extract subarray here

#	print("Extracting image centred on $xpixpos and $ypixpos \n");

# Pixel coordinates were found in call to wcs2pix above
	print "pixel coordinates are $xpixpos and $ypixpos \n";

	my $xpixposint = int($xpixpos + 0.5);
	my $ypixposint = int($ypixpos + 0.5);

	print "pixel integer coordinates are $xpixposint and $ypixposint \n";

# Now need to calculate box size given in arcsec in pixels
	
# Open image again to get another fptr
#	fits_open_file($fptr,$filename,READONLY(),$status);
	Astro::FITS::CFITSIO::fits_open_file($fptr,$filename,READONLY(),$status);

#check_status($status) or die;
#printf "Opened image OK \n\n";
	if ( $status != 0 )
	  { printf("Failed to open $filename. Exiting.\n");
	    die;}

	my $xcol = 0;
	my $ycol = 0;
	my $xrefval = 0;
	my $yrefval = 0;
	my $xrefpix = 0;
	my $yrefpix = 0;
	my $xinc = 0;
	my $yinc = 0;
	my $rot = 0;
	my $coordtype = ' ';
	#my $status = 0;
	my $returnval = 0;


	fits_read_img_coord($fptr,$xrefval, $yrefval, $xrefpix, $yrefpix, $xinc, $yinc, $rot, $coordtype, $status);
	
	my $errmsg = ' ';
	if ( $status != 0 )
{
  printf ("Possible problem with $filename \n");
  if ( $status == 506){
    printf("Status implies approximate wcs keyword values were returned \n");
  $status=0}
  else {
    printf("Failed to read $filename. Exiting.\n");
    printf("Status value is $status \n");
    fits_get_errstatus($status,$errmsg);
    printf("Error message is $errmsg \n");
    fits_close_file($fptr,$status);
    die;}
  }

# Close file
$fptr->close_file($status);
check_status($status) or die;

#printf("size of square in arcseconds is $imsize_arcsec \n\n");

my $pixsize = 3600.0 * abs($xinc);
#printf("pixel size is $pixsize arcseconds\n");

my $nxpixsize = int( ($imsize_arcsec /$pixsize) + 0.5);

printf("Size of box in pixels is $nxpixsize \n");

# Now need to extract subarray, with suitable checking for edge conditions
###########################################################################

print("\nExtracting image centred on $xpixposint and $ypixposint \n\n");

# Calculate bottom left coordinate

my $xbotleft=-99;
if ($xpixposint - int($nxpixsize/2) < 0) 
  {$xbotleft = 0;} 
else 
  {$xbotleft = $xpixposint - int($nxpixsize/2);}
#print("xbotleft is $xbotleft \n");

my $ybotleft=-99;
if ($ypixposint - int($nxpixsize/2) < 0) 
  {$ybotleft = 0;} 
else 
  {$ybotleft = $ypixposint - int($nxpixsize/2);}
#print("ybotleft is $ybotleft \n");

# Calculate bottom right coordinate

my $xbotright=-99;
if ($xpixposint + int($nxpixsize/2) > $naxis1)
  {$xbotright = $naxis1;} 
else 
  {$xbotright = $xpixposint + int($nxpixsize/2);}
#print("xbotright is $xbotright \n");

my $ybotright=-99;
if ($ypixposint - int($nxpixsize/2) < 0) 
  {$ybotright = 0;} 
else 
  {$ybotright = $ypixposint - int($nxpixsize/2);}
#print("ybotright is $ybotleft \n");

# Calculate top left coordinate

my $xtopleft=-99;
if ($xpixposint - int($nxpixsize/2) < 0 ) 
  {$xtopleft = 0;} 
else 
  {$xtopleft = $xpixposint - int($nxpixsize/2);}
#print("xtopleft is $xtopleft \n");

my $ytopleft=-99;
if ($ypixposint + int($nxpixsize/2) > $naxis2 ) 
  {$ytopleft = $naxis2;} 
else 
  {$ytopleft = $ypixposint + int($nxpixsize/2);}
#print("ytopleft is $ytopleft \n");

# Calculate top right coordinate

my $xtopright=-99;
if ($xpixposint + int($nxpixsize/2) > $naxis1) 
  {$xtopright = $naxis1;} 
else 
  {$xtopright = $xpixposint + int($nxpixsize/2);}
#print("xtopright is $xtopright \n");

my $ytopright=-99;
if ($ypixposint + int($nxpixsize/2) > $naxis2) 
  {$ytopright = $naxis2;} 
else 
  {$ytopright = $ypixposint + int($nxpixsize/2);}
#print("ytopright is $ytopright \n");

print ("End of box coordinate calculation \n");

# Copy subimage to array.
################################################################


#my $subarraysize = $nxpixsize * $nxpixsize;
my @subimage;

#$subimage[1]=71;

print "number of pixels in subimage: nxpixsize is $nxpixsize \n";

my $y=0;
my $x=0;

# perl arrays start at 0, but there is no <= so it is ok to use limits below.
for ( $y=0; $y < $nxpixsize; $y++){
  for ($x=0 ; $x < $nxpixsize ; $x++){

#    print "$x,$y \n";

    $subimage[$x][$y] = $array[$xbotleft -1 +$x][$ybotleft -1 +$y];
#    print "copied $array[$xbotleft -1 +$x][$ybotleft -1 +$y] to $subimage[$x][$y]\n";
  }
}

# Dump array to check it looks OK.
#print Dumper \@subimage;

#&copyarray($naxis1, $naxis2, \@array, \@subimage);

# Begin display of image
###########################################################################

print ("Start of PGPLOT initialisation \n");

# Initialise PGPLOT
# First argument should be 0 according to source
# second argument is graphics device
# How many plots/divisions/pages in x direction
# How many plots/divisions/pages in y direction
#
# Don't need this with pgopen or get 2 windows.
#	pgbeg(0,'/xs',1,1);
#sleep 5;

# Open a new graphics window.
	my $win_id = 0;

# Open a graphics device
# return value must be >= 0 should check for this else error
	$win_id = pgopen('/xs');
#	$win_id = pgopen('file.png/PNG');
	print "win_id is $win_id \n";

#sleep 5;

# Select one of the open graphics devices and direct subsequent
# plotting to it. The argument is the device identifier returned by
# PGOPEN when the device was opened
	pgslct($win_id);

# set color index. The default color index is 1, usually white on a black
# background for video displays or black on a white background for
# printer plots.
	pgsci(3);

# set window and viewport and draw labeled frame.
# Set PGPLOT "Plotter Environment".  PGENV establishes the scaling
# for subsequent calls to PGPT, PGLINE, etc.  The plotter is
# advanced to a new page or panel, clearing the screen if necessary.
# If the "prompt state" is ON (see PGASK), confirmation
# is requested from the user before clearing the screen.
# If requested, a box, axes, labels, etc. are drawn according to
# the setting of argument AXIS.
#
#     SUBROUTINE PGENV (XMIN, XMAX, YMIN, YMAX, JUST, AXIS)
#      REAL XMIN, XMAX, YMIN, YMAX
#      INTEGER JUST, AXIS
# Arguments:
#  XMIN   (input)  : the world x-coordinate at the bottom left corner
#                    of the viewport.
#  XMAX   (input)  : the world x-coordinate at the top right corner
#                    of the viewport (note XMAX may be less than XMIN).
#  YMIN   (input)  : the world y-coordinate at the bottom left corner
#                    of the viewport.
#  YMAX   (input)  : the world y-coordinate at the top right corner
#                    of the viewport (note YMAX may be less than YMIN).
#  JUST   (input)  : if JUST=1, the scales of the x and y axes (in
#                    world coordinates per inch) will be equal,
#                    otherwise they will be scaled independently.
#  AXIS   (input)  : controls the plotting of axes, tick marks, etc:
#      AXIS = -2 : draw no box, axes or labels;
#      AXIS = -1 : draw box only;
#      AXIS =  0 : draw box and label it with coordinates;
#      AXIS =  1 : same as AXIS=0, but also draw the
#                  coordinate axes (X=0, Y=0);
#      AXIS =  2 : same as AXIS=1, but also draw grid lines
#                  at major increments of the coordinates;
#      AXIS = 10 : draw box and label X-axis logarithmically;
#      AXIS = 20 : draw box and label Y-axis logarithmically;
#      AXIS = 30 : draw box and label both axes logarithmically.
#
# For other axis options, use routine PGBOX. PGENV can be persuaded to
# call PGBOX with additional axis options by defining an environment
#  parameter PGPLOT_ENVOPT containing the required option codes.


#	pgenv(0,$naxis2-1,0,$naxis1-1,0,0);
        pgenv(0,$nxpixsize-1,0,$nxpixsize-1,0,0);
	
# This is the transformation from pixel coordinate to axis value
	my @tr = [0,1,0,0,0,1];


# PGIMAG -- color image from a 2D data array
#      SUBROUTINE PGIMAG (A, IDIM, JDIM, I1, I2, J1, J2,
#                   A1, A2, TR)
#      INTEGER IDIM, JDIM, I1, I2, J1, J2
#      REAL    A(IDIM,JDIM), A1, A2, TR(6)
#
# Draw a color image of an array in current window. The subsection
# of the array A defined by indices (I1:I2, J1:J2) is mapped onto
# the view surface world-coordinate system by the transformation
# matrix TR. The resulting quadrilateral region is clipped at the edge
# of the window. Each element of the array is represented in the image
# by a small quadrilateral, which is filled with a color specified by
# the corresponding array value.
#
# The subroutine uses color indices in the range C1 to C2, which can
# be specified by calling PGSCIR before PGIMAG. The default values
# for C1 and C2 are device-dependent; these values can be determined by
# calling PGQCIR. Note that color representations should be assigned to
# color indices C1 to C2 by calling PGSCR before calling PGIMAG. On some
# devices (but not all), the color representation can be changed after
# the call to PGIMAG by calling PGSCR again.
#
# Array values in the range A1 to A2 are mapped on to the range of
# color indices C1 to C2, with array values <= A1 being given color
# index C1 and values >= A2 being given color index C2. The mapping
# function for intermediate array values can be specified by
# calling routine PGSITF before PGIMAG; the default is linear.
#
# On devices which have no available color indices (C1 > C2),
# PGIMAG will return without doing anything. On devices with only
# one color index (C1=C2), all array values map to the same color
# which is rather uninteresting. An image is always "opaque",
# i.e., it obscures all graphical elements previously drawn in
# the region.
#
# The transformation matrix TR is used to calculate the world
# coordinates of the center of the "cell" that represents each
# array element. The world coordinates of the center of the cell
# corresponding to array element A(I,J) are given by:
#
#          X = TR(1) + TR(2)*I + TR(3)*J
#          Y = TR(4) + TR(5)*I + TR(6)*J
#
# Usually TR(3) and TR(5) are zero -- unless the coordinate
# transformation involves a rotation or shear.  The corners of the
# quadrilateral region that is shaded by PGIMAG are given by
# applying this transformation to (I1-0.5,J1-0.5), (I2+0.5, J2+0.5).
#
# Arguments:
#  A      (input)  : the array to be plotted.
#  IDIM   (input)  : the first dimension of array A.
#  JDIM   (input)  : the second dimension of array A.
#  I1, I2 (input)  : the inclusive range of the first index
#                    (I) to be plotted.
#  J1, J2 (input)  : the inclusive range of the second
#                    index (J) to be plotted.
#  A1     (input)  : the array value which is to appear with shade C1.
#  A2     (input)  : the array value which is to appear with shade C2.
#  TR     (input)  : transformation matrix between array grid and
#                    world coordinates.



#	pgimag(\@array,$naxis1,$naxis2,1,$naxis1,1,$naxis2,0,400,[0,1,0,0,0,1]);

# Add bias here to make array all positive

print "Scaling image \n";

my $minval = 0.0;
my $maxval = 0.0;

# Can't use simple min or max on 2D array
for ( $y=0; $y < $nxpixsize; $y++){
  for ($x=0 ; $x < $nxpixsize ; $x++){
    if ($subimage[$x][$y] < $minval ){$minval = $subimage[$x][$y]};
    if ($subimage[$x][$y] > $maxval ){$maxval = $subimage[$x][$y]}
  }
}


#$bias = min(\@subimage) ;
print "Min value is $minval \n";
print "Max value is $maxval \n";

# If bias is less than zero add abs value to make whole array positive.
if ($minval < 0.0){
  for ( $y=0; $y < $nxpixsize; $y++){
    for ($x=0 ; $x < $nxpixsize ; $x++){
      $subimage[$x][$y] = $subimage[$x][$y] + abs($minval)}
  }
}

# get depth of display
my @depth = (0.0,0.0);
pgqcir(@depth);
print "indexes are $depth[0] and $depth[1] \n";



pgimag(\@subimage,$nxpixsize,$nxpixsize,1,$nxpixsize,1,$nxpixsize,0,5,[0,1,0,0,0,1]);

##	pgcont($array,$naxis1,$naxis2,1,$naxis1,1,$naxis2,[10,30,50,100],8,@tr);


#	pgpage();




      }

}

pgclos();
pgend();
print "\n";
print "\n";
exit;

###########################################################################

sub copyarray
  {
#local int subimage(10,10);

print("arrgh\n");
print("first  parameter is $_[0]  \n");
print("second  parameter is $_[1]  \n");

my @narray_ref = @{$_[2]};
#print("first array value is  ${ $_[2] } [1][1] \n\n");
print "narray value[20][20] is $narray_ref[20][20] \n";

my @nsubimage_ref = @{$_[3]};
#print("subimage[0] is ${ $_[3] } [0] \n");
print(" subimage[1] is $nsubimage_ref[1] \n");

##my $firstval = $$@{$array_ref}[0];
##my $firstval = $$$array_ref[0];

#print("firstval is $firstval \n");

#print("third argument is $@{ $_[2] }[1] \n");

}
