assert = (require 'chai').assert
moment = require 'moment'

conf = require './conf'
drone = require '../src/'


describe 'schedule-drone', ->
    ###
        This test suite is intended to test the scheduler drone in an end to
        end fashion, ie. make sure params are correctly parsed, database
        is correclty setup, tasks are correctly inserted and executed.
    ###

    it 'should schedule and execute a one-off task', (done) ->

        event = 'test-one-time'
        payload = data: true
        date = moment().add('seconds', 2).toDate()

        drone.setConfig
            persistence:
                type: 'mongodb'
                connectionString: conf.mongo.connectionString
                eventsCollection: conf.mongo.eventsCollection

        # Start the daemon that listens to new tasks and runs current ones.
        scheduler = drone.daemon()

        scheduler.on event, (receivedPayload) ->
            assert.deepEqual receivedPayload, payload,
                'should receive the same payload as the one previously sent!'

            # Check the database.
            scheduler.store.EventModel.find().exec (error, scheduledEvents) ->
                if error? then return done error

                assert.lengthOf scheduledEvents, 0, 'should have removed the '+
                                        'task record before triggering the event'
                done()

        # Trigger the event.
        scheduler.schedule date, event, payload, (error) ->
            if error? then return done error
            assert.ok true, 'has successfully scheduled the event.'
