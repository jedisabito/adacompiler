%{
  /*
    Joe DiSabito
    10/5/14
    ada.y
    Still need to figure out: condition
   */

  extern int lineno;
%}

%token IS BEG END PROCEDURE ID NUMBER TYPE ARRAY RAISE OTHERS
%token RECORD IN OUT RANGE CONSTANT ASSIGN EXCEPTION NULLWORD LOOP IF
%token THEN ELSEIF ELSE EXIT WHEN AND OR EQ NEQ LT GT GTE LTE TICK
%token NOT EXP ARROW OF DOTDOT ENDIF ENDREC ENDLOOP EXITWHEN
%type <integer> NUMBER loop
%type <integer> constant multiplying_op adding_op
%type <var> ID type_name boolean_op
%type <op> relational_op
%type <mode> mode
%type <theList> identifier_list
%type <symbol_table_ptr> variable_decl formal_parameter_part
%type <symbol_table_ptr> formal_parameter_list_2 proc_head procedure_specification
%type <expr_tree_ptr> primary term simple_expr relation expression
%type <expr_tree_ptr> factor begin condition expression_list opt_assign
%union {
  int integer;
  char op;
  char *var;
  struct Node *symbol_table_ptr;
  struct exprNode *expr_tree_ptr;
  char *mode;
  struct idnode *theList;
}

%%

ada_main    : procedure_specification IS
                  declarative_part
                  proc_list
              begin
                  sequence_of_statements
                  exception_part 
              END ';' 
{
  if (top >= 1 && $1 != NULL && $5 != NULL){
    $1->data.offset = binStack[top].arSize;
    $1->data.address = $5->address;
  }

  printf("\nPopping scope %s:\n", binStack[top].nombre);
  printTree(binStack[top].root);
  
  fprintf(fp, "%i:  r%i := contents b, 1\n", instCtr++, regNum);
  fprintf(fp, "%i:  b := contents b, 3\n", instCtr++);
  fprintf(fp, "%i:  pc := r%i\n", instCtr++, regNum++);

  if (top == 1){
    patchList = addPatch(patchList, instCtr, 0);
    patchList = addPatch(patchList, instCtr + binStack[top].arSize, 1);
  }

  pop(); 

}
; 

procedure_specification : proc_head formal_parameter_list
;

proc_head : PROCEDURE ID
{
  printf("\nPushing scope %s:\n", $2);

  offset = 4;

  if (top == 0){
    fprintf(fp, "%i:  b := ?\n", instCtr); instCtr++;
    fprintf(fp, "%i:  contents b, 0 := ?\n", instCtr); instCtr++;
    fprintf(fp, "%i:  contents b, 1 := 4\n", instCtr); instCtr++;
    fprintf(fp, "%i:  pc := ?\n", instCtr); instCtr++;
    fprintf(fp, "%i:  halt\n", instCtr); instCtr++;
  }else{
    struct Entry stuff;

    stuff.name = mallocCpy($2);
    stuff.kind = mallocCpy("procedure");
    stuff.parent_type = NULL;
  
    if (binStack[top].root != NULL && strcmp(binStack[top].root->data.kind, "parm") == 0){
      stuff.next = binStack[top].root;
    }else{
      stuff.next = NULL;
    }

    if (!add(stuff)){
      yyerror("procedure name appears more than once in context"); 
    }

    $$ = search($2);
  }

  push($2);

} 
;

begin : BEG
{

  if (top == 1){
    patchList = addPatch(patchList, instCtr, 3);
  }

  $$ = (struct exprNode*)malloc(sizeof(struct exprNode));
  $$->kind = mallocCpy("procedure");
  $$->address = instCtr;
}
;

formal_parameter_list   : '(' formal_parameter_list_2 ')'
                        |
;

formal_parameter_list_2 : formal_parameter_part ';' formal_parameter_list_2
{
  $1->data.next = $3;
}
| formal_parameter_part {$$ = $1;}
;

