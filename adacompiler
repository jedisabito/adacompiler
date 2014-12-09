//patchList.h
//Joe DiSabito

#include <string.h>
#include <stdlib.h>
#include <stddef.h>

struct patchNode {
  struct patchNode *next;
  
  int address, patch;
};

struct patchNode *lpStack[50];
int lpTop = 0;

struct patchNode* addPatch(struct patchNode *patchList, int patch, int patchAddress){

  struct patchNode *newNode = (struct patchNode*)malloc(sizeof(struct patchNode));

  newNode->address = patchAddress;
  newNode->patch = patch;
  newNode->next = patchList;

  return newNode;
 
}

int printPatches(FILE *fp, struct patchNode *patchList){
  if (patchList != NULL){
    fprintf(fp, "Patch: %i at line %i\n", patchList->patch, patchList->address);
    if (patchList->next != NULL){
      printPatches(fp, patchList->next);
    }
  }
}

lpAdd(int base, int address){
  lpStack[base] = addPatch(lpStack[base], 0, address);
}

lpPush(){
  lpTop++;
  lpStack[lpTop] = NULL;
}

struct patchNode* lpGetPop(struct patchNode* patchList, int patch){
  
  struct patchNode *temp = lpStack[lpTop];

  while (temp != NULL){
    patchList = addPatch(patchList, patch, temp->address);
    temp = temp->next;
  }

  lpTop--;

  return patchList;
}

int searchPatches(struct patchNode* patchList, int address){
  
  struct patchNode *temp = patchList;
  
  while (temp != NULL){
    if (temp->address == address){
      return temp->patch;
    } 
    temp = temp->next;
  }

  return -1;
}

patchFile(FILE *fp, FILE *fp2, struct patchNode* patchList){

  char * line = NULL;
  int linenum = 0;
  size_t len = 0;
  int toPatch;
  char *patch = malloc(50);
  char buffer[200];

  while (getline(&line, &len, fp) != -1) {
    strcpy(buffer, line);

    toPatch = searchPatches(patchList, linenum);
    
    int i;

    for (i = 0; i < len; i++){
      if (buffer[i] == '?'){
	fprintf(fp2, "%i", toPatch);
      }else if(buffer[i] == '\0'){
	break;
      }else{
	fprintf(fp2, "%c", buffer[i]);
      }
    }

    linenum++;
  }
}


