module  Eagleplatform
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
end