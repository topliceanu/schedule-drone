# Schedule-Drone

## Gist

Feature-rich, highly-available and reliable event scheduler with a rest api.

## Why?

Distributed applications often need to perform asynchronous tasks at some point in the future or on a recurring schedule.
In a microservices architecture, the **schedule-drone** ofers a simple api for CRUDing such tasks, then executing them.

## STATUS

[![NPM](https://nodei.co/npm/schedule-drone.png?downloads=true&stars=true)](https://nodei.co/npm/schedule-drone/)

[![NPM](https://nodei.co/npm-dl/schedule-drone.png?months=12)](https://nodei.co/npm-dl/schedule-drone/)

| Indicator              |                                                                          |
|:-----------------------|:-------------------------------------------------------------------------|
| documentation          | [topliceanu.github.io/schedule-drone](http://topliceanu.github.io/schedule-drone) ~~[hosted on coffedoc.info](http://coffeedoc.info/github/topliceanu/schedule-drone/master/)~~|
| continuous integration | [![Build Status](https://travis-ci.org/topliceanu/schedule-dron.svg?branch=master)](https://travis-ci.org/topliceanu/) |
| dependency management  | [![Dependency Status](https://david-dm.org/topliceanu/schedule-drone.svg?style=flat)](https://david-dm.org/topliceanu/schedule-drone) [![devDependency Status](https://david-dm.org/topliceanu/schedule-drone/dev-status.svg?style=flat)](https://david-dm.org/topliceanu/schedule-drone#info=devDependencies) |
| code coverage          | [![Coverage Status](https://coveralls.io/repos/topliceanu/schedule-drone/badge.svg?branch=master)](https://coveralls.io/r/topliceanu/schedule-drone?branch=master) |
| examples               | [/examples](https://github.com/topliceanu/schedule-drone/tree/master/examples) |
| development management | [![Stories in Ready](https://badge.waffle.io/topliceanu/schedule-drone.svg?label=ready&title=Ready)](http://waffle.io/topliceanu/schedule-drone) |
| change log             | [CHANGELOG](https://github.com/topliceanu/schedule-drone/blob/master/CHANGELOG.md) [Releases](https://github.com/topliceanu/schedule-drone/releases) |

## Features

* Rest api including reporting and CRUD for tasks.
* Persistance for scheduled tasks and their responses
* Higly configurable

## Install

```shell
npm install schedule-drone
```

## Quick Example

- read more on [crontab syntax here](http://crontab.org/)


## Contributing

1. Contributions to this project are more than welcomed!
    - Anything from improving docs, code cleanup to advanced functionality is greatly appreciated.
    - Before you start working on an ideea, please open an issue and describe in detail what you want to do and __why it's important__.
    - You will get an answer in max 12h depending on your timezone.
2. Fork the repo!
3. If you use [vagrant](https://www.vagrantup.com/) then simply clone the repo into a folder then issue `$ vagrant up`
    - if you don't use it, please consider learning it, it's easy to install and to get started with.
    - If you don't use it, then you have to:
         - install mongodb and have it running on `localhost:27017`.
         - install node.js and all node packages required in development using `$ npm install`
         - For reference, see `./vagrant_boostrap.sh` for instructions on how to setup all dependencies on a fresh ubuntu 14.04 machine.
    - Run the tests to make sure you have a correct setup: `$ npm run test`
4. Create a new branch and implement your feature.
 - make sure you add tests for your feature. In the end __all tests have to pass__! To run test suite `$ npm run test`.
 - make sure test coverage does not decrease. Run `$ npm run coverage` to open a browser window with the coverage report.
 - make sure you document your code and generated code looks ok. Run `$ npm run doc` to re-generate the documentation.
 - make sure code is linted (and tests too). Run `$ npm run lint`
 - submit a pull request with your code.
 - hit me up for a code review!
5. Have my kindest thanks for making this project better!


## Licence

(The MIT License)

Copyright (c) 2012 Alexandru Topliceanu (alexandru.topliceanu@gmail.com)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