formal_parameter_part   : identifier_list ':' mode type_name
{
  struct idnode *tempList = malloc(sizeof(struct idnode));
  tempList = $1;

  //gets the procedure
  struct Node *temp = search(binStack[top].nombre);
  
  //gets to the last node in the string of nexts
  while (temp->data.next != NULL){
    temp = temp->data.next;
  }

  //goes through list of id's
  while (tempList != NULL){
    struct Entry stuff;
    
    //adds id to top table
    stuff.name = mallocCpy(tempList->name);
    stuff.kind = mallocCpy("parm");
    stuff.mode = mallocCpy($3);
    stuff.parent_type = search($4);
    if (stuff.parent_type == NULL){
      yyerror("parent_type not found");
    }
    stuff.size = stuff.parent_type->data.size;
    offset += stuff.size;
    stuff.offset = offset;
    if (!add(stuff)) yyerror("procedure param already exists in local symbol table");
    
    //updates next
    temp->data.next = search(stuff.name);
    temp = temp->data.next;

    //goes to next id
    tempList = tempList->next;
  }
  
  //returns end of list of nexts
  $$ = temp;

  //resets theList
  theList = NULL;
}
;

type_name : ID {$$ = mallocCpy($1);}
;

mode : IN {$$ = mallocCpy("in");}
     | OUT {$$ = mallocCpy("out");}
     | IN OUT {$$ = mallocCpy("in out");}
     |
;

declarative_part : declarative_option ';' declarative_part
{
  binStack[top].arSize = offset;
}
                 |
{
  binStack[top].arSize = offset;
}
;

proc_list : ada_main proc_list
          |
;

declarative_option : array 
                   | record
                   | range 
                   | variable_decl
                   | constant_decl
                   | exception    
;


array : TYPE ID IS ARRAY '(' constant DOTDOT constant ')' OF type_name
{
  struct Entry stuff;

  stuff.name = mallocCpy($2);
  stuff.kind = mallocCpy("array");
  stuff.lower = $6;
  stuff.upper = $8;
  stuff.parent_type = search($11);
  if (stuff.parent_type == NULL){
      yyerror("parent_type not found");
  }
  stuff.size = stuff.parent_type->data.size * (stuff.upper - stuff.lower + 1);
  stuff.next = NULL;
  if (!add(stuff)) yyerror("array name already exists in local symbol table");
}
;

record : TYPE ID IS RECORD component_list ENDREC
{
  
}
;

range : TYPE ID IS RANGE constant DOTDOT constant
{
  struct Entry stuff;

  stuff.name = mallocCpy($2);
  stuff.kind = mallocCpy("range");
  stuff.lower = $5;
  stuff.upper = $7;
  stuff.parent_type = search("integer");
  stuff.size = stuff.parent_type->data.size;
  stuff.next = NULL;
  if (!add(stuff)) yyerror("range name already exists in local symbol table");
}
;

exception : identifier_list ':' EXCEPTION
{
  struct idnode *tempList = malloc(sizeof(struct idnode));
  tempList = $1;
  printf("line#: %i - ", lineno);
  int error = 0;
  while (tempList != NULL){
    struct Entry stuff;
    stuff.name = mallocCpy(tempList->name);
    printf("%s ", tempList->name);
    stuff.kind = mallocCpy("exception");
    stuff.parent_type = NULL;
    stuff.next = NULL;
    if (!add(stuff)) {
      error = 1;
      yyerror("symbol already exists in local symbol table");
    }
    tempList = tempList->next;
  }
  if (!error){
    printf(": exception\n");
  }
  theList = NULL;
}  
;

constant_decl : identifier_list ':' CONSTANT ASSIGN constant_expression
{
  theList = NULL;
}
;

constant_expression : expression
;

component_list : component_list variable_decl ';' 
               | variable_decl ';'
;

variable_decl : identifier_list ':' type_name
{
  struct idnode *tempList = malloc(sizeof(struct idnode));
  tempList = $1;
  printf("line#: %i - ", lineno);
  int error = 0;
  while (tempList != NULL){
    struct Entry stuff;
    stuff.name = mallocCpy(tempList->name);
    printf("%s ", tempList->name);
    stuff.kind = mallocCpy("variable");
    stuff.parent_type = search($3);
    if (stuff.parent_type == NULL){
      yyerror("parent_type not found");
    }
    stuff.size = stuff.parent_type->data.size;
    if (strcmp(stuff.parent_type->data.kind, "array") == 0){
      int lower = stuff.parent_type->data.lower;
      stuff.offset = offset - lower; 
    }else{
      stuff.offset = offset;
    }
    offset += stuff.size;
    stuff.next = NULL;
    if (!add(stuff)) {
      error = 1;
      yyerror("symbol already exists in local symbol table");
    }
    tempList = tempList->next;
  }
  if (!error){
    printf(": %s\n", $3);
  }
  theList = NULL;
}
; 

