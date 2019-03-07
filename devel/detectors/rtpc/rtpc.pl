#!/usr/bin/perl -w

use strict;
use lib ("$ENV{GEMC}/io");
use utils;
use geometry;
use math;
use materials;
use bank;
use hit;

# Help Message
sub help()
{
	print "\n Usage: \n";
	print "   rtpc.pl <configuration filename>\n";
	print "   Will create the CLAS12 RTPC using the variation specified in the configuration file\n";
	print "   Note: The passport and .visa files must be present to connect to MYSQL. \n\n";
	exit;
}

# Make sure the argument list is correct
# If not pring the help
if( scalar @ARGV != 1)
{
	help();
	exit;
}

# Loading configuration file from argument
our %configuration = load_configuration($ARGV[0]);

#materials
require "./materials.pl";
materials();

#bank
require "./bank.pl";
define_bank();

#bank
require "./hit.pl";
define_hit();

###########################################################################################
# All dimensions in mm
my $z_half = 192.0;
my @zhalf = ($z_half + 50.0, $z_half, $z_half);
my $gap = 0.001;

#  Target, Ground foil, Cathod foil
my @radius  = (3.0, 20.0, 30.0); # mm
my @thickness = (0.055, 0.006, 0.004); # mm (i.e. 55 um, 6 um, 4 um)

# Target, Ground foil, Cathod foil (al layer neglected)
my @layer_mater = ('G4_KAPTON', 'G4_MYLAR', 'G4_MYLAR');
my @layer_color = ('330099', 'aaaaff', 'aaaaff');

# GEM Layer parameters
my @gem_radius = (70.0, 73.0, 76.0); # mm
my @gem_thick = (0.005, 0.05, 0.005); # 5um, 50um, 5um
my @gem_mater = ( 'G4_Cu', 'G4_KAPTON', 'G4_Cu');
my @gem_color = ('661122',  '330099', '661122');

# Readout pad parameters
my $pad_layer_radius = 80.0; # mm
my @pad_layer_color = ('aaafff');
my $pad_layer_thick = 0.2794; # 11 mils  = 0.2794 mm

# Electronics/Ribs/Spines (ERS) Layer
my $ers_layer_radius = $gap + $pad_layer_radius + $pad_layer_thick; # mm
my $ers_layer_thick = 5.0; # mm
my @ers_layer_color = ('ffd56f');

# protection circuits
my $prot_radius = $gap + $ers_layer_radius + $ers_layer_thick; # mm
my $prot_length = 35.5; # mm
my $prot_thick = 0.5; # mm        <===- NEEDS TO BE CHANGED/VERIFIED
my @prot_color = ('000000');

# Translation board parameters
my $Tboard_radius = $gap + $ers_layer_radius + $ers_layer_thick; # mm
my $Tboard_length = 106.8; # mm
my $Tboard_thick = 0.279; # mm (11 mils)
my @Tboard_color = ('ace4d2');

# Downstream end-plate parameters
my @dsep_rmin = (0, 3.0551, 23.001); # mm
my @dsep_rmax = (3.055, 23.00, 80.0); # mm
my @dsep_thick = (0.015, 1.0, 1.0); # mm
my @dsep_color = ('330099', '000000', 'c9d6cf');
my @dsep_mat = ('G4_Al', "G10", "G10");



# mother volume
sub make_rtpc
{
	my %detector = init_det();
	$detector{"name"}        = "rtpc";
	$detector{"mother"}      = "root";
	$detector{"description"} = "Radial Time Projecion Chamber";
	$detector{"color"}       = "eeeegg";
	$detector{"type"}        = "Tube";
	$detector{"dimensions"}  = "0*mm 190.0*mm 255.0*mm 0*deg 360*deg";
	$detector{"material"}    = "G4_He";
	$detector{"visible"}     = 0;
	print_det(\%configuration, \%detector);
}


