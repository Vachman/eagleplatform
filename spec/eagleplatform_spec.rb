require File.dirname(__FILE__) + '/../lib/eagleplatform.rb'

describe "Eaglepltaform" do
  it "methods list" do
    Eagleplatform::Methods.constants should_not be nil
  end
  
  describe  "setup" do
    it 'should raise ArgumentError if params < 2' do
      lambda { Eagleplatform.sutup }.should raise_error
    end
    
    it 'should raise ArgumenError "account is blank" if account is blank' do
      lambda { Eagleplatform.setup('','foo') }.should raise_error(ArgumentError, 'account is blank')
    end
    
    it 'should raise ArgumentError "auth_token is blank" if auth_token is blank' do
      lambda { Eagleplatform.setup('foo','') }.should raise_error(ArgumentError, 'auth_token is blank')
    end
  
    it 'should raise ArgumentError "server is blank" if serevr is blank ' do
      lambda { Eagleplatform.setup('foo','bar', '') }.should raise_error(ArgumentError, 'server is blank')
    end
    
    it "should slice! 'http://' from server if it present" do
      Eagleplatform.setup('foo','bar', 'http://www.example.com')
      Eagleplatform.module_eval('@@api_url.to_s').should == 'http://www.example.com'  
    end
  end 
  
  describe 'request' do
    it  'should raise ArgumentError without parameters' do
      lambda { Eagleplatform.request }.should raise_error(ArgumentError) 
    end
    
    it 'should raise error "You must set account" if @@account is nil' do
      Eagleplatform.module_eval('@@account = nil')
      lambda { Eagleplatform.request({method: 'put', path: '/root'})}.should raise_error('You must set account')
    end

    it 'should raise error "You must set auth_token" if @@account is nil' do
      Eagleplatform.module_eval("@@account = 'sa'; @@auth_token = nil")
      lambda { Eagleplatform.request({method: 'put', path: '/root'})}.should raise_error('You must set auth_token')
    end
    
    it 'should raise error if api_method[:method] or api_method[:path] is blank' do
       Eagleplatform.module_eval("@@account = 'foo'; @@auth_token = 'bar'")
       lambda { Eagleplatform.request({method: '', path: ''}) }.should raise_error("Wrong api_method param")
    end
    
    it "should raise error if api_method[:method] not one of  get, post, put, delete" do
       Eagleplatform.module_eval("@@account = 'foo'; @@auth_token = 'bar'")
       lambda { Eagleplatform.request({method: 'wrong_method', path: '/path'}) }.should raise_error("Wrong http method name 'wrong_method'")
    end
  end

  context 'Record' do
    describe "self.find" do
      it  'should raise ArgumentError without parameters' do
        lambda { Eagleplatform::Record.find }.should raise_error(ArgumentError) 
      end
      
      it "should raise ArgumentError 'id must be numeric' if id is not numeric" do
        lambda { Eagleplatform::Record.find('not_numeric') }.should raise_error(ArgumentError,"id must be numeric")
      end
      
     it "should return Record Object" do
      #  record = { record: { 
      #      id: 47030,
      #      name: "test",
      #      description: '',
      #      duration: 4307190,
      #      origin: "http://eagle.b25.servers.eaglecdn.com/20120517/4fb50297b0b6f.flv",
      #      origin_size: 115810695,
      #      is_processed: true,
      #      screenshot: "http://st1.eaglecdn.com/eagle/20120517/4fb50297b0b6f_362_640x360.jpg",
      #      view_count: 0,
      #      click_url: "http://ya.ru?47030",
      #      user_id: 26,
      #      recorded_at: '',
      #      updated_at: "2012-05-17T13:53:17+00:00",
      #      created_at: "2012-05-17T13:52:28+00:00"
      #    }
      #  }
      #  Eagleplatform.stub!(:call_api).and_return(record)
      #  Eagleplatform::Record.find(47030).should be_an_instance_of Eagleplatform::Record
      end 
    end
    
    describe "self.upload_from_ftp" do
      it "should raise ArgumentError if record[:name] is blank" do
         lambda { Eagleplatform::Record.upload_from_ftp( record: {name: ''})}.
          should raise_error(ArgumentError,"record[:name] is blank")
      end
      
      it "should raise ArgumentError if ftp[:server] is blank" do
        lambda { Eagleplatform::Record.upload_from_ftp( record: {name: 'foo'},
         ftp: { server: ''}) }.should raise_error(ArgumentError,"ftp[:server] is blank")
      end
      
      it "should raise ArgumentError if ftp[:file_path] is blank" do
        lambda { Eagleplatform::Record.upload_from_ftp( record: {name: 'foo'},
          ftp: { server: 'bar', file_path: ''}) }.should raise_error(ArgumentError,"ftp[:file_path] is blank")
      end
    end
    
    describe "self.upload_from_http" do
      it "should raise ArgumentError if record[:name] is blank" do
         lambda { Eagleplatform::Record.upload_from_http( record: {name: ''})}.
          should raise_error(ArgumentError,"record[:name] is blank")
      end
      
      it "should raise ArgumentError if 'upload_url' is blank" do
        lambda { Eagleplatform::Record.upload_from_http( record: {name: 'foo'},
          upload_url: '')}.should raise_error(ArgumentError,"upload_url is blank")
      end
    end

    
    describe "update" do
      
    end

    describe "delete" do
      
    end

    describe "self.statistics" do
     it "should raise ArgumentError if wrong date format" do
       lambda { Eagleplatform::Record.statistics(date_from: '11,2.2001') }.should raise_error(ArgumentError)
     end
     
     it "should raise ArgumentError if date_from > date_to" do
        lambda { Eagleplatform::Record.statistics(date_from: '11.2.2012', date_to: '1.2.2010') }.should raise_error(ArgumentError)
      end  
    end

    describe "statistics" do
      it "should raise Error if self.id is blank" do
      end
    end
  end

end


