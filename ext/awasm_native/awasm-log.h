#pragma once

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

typedef uint8_t awasm_log_level;
#define AWASM_LOG_LEVEL_TRACE   0
#define AWASM_LOG_LEVEL_DEBUG   1
#define AWASM_LOG_LEVEL_INFO    2
#define AWASM_LOG_LEVEL_WARN    3
#define AWASM_LOG_LEVEL_ERROR   4
#define AWASM_LOG_LEVEL_FATAL   5
#define AWASM_N_LOG_LEVELS      6

#ifndef AWASM_MIN_LOG_LEVEL
#  define AWASM_MIN_LOG_LEVEL AWASM_LOG_LEVEL_INFO
#endif

extern awasm_log_level awasm_min_log_level;
extern FILE *          awasm_log_file;

#ifdef __GNUC__
#  define AWASM_LOG_ATTRS __attribute__ ((format(printf, 3, 4)))
#else
#  define AWASM_LOG_ATTRS
#endif

#define AWASM_DECL_LOG_TAG(tag) awasm_used static const char *_awasm_log_tag = tag;
#define AWASM_LOG_TAG _awasm_log_tag

void
awasm_log(awasm_log_level level, const char *tag, const char *format, ...) AWASM_LOG_ATTRS;

#if AWASM_MIN_LOG_LEVEL <= AWASM_LOG_LEVEL_TRACE
#  define awasm_trace(...) awasm_log(AWASM_LOG_LEVEL_TRACE, AWASM_LOG_TAG, __VA_ARGS__)
#else
#  define awasm_trace(...)
#endif

#if AWASM_MIN_LOG_LEVEL <= AWASM_LOG_LEVEL_DEBUG
#  define awasm_debug(...) awasm_log(AWASM_LOG_LEVEL_DEBUG, AWASM_LOG_TAG, __VA_ARGS__)
#else
#  define awasm_debug(...)
#endif

#if AWASM_MIN_LOG_LEVEL <= AWASM_LOG_LEVEL_INFO
#  define awasm_info(...) awasm_log(AWASM_LOG_LEVEL_INFO, AWASM_LOG_TAG, __VA_ARGS__)
#else
#  define awasm_info(...)
#endif

#if AWASM_MIN_LOG_LEVEL <= AWASM_LOG_LEVEL_WARN
#  define awasm_warn(...) awasm_log(AWASM_LOG_LEVEL_WARN, AWASM_LOG_TAG, __VA_ARGS__)
#else
#  define awasm_warn(...)
#endif

#if AWASM_MIN_LOG_LEVEL <= AWASM_LOG_LEVEL_ERROR
#  define awasm_error(...) awasm_log(AWASM_LOG_LEVEL_ERROR, AWASM_LOG_TAG, __VA_ARGS__)
#else
#  define awasm_error(...)
#endif

#if AWASM_MIN_LOG_LEVEL <= AWASM_LOG_LEVEL_FATAL
#  define awasm_fatal(...) awasm_log(AWASM_LOG_LEVEL_FATAL, AWASM_LOG_TAG, __VA_ARGS__)
#else
#  define awasm_fatal(...)
#endif
