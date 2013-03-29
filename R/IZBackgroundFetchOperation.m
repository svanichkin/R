/*
 Copyright (C) 2010 Zsombor Szabó, IZE Ltd.. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "IZBackgroundFetchOperation.h"

@implementation IZBackgroundFetchOperation

@synthesize persistentStoreCoordinator;
@synthesize fetchRequest;
@synthesize callbackThread;
@synthesize delegate;

- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)psc
							fetchRequest:(NSFetchRequest *)request
						  callbackThread:(NSThread *)thread
								delegate:(id<IZBackgroundFetchOperationDelegate>)aDelegate
{
	if (self = [super init])
	{
		self.persistentStoreCoordinator = psc;
		self.fetchRequest = request;
		self.callbackThread = thread;
		self.delegate = aDelegate;
	}
	
	return self;
}

static NSString *errorKey = @"errorKey";
static NSString *resultsKey = @"resultsKey";

// Worker thread
- (void)main
{
	// Sanity check
	if (self.persistentStoreCoordinator == nil || self.fetchRequest == nil || self.callbackThread == nil || self.delegate == nil)
		return;
	
	NSManagedObjectContext *searchContext = [[NSManagedObjectContext alloc] init];
	[searchContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
	
	// Fetch only the objectIDs and pass those back.
	NSFetchRequest *requestCopy = [self.fetchRequest copy];
	[requestCopy setResultType:NSManagedObjectIDResultType];
	// Performance tweak. We just want the objectIDs unsorted. We will do an another fetchrequest with sorting later.
	[requestCopy setSortDescriptors:nil]; 
	
	NSError *error = nil;
	// This little thingy blocks. 
	// If the fetch is complicated and/or we have a very large dataset it runs for a long time.
	NSArray *results = [searchContext executeFetchRequest:requestCopy error:&error];
	
	// Maybe the operation got cancelled in the meantime?
	if ([self isCancelled] == NO)
	{
		NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
		if (error)
			[userInfo setObject:error forKey:errorKey];
		if (results)
			[userInfo setObject:results forKey:resultsKey];	
		
		[self performSelector:@selector(fetchRequestDidCompleteWithUserInfo:) 
					 onThread:self.callbackThread 
				   withObject:userInfo 
				waitUntilDone:NO];
		
	}	
	
	// Cleanup
}

// Callback Thread
- (void)fetchRequestDidCompleteWithUserInfo:(NSDictionary *)userInfo
{
	NSError *error = [userInfo objectForKey:errorKey];
	NSArray *results = [userInfo objectForKey:resultsKey];
	
	[self.delegate backgroundFetchOperation:self completedWithIDs:results error:error];
}

- (void)dealloc
{
	self.delegate = nil;
}

@end
