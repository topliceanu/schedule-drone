Q = require 'q'
request = require 'request'
retry = require 'retry'



exports.call = call = (options = {}, callback) ->
    ###
        Wrapper on top of request.js to support http call retry.
        This method will call the endpoint and execute the callback on the
        response. If the returned promise fails, it will call the endpoint
        again. If it fails for the given number of tries, a promise with the
        last error is returned. If it succedes a promise with the desired
        result is returned.

        @see https://github.com/mikeal/request#requestoptions-callback
        @see https://github.com/tim-kos/node-retry#retrytimeoutsoptions

        @param {Object} options - all options supported by request.js and retry.js
        @param {String} options.uri|url - fully qualified uri
        @param {Object} options.qs - object containing querystring values
        @param {String} options.method - http method (default: "GET")
        @param {Object} options.headers - http headers (default: {})
        @param {Mixed} options.body - entity body for PATCH, POST and PUT
        @param {Object} options.form - simulates submiting a form
        @param {Mixed} options.auth - A hash containing values user|username
        @param {Object} options.json - sets body but to JSON representation
        @param {Boolean} options.followRedirect
        @param {Boolean} options.followAllRedirects
        @param {Number} options.maxRedirects - the maximum number of redirects
        @param {String} options.encoding - Encoding of response data.
        @param {Nubmer} options.timeout - Integer milliseconds to wait.
        @param {String} options.proxy - An HTTP proxy to be used.
        @param {Object} options.oauth - Options for OAuth HMAC-SHA1 signing.
        @param {Object} options.hawk - Options for Hawk signing.
        @param {Boolean} options.strictSSL - If true, requires SSL certificates.
        @param {Boolean} options.gzip - Gzip content
        @param {Number} options.retries - The maximum amount of times to retry the op.
        @param {Number} options.factor - The exponential factor to use. Default is 2.
        @param {Number} options.minTimeout - The number of ms before starting first retry.
        @param {Number} options.maxTimeout - The max number of ms between two retries.
        @param {Number} options.randomize - Randomizes the timeouts.
        @param {Function} callback - method is called whenever the
                            response from the http request comes back. It must
                            return an Q.Promise.
        @return {Object} Q.Promise which resolves to the response data.
    ###
    deferred = Q.defer()

    if options.retries? then options.retries -= 1

    operation = retry.operation options
    operation.attempt (numAttempt) ->
        (Q.nfcall request, options).then ([res, body]) ->
            callback res, body
        .then (result) ->
            deferred.resolve result
        .fail (error) ->
            shouldRetry = operation.retry error
            return if shouldRetry
            deferred.reject error

    deferred.promise
