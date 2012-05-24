module  Eagleplatform
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
    # Update record on Eagleplatform
    # @param [Hash] record Hash of record fields
    # @option record [String] :id
    # @option record [String] :name
    # @option record [String] :description
    # @example 
    #   Eagleplatform::Record.update(id: 1234, name: 'Hello world', description: 'Heyy')
    # @return [Hash] Updated record 
    def self.update(args = {})
      raise ArgumentError, 'ID is blank' if args[:id].blank?  
      raise ArgumentError, 'id must be numeric' unless args[:id].is_a? Numeric
      params = {
        record: args
      }
      
      api_method = {method: Methods::RECORD_UPDATE[:method], 
                    path: Methods::RECORD_UPDATE[:path].gsub(':id',args[:id].to_s)}
      result = Eagleplatform.call_api(api_method, params).first[1].to_options
    end
    
    
    ## 
    # Delete record from Eagleplatform
    # @example 
    #   Eagleplatform::Record.delete(1234)
    # @return [String] 'Record id: #{id} is deleted' if record deleted successfully
    def self.delete(id)
      raise ArgumentError, 'id must be numeric' unless id.is_a? Numeric
      api_method = {method: Methods::RECORD_DELETE[:method], 
                    path: Methods::RECORD_DELETE[:path].gsub(':id',id.to_s)}        
      Eagleplatform.call_api(api_method) == "ok" ? "Record id: '#{id}' is deleted" : (raise "Can't delete record")
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
    # @return [String] 'Record id: #{id}, name:#{self.name} is deleted' if record deleted successfully
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
end