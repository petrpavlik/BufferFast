//
//  AppDelegate.m
//  BufferFast
//
//  Created by Petr Pavlik on 12/7/12.
//  Copyright (c) 2012 Petr Pavlik. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    NSStatusItem* statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setTitle:@"Status"];
    [statusItem setHighlightMode:YES];

}

- (void)awakeFromNib {
    
        
}

@end