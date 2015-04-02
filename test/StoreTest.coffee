assert = (require 'chai').assert
mongoose = require 'mongoose'
moment = require 'moment'

conf = require './conf'
Store = require '../src/Store'


describe 'Store', ->

    beforeEach ->
        @store = new Store
            connectionString: conf.mongo.connectionString
            eventsCollection: conf.mongo.eventsCollection

    afterEach (done) ->
        dataStore = @store
        dataStore.EventModel.collection.remove (err) =>
            if err? then done err
            dataStore.closeConnection done

    it 'should support the extended connection options, '+
       'ie. clustering', (done) ->
        store = new Store
            connectionString: 'mongodb://localhost:27017/schedule-drone-test'
            eventsCollection: 'events'
            options:
                someOption: true
        assert.isDefined store?.connection?.options?.someOption,
            'should pass the options to the constructor'
        assert.isTrue store.connection.options.someOption,
            'should set the correct option value to the underlying driver'
        done()

    it 'should expose the correct api', ->
        assert.ok @store.EventModel?,
            'should expose the model object'

        ['getOneTimeEvents', 'getCyclicEvents',
         'getUnsolvedEvents', 'save', 'solve'].forEach (method) =>
             assert.ok @store[method],
                 "should expose the #{method} method"

    it 'should store a new cron event', (done) ->
        event =
            event: 'some-event'
            timestamp: '* * * * * *'
            payload:
                data: true
        @store.save event, (err, storedEvent) ->
            assert.ok not err?, 'no errors should be thrown'
            assert.ok storedEvent.id?, 'should have an id now'
            assert.equal event.event, storedEvent.event, 'save event name'
            assert.equal event.timestamp, storedEvent.timestamp, 'same timestamp'
            assert.deepEqual event.payload, storedEvent.payload, 'same payload'
            done()

    it 'should store a timestamp event', (done) ->
        event =
            event: 'some-event'
            timestamp: new Date
            payload:
                data: true
        @store.save event, (err, storedEvent) ->
            assert.ok not err?, 'no errors should be thrown'
            assert.ok storedEvent.id?, 'should have an id now'
            assert.equal event.event, storedEvent.event, 'save event name'
            assert.equal event.timestamp, storedEvent.timestamp, 'same timestamp'
            assert.deepEqual event.payload, storedEvent.payload, 'same payload'
            done()

    it 'should make an event solved', (done) ->
        event =
            event: 'some-event'
            timestamp: new Date
            payload:
                data: true
        @store.save event, (err, storedEvent) =>
            assert.ok not err?, 'no errors should be thrown'
            assert.ok storedEvent.id?, 'should have an id now'

            @store.solve storedEvent.id, (err, isSolved) ->
                assert.ok not err?, 'no errors should be thrown'
                assert.isTrue isSolved, 'should be solved'
                done()

    it 'should throw an error for unexistent event ids', (done) ->
        fakeEventId = "515164134de3fb6c14000004"
        @store.solve fakeEventId, (err, isSolved) ->
            assert.ok err?, 'should throw an error'
            assert.match err.message, /Could not find event/,
                'should complain about the event id'
            done()

    it 'should fetch all one-time events', (done) ->
        event1 =
            event: 'event-1'
            timestamp: moment().add('minutes', 10).toDate()
            payload:
                event: 1
        event2 =
            event: 'event-2'
            timestamp: moment().add('minutes', 70).toDate()
            payload:
                event: 2

        @store.save event1, (err, storedEvent1) =>
            assert.ok not err?, 'no errors have occured'

            @store.save event2, (err, storedEvent2) =>
                assert.ok not err?, 'no errors have occured'

                oneHour = 60*60*1000
                @store.getOneTimeEvents oneHour, (err, events) =>
                    assert.lengthOf events, 1,
                        'should only return only one event for the next hour'
                    assert.ok events[0].id?, 'should be stored in the db'
                    assert.ok events[0].event, event1.event, 'same event'
                    assert.equal events[0].timestamp.toString(),
                        event1.timestamp.toString(), 'same timestamp'
                    assert.deepEqual events[0].payload, event1.payload,
                        'same payload for the first event'
                    done()

    it 'should fetch all un-solved event', (done) ->
        event1 =
            event: 'event-1'
            timestamp: moment().subtract('minutes', 30).toDate()
            payload:
                event: 1
        event2 =
            event: 'event-2'
            timestamp: moment().subtract('minutes', 40).toDate()
            payload:
                event: 2
        @store.save event1, (err, storedEvent1) =>
            assert.ok not err?, 'no errors occured while saving event1'

            @store.save event2, (err, storedEvent2) =>
                assert.ok not err?, 'no errors occured while saving event2'

                @store.solve storedEvent2.id, (err, isSolved) =>
                    assert.ok not err? and isSolved is yes,
                        'no errors occured while solving event2'

                    @store.getUnsolvedEvents (err, events) =>
                        assert.ok not err?,
                            'no errors while fetching unsolved events'

                        assert.lengthOf events, 1, 'only one event is unsolved'
                        assert.ok events[0].id?, 'should have an id'
                        assert.equal event1.event, events[0].event,
                            'same event name'
                        assert.equal event1.timestamp.toString(),
                            events[0].timestamp.toString(), 'same timestamp'
                        assert.deepEqual event1.payload, events[0].payload,
                            'same event payload'
                        done()

    it 'should fetch all cyclic cron events', (done) ->
        event1 =
            event: 'event-1'
            timestamp: moment().subtract('minutes', 30).toDate()
            payload:
                event: 1
        event2 =
            event: 'event-2'
            timestamp: '* * * * * *'
            payload:
                event: 2

        @store.save event1, (err, storedEvent1) =>
            assert.ok not err?, 'no errors occured while saving event1'

            @store.save event2, (err, storedEvent2) =>
                assert.ok not err?, 'no errors occured while saving event2'

                @store.getCyclicEvents (err, events) ->
                    assert.ok not err?, 'no errors fetching cron events'

                    assert.lengthOf events, 1, 'only one event is unsolved'
                    assert.ok events[0].id?, 'should have an id'
                    assert.equal event2.event, events[0].event,
                        'same event name'
                    assert.equal event2.timestamp.toString(),
                        events[0].timestamp.toString(), 'same timestamp'
                    assert.deepEqual event2.payload, events[0].payload,
                        'same event payload'
                    done()
