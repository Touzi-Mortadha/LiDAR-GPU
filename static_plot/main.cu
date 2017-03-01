#include <string>
#include <iostream>
#include <pcap.h>
#include <stdio.h>
#include <time.h>
#include <math.h>
#include <iostream>
#include <fstream> 

using namespace std;


#define ROTATION_RESOLUTION  0.01f /**< degrees */
#define DISTANCE_RESOLUTION  0.002f
#define PI 3.1415926535 



struct point
{
double x; 
double y;
double z; 
double reflectivity;
}; 




//TODO
__global__ 
void analyse(u_char* data, point* d_point,double * d_azimuth,int * d_vertical_angle )
{
	
//	extern __shared__ float s_azimuth[];
//	extern __shared__ float s_vertical_angle[];
//	extern int	


//	__syncthreads(); 
	//my magic equation
	int j = threadIdx.x;
	// point on the first byte of each data point
	int pointer = 100*(int)(j/32) + (j%32)*3+46;
	
	int index_alpha = (int)(j/16);
	int index_omega = (int)(j%16);
	//millimeter as unit
	double distance=(double)((data[pointer+1]<<8)+data[pointer])*0.002; 
	

	double v_angle= d_vertical_angle[index_omega]  * PI / 180.0;
	double v_azimuth=d_azimuth[index_alpha] * PI / 180.0;
	
	//printf("%d   alpha :  %d \t%f\n",pointer,data[pointer],distance);
	d_point[j].x= distance*cosf(v_angle)*sinf(v_azimuth);
	d_point[j].y= distance*cosf(v_angle)*cosf(v_azimuth);
	d_point[j].z= distance*sinf(v_angle);
	d_point[j].reflectivity=data[pointer+2];
}



int main(int argc, char *argv[])
{
	string file = "./vlp.pcap";
	ofstream f;
	f.open ("file.csv");
	//declare host table, use it in CPU
	double azimuth_array[24];
	point h_point[384];//the return of coordinate of each point in this array of structure
	int vertical_angle[16]={-15,1,-13,-3,-11,5,-9,7,-7,9,-5,11,-3,13,-1,15};//this table is from datasheet
	// Create a character array using a u_char
	const u_char *data;//data in all packet(1248 bytes) 

	//device array for GPU
	int* d_vertical_angle; 	//the real array that we will allocate it in GPU.
	u_char * d_array ; // data array	
	point * d_point;
	double *d_azimuth;
	
	//array sizes in GPU
	int vertical_angle_bytes = 16 * sizeof(int) ;//size of vertical angle array, need it for allocation in GPU
	const int array_bytes = 1248 * sizeof(u_char);//size of data array, need it for allocation in GPU.
	int point_bytes = 384 * sizeof(point);
	int azimuth_bytes = 24* sizeof(double);

	
	//allocate array in GPU
	cudaMalloc(&d_vertical_angle,vertical_angle_bytes) ;
	cudaMalloc(&d_azimuth,azimuth_bytes);
	cudaMalloc(&d_point,point_bytes); 	
	cudaMalloc(&d_array,array_bytes);
	
	//memory copy in CUDA GPU
	cudaMemcpy(d_vertical_angle,vertical_angle,vertical_angle_bytes,cudaMemcpyHostToDevice); 
	
	//variable for time calcultaion
	clock_t start, end;

	// Create an char array to hold the error.

	char errbuff[PCAP_ERRBUF_SIZE];

	
	// Step 4 - Open the file and store result in pointer to pcap_t
	pcap_t * pcap = pcap_open_offline(file.c_str(), errbuff);



	// Step 5 - Create a header object
	struct pcap_pkthdr *header;
	

	//start clock for calculation time
	start = clock();
	//Step 6 - Loop through packets and print them to screen
	//pcap_next_ex(pcap, &header, &data) ; 

	
	while (int returnValue = pcap_next_ex(pcap, &header, &data) >= 0)
	{
		//pcap_next_ex(pcap, &header, &data);

	//****************** azimuth calculation ***********//
		pcap_next_ex(pcap, &header, &data);
	
		int k =0;
		for(int i = 0;i<12;i++)
		{
		int j = i*100+44;
		int a = data[j];
		int b = data[j+1];
		azimuth_array[k]=(double)((b<<8)+a)/100.0;
		//printf("%d   %d   %f\n",a,b,tab[k]);
		k+=2;
		}
	
		for(int i=1;i<23;i+=2)
		{
			if(azimuth_array[i+1]<azimuth_array[i-1])
			{			
				azimuth_array[i+1]+=360.0;			
			}
			azimuth_array[i] = azimuth_array[i-1]+ (double)(azimuth_array[i+1]-azimuth_array[i-1])/2.0;
			if(azimuth_array[i]>360.0)
				azimuth_array[i]-=360.0;
		}
		azimuth_array[23]=azimuth_array[22];
		
	/*	for(int i=1;i<24;i++)
		{
			printf("%f\n",azimuth_array[i]);
		}
	*/
	//********* END of azimuth calculation ***********//
	

	
		cudaMemcpy(d_array,data,array_bytes,cudaMemcpyHostToDevice); 
		cudaMemcpy(d_azimuth,azimuth_array,azimuth_bytes,cudaMemcpyHostToDevice); 
	
		analyse<<<1,384>>>(d_array,d_point,d_azimuth,d_vertical_angle);
		cudaDeviceSynchronize();	
	
		cudaMemcpy(h_point,d_point,point_bytes,cudaMemcpyDeviceToHost);
	
	
		for(int i=0;i<384;i++)
		{
			f<<h_point[i].x<<','<<h_point[i].y<<","<<h_point[i].z<<endl;
			printf("%f\t%f\t%f\n",h_point[i].x,h_point[i].y,h_point[i].z);
		}	
	}
	//end of clock time
	end = clock();
	f.close();
	//double time_taken = ((double) (end - start)) / CLOCKS_PER_SEC;	
//	printf("fun took %f seconds to execute \n\n\n\n", time_taken);

}
