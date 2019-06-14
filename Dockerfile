FROM ubuntu:18.04
LABEL maintainer="charleshatt@imbio.com"

# definitions
ENV TERM=/usr/bin/less
ENV GCC=gcc-6
ENV GPP=g++-6
ENV YACTA=/yacta
ENV IMBIO_YACTA=imbio.yacta
ENV YACTA_BIN=$YACTA/$IMBIO_YACTA/bin
ENV PKG_LIST="apt-utils $GCC $GPP cmake libboost-all-dev libglu1-mesa-dev freeglut3-dev mesa-common-dev"

#### Install TOOLS ####
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -yq $PKG_LIST libvtk7-dev

#### Create project ####
RUN mkdir $YACTA
WORKDIR $YACTA
ADD $IMBIO_YACTA $IMBIO_YACTA

# as the git repo is not public use local version
# you need to clone the repo before build the image
RUN test -d $YACTA/$IMBIO_YACTA/src || exit 1 :

#### Install VTK ####
# uncomment below if you want to build VTK from source
#ENV VTK=$YACTA/vtk
#ENV VTK_V=7.1
#ENV VTK_F=$VTK_V.1
#ENV VTK_BIN=$VTK/VTK-$VTK_F/bin
#RUN mkdir -p $VTK
#ADD https://www.vtk.org/files/release/$VTK_V/VTK-$VTK_F.tar.gz $VTK/download
#WORKDIR $VTK
#RUN tar -zxf download
#RUN mkdir -p $VTK_BIN
#WORKDIR $VTK_BIN
#RUN cmake -DCMAKE_C_COMPILER=/usr/bin/$GCC -DCMAKE_CXX_COMPILER=/usr/bin/$GPP -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release ..
#RUN make install
#RUN sed -i "s\VTK REQUIRED\VTK REQUIRED PATHS $VTK/vtk/VTK-$VTK_F/bin\g" $YACTA/imbio.yacta/src/CMakeLists.txt

#### Install ITK ####
ENV ITK=$YACTA/itk
ENV ITK_V=4.10
ENV ITK_F=$ITK_V.1
ENV ITK_BIN=$ITK/InsightToolkit-$ITK_F/bin
RUN mkdir -p $ITK
WORKDIR $ITK
# using local copy when source does not download
#ADD https://sourceforge.net/projects/itk/files/itk/$ITK_V/InsightToolkit-$ITK_F.tar.gz/download $ITK
COPY tmp/download download
RUN tar -zxf download
RUN mkdir -p $ITK_BIN
WORKDIR $ITK_BIN
RUN cmake -DCMAKE_C_COMPILER=/usr/bin/$GCC -DCMAKE_CXX_COMPILER=/usr/bin/$GPP -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release ..
RUN make install

#### Build yacta.exe ####
#RUN sed -i "s/VTK REQUIRED/VTK REQUIRED PATHS \/usr\/lib\/cmake\/vtk-7.1/g" $YACTA/imbio.yacta/src/CMakeLists.txt 
RUN sed -i "s\ITK REQUIRED\ITK REQUIRED PATHS $ITK_BIN\g" $YACTA/imbio.yacta/src/CMakeLists.txt 
WORKDIR $YACTA_BIN
RUN cmake -DCMAKE_CXX_COMPILER=/usr/bin/$GPP -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-std=c++0x" -DCMAKE_C_FLAGS="-std=c++0x" ../src
RUN make
RUN echo $ITK/bin > /etc/ld.so.conf.d/itk
RUN ldconfig
