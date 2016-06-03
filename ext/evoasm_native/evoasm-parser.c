#include "evoasm-parser.h"

#include "lexer.h"

void
evoasm_parser_init(evoasm_parser *parser) {
  static evoasm_parser zero_parser = {0};
  *parser = zero_parser;
  yylex_init(&parser->scanner);
}

void
evoasm_parser_destroy(evoasm_parser *parser) {
  yylex_destroy(parser->scanner);
}

evoasm_success
evoasm_parser_parse(evoasm_parser *parser, const char *buf, size_t len,
                   evoasm_asg *asg)
{
  YY_BUFFER_STATE buffer = NULL;

  _evoasm_parse_ctx ctx = {.parser = parser, .asg = asg};
  yyset_extra((void *)&ctx, parser->scanner);

  buffer = yy_scan_bytes(buf, len, parser->scanner);

  while(yylex(parser->scanner) != 0) {}

  yy_delete_buffer(buffer, parser->scanner);

  return true;
}



