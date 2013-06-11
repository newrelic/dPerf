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

#import "SampleProfiledApp.h"
#import "Requester.h"

@implementation SampleProfiledApp

+ (void) start
{
    SampleProfiledApp *app = [[SampleProfiledApp alloc] init];
    
    [app run200Test];
}

// Send requests which generate HTTP 200 responses.
- (void) run200Test
{
    [self requestUrl:URL_200 atRate:REQUEST_RATE];
}

// Send requests which generate HTTP 500 responses.
- (void) run500Test
{
    [self requestUrl:URL_500 atRate:REQUEST_RATE];
}

// Send requests to USGS and parse the GeoJSON responses.
- (void) runParseTest
{
    [self requestUrl:URL_USGS atRate:REQUEST_AND_PARSE_RATE parsingResponse:YES];
}

// Spin up a few threads and generate some load.
- (void) runCPUTest
{
    [self useLotsOfCPUonThreads:4];
}

// Initiate periodic requests.
- (void) requestUrl: (NSString *)url atRate: (float) rate parsingResponse: (BOOL) parseResponse
{
    [Requester requestWithURL:url andRequestRate:rate parsingResponse:parseResponse];
}

// Initiate periodic requests, never parsing their responses.
- (void) requestUrl: (NSString *)url atRate: (float) rate
{
    [self requestUrl:url atRate:rate parsingResponse:NO];
}

// Start |numThreads| threads and spin them.
- (void) useLotsOfCPUonThreads: (uint) numThreads
{
    for (int i = 0; i < numThreads; i++) {
        @autoreleasepool {
            [NSThread detachNewThreadSelector:@selector(grindCPU) toTarget:self withObject:nil];
        }
    }
}

// Arbitrary function which generates CPU load.
- (void) grindCPU
{
    uint count = 0;
    while(1) {
        count++;
    }
}

@end
