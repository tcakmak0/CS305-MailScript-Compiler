#ifndef __STRUCTURES_H
#define __STRUCTURES_H
typedef struct Inf
{
    char *value;
    int lineNum;   
} InformationNode;


typedef struct settedVariable
{
    char *key;
    char *value;
    int lineNum; 
} settedVariable; 

typedef struct optionInfo
{
    char* identifier;
    char* content;
    int lineNum; 
    int errorFlag; 
}optionInfo;

typedef struct recipientInfo{
    char* address;
    char* name;
    char* ident;
    int lineNum;
    int errorFlag;
}recipientInfo;

typedef struct sheduleNotification{
    int64_t order;
    char* content;
}sheduleNotification;



#endif