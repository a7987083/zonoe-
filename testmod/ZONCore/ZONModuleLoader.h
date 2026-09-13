#ifndef ZONModuleLoader_h
#define ZONModuleLoader_h

#import <Foundation/Foundation.h>
#import "ZONModuleABI.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT void ZONCoreLog(ZONLogLevel level,
                                  const char * _Nullable moduleID,
                                  const char * _Nullable message);
FOUNDATION_EXPORT const ZONHostAPI *ZONGetHostAPI(void);
FOUNDATION_EXPORT void ZONLoadBundledModules(void);

NS_ASSUME_NONNULL_END

#endif /* ZONModuleLoader_h */
