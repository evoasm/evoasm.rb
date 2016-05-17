#pragma once

typedef struct  {
  uint32_t idx;
} awasm_sym;

typedef struct {
  char *data;
  uint32_t capa;
  uint32_t len;
} awasm_sym_tbl;