sub make_target
{
    my $rmin = 0.;
	my $rmax  = $radius[0];
    my $phistart = 0;
	my $pspan = 360;
	my $mate  = "DeuteriumTargetGas";
	my %detector = init_det();
    my $z_tar = $zhalf[0];

	$detector{"name"} = "DeuteriumTarget";
	$detector{"mother"}      = "rtpc";
	$detector{"description"} = "7 atm deuterium target gas";
	$detector{"color"}       = "a54382";
	$detector{"type"}        = "Tube";
	$detector{"dimensions"}  = "$rmin*mm $rmax*mm $z_tar*mm $phistart*deg $pspan*deg";
	$detector{"material"}    = $mate;
	$detector{"style"}       = 1;
    #$detector{"sensitivity"}  = "rtpc"; ## HitProcess definition
    #$detector{"hit_type"}     = "rtpc"; ## HitProcess definition
	print_det(\%configuration, \%detector);

}

sub make_layers
{
	my $layer = shift;
	
	my $rmin  = 0;
	my $rmax  = 0;
    my $phistart = 0;
	my $pspan = 360;
	my $mate  = "G4_He";
	my %detector = init_det();
	
	# target wall $layer==0
    # ground foil $layer==1
    # cathode $layer==2
	$rmin  = $radius[$layer];
	$rmax  = $rmin + $thickness[$layer];
	$mate  = $layer_mater[$layer];
    my $z_lay = $zhalf[$layer];
    
	$detector{"name"} = "layer_".$layer;
	$detector{"mother"}      =  "rtpc";
	$detector{"description"} = "Layer ".$layer;
	$detector{"color"}       = $layer_color[$layer];
	$detector{"type"}        = "Tube";
	$detector{"dimensions"}  = "$rmin*mm $rmax*mm $z_lay*mm $phistart*deg $pspan*deg";
	$detector{"material"}    = $mate;
	$detector{"style"}       = 1;
    #$detector{"sensitivity"}  = "rtpc"; ## HitProcess definition
    #$detector{"hit_type"}     = "rtpc"; ## HitProcess definition
	print_det(\%configuration, \%detector);
}

# Buffer volume between target and ground foil (20mm)
sub make_buffer_volume
{
    my $rmin  = $radius[0] + $thickness[0];
    my $rmax  = $radius[1];
    my $phistart = 0;
    my $pspan = 360;
    my %detector = init_det();
    my $mate  = "BONuSGas";
    
    $detector{"name"} = "buffer_layer";
    $detector{"mother"}      = "rtpc";
    $detector{"description"} = "Buffer volume";
    $detector{"color"}       = "f0f8ff";
    $detector{"type"}        = "Tube";
    $detector{"dimensions"}  = "$rmin*mm $rmax*mm $z_half*mm $phistart*deg $pspan*deg";
    $detector{"material"}    = $mate;
    $detector{"style"}       = 1;
    #$detector{"sensitivity"}  = "rtpc"; ## HitProcess definition
    #$detector{"hit_type"}     = "rtpc"; ## HitProcess definition
    print_det(\%configuration, \%detector);
}


# Buffer volume between ground foil and cathode (30mm)
sub make_buffer2_volume
{
    my $rmin  = $radius[1] + $thickness[1];
    my $rmax  = $radius[2];
    my $phistart = 0;
    my $pspan = 360;
    my %detector = init_det();
    my $mate  = "BONuSGas";
    
    $detector{"name"} = "buffer2_layer";
    $detector{"mother"}      = "rtpc";
    $detector{"description"} = "Buffer volume";
    $detector{"color"}       = "e0ffff";
    $detector{"type"}        = "Tube";
    $detector{"dimensions"}  = "$rmin*mm $rmax*mm $z_half*mm $phistart*deg $pspan*deg";
    $detector{"material"}    = $mate;
    $detector{"style"}       = 1;
    #$detector{"sensitivity"}  = "rtpc"; ## HitProcess definition
    #$detector{"hit_type"}     = "rtpc"; ## HitProcess definition
    print_det(\%configuration, \%detector);
}


