module QBWC
  module Controller
    def self.included(base)
      base.class_eval do
        include WashOut::SOAP
        skip_before_filter :_parse_soap_parameters, :_authenticate_wsse, :_map_soap_parameters, :only => :qwc

        soap_action 'authenticate',
                    :args   => {:strUserName => :string, :strPassword => :string},
                    :return => {'tns:authenticateResult' => StringArray},
                    :response_tag => 'tns:authenticateResponse'

        soap_action 'sendRequestXML', :to => :send_request,
                    :args   => {:ticket => :string, :strHCPResponse => :string, :strCompanyFilename => :string, :qbXMLCountry => :string, :qbXMLMajorVers => :string, :qbXMLMinorVers => :string},
                    :return => {'tns:sendRequestXMLResult' => :string},
                    :response_tag => 'tns:sendRequestXMLResponse'

        soap_action 'receiveResponseXML', :to => :receive_response,
                    :args   => {:ticket => :string, :respone => :string, :hresult => :string, :message => :string},
                    :return => {'tns:receiveResponseXMLResult' => :integer},
                    :response_tag => 'tns:receiveResponseXMLResponse'

        soap_action 'closeConnection', :to => :close_connection,
                    :args   => {:ticket => :string},
                    :return => {'tns:closeConnectionResult' => :string},
                    :response_tag => 'tns:closeConnectionResponse'

        soap_action 'connectionError', :to => :connection_error,
                    :args   => {:ticket => :string, :hresult => :string, :message => :string},
                    :return => {'tns:connectionErrorResult' => :string},
                    :response_tag => 'tns:connectionErrorResponse'

        soap_action 'getLastError', :to => :get_last_error,
                    :args   => {:ticket => :string},
                    :return => {'tns:getLastErrorResult' => :string},
                    :response_tag => 'tns:getLastErrorResponse'
      end
    end

    def qwc
      qwc = <<QWC
<QBWCXML>
   <AppName>#{Rails.application.class.parent_name} #{Rails.env}</AppName>
   <AppID></AppID>
   <AppURL>#{url_for(:controller => self.controller_path, :action => 'action', :protocol => 'https://')}</AppURL>
   <AppDescription>Quickbooks integration</AppDescription>
   <AppSupport>#{QBWC.support_site_url || root_url(:protocol => 'https://')}</AppSupport>
   <UserName>qbint</UserName>
   <UserName>#{QBWC.username}</UserName>
   <OwnerID>#{QBWC.owner_id}</OwnerID>
   <FileID>{90A44FB5-33D9-4815-AC85-BC87A7E7D1EB}</FileID>
   <QBType>QBFS</QBType>
   <Style>Document</Style>
   <Scheduler>
      <RunEveryNMinutes>#{QBWC.minutes_to_run}</RunEveryNMinutes>
   </Scheduler>
</QBWCXML>
QWC
      send_data qwc, :filename => 'servpac.qwc'
    end

    class StringArray < WashOut::Type
      map "tns:string" => [:string]
    end

    def authenticate
      user = authenticate_user(params[:strUserName], params[:strPassword])
      if user
        company = current_company(user)
        ticket = Time.now.to_i.to_s if company
        company ||= 'none'
      end
      render :soap => {"tns:authenticateResult" => {"tns:string" => [ticket || '', company || 'nvu']}}
    end

    def send_request
      render :soap => {'tns:sendRequestXMLResult' => ''}
    end

    def receive_response
      render :soap => {'tns:receiveResponseXMLResult' => 0}
    end

    def close_connection
      render :soap => {'tns:closeConnectionResult' => 'OK'}
    end

    def connection_error
      render :soap => {'tns:connectionErrorResult' => 'done'}
    end

    def get_last_error
      render :soap => {'tns:getLastErrorResult' => 'Unknown error'}
    end

    protected
    def authenticate_user(username, password)
      username if username == QBWC.username && password == QBWC.password
    end
    def current_company(user)
      nil
    end
  end
end