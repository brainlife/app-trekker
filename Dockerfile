FROM brainlife/mrtrix3:3.0_RC3

RUN git clone https://github.com/dmritrekker/trekker /trekker && cd /trekker && make

