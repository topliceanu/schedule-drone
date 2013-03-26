events = require 'events'

cron = require 'cron'
_ = require 'underscore'


class Scheduler extends events.EventEmitter
    ###
        This class extends EventEmitter to add an extra
        method `schedule` used to schedule an event trigger
        sometime in the future.
    ###

    schedule: (timestamp, event, payload = undefined) ->
        unless _.isString event
            throw new Error "Expected `event` to be String. #{event} given!"

        unless (_.isString timestamp) or (_.isDate timestamp)
            throw new Error "Expected `timestamp` to be either String or Date."+
                            "#{timestamp} given!"

        new cron.CronJob
            cronTime: timestamp
            onTick: =>
                @onTickEmit event, payload
            start: true

    onTickEmit: (event, payload) ->
        @emit event, payload

# Public API.
module.exports = Scheduler