identifier_list : ID ',' identifier_list {theList = addID(theList, $1); $$ = theList;}
| ID {theList = addID(theList, $1); $$ = theList;}
;

constant : ID 
{
  struct Node *temp = search($1);
  if (search($1) == NULL) yyerror("constant ID not found");
  $$ = temp->data.value;
} 
| NUMBER {$$ = $1;}
;

sequence_of_statements : statement sequence_of_statements
                       | statement
;

statement : NULLWORD ';'
          | var_assignment
          | procedure_call
          | loop_stuff
          | exit
          | exit_when
          | if_statement
          | RAISE ID ';'
;

if_statement : if_header
                  then_stmts
                  else_if_list
                  optional_else
               endif ';'
;

then_stmts : sequence_of_statements
{
  fprintf(fp, "%i:  pc := ?\n", instCtr);
  lpAdd(base[topBase], instCtr++);
}
;

if_header : if condition THEN
{
  if (strcmp($2->kind, "register") == 0){
    fprintf(fp, "%i:  pc := ? if not r%i\n", instCtr, $2->address);
  }else{
    fprintf(fp, "%i:  r%i := %i\n", instCtr++, regNum, $2->value);
    fprintf(fp, "%i:  pc := ? if not r%i\n", instCtr, regNum++);
  }
  lpPush();
  lpAdd(lpTop, instCtr++);
}
;

if : IF
{
  lpPush();
  base[++topBase] = lpTop;
}
;

endif : ENDIF
{
  patchList = lpGetPop(patchList, instCtr);
  topBase--;
}
;

else_if_list : else_if_stmt
               else_if_list
             |
;

else_if_stmt : else_if_header
                 sequence_of_statements
{
  fprintf(fp, "%i:  pc := ?\n", instCtr);
  lpAdd(base[topBase], instCtr++);
}
;

else_if_header : else_if condition THEN
{
  if (strcmp($2->kind, "register") == 0){
    fprintf(fp, "%i:  pc := ? if not r%i\n", instCtr, $2->address);
  }else{
    fprintf(fp, "%i:  r%i := %i\n", instCtr++, regNum, $2->value);
    fprintf(fp, "%i:  pc := ? if not r%i\n", instCtr, regNum++);
  }
  lpPush();
  lpAdd(lpTop, instCtr++);  
}
;

else_if : ELSEIF
{
  patchList = lpGetPop(patchList, instCtr);
}
;

optional_else : else sequence_of_statements
              |
{
  patchList = lpGetPop(patchList, instCtr);
}
;

else : ELSE
{
  patchList = lpGetPop(patchList, instCtr);
}
;

exit : EXIT ';'
{
  fprintf(fp, "%i:  pc := ?\n", instCtr);
  lpAdd(lpTop, instCtr++);
}
;

exit_when : EXITWHEN condition ';'
{
  if (strcmp($2->kind, "number") == 0){
    fprintf(fp, "%i:  r%i = %i", instCtr++, regNum, $2->value);
    fprintf(fp, "%i:  pc := ? if r%i\n", instCtr, regNum++);
  }else{
    fprintf(fp, "%i:  pc := ? if r%i\n", instCtr, $2->address);
  }
  lpAdd(lpTop, instCtr++);
}
;

loop_stuff : loop sequence_of_statements ENDLOOP ';'
{
  fprintf(fp, "%i:  pc := %i\n", instCtr++, $1);
  patchList = lpGetPop(patchList, instCtr);
}
;

loop : LOOP
{
  $$ = instCtr;
  lpPush();
}
;

