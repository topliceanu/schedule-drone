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

PersistentScheduler = require './PersistentScheduler.coffee'
Store = require './Store.coffee'

isOptions = false
moduleOptions = {}
store = null

exports.setConfig = (options) ->
    ###
        Set module configuration.
        @param {Object} options
        @param {String} options.connectionString - mongodb connection string
        @param {String} options.eventsCollection - OPTIONAL - name of the
                            collection where tasks will be stored,
                            default value is 'ScheduledEvents'
        @param {Number} options.scheduleInterval - OPTIONAL - interval in ms
                            to poll the database for new scheduled events,
                            default 1000ms
        @param {Boolean} options.startPollingForEvents - OPTIONAL - allows the
                        user to start polling for events on demand if false,
                        defaults to true
    ###
    isOptions = true
    moduleOptions = options
    store = new Store options

exports.daemon = ->
    ###
        Starts the event listener daemon.
        @return an instance of a PersistentScheduler which inherits from
            events.EventEmitter. Use it to schedule events and to register
            handlers for the events.
    ###
    unless isOptions
        throw new Error 'Execute #setConfig() first'
    new PersistentScheduler store, options

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
