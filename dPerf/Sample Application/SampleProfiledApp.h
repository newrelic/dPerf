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

#import <Foundation/Foundation.h>

#define REQUEST_RATE 1.0 // per second
#define REQUEST_AND_PARSE_RATE (1.0 / 5.0) // per second

#define URL_200 @"http://httpstat.us/200"
#define URL_500 @"http://httpstat.us/500"
#define URL_USGS @"http://earthquake.usgs.gov/earthquakes/feed/v0.1/summary/2.5_month.geojson"

// An example app to profile. Supports repeatedly requesting a URL, and spinning
// the CPU on multiple threads.
@interface SampleProfiledApp : NSObject

// Run the sample application, running whatever tests are specified in |start|.
+ (void) start;

@end
