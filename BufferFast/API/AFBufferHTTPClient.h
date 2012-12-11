//
//  AFBufferHTTPClient.h
//  BufferTest
//
//  Created by Petr Pavlik on 11/29/12.
//  Copyright (c) 2012 Petr Pavlik. All rights reserved.
//

#import "AFHTTPClient.h"

@interface AFBufferHTTPClient : AFHTTPClient

+ (AFBufferHTTPClient*)sharedClient;

@end
