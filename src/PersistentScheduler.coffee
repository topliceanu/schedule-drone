moment = require 'moment'
_ = require 'underscore'

Scheduler = require './Scheduler.coffee'
Store = require './Store.coffee'
util = require './util.coffee'


class PersistentScheduler extends Scheduler

    # A has of cyclic event ids which are currently running.
    runningCyclicEvents: []

    defaults:
        scheduleInterval: (moment.duration 1, 'hour').asMilliseconds()
        startPollingForEvents: true

    constructor: (@store, @options = {})->
        ###
            @param {Object} store - instance of Store, the persistence layer.
            @param {Object} options - constructor options
            @param {Number} [options.scheduleInterval] -  interval in ms to
                                    search for new events in the data store.
        ###
        unless @store instanceof Store
            throw new Error 'PersistentScheduler requires a Store instance'

        # Apply defaults.
        @options = _.extend @defaults, @options

        if @options.startPollingForEvents
            @_checkForEvents @options.scheduleInterval

    scheduleAndStore: (timestamp, event, payload = {}, callback) ->
        ###
            Method persists a scheduled event. If a callback is supplied it
            can return the cron job created.
            @param {String|Date} timestamp
            @param {String} event
            @param {Object} payload
            @param {Function} callback - function (err, cronJob)
        ###
        unless _.isString event
            throw new Error "Expected `event` to be String. #{event} given!"

        unless (_.isString timestamp) or (_.isDate timestamp)
            throw new Error "Expected `timestamp` to be either String or Date."+
                            "#{timestamp} given!"

        data =
            timestamp: timestamp
            event: event
            payload: payload

        @store.save data, (err, storedEvent) =>
            if err? then return callback err
            payload.__eventId = storedEvent.id

            return callback()

    @scheduleAndStore: (store, timestamp, event, payload = {}, callback) ->
        ###
            Class method to store a scheduled event.
            @static
            @see PersistentScheduler#scheduleAndStore for details
        ###
        unless store instanceof Store
            throw new Error 'PersistentScheduler requires a Store instance'

        unless _.isString event
            throw new Error "Expected `event` to be String. #{event} given!"

        unless (_.isString timestamp) or (_.isDate timestamp)
            throw new Error "Expected `timestamp` to be either String or Date."+
                            "#{timestamp} given!"
        data =
            timestamp: timestamp
            event: event
            payload: payload

        @store.save data, (err, storedEvent) =>
            callback err

    onTickEmit: (event, payload) =>
        ###
            Method overrides onTickEvent to make sure the event is marked as
            solved then the event is actually emitted.
            @override
        ###
        if payload? and _.isString payload.__eventId
            @store.solve payload.__eventId, (err) =>
                if err?
                    throw new util.Error err
                delete payload.__eventId
                super event, payload
        else
            # If the event is not persisted, fallback to the base class impl.
            super event, payload

    _checkForEvents: (scheduleInterval) ->
        ###
            Method runs every predefined interval to fetch one time events
            scheduled for the next interval and cyclic events that were not
            are new.
            @private
            @param {Number} scheduleInterval - ms upto next query for events.
        ###
        @_executeCyclicEvents()
        @_executeOneTimeEvents scheduleInterval

        # Check for new events at a configurable interval.
        setTimeout =>
            @_checkForEvents scheduleInterval
        , scheduleInterval

    _executeCyclicEvents: ->
        ###
            Method fetches all cron events from the store and schedules them.
            @private
        ###
        @store.getCyclicEvents (err, events) =>
            if err then throw new util.Error err
            for {id, timestamp, event, payload} in events when not (id in @runningCyclicEvents)
                @runningCyclicEvents.push id
                @schedule timestamp, event, payload

    _executeOneTimeEvents: (scheduleInterval) ->
        ###
            Method fetches events from the database for a given interval and
            executes them. In addition it fetches all unsolved events and
            executed them as well.
            @param {Number} scheduleInterval - the interval in ms for events
        ###

        @store.getOneTimeEvents scheduleInterval, (err, oneTimeEvents) =>
            if err? then throw new util.Error err

            @store.getUnsolvedEvents (err, unsolvedOneTimeEvents) =>
                if err then throw new util.Error err

                todoEvents = unsolvedOneTimeEvents.concat oneTimeEvents
                for {timestamp, event, payload} in todoEvents
                    @schedule timestamp, event, payload


# Public api.
module.exports = PersistentScheduler
