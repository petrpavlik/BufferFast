//
//  StatusBarView.m
//  BufferFast
//
//  Created by Petr Pavlik on 12/11/12.
//  Copyright (c) 2012 Petr Pavlik. All rights reserved.
//

#import "StatusBarView.h"

@implementation StatusBarView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)rect
{
    rect = CGRectInset(rect, 2, 2);
    
    [[NSColor textColor] set]; /* blackish */
    
    /*if ([self.delegate isActive]) {
     [[NSColor selectedMenuItemColor] set];
     } else {
     [[NSColor textColor] set];
     }*/
    
    NSRectFill(rect);
}

@end
