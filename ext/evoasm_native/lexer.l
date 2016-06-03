%{
#include <uchar.h>
#include "evoasm-parser.h"
#include "evoasm-token.h"
#include "evoasm-asg.h"
#include "evoasm-log.h"

EVOASM_DECL_LOG_TAG("lexer")

static evoasm_token *
new_token(_evoasm_parse_ctx *ctx, uint16_t token_id) {
  evoasm_asg_node *node;

  evoasm_asg_add(ctx->asg, &node);

  node->token.id = (uint16_t) token_id;
  node->token.line = ctx->line;
  node->token.col = ctx->last_col;
  node->token.begin = ctx->last_pos;
  node->token.end = ctx->pos;

  return &node->token;
}

static size_t
unescape_ml_comment(char *string, size_t len, char *buffer)
{
  size_t i, j = 0;
  for(i = 0; i < len; i++)
  {
    if(string[i] == '\\' && i < len - 3 && string[i + 1] == '#' && string[i + 2] == '#' && string[i + 3] == '#')
      continue;
    else
      buffer[j++] = string[i];
  }
  return j;
}

static size_t
unescape_snglq(char *string, size_t len, char *buffer, char str_char)
{
  size_t i, j = 0;
  for(i = 0; i < len; i++)
  {
    /* escape /' /] etc.  and // */
    if(string[i] == '\\'
       && (i + 1 < len)
       && (string[i + 1] == str_char || string[i + 1] == '\\')) {
      continue;
    }
    else
    {
      buffer[j++] = string[i];
    }
  }
  return j;
}

static size_t
unescape_regexp(char *string, size_t len, char *buffer, char str_char)
{
  return unescape_snglq(string, len, buffer, str_char);
}

static size_t
unescape_dblq(char *string, size_t len, char *buffer, char str_char)
{
  size_t i = 0, j = 0;
  bool esc = false;

  while(i < len)
  {

    if(string[i] == '\\' && !esc)
    {
      esc = true;
      i++;

      continue;
    }

    if(esc)
    {
      char c;

      esc = false;
      c = string[i++];
      switch(c)
      {
        case 'b':
          buffer[j++] = '\b';
          break;
        case 'a':
          buffer[j++] = '\a';
          break;
        case 'v':
          buffer[j++] = '\v';
          break;
        case 'f':
          buffer[j++] = '\f';
          break;
        case 'n':
          buffer[j++] = '\n';
          break;
        case 'r':
          buffer[j++] = '\r';
          break;
        case 't':
          buffer[j++] = '\t';
          break;
        case 'u':
        {
          char32_t code_point[] = {0, 0};
          char u8_buffer[MB_CUR_MAX];
          size_t u8_len = 0;

          (void) sscanf(string + i, "%4x", code_point);

          u8_len = c32rtomb(u8_buffer, code_point[0], NULL);

          if(u8_len == (size_t)-1) {
            evoasm_warn("Invalid unicode escape");
          }

          for(size_t k = 0; k < u8_len; k++)
          {
            buffer[j++] = u8_buffer[k];
          }
          i += 4;
          break;
        }
        default:
        {
          buffer[j++] = c;
        }
      }
    }
    else
    {
      buffer[j++] = string[i++];
    }
  }
  return j;
}

static int
count_newlines(const char *buffer, size_t len)
{
  int newlines = 0;

  for(size_t i = 0; i < len; i++)
  {
    if(buffer[i] == '\n')
      newlines++;
  }
  return newlines;
}

static void
update_lineno(_evoasm_parse_ctx *ctx, const char *text, size_t len)
{
  int nls = count_newlines(text, len);
  if(nls > 0)
  {
    ctx->col = 1;
    ctx->last_col = 1;
    ctx->last_line = ctx->line;
    ctx->line += (uint32_t) nls;
  }
}

#define NEW_TOKEN(t) new_token(yyctx, EVOASM_TOKEN_ID_##t)

#define yyctx (yyextra)
#define YIELD_SIMPLE_TOKEN(id) yield_token(yyextra, NEW_TOKEN(id));

#define YYLESS(n)\
  do {\
    yyctx->column -= (yyleng - n);\
    yyctx->pos -= (yyleng - n);\
    yyless(n);\
  } while(0);

#define YYMORE()\
  do {\
    yyctx->col -= (uint32_t) yyleng;\
    yyctx->pos -= (uint32_t) yyleng;\
    yymore();\
  } while(0);

#define YY_USER_ACTION\
  do {\
    yyctx->last_col = yyctx->col;\
    yyctx->col += (uint32_t) yyleng;\
    yyctx->last_pos = yyctx->pos;\
    yyctx->pos += (uint32_t) yyleng;\
  } while(0);

#define YIELD_SCANNER_TOKEN(id, value) yield_scanner_token(yyctx, new_token(yyctx, id, value))


static void
preparse_number(char *num_str, int *basep, const char *text, size_t len)
{
  size_t i = 0, j = 0;
  int base = 10;

  if(text[0] == '+' || text[0] == '-')
  {
    i = 1;
  }

  if(text[i] == '0')
  {
    switch(text[i + 1])
    {
      case 'd':
      case 'D':
        base = 10;
        i += 2;
        break;
      case 'x':
      case 'X':
        base = 16;
        i += 2;
        break;
      case 'o':
      case 'O':
        base = 8;
        i += 2;
        break;
      case 'b':
      case 'B':
        base = 2;
        i += 2;
        break;
      default:
        evoasm_fatal("invalid number format");
        abort();
    }
  }

  for(; i < len; i++)
  {
    if(text[i] != '_')
    {
      num_str[j++] = text[i];
    }
  }
  num_str[j] = '\0';
  *basep = base;
}

%}

