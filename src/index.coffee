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
    isOptions = true
    moduleOptions = options
    store = new Store options

exports.daemon = ->
    ###
        Starts the event listener.
    ###
    new PersistentScheduler store, options

exports.scheduleAndStore = (timestamp, event, payload, callback) ->
    ###
        Schedule an event to be emitted at some point in the future.
    ###
    PersistentScheduler.scheduleAndStore store, timestamp, event, payload,
        (err, job) ->
            if err? then return callback err
            return callback null, job
