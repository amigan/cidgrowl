//
//  CIDGrowlAppDelegate.h
//  CIDGrowl
//
//  Created by Dan Ponte on 1/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

@interface CIDGrowlAppDelegate : NSObject <GrowlApplicationBridgeDelegate> {
	NSWindow *window;
    IBOutlet NSMenu *statusMenu;
    NSStatusItem * statusItem;
	IBOutlet NSMenuItem *callCountItem;
	//int numberOfCalls;
}



//-(void)setCallNum:(int)calls;

+(void)start_netloop:(id)param;

- (IBAction)openAboutPanel:(id)sender;

//-(void) growlIsReady;
@property (assign) IBOutlet NSWindow *window;

@end
