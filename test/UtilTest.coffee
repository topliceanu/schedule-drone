assert = (require 'chai').assert

util = require '../src/util.coffee'


describe 'Util', ->

    describe 'PersistentSchedulerError', ->

        it 'should have the correct name', ->
            error = new util.Error
            assert.equal error.name, 'PersistentSchedulerError',
                'should have the correct name'

        it 'should work when given plain string messages', ->
            msg = 'some msg'
            error = new util.Error msg
            assert.equal msg, error.message, 'messages should be the same'

        it 'should work when given an error instance', ->
            msg = 'my error message'
            originalError = null

            try
                throw new Error msg
            catch exception
                error = new util.Error exception

                assert.equal error.name, 'PersistentSchedulerError',
                    'should keep the error type'
                assert.equal error.message, msg,
                    'should inherit the message from the parent'
                assert.equal error.stack, exception.stack,
                    'should inherit the stack from the original'
