#include <stdio.h>
#include <wiringPi.h>

int main(){
	if(wiringPiSetup() == 1)
		return 1;
	
	pinMode(7,OUTPUT);
	digitalWrite(7,LOW);
	
	printf("부저종료!\n");
	return 0;
}
