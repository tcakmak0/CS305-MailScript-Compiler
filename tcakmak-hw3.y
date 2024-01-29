%{

#ifdef YYDEBUG
  yydebug = 1;
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "./tcakmak-hw3.h"


void yyerror (const char *msg) /* Called by yyparse on error */ {return; }
    settedVariable* globalScope;
    settedVariable* localScope;
    recipientInfo* recipientListArr;
    sheduleNotification* schNotifications;

    char** errorBuffer;
    char** sendBuffer;
    char** scheduleBuffer;
    char blockAddress[128];
    char* blockDate;
    char* blockHour;  
    


    int globalScopeUpper = 0;
    int localScopeUpper = 0;
    int globalScopeCapacity = 256;
    int localScopeCapacity = 256;
    int recipientListCapacity = 256;
    int scheduleBufferCapacity = 256;
    int globalErrorFlag = 0; 
    int errorCounter = 0;
    int scheduleNotCounter = 0;
    int recipientListCounter = 0;
    int sendNotifCounter = 0; 
    int64_t orderNumber = 0;

    settedVariable * setOperation(InformationNode ident, InformationNode lValue);
    optionInfo* setOptionByString(InformationNode inf);
    optionInfo* setOptionByIdent(InformationNode inf);
    recipientInfo* setRecepientByAdd(InformationNode inf);
    recipientInfo* setRecepientByName(InformationNode nameStr, InformationNode inf);
    recipientInfo* setRecepientByIdent(InformationNode ident, InformationNode inf);
    

    int checkLocalScope(settedVariable* s);
    int checkGlobalScope(settedVariable* s);
    void globalSet(settedVariable* s);
    void localSet(settedVariable* s);
    void insertErrorbyRecepient(recipientInfo* r);
    void insertErrorbyOption (optionInfo* o);
    void timeValidate(InformationNode date, InformationNode clock);
    void insertToRecepientList(recipientInfo* r);
    void setBlockAddress(InformationNode inf);
    void insertSendNotification(optionInfo* o);
    void generateScheduleNotification(optionInfo* s);
    void insertToRecepientList(recipientInfo* r);

    void printScopes();
    void printErrorBuffer();
    void printRecepientList();
    void printSend();
    void printSchedule();
    void insertByOrder(sheduleNotification* s);


 
%}



%union{
    InformationNode infoNode;
    settedVariable* setted;
    optionInfo* opt;
    recipientInfo* rec;
    int lineNum;
}


%token tMAIL tENDMAIL tSCHEDULE tENDSCHEDULE tSEND tTO tFROM tSET tCOMMA tCOLON tLPR tRPR tLBR tRBR tAT
%token <infoNode> tDATE tTIME tSTRING tIDENT tADDRESS

%type <setted> setStatement
%type <opt> option
%type <rec> recipient

%start program

%%
program : statements{if(globalErrorFlag){
    printErrorBuffer();
}
else{
    printSend();
    printSchedule();
}

}
;

statements : 
            | statements setStatement  {globalSet($2);} 
            | statements mailBlock     {localScopeUpper = 0;}
;

mailBlock : tMAIL tFROM tADDRESS tCOLON {setBlockAddress($3);} statementList tENDMAIL 
;

statementList : 
                | statementList setStatement  {localSet($2);}
                | statementList sendStatement 
                | statementList scheduleStatement 
;

sendStatements : sendStatement2
                | sendStatements sendStatement2  
;

sendStatement : tSEND tLBR option tRBR tTO tLBR recipientList tRBR {insertSendNotification($3);}
;

sendStatement2 : tSEND tLBR option tRBR tTO tLBR recipientList2 tRBR {  
    // Insert Schedule Notification
    generateScheduleNotification($3);
}
;

option: tSTRING {$$ = setOptionByString($1); insertErrorbyOption($$);} | tIDENT {$$ = setOptionByIdent($1); insertErrorbyOption($$);}
;


recipientList : recipient {insertToRecepientList($1);}
            | recipientList tCOMMA recipient {insertToRecepientList($3);}
