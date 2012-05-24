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

  # @api private
  # Class provides methods for all Eagleplatform Objects
  class EagleplatformObject < Struct    
    # @return [Hash] convert Struct to Hash
    def to_hash
      Hash[self.each_pair.to_a]
    end
  end



  # Records
  class Record < EagleplatformObject.new(:id, :name, :description, :duration, :origin, 
                                          :origin_size, :updated_at, :is_processed, :screenshot,
                                          :view_count, :click_url, :user_id, :recorded_at,
                                          :created_at, :tags, :record_files)
    ##
    # Find Record by ID
    # @param [Numeric] id ID of record
    # @example 
    #   Eagleplatform::Record.find(45632)
    # @return [Eagleplaform::Record] if record present
    # # @raise [ArgumentError] id must be numeric
    def self.find(id)
      raise ArgumentError, 'id must be numeric' unless id.is_a? Numeric
      api_method = {method: Methods::RECORD_GET_INFO[:method], 
                    path: Methods::RECORD_GET_INFO[:path].gsub(':id',id.to_s)}
      result = Eagleplatform.call_api(api_method).first[1].to_options  
      rec = self.new
      rec.each_pair { |k,v| rec[k] = result[k] }    
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
      result = Eagleplatform.call_api(Methods::RECORD_UPLOAD_FROM_FTP, params).first[1].to_options
      rec = self.new
      rec.each_pair { |k,v| rec[k] = result[k]}
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
      result = Eagleplatform.call_api(Methods::RECORD_UPLOAD_FROM_HTTP, params).first[1].to_options
      rec = self.new
      rec.each_pair { |k,v| rec[k] = result[k]}
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
      result = Eagleplatform.call_api(api_method, params).first[1].to_options
      self.to_hash.diff(result).keys.include?(:updated_at) ? self : 'Something wrong'
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
    # @return [Array] return records statistics
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
    # @return [Array] return record statistics
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
  class Translation < EagleplatformObject.new(:id, :name, :description, :status, :announce, :created_at,
                                              :updated_at, :starts_at, :ad_template_id, :product_code,
                                              :age_restrictions_type, :country_access_template_id,
                                              :player_template_id, :site_access_template_id, :stream_name,
                                              :announce, :account_id, :user_id)
                                              
    undef user_id=
    undef account_id=
    undef status=
    undef created_at=
    undef updated_at=
    undef starts_at=

    ##
    # Get list of translations
    # @param [Numeric] per_page translations number per page
    # @param [Numeric] page translations page
    # @example
    #   translations = Eagleplatform::Translation.list
    #   
    #   #Get translations page=2, per_page=20
    #   translations = Eagleplatform::Translation.list(20,2) 
    # @return [Array] Array of Translations objects
    def self.list(per_page = 50, page = 1)
      params = {
        per_page: per_page.to_s,
        page: page.to_s
      }
      result = Eagleplatform.call_api(Methods::TRANSLATIONS_GET_LIST, params).to_options
      translations = []
      result[:translations].each do |translation|
        t = self.new
        t.each_pair { |k,v| t[k] = translation[k.to_s]}
        translations.push(t)
      end
      if result[:total_pages] > 1
        puts "Translations per_page: #{per_page}"
        puts "Current page: #{result[:current_page]}"
        puts "Total pages: #{result[:total_pages]}"
        puts "Total entries: #{result[:total_entries]}"        
      end
      translations
    end
    
    ##
    # Find Translation by ID
    # @param [Numeric] id ID of translation
    # @example 
    #   Eagleplatform::Translation.find(45632)
    # @return [Eagleplaform::Translation] if translation present
    # @raise [ArgumentError] id must be numeric
    def self.find(id)
       raise ArgumentError, "id must be numeric" unless id.is_a? Numeric
       api_method = {method: Methods::TRANSLATION_GET_INFO[:method], 
                     path: Methods::TRANSLATION_GET_INFO[:path].gsub(':id',id.to_s)}

       result = Eagleplatform.call_api(api_method).first[1].to_options      
       trans = self.new
       trans.each_pair { |k,v| trans[k] = result[k] }
    end

    ##
    # Update translation on Eagleplatform
    # @example 
    #   t = Eagleplatform::Translation.find(1234)
    #   t.description = 'Mega stream'
    #   t.update
    # @return [Eagleplatform::Translation] if record successfully updated
    def update
       api_method = {method: Methods::TRANSLATION_UPDATE[:method], 
                     path: Methods::TRANSLATION_UPDATE[:path].gsub(':id',id.to_s)}
       params = {}
       translation = self.to_hash
       translation.delete(:user_id)
       translation.delete(:account_id)
       translation.delete(:status)
       translation.delete(:created_at)
       translation.delete(:updated_at)
       translation.delete(:starts_at)
       
       params[:translation] = translation
       result = Eagleplatform.call_api(api_method, params).first[1].to_options
       translation.diff(result).keys.include?(:updated_at) ? self : 'Something wrong'  
    end

    ## 
    # Switch off translation from Eagleplaform
    # @example 
    #   t = Eagleplatform::translation.find(1234)
    #   t.delete
    # @return [String] 'ok' if translation switched off successfully
    def delete
      api_method = {method: Methods::TRANSLATION_DELETE[:method], 
                    path: Methods::TRANSLATION_DELETE[:path].gsub(':id',id.to_s)}        
      Eagleplatform.call_api(api_method) == "ok" ? "Translation id: '#{self.id}', name:#{self.name} is switched off" : (raise "Can't delete record")
    end
    
    ##
    # Get current translation statistics
    #   Date format is - 'dd.mm.yyyy'
    # @param [Hash] args the statistics options
    # @option args [String] :date_from ('yesterday') yesterday date
    # @option args [String] :date_to ('today') today date
    # @example 
    #   t = Eagleplatform::Translation.find(12345)
    #   t.statistics(date_from: '1.5.2012', date_to: '25.5.2012')
    # @return [Array] return translation statistics
    def statistics(args = {})
      raise "self.id is blank" if self.id.blank?
      params = {
        date_from: args[:date_from] || (Time.now - 1.day).strftime('%d.%m.%Y'),
        date_to: args[:date_to] || Time.now.strftime('%d.%m.%Y')
      }

      raise ArgumentError, "Wrong 'date_from' format. Must be 'dd.mm.yyyy'" unless DATE_FORMAT =~ params[:date_from] 
      raise ArgumentError, "Wrong 'date_to' format. Must be 'dd.mm.yyyy'" unless DATE_FORMAT =~ params[:date_from]
      raise ArgumentError, "date_from: #{params[:date_from]} > date_to: #{params[:date_from]}" if params[:date_from].to_date > params[:date_to].to_date

      api_method = {method: Methods::TRANSLATION_GET_STATISTICS[:method], 
                    path: Methods::TRANSLATION_GET_STATISTICS[:path].gsub(':id',id.to_s)}
      result = Eagleplatform.call_api(api_method, params).first[1]
    end    
  end


  # Filters
  # @example
  #   # Simple request:
  #   f = Eagleplatform::Filter.find(54321) 
  #   
  #   # With custom records count per page: 
  #   f = Eagleplatform::Filter.find(54321, 100 ) 
  #   
  #   # With custom records count per page and custom page number: 
  #   f = Eagleplatform::Filter.find(54321, 50, 3 )
  #
  #   f.current_page 
  #   => '3'
  #   f.records.count 
  #   => '50'
  #
  #   f.next_page
  #   => '+ 50 records loaded'
  #
  #    f.current_page 
  #   => '4'
  #   # f.records.count 
  #   => '100'
  # 
  #   # List of records name with create date :
  #   f.records.each { |rec| puts "name: #{rec.name} created_at: #{rec.created_at}" }
  class Filter     
    attr_reader :id, :name, :total_entries, :current_page, :total_pages, :per_page
    
    # List of loaded records
    # @return [Array] List of loaded records
    def records
      @records
    end
   
    # @api private
    def initialize(result)
      @id = result['id']
      @name  = result['name']
      @total_entries = result['total_entries']
      @total_pages = result['total_pages']
      @current_page = result['current_page']
      
      @records = []
      result['records'].each do |record|
        rec = Eagleplatform::Record.new
        rec.each_pair { |k,v| rec[k] = record[k.to_s]}
        @records.push(rec) 
      end
      
      notice = <<-EOF
      #####################################################  
        ATTENTION - There is more then one page
        method 'next_page' load more records
        See: total_pages, current_page and total_enteries
      #####################################################
      EOF
      puts notice if @total_pages > 1
    end

    ##
    # Load records form filter next page 
    # @example
    #   f = Eagleplatform::Filter.find(54321)
    #   f.next_page
    # @return [String] Count of loaded records
    def next_page
      if @current_page < @total_pages
        begin
          @current_page += 1
          params = {
            page: @current_page.to_s,
            per_page: @per_page.to_s
          }
          api_method = {method: Methods::FILTER_GET_RECORDS[:method], 
                        path: Methods::FILTER_GET_RECORDS[:path].gsub(':id', self.id.to_s)}
          result = Eagleplatform.call_api(api_method, params) 
          result['records'].each do |record|
            rec = Eagleplatform::Record.new
            rec.each_pair { |k,v| rec[k] = record[k.to_s]}
            @records.push(rec) 
          end
          puts "+#{result['records'].count} records loaded."            
        rescue Exception => e
          @current_page -= 1
          puts e
        end
      elsif @current_page == @total_pages
        puts "@current_page == @total_pages. Nothing to load"
      end
    end
  
    ##
    # Get records form filter
    # @param [Numeric] id ID of filter
    # @param [Numeric] per_page Records per page
    # @param [Numeric] page Records page number
    # @example
    #   # Simple request:
    #   f = Eagleplatform::Filter.find(54321) 
    #   
    #   # With custom records count per page: 
    #   f = Eagleplatform::Filter.find(54321, 100 ) 
    #   
    #   # With custom records count per page and custom page number: 
    #   f = Eagleplatform::Filter.find(54321, 50, 3 )
    # @return [Eagleplatform::Filter] if filetr present
    # @raise [ArgumentError] id must be numeric
    def self.find(id, per_page = 50, page = 1)
      raise 'per_page must be betwen 1 to 1000' unless per_page.between?(1,1000)
      raise ArgumentError, 'id must be numeric' unless id.is_a? Numeric
      params = {
        page: page.to_s,
        per_page: per_page.to_s
      }
      api_method = {method: Methods::FILTER_GET_RECORDS[:method], 
                    path: Methods::FILTER_GET_RECORDS[:path].gsub(':id',id.to_s)}
      result = Eagleplatform.call_api(api_method, params)    
      filter = self.new(result)
      filter.instance_eval("@per_page = #{per_page}")
      filter
    end
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