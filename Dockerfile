#FROM brainlife/mrtrix3:3.0.0
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

#build requirements
RUN apt-get update && apt-get install -y python3-pip python3 cmake g++ git 

#extras
RUN apt-get install -y jq vim

RUN pip3 install Cython

#compile / install trekker
RUN git clone https://github.com/baranaydogan/trekker -b memoryworkout /trekker
RUN mkdir -p /trekker/build/Linux && cd /trekker/build/Linux && cmake -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DCMAKE_BUILD_TYPE=Release -DBuild_Python3_WRAPPER=ON -DPython3_EXECUTABLE=python3 ../../
RUN cd /trekker/build/Linux && cmake --build . --config Release --target install --parallel 8

RUN pip3 install /trekker/build/Linux/install/python/dist/Trekker-0.5-cp38-cp38-linux_x86_64.whl
