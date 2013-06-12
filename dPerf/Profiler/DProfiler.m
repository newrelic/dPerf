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

#import "DProfiler.h"
#import <mach/mach.h>
#import <mach/mach_time.h>

@interface DProfiler() {
    double _sampleRate;
    int _duration;
    int _maxSamples;
    float _samplingOverhead;
    NSString *_testName;
    NSString *_serverUrl;
    NSMutableArray *_samples;
    dispatch_source_t _dispatchTimer;
    struct mach_timebase_info _timebaseInfo;
}
@end

@implementation DProfiler

+ (id) profileToServer: (NSString *)serverUrl
          withSampleRate: (double) sampleRate
             andDuration: (int) duration
             andTestName: (NSString *)testName
{
    DProfiler *p = [[DProfiler alloc] initWithServer:serverUrl
                                     andSampleRate:sampleRate
                                       andDuration:duration
                                       andTestName:testName];
    [p start];
    return p;
}

- (id) initWithServer: (NSString *) serverUrl
        andSampleRate: (double) sampleRate
          andDuration: (int) duration
          andTestName: (NSString *)testName
{
    self = [super init];
    if (self) {
        _sampleRate = sampleRate;
        _duration = duration;
        _testName = [testName copy];
        _serverUrl = serverUrl;
        
        mach_timebase_info(&self->_timebaseInfo);
        
        [self reset];
        _samplingOverhead = [self benchmarkSample];
    }
    return self;
}

// Starts the sampling timer.
- (void) start
{
    _dispatchTimer = CreateDispatchTimer((1.0 / _sampleRate) * NSEC_PER_SEC,
                                         0,
                                         dispatch_get_main_queue(), ^{
        [self sample];
    });
}

// Stops the sampling timer.
- (void) stop
{
    dispatch_source_cancel(_dispatchTimer);
    
    if (_samples.count < _maxSamples) {
        NSLog(@"Prematurely stopped. sampling incomplete.");
    } else {
        NSLog(@"Recorded %d samples.", _samples.count);
    }
}

// Resets the stores samples to an empty array.
- (void) reset
{
    _maxSamples = _duration * _sampleRate;
    _samples = [NSMutableArray arrayWithCapacity: _maxSamples];
}

// Obtain one sample of the CPU time. If all samples have been collected, kick
// off the reporting thread.
- (void) sample
{
    if (_samples.count >= _maxSamples) {
        [self stop];
        @autoreleasepool {
            [NSThread detachNewThreadSelector:@selector(report) toTarget:self withObject:nil];
        }
    }
    [_samples addObject:[NSNumber numberWithDouble:([self cpuTime] - _samplingOverhead)]];
}

// Perform a benchmark |trials| times on the |block| block.
- (uint64_t) benchmarkWithTrials: (uint) trials
                        andBlock: (dispatch_block_t) block
{
    // Call the block once beforehand, warming up any method table lookups.
    block();
    
    uint64_t start = mach_absolute_time();
    for(int t = 0; t < trials; t++) {
        block();
    }
    return (mach_absolute_time() - start) / trials;
}

// Benchmark the |sample| method.
- (float) benchmarkSample
{
    // Temporarily modify max number of samples, generate some samples, but
    // not enough to trigger reporting.
    
    _maxSamples = BENCHMARK_TRIALS + 2;
    _samples = [NSMutableArray arrayWithCapacity: self->_maxSamples];
    
    uint64_t benchInterval = [self benchmarkWithTrials:BENCHMARK_TRIALS
                                              andBlock:^{
        [self sample];
    }];
    
    // Clean up our mess.
    [self reset];
    
    return [self secondsFromInterval:benchInterval];
}

// Gathers collected samples and metadata, serializes to JSON and sends results
// to the server.
- (void) report
{
    NSLog(@"Sending samples to %@", _serverUrl);
    
    // Snapshot the samples, in case sample collection is ongoing.
    NSArray *samples = [_samples copyWithZone:NULL];
    
    UIDevice *dev = [UIDevice currentDevice];
    NSNumber *runId = [NSNumber numberWithUnsignedInt: [self randomRunId]];
    NSNumber *epoch = [NSNumber numberWithUnsignedInt: [[NSDate date] timeIntervalSince1970]];
    NSNumber *sampleRate = [NSNumber numberWithUnsignedInt:_sampleRate];
    NSNumber *duration = [NSNumber numberWithUnsignedInt:_duration];
    
    // Dictionary which will be serialized to JSON.
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          _testName, @"name",               // Test name
                          runId, @"runId",                  // Unique run ID
                          epoch, @"time",                   // Timestamp
                          [dev systemVersion], @"version",  // iOS version
                          [dev model], @"model",            // Device model
                          sampleRate, @"sampleRate",        // Sampling rate
                          duration, @"duration",            // Profile duration
                          samples, @"samples",              // Samples
                          nil
                          ];
    
    NSData *json = [NSJSONSerialization dataWithJSONObject:dict
                                                   options:0
                                                     error: nil];
    
    // Create a URL for the request using the |_serverUrl| and appending a
    // cache busting token.
    NSString *url = [NSString stringWithFormat:@"%@/?cacheBust=%u",
                     _serverUrl,
                     (uint)[[NSDate date] timeIntervalSince1970]
                     ];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:json];
    
    NSError *error = [[NSError alloc] init];
    NSURLResponse *res = [[NSURLResponse alloc] init];
    
    NSData *resData = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&error];
    if (resData == nil && error != nil) {
        NSLog(@"Reporting may have failed: %@", [error localizedDescription]);
    }
}