;

recipientList2 : recipient {insertToRecepientList($1);}
            | recipientList2 tCOMMA recipient {insertToRecepientList($3);}
;

recipient : tLPR tADDRESS tRPR  { $$ = setRecepientByAdd($2);}
            | tLPR tSTRING tCOMMA tADDRESS tRPR {$$ = setRecepientByName($2,$4);}
            | tLPR tIDENT tCOMMA tADDRESS tRPR  {$$= setRecepientByIdent($2,$4); insertErrorbyRecepient($$);}
;

scheduleStatement : tSCHEDULE tAT tLBR tDATE tCOMMA tTIME {timeValidate($4,$6);} tRBR tCOLON sendStatements tENDSCHEDULE 
;

setStatement : tSET tIDENT tLPR tSTRING tRPR {
    $$ = setOperation($2, $4);
    }
;

%%



settedVariable * setOperation(InformationNode ident, InformationNode lValue){
    settedVariable* s = (settedVariable*)malloc(sizeof(settedVariable)); 
    s->key = ident.value;
    s->value = lValue.value;
    s->lineNum = ident.lineNum;
    // printInformation(lValue);
    return s;
}

void localSet(settedVariable* s){
    int localFlag = checkLocalScope(s);
        if(localFlag == -1){
            if(localScopeUpper < localScopeCapacity){        
                localScope[localScopeUpper] = *s;
                localScopeUpper += 1;
            }
            else{
                localScopeCapacity *= 2;
                settedVariable* newLocalScope = realloc(localScope, localScopeCapacity * sizeof(settedVariable));
                localScope = newLocalScope;
                localScope[localScopeUpper] = *s;
                localScopeUpper += 1;
            }
        }
        else{
            localScope[localFlag] = *s;
        }

}
     

void globalSet(settedVariable* s){
    int flag = checkGlobalScope(s);
    if(flag == -1){
        if(globalScopeUpper < globalScopeCapacity){        
            globalScope[globalScopeUpper] = *s;
            globalScopeUpper += 1;
        }
        else{
            globalScopeCapacity *= 2;
            settedVariable* newGlobalScope = realloc(globalScope, globalScopeCapacity * sizeof(settedVariable));
            globalScope = newGlobalScope;
            globalScope[globalScopeUpper] = *s;
            globalScopeUpper += 1;
        }
    }

    else{
        globalScope[flag] = *s;
    }
}

int checkGlobalScope(settedVariable* s){
    int i =0;
    for(; i < globalScopeUpper;i++){
        if(strcmp(globalScope[i].key,s->key) == 0){
            return i;
        }
    }
    return -1;
}

int checkLocalScope(settedVariable* s){
    int i =0;
    for(; i < localScopeUpper;i++){
        if(strcmp(localScope[i].key ,s->key) == 0){
            return i;
        }
    }
    return -1;
}

void insertErrorbyRecepient(recipientInfo* r){
    if(r->errorFlag == 0){
        return;
    }
    else{
        //Undefined variable error
        char* x = (char*) malloc(sizeof(char*) + 128);
        sprintf(x, "ERROR at line %d: %s is undefined", r->lineNum, r->ident); 
        errorBuffer[errorCounter] = x;
        errorCounter += 1;
        globalErrorFlag = 1;
    }
}

void insertErrorbyOption(optionInfo* o){
    if(o->errorFlag == 0){
        return;
    }
    else{
        //Undefined variable error
        char* x = (char*) malloc(sizeof(char*) + 128);
        sprintf(x, "ERROR at line %d: %s is undefined", o->lineNum, o->identifier); 
        errorBuffer[errorCounter] = x;
        errorCounter += 1;
        globalErrorFlag = 1;
    }

}

optionInfo* setOptionByString(InformationNode inf){
    optionInfo* op = (optionInfo*)malloc(sizeof(optionInfo));
    op->identifier = NULL;
    op->content = inf.value;
    op->lineNum = inf.lineNum;
    op->errorFlag = 0;
    return op;
}


