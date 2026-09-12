#ifndef ZONModuleLoader_h
#define ZONModuleLoader_h

#import <Foundation/Foundation.h>
#import "ZONModuleABI.h"

NS_ASSUME_NONNULL_BEGIN

void ZONCoreLog(ZONLogLevel level, const char *moduleID, const char *message);
const ZONHostAPI *ZONGetHostAPI(void);
NSArray<NSString *> *ZONBundledModuleDirectories(void);
BOOL ZONPathIsInsideDirectory(NSString *path, NSString *directory);
BOOL ZONLoadModuleAtPath(NSString *path, NSMutableSet<NSString *> *loadedIdentifiers);
void ZONLoadBundledModules(void);

NS_ASSUME_NONNULL_END

#endif /* ZONModuleLoader_h */
