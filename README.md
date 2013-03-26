schedule-drone
==============

A reliable , fault-tolerant, persistent event scheduler for node.js
It achieves it's resiliance by storing event configurations on disk.
Currently only MongoDB persistance is supported.

Install
-------

````bash
npm install schedule-drone
````

Dev Install
-----------

````bash
git clone git@github.com:topliceanu/schedule-drone.git
cd schedule-drone
npm install
npm test # To run the tests.
````

Api
---

`drone.Scheduler` class extends from `events.EventEmitter` and adds a new
method that schedule a new event sometime in the future.

`drone.Scheduler.schedule(when:Mixed, event:String, [params:Object])`

    `when` can be a number, in this case it will be interpreted as a unix
    timestamp when the event will be triggered, or as a cron syntax string
    for a cyclic event.

    `params` can is an Object, that is passed to the event listener.

Example
-------

````coffeescript
drone = require 'schedule-drone'
drone.setup options
````



````coffeescript
drone = require 'schedule-drone'
drone.setConfig
    provider: 'mongodb'
    connection: 'mongodb://localhost'

scheduler = drone.daemon()
scheduler.on 'event'

drone.scheduleAndStore


# Initialize the scheduler drone.
scheduler = new drone.Persistence
    persistance:
        provider: 'mongodb'
        connection: 'mongodb://localhost'

# Add a one-time event scheduled in the future, given the unix timestamp.
# Note that the current supported resolution
# for one-time scheduled event is 1 minute.
scheduler.schedule 12341234514, 'event-name',
    # Pass in event params that will be delivered to the client
    param1: 'val1'
    param2: 'val2'
    # ...

# Add the cyclic event using the standard unix timestamp.
scheduler.schedule '* * * * * 1', 'event-name',
    # Pass in event params that will be delivered to the client
    param1: 'val1'
    param2: 'val2'
    # ...

# Make the scheduler trigger new event. If this method is not called,
# the scheduler can only be used to publish event.
scheduler.daemon()

# Register callbacks for events, but only after you start the daemon.
scheduler.on 'event-name', (params) ->
    # Do some magic with the params here.
````