optionInfo* setOptionByIdent(InformationNode inf){
    optionInfo* op = (optionInfo*)malloc(sizeof(optionInfo));
    settedVariable* s = (settedVariable*)malloc(sizeof(settedVariable));
    
    s->key = inf.value;
    op->identifier = inf.value;
    op->lineNum = inf.lineNum;
    int localID = checkLocalScope(s);

    if(localID == -1){
        // Check global scope
        int globalID = checkGlobalScope(s);
        if(globalID == -1){
            // Variable is not defined
            op->content = NULL;
            op->errorFlag = 1;
        }
        else{
            // Value globally defined 
            op->content = globalScope[globalID].value;
            op->errorFlag = 0;
        }

    }

    else{
        // Exist in the local scope
        op->content = localScope[localID].value;
        op->errorFlag = 0; 
    }
    return op;
}

recipientInfo* setRecepientByAdd(InformationNode inf){
    recipientInfo* rec2 = (recipientInfo*) malloc(sizeof(recipientInfo));
    rec2->address = inf.value;
    rec2->lineNum = inf.lineNum;
    rec2->ident = NULL;
    rec2->name = NULL;
    rec2->errorFlag = 0;
    return rec2;
}

recipientInfo* setRecepientByName(InformationNode nameStr, InformationNode inf){
    recipientInfo* rec2 = (recipientInfo*) malloc(sizeof(recipientInfo));
    rec2->address = inf.value;
    rec2->lineNum = inf.lineNum;
    rec2->name = (nameStr.value + 1);
    rec2->name[strlen(rec2->name) -1] = '\0';
    rec2->ident = NULL;
    rec2->errorFlag = 0;
    return rec2;
}

recipientInfo* setRecepientByIdent(InformationNode ident, InformationNode inf){
    recipientInfo* rec2 = (recipientInfo*) malloc(sizeof(recipientInfo));
    settedVariable* s = (settedVariable*) malloc(sizeof(settedVariable));
    
    rec2->address = inf.value;
    rec2->lineNum = inf.lineNum;
    rec2->ident = ident.value;
    
    s->key=ident.value;
    int localID = checkLocalScope(s);
    if(localID == -1){
        // Check Global Scope
        int globalID = checkGlobalScope(s);
        if(globalID == -1){
            // Variable is not defined, ERROR
            rec2->name = NULL;
            rec2->errorFlag = 1;
        }
        else{
            rec2->name = globalScope[globalID].value + 1;
            rec2->name[strlen(rec2->name) -1] = '\0';
            rec2->errorFlag = 0; 
        }
    }
    else{
        rec2->name = localScope[localID].value + 1;
        rec2->name[strlen(rec2->name) -1] = '\0';
        rec2->errorFlag = 0;
    }
    return rec2;
}


