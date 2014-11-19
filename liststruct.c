/******
 *Joe DiSabito
 *liststruct.c
 *used to implement id list
 ******/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

typedef struct idnode {
  char *name;
  struct idnode *next;
} *IDnodeptr;


int printList(IDnodeptr theList){
  while (theList != NULL){
    printf("%s\n", theList->name);
    theList = theList->next;
  }

  return 0;
}

IDnodeptr addID(IDnodeptr theList, char *name){
  IDnodeptr tempNode = malloc(sizeof(struct idnode));
  tempNode->name = malloc(sizeof(name));
  strcpy(tempNode->name, name);
  tempNode->next = theList;
  return tempNode;
}




