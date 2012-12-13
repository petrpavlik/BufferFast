//
//  StatusBarView.h
//  BufferFast
//
//  Created by Petr Pavlik on 12/11/12.
//  Copyright (c) 2012 Petr Pavlik. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class StatusBarView;

@protocol StatusBarViewDelegate <NSObject>

- (void)statusBarView:(StatusBarView*)statusBarView didReceiveMouseDownEvent:(NSEvent*)event;

@end

@interface StatusBarView : NSView

@property(weak) id<StatusBarViewDelegate> delegate;

@end