var_assignment : ID ASSIGN expression ';'
{
  struct Node *temp = search($1);
  if (temp == NULL){
    yyerror("ID not found");
  }else if (strcmp(temp->data.kind, "array") == 0){
    yyerror("must specify index for array assignment");
  }else{
 
    if (temp->data.depth == 0){
      if (strcmp($3->kind, "number") == 0){
	fprintf(fp, "%i:  r%i := %i\n", instCtr++, regNum, $3->value);
	fprintf(fp, "%i:  contents b, %i := r%i\n", instCtr++, temp->data.offset, regNum++);
      }else{
	fprintf(fp, "%i:  contents b, %i := r%i\n", instCtr++, temp->data.offset, $3->address);
      }
    }else{
      int depth = temp->data.depth;
      int firstTime = 1;
      while (depth  > 0){
	if (firstTime){
	  fprintf(fp, "%i:  r%i := contents b, 2\n", instCtr, regNum);
	  instCtr++;
	  firstTime = 0;
	}else{
	  fprintf(fp, "%i:  r%i := contents r%i, 2\n", instCtr, regNum, regNum);
	  instCtr++;
	}
	depth--;
      }

      regNum++;

      if (strcmp($3->kind, "number") == 0){
	fprintf(fp, "%i:  r%i := %i\n", instCtr++, regNum++, $3->value);
	fprintf(fp, "%i:  contents r%i, %i := r%i\n", instCtr++, regNum - 2, temp->data.offset, regNum - 1);
      }else{
	fprintf(fp, "%i:  contents r%i, %i := r%i\n", instCtr++, regNum - 1, temp->data.offset, $3->address);
      }
    }
  }
}
;

procedure_call : ID '(' expression_list ')' opt_assign ';'
{
  struct Node *temp = search($1);
  if ($5 != NULL){
    if (temp != NULL){
      if (strcmp($3->kind, "number") == 0 && strcmp($5->kind, "number") == 0){
	fprintf(fp, "%i:  contents b, %i := %i\n", instCtr++, temp->data.offset + $3->value, $5->value);
      }else if (strcmp($3->kind, "number") == 0 && strcmp($5->kind, "register") == 0){
	fprintf(fp, "%i:  contents b, %i := r%i\n", instCtr++, temp->data.offset + $3->value, $5->address);
      }else if (strcmp($3->kind, "register") == 0 && strcmp($5->kind, "number") == 0){
	int offsetStore = regNum++; int sumStore = regNum++;
	fprintf(fp, "%i:  r%i := %i\n", instCtr++, offsetStore, temp->data.offset);
	fprintf(fp, "%i:  r%i := r%i + r%i\n", instCtr++, sumStore, $3->address, offsetStore);
	fprintf(fp, "%i:  contents b, r%i := %i\n", instCtr++, sumStore, $5->value);
      }else{
	int offsetStore = regNum++; int sumStore = regNum++;
	fprintf(fp, "%i:  r%i := %i\n", instCtr++, offsetStore, temp->data.offset);
	fprintf(fp, "%i:  r%i := r%i + r%i\n", instCtr++, sumStore, $3->address, offsetStore);
	fprintf(fp, "%i:  contents b, r%i := r%i\n", instCtr++, sumStore, sumStore);
      }

    }else{
      yyerror("ID is not a defined array");
    }
  }else{
    if (temp == NULL){
      yyerror("procedure name not found");
    }else{
      if (strcmp(temp->data.kind, "write_routine") == 0){
	struct exprNode *temp = $3;
	while (temp != NULL){
	  if (strcmp($3->kind, "number") == 0){ 
	    fprintf(fp, "%i:  write %i\n", instCtr++, temp->value);
	  }else{
	    fprintf(fp, "%i:  write r%i\n", instCtr++, temp->address);
	  }
	  temp = temp->next;
	}
      }else if (strcmp(temp->data.kind, "read_routine") == 0){
	struct exprNode *temp = $3;
	if (temp->next == NULL){
	  if (strcmp($3->kind, "number") == 0){ 
	    yyerror("cannot read a number");
	  }else{
	    if ($3->opDone){
	      yyerror("read can only take in variables as parameters");
	    }else{
	      fprintf(fp, "%i:  read r%i\n", instCtr++, temp->address);
	    }
	  }
	}else{
	  yyerror("read can only take in one parameter");
	}
      }else if (strcmp(temp->data.kind, "array") == 0){
	yyerror("reference to array item without assignment");
      }
    }
  }
}
|
ID ';'
{
  struct Node *temp = search($1);
  if (temp != NULL){
    fprintf(fp, "%i:  r%i := b\n", instCtr++, regNum);
    fprintf(fp, "%i:  b := contents r%i, 0\n", instCtr++, regNum);
    fprintf(fp, "%i:  contents b, 3 := r%i\n", instCtr++, regNum);

    //static link
    
    if (temp->data.depth == 0){
      fprintf(fp, "%i:  contents b, 2 := r%i\n", instCtr, regNum);
      instCtr++;
    }else{
      int depth = temp->data.depth;
      int firstTime = 1;
      while (depth > 1){
	
	fprintf(fp, "%i:  r%i := contents r%i, 2\n", instCtr, regNum, regNum);
	instCtr++;
	depth--;
      }

      fprintf(fp, "%i:  contents b, 2 := contents r%i, 2\n", instCtr, regNum, regNum);
      instCtr++;

    }

    regNum++;
    
    fprintf(fp, "%i:  r%i := %i\n", instCtr++, regNum, temp->data.offset);
    fprintf(fp, "%i:  contents b, 0 := b + r%i\n", instCtr++, regNum++);
    fprintf(fp, "%i:  r%i := %i\n", instCtr, regNum, instCtr + 3); instCtr++;
    fprintf(fp, "%i:  contents b, 1 := r%i\n", instCtr++, regNum++);
    fprintf(fp, "%i:  pc := %i\n", instCtr++, temp->data.address);
  }else{
    yyerror("procedure ID not found");
  }
}
;

