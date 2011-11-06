//
//  CIDGrowlAppDelegate.m
//  CIDGrowl
//
//  Created by Dan Ponte on 1/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CIDGrowlAppDelegate.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define PORT 3890
#define BUFFERL 256



@implementation CIDGrowlAppDelegate


@synthesize window;

- (IBAction)openAboutPanel:(id)sender
{
    NSDictionary *options;
    NSImage *img;
	
    img = [NSImage imageNamed: @"Picture 1"];
    options = [NSDictionary dictionaryWithObjectsAndKeys:
			   @"0.1", @"Version",
			   @"CIDGrowl", @"ApplicationName",
			   img, @"ApplicationIcon",
			   @"Copyright 2010 Dan Ponte", @"Copyright",
			   @"CIDGrowl v0.1", @"ApplicationVersion",
			   nil];
	
    [[NSApplication sharedApplication] orderFrontStandardAboutPanelWithOptions:options];
}

struct sockaddr_in servsad;
char servaddr[256];
typedef struct cis
{
	char *name;
	char *number;
	char *date;
	char *time;
} cidinfo;

void
parseinfo (buffer, cifo)
char *buffer;
cidinfo *cifo;
{
	char *bfrp;
	char *origbuf;
	origbuf = buffer;
	bfrp = origbuf;
	/* 9005:2010:0:WIRELESS CALL   :401213123123 */
	cifo->date = strsep (&bfrp, ":");
	cifo->time = strsep (&bfrp, ":");
	if(cifo->time == NULL) return;
	strsep (&bfrp, ":");
	cifo->name = strsep (&bfrp, ":");
	cifo->number = bfrp;
}

void telluser(buf)
char *buf;
{
	cidinfo cid;
	char *ltx;
	size_t lent;
	NSString *ltns;
	bzero(&cid, sizeof cid);
	parseinfo (buf, &cid);
	if(cid.name == NULL) return;
	if(cid.name == NULL || cid.number == NULL) {return;}
	lent =	sizeof ("Name: \nNumber: \nDate: \nTime: \n           ");
	lent +=
    sizeof (char) * (strlen (cid.name) + strlen (cid.number) +
					 strlen (cid.date) + strlen (cid.time));
	ltx = (char *) malloc (lent);
	memset (ltx, 0, lent);
	snprintf (ltx, lent, "Name: %s\nNumber: %s",
			  cid.name, cid.number, cid.date, cid.time); /* XXX: Use NSString functions right off the bat */
	ltns = [[NSString alloc] initWithCString:ltx encoding:NSMacOSRomanStringEncoding]; /* turn it into NSString because we are so fucking lazy about rewriting... */
	[GrowlApplicationBridge notifyWithTitle:@"Phone Call"
								description:ltns
						   notificationName:@"Phone Call"
								   iconData:nil
								   priority:0
								   isSticky:NO
							   clickContext:[NSDate date]];
	[ltns autorelease];
	free (ltx);	
}
/*
-(void)setCallNum: (int)calls
{
	NSString *tstr;
	if (calls)
		numberOfCalls += calls;
	else {
		numberOfCalls = 0;
	}

	tstr = [[NSString alloc] initWithFormat:@"%d calls", numberOfCalls];
	[callCountItem setTitle:tstr];
	[tstr autorelease];
}
*/
+(void)start_netloop: (id)param
{
	int sockfd, nbytes;
	unsigned int addr_len;
	struct sockaddr_in ouraddr;
	struct sockaddr_in* bcasaddr;
	struct timeval tv;
	NSAutoreleasePool	 *autoreleasepool = [[NSAutoreleasePool alloc] init];
	bcasaddr = &servsad;
	bzero(&servsad, sizeof servsad);
	fd_set fds_read;
	FD_ZERO(&fds_read);
	char buffer[BUFFERL];
	
	if((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
		perror("sock");
		exit(-1);
	}
	ouraddr.sin_family = AF_INET;
	ouraddr.sin_port = htons(PORT);
	ouraddr.sin_addr.s_addr = INADDR_ANY;
	memset(&(ouraddr.sin_zero), 0, 8);
	if(bind(sockfd, (struct sockaddr*)&ouraddr, sizeof(struct sockaddr)) == -1) {
		perror("bind");
		exit(-2);
	}
	addr_len = sizeof(struct sockaddr);
	while(1)
	{
		FD_ZERO(&fds_read);
		FD_SET(sockfd, &fds_read);
		tv.tv_sec = 3; tv.tv_usec = 0;
		switch(select(sockfd + 1, &fds_read, NULL, NULL, NULL))
		{
			case -1:
				perror("select");
				goto doublebreak; /* the only case K&R ever recommends using a goto! */
				break;
			default:
				if(FD_ISSET(sockfd, &fds_read) != 0)
				{
					
					if((nbytes = recvfrom(sockfd, buffer, BUFFERL - 1, 0, (struct sockaddr*)bcasaddr, &addr_len
										  )) == -1) {
						perror("recv");
						goto doublebreak;
					}
					buffer[nbytes] = 0;
#ifdef DEBUG
					printf("got %s\n", buffer);
#endif
					telluser(buffer);
					memset(buffer, 0, BUFFERL);
				}
		}
	}
doublebreak:
	close(sockfd);
	[autoreleasepool release];
	/* TODO: NSLog here (or replace perror()s with NSLog) */
	[NSApp terminate: nil];
	return;
}



- (void) receiveWakeNote: (NSNotification*) note
{
    // make call count zero
}


- (void)awakeFromNib {
	// Insert code here to initialize your application 

	NSImage *appic = [[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"menuic" ofType:@"png"]];
	NSBundle *myBundle = [NSBundle bundleForClass:[CIDGrowlAppDelegate class]];
	NSString *growlPath = [[myBundle privateFrameworksPath] stringByAppendingPathComponent:@"Growl-WithInstaller.framework"];
	NSBundle *growlBundle = [NSBundle bundleWithPath:growlPath];
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain]; 
	

	//[statusItem setTitle:@"C"];
	[statusItem setImage:appic];
	[statusItem setHighlightMode:YES];
	[statusItem setMenu:statusMenu];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self 
														   selector: @selector(receiveWakeNote:) name: NSWorkspaceDidWakeNotification object: NULL];
	if (growlBundle && [growlBundle load]) {
		// Register ourselves as a Growl delegate
		[GrowlApplicationBridge setGrowlDelegate:self];
		
		[NSThread detachNewThreadSelector:@selector(start_netloop:) toTarget:[CIDGrowlAppDelegate class] withObject:nil];
			
	}
	else {
		NSLog(@"ERROR: Could not load Growl.framework");
	}
	[appic autorelease];
}

@end
