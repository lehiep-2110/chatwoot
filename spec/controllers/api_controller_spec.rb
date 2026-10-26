require 'rails_helper'

RSpec.describe 'API Base', type: :request do
  describe 'request to api base url' do
    it 'returns api version' do
      get '/api/'
      expect(response).to have_http_status(:success)
      expect(response.body).to include(Chatwoot.config[:version])
      expect(response.body).to include('queue_services')
      expect(response.body).to include('data_services')
      expect(response.parsed_body['data_services']).to eq('ok')
    end

    it 'checks a database connection that has not been activated yet' do
      connection = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter, active?: false, select_value: 1)
      allow(ActiveRecord::Base).to receive(:connection).and_return(connection)

      get '/api/'

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['data_services']).to eq('ok')
    end

    [ActiveRecord::ConnectionNotEstablished, ActiveRecord::StatementInvalid].each do |error_class|
      it "reports failing data services for #{error_class.name}" do
        connection = ActiveRecord::Base.connection
        allow(connection).to receive(:select_value).and_call_original
        allow(connection).to receive(:select_value).with('SELECT 1').and_raise(error_class)

        get '/api/'

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['data_services']).to eq('failing')
      end
    end
  end
end
