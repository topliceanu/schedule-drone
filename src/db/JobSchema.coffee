mongoose = require 'mongoose'

conf = require '../conf'


REGEX_URL_VALIDATOR = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/gim

JobSchema = new mongoose.Schema
    # Helps to bundle together multiple scheduled job.
    namespace: {type: String, required: false}

    # Date when to execute the the scheduled job.
    start: {type: Date, required: true, default: Date.now()}

    # Main action of the job.
    # This action should be immutable. For a new uri/method/etc, a new
    # scheduled job should be created you should create a new endpoint !?
    action:
        uri: {type: String, match: REGEX_URL_VALIDATOR}
        method:
            type: String
            enum: _.values conf.const.METHOD
            default: conf.const.METHOD.GET
        headers: {type: Object}
        body: {type: String}

    # Configures the response object.
    expect:
        # What status codes are acceptable as responses.
        status: [{type: Number, default: 200}]
        headers: {type: Object}
        # RegExp to match against the response payload.
        body: {type: String}

    # If the initial call fails, multiple attempts will be performed and are
    # configured by the following parameters.
    retry:
        # Number of seconds to wait for a reply!
        timeout: {type: Number, default: conf.default.timeout}
        tries: {type: Number, default: conf.default.tries}
        factor: {type: Number, default: conf.default.factor}
        minTimeout: {type: Number}
        maxTimeout: {type: Number}

    # Action to perform when the main action fails after best effort attempts.
    error:
        uri: {type: String, match: REGEX_URL_VALIDATOR}
        method:
            type: String
            enum: _.values conf.const.METHOD
            default: conf.const.METHOD.GET
        headers: {type: Object}
        body: {type: String}

    # Configurations needed in case this job is recurring.
    rec:
        cron: {type: String} # Supports cron type.
        count: {type: Number} # Number of times this should run.
        endDate: {type: Date} # This should not run after this date.

    # The state of the job:
    # ENABLED - it is ignored when executing jobs.
    # DISABLED - it is ignored when executing jobs
    status:
        type: Number
        required: true
        enum: _.values conf.const.JOB_STATE
        default: conf.const.JOB_STATE.ENABLED

    # Contains the response from the scheduled jobs and details of the responses.
    execution:
        # Last execution date, if this job is recurring.
        last: {type: Date}
        # Total number of executions so far, if this job is recurring.
        count: {type: Number, default: 0}
        # Number of failed executions so far, if this job is recurring.
        failed: {type: Number, default: 0}
        # List of job execution sorted desc by timestamp.
        responses: [{
            # When was the job performed.
            timestap: {type: Date}
            # The headers received from the server. Only 20 headers are stored.
            headers: {type: Object}
            # The Contents received from the server. Only 2kb of data are stored.
            body: {type: String}
        }]


# Public API.
module.exports = JobSchema