%option noyywrap reentrant fast 8bit
%option extra-type="_evoasm_parse_ctx *"

atom_no_arity [a-z]([0-9A-Za-z_])*
atom {atom_no_arity}("/"[0-9]+)?
pred {atom_no_arity}"("
var [A-Z_]([0-9A-Za-z_])*
bin_digits [0-1]("_"?[0-1])*
oct_digits [0-8]("_"?[0-8])*
dec_digits ("0"|[1-9]("_"?[0-9])*)
hex_digits [0-9a-fA-F]("_"?[0-9a-fA-F])*

exp [Ee][+\-]?{dec_digits}
int [+\-]?(("0"[dD])?{dec_digits}|"0"[xX]{hex_digits}|"0"[oO]{oct_digits}|"0"[bB]{bin_digits})

float [+\-]?{dec_digits}("."[0-9]+)?{exp}?
hex [0-9a-fA-F]
esc (\\\\|\\\/|\\b|\\a|\\v|\\f|\\n|\\r|\\t|\\e|\\u{hex}{hex}{hex}{hex})
regexp "/"({esc}|[^/\\])*"/"[imxo]*
sl_comment "#"
ml_comment "###"

/* Based on http://stackoverflow.com/questions/921648/how-to-make-a-flex-lexical-scanner-to-read-utf-8-characters-input */
utf8_byte [\200-\277]
utf8_1 [\300-\337]{utf8_byte}
utf8_2 [\340-\357]{utf8_byte}{2}
utf8_3 [\360-\367]{utf8_byte}{3}
utf8_4 [\370-\373]{utf8_byte}{4}
utf8_5 [\374-\375]{utf8_byte}{5}
utf8 ({utf8_1}|{utf8_2}|{utf8_3}|{utf8_4}|{utf8_5})

%x SL_COMMENT
%x ML_COMMENT
%x DQ_STR
%x SQ_STR
%x REGEXP

%%


{ml_comment} {
  BEGIN(ML_COMMENT);
  YYMORE();
}

{sl_comment} {
 BEGIN(SL_COMMENT); 
 YYMORE();
}

<ML_COMMENT>"\\"{ml_comment} {
  YYMORE();
}

<ML_COMMENT>{ml_comment} {
  char buffer[yyleng];
  size_t len = unescape_ml_comment(yytext + 3, yyleng - 3, buffer);

  yyctx->after_comment = true;

  evoasm_token *token = NEW_TOKEN(ML_COMMENT, len);
  evoasm_token_set_value(token, EVOASM_PARSER_TOKEN_TYPE_STR, buffer);
  yield_token(yyextra, token);

  update_lineno(yyctx, yytext, yyleng);
  BEGIN(INITIAL);
}
<ML_COMMENT>. {
  YYMORE();
}

<ML_COMMENT>"\n" {
  YYMORE();
}

<SL_COMMENT>\n {
  evoasm_token *token = NEW_TOKEN(SL_COMMENT, yyleng - 1);
  evoasm_token_set_value(token, EVOASM_PARSER_TOKEN_TYPE_STR, yytext + 1);
  yield_token(yyextra, token);

  update_lineno(yyctx, yytext, yyleng);
  BEGIN(INITIAL);
}
<SL_COMMENT>. {
  YYMORE();
}

"\"" {
  BEGIN(DQ_STR);
}

"'" {
 BEGIN(SQ_STR);
}

