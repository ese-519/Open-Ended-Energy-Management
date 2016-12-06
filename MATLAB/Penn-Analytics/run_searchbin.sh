#!/bin/sh
# script for execution of deployed applications
#
# Sets up the MATLAB Runtime environment for the current $ARCH and executes 
# the specified command.
#
exe_name=$0
exe_dir=`dirname "$0"`
echo "------------------------------------------"
echo Setting up environment variables
MCRROOT="/usr/local/MATLAB/MATLAB_Runtime/v91/"
echo ---
LD_LIBRARY_PATH=.:${MCRROOT}/runtime/glnxa64 ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnxa64 ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnxa64;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/opengl/lib/glnxa64;
export LD_LIBRARY_PATH;
echo LD_LIBRARY_PATH is ${LD_LIBRARY_PATH};
#shift 1

bin=$1
building_name = $2
#args=
#while [ $# -gt 0 ]; do
 #    bin=$1
  #   building_name = $2
args="${args} \"${bin}\${building_name}\"" 
  #   shift
# done
 eval "\"${exe_dir}/searchbin\"" $args

exit