opt_assign : ASSIGN expression
{
  $$ = $2;
}
|
{
  $$ = NULL;
}
;

condition : expression
;

expression_list : expression ',' expression_list
{
  $1->next = $3;
}
| expression
{
  $$ = $1;
  $$->next = NULL;
}
;

expression : relation
| expression boolean_op relation
{
  $$ = (struct exprNode*)malloc(sizeof(struct exprNode)); 
  
  if (strcmp($1->kind, "number") == 0 && strcmp($3->kind, "number") == 0){
    $$->kind = mallocCpy("number");
    if (strcmp($2, "and") == 0){
      $$->value = $1->value && $3->value;
    }else{
      $$->value = $1->value || $3->value;
    }
  }else{
    $$->kind = mallocCpy("register");

    if (strcmp($1->kind, "register") == 0 && strcmp($3->kind, "number") == 0){

      int twoReg = regNum;
      fprintf(fp, "%i:  r%i := %i\n", instCtr++, regNum++, $3->value);

      fprintf(fp, "%i:  r%i := r%i %s r%i\n", instCtr++, regNum, $1->address, $2, twoReg); 
  
    }else if (strcmp($1->kind, "number") == 0 && strcmp($3->kind, "register") == 0){

      int oneReg = regNum;
      fprintf(fp, "%i:  r%i := %i\n", instCtr++, regNum++, $1->value);

      fprintf(fp, "%i:  r%i := r%i %s r%i\n", instCtr++, regNum, oneReg, $2, $3->address);

    }else{
      fprintf(fp, "%i:  r%i := r%i %s r%i\n", instCtr++, regNum, $1->address, $2, $3->address);
    }    

    $$->address = regNum++;
    $$->opDone = 1;
  }
} 
;

relation : simple_expr 
| relation relational_op simple_expr
{
  $$ = (struct exprNode*)malloc(sizeof(struct exprNode)); 
  
  if (strcmp($1->kind, "number") == 0 && strcmp($3->kind, "number") == 0){
    $$->kind = mallocCpy("number");

    switch ($2){
      case '=':
	$$->value = $1->value == $3->value;
	break;
      case '!':
	$$->value = $1->value != $3->value;
	break;
      case '<':
	$$->value = $1->value < $3->value;
	break;
      case 'L':
	$$->value = $1->value <= $3->value;
	break;
      case '>':
	$$->value = $1->value > $3->value;
	break;
      case 'G':
	$$->value = $1->value >= $3->value;
    }
  }else{
    $$->kind = mallocCpy("register");
    char *token;
    int change = 0;

    switch ($2){
      case '=':
	token = mallocCpy("=");
	break;
      case '!':
	token = mallocCpy("/=");
	break;
      case '<':
	token = mallocCpy("<");
	break;
      case 'L':
	token = mallocCpy("<=");
	break;
      case '>':
	token = mallocCpy("<");
	change = 1;
	break;
      case 'G':
	token = mallocCpy("<=");
	change = 1;
    }

    if (strcmp($1->kind, "register") == 0 && strcmp($3->kind, "number") == 0){

      int twoReg = regNum;
      fprintf(fp, "%i:  r%i := %i\n", instCtr++, regNum++, $3->value);

      if (change == 1){
	fprintf(fp, "%i:  r%i := r%i %s r%i\n", instCtr++, regNum, twoReg, token, $1->address);
      }else{
	fprintf(fp, "%i:  r%i := r%i %s r%i\n", instCtr++, regNum, $1->address, token, twoReg);
      } 
  
    }else if (strcmp($1->kind, "number") == 0 && strcmp($3->kind, "register") == 0){

      int oneReg = regNum;
      fprintf(fp, "%i:  r%i := %i\n", instCtr++, regNum++, $1->value);

      if (change == 1){
	fprintf(fp, "%i:  r%i := r%i %s r%i\n", instCtr++, regNum, $3->address, token, oneReg);
      }else{
	fprintf(fp, "%i:  r%i := r%i %s r%i\n", instCtr++, regNum, oneReg, token, $3->address);
      }

    }else{
      if (change == 1){
	fprintf(fp, "%i:  r%i := r%i %s r%i\n", instCtr++, regNum, $3->address, token, $1->address);
      }else{
	fprintf(fp, "%i:  r%i := r%i %s r%i\n", instCtr++, regNum, $1->address, token, $3->address);
      }
    }
    $$->address = regNum++;
    $$->opDone = 1;
  }
 
}
;

