#include "levenshtein_distance.h"

// Levenshtein Distance Algorithm: C Implementation
//
// by Lorenzo Seidenari (sixmoney@virgilio.it)
//
// http://www.merriampark.com/ldc.htm

/*****************************************************/
/*Function prototypes and libraries needed to compile*/
/*****************************************************/

#include <stdlib.h>
#include <string.h>

int minimum(int a, int b, int c);

/****************************************/
/*Implementation of Levenshtein distance*/
/****************************************/

int levenshtein_distance(const char *s, const char *t)
/*Compute levenshtein distance between s and t*/
{
    //Step 1
    int n,m;
    n=strlen(s); 
    m=strlen(t);
    return levenshtein_distance_with_bytes(s, n, t, m);
}

int levenshtein_distance_with_bytes(const char *s, int n, const char *t, int m)
{
    int k,i,j,cost,*d,distance;
    if(n!=0&&m!=0)
    {
        d=malloc((sizeof(int))*(m+1)*(n+1));
        m++;
        n++;
        //Step 2	
        for(k=0;k<n;k++)
            d[k]=k;
        for(k=0;k<m;k++)
            d[k*n]=k;
        //Step 3 and 4	
        for(i=1;i<n;i++)
            for(j=1;j<m;j++)
            {
                //Step 5
                if(s[i-1]==t[j-1])
                    cost=0;
                else
                    cost=1;
                //Step 6			 
                d[j*n+i]=minimum(d[(j-1)*n+i]+1,d[j*n+i-1]+1,d[(j-1)*n+i-1]+cost);
            }
        distance=d[n*m-1];
        free(d);
        return distance;
    }
    else 
        return -1; //a negative return value means that one or both strings are empty.
    
}

int minimum(int a, int b, int c)
/*Gets the minimum of three values*/
{
    int min=a;
    if(b<min)
        min=b;
    if(c<min)
        min=c;
    return min;
}