/*
 Copyright (c) 2013 New Relic, Inc.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "Requester.h"

@interface Requester() {
    NSTimer *_timer;
    NSURL *_url;
    double _requestRate;
    BOOL _parseResponse;
}
@end

@implementation Requester

+ (id) requestWithURL: (NSString *)url
         andRequestRate: (double) requestRate
        parsingResponse: (BOOL) parseResponse
{
    Requester *r = [[Requester alloc] initWithURL:url
                                   andRequestRate: requestRate
                                  parsingResponse: parseResponse];
    [r start];
    return r;
}

- (id) initWithURL: (NSString *)url
    andRequestRate: (double) requestRate
   parsingResponse: (BOOL) parseResponse
{
    self = [super init];
    if (self) {
        _url = [NSURL URLWithString:url];
        _requestRate = requestRate;
        _parseResponse = parseResponse;
    }
    return self;
}

- initWithURL: (NSString *)url andRequestRate: (double) requestRate
{
    return [self initWithURL:url andRequestRate:requestRate parsingResponse:NO];
}

- (void) start
{
    @autoreleasepool {
        [NSThread detachNewThreadSelector:@selector(startTimer)
                                 toTarget:self
                               withObject:nil];
    } 
}

- (void) stop
{
    [_timer invalidate];
}

// Schedules a new timer, adds it to the current run loop and waits forever.
- (void) startTimer
{
    _timer = [NSTimer scheduledTimerWithTimeInterval: 1.0 / _requestRate
                                              target:self
                                            selector:@selector(request)
                                            userInfo:nil
                                             repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantFuture]];
}

// Perform a single request.
- (void) request
{
    // Create a new request which has caching disabled.
    NSURLRequest *req = [NSURLRequest requestWithURL:_url
                                         cachePolicy: NSURLRequestReloadIgnoringCacheData
                                     timeoutInterval:5.0];
    
    NSURLResponse *res = [[NSURLResponse alloc] init];
    NSError *error = [[NSError alloc] init];
    
    // Make synchronous request.
    NSData *reqData = [NSURLConnection sendSynchronousRequest:req
                                            returningResponse:&res
                                                        error:&error];
    if (reqData == nil) {
        NSLog(@"Request failed: %@",  [error localizedDescription]);
        return;
    }
    
    // Attempt to decode a JSON response.
    if (_parseResponse) {
        error = [[NSError alloc] init];
        NSObject *o = [NSJSONSerialization JSONObjectWithData:reqData
                                                      options:0
                                                        error:&error];
        if (o == nil) {
            NSLog(@"JSON deserialization failed: %@",
                  [error localizedDescription]);
            return;
        }
    }
}

@end
