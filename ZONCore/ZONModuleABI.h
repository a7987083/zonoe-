#ifndef ZONModuleABI_h
#define ZONModuleABI_h

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ZON_MODULE_ABI_VERSION 1u

// Log levels are intentionally stable C values so modules do not depend on ObjC types.
typedef enum ZONLogLevel {
    ZONLogLevelDebug = 0,
    ZONLogLevelInfo  = 1,
    ZONLogLevelWarn  = 2,
    ZONLogLevelError = 3,
} ZONLogLevel;

// Versioned host interface. New fields may only be appended.
typedef struct ZONHostAPI {
    uint32_t struct_size;
    uint32_t abi_version;
    void (*log)(ZONLogLevel level, const char *module_id, const char *message);
} ZONHostAPI;

typedef uint32_t (*ZONModuleABIVersionFn)(void);
typedef const char *(*ZONModuleIdentifierFn)(void);
typedef bool (*ZONModuleInitializeFn)(const ZONHostAPI *host_api);
typedef void (*ZONModuleShutdownFn)(void);

// Required exports from every external zonoemenu module:
//   uint32_t zonoe_module_abi_version(void);
//   const char *zonoe_module_identifier(void);
//   bool zonoe_module_initialize(const ZONHostAPI *host_api);
// Optional:
//   void zonoe_module_shutdown(void);

#ifdef __cplusplus
}
#endif

#endif /* ZONModuleABI_h */