// Generate a random 32-bit ID for identifying unique sessions.
- (uint) randomRunId
{
    uint8_t b[4];
    uint runId;
    
    int ret = SecRandomCopyBytes(kSecRandomDefault, 4, b);
    if (ret < 0) {
        NSLog(@"Error generating random run id. errno %d", errno);
        return 0;
    }
    
    runId = b[0] << 24 | b[1] << 16 | b[2] << 8 | b[3];
    return runId;
}

// Return the cumulative CPU time for this process. Adds CPU time for all
// threads dead or alive.
// See http://stackoverflow.com/questions/1543157/how-can-i-find-out-how-much-memory-my-c-app-is-using-on-the-mac
- (double)cpuTime
{
    task_t task;
    kern_return_t error;
    mach_msg_type_number_t count;
    thread_array_t thread_table;
    thread_basic_info_t thi;
    thread_basic_info_data_t thi_data;
    unsigned table_size;
    unsigned table_array_size;
    struct task_basic_info ti;
    double total_time;
    
    task = mach_task_self();
    count = TASK_BASIC_INFO_COUNT;
    error = task_info(task, TASK_BASIC_INFO, (task_info_t)&ti, &count);
    if (error != KERN_SUCCESS) {
        return -1;
    }
    {
        unsigned i;
        
        total_time = ti.user_time.seconds + ti.user_time.microseconds * 1e-6;
        total_time += ti.system_time.seconds + ti.system_time.microseconds * 1e-6;
        
        error = task_threads(task, &thread_table, &table_size);
        
        if (error != KERN_SUCCESS) {
            error = mach_port_deallocate(mach_task_self(), task);
            assert(error == KERN_SUCCESS);
            return -1;
        }
        
        thi = &thi_data;
        table_array_size = table_size * sizeof(thread_array_t);
        
        for (i = 0; i < table_size; ++i) {
            count = THREAD_BASIC_INFO_COUNT;
            error = thread_info(thread_table[i], THREAD_BASIC_INFO, (thread_info_t)thi, &count);
            

            if (error != KERN_SUCCESS) {
                for (; i < table_size; ++i) {
                    error = mach_port_deallocate(mach_task_self(), thread_table[i]);
                    assert(error == KERN_SUCCESS);
                }
                
                error = vm_deallocate(mach_task_self(), (vm_offset_t)thread_table, table_array_size);
                assert(error == KERN_SUCCESS);
                
                error = mach_port_deallocate(mach_task_self(), task);
                assert(error == KERN_SUCCESS);
                
                return -1;
            }
            
            if ((thi->flags & TH_FLAGS_IDLE) == 0) {
                total_time += thi->user_time.seconds + thi->user_time.microseconds * 1e-6;
                total_time += thi->system_time.seconds + thi->system_time.microseconds * 1e-6;
            }
            
            error = mach_port_deallocate(mach_task_self(), thread_table[i]);
            assert(error == KERN_SUCCESS);
        }
        
        error = vm_deallocate(mach_task_self(), (vm_offset_t)thread_table, table_array_size);
        assert(error == KERN_SUCCESS);
    }
    if (task != mach_task_self()) {
        error = mach_port_deallocate(mach_task_self(), task);
        assert(error == KERN_SUCCESS);
    }
    return total_time;
}

// Creates a dispatch timer. From Apple Concurrency Programming Guide.
dispatch_source_t CreateDispatchTimer(uint64_t interval,
                                      uint64_t leeway,
                                      dispatch_queue_t queue,
                                      dispatch_block_t block)
{
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                                     0, 0, queue);
    if (timer)
    {
        dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval, leeway);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}

- (float) nanosFromInterval: (uint64_t) timeInterval
{
    timeInterval *= _timebaseInfo.numer;
    timeInterval /= _timebaseInfo.denom;
    return (float)timeInterval;
}

- (float) secondsFromInterval: (uint64_t) timeInterval
{
    return NanosToSeconds([self nanosFromInterval:timeInterval]);
}



@end
