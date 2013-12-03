require('chai').should()
fs = require 'fs'
_ = require 'underscore'
exec = require('child_process').exec
cli = require('../lib/cli')
sinon = require('sinon')

cmd = ['node', 'fixclosure', '--no-color']

class MockStdOut
  constructor: () ->
    @buffer = []
  write: (msg) ->
    @buffer.push msg
  toString: () ->
    @buffer.join ''

describe 'Command line', ->
  out = null
  err = null
  exit = null

  beforeEach ->
    out = new MockStdOut
    err = new MockStdOut
    exit = sinon.spy()

  it 'suceed with file argument', () ->
    cli(cmd.concat(['test/fixtures/cli/ok.js']), out, err, exit)
    exit.called.should.be.false

  it 'exit with 1 if no file argument', () ->
    stubWrite = sinon.stub(process.stdout, 'write');
    cli(cmd, out, err, exit)
    stubWrite.restore()

    exit.calledOnce.should.be.true
    exit.firstCall.args.should.eql [1]

  it 'exit with 1 if the result is NG', () ->
    cli(cmd.concat(['test/fixtures/cli/ng.js']), out, err, exit)
    exit.calledOnce.should.be.true
    exit.firstCall.args.should.eql [1]

  describe 'Options', ->
    it '--packageMethods', () ->
      cli(cmd.concat([
        'test/fixtures/cli/package_method.js',
        '--packageMethods=goog.foo.packagemethod1,goog.foo.packagemethod2'
      ]), out, err, exit)
      exit.called.should.be.false

    it '--roots', () ->
      cli(cmd.concat([
        'test/fixtures/cli/roots.js',
        '--roots=foo,bar'
      ]), out, err, exit)
      exit.called.should.be.false

    it '--replaceMap', () ->
      cli(cmd.concat([
        'test/fixtures/cli/replacemap.js',
        '--replaceMap=goog.foo.foo:goog.bar.bar,goog.baz.Baz:goog.baz.Baaz'
      ]), out, err, exit)
      exit.called.should.be.false

    it '--no-success', () ->
      cli(cmd.concat([
        'test/fixtures/cli/ok.js',
        'test/fixtures/cli/ng.js',
        '--no-success'
      ]), out, err, exit)
      exit.calledOnce.should.be.true
      exit.firstCall.args.should.eql [1]
      out.toString().should.be.eql ''
      err.toString().should.be.eql '''
        File: test/fixtures/cli/ng.js

        Provided:
        - goog.bar
        
        Required:
        - (none)
        
        Missing Require:
        - goog.baz
        
        FAIL!

        1 of 2 files failed

        '''

  describe '.fixclosurerc', ->
    it 'default', () ->
      cli(cmd.concat([
        'test/fixtures/cli/config.js',
      ]), out, err, exit)
      exit.called.should.be.false

    it '--config', () ->
      cli(cmd.concat([
        'test/fixtures/cli/config.js',
        '--config=fixtures/cli/.fixclosurerc1'
      ]), out, err, exit)
      exit.called.should.be.false