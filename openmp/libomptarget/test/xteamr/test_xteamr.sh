#!/bin/bash
#== overload_insts_1024.h overloaded instatiations of Xteamr fcts -C++ -*-===//
#
# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
#===----------------------------------------------------------------------===//
# 
#  test_xteamr.sh: Script to test high performance reduction helper functions
#                  in llvm-project/openmp/libomptarget/DeviceRTL/src/Xteamr.cpp
#                  It compiles and executes test_xteamr.cpp in 3 configs.
#                  1024 device threads, 512 dev threads, and 256 dev threads.
#
#  See README file in this directory for more information.
#
#===----------------------------------------------------------------------===//

LLVM_INSTALL=${LLVM_INSTALL:-$HOME/llvm}
[ ! -f $LLVM_INSTALL/bin/clang ] && echo "ERROR: no LLVM install at $LLVM_INSTALL" && exit 1

OFFLOAD_ARCH=${OFFLOAD_ARCH:-sm_70}

tmpdir=/tmp/$USER/xteamr && mkdir -p $tmpdir
[ ! -d $tmpdir ] && echo "ERROR: could not create $tmpdir"

ARRAY_SIZE=${ARRAY_SIZE:-41943040}
#ARRAY_SIZE=${ARRAY_SIZE:-33554432}
as_arg="-D_ARRAY_SIZE=$ARRAY_SIZE"

NUM_TEAMS=${NUM_TEAMS:-80}

cuda_args=""
CUDA_INSTALL=${CUDA_INSTALL:-/usr/local/cuda}
[ -d $CUDA_INSTALL ] && cudalib=$CUDA_INSTALL/targets/x86_64-linux/lib && export LD_LIBRARY_PATH=$cudalib && cuda_args="-L$cudalib -lcudart"

nt_args="-D_XTEAM_NUM_THREADS=1024 -D_XTEAM_NUM_TEAMS=$NUM_TEAMS"
echo " COMPILE with --offload-arch=$OFFLOAD_ARCH $as_arg $nt_args"
$LLVM_INSTALL/bin/clang++ -O3 -I. $as_arg $nt_args -fopenmp --offload-arch=$OFFLOAD_ARCH test_xteamr.cpp -o $tmpdir/xteamr_1024 $cuda_args -lstdc++ -latomic
rc1=$?

nt_args="-D_XTEAM_NUM_THREADS=512 -D_XTEAM_NUM_TEAMS=$NUM_TEAMS"
echo " COMPILE with --offload-arch=$OFFLOAD_ARCH $as_arg $nt_args"
$LLVM_INSTALL/bin/clang++ -O3 -I. $as_arg $nt_args -fopenmp --offload-arch=$OFFLOAD_ARCH test_xteamr.cpp -o $tmpdir/xteamr_512 $cuda_args -lstdc++ -latomic
rc2=$?

nt_args="-D_XTEAM_NUM_THREADS=256 -D_XTEAM_NUM_TEAMS=$NUM_TEAMS"
echo " COMPILE with --offload-arch=$OFFLOAD_ARCH $as_arg $nt_args"
$LLVM_INSTALL/bin/clang++ -O3 -I. $as_arg $nt_args -fopenmp --offload-arch=$OFFLOAD_ARCH test_xteamr.cpp -o $tmpdir/xteamr_256 $cuda_args -lstdc++ -latomic
rc3=$?

[ $rc1 == 0 ] && echo "START EXECUTE xteamr_1024" && $tmpdir/xteamr_1024 > $tmpdir/xteamr_1024.out
rc4=$?
[ $rc2 == 0 ] && echo "START EXECUTE xteamr_512" && $tmpdir/xteamr_512 > $tmpdir/xteamr_512.out
rc5=$?
[ $rc3 == 0 ] && echo "START EXECUTE xteamr_256" && $tmpdir/xteamr_256 > $tmpdir/xteamr_256.out
rc6=$?

echo 
rc=$(( $rc1 + $rc2 + $rc3 + $rc4 + $rc5 + $rc6 ))
if [ $rc != 0 ] ; then 
  echo "ERRORS DETECTED!"
else
  echo "No errors detected"
fi
echo "Logs and binaries saved to $tmpdir"
exit $rc