void timeValidate(InformationNode date, InformationNode clock){
    char day[3];
    char month[3];
    char year[5];
    char hour[3];
    char minute[3];

    strncpy(day,date.value,2);
    strncpy(month,date.value + 3,2);
    strncpy(year,date.value + 6, 4);
    strncpy(hour, clock.value, 2);
    strncpy(minute, clock.value + 3, 2);

    

    int dayInt = atoi(day);
    int monthInt = atoi(month);
    int yearInt = atoi(year);
    int hourInt = atoi(hour);
    int minuteInt = atoi(minute);

    char* errorMsg = (char*) malloc(sizeof(char*) + 128);
    char* errorMsg2 = (char*) malloc(sizeof(char*) + 128);
    
    const int minutesPerHour = 60;
    const int hoursPerDay = 24;
    const int daysPerMonth = 30; // Assuming 30 days per month for simplicity
    const int monthsPerYear = 12;


    int daysInMonth[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    char *fullMonths[] = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};

    if(yearInt % 4 == 0){
        daysInMonth[1] = 29;
    }

    // printf("%c%c %c%c %c%c%c%c %c%c %c%c \n",day[0],day[1],month[0],month[1],year[0],year[1],year[2],year[3],hour[0],hour[1],minute[0],minute[1]);
    
    if(monthInt <= 0 || monthInt > 12){
        sprintf(errorMsg, "ERROR at line %d: date object is not correct (%c%c/%c%c/%c%c%c%c)",date.lineNum,day[0],day[1],month[0],month[1],year[0],year[1],year[2],year[3]);
        errorBuffer[errorCounter] = errorMsg;
        errorCounter += 1;
        globalErrorFlag = 1;
    }
    else if(dayInt <= 0 || dayInt > daysInMonth[monthInt -1]){
        sprintf(errorMsg, "ERROR at line %d: date object is not correct (%c%c/%c%c/%c%c%c%c)",date.lineNum,day[0],day[1],month[0],month[1],year[0],year[1],year[2],year[3]);
        errorBuffer[errorCounter] = errorMsg;
        errorCounter += 1;
        globalErrorFlag = 1;
    }
    
    if(hourInt < 0 || hourInt > 23 || minuteInt < 0 || minuteInt > 59){
        sprintf(errorMsg2, "ERROR at line %d: time object is not correct (%c%c:%c%c)",date.lineNum,hour[0],hour[1],minute[0],minute[1]);
        errorBuffer[errorCounter] = errorMsg2;
        errorCounter += 1;
        globalErrorFlag = 1;
    }
    
    if(globalErrorFlag != 1){
        char* dateInfo =(char*) malloc(sizeof(char*) + 256);
        char* hourInfo =(char*) malloc(sizeof(char*) + 256);
        sprintf(dateInfo,"%s %d, %d", fullMonths[monthInt -1], dayInt,yearInt);
        blockDate = dateInfo; 
        sprintf(hourInfo,"%c%c:%c%c", hour[0],hour[1],minute[0],minute[1]);
        blockHour = hourInfo;
        orderNumber = minuteInt + hourInt * minutesPerHour + (dayInt - 1) * hoursPerDay * minutesPerHour +
                       (monthInt - 1) * daysPerMonth * hoursPerDay * minutesPerHour +
                       (yearInt - 1) * monthsPerYear * daysPerMonth * hoursPerDay * minutesPerHour;
        // printf("%d \n",orderNumber);
        // printf("%s %s ", blockDate, blockHour);
    }    
}

void insertToRecepientList(recipientInfo* r){
    int i = 0;
        for(; i < recipientListCounter; i++){
            if(strcmp(recipientListArr[i].address,r->address) == 0){
                //Already in the list return
                return;
            }
    }
    
    if(recipientListCounter < recipientListCapacity){
        // There is enough space to insert        
        recipientListArr[recipientListCounter] = *r;
        recipientListCounter += 1;

    }
    else{
        //Re-allocation needed
        recipientListCapacity *= 2;
        recipientInfo* newRecArr = realloc(recipientListArr, recipientListCapacity * sizeof(recipientInfo));
        recipientListArr = newRecArr;
        recipientListArr[recipientListCounter] = *r;
        recipientListCounter += 1;
    }
}

void insertSendNotification(optionInfo* o){
    int i = 0;
    for(i; i < recipientListCounter; i++){
        char* notificationContent = (char*)malloc(sizeof(char*) + 2048);
        if(recipientListArr[i].name == NULL){
            sprintf(notificationContent, "E-mail sent from %s to %s: %s", blockAddress ,recipientListArr[i].address, o->content);
        }
        else{
            sprintf(notificationContent,"E-mail sent from %s to %s: %s", blockAddress ,recipientListArr[i].name, o->content);
        }
        sendBuffer[sendNotifCounter] = notificationContent;
        sendNotifCounter += 1;
    }
    recipientListCounter = 0;
}

void setBlockAddress(InformationNode inf){
    strcpy(blockAddress,inf.value);
}

