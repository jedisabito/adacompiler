/***********
 *Joe DiSabito
 *9/9/14
 *binTree.c
 *Implementation of binary tree found on cslibrary.stanford.edu,
 *Binary Trees by Nick Parlante
 ***********/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

struct Entry {
  char *kind, *name, *mode;
  int value, lower, upper, size, offset, depth, address;
  struct Node *next, *parent_type;
};

struct Node {
  struct Entry data;
  struct Node *left;
  struct Node *right;
};

struct Item {
  char *nombre;
  struct Node *root;
  int arSize;
};

struct Node* lookup(struct Node* node, char *nam){
  if (node == NULL){
    return NULL; 
  }else{
    if (strcmp(node->data.name, nam) == 0){
      return node;
    }else if (strcmp(nam, node->data.name) < 0){
      return lookup(node->left, nam);
    }else{
      return lookup(node->right, nam);
    }
  }
}

struct Node* insert(struct Node* node, struct Entry stuff){
  if (node == NULL){
      node = (struct Node*)malloc(sizeof(struct Node));
      node->data = stuff;
      node->left = NULL;
      node->right = NULL;
      return node;
  }else{
    if (strcmp(stuff.name, node->data.name) < 0)
      node->left = insert(node->left, stuff);
    else if (strcmp(stuff.name, node->data.name) > 0)
      node->right = insert(node->right, stuff);
    else
      return NULL;

    return node;
  }
}

const int STACK_SIZE = 40;
struct Item binStack[40];
int top = -1;

int push(char* nam){
  top += 1;
  if (top >= STACK_SIZE){
    return 0;
    top -= 1;
  }else{
    binStack[top].nombre = malloc(sizeof(nam));
    binStack[top].nombre = nam;
    binStack[top].root = NULL;
    return 1;
  }

}

int pop(){
  if (top < 0){
    return 0;
  }
  
  binStack[top].root = NULL;
  binStack[top].nombre = NULL;
  top -= 1;

  return 1;
}

int add(struct Entry stuff){
  if (lookup(binStack[top].root, stuff.name) == NULL){
    binStack[top].root = insert(binStack[top].root, stuff);
  }else{
    return 0;
  }

  return 1;
}

struct Node* search(char *entry){
  int index = top;
  int depth = 0;
  while (index >= 0){
    struct Node *tempNode = (struct Node*)malloc(sizeof(struct Node));
    tempNode = lookup(binStack[index].root, entry);
    if (tempNode == NULL){
      //do nothing
    }else{
      tempNode->data.depth = depth;
      return tempNode;
    }
    depth++;
    index--;
  }
  return NULL;
}

char* mallocCpy(char *string2){
  char* string1 = malloc(sizeof(string2) + 1);
  strcpy(string1, string2);

  return string1;
}

int printStuff(struct Entry stuff){

  stuff.depth = 0;
  printf(">| ");
  printf("%s ", stuff.name);
  printf("%s ", stuff.kind);
  if (strcmp(stuff.kind, "parm") == 0){
     printf("%s ", stuff.mode);
  }
  if (stuff.parent_type != NULL){
    printStuff(stuff.parent_type->data);
  }
  if (strcmp(stuff.kind, "variable") == 0){
    printf("%i %i ", stuff.size, stuff.offset);
  }
  if (strcmp(stuff.kind, "array") == 0 || strcmp(stuff.kind, "range") == 0){
    printf("%i - %i ", stuff.lower, stuff.upper);
    printf("%i ", stuff.size);
  }

  if (strcmp(stuff.kind,"parm") == 0 && stuff.next != NULL){
    printf("Next: ");
    printStuff(stuff.next->data);
  }
  
  if (strcmp(stuff.kind, "procedure") == 0 && stuff.next != NULL){
    printf("Params: ");
    printStuff(stuff.next->data);
  }

  printf("|< ");
 
  return 0;
}

int printTree(struct Node *node){
  
  if (node == NULL){
    //do nothing
  }else{
    struct Entry stuff = node->data;
    printTree(node->left);
    printStuff(stuff);
    printf("\n");
    printTree(node->right);
  }

  return 0;
}

int init(){
  push("outer context");
  struct Entry stuff;
  stuff.name = mallocCpy("integer");
  stuff.kind = mallocCpy("type");
  stuff.parent_type = NULL;
  stuff.next = NULL;
  stuff.size = 1;
  add(stuff);

  stuff.name = mallocCpy("boolean");
  stuff.kind = mallocCpy("type");
  stuff.size = 1;
  add(stuff);

  stuff.name = mallocCpy("false");
  stuff.kind = mallocCpy("value");
  stuff.value = 0;
  add(stuff);

  stuff.name = mallocCpy("maxint");
  stuff.kind = mallocCpy("value");
  stuff.value = 20;
  add(stuff);

  stuff.name = mallocCpy("true");
  stuff.kind = mallocCpy("value");
  stuff.value = 1;
  add(stuff);

  stuff.name = mallocCpy("read");
  stuff.kind = mallocCpy("read_routine");
  stuff.value = 0;
  add(stuff);

  stuff.name = mallocCpy("write");
  stuff.kind = mallocCpy("write_routine");
  add(stuff);
 
  return 1;
}
