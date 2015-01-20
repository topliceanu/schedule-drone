assert = (require 'chai').assert
moment = require 'moment'
Q = require 'q'

conf = require '../../conf'
models = (require '../../models')('General')
queue = require '../../modules/queue'
Scheduler = require '../../modules/Scheduler'


describe 'Scheduler', ->

    before ->
        @client = queue.singleton()

    afterEach (done) ->
        Q.all([
            @client.cleanup()
            models.clearDatabase()
        ]).then (-> done()), done

    it 'should add a new task to the database', (done) ->
        params =
            timestamp: (moment().add 'days', 1).toDate()
            event: conf.const.QUEUE_EVENTS.NEWSLETTER
            payload:
                campaignId: 'test-campaign-id'
        Scheduler.add params, (error, task) ->
            if error? then return done error

            assert.isDefined task.id, 'should have been stored in the db'
            assert.equal task.timestamp, params.timestamp, 'same date'
            assert.equal task.event, params.event, 'same event'
            assert.deepEqual task.payload, params.payload, 'same payload'
            done()

    it 'should process tasks when started as a daemon', (done) ->
        queue = 'scheduler-tasks-1'
        scheduler = new Scheduler queue: queue

        params1 =
            timestamp: (moment().add 'hours', -1).toDate()
            event: conf.const.QUEUE_EVENTS.NEWSLETTER
            payload:
                campaignId: 'test-campaign-1'

        params2 =
            timestamp: (moment().add 'hours', -2).toDate()
            event: conf.const.QUEUE_EVENTS.NEWSLETTER
            payload:
                campaignId: 'test-campaign-2'

        # Add events to db.
        Scheduler.add params1, (error, task1) ->
            if error? then return done error

            Scheduler.add params2, (error, task2) ->
                if error? then return done error

                # Start scheduler daemon.
                scheduler.daemon()

        messageCounter = 0
        @client.subscribe queue, (error, data, ack) =>
            ack()
            messageCounter += 1

            if error?
                scheduler.stopDaemon()
                return done error

            assert.equal data.event, conf.const.QUEUE_EVENTS.NEWSLETTER,
                'should be the same type as the one stored'
            campaignIds = [
                params1.payload.campaignId
                params2.payload.campaignId
            ]
            assert.include campaignIds, data.params.campaignId,
                'should be one of the initial campaign ids'

            if messageCounter is 2
                scheduler.stopDaemon()
                done()

    it 'should process cyclic tasks when repeat is a timespan object', (done) ->
        ###
            Test makes sure the Scheduler, after executing a task, checks to
            see if it's cyclic (ie. has a repeat property) then puts another
            event in the database with the right timestamp, given that
            repeat is a object expected by util.timespanToMoment.
        ###
        queue = 'scheduler-tasks-2'
        scheduler = new Scheduler queue: queue

        # Add a job timestamp in the past so it will be executed immediately
        # when the scheduler starts.
        jobTimestamp = moment().subtract 'seconds', 1

        params =
            timestamp: jobTimestamp.toDate()
            event: conf.const.QUEUE_EVENTS.NEWSLETTER
            payload:
                campaignId: 'test-campaign-id'
            repeat:
                days: 1

        # Add the message to the queue.
        Scheduler.add params, (error, task) ->
            if error? then return done error
            assert.isDefined task.id, 'should have stored the task in the db'
            scheduler.daemon()

        @client.subscribe queue, (error, data, ack) ->
            # Send ack to the queue and stop the daemon no matter what happens.
            ack()
            scheduler.stopDaemon()

            if error?
                return done error

            assert.equal data.event, params.event, 'same event name'
            assert.deepEqual data.params, params.payload,
                'should have stored the same payload'

            models.ScheduledEvent.find()
                .where('done').equals(false)
                .exec (error, tasks) ->
                    if error?
                        return done error

                    assert.lengthOf tasks, 1,
                        'should have found only one not-done task'
                    task = tasks[0]

                    assert.equal \
                        moment(task.timestamp).startOf('minute').valueOf(),
                        jobTimestamp.add('days', 1).startOf('minute').valueOf(),
                        'should have scheduled execution in one day time'
                    assert.equal task.event, params.event, 'same event type'
                    assert.deepEqual task.payload, params.payload,
                        'should have placed the same payload'
                    assert.deepEqual task.repeat, params.repeat,
                        'should keep the same repeat param'
                    done()

    it 'should process cyclic tasks when repeat is in crontab format', (done) ->
        ###
            Test makes sure the Scheduler, after executing a tasks, checks to
            see if it's cyclic (ie. has a repeat property) then puts another
            event in the database with the right timestamp, given that repeat
            is a crontab string format.
        ###
        queue = 'scheduler-tasks-2'
        scheduler = new Scheduler queue: queue

        params =
            timestamp: new Date
            event: conf.const.QUEUE_EVENTS.NEWSLETTER
            payload:
                campaignId: 'test-campaign-id'
            repeat: '00 00 00 * * *' # Every day at 00:00:00.

        Scheduler.add params, (error, task) ->
            if error? then return done error
            assert.isDefined task.id, 'should have stored the task in the db'

            # Process now the task that was just inserted.
            scheduler._onData task, ->

                assert.isTrue task.done, 'original task should be executed'

                # Fetch the updated task
                models.ScheduledEvent.find()
                    .where('done').equals(false)
                    .exec (error, tasks) ->
                        if error? then return done error

                        assert.lengthOf tasks, 1,
                            'should have found only one not-done task'
                        task = tasks[0]

                        expectedTimestamp = moment()
                            .add('days', 1).startOf('day').toDate()

                        assert.equal task.timestamp.toString(),
                            expectedTimestamp.toString(),
                            'should schedule next execution correctly'

                        assert.equal task.event, params.event, 'same event type'
                        assert.deepEqual task.payload, params.payload,
                            'should have placed the same payload'
                        assert.deepEqual task.repeat, params.repeat,
                            'should keep the same repeat param'
                        done()

    it 'should be able to re-schedule a task not-executed', (done) ->
        ###
            Test makes sure an existing task is updated and only executed
            at the new update time.
        ###
        jobTimestamp = moment().subtract 'seconds', 1
        params =
            timestamp: jobTimestamp.toDate()
            event: conf.const.QUEUE_EVENTS.NEWSLETTER
            payload:
                campaignId: 'test-campaign-id'
            repeat:
                days: 1

        Scheduler.add params, (error, task) ->
            if error? then return done error
            assert.isDefined task.id, 'should have stored the task in the db'

            newTimestamp = jobTimestamp.add 'minute', 1
            updates =
                timestamp: newTimestamp.toDate()

            Scheduler.update task.id, updates, (error, updatedTask) ->
                if error? then return done error

                assert.equal task.id, updatedTask.id, 'same task id'
                assert.equal updatedTask.timestamp.toString(),
                    newTimestamp.toDate().toString(),
                    'should have the new timestamp stored'
                assert.isFalse updatedTask.done,
                    'delayed task should still be not-done'
                done()

    it 'should not re-schedule a completed task', (done) ->
        ###
            Test makes sure an existing task is not updated if it's already
            processed.
        ###
        jobTimestamp = moment().subtract 'days', 1
        params =
            timestamp: jobTimestamp.toDate()
            event: conf.const.QUEUE_EVENTS.NEWSLETTER
            payload:
                campaignId: 'test-campaign-id'

        Scheduler.add params, (error, task) ->
            if error? then return done error
            assert.isDefined task.id, 'should have stored the task in the db'

            # Mark the task as completed.
            task.done = true
            task.save (error) =>
                if error? then return done error

                newTimestamp = jobTimestamp.add 'minute', 1
                updates =
                    timestamp: newTimestamp.toDate()

                Scheduler.update task.id, updates, (error, updatedTask) ->
                    assert.isDefined error, 'should return an error'
                    assert.match error.message, /was already processed/,
                        'should complain about the task being done already'
                    assert.isUndefined updatedTask,
                        'should not return any updated task'
                    done()

    describe '_getNextDate()', ->

        it 'should produce the expected date for a crontab string', ->
            repeat = '00 00 00 * * *' # Every day at 00:00.
            expected = ((moment().add 'days', 1).startOf 'day').toDate()
            actual = Scheduler::_getNextDate repeat
            assert.equal actual.toString(), expected.toString(),
                'should product the next day at 00:00'

        it 'should product the expected date for a timespan object', ->
            repeat = {'days': 1}
            expected = (moment.utc().add 'days', 1).toDate()
            actual = Scheduler::_getNextDate repeat
            assert.equal actual.toString(), expected.toString(),
                'should product the same timestamp but tomorrow'

        it 'should error if repeat is not a correct cron format', ->
            repeat = 'alexandru'
            assert.throws ->
                Scheduler::_getNextDate repeat
            , Error, /.*?/
            , 'throws error because it cant parse repeat as cron'

        it 'should error out if wrong param is passed in', ->
            repeat = 123456789
            assert.throws ->
                Scheduler::_getNextDate repeat
            , Error, /Unsupported repeat format/
            , 'throws error because repeat is neither string nor object'

    describe 'queue option', ->

        it 'should set the message on a custom queue', (done) ->
            ###
                Instantiates the scheduler with a given default queue,
                but place a message for another queue. This test makes
                sure the message is still correctly read.
            ###
            scheduler = new Scheduler queue: conf.const.QUEUES.EMAILING

            params =
                timestamp: moment().subtract('days', 1).toDate()
                event: conf.const.QUEUE_EVENTS.TRANSACTIONAL_SEND
                queue: conf.const.QUEUES.TRANSACTIONAL_SEND
                payload:
                    campaignId: 'some-campaign-id'
                    userId: 'some-user-id'
                    shopId: 'some-shop-id'
                    event: {'some-event': 'data'}

            Scheduler.add params, (error, task) ->
                if error? then done error
                scheduler.daemon()

            @client.subscribe conf.const.QUEUES.TRANSACTIONAL_SEND,
                (error, data, ack) =>
                    # Return ACK to the queue and stop the scheduler
                    # daemon no matter what.
                    ack()
                    scheduler.stopDaemon()

                    if error? then return done error
                    assert.equal data.event, conf.const.QUEUE_EVENTS.TRANSACTIONAL_SEND,
                        'should set the correct event type'
                    assert.deepEqual data.params, params.payload,
                        'should send the initial payload as message params'
                    done()