void generateScheduleNotification(optionInfo* s){
    int i = 0;
    for(; i < recipientListCounter; i++){
        char* notificaionContent = malloc(sizeof(char*) + 1024);

        if(recipientListArr[i].name != NULL){
            sprintf(notificaionContent,"E-mail scheduled to be sent from %s on %s, %s to %s: %s",blockAddress,blockDate,blockHour,recipientListArr[i].name, s->content);
        }
        else{
            sprintf(notificaionContent,"E-mail scheduled to be sent from %s on %s, %s to %s: %s",blockAddress,blockDate,blockHour,recipientListArr[i].address,s->content);
        }
        sheduleNotification* s = malloc(sizeof(sheduleNotification));
        // printf("DEBUG1: %s \n", notificaionContent);

        s->content = notificaionContent;
        // printf("DEBUG2: %s \n", s->content);
        s->order = orderNumber;
        insertByOrder(s);
    }
    
    recipientListCounter = 0; 
}

void insertByOrder(sheduleNotification* s){
    int insertionPoint = scheduleNotCounter; 
    int i = 0; 
    for(; i < scheduleNotCounter; i++){
        if(schNotifications[i].order > s->order){
            insertionPoint = i;
            break;
        }
    }
    if(insertionPoint < scheduleNotCounter){
        // Shifting required
        int j = scheduleNotCounter;
        for(; j >= insertionPoint; j--){
         schNotifications[j+1] = schNotifications[j];   
        }
    }
    schNotifications[insertionPoint] = *s;
    scheduleNotCounter += 1;
}







// Debug functions


void printInformation(InformationNode inf){
    printf("%d %s \n",inf.lineNum,inf.value);

}

void printSetStatement(settedVariable* s){
    printf("Ben basladim  \n");
    printf("%s %s \n",s->key, s->value);
}

void printScopes(){
    int i = 0; 
    printf("Local Scope defined Variables are as follows: \n");
    for(; i < localScopeUpper; i++){
        printf("%s \n", localScope[i].value);
    }
    printf("Global Scope defined Variables are as follows: \n");
    i = 0; 
    for(; i < globalScopeUpper; i++){
        printf("%s \n", globalScope[i].value);
    }
}

void printOpt(optionInfo* op){
    printf("Option info: \n");
    if(op->identifier != NULL){
        printf("%s\n",op->identifier);
    }
    if(op->content != NULL){
        printf("%s\n",op->content);
    }

    
    printf("LineNum: %d\n",op->lineNum);
    printf("ErrorFlag: %d\n",op->errorFlag);
    printf("-------------\n");
    
}
void printRecep(recipientInfo* r){
    printf("Recipient Info: \n");
    printf("Address: %s\n", r->address);
    if(r->name != NULL){
        printf("Name: %s\n", r->name);
    }
    if(r->ident != NULL){
        printf("Ident: %s\n", r->ident);
    }
    printf("lineNum: %d\n", r->lineNum);
    printf("lineNum: %d\n", r->errorFlag);
    printf("-------------\n");
}

void printErrorBuffer(){
    int i = 0;
    for(; i < errorCounter;i++){
        printf("%s\n",errorBuffer[i]);
    }
}

void printRecepientList(){
    int i = 0;
    for(; i < recipientListCounter; i++){
        if(recipientListArr[i].name != NULL){
            printf("Mail address: %s\n",recipientListArr[i].name);
        }
        printf("Mail address: %s\n",recipientListArr[i].address);
    }
}
void printSend(){
    int i = 0;
     for(; i < sendNotifCounter; i++){
        printf("%s\n",sendBuffer[i]);
    }
}
void printSchedule(){
    int i = 0;
     for(; i < scheduleNotCounter; i++){
        printf("%s\n",schNotifications[i].content);
    }
}



int main () 
{
    globalScope = malloc(globalScopeCapacity * sizeof(settedVariable));
    localScope = malloc(localScopeCapacity * sizeof(settedVariable));
    recipientListArr = malloc(recipientListCapacity * sizeof(recipientInfo));
    errorBuffer = malloc(1024 * sizeof(char*));
    sendBuffer = malloc(1024 * sizeof(char*));
    schNotifications = malloc(1024 * sizeof(sheduleNotification));
   if (yyparse())
   {
      printf("ERROR\n");
      return 1;
    } 
    else 
    {
        return 0;
    } 
}
