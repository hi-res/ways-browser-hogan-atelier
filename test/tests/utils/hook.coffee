should = do (require 'chai').should
request = require 'request'

user = process.env.SAUCE_USERNAME
key = process.env.SAUCE_ACCESS_KEY
build_id = process.env.TRAVIS_BUILD_NUMBER or (do new Date().getTime)

module.exports = (ctx, browser, caps, base_url, notify_sauce_labs, coverage) ->

  passed = false
  failures = 0

  ctx.beforeAll (done)->
    browser.init caps, (err)->
      console.log err if err?
      should.not.exist err
      browser.get base_url, (err)->
        console.log err if err?
        should.not.exist err
        do done

  ctx.afterAll (done)->

    if not coverage
      return quit browser, failures, notify_sauce_labs, done

    console.log '\nSaving test coverage..'

    browser.eval 'window.__coverage__', (err, coverage)->
      should.not.exist err
      should.exist coverage

      post_coverage base_url, coverage, ->
        quit browser, failures, notify_sauce_labs, ->
          console.log 'Done.\n\n'
          do done

  ctx.beforeEach ->
    passed = false

  ctx.afterEach ->
    failures++ if not passed

  pass = (done)->
    passed = true
    do done


quit = (browser, failures, notify_sauce_labs, done) ->
  browser.quit (err)->
    should.not.exist err
    
    if not notify_sauce_labs
      do done
    else
      do_notify_sauce_labs browser.sessionID, (failures is 0), done


do_notify_sauce_labs = ( job_id, status, done) ->
  opts =
    url: "http://#{user}:#{key}@saucelabs.com/rest/v1/#{user}/jobs/#{job_id}"
    method: 'PUT'
    headers: 'Content-Type': 'text/json'
    body: JSON.stringify
      passed: status
      public: true
      build: build_id
    jar: false # disable cookies: avoids CSRF issues

  request opts, (err, res)->
    should.not.exist err
    do done

post_coverage = ( base_url, coverage, done )->
  opts =
    url: base_url + 'coverage/client'
    method: 'POST'
    headers: 'Content-Type': 'application/json'
    body: JSON.stringify coverage

  request opts, (err, res)->
    should.not.exist err
    done()