mortimer = require 'mortimer'

db = require '../db'


# Resource for the ScheduledTaks
class JobResource extends mortimer.Resource

    constructor: (options) ->
        super db.JobModel, options

    # If needs be, you can restart this job.
    restart: (options = {}) ->


# Public Api
module.exports = JobResource