simple_expr : '-' term
{
  $$ = (struct exprNode*)malloc(sizeof(struct exprNode)); 
  
  if (strcmp($2->kind, "number") == 0){
    $$->kind = mallocCpy("number");
    $$->value = -1 * $2->value;
  }else{
    $$->kind = mallocCpy("register");

    fprintf(fp, "%i:  r%i := - r%i\n", instCtr++, regNum, $2->address); 

    $$->address = regNum++;
    $$->opDone = 1;
  }
}
| term 
| simple_expr adding_op term
{
  $$ = (struct exprNode*)malloc(sizeof(struct exprNode)); 
  
  if (strcmp($1->kind, "number") == 0 && strcmp($3->kind, "number") == 0){
    $$->kind = mallocCpy("number");
    $$->value = $1->value + $2 * $3->value;
  }else{
    $$->kind = mallocCpy("register");
    
    char sign;
    if ($2 == 1){
      sign = '+';
    }else{
      sign = '-';
    }

    if (strcmp($1->kind, "register") == 0 && strcmp($3->kind, "number") == 0){

      int twoReg = regNum;
      fprintf(fp, "%i:  r%i := %i\n", instCtr++, regNum++, $3->value);

      fprintf(fp, "%i:  r%i := r%i %c r%i\n", instCtr++, regNum, $1->address, sign, twoReg); 
  
    }else if (strcmp($1->kind, "number") == 0 && strcmp($3->kind, "register") == 0){

      int oneReg = regNum;
      fprintf(fp, "%i:  r%i := %i\n", instCtr++, regNum++, $1->value);

      fprintf(fp, "%i:  r%i := r%i %c r%i\n", instCtr++, regNum, oneReg, sign, $3->address);

    }else{
      fprintf(fp, "%i:  r%i := r%i %c r%i\n", instCtr++, regNum, $1->address, sign, $3->address);
    }

    $$->address = regNum++;
    $$->opDone = 1;
  }
  
}
;

term : factor
     | term multiplying_op factor
{
  $$ = (struct exprNode*)malloc(sizeof(struct exprNode)); 
  
  if (strcmp($1->kind, "number") == 0 && strcmp($3->kind, "number") == 0){
    $$->kind = mallocCpy("number");
    $$->value = $1->value * pow($3->value, $2);
  }else{
    $$->kind = mallocCpy("register");
       char sign;
    if ($2 == 1){
      sign = '*';
    }else{
      sign = '/';
    }

    if (strcmp($1->kind, "register") == 0 && strcmp($3->kind, "number") == 0){

      int twoReg = regNum;
      fprintf(fp, "%i:  r%i := %i\n", instCtr++, regNum++, $3->value);

      fprintf(fp, "%i:  r%i := r%i %c r%i\n", instCtr++, regNum, $1->address, sign, twoReg); 
  
    }else if (strcmp($1->kind, "number") == 0 && strcmp($3->kind, "register") == 0){

      int oneReg = regNum;
      fprintf(fp, "%i:  r%i := %i\n", instCtr++, regNum++, $1->value);

      fprintf(fp, "%i:  r%i := r%i %c r%i\n", instCtr++, regNum, oneReg, sign, $3->address);

    }else{
      fprintf(fp, "%i:  r%i := r%i %c r%i\n", instCtr++, regNum, $1->address, sign, $3->address);
    }
    $$->address = regNum++;
  }
}
;


