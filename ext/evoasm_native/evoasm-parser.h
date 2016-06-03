#pragma once

#include "evoasm-asg.h"

typedef struct {
  void *scanner;
} evoasm_parser;

typedef struct {
  evoasm_parser *parser;
  evoasm_asg *asg;
  uint32_t col;
  uint32_t last_col;
  uint32_t line;
  uint32_t last_line;
  uint32_t pos;
  uint32_t last_pos;
  bool after_comment;
} _evoasm_parse_ctx;

typedef enum {
  EVOASM_TOKEN_ID_ML_COMMENT,
  EVOASM_TOKEN_ID_SL_COMMENT,
  EVOASM_TOKEN_ID_STR,
  EVOASM_TOKEN_ID_FLOAT,
  EVOASM_TOKEN_ID_TO,
  EVOASM_TOKEN_ID_LPAREN,
  EVOASM_TOKEN_ID_RPAREN,
  EVOASM_TOKEN_ID_LBRACK,
  EVOASM_TOKEN_ID_RBRACK,
  EVOASM_TOKEN_ID_COMMA,
  EVOASM_TOKEN_ID_SEMIC,
  EVOASM_TOKEN_ID_BAR,
  EVOASM_TOKEN_ID_EQL,
  EVOASM_TOKEN_ID_MOD,
  EVOASM_TOKEN_ID_MUL,
  EVOASM_TOKEN_ID_MINUS,
  EVOASM_TOKEN_ID_PLUS,
  EVOASM_TOKEN_ID_POW,
  EVOASM_TOKEN_ID_DIV,


} evoasm_token_id;
