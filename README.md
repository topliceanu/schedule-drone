schedule-drone
==============

[![Build Status](https://travis-ci.org/topliceanu/schedule-drone.png?branch=master)](https://travis-ci.org/topliceanu/schedule-drone)

A reliable , fault-tolerant, persistent event scheduler for node.js
It achieves it's resiliance by storing event configurations on disk.
Currently only MongoDB persistance is supported.

Install
-------

````bash
npm install schedule-drone
````

Development
-----------

````bash
git clone git@github.com:topliceanu/schedule-drone.git
cd schedule-drone
npm install
npm test # To run the tests.
npm build # To build the js files that are published to npm
````

Example
-------

````coffeescript
drone = require 'schedule-drone'
drone.setConfig
    connectionString: 'mongodb://localhost:27017/scheduled-events'

scheduler = drone.daemon()

# Add a one-time event scheduled in the future, given a Date instance.
scheduler.schedule dateInFuture, 'my-one-time-event', params

# Add the cyclic event using the standard unix cron syntax.
scheduler.schedule '* * * * * 1', 'my-cron-event', params

scheduler.on 'my-one-time-event', (params) ->
    # Do something awesome

````

Api
---

`drone.setConfig()` - pass in configuration needed for the module's api to work. At the very least the connection string to the persistence layer must be supplied.

`drone.daemon()` - start the scheduler daemon. It listens to new scheduled events, stores then, and triggeres them appropriately. Returns an instance of a PersistenceScheduler.

`class PersistentScheduler` - inherits from `events.EventEmitter`

`PersistenceScheduler.schedule(when:String|Date, event:String, data:Object, callback:Function)`
- schedules an event in the future without storing it on disk.
- `when` can be a [crontab syntax string](http://crontab.org/) for cyclic events or an instance of [Date](https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Date) in the future for one-time events.

`PersistenceScheduler.scheduleAndStore(when:String|Date, event:String, data:Object, callbac:Function)`
- schedules and events in the future and stores it on disk.
- `when` can be a [crontab syntax string](http://crontab.org/) for cyclic events or an instance of [Date](https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Date) in the future for one-time events.

`drone.schedule(dataOrCronString, eventName, eventPayload, callback)`
- useful for scheduling events without actually needing to listen to when they occur (ie in another process)
- the _optional_  `callback` is called when an error occurs while persisting the task.


Licence
-------

MIT Licence

Copyright (C) 2013 alexandru.topliceanu@gmail.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
