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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "IZBackgroundFetchOperation.h"

@class IZManagedObjectContext;

@protocol IZManagedObjectContextDelegate
- (void)managedObjectContext:(IZManagedObjectContext *)context fetchCompletedForRequest:(NSFetchRequest *)request withResults:(NSArray *)results error:(NSError *)error;
@end

@interface IZManagedObjectContext : NSManagedObjectContext <IZBackgroundFetchOperationDelegate> {
	NSOperationQueue				*queue;
	NSThread						*initThread;
	
	NSMutableDictionary				*_delegatesForRequests;
	NSMutableDictionary				*_backgroundFetchOperationsForRequests;
}

// This queue is used for the background operations
@property (strong) NSOperationQueue	*queue;

// NSManagedObjectContext was inited on this thread. 
// The object is only valid where it is inited because it is not threadsafe.
@property (strong, readonly) NSThread *iThread;

// Only call this method from the initThread. If called from any other thread it will blow up the world.
- (void)executeFetchRequestAsynchronously:(NSFetchRequest *)request 
								 delegate:(id<IZManagedObjectContextDelegate>)delegate;

- (void)cancelFetchRequest:(NSFetchRequest *)request;

@end
