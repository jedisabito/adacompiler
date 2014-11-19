%{
/*
Joe DiSabito
10/5/14
Ada Lexer
ada.l
Lexer for ada that handles reserved words, identifiers,
numbers, and carriage returns.
*/

  #include "y.tab.h"
  int lineno = 1;
  char linebuf[500];
%}

alpha [a-zA-Z]
digits [0-9]
alphanum [a-zA-Z0-9]

%%
"end if"                        {return ENDIF;}
"end record"                    {return ENDREC;}
"end loop"                      {return ENDLOOP;}
"exit when"                     {return EXITWHEN;}
"is"                            {return IS;}  
"of"                            {return OF;}
"begin"                         {return BEG;}
"end"                           {return END;}
".."                            {return DOTDOT;}
"'"                             {return TICK;}
"procedure"                     {return PROCEDURE;}
"type"                          {return TYPE;}
"array"                         {return ARRAY;}
"record"                        {return RECORD;}
"in"                            {return IN;}
"out"                           {return OUT;}
"range"                         {return RANGE;}
"constant"                      {return CONSTANT;}
":="                            {return ASSIGN;}
"exception"                     {return EXCEPTION;}
"null"                          {return NULLWORD;}
"loop"                          {return LOOP;}
"if"                            {return IF;}
"then"                          {return THEN;}
"elsif"                         {return ELSEIF;}
"else"                          {return ELSE;}
"exit"                          {return EXIT;}
"when"                          {return WHEN;}
"and"                           {return AND;}
"or"                            {return OR;}
"not"                           {return NOT;}
"="                             {return EQ;}
"/="                            {return NEQ;}
">="                            {return GTE;}
"<="                            {return LTE;}
">"                             {return GT;}
"<"                             {return LT;}
"**"                            {return EXP;}
"raise"                         {return RAISE;}
"others"                        {return OTHERS;}
"=>"                            {return ARROW;}
"--"[^\n]*                      ;
[ \t]                           
\n.*                            {strcpy(linebuf, yytext+1);
                                 lineno++;
                                 yyless(1);}
{digits}+                       {yylval.integer = atoi(yytext); 
                                 return NUMBER;}
{alpha}({alphanum}*"_"*)*       {yylval.var = malloc(sizeof(yytext)); 
                                 strcpy(yylval.var, yytext); 
                                 return ID;}
.                               {return yytext[0];}

%%

yyerror(char *s)
{
    printf("%d: %s at '%s' in this line:\n%s\n", lineno, s, yytext, linebuf);
}