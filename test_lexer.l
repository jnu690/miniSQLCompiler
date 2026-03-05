%option noyywrap

%{
#include <stdio.h>
%}

%%

[ \t\r\n]+               { }

"SELECT"                 { printf("[SELECT]\n"); }
"FROM"                   { printf("[FROM]\n"); }
"WHERE"                  { printf("[WHERE]\n"); }
"AND"                    { printf("[AND]\n"); }
"OR"                     { printf("[OR]\n"); }
"*"                      { printf("[STAR]\n"); }

","                      { printf("[COMMA]\n"); }
";"                      { printf("[SEMICOLON]\n"); }
"("                      { printf("[LPAREN]\n"); }
")"                      { printf("[RPAREN]\n"); }

">="                     { printf("[GTE]\n"); }
"<="                     { printf("[LTE]\n"); }
"=="                     { printf("[EQ]\n"); }
"!="                     { printf("[NEQ]\n"); }
">"                      { printf("[GT]\n"); }
"<"                      { printf("[LT]\n"); }

[0-9]+\.[0-9]+           { printf("[FLOAT: %s]\n", yytext); }
[0-9]+                   { printf("[INT: %s]\n", yytext); }

\'[^\']*\'               { printf("[STRING: %s]\n", yytext); }
\"[^\"]+\"               { 
                            if (strstr(yytext, ".csv") != NULL) {
                                printf("[FILE_PATH: %s]\n", yytext);
                            } else {
                                printf("[STRING: %s]\n", yytext);
                            }
                         }

[a-zA-Z_][a-zA-Z0-9_]*  { printf("[IDENT: %s]\n", yytext); }

.                        { printf("[UNKNOWN: %s]\n", yytext); }

%%

int main() {
    yylex();
    return 0;
}