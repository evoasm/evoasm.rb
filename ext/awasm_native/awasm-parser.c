#include "awasm-parser.h"

#include "lexer.h"

void
awasm_parser_init(awasm_parser *parser) {
  static awasm_parser zero_parser = {0};
  *parser = zero_parser;
  yylex_init(&parser->scanner);
}

void
awasm_parser_destroy(awasm_parser *parser) {
  yylex_destroy(parser->scanner);
}

awasm_success
awasm_parser_parse(awasm_parser *parser, const char *buf, size_t len,
                   awasm_src_graph *src_graph)
{
  YY_BUFFER_STATE buffer = NULL;

  _awasm_parse_ctx ctx = {.parser = parser, .graph = src_graph};
  yyset_extra((void *)&ctx, parser->scanner);

  buffer = yy_scan_bytes(buf, len, parser->scanner);

  while(yylex(parser->scanner) != 0) {}

  yy_delete_buffer(buffer, parser->scanner);

  return true;
}



