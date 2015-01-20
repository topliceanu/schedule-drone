mongoose = require 'mongoose'

conf = require '../conf'


REGEX_URL_VALIDATOR = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/gim
TWO_MINUTES = 2 * 60 * 1000 # Two minutes in seconds.


JobSchema = new mongoose.Schema
    # Helps to bundle together multiple scheduled job.
    namespace: {type: String, required: false}

    # Date when to execute the the scheduled job.
    start: {type: Date, required: true, default: Date.now()}

    # Main action of the job.
    # This action should be immutable. For a new uri/method/etc, a new
    # scheduled job should be created you should create a new endpoint !?
    action:
        uri: {type: String, match: REGEX_URL_VALIDATOR}
        method:
            type: String
            enum: _.values conf.const.METHOD
            default: conf.const.METHOD.GET
        headers: {type: Object}
        body: {type: String}

    # If the initial call fails, multiple attempts will be performed and are
    # configured by the following parameters.
    retry:
        # Number of seconds to wait for a reply!
        timeout: {type: Number, default: conf.default.timeout}
        tries: {type: Number, default: conf.default.tries}
        factor: {type: Number, default: conf.default.factor}
        minTimeout: {type: Number}
        maxTimeout: {type: Number}

    # Action to perform when the main action fails after best effort attempts.
    error:
        uri: {type: String, match: REGEX_URL_VALIDATOR}
        method:
            type: String
            enum: _.values conf.const.METHOD
            default: conf.const.METHOD.GET
        headers: {type: Object}
        body: {type: String}

    # Configurations needed in case this job is recurring.
    rec:
        cron: {type: String} # Supports cron type.
        count: {type: Number} # Number of times this should run.
        endDate: {type: Date} # This should not run after this date.

    # The state of the job:
    # ENABLED - it is ignored when executing jobs.
    # DISABLED - it is ignored when executing jobs
    state:
        type: Number
        required: true
        enum: _.values conf.const.JOB_STATE
        default: conf.const.JOB_STATE.ENABLED

    # Contains the response from the scheduled jobs and details of the responses.
    execution:
        # Last execution date, if this job is recurring.
        last: {type: Date}
        # Total number of executions so far, if this job is recurring.
        count: {type: Number, default: 0}
        # Number of failed executions so far, if this job is recurring.
        failed: {type: Number, default: 0}
        # List of job execution sorted desc by timestamp.
        responses: [{
            # When was the job performed.
            timestap: {type: Date}
            # The headers received from the server. Only 20 headers are stored.
            headers: {type: Object}
            # The Contents received from the server. Only 2kb of data are stored.
            body: {type: String}
        }]
,
    # Remove version key.
    versionKey: false


# Public API.
module.exports = JobSchema




















#_ = require 'underscore'
#mongoose = require 'mongoose'
#
#createdOnUpdatedOn = require './plugins/createdOnUpdatedOn'
#conf = require '../conf'
#
#
####
#    Model holds the collection of scheduled events in the database.
#    This are used to publish messages w/ payloads on the queue at
#    a certain time
#    @see github.com/topliceanu/schedule-drone
####
#
#Mixed = mongoose.Schema.Types.Mixed
#
#ScheduledEventSchema = new mongoose.Schema
#    # LEGACY a kind of namespace for messages on a given queue.
#    # Can be ignored but the scheduler will publish a message of format:
#    # {event: event, params: payload}
#    event: {type: String, required: true}
#    # The name of the queue on which to publish the message.
#    queue: {type: String, required: false} # conf.const.QUEUES
#    # A Date object specifying when the message should be placed on the queue.
#    # NOTE! This is in UTC time.
#    timestamp: {type: Date, required: true}
#    # Messages can be placed on a queue in a repeated manner. The scheduler
#    # will place a message on the queue at the given timestamp then automatically
#    # schedule the same message for delivery on after `repeat` interval.
#    # This field can have two types of values:
#    # 1. {minutes: <>, hours: <>, days: <>, weeks: <>, months: <>}
#    # 2. unix-style cron-job strings.
#    # Eg. db.scheduledevents.find({event: 'parse', done: false}).pretty()
#    repeat: {type: Mixed, required: false}
#    # Indicates whether or not the event was placed on the queue.
#    # NOTE! As far as the scheduler is concerned the message is done, however
#    # the message may stay on the queue for longer if no workers are available
#    # or if it errors.
#    done: {type: Boolean, required: true}
#    # Object which will be serialized as json and placed on the queue.
#    # NOTE! The format of the object placed on the queue is:
#    # {event: event, params: payload} so the payload is accesible in `params` key
#    payload: {type: Mixed, required: false}
#    # Marks a scheduled event as deleted. It will not be visible from the api.
#    deleted: {type: Boolean}
#,
#    # Rename collection to match the one inserted.
#    collection: 'scheduledevent'
#    # Disable ensureIndex call when application starts.
#    autoIndex: false
#    # Allows saving any keys to the model.
#    strict: false
#    # No versioning is stored in the model.
#    versionKey: false
#
## Add createdOn and updatedOn fields to the schema.
#ScheduledEventSchema.plugin createdOnUpdatedOn
#
#ScheduledEventSchema.methods.publish = ->
#    ###
#        Publishes a ScheduledEvent document to the api
#        @return {Object}
#    ###
#    id: @id
#    event: @event
#    queue: @queue
#    timestamp: @timestamp.toString()
#    repeat: @repeat
#    done: @done
#    payload: @payload
#
#
#module.exports = ScheduledEventSchema