factor : primary 
| factor EXP primary
{
  $$ = (struct exprNode*)malloc(sizeof(struct exprNode)); 
  
  if (strcmp($1->kind, "number") == 0 && strcmp($3->kind, "number") == 0){
    $$->kind = mallocCpy("number");
    $$->value = pow($1->value, $3->value); 
  }else{
    
    int loop = instCtr + 9;
    int end = loop + 7;

    if (strcmp($1->kind, "number") == 0) loop++; end++;

    int powerStore = regNum;
    if (strcmp($3->kind, "number") == 0){
      regNum++;
      fprintf(fp, "%i:  r%i := %i\n", instCtr++, powerStore, $1->value);
      loop++;
      end++;
    }

    //r1
    int startReg = regNum;
    fprintf(fp, "%i:  r%i := 1\n", instCtr++, regNum++);

    //r2
    int expReg = regNum;
    if (strcmp($3->kind, "register") == 0){
      fprintf(fp, "%i:  r%i := r%i\n", instCtr++, regNum++, $3->address); 
    }else{
      fprintf(fp, "%i:  r%i := %i\n", instCtr++, regNum++, $3->value);
    }

    int zeroReg = regNum++;
    fprintf(fp, "%i:  r%i := 0\n", instCtr++, zeroReg);

    //r3
    int compReg = regNum++;
    fprintf(fp, "%i:  r%i := r%i = r%i\n", instCtr++, compReg, expReg, zeroReg);
    fprintf(fp, "%i:  pc := %i if r%i\n", instCtr++, end, compReg);

    int oneReg = regNum++;
    fprintf(fp, "%i:  r%i := 1\n", instCtr++, oneReg);

    //2
    fprintf(fp, "%i:  r%i := r%i <= r%i\n", instCtr++, compReg, zeroReg, expReg);

    //jump loop if r3
    fprintf(fp, "%i:  pc := %i if r%i\n", instCtr++, loop, compReg);
    fprintf(fp, "%i:  r%i := - r%i\n", instCtr++, expReg, expReg);


    //$1
    int baseReg = regNum;

    //r1 := r1 * $1
    if (strcmp($1->kind, "number") == 0){
      fprintf(fp, "%i:  r%i := %i\n", instCtr++, baseReg, $1->value);
      fprintf(fp, "%i:  r%i := r%i * r%i\n", instCtr++, startReg, startReg, baseReg);
      regNum++;
    }else{
      fprintf(fp, "%i:  r%i := r%i * r%i\n", instCtr++, startReg, startReg, $1->address);
    }

    //r2 := r2 - 1
    fprintf(fp, "%i:  r%i := r%i - r%i\n", instCtr++, expReg, expReg, oneReg); 

    //r3 := 0 < r2
    fprintf(fp, "%i:  r%i := r%i < r%i\n", instCtr++, compReg, zeroReg, expReg);

    //jump loop if r3
    fprintf(fp, "%i:  pc := %i if r%i\n", instCtr++, loop, compReg);

    //r3 = 0 <= $2
    if (strcmp($3->kind, "number") != 0){
      fprintf(fp, "%i:  r%i := r%i <= r%i\n", instCtr++, compReg, zeroReg, $3->address);
    }else{
      fprintf(fp, "%i:  r%i := r%i <= r%i\n", instCtr++, compReg, zeroReg, powerStore);
    }
    
    //jump end if r3
    fprintf(fp, "%i:  pc := %i if r%i\n", instCtr++, end, compReg);

    //r1 := 1 / r1
    fprintf(fp, "%i:  r%i := r%i / r%i\n", instCtr++, startReg, oneReg, startReg);
    

    $$->kind = mallocCpy("register");
    $$->address = startReg;
    $$->opDone = 1;
  }
  
}
       | NOT primary
{

  $$ = (struct exprNode*)malloc(sizeof(struct exprNode));

  if (strcmp($2->kind, "number") == 0){
    $$->kind = mallocCpy("number");
    $$->value = !$2->value;
  }else{
    $$->kind = mallocCpy("register");
    fprintf(fp, "%i:  r%i := not r%i\n", instCtr++, regNum, $2->address);

    $$->address = regNum++;
  }
  $$->opDone = 1;
}
;

