record = null

module "Travis.Build",
  setup: ->
  teardown: ->
    Travis.Build.resetData()
    Travis.Job.resetData()

test 'it does not load record on duration, finishedAt and result if job is not in finished state', ->
  Travis.Build.load [{ id: 1, state: 'started', started_at: null }]

  Ember.run ->
    record = Travis.Build.find 1

    record.loadTheRest = ->
      ok(false, 'loadTheRest should not be called')

    record.get('duration')
    record.get('finishedAt')
    record.get('result')

  wait().then ->
    ok(true, 'loadTheRest was not called')

test 'it loads record on duration, finishedAt and result if job is in finished state', ->
  expect(1)

  Travis.Build.load [{ id: 1, state: 'passed', started_at: null }]

  Ember.run ->
    record = Travis.Build.find 1

    record.loadTheRest = ->
      ok(true, 'loadTheRest should be called')

    record.get('finishedAt')

  wait()

test 'it takes into account all the jobs when getting config keys', ->
  buildConfig = { rvm: ['1.9.3', '2.0.0'] }
  Travis.Build.load [{ id: '1', job_ids: ['1', '2', '3'], config: buildConfig }]

  Travis.Job.load [{ id: '1', config: { rvm: '1.9.3', env: 'FOO=foo'       } }]
  Travis.Job.load [{ id: '2', config: { rvm: '2.0.0', gemfile: 'Gemfile.1' } }]
  Travis.Job.load [{ id: '3', config: { rvm: '1.9.3', jdk: 'OpenJDK'       } }]

  build = null
  rawConfigKeys = null
  configKeys = null
  Ember.run ->
    build = Travis.Build.find '1'
    rawConfigKeys = build.get('rawConfigKeys')
    configKeys = build.get('configKeys')

  deepEqual(rawConfigKeys, ['rvm', 'env', 'gemfile', 'jdk' ])
  deepEqual(configKeys, [ 'Job', 'Duration', 'Finished', 'Ruby', 'ENV', 'Gemfile', 'JDK' ])

test 'build can be canceled if any of the jobs is cancelable', ->
  Travis.Build.load [{ id: '1', job_ids: ['1', '2'], state: 'running' }]

  Travis.Job.load [{ id: '1', state: 'running' }]
  Travis.Job.load [{ id: '2', state: 'finished' }]

  build = null
  job   = null
  Ember.run ->
    build = Travis.Build.find '1'
    job   = Travis.Job.find '1'

  ok(build.get('canCancel'))

  Ember.run -> build.set('state', 'finished')
  ok(build.get('canCancel'))

  Ember.run -> job.set('state', 'finished')
  ok(!build.get('canCancel'))
