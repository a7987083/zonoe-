#include "../ZONCore/ZONModuleABI.h"

#include <assert.h>
#include <stdio.h>
#include <string.h>

extern uint32_t zonoe_module_abi_version(void);
extern const char *zonoe_module_identifier(void);
extern bool zonoe_module_initialize(const ZONHostAPI *host_api);
extern void zonoe_module_shutdown(void);

static int g_log_count = 0;

static void test_log(ZONLogLevel level, const char *module_id, const char *message) {
    (void)level;
    assert(module_id != NULL);
    assert(message != NULL);
    g_log_count++;
}

int main(void) {
    ZONHostAPI host = {
        .struct_size = sizeof(ZONHostAPI),
        .abi_version = ZON_MODULE_ABI_VERSION,
        .log = test_log,
    };

    assert(zonoe_module_abi_version() == ZON_MODULE_ABI_VERSION);
    assert(strcmp(zonoe_module_identifier(), "xyz.zonoe.example") == 0);
    assert(zonoe_module_initialize(&host));
    assert(g_log_count == 1);

    zonoe_module_shutdown();
    assert(g_log_count == 2);

    puts("zonoemenu module ABI smoke test passed");
    return 0;
}
