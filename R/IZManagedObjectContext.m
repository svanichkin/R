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

#import "IZManagedObjectContext.h"

@implementation IZManagedObjectContext

@synthesize queue;
@synthesize iThread;

// Init thread -- Normaly inithread is the mainthread
- (id)init
{
	if (self = [super init])
	{
		_delegatesForRequests = [[NSMutableDictionary alloc] init];
		_backgroundFetchOperationsForRequests = [[NSMutableDictionary alloc] init];
		
		NSOperationQueue *q = [[NSOperationQueue alloc] init];
		self.queue = q;
		
		iThread = [NSThread currentThread];
	}
	
	return self;
}

// Init thread (?) TODO: find out 
- (void)dealloc
{
	_delegatesForRequests = nil;	
	for (IZBackgroundFetchOperation *o in [_backgroundFetchOperationsForRequests allValues])
	{
		[o cancel];
		o.delegate = nil;
	}
	_backgroundFetchOperationsForRequests = nil;
}

// Init thread
- (void)executeFetchRequestAsynchronously:(NSFetchRequest *)request 
								 delegate:(id<IZManagedObjectContextDelegate>)delegate;
{
	// Sanity check
	NSAssert([NSThread currentThread] == self.iThread, @"Not on the thread where the managedObjectContext was inited");
	if (request == nil || delegate == nil)
		return;
	NSPersistentStoreCoordinator *psc = [self persistentStoreCoordinator];
	if (psc == nil)
		return; // Maybe instead throw an exception here
	// End sanity check
	
	[_delegatesForRequests setObject:delegate forKey:request];
	
	IZBackgroundFetchOperation *backgroundFetchOperation = [[IZBackgroundFetchOperation alloc] initWithPersistentStoreCoordinator:psc 
																													 fetchRequest:request 
																												   callbackThread:self.iThread 
																														 delegate:self];
	[_backgroundFetchOperationsForRequests setObject:backgroundFetchOperation forKey:request];
	[self.queue addOperation:backgroundFetchOperation];
}

// Init thread
- (void)cancelFetchRequest:(NSFetchRequest *)request
{
	// Sanity check
	NSAssert([NSThread currentThread] == self.iThread, @"Not on the thread where the managedObjectContext was inited");
	if (request == nil)
		return;	
	
	IZBackgroundFetchOperation *backgroundFetchOperation = (IZBackgroundFetchOperation *)[_backgroundFetchOperationsForRequests objectForKey:request];
	if (backgroundFetchOperation)
	{
		[backgroundFetchOperation cancel];
		backgroundFetchOperation.delegate = nil;
		
		// Cleanup
		[_delegatesForRequests removeObjectForKey:request];
		[_backgroundFetchOperationsForRequests removeObjectForKey:request];
	}
}

#pragma mark -
#pragma mark IZBackgroundFetchOperationDelegate method

// Init thread
- (void)backgroundFetchOperation:(IZBackgroundFetchOperation *)operation completedWithIDs:(NSArray *)results error:(NSError *)error
{
	// Sanity check -- This line can be taken out safely from here.
	NSAssert([NSThread currentThread] == self.iThread, @"Not on the thread where the managedObjectContext was inited");
	
	NSFetchRequest *request = operation.fetchRequest;
	
	[_backgroundFetchOperationsForRequests removeObjectForKey:request];
		
	id<IZManagedObjectContextDelegate> delegate = [_delegatesForRequests objectForKey:request];
	
	if (error != nil)
	{
		[delegate managedObjectContext:self fetchCompletedForRequest:request withResults:results error:error];
		[_delegatesForRequests removeObjectForKey:request];
		return;
	}
		
	// Set the new predicate so we fetch objects with the result ids
	NSFetchRequest *modifiedRequest = [request copy];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self IN %@", results];
	[modifiedRequest setPredicate:predicate];
	
	// Now let's do the fetch on this thread. 
	// This fetch should have only O(n) complexity if the executeFetchRequest:error: is optimized for fetching objectIDs
	// Anyway, it will be way faster than the initial fetch request which had a more "complicated" predicate
	NSError *e = nil;
	NSArray *r = [self executeFetchRequest:modifiedRequest error:&e];
	
	[delegate managedObjectContext:self fetchCompletedForRequest:request withResults:r error:e];
	
	// Cleanup
	[_delegatesForRequests removeObjectForKey:request];
}

@end
