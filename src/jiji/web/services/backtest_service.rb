# coding: utf-8

require 'sinatra/base'
require 'jiji/web/services/abstract_service'

module Jiji::Web
  class BackTestService < Jiji::Web::AuthenticationRequiredService

    options '/' do
      allow( 'GET,OPTIONS')
    end

    get '/' do
      ok(repository.all)
    end


    options '/:backtest_id' do
      allow( 'GET,DELETE,OPTIONS')
    end

    get '/:backtest_id' do
      ok(repository.get(param[:backtest_id]))
    end

    delete '/:backtest_id' do
      repository.delete(param[:backtest_id])
      no_content
    end


    def repository
      lookup(:backtest_repository)
    end

  end
end
