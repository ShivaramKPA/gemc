# gemc
This version has all updated geometry and parameters for the RTPC,
to include the most recent (flawed) solenoid map.

To use:
1. Clone the gemc git repo
2. cd [gemc directory]/source
3. run:
    scons OPT=1 -jN
    where N = number of cores you want to use
    
4. Open the file:
   $JLAB_ROOT/$JLAB_VERSION/ce/gemc.csh
   
   Modify the [gemc directory] to match where you put it
   
   set PROPOSEDINSTALL = $JLAB_SOFTWARE/[gemc directory]/$GEMC_VERSION/source
   
5. Then run:
   source $JLAB_ROOT/2.2/ce/jlab.csh
