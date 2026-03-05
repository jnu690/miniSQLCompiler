%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "executor.cpp"

using namespace std;

void yyerror(const char* s);
int  yylex();

extern FILE* yyin;
%}

%union {
    int   ival;
    float fval;
    char* sval;
}

/* ── Tokens from lexer ── */
%token SELECT FROM WHERE AND OR STAR
%token COMMA SEMICOLON LPAREN RPAREN

%token GT LT GTE LTE EQ NEQ

%token <ival> INT_LIT
%token <fval> FLOAT_LIT
%token <sval> IDENT STRING_LIT FILE_PATH

%type <sval> condition columns column_list

/* ── Operator precedence ── */
%left OR
%left AND

%%

/* ── Grammar Rules ── */

query:
    SELECT columns FROM IDENT SEMICOLON
        { 
          currentQuery.table = $4;
          currentQuery.whereCondition = "";
          executeQuery();
        }

  | SELECT columns FROM FILE_PATH SEMICOLON
        { 
          std::string path = $4;
          currentQuery.table = path.substr(1, path.length()-2);
          currentQuery.whereCondition = "";
          executeQuery();
        }

  | SELECT columns FROM IDENT WHERE condition SEMICOLON
        { 
          currentQuery.table = $4;
          currentQuery.whereCondition = $6;
          executeQuery();
        }

  | SELECT columns FROM FILE_PATH WHERE condition SEMICOLON
        { 
          std::string path = $4;
          currentQuery.table = path.substr(1, path.length()-2);
          currentQuery.whereCondition = $6;
          executeQuery();
        }
  ;

columns:
    STAR
        { currentQuery.columns.clear();
          currentQuery.columns.push_back("*"); }

  | column_list
  ;

column_list:
    IDENT
        { currentQuery.columns.clear();
          currentQuery.columns.push_back($1); }

  | column_list COMMA IDENT
        { currentQuery.columns.push_back($3); }
  ;

condition:
    IDENT GT INT_LIT
        { char buf[100];
          sprintf(buf, "%s > %d", $1, $3);
          $$ = strdup(buf); }

  | IDENT LT INT_LIT
        { char buf[100];
          sprintf(buf, "%s < %d", $1, $3);
          $$ = strdup(buf); }

  | IDENT GTE INT_LIT
        { char buf[100];
          sprintf(buf, "%s >= %d", $1, $3);
          $$ = strdup(buf); }

  | IDENT LTE INT_LIT
        { char buf[100];
          sprintf(buf, "%s <= %d", $1, $3);
          $$ = strdup(buf); }

  | IDENT EQ STRING_LIT
        { char buf[100];
          sprintf(buf, "%s == %s", $1, $3);
          $$ = strdup(buf); }

  | IDENT NEQ STRING_LIT
        { char buf[100];
          sprintf(buf, "%s != %s", $1, $3);
          $$ = strdup(buf); }

  | IDENT EQ INT_LIT
        { char buf[100];
          sprintf(buf, "%s == %d", $1, $3);
          $$ = strdup(buf); }

  | IDENT NEQ INT_LIT
        { char buf[100];
          sprintf(buf, "%s != %d", $1, $3);
          $$ = strdup(buf); }

  | condition AND condition
        { char buf[200];
          sprintf(buf, "(%s AND %s)", $1, $3);
          $$ = strdup(buf); }

  | condition OR condition
        { char buf[200];
          sprintf(buf, "(%s OR %s)", $1, $3);
          $$ = strdup(buf); }

  | LPAREN condition RPAREN
        { $$ = $2; }
  ;

%%

void yyerror(const char* s) {
    fprintf(stderr, "\n❌ Parse Error: %s\n", s);
}

int main() {
    printf("Mini-SQL Parser\n");
    printf("---------------\n");
    printf("Enter your query:\n\n");
    yyparse();
    return 0;
}