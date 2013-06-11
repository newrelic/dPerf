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

/* Requests a given URL multiple times at a set frequency, optionally parsing
   a JSON response. */
@interface Requester : NSObject

/* Create and start requesting the specified url.
   See -initWithUrl:andRequestRate:parsingResponse for parameter details. */
+ (id) requestWithURL: (NSString *)url
         andRequestRate: (double) requestRate
        parsingResponse: (BOOL) parseResponse;

/* Designated initializer. |url| is the URL to request. |requestRate| is the
   frequency with which to request, given in hertz (requests per second).
   |parseResponse| controls whether or not a response body will attempt to be
   parsed as JSON. */
- (id) initWithURL: (NSString *)url
    andRequestRate: (double) requestRate
   parsingResponse: (BOOL) parseResponse;

/* Convenience initializer. Calls the designated initializer with
   |parsingResponse| specified as NO.
   See -initWithUrl:andRequestRate:parsingResponse for parameter details. */
- (id) initWithURL: (NSString *)url andRequestRate: (double) requestRate;

/* Start requesting. */
- (void) start;

@end
