_ = require 'underscore'
mongoose = require 'mongoose'

createdOnUpdatedOn = require './plugins/createdOnUpdatedOn'
conf = require '../conf'


###
    Model holds the collection of scheduled events in the database.
    This are used to publish messages w/ payloads on the queue at
    a certain time
    @see github.com/topliceanu/schedule-drone
###

Mixed = mongoose.Schema.Types.Mixed

ScheduledEventSchema = new mongoose.Schema
    # LEGACY a kind of namespace for messages on a given queue.
    # Can be ignored but the scheduler will publish a message of format:
    # {event: event, params: payload}
    event: {type: String, required: true}
    # The name of the queue on which to publish the message.
    queue: {type: String, required: false} # conf.const.QUEUES
    # A Date object specifying when the message should be placed on the queue.
    # NOTE! This is in UTC time.
    timestamp: {type: Date, required: true}
    # Messages can be placed on a queue in a repeated manner. The scheduler
    # will place a message on the queue at the given timestamp then automatically
    # schedule the same message for delivery on after `repeat` interval.
    # This field can have two types of values:
    # 1. {minutes: <>, hours: <>, days: <>, weeks: <>, months: <>}
    # 2. unix-style cron-job strings.
    # Eg. db.scheduledevents.find({event: 'parse', done: false}).pretty()
    repeat: {type: Mixed, required: false}
    # Indicates whether or not the event was placed on the queue.
    # NOTE! As far as the scheduler is concerned the message is done, however
    # the message may stay on the queue for longer if no workers are available
    # or if it errors.
    done: {type: Boolean, required: true}
    # Object which will be serialized as json and placed on the queue.
    # NOTE! The format of the object placed on the queue is:
    # {event: event, params: payload} so the payload is accesible in `params` key
    payload: {type: Mixed, required: false}
    # Marks a scheduled event as deleted. It will not be visible from the api.
    deleted: {type: Boolean}
,
    # Rename collection to match the one inserted.
    collection: 'scheduledevent'
    # Disable ensureIndex call when application starts.
    autoIndex: false
    # Allows saving any keys to the model.
    strict: false
    # No versioning is stored in the model.
    versionKey: false

# Add createdOn and updatedOn fields to the schema.
ScheduledEventSchema.plugin createdOnUpdatedOn

ScheduledEventSchema.methods.publish = ->
    ###
        Publishes a ScheduledEvent document to the api
        @return {Object}
    ###
    id: @id
    event: @event
    queue: @queue
    timestamp: @timestamp.toString()
    repeat: @repeat
    done: @done
    payload: @payload


module.exports = ScheduledEventSchema
