assert = (require 'chai').assert
moment = require 'moment'
sinon = require 'sinon'

conf = require './conf'
Store = require '../src/Store'
Scheduler = require '../src/Scheduler'
PersistentScheduler = require '../src/PersistentScheduler'


describe 'PersistentScheduler', ->

    beforeEach ->
        @store = new Store
            connectionString: conf.mongo.connectionString
            eventsCollection: conf.mongo.eventsCollection

    afterEach (done) ->
        dataStore = @store
        dataStore.EventModel.collection.remove (err) =>
            if err? then done err
            dataStore.closeConnection done

    it 'should be a scheduler', ->
        ps = new PersistentScheduler @store,
            scheduleInterval: (moment.duration 1, 'hour').asMilliseconds()
        assert.ok ps instanceof Scheduler, 'is instance of scheduler'

    it 'should schedule and store a one-time event', (done) ->
        ps = new PersistentScheduler @store,
            scheduleInterval: 1000

        # Schedule the event to go off in one second from now.
        event = 'test-one-time'
        payload = data: true
        date = moment().add('seconds', 2).toDate()
        eventScheduled = Date.now()

        ps.scheduleAndStore date, event, payload, (err) =>
            assert.ok not err?, 'should not error while storing the event'

            oneHour = 60 * 60 * 1000
            @store.getOneTimeEvents oneHour, (err, events) =>
                assert.lengthOf events, 1,
                    'should only return only one event for the next hour'
                assert.ok events[0].id?, 'should be stored in the db'
                assert.ok events[0].event, event, 'same event'
                assert.equal events[0].timestamp.toString(),
                    date.toString(), 'same timestamp'
                assert.equal events[0].payload.data, payload.data,
                    'same payload for the first event'

                ps.on event, (received) ->
                    assert.equal payload.data, received.data,
                        'same data is received'
                    done()

    it 'should schedule, execute and store a cron event', (done) ->
        ps = new PersistentScheduler @store,
            scheduleInterval: 1000

        # Schedule the event to go off at each second
        payload = data: true
        everySecond = '* * * * * *'
        event = 'text-cyclic'
        ps.scheduleAndStore everySecond, event, payload, (err) =>
            assert.ok not err?, 'should not error while storing the event'

            @store.getCyclicEvents (err, events) =>
                assert.lengthOf events, 1,
                    'should only return only one event for the next hour'
                assert.ok events[0].id?, 'should be stored in the db'
                assert.ok events[0].event, event, 'same event'
                assert.equal events[0].timestamp, everySecond, 'same timestamp'
                assert.equal events[0].payload.data, payload.data,
                    'same payload for the first event'

                eventCount = 0
                ps.on event, (received) ->
                    assert.equal payload.data, received.data,
                        'same data is received'
                    eventCount += 1
                    done() if eventCount is 1

    it 'should check for new events on a given interval', (done) ->
        spy = sinon.spy PersistentScheduler::, '_checkForEvents'
        ps = new PersistentScheduler @store,
            scheduleInterval: 1000 # ms
            startPollingForEvents: no

        ps._checkForEvents ps.options.scheduleInterval
        test = =>
            assert.ok spy.called, 'should have been called'
            assert.equal spy.callCount, 4, 'once on initialization and '+
                                           'once scheduled'
            PersistentScheduler::_checkForEvents.restore()
            done()
        setTimeout test, 1000
