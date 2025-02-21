/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI46_0_0RCTReloadCommand.h"

#import "ABI46_0_0RCTAssert.h"
#import "ABI46_0_0RCTKeyCommands.h"
#import "ABI46_0_0RCTUtils.h"

static NSHashTable<id<ABI46_0_0RCTReloadListener>> *listeners;
static NSLock *listenersLock;
static NSURL *bundleURL;

NSString *const ABI46_0_0RCTTriggerReloadCommandNotification = @"ABI46_0_0RCTTriggerReloadCommandNotification";
NSString *const ABI46_0_0RCTTriggerReloadCommandReasonKey = @"reason";
NSString *const ABI46_0_0RCTTriggerReloadCommandBundleURLKey = @"bundleURL";

void ABI46_0_0RCTRegisterReloadCommandListener(id<ABI46_0_0RCTReloadListener> listener)
{
  if (!listenersLock) {
    listenersLock = [NSLock new];
  }
  [listenersLock lock];
  if (!listeners) {
    listeners = [NSHashTable weakObjectsHashTable];
  }
#if ABI46_0_0RCT_DEV
  ABI46_0_0RCTAssertMainQueue(); // because registerKeyCommandWithInput: must be called on the main thread
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [[ABI46_0_0RCTKeyCommands sharedInstance] registerKeyCommandWithInput:@"r"
                                                   modifierFlags:UIKeyModifierCommand
                                                          action:^(__unused UIKeyCommand *command) {
                                                            ABI46_0_0RCTTriggerReloadCommandListeners(@"Command + R");
                                                          }];
  });
#endif
  [listeners addObject:listener];
  [listenersLock unlock];
}

void ABI46_0_0RCTTriggerReloadCommandListeners(NSString *reason)
{
  [listenersLock lock];
  [[NSNotificationCenter defaultCenter] postNotificationName:ABI46_0_0RCTTriggerReloadCommandNotification
                                                      object:nil
                                                    userInfo:@{
                                                      ABI46_0_0RCTTriggerReloadCommandReasonKey : ABI46_0_0RCTNullIfNil(reason),
                                                      ABI46_0_0RCTTriggerReloadCommandBundleURLKey : ABI46_0_0RCTNullIfNil(bundleURL)
                                                    }];

  for (id<ABI46_0_0RCTReloadListener> l in [listeners allObjects]) {
    [l didReceiveReloadCommand];
  }
  [listenersLock unlock];
}

void ABI46_0_0RCTReloadCommandSetBundleURL(NSURL *URL)
{
  bundleURL = URL;
}
