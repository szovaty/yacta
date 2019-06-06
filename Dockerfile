FROM ubuntu:16.04
LABEL maintainer="charleshatt@imbio.com"

ENV GCC=gcc
ENV GPP=g++
ENV YACTA=/yacta
ENV IMBIO_YACTA=imbio.yacta
ENV VTK=$YACTA/vtk
ENV VTK_V=7.1
ENV VTK_F=7.1.1
ENV ITK=$YACTA/itk
ENV ITK_V=4.10
ENV ITK_F=4.10.1

#### Install TOOLS ####
RUN apt-get update
RUN apt-get install -y apt-utils
RUN apt-get install -y $GCC $GPP cmake
RUN apt-get install -y libboost-all-dev 

#### Create project ####
RUN mkdir $YACTA
WORKDIR $YACTA
ADD $IMBIO_YACTA $IMBIO_YACTA

#### Install VTK ####
RUN apt-get install -y libglu1-mesa-dev freeglut3-dev mesa-common-dev
RUN mkdir -p $VTK
ADD https://www.vtk.org/files/release/$VTK_V/VTK-$VTK_F.tar.gz vtk/download
WORKDIR $YACTA/vtk
RUN tar -zxf download
RUN mkdir -p $VTK/VTK-$VTK_F/bin
WORKDIR $VTK/VTK-$VTK_F/bin
RUN cmake -DCMAKE_C_COMPILER=/usr/bin/$GCC -DCMAKE_CXX_COMPILER=/usr/bin/$GPP -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release ..

#### Install ITK ####
RUN mkdir $ITK
WORKDIR $YACTA/itk
ADD https://sourceforge.net/projects/itk/files/itk/$ITK_V/InsightToolkit-$ITK_F.tar.gz/download ./download
RUN tar -zxf download
RUN mkdir -p $ITK/InsightToolkit-$ITK_F/bin
WORKDIR $ITK/InsightToolkit-$ITK_F/bin
RUN cmake -DCMAKE_C_COMPILER=/usr/bin/$GCC -DCMAKE_CXX_COMPILER=/usr/bin/$GPP -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release ..

#### Build yacta ####
RUN sed -i "s\VTK REQUIRED\VTK REQUIRED PATHS /yacta/vtk/VTK-7.1.1/bin\g" $YACTA/imbio.yacta/src/CMakeLists.txt 
RUN sed -i "s\ITK REQUIRED\ITK REQUIRED PATHS /yacta/itk/InsightToolkit-4.10.1/bin\g" $YACTA/imbio.yacta/src/CMakeLists.txt 
WORKDIR /yacta/imbio.yacta/bin
RUN cmake -DCMAKE_CXX_COMPILER=/usr/bin/$GPP -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-std=c++0x" -DCMAKE_C_FLAGS="-std=c++0x" ../src
RUN make