{int} {
  int64_t int_val;

  char num_str[yyleng + 1];
  int base;
  preparse_number(num_str, &base, yytext, yyleng);

  int_val = strtoll(num_str, NULL, base);

  if(errno == ERANGE)
  {
    evoasm_fatal("integer literal too large");
    abort();
  }

  if(yytext[0] == '-')
  {
    int_val = -int_val;
  }

  evoasm_token *token = NEW_TOKEN(INT, 0);
  evoasm_token_set_value(token, EVOASM_PARSER_TOKEN_TYPE_INT, int_val);
  return yield_token(yyextra, token);
}

{float} {
  double double_val;

  char num_str[yyleng + 1];
  int base;
  preparse_number(num_str, &base, yytext, yyleng);

  double_val = strtod(num_str, NULL);

  if(errno == ERANGE)
  {
    /* FIXME: C'mon! */
    evoasm_fatal("float literal too large");
    abort();
  }

  if(yytext[0] == '-')
  {
    double_val = -double_val;
  }

  evoasm_token *token = NEW_TOKEN(FLOAT, 0);
  evoasm_token_set_value(token, EVOASM_PARSER_TOKEN_TYPE_FLOAT, double_val);
  return yield_token(yyextra, token);
}

<DQ_STR>{
 "\\\"" {
    YYMORE();
  }

  "\"" {
    evoasm_token *token = NEW_TOKEN(DBLQ_STR, yyleng - 2);
    evoasm_token_set_value(token, EVOASM_PARSER_TOKEN_TYPE_STR, yytext + 1);
    yield_token(yyextra, token);
    BEGIN(INITIAL);
  }

  ({esc}|[^\\]|utf8) {
    YYMORE();
  }
}

<SQ_STR>{
 "\\'" {
    YYMORE();
  }

  "'" {
    evoasm_token *token = NEW_TOKEN(SNGLQ_STR, yyleng - 2);
    evoasm_token_set_value(token, EVOASM_PARSER_TOKEN_TYPE_STR, yytext + 1);
    yield_token(yyextra, token);
    BEGIN(INITIAL);
  }

  ({esc}|[^\\]|utf8) {
    YYMORE();
  }
}

"." {
  evoasm_token *token = NEW_TOKEN(DOT, 0);
  return yield_token(yyextra, token);
}

":-" {
  return YIELD_SIMPLE_TOKEN(TO);
}

"(" {
  return YIELD_SIMPLE_TOKEN(LPAREN);
}

")" {
  return YIELD_SIMPLE_TOKEN(RPAREN);
}

"[" {
  return YIELD_SIMPLE_TOKEN(LBRACK);
}

"]" {
  return YIELD_SIMPLE_TOKEN(RBRACK);
}

"," {
  return YIELD_SIMPLE_TOKEN(COMMA);
}

";" {
  return YIELD_SIMPLE_TOKEN(SEMIC);
}

"|" {
  return YIELD_SIMPLE_TOKEN(BAR);
}

"=" {
  return YIELD_SIMPLE_TOKEN(EQL);
}

"%" {
  return YIELD_SIMPLE_TOKEN(MOD);
}

"/" {
  return YIELD_SIMPLE_TOKEN(DIV);
}

"*" {
  return YIELD_SIMPLE_TOKEN(MUL);
}

"-" {
  return YIELD_SIMPLE_TOKEN(MINUS);
}

"+" {
  return YIELD_SIMPLE_TOKEN(PLUS);
}

"**" {
  return YIELD_SIMPLE_TOKEN(POW);
}

{atom} {
  evoasm_token *token = NEW_TOKEN(ATOM, yyleng);
  evoasm_token_set_value(token, EVOASM_PARSER_TOKEN_TYPE_STR, yytext);
  return yield_token(yyextra, token);
}

{pred} {
  evoasm_token *token = NEW_TOKEN(PRED, yyleng - 1);
  evoasm_token_set_value(token, EVOASM_PARSER_TOKEN_TYPE_STR, yytext);
  return yield_token(yyextra, token);
}

{var} {
  evoasm_token *token = NEW_TOKEN(VAR, yyleng);
  evoasm_token_set_value(token, EVOASM_PARSER_TOKEN_TYPE_STR, yytext);
  return yield_token(yyextra, token);
}

{regexp} {
  evoasm_token *token = NEW_TOKEN(REGEXP, yyleng - 2);
  evoasm_token_set_value(token, EVOASM_PARSER_TOKEN_TYPE_STR, yytext + 1);
  return yield_token(yyextra, token);
}

(" "|"\n")+ {
  update_lineno(yyctx, yytext, yyleng);
}

. {
  evoasm_warn("invalid token '%.*s'", (int)yyleng, yytext);
}

%%
