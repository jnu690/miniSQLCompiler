%option noyywrap

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"
%}

%%

[ \t\r\n]+               { /* skip whitespace */ }

"SELECT"                 { return SELECT;    }
"FROM"                   { return FROM;      }
"WHERE"                  { return WHERE;     }
"AND"                    { return AND;       }
"OR"                     { return OR;        }
"*"                      { return STAR;      }

","                      { return COMMA;     }
";"                      { return SEMICOLON; }
"("                      { return LPAREN;    }
")"                      { return RPAREN;    }

">="                     { return GTE; }
"<="                     { return LTE; }
"=="                     { return EQ;  }
"!="                     { return NEQ; }
">"                      { return GT;  }
"<"                      { return LT;  }

[0-9]+\.[0-9]+           { yylval.fval = atof(yytext); return FLOAT_LIT; }
[0-9]+                   { yylval.ival = atoi(yytext); return INT_LIT;   }

\'[^\']*\'               { yylval.sval = strdup(yytext); return STRING_LIT; }
\"[^\"]+\"               { 
                            char* str = strdup(yytext);
                            if (strstr(str, ".csv") != NULL) {
                                yylval.sval = str;
                                return FILE_PATH;
                            } else {
                                yylval.sval = str;
                                return STRING_LIT;
                            }
                         }

[a-zA-Z_][a-zA-Z0-9_]*  { yylval.sval = strdup(yytext); return IDENT; }

.                        { /* skip unknown */ }

%%

