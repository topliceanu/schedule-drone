_ = require 'underscore'


class PersistentSchedulerError extends Error
    constructor: (error, context...) ->
        super()
        @name = 'PersistentSchedulerError'
        @context = context
        if _.isString error
            @message = error
        if error instanceof Error
            @message = error.message
            @stack = error.stack

    toString: ->
        return "#{@name}: #{@message}, #{@context}, #{@stack}"

# Public API
exports.Error = PersistentSchedulerError
