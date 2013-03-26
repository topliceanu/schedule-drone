_ = require 'underscore'
moment = require 'moment'
mongoose = require 'mongoose'

util = require './util.coffee'

Mixed = mongoose.Schema.Types.Mixed

class Store

    EVENTS_COLLECTION = 'ScheduledEvent'

    EventModel: null

    constructor: (@options = {}) ->
        unless (_.isObject @options) and
            (_.isString @options.connectionString)
                throw new util.Error 'Incorrect params'
        @options.eventsCollection ||= EVENTS_COLLECTION
        @connection = mongoose.createConnection @options.connectionString
        @_setupModel()

    closeConnection: (callback) ->
        @connection.close callback

    _setupModel: ->
        ###
            @private
        ###
        EventSchema = new mongoose.Schema
            event: {type: String, required: true}
            timestamp: {type: Date, required: false, sparse: true}
            done: {type: Boolean, required: false, sparse: true, default: false}
            cron: {type: String, required: false, sparse: true}
            payload: {type: Mixed, required: false, default: {}}

        EventSchema.methods.publish = ->
            event =
                id: @id
                event: @event
                timestamp: @timestamp or @cron
                payload: @payload

        @EventModel = @connection.model @options.eventsCollection, EventSchema

    getOneTimeEvents: (interval, callback) ->
        ###
            @return {Array} all one-time events from now upto now+interval.
            @param {Number} interval - poll interval once every interval ms.
            @param {Function} callback - function (err, events)
        ###
        unless (_.isNumber interval) and (_.isFunction callback)
            throw new util.Error "Bad params for getOneTimeEvents()",
                interval, callback

        start = moment().toDate()
        end = moment().add(interval).toDate()
        @EventModel.find()
            .where('timestamp').exists(yes)
            .where('cron').exists(no)
            .where('done').equals(false)
            .where('timestamp').gte(start).lte(end)
            .exec (err, events) ->
                if err? then return callback err
                unless events? and _.isArray events
                    return callback null, []

                formatedEvents = events.map (event) -> event.publish()
                return callback null, formatedEvents

    getUnsolvedEvents: (callback) ->
        ###
            @return {Array} all unfinished one-time events.
            @param {Function} callback - function (err, events)
        ###
        unless _.isFunction callback
            throw new util.Error 'Bad params for getUnsolvedEvents()'

        now = moment().toDate()
        @EventModel.find()
            .where('timestamp').exists(yes)
            .where('cron').exists(no)
            .where('done').equals(false)
            .where('timestamp').lte(now)
            .exec (err, events) ->
                if err? then return callback err
                unless events? and _.isArray events
                    return callback null, []

                formatedEvents = events.map (event) -> event.publish()
                return callback null, formatedEvents

    getCyclicEvents: (callback) ->
        ###
            @return {Array} all cron events registered.
            @param {Function} callback - function (err, events)
        ###
        unless _.isFunction callback
            throw new util.Error 'Bad params for getCyclicEvents()'

        @EventModel.find()
            .where('timestamp').exists(no)
            .where('cron').exists(yes)
            .exec (err, events) ->
                if err? then return callback err
                unless events? and _.isArray events
                    return callback null, []

                formatedEvents = events.map (event) -> event.publish()
                return callback null, formatedEvents

    save: (event, callback) ->
        ###
            Stores an event in the persistence layer.
            @param {Object} event - the event data to be stored
            @param {String|Date} event.timestamp - either a cron string or Date
            @param {String} event.event - the event's name
            @param {Object} event.payload - data attached to the event
            @return {Object} the saved object
        ###
        unless (_.isObject event) and
            (_.isString event.event) and
            ((_.isString event.timestamp) or (_.isDate event.timestamp))
                throw new util.Error 'Invalid event params for storage'

        storedEvent = new @EventModel
            event: event.event
            timestamp: event.timestamp if _.isDate event.timestamp
            cron: event.timestamp if _.isString event.timestamp
            payload: event.payload
        storedEvent.save (err) ->
            if err then return callback err
            return callback null, storedEvent.publish()

    solve: (eventId, callback) ->
        ###
            Marks a one-time event as solved in the persistence layer.
            @return {Boolean} whether the event was removed or not.
        ###
        @EventModel.findOneAndUpdate {_id: eventId}, {done: true},
            (err, event) ->
                if err? then return callback err
                unless event?
                    err = new util.Error "Could not find event for id #{eventId}"
                    return callback err

                return callback null, event.done is true


# Public API
module.exports = Store
