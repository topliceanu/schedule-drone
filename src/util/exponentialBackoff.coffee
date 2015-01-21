_ = require 'underscore'
Q = require 'q'
retry = require 'retry'


module.exports = exponentialBackoff = (fn, options = {}) ->
    options = _.extend options,
        # The maximum amount of times to retry the operation.
        retries: 9
        # The exponential factor to use.
        factor: 2
        # The number of milliseconds before starting the first retry.
        minTimeout: 1000 # 1 second in ms.
        # The maximum number of milliseconds between two retries.
        maxTimeout: 2 * 60 * 1000 # 2 minutes in ms.
        # Randomizes the timeouts by multiplying with a factor between 1 to 2.
        randomize: false
    retryOperation = retry.operation options

    retryOperation.attempt (numAttemptsSoFar) ->
        fn().fail (error) ->
            return if retryOperation.retry(error)
            Q.reject error
