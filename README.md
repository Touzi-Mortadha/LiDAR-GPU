# How to compile and run the file main.cpp 


## first you need to install pcap library : 
sudo apt-get install libpcap0.8-dev


## to compile
/usr/local/cuda-8.0/bin/nvcc main.cu -std=c++11 -lpcap -Wno-deprecated-gpu-targets

## to run 
./a.out > pcap.txt

## to plot
./visualize_point_cloud.py file.csv 
python p.py file.csv



##### THANK's #####
