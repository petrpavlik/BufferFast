//
//  AFPastebinHTTPClient.h
//  BufferFast
//
//  Created by Petr Pavlik on 12/15/12.
//  Copyright (c) 2012 Petr Pavlik. All rights reserved.
//

#import "AFHTTPClient.h"

@interface AFPastebinHTTPClient : AFHTTPClient

+ (AFPastebinHTTPClient*)sharedClient;

@end
