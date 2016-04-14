//
//  SKYCallConfiguration.h
//  SkyBell
//
//  Created by Gabriel Sosa Martínez on 5/1/15.
//  Copyright (c) 2015 SkyBell Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKYConstants.h"

static uint16_t const SKYCallConfigurationDefaultAudioPort = 5006;
static uint16_t const SKYCallConfigurationDefaultVideoPort = 5004;

@interface SKYCallConfiguration : NSObject

@property (nonatomic, strong) NSString *destinationHost;
@property (nonatomic, strong) NSString *deviceId;
@property (nonatomic, strong) NSString *callId;
@property (nonatomic, strong) NSString *role;
@property (nonatomic, assign) uint16_t destinationAudioPort;
@property (nonatomic, assign) uint16_t destinationVideoPort;
@property (nonatomic, assign) uint16_t localAudioPort;
@property (nonatomic, assign) uint16_t localVideoPort;
@property (nonatomic, assign) SKYCallTrigger callTrigger;
@property (nonatomic, strong, readonly) NSString *triggerDescription;

@end