# three gem
sub make_gems
{
    my $gemN = shift;
	my $layer = shift;
	
	my $rmin  = 0;
	my $rmax  = 0;
	my $pspan = 360;
	my $color = "000000";
	my $mate  = "Air";
	my $phistart = 0;
	my %detector = init_det();
	
	$rmin  = $gem_radius[$gemN];
    
    for(my $l = $layer-1; $l > -1; $l--){
	  $rmin +=  $gem_thick[$layer];
    }
    
	$rmax  = $rmin + $gem_thick[$layer];
	$color = $gem_color[$layer];
	$mate  = $gem_mater[$layer];
	
	$detector{"name"} = "gem_".$gemN."_layer_".$layer;	
	$detector{"mother"}      = "rtpc";
	$detector{"description"} = "gem_".$gemN."_layer_".$layer;
	$detector{"color"}       = $color;
	$detector{"type"}        = "Tube";
	$detector{"style"}       = 1;
    #$detector{"sensitivity"}  = "rtpc"; ## HitProcess definition
    #$detector{"hit_type"}     = "rtpc"; ## HitProcess definition
	$detector{"dimensions"}  = "$rmin*mm $rmax*mm $z_half*mm $phistart*deg $pspan*deg";
	$detector{"material"}    = $mate;
	print_det(\%configuration, \%detector);
	
}

# make drift volume from cathode to first GEM (30-70 mm)
sub make_drift_volume
{	
	my $rmin  = $radius[2] + $thickness[2];
	my $rmax  = $gem_radius[0] - $gap;
	my $pspan = 360.;	
	my $phistart = 0;
	my %detector = init_det();
	my $mate  = "BONuSGas";

	$detector{"name"} = "sensitive_drift_volume";	
	$detector{"mother"}      = "rtpc";
	$detector{"description"} = "Sensitive drift volume";
	$detector{"color"}       = "ff88994";
	$detector{"type"}        = "Tube";
	$detector{"dimensions"}  = "$rmin*mm $rmax*mm $z_half*mm $phistart*deg $pspan*deg";
	$detector{"material"}    = $mate;
	$detector{"style"}       = 1;
    $detector{"sensitivity"}  = "rtpc"; ## HitProcess definition
    $detector{"hit_type"}     = "rtpc"; ## HitProcess definition
	print_det(\%configuration, \%detector);
}

# readout pad layer
sub make_readout_layer
{
	my $rmin  = $pad_layer_radius;
	my $rmax  = $pad_layer_radius+$pad_layer_thick;
	my $phistart = 0;
	my $pspan = 360;
	my %detector = init_det();
	my $mate  = "PCB";
	
	$detector{"name"} = "pad_layer";
	
	$detector{"mother"}      = "rtpc";
	$detector{"description"} = "Readout pad layer";
	$detector{"color"}       = $pad_layer_color[0];
	$detector{"type"}        = "Tube";
	$detector{"dimensions"}  = "$rmin*mm $rmax*mm $z_half*mm $phistart*deg $pspan*deg";
	$detector{"material"}    = $mate;
	$detector{"style"}       = 1;
    #$detector{"sensitivity"}  = "rtpc"; ## HitProcess definition
    #$detector{"hit_type"}     = "rtpc"; ## HitProcess definition
	print_det(\%configuration, \%detector);
}

# ERS layer - meant to simulate a smearing of material
# from readout pads to translation boards
sub make_ers_layer
{
    my $rmin  = $ers_layer_radius;
    my $rmax  = $ers_layer_radius+$ers_layer_thick;
    my $phistart = 0;
    my $pspan = 360;
    my %detector = init_det();
    my $mate  = "ERS";
    
    $detector{"name"} = "ers_layer";
    
    $detector{"mother"}      = "rtpc";
    $detector{"description"} = "Electronics/Ribs/Spine layer";
    $detector{"color"}       = $ers_layer_color[0];
    $detector{"type"}        = "Tube";
    $detector{"dimensions"}  = "$rmin*mm $rmax*mm $z_half*mm $phistart*deg $pspan*deg";
    $detector{"material"}    = $mate;
    $detector{"style"}       = 1;
    #$detector{"sensitivity"}  = "rtpc"; ## HitProcess definition
    #$detector{"hit_type"}     = "rtpc"; ## HitProcess definition
    print_det(\%configuration, \%detector);
}

