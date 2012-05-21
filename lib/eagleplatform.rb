require 'active_support/core_ext'
require 'rest_client'
require 'net/http'
require 'json'
require "erb"

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
  
  SERVER = "api.eagleplatform.com"  # API server url
  # Date format: 'dd.mm.yyyy' => '18.5.2012'
  DATE_FORMAT = Regexp.new(/^([0-9]|0[1-9]|1[0-9]|2[0-9]|3[0-1])\.([0-9]|0[1-9]|1[0-2])\.(19|20)\d\d$/)
  
  # Methods list provided by eaglelatform API
  module Methods
    TRANSLATIONS_GET_LIST = { method: "get", path: "/streaming/translations.json"}
    TRANSLATION_GET_INFO = { method: "get", path: "/streaming/translations/:id.json"}
    TRANSLATION_DELETE = { method: "delete", path: "/streaming/translations/:id.json"}
    TRANSLATION_UPDATE = { method: "put", path: "/streaming/translations/:id.json"}
    TRANSLATION_GET_STATISTICS = { method: "get", path: "/streaming/translations/:id.json"}
    
    RECORDS_GET_STATISTICS = { method: "get", path: "/media/records/statistics.json"}
    RECORD_GET_STATISTICS = { method: "get", path: "/media/records/:id/statistics.json"}
    RECORD_GET_INFO = { method: "get", path: "/media/records/:id.json"}
    RECORD_UPDATE = { method: "put", path: "/media/records/:id.json"}
    RECORD_DELETE = { method: "delete", path: "/media/records/:id.json"}
    RECORD_UPLOAD_FROM_FTP = { method: "post", path: "/media/records.json"}
    RECORD_UPLOAD_FROM_HTTP = { method: "post", path: "/media/records.json"}
    
    FILTER_GET_RECORDS = { method: "get", path: "/media/filters/:id.json"}
  end

  # @api private
  # Class porvides methods for all Eagleplatform Objects
  class EagleplatformObject < Struct    
    # @return [Hash] convert Struct to Hash
    def to_hash
      Hash[self.each_pair.to_a]
    end
  end
  
  # Record class
  class Record < EagleplatformObject
    
    ##
    # @param [Numeric] id ID of record
    # @example 
    #   Eagleplatform::Record.find(45632)
    # @return [Eagleplaform::Record] if record present
    def self.find(id)
      raise ArgumentError, 'id must be numeric' unless id.is_a? Numeric
      api_method = {method: Methods::RECORD_GET_INFO[:method], 
                    path: Methods::RECORD_GET_INFO[:path].gsub(':id',id.to_s)}
      
      result = Eagleplatform.call_api(api_method).first[1]      
      Eagleplatform::Record.new("Record",*result.keys).new(*result.values)
    end
    
    
    ##
    # Create record and upload file form ftp server
    # @param [Hash] args the ftp options to upload video
    # @option args [Hash] :ftp
    #   server: 'ftp_server',
    #   file_path: 'file_path',
    #   username: 'user',
    #   password: 'pass'
    # @option args [Hash] :record
    #   name: 'record_name'
    #   description: 'record_description'
    # @example 
    #   record_params = { name: 'SomeRecord', description: 'Example Video' }
    #   ftp_params = { server: 'ftp.example_server.com',file_path: '/videos/my_video.mpg',username: 'ftp_username', password: 'ftp_passowrd' }  
    #   Eagleplatform::Record.upload_form_ftp( record: record_params, ftp: ftp_params)
    # @return [Eagleplatform::Record] return Record object if record created
    def self.upload_from_ftp(args)
      raise ArgumentError, "record[:name] is blank" if args[:record][:name].blank?
      raise ArgumentError, "ftp[:server] is blank" if args[:ftp][:server].blank?
      raise ArgumentError, "ftp[:file_path] is blank" if args[:ftp][:file_path].blank?      
      params = {
        record: args[:record],
        source: { 
          type: 'ftp',
          parameters: { 
            host: args[:ftp][:server],
            file: args[:ftp][:file_path],
            username: args[:ftp][:username] || "ftp",
            password: args[:ftp][:password] || ""
          }
        }
      }
      result = Eagleplatform.call_api(Methods::RECORD_UPLOAD_FROM_FTP, params).first[1]
      self.new("Record",*result.keys).new(*result.values)
    end
    
    
    ##
    # Create record and upload file form http server
    # @param [Hash] args the http options to upload video
    # @option args [String] :upload_url
    # @option args [Hash] :record
    #   name: 'record_name'
    #   description: 'record_description'
    # @example 
    #   record_params = { name: 'SomeRecord', description: 'Example Video' }
    #   Eagleplatform::Record.upload_form_http( record: record_params, upload_url: 'http://exapmle.com/video.mpg')
    # @return [Eagleplatform::Record] return Record object if record created
    def self.upload_from_http(args)
      raise ArgumentError, "record[:name] is blank" if args[:record][:name].blank?
      raise ArgumentError, "upload_url is blank" if args[:upload_url].blank?
      params = {
        record: args[:record],
        source: {
          type: 'http',
          parameters: { url: args[:upload_url] }
        }
      }
      result = Eagleplatform.call_api(Methods::RECORD_UPLOAD_FROM_HTTP, params).first[1]
      self.new("Record",*result.keys).new(*result.values)
    end
    
    ##
    # Update record on Eagleplatform
    # @example 
    #   record = Eagleplatform::Record.find(1234)
    #   record.description = 'Very fun record'
    #   record.update
    # @return [Eagleplatform::Record] if record successfully updated
    def update
      api_method = {method: Methods::RECORD_UPDATE[:method], 
                    path: Methods::RECORD_UPDATE[:path].gsub(':id',id.to_s)}
      params = {}
      params[:record] = self.to_hash
      params[:record].delete(:record_files)
      result = Eagleplatform.call_api(api_method, params).first[1]
      self.to_hash.diff(result.to_sym_hash).keys == [:updated_at] ? self : 'Something wrong'
    end
    
     
    ## 
    # Delete record from Eagleplaform
    # @example 
    #   record = Eagleplatform::Record.find(1234)
    #   record.delete
    # @return [String] 'ok' if record deleted successfully
    def delete
      api_method = {method: Methods::RECORD_DELETE[:method], 
                    path: Methods::RECORD_DELETE[:path].gsub(':id',id.to_s)}        
      Eagleplatform.call_api(api_method) == "ok" ? "Record id: '#{self.id}', name:#{self.name} is deleted" : (raise "Can't delete record")   
    end
    
    ##
    # Get all records statistics
    #   Date format is - 'dd.mm.yyyy'
    # @option args [String] :date_from ('yesterday') yesterday date
    # @option args [String] :date_to ('today') today date
    # @option args [String] :uniq ('false') unique user statistics
    # @example 
    #   DATE_FROMAT: 'dd.mm.yyyy'
    #   Eagleplatform::Record.statistics(date_from: '1.5.2012', date_to: '25.5.2012', uniq: 'true')
    # @return [Eagleplatform::Record] return Record object if record created
    def self.statistics(args = {})
      params = {
        date_from: args[:date_from] || (Time.now - 1.day).strftime('%d.%m.%Y'),
        date_to: args[:date_to] || Time.now.strftime('%d.%m.%Y')
      }

      raise ArgumentError, "Wrong 'date_from' format. Must be 'dd.mm.yyyy'" unless DATE_FORMAT =~ params[:date_from] 
      raise ArgumentError, "Wrong 'date_to' format. Must be 'dd.mm.yyyy'" unless DATE_FORMAT =~ params[:date_from]       
      raise ArgumentError, "date_from: #{params[:date_from]} > date_to: #{params[:date_from]}" \
        if params[:date_from].to_date > params[:date_to].to_date 

      params[:uniq] = 'true' if args[:uniq] == true  
      result = Eagleplatform.call_api(Methods::RECORDS_GET_STATISTICS, params).first[1]
    end
  
    
    ##
    # Get current record statistics
    #   Date format is - 'dd.mm.yyyy'
    # @param [Hash] args the statistics options
    # @option args [String] :date_from ('yesterday') yesterday date
    # @option args [String] :date_to ('today') today date
    # @option args [String] :uniq ('false') unique user statistics 
    # @example 
    #   record = Eagleplatform::Record.find(12345)
    #   record.statistics(date_from: '1.5.2012', date_to: '25.5.2012')
    # @return [Eagleplatform::Record] return Record object if record created
    def statistics(args = {})
      raise "self.id is blank" if self.id.blank?
      params = {
        date_from: args[:date_from] || (Time.now - 1.day).strftime('%d.%m.%Y'),
        date_to: args[:date_to] || Time.now.strftime('%d.%m.%Y')
      }
      params[:uniq] = 'true' if args[:uniq] == true  
      
      raise ArgumentError, "Wrong 'date_from' format. Must be 'dd.mm.yyyy'" unless DATE_FORMAT =~ params[:date_from] 
      raise ArgumentError, "Wrong 'date_to' format. Must be 'dd.mm.yyyy'" unless DATE_FORMAT =~ params[:date_from]
      raise ArgumentError, "date_from: #{params[:date_from]} > date_to: #{params[:date_from]}" \
        if params[:date_from].to_date > params[:date_to].to_date
      
      api_method = {method: Methods::RECORD_GET_STATISTICS[:method], 
                    path: Methods::RECORD_GET_STATISTICS[:path].gsub(':id',id.to_s)}
      result = Eagleplatform.call_api(api_method, params).first[1]
    end
  end
  
  # Translations
  class Translation < EagleplatformObject
    def self.find(id)
       raise ArgumentError, "id must be numeric" unless id.is_a? Numeric
       api_method = {method: Methods::RECORD_GET_INFO[:method], 
                     path: Methods::RECORD_GET_INFO[:path].gsub(':id',id.to_s)}

       result = Eagleplatform.call_api(api_method).first[1]      
       self.new("Record",*result.keys).new(*result.values)
     end

     def self.upload_from_ftp(args)
       raise ArgumentError, "record[:name] is blank" if args[:record][:name].blank?
       raise ArgumentError, "ftp[:server] is blank" if args[:ftp][:server].blank?
       raise ArgumentError, "ftp[:file_path] is blank" if args[:ftp][:file_path].blank?      
       params = {
         record: args[:record],
         source: { 
           type: 'ftp',
           parameters: { 
             host: args[:ftp][:server],
             file: args[:ftp][:file_path],
             username: args[:ftp][:username] || "ftp",
             password: args[:ftp][:password] || ""
           }
         }
       }
       result = Eagleplatform.call_api(Methods::RECORD_UPLOAD_FROM_FTP, params).first[1]
       self.new("Record",*result.keys).new(*result.values)
     end

     def self.upload_from_http(args)
       raise ArgumentError, "record[:name] is blank" if args[:record][:name].blank?
       raise ArgumentError, "upload_url is blank" if args[:upload_url].blank?
       params = {
         record: args[:record],
         source: {
           type: 'http',
           parameters: { url: args[:upload_url] }
         }
       }
       result = Eagleplatform.call_api(Methods::RECORD_UPLOAD_FROM_HTTP, params).first[1]
       self.new("Record",*result.keys).new(*result.values)
     end

     def update
       api_method = {method: Methods::RECORD_UPDATE[:method], 
                     path: Methods::RECORD_UPDATE[:path].gsub(':id',id.to_s)}
       params = {}
       params[:record] = self.to_hash
       params[:record].delete(:record_files)
       result = Eagleplatform.call_api(api_method, params).first[1]
       self.to_hash.diff(result.to_sym_hash).keys == [:updated_at] ? self : 'Something wrong'  
    end
  end
  
  # Filters
  class Filter < EagleplatformObject
  end
  
  class << self
    # @api private
    def request(api_method, params = {})
        # Add other required params. 
        params['account'] = @@account || ( raise "You must set account" )
        params['auth_token'] = @@auth_token || ( raise "You must set auth_token" )
        raise "Wrong api_method param" if api_method[:method].blank? || api_method[:path].blank? 
        full_api_url = @@api_url.to_s+api_method[:path]
        
        # Check method name and render request
        if ['get','delete'].include? api_method[:method]
          req_code = ERB.new <<-EOF
            RestClient.<%=api_method[:method] %> "<%= full_api_url %>", :params => <%= params %>
          EOF
        elsif ['post','put'].include? api_method[:method]
          req_code = ERB.new <<-EOF
            RestClient.<%=api_method[:method] %> "<%= full_api_url %>", params
          EOF
        else
          # raise error if wrong method name 
          raise "Wrong http method name '#{api_method[:method]}'"
        end
         
        #puts req_code.result(binding)
        # Execute request
        eval req_code.result(binding)
    end
    
    # @api private
    def call_api(api_method, params = {})      
        response = call_api_raw(api_method, params)
        root = JSON.parse(response)
        
        #Check if there was an error
        unless root.empty?
          raise root['error'] if root['error'] 
          #    code = result.elements['code'].text
          #    message = result.elements['msg'].text
          #    bad_request = result.elements['your_request'].to_s
          #    raise FacebookError.new(code, message, bad_request)
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