primary : NUMBER
{ 
  $$ = (struct exprNode*)malloc(sizeof(struct exprNode));
  $$->kind = mallocCpy("number");
  $$->value = $1;
  $$->opDone = 0;
}
| ID
{
  
  int enum_type = 0;

  struct Node *temp = search($1);

  if (temp == NULL){
    yyerror("primary ID not found");
  }else{
    if (temp->data.depth == top && strcmp(temp->data.kind, "value") == 0){
      $$ = (struct exprNode*)malloc(sizeof(struct exprNode));
      $$->kind = mallocCpy("number");
      $$->value = temp->data.value;
      enum_type = 1;
    }else if (temp->data.depth == 0){
      fprintf(fp, "%i:  r%i := contents b, %i\n", instCtr, regNum, temp->data.offset);
      instCtr++;
    }else{
      int depth = temp->data.depth;
      int firstTime = 1;
      while (depth  > 0){
	if (firstTime){
	  fprintf(fp, "%i:  r%i := contents b, 2\n", instCtr, regNum);
	  instCtr++;
	  firstTime = 0;
	}else{
	  fprintf(fp, "%i:  r%i := contents r%i, 2\n", instCtr, regNum, regNum);
	  instCtr++;
	}
	depth--;
      }

      fprintf(fp, "%i:  r%i := contents r%i, %i\n", instCtr, regNum, regNum, temp->data.offset);
      instCtr++;

    }
    if (!enum_type){
      $$ = (struct exprNode*)malloc(sizeof(struct exprNode));
      $$->kind = mallocCpy("register");
      $$->offset = temp->data.offset;
      $$->address = regNum++;
      $$->opDone = 0;
    }
  }
  
}
| '(' expression ')'
{
  $$ = $2;
}
| ID '(' expression ')'
{
  struct Node *temp = search($1);
  if (temp == NULL){
    yyerror("ID not a defined array");
  }else{
    if (strcmp($3->kind, "number") == 0){
      fprintf(fp, "%i:  r%i := contents b, %i\n", instCtr++, regNum, $3->value + temp->data.offset);  
    }else{
      int offsetStore = regNum++; int sumStore = regNum++;
      fprintf(fp, "%i:  r%i := %i\n", instCtr++, offsetStore, temp->data.offset);
      fprintf(fp, "%i:  r%i := r%i + r%i\n", instCtr++, sumStore, $3->address, offsetStore);
      fprintf(fp, "%i:  r%i := contents b, r%i\n", instCtr++, regNum, sumStore);
    }
    $$ = (struct exprNode*)malloc(sizeof(struct exprNode));
    $$->kind = mallocCpy("register");
    $$->offset = temp->data.offset;
    $$->address = regNum++;
    $$->opDone = 0;
  }
}
;

boolean_op : AND 
{
  $$ = mallocCpy("and");
}
| OR
{
  $$ = mallocCpy("or");
}
;

relational_op : EQ 
{
  $$ = '=';
}
| NEQ 
{
  $$ = '!';
}
| LT 
{
  $$ = '<';
}
| GT 
{
  $$ = '>';
}
| LTE 
{
  $$ = 'L';
}
| GTE
{
  $$ = 'G';
}
;

adding_op : '+' 
{
  $$ = 1;
}
| '-'
{
  $$ = -1;
}
;

multiplying_op : '*' 
{
  $$ = 1;
}
| '/'
{
  $$ = -1;
}
;

exception_part : EXCEPTION exception_handler_list
               |
;

exception_handler_list : exception_handler_list exception_handler 
                       | exception_handler
;

exception_handler : WHEN choice_sequence ARROW sequence_of_statements
;

choice_sequence : choice_sequence '|' ID 
                | ID
                | OTHERS
;

%%
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
#include "liststruct.c"
#include "binTree.h"
#include "patchList.h"

struct idnode *theList = NULL;
int offset = 4;
int mainOffset = 4;

int instCtr = 0;
int regNum = 1;

FILE *fp, *fp2;

int base[50];
int topBase = 0;

struct exprNode {
  char *kind;
  struct exprNode *next;
  int offset, address, value, opDone;
};

struct patchNode *patchList = NULL;

main()
{

  fp = fopen("output.txt", "w");

  init();
  printf("Outer context:\n");
  printTree(binStack[top].root);

  yyparse();
  printf("Scanning complete.\n");

  fclose(fp);
  
  fp = fopen("output.txt", "r");
  fp2 = fopen("patched.txt", "w");

  patchFile(fp, fp2, patchList);

  fclose(fp);
  fclose(fp2);
  
}
