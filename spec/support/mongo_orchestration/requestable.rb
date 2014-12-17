# Copyright (C) 2009-2014 MongoDB, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'httparty'

module MongoOrchestration

  module Requestable
    include HTTParty

    def initialize(options = {})
      @base_path = options[:path] || MongoOrchestration::DEFAULT_BASE_URI
      create(options)
    end

    private

    def http_request(method, path = nil, options = {})
      dispatch do
        abs_path = [@base_path, path].compact.join('/')
        options[:body] = options[:body].to_json if options.has_key?(:body)
        HTTParty.send(method, abs_path, options)
      end
    end

    def get(path = nil, options = {})
      http_request(__method__, path, options)
    end

    def post(path = nil, options = {})
      http_request(__method__, path, options)
    end

    def ok?
      @response && @response.code/100 == 2
    end

    def alive?(id)
      begin
        get("servers/#{id}")
      rescue ServiceNotAvailable
        return false
      end
      @config = @response if @response && @response['procInfo']['alive']
    end

    def dispatch
      begin
        @response = yield
      rescue ArgumentError, Errno::ECONNREFUSED
        raise ServiceNotAvailable.new unless ok?
      end
    end
  end
end