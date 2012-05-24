module  Eagleplatform
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
end