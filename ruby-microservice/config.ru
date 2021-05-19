# frozen_string_literal: true

## config.ru

require 'rack/protection'
require './app'

run Multivac
