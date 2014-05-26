_ = require 'underscore'
child_process = require 'child_process'
jade = require 'jade'
path = require 'path'
async = require 'async'
tmp = require 'tmp'
fs = require 'fs'

mAccount = require '../../core/model/account'

module.exports =
  enable: (account, callback) ->
    mAccount.update _id: account._id,
      $set:
        'attribute.plugin.phpfpm.is_enable': false
    , ->
      callback()

  delete: (account, callback) ->
    if attribute.plugin.phpfpm.is_enable
      this.switch account, callback
    else
      callback()

  switch: (account, is_enable, callback) ->
    callbackback = ->
      child_process.exec 'service php5-fpm restart', ->
        callback()

    if is_enable
      async.series [
        (callbacl) ->
          tmp.file
            mode: 0o750
          , (err, filepath, fd) ->
            config_content = _.template (fs.readFileSync path.join(__dirname, 'template/fpm-pool.conf')).toString(),
              account: account
            fs.writeSync fd, config_content, 0, 'utf8'
            fs.closeSync fd
            callback()

        (callback) ->
          child_process.exec "sudo cp #{filepath} /etc/php5/fpm/pool.d/#{account.username}.conf", ->
            callback()
      ], ->
        callbackback()
    else
      child_process.exec "sudo rm /etc/php5/fpm/pool.d/#{account.username}.conf", ->
        callbackback()

  widget: (account, callback) ->
    jade.renderFile path.join(__dirname, 'view/widget.jade'), {account: account}, (err, html) ->
      throw err if err
      callback html

  preview: (callback) ->
    jade.renderFile path.join(__dirname, 'view/preview.jade'), {}, (err, html) ->
      callback html
