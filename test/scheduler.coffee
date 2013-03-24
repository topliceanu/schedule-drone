events = require 'events'

assert = (require 'chai').assert
moment = require 'moment'

Scheduler = require '../src/Scheduler.coffee'


describe 'Scheduler', ->

    it 'should extend EventEmitter', ->
        scheduler = new Scheduler
        assert.ok scheduler instanceof events.EventEmitter,
            'should be instance of events.EventEmitter'

        assert.ok scheduler.on? and scheduler.emit?,
            'has the methods on an EventEmitter'
        assert.ok scheduler.schedule?,
            'has the extra method used to schedule events'

    it 'should throw error when timestamp is not valid', ->
        scheduler = new Scheduler

        assert.throws ->
            scheduler.schedule 123, 'event', {}
        , Error, /timestamp/, 'Should throw error regarding timestamp format'

        assert.throws ->
            scheduler.schedule '* bad cron format', 'event', {}
        , Error, /bad/, 'Should throw error regarding cron pattern'

        assert.throws ->
            scheduler.schedule new Date, 123, {}
        , Error, /event/, 'Should complain about the event not being a String'

    it 'should correctly schedule a one-time event', (done) ->
        scheduler = new Scheduler

        # Schedule the event to go off in two seconds from now.
        payload = data: true
        date = moment().add('seconds', 1).toDate()
        eventScheduled = Date.now()
        scheduler.schedule date, 'test-event', payload

        scheduler.on 'test-event', (receivedPayload) ->
            eventTriggered = Date.now()
            assert.ok 950 < eventTriggered - eventScheduled < 1050,
                'should be triggered at ~1000ms from scheduling'
            assert.deepEqual receivedPayload, payload,
                'should send the correct data on the event'
            done()
