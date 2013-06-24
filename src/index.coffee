###
    This Module implements a persistant scheduler.
    It's main componenets are:
    1. A Scheduler Class that extends event.EventEmitter and allows user
    to postpone the event trigger to a configurable point in the future.
    2. A Data Store used to store event information,
    making the scheduler fault-tolerant.
    3. A PersistentScheduler that extends the Scheduler to allow the events to
    be stored in the database and be triggered in batches.
###

PersistentScheduler = require './PersistentScheduler'
Store = require './Store'

isOptions = false
moduleOptions = {}
store = null

exports.setConfig = (options) ->
    ###
        Set module configuration.
        @param {Object} options - params to pass to the scheduler drone
        @param {Object} options.persistence - options for the persistence
                                              layer of tasks
        @param {String} options.persistence.type - the type of storage supported
                                        Currently only 'mongodb' is supported.
        @param {String} options.persistence.connectionString - specific option
                                        for mongoose, the connection string.
        @param {String} options.persistence.options - specific option
                                        for mongoose, the second options passed
                                        to the Mongoose connection constructor.
        @param {String} options.persistence.eventsCollection - OPTIONAL - name
                            of the collection where tasks will be stored,
                            default value is 'ScheduledEvents'
        @param {Number} options.scheduleInterval - OPTIONAL - interval in ms
                            to poll the database for new scheduled events,
                            default 1000ms
        @param {Boolean} options.startPollingForEvents - OPTIONAL - allows the
                        user to start polling for events on demand if false,
                        defaults to true
    ###
    unless options.persistence?.type? and options.persistence.type is 'mongodb'
        throw new Error 'Only mongodb persistence is supported currently'
    store = new Store options.persistence

    isOptions = true
    moduleOptions = options

exports.daemon = ->
    ###
        Starts the event listener daemon.
        @return an instance of a PersistentScheduler which inherits from
            events.EventEmitter. Use it to schedule events and to register
            handlers for the events.
    ###
    unless isOptions
        throw new Error 'Execute #setConfig() first'
    new PersistentScheduler store, moduleOptions

exports.schedule = (timestamp, event, payload, callback = ->) ->
    ###
        Schedule an event to be emitted at some point in the future.
        @param {String|Date} timestamp - either a cron string or a Date
        @param {String} event - the event name
        @param {Object} payload - the data attached to the event
        @param {Function} callback - OPTIONAL
    ###
    unless isOptions
        throw new Error 'Execute #setConfig() first'
    PersistentScheduler.scheduleAndStore store, timestamp, event, payload, (err) ->
        return callback err
