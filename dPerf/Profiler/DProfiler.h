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


// Conversion of nanoseconds to seconds.
#define NanosToSeconds(x) (x / 1000000000.0)

// Number of trials to perform when benchmarking an operation.
#define BENCHMARK_TRIALS 1000

// A CPU profiling class which reports results to a remote server.
@interface DProfiler : NSObject

// Creates and starts a Profiler. See -initWithServer:andSampleRate:andTestName
// for parameter details.
+ (id) profileToServer: (NSString *)serverUrl
          withSampleRate: (double) sampleRate
             andDuration: (int) duration
             andTestName: (NSString *)testName;

// Designated initializer. |serverUrl| is a string specifying the destination
// server, including protocol and port. |sampleRate| is the profiling frequency
// given in hertz (samples per second). |duration| is the length of the
// profiling session. |testName| is the name of the current test or app.
- (id) initWithServer: (NSString *)serverUrl
        andSampleRate: (double) sampleRate
          andDuration: (int) duration
          andTestName: (NSString *)testName;

// Start the profiler.
- (void) start;

// Stop the profiler.
- (void) stop;

@end
