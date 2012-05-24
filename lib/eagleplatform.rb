require 'active_support/core_ext'
require 'rest_client'
require 'net/http'
require 'json'
require "erb"

require "eagleplatform/eagleplatform_object"
require "eagleplatform/record"
require "eagleplatform/translation"
require "eagleplatform/filter"
require "eagleplatform/version"

# @api private
class Hash
  # @return [Hash] Return Hash with symbolic keys
  def to_sym_hash
    self.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
  end
end

# To use this library you must do:
#   require 'eagleplatform'
#   Eagleplatform.setup('account','auth_token')
#   
#   # Update record fields:
#     record = Eagleplatform::Record.find(1234)
#     record.description = 'Very fun record'
#     record.update
#     
#   # Close all translations:
#     Eagleplatform::Translation.all.each do |translation|
#       translation.delete
#     end
# @see setup
module  Eagleplatform
  @@account, @@auth_token, @@api_url = nil
  
  # Return account  
  def account
    @@account
  end
  
  SERVER = "api.eagleplatform.com"  # API server url
  # Date format: 'dd.mm.yyyy' => '18.5.2012'
  DATE_FORMAT = Regexp.new(/^([0-9]|0[1-9]|1[0-9]|2[0-9]|3[0-1])\.([0-9]|0[1-9]|1[0-2])\.(19|20)\d\d$/)
  
  # Methods list provided by eaglelatform API
  module Methods
    TRANSLATIONS_GET_LIST = { method: "get", path: "/streaming/translations.json"}
    TRANSLATION_GET_INFO = { method: "get", path: "/streaming/translations/:id.json"}
    TRANSLATION_DELETE = { method: "delete", path: "/streaming/translations/:id.json"}
    TRANSLATION_UPDATE = { method: "put", path: "/streaming/translations/:id.json"}
    TRANSLATION_GET_STATISTICS = { method: "get", path: "/streaming/translations/:id/statistics.json"}
    
    RECORDS_GET_STATISTICS = { method: "get", path: "/media/records/statistics.json"}
    RECORD_GET_STATISTICS = { method: "get", path: "/media/records/:id/statistics.json"}
    RECORD_GET_INFO = { method: "get", path: "/media/records/:id.json"}
    RECORD_UPDATE = { method: "put", path: "/media/records/:id.json"}
    RECORD_DELETE = { method: "delete", path: "/media/records/:id.json"}
    RECORD_UPLOAD_FROM_FTP = { method: "post", path: "/media/records.json"}
    RECORD_UPLOAD_FROM_HTTP = { method: "post", path: "/media/records.json"}
    
    FILTER_GET_RECORDS = { method: "get", path: "/media/filters/:id.json"}
  end

  class << self
    # @api private
    def request(api_method, params = {})
        # Add other required params.
        params['account'] = @@account || ( raise "You must set account" )
        params['auth_token'] = @@auth_token || ( raise "You must set auth_token" )
        raise "Wrong api_method param" if api_method[:method].blank? || api_method[:path].blank? 
        full_api_url = @@api_url.to_s+api_method[:path]
        
        #params.each_pair { |k,v| params[k]=v.to_s}
        
        # Check method name and render request
        if ['get','delete'].include? api_method[:method]
          req_code = ERB.new <<-EOF
            RestClient.<%=api_method[:method] %> "<%= full_api_url %>", :params => <%= params %>
          EOF
        elsif ['post','put'].include? api_method[:method]
          req_code = ERB.new <<-EOF
            RestClient.<%=api_method[:method] %> "<%= full_api_url %>", params
          EOF
          puts params
        else
          # raise error if wrong method name 
          raise "Wrong http method name '#{api_method[:method]}'"
        end
         
        puts req_code.result(binding)
        # Execute request
        eval req_code.result(binding)
    end
    
    # @api private
    def call_api(api_method, params = {})      
        response = call_api_raw(api_method, params)
        root = JSON.parse(response)
        
        #Check if there was an error
        unless root.empty?
          raise "Call_API ERROR: #{root['error']}" if root['error'] 
          #    code = result.elements['code'].text
          #    message = result.elements['msg'].text
          #    bad_request = result.elements['your_request'].to_s
          #    raise EagleError.new(code, message, bad_request)
        end
        root['data'] ? (data = root['data']) : (raise 'Not include data')
        return data
    end
    
    # @api private
    def call_api_raw(api_method, params = {})
        request(api_method, params).body
    end

    ##
    # Eagleplatform module initializator
    # @example How to use Eagleplatform.setup()
    #   Eagpleplatform.setup('your_account','your_auth_token')
    # @param [String] account Your account name   
    # @param [String] auth_token Your authentication token form eagleplatform.com
    # @param [String] server API server url. Default: api.eagleplatform.com 
    ##
    def setup(account, auth_token, server = SERVER)
        account.blank? ? ( raise ArgumentError, 'account is blank') : @@account = account
        auth_token.blank? ? ( raise ArgumentError, 'auth_token is blank') : @@auth_token = auth_token
        server.blank? ? ( raise ArgumentError, 'server is blank' ) : server.slice!('http://')
        @@api_url = URI.parse("http://#{server}")
    end
  end
end