# translation boards
sub make_boards
{
    my $boardN = shift;
    
    my $rmin  = $Tboard_radius;
    my $rmax  = $Tboard_radius + $Tboard_length;
    my $pspan = ($Tboard_thick/(2*3.14*$Tboard_radius))*360;
    my $color = $Tboard_color[0];
    my $mate  = "PCB";
    my $phistart = $boardN*8;
    my %detector = init_det();
    
    $detector{"name"} = "board_".$boardN;
    $detector{"mother"}      = "rtpc";
    $detector{"description"} = "board_".$boardN;
    $detector{"color"}       = $color;
    $detector{"type"}        = "Tube";
    $detector{"style"}       = 1;
    $detector{"dimensions"}  = "$rmin*mm $rmax*mm $z_half*mm $phistart*deg $pspan*deg";
    $detector{"material"}    = $mate;
    #$detector{"sensitivity"}  = "rtpc"; ## HitProcess definition
    #$detector{"hit_type"}     = "rtpc"; ## HitProcess definition
    print_det(\%configuration, \%detector);
}

# protection circuits on translation boards
sub make_protcircuit
{
    my $cirN = shift;
    
    my $rmin  = $prot_radius;
    my $rmax  = $prot_radius + $prot_length;
    my $pspan = ($prot_thick/(2*3.14*$prot_radius))*360;
    my $color = $prot_color[0];
    my $mate  = "protectionCircuit";
    my $phistart = ($Tboard_thick/(2*3.14*$Tboard_radius))*360 + $cirN*8;
    my %detector = init_det();
    
    $detector{"name"} = "cir_".$cirN;
    $detector{"mother"}      = "rtpc";
    $detector{"description"} = "cir_".$cirN;
    $detector{"color"}       = $color;
    $detector{"type"}        = "Tube";
    $detector{"style"}       = 1;
    $detector{"dimensions"}  = "$rmin*mm $rmax*mm $z_half*mm $phistart*deg $pspan*deg";
    $detector{"material"}    = $mate;
    #$detector{"sensitivity"}  = "rtpc"; ## HitProcess definition
    #$detector{"hit_type"}     = "rtpc"; ## HitProcess definition
    print_det(\%configuration, \%detector);
}

# Down Stream End Plates (DSEP)
sub make_dsep
{
    my $dsepL = shift;
    
    my $dsep_zpos = $zhalf[$dsepL] + 0.001;
    my $rmin  = $dsep_rmin[$dsepL];
    my $rmax  = $dsep_rmax[$dsepL];
    my $phistart = 0;
    my $pspan = 360;
    my %detector = init_det();
    my $mate  = $dsep_mat[$dsepL];
    my $dsepThick = $dsep_thick[$dsepL];
    my $dsepColor = $dsep_color[$dsepL];
    
    $detector{"name"} = "dsep_".$dsepL;
    
    $detector{"mother"}      = "rtpc";
    $detector{"description"} = "Down Stream End Plate Layer ".$dsepL;
    $detector{"color"}       = $dsepColor;
    $detector{"type"}        = "Tube";
    $detector{"pos"}         = "0*mm 0*mm $dsep_zpos*mm";
    $detector{"dimensions"}  = "$rmin*mm $rmax*mm $dsepThick*mm $phistart*deg $pspan*deg";
    $detector{"material"}    = $mate;
    $detector{"style"}       = 1;
    #$detector{"sensitivity"}  = "rtpc"; ## HitProcess definition
    #$detector{"hit_type"}     = "rtpc"; ## HitProcess definition
    print_det(\%configuration, \%detector);
}

make_rtpc();

make_target();

for(my $l = 0; $l < 3; $l++)
{
	make_layers($l);
}

make_buffer_volume();
make_buffer2_volume();
make_drift_volume();

for(my $gem = 0; $gem < 3; $gem++)
{
  for(my $l = 0; $l < 3; $l++)
  {
     make_gems($gem,$l);
  }
}


make_readout_layer();

make_ers_layer();

for(my $board = 0; $board < 45; $board++){
    make_boards($board);
}

for(my $circuit = 0; $circuit < 45; $circuit++){
    make_protcircuit($circuit);
}
for(my $dsep_layer = 0; $dsep_layer < 3; $dsep_layer++){
    make_dsep($dsep_layer);
}

