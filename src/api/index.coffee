bodyParser = require 'body-parser'
cors = require 'cors'
express = require 'express'

JobResource = require './JobResource'


app = express()
app.use(bodyParser.json())

resource = new JobResource
app.get '/jobs', resource.readDocs()
app.post '/jobs', resource.createDoc()
app.get '/jobs/:jobId', resource.readDoc()
app.patch '/jobs/:jobId', resource.patchDoc()
app.delete '/jobs/:jobId', resource.removeDoc()


# Public API.
module.exports = app
