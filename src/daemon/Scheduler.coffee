_ = require 'underscore'
cron = require 'cron'
moment = require 'moment'

conf = require '../conf'
models = (require '../models')('General')
queue = require './queue'
util = require '../util'


class Scheduler
    ###
        Class handles both scheduling and execution of tasks.
        It supports both one-time and cyclic events.

        A cyclic event is just like a one-time event, with the only difference
        that, upon completion, the cyclic event schedules another cylic event
        at the given specified time in the future.

        NOTE! only the immediate next execution time is
        calculated for cyclic events.

        Two types of cyclic events are supported:
        1. where you specify the interval between consecutive
           executions in and object syntax.
        2. where you special a crontab format to calculate next execution time.
    ###

    ONE_MINUTE = 60 * 1000 # One minute in ms.

    @add: (options, callback) ->
        ###
            Adds a scheduled task to the db.
            Optionally it can store a cyclic event which starts running at
            `timestamp` then re-executes each `repeat` interval.
            @static
            @param {Object} options
            @param {Date} options.timestamp - date to first publish the event
            @param {String} options.event - one of conf.const.QUEUE_EVENTS
            @param {String} [options.queue] - one of conf.const.QUEUES
            @param {Object} options.payload - event data
            @param {Object} options.repeat - OPTIONAL, repeat interval
            @param {Function} callback - gets executed when task is stored.
                        @param {Object} error - instance of Error
                        @param {Object} task - instance of model.ScheduledEvent
        ###
        schema = util.schemajs.create
            timestamp: {type: 'date', required: true}
            event:
                type: 'string',
                enum: _.values conf.const.QUEUE_EVENTS
                required: true
            queue:
                type: 'string'
                enum: _.values conf.const.QUEUES
                required: false
            payload:
                type: 'object'
                schema: conf.schemas.queue[options.event]
                required: false

        check = schema.validate options
        if check.valid is false
            return callback new Error JSON.stringify check.errors

        # Check repeat options.
        if options.repeat?
            unless (_.isString options.repeat) or (_.isObject options.repeat)
                return callback \
                    new Error 'repeat must be either a string or object'
            check.data.repeat = options.repeat

        task = new models.ScheduledEvent
            timestamp: check.data.timestamp
            event: check.data.event
            queue: check.data.queue
            repeat: check.data.repeat
            payload: check.data.payload # Whitelisted payload.
            done: false
        task.save (error) ->
            resolution = if error? then 'errored' else 'scheduled'
            util.stats.increment "scheduler.#{check.data.queue}."+
                "#{check.data.event}.#{resolution}"
            callback error, task

    @update: (taskId, options, callback) ->
        ###
            Method updates an existing scheduled task by it's id.
            If the task was already been executed (done=true) then it
            will not be updated and an error will be returned.

            @param {String} taskId - the id the task to reschedule.
            @param {Object} options - new task params
            @param {Date} options.timestamp - date to first publish the event
            @param {String} options.event - one of conf.const.QUEUE_EVENTS
            @param {String} [options.queue] - one of conf.const.QUEUES
            @param {Object} options.payload - event data
            @param {Object} options.repeat - OPTIONAL, repeat interval
            @param {Function} callback - gets executed when task is stored.
                        @param {Object} error - instance of Error
                        @param {Object} task - instance of model.ScheduledEvent
        ###

        # Check params
        unless _.isString taskId
            return callback new Error 'Expected `taskId` to be String'

        schema = util.schemajs.create
            timestamp: {type: 'date'}
            event:
                type: 'string',
                enum: _.values conf.const.QUEUE_EVENTS
                required: false
            queue:
                type: 'string'
                enum: _.values conf.const.QUEUES
                required: false
            payload:
                type: 'object'
                schema: conf.schemas.queue[options.event]
                required: false

        check = schema.validate options
        if check.valid is false
            return callback new Error JSON.stringify check.errors

        # Check repeat options.
        if options.repeat?
            unless (_.isString options.repeat) or (_.isObject options.repeat)
                return callback \
                    new Error 'repeat must be either a string or object'
            check.data.repeat = options.repeat

        models.ScheduledEvent.findById taskId, (error, task) ->
            if error? then return callback error
            unless task?
                return callback new Error "Task #{taskId} not found"
            if task.done is true
                return callback new Error "Task #{taskId} was already processed"

            # Override task params.
            # NOTE! we don't recursive merge params!
            ['timestamp', 'event', 'payload', 'repeat', 'queue'].forEach \
                (field) ->
                    task[field] = check.data[field] if check.data?[field]

            task.save (error) ->
                if error? then return callback error
                callback null, task


    # Keeps a count of the number of tasks that have
    # been processed each interval.
    taskCounter: 0

    # Queue client.
    client: queue.singleton()

    constructor: (options = {}) ->
        ###
            Builds an instance of the scheduler.
            NOTE! It does not start the daemon, nor should it!
            @param {Object} options
            @param {Number} options.interval - the interval in ms to look for
                                tasks in the database, defaults to ONE_MINUTE
        ###
        defaults =
            interval: ONE_MINUTE
            queue: conf.const.QUEUES.NEWSLETTER
        @options = _.extend defaults, options

    daemon: ->
        ###
            Starts a timer to continuously look for new tasks to process.
        ###
        @_processTasks()

    stopDaemon: ->
        ###
            Stops the polling of the database for new tasks.
        ###
        clearTimeout @currentInterval
        @currentInterval = null

    _processTasks: =>
        ###
            This method queries the database for new tasks to process.
            It will fetch all done=false tasks with the timestamp less then
            the current timestamp using mongoose.QueryStream
        ###
        util.log 'info', 'Start processing tasks'
        @taskCounter = 0

        queryStream = models.ScheduledEvent.find()
            .where('timestamp').lte(moment().toDate())
            .where('done').equals(false)
            .stream()

        queryStream.on 'data', (task) =>
            queryStream.pause()
            @_onData task, queryStream.resume.bind queryStream

        queryStream.on 'error', @_onError

        queryStream.on 'close', @_onClose

    _onData: (task, next) ->
        ###
            Gets executed whenever a new task is retrieved from the db.
            @param {Object} task - instance of models.ScheduledEvent
            @param {Function} next - continuation that resumes the query stream.
        ###
        task.done = true
        task.save (error) =>
            if error?
                util.log 'error', "Update task #{task.id} status failed", error
                return next()
            if task.repeat?
                # First reschedule the task, then publish on the queue.
                @_scheduleRepeat task, next
            else
                # Publish the message on the queue.
                @_publish task, next

    _scheduleRepeat: (task, next) ->
        ###
            Method stores a the same original task but
            at the next repeat interval.
            @param {Object} task - instance of models.ScheduledEvent
            @param {Function} next - continuation
        ###
        params =
            timestamp: @_getNextDate task.repeat
            event: task.event
            queue: task.queue
            payload: task.payload
            repeat: task.repeat
        Scheduler.add params, (callback, newTask) =>
            if error?
                util.log 'error', 'Unable to store cyclic task',
                         error, params
                return next()
            @_publish task, next

    _getNextDate: (repeat) ->
        ###
            This method calculates the next date a task should run at based
            on the repeat parameter.

            @param {Object|String} repeat - the interval to the next execution
                                of the current task. If String, it should follow
                                the crontab specs, if Object it should work with
                                util.timespanToMoment.
            @return {Date} - date of next execution of the task.
        ###
        if _.isObject repeat
            return (util.timespanToMoment repeat).toDate()
        else if _.isString repeat
            cronTime = new cron.CronTime repeat
            return (moment.utc cronTime.sendAt()).toDate()
        else
            throw new Error "Unsupported repeat format #{repeat}"

    _publish: (task, next) ->
        ###
            Method publishes a task to a queue. If a queue name is
            specified on the task it will be used, otherwise the Scheduler
            configuration task is used.
            Calls next() to resume the QueryStream.
            @param {Object} task - instance of models.ScheduledEvent
            @param {Function} next - continuation that resumes the query stream.
        ###
        queueName = task.queue or @options.queue
        @client.publish queueName,
            event: task.event
            params: task.payload
        @taskCounter += 1
        next()

    _onError: (error) =>
        ###
            Called each time an error occures.
            @param {Object} error
        ###
        util.log 'error', "Error fetching tasks", error

    _onClose: =>
        ###
            Called when processing the current batch of tasks ended.
        ###
        util.log 'info', "Finish processing tasks, count: #{@taskCounter}"
        @currentInterval = setTimeout @_processTasks, @options.interval


# Public API.
module.exports = Scheduler
