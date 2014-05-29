async = require 'async'
_ = require 'undersocre'

config = require './config'
plugin = require './plugin'

mAccount = require './model/account'

exports.joinPlan = (account, plan, callback) ->
  mAccount.joinPlan account, req.body.plan, ->
    async.each config.plans[req.body.plan].services, (serviceName, callback) ->
      if serviceName in account.attribute.services
        return callback()

      mAccount.update _id: account._id,
        $addToSet:
          'attribute.services': serviceName
      , ->
        if config.debug.mock_test
          return callback()

        (plugin.get serviceName).service.enable account, ->
          callback()

exports.leavePlan = (account, plan, callback) ->
  mAccount.leavePlan account, req.body.plan, ->
    async.each config.plans[req.body.plan].services, (serviceName, callback) ->
      stillInService = do ->
        for item in _.without(account.attribute.plans, req.body.plan)
          if serviceName in config.plans[req.body.plan].services
            return true

        return false

      if stillInService
        callback()
      else
        mAccount.update _id: account._id,
          $pull:
            'attribute.services': serviceName
        , ->
          if config.debug.mock_test
            return callback()

          (plugin.get serviceName).service.delete account, ->
            callback()