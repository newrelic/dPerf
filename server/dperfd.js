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

/*
 dPerf - distributed profiler
 This is the Node data collection server for dPerf. Simply records incoming
 test runs from clients and renders each of them with Google Charts.
 */

var express = require('express'),
    stylus = require('stylus'),
    nib = require('nib'),
    mongo = require('mongodb');

var dperf = {
    // Listening port for the service.
    PORT: 9123,

    // MongoDB server hostname.
    MONGOD_HOST: 'localhost',

    // MongoDB server port.
    MONGOD_PORT: 27017,

    // MongoDB database name.
    MONGOD_DB: 'dperf',

    // Location of Jade view templates.
    VIEW_DIR: '/views',

    // Public static content.
    PUBLIC_DIR: '/public'
};


// Express configuration.
var app = express();
app.configure(function () {
    app.set('views', __dirname + dperf.VIEW_DIR);
    app.set('view engine', 'jade');
    app.use(express.favicon());
    app.use(express.logger());
    app.use(express.bodyParser());
    app.use(express.methodOverride());
    app.use(app.router);
    app.use(stylus.middleware(
        {
            src: __dirname + dperf.PUBLIC_DIR,
            compile: function (str, path) {
                return stylus(str).set('filename', path).use(nib());
            }
        }
    ));
    app.use(express.static(__dirname + dperf.PUBLIC_DIR))
});

var db = new mongo.Db(
    dperf.MONGOD_DB,
    new mongo.Server(dperf.MONGOD_HOST, dperf.MONGOD_PORT),
    { safe: false }
);

// Basic validation of a test run.
var validateRun = function (run) {
    var fields = [
        'name', 'runId', 'time', 'version', 'model',
        'sampleRate', 'duration', 'samples'
    ];

    for (var f in fields) {
        var field = fields[f];
        if (!run.hasOwnProperty(field))
            return false;
        if (run[field].length == 0)
            return false;
    }

    if (!run.samples instanceof Array)
        return false;

    return true;
};

// Error handler for bad requests.
var errorResponse = function (res, message) {
    res.write(JSON.stringify({status: 'error', message: message}));
    res.end();
};

// Success handler for good requests.
var okResponse = function (res) {
    res.write(JSON.stringify({status: 'ok'}));
    res.end();
}

// Obtain a database connection and start up the REST service.
db.open(function (err, db) {
    if (err) throw err;

    db.collection("runs", function (err, runs) {
        if (err) throw err;

        // Index endpoint. Serves up the graphing client.
        app.get('/', function (req, res) {
            res.render('index', { title: 'dPerf' });
        });

        // Data post endpoint. Saves test run information from clients.
        app.post('/', function (req, res) {
            var run = req.body;

            if (!validateRun(run))
                return errorResponse(res, "Invalid run.");

            runs.insert(run, function (err) {
                if (err) {
                    console.warn(err);
                    return errorResponse(res, "Can't insert run.");
                }
                console.log("Saved " + run.name + " run " + run.runId);
                okResponse(res);
            });
        });

        // REST interface that returns a JSON representation of all runs.
        app.get('/runs', function (req, res) {
            var fields = { runId: 1, name: 1, time: 1 };
            var sort = { time: -1 };
            runs.find({}, fields).sort(sort).toArray(function (err, allRuns) {
                if (err) {
                    console.warn(err);
                    return errorResponse(res, "Can't find runs.");
                }
                var byName = {};
                allRuns.forEach(function (run) {
                    if (!byName[run.name])
                        byName[run.name] = [run];
                    else
                        byName[run.name].push(run);
                });
                res.write(JSON.stringify(byName));
                res.end();
            });
        });

        // REST interface that returns JSON for a single run.
        app.get('/run/:runId', function (req, res) {
            var runId = parseInt(req.params.runId);

            runs.find({ runId: runId }).toArray(function (err, run) {
                if (err) {
                    console.warn(err);
                    return errorResponse(res, "No run with id " + runId);
                }
                if (!run.length) {
                    return errorResponse(res, "No run with id " + runId);
                }
                res.write(JSON.stringify(run[0]));
                res.end();
            });
        });

        // Start listening.
        console.log("Listening for requests on " + dperf.PORT);
        app.listen(dperf.PORT);
    });
});
