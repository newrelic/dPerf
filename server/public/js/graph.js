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

Graph = function () {
    google.load('visualization', '1.0', {'packages': ['corechart']});
    google.setOnLoadCallback(this.draw.bind(this));
}

Graph.prototype.each = function (collection, cb) {
    for (var e in collection) {
        if (collection.hasOwnProperty(e)) {
            cb(e, collection[e]);
        }
    }
};

Graph.prototype.xhr = function (url, cb) {
    var r = new XMLHttpRequest();
    r.onreadystatechange = function () {
        if (r.readyState === 4) {
            cb(JSON.parse(r.responseText));
        }
    };
    r.open('GET', url, true);
    r.send(null);
}

Graph.prototype.getRuns = function (cb) {
    this.xhr('/runs', cb);
}

Graph.prototype.drawRun = function (runId) {
    var g = this;
    var div = document.createElement('div');
    div.id = "run_" + runId;
    document.getElementById('runs').appendChild(div);
    g.xhr("/run/" + runId, function (run) {
        if (!run.samples || !run.samples.length) {
            console.error("Run " + run.runId + " has no samples.");
            return;
        }

        var dataArray = [
            ['Time', 'CPU']
        ];

        var prev = undefined;
        g.each(run.samples, function (index, sample) {
            if (prev == undefined)
                prev = sample;

            var value = sample - prev;
            prev = sample;
            dataArray.push([index / run.sampleRate, value * 100]);
        });

        var data = google.visualization.arrayToDataTable(dataArray);
        data.setColumnLabel(0, 'ms');

        var date = new Date(run.time * 1000);
        var options = {
            title: run.name + ' ' + run.model + ' ' + run.version + ' - ' +
                run.sampleRate + ' samples/sec - ' + run.duration +
                ' seconds - ' + date,
            width: window.innerWidth,
            height: 600,
            vAxis: {format: '# ms'},
            hAxis: {format: '# sec'}
        };

        var chart = new google.visualization.LineChart(div);
        chart.draw(data, options);
    });
}

Graph.prototype.draw = function () {
    var g = this;
    g.getRuns(function (runsByName) {
        g.each(runsByName, function (runName, runs) {
            var timeSorted = runs.sort(function (a, b) {
                return b.time - a.time;
            });
            g.each(timeSorted, function (idx, run) {
                g.drawRun(run.runId);
            });
        });
    });
}
