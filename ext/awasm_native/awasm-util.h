#pragma once

#define AWASM_INT8_MAX  INT8_MAX
#define AWASM_INT8_MIN  INT8_MIN
#define AWASM_INT16_MAX INT16_MAX
#define AWASM_INT16_MIN INT16_MIN
#define AWASM_INT32_MAX INT32_MAX
#define AWASM_INT32_MIN INT32_MIN
#define AWASM_INT64_MAX INT64_MAX
#define AWASM_INT64_MIN INT64_MIN


#define AWASM_MAX(a,b) (((a) > (b)) ? (a) : (b))
#define AWASM_MIN(a,b) (((a) < (b)) ? (a) : (b))
#define AWASM_CLAMP(x, min, max) (((x) > (max)) ? (max) : (((x) < (min)) ? (min) : (x)))

#define AWASM_ALIGN_DOWN(s, a) ((s) &~ ((a) - 1))
#define AWASM_ALIGN_UP(s, a) AWASM_ALIGN_DOWN(((s) + (a) - 1), a)

#define AWASM_ARY_LEN(ary) (sizeof(ary) / sizeof(ary[0]))

#ifdef __GNUC__
# define AWASM_UNLIKELY(e) (__builtin_expect(e, 0))
# define AWASM_LIKELY(e) (__builtin_expect(e, 1))
# define awasm_used __attribute__((used))
# define awasm_force_inline __attribute__((always_inline))
#else
# define AWASM_UNLIKELY(e) (e)
# define AWASM_LIKELY(e) (e)
# define awasm_used
#endif

#if defined(__GNUC__)
# define awasm_check_return __attribute__((warn_unused_result))
#elif defined(_MSC_VER)
# define awasm_check_return _Check_return_
# define awasm_force_inline __forceinline
#else
# define awasm_check_return
#endif
