# dPerf - Distributed profiler for iOS

dPerf is a little CPU profiler designed to run efficiently on real hardware
and report back to a centralized server so that data from many devices can be
aggregated and analyzed in bulk.

This is an experimental tool and should be treated as such.

# Running the dPerf client 

Simply copy Profiler.h and Profiler.m into your application.

Add the following to your AppDelegate, or wherever you would like to start
the Profiler. Substitute parameter values that make sense for your profiling needs:

    [Profiler profileToServer:@"http://localhost:9123" withSampleRate:50.0 andDuration:65 andTestName:@"your test" ];

# Running the dPerf server

Install [Node](http://nodejs.org/) and [MongoDB](http://www.mongodb.org/).

Change to the "server" directory of dPerf and run "npm install".

Run "node dperfd.js".

Browse to port 9123 of your server, such as [http://localhost:9123](http://localhost:9123)

# License

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
