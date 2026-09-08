#include "../ZONCore/ZONModuleABI.h"

static const ZONHostAPI *g_host = 0;

__attribute__((visibility("default")))
uint32_t zonoe_module_abi_version(void) {
    return ZON_MODULE_ABI_VERSION;
}

__attribute__((visibility("default")))
const char *zonoe_module_identifier(void) {
    return "xyz.zonoe.example";
}

__attribute__((visibility("default")))
bool zonoe_module_initialize(const ZONHostAPI *host_api) {
    if (!host_api || host_api->struct_size < sizeof(ZONHostAPI) ||
        host_api->abi_version != ZON_MODULE_ABI_VERSION || !host_api->log) {
        return false;
    }

    g_host = host_api;
    g_host->log(ZONLogLevelInfo, zonoe_module_identifier(), "example module initialized");
    return true;
}

__attribute__((visibility("default")))
void zonoe_module_shutdown(void) {
    if (g_host && g_host->log) {
        g_host->log(ZONLogLevelInfo, zonoe_module_identifier(), "example module shutdown");
    }
    g_host = 0;
}
