#pragma once

#include "awasm-asg.h"

typedef struct {
  void *scanner;
} awasm_parser;

typedef struct {
  awasm_parser *parser;
  awasm_asg *asg;
  uint32_t col;
  uint32_t last_col;
  uint32_t line;
  uint32_t last_line;
  uint32_t pos;
  uint32_t last_pos;
  bool after_comment;
} _awasm_parse_ctx;

typedef enum {
  AWASM_TOKEN_ID_ML_COMMENT,
  AWASM_TOKEN_ID_SL_COMMENT,
  AWASM_TOKEN_ID_STR,
  AWASM_TOKEN_ID_FLOAT,
  AWASM_TOKEN_ID_TO,
  AWASM_TOKEN_ID_LPAREN,
  AWASM_TOKEN_ID_RPAREN,
  AWASM_TOKEN_ID_LBRACK,
  AWASM_TOKEN_ID_RBRACK,
  AWASM_TOKEN_ID_COMMA,
  AWASM_TOKEN_ID_SEMIC,
  AWASM_TOKEN_ID_BAR,
  AWASM_TOKEN_ID_EQL,
  AWASM_TOKEN_ID_MOD,
  AWASM_TOKEN_ID_MUL,
  AWASM_TOKEN_ID_MINUS,
  AWASM_TOKEN_ID_PLUS,
  AWASM_TOKEN_ID_POW,
  AWASM_TOKEN_ID_DIV,


} awasm_token_id;
