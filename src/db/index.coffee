mongoose = require 'mongoose'

JobSchema = require './JobSchema'


mongoose.connect

# Public API.
exports.JobModel = mongoose.model 'Job', JobSchema

