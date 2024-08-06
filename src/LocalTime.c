#include <time.h>

void GetLocalTime(unsigned char* hour, unsigned char* minute, unsigned char* second ) {
    // Declare a variable to store the current time
    time_t currentTime;
    
    // Obtain the current time
    time(&currentTime);
    
    // Convert the current time to a human-readable format
    struct tm *localTime = localtime(&currentTime);
    
    // Record result
    *hour = localTime->tm_hour;
    *minute = localTime->tm_min;
    *second = localTime->tm_sec;
}