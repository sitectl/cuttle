#!/opt/sensu/embedded/bin/ruby
#
# This handler creates and resolves remedy incidents, refreshing
# stale incident details every 30 minutes
#
# Copyright
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#
# Dependencies:
#
#   sensu-plugin >= 1.0.0
#   savon == 2.11.1
#

require 'sensu-handler'
require 'savon'

class Remedy < Sensu::Handler

  def get_wsdl
    @baseurl = settings['remedy']['urls']['baseurl']
    @wsdl_create = settings['remedy']['urls']['wsdl_create']
    @wsdl_query = settings['remedy']['urls']['wsdl_query']
    @wsdl_update = settings['remedy']['urls']['wsdl_update']
    @wsdlfiles = {
        'create' => "#@baseurl/#@wsdl_create",
        'query' => "#@baseurl/#@wsdl_query",
        'update' => "#@baseurl/#@wsdl_update",
    }
  end

  def get_soap
    @userName = settings['remedy']['userName']
    @password = settings['remedy']['password']

    @soap_header = {
        'AuthenticationInfo' => {
            'userName' => @userName,
            'password' => @password
        }}
  end

  def incident_name
    source = @event['check']['source'] || @event['client']['name']
    [source, @event['check']['name']].join('/')
  end

  def create_incident
    if not get_open_incidents
      puts "No incidents relate to #{incident_name}. Creates a new one."
      # no open incidents about the incident_name
      # create a new one
      client = Savon.client(
          wsdl: get_wsdl['create'],
          log: false,
          ssl_verify_mode: :none,
          soap_header: get_soap)

      severity_map = {
          '2' => '1',
          '1' => '2'}
      urgency_map = {
          '2' => '1-Critical',
          '1' => '3-Medium'}
      impact_map = {
          '2' => '1-Extensive/Widespread',
          '1' => '3-Moderate/Limited'}

      description = ['Blue Box Alert',
                     "SEV#{severity_map[@event['check']['status'].to_s]} -",
                     "#{@event['client']['name']}:",
                     "#{incident_name}"
                     ].join(' ')
      detailed_description = ['Blue Box Alert:',
                              "\"Severity\": #{severity_map[@event['check']['status'].to_s]},",
                              "\"Hostname\": #{@event['client']['name']},",
                              "\"Event Summary\": #{event_summary}"
                              ].join(' ')

      response = client.call(:create_operation, message: {
          'Status' => 'Assigned',
          'Description' => description,
          'Company' => 'China Bluemix',
          'Last_Name' => 'Bluemix',
          'First_Name' => 'Monitor',
          'z1D_Action' => 'CREATE',
          'Service_Type' => 'Infrastructure Event',
          'Detailed_Decription' => detailed_description,
          'Urgency' => urgency_map[@event['check']['status'].to_s],
          'Impact' =>  impact_map[@event['check']['status'].to_s],
          'Support_Tier' => 'Standard',
          'type' => 'alert ticket',
          'Uni_sendAttachment1' => 'No',
          'Uni_sendAttachment2' => 'No',
          'Uni_sendAttachment3' => 'No',
          'Uni_sendAttachment4' => 'No',
          'Uni_sendAttachment5' => 'No',
          'Uni_Service' => settings['remedy']['service'],
          'Reported_Source_OOTB_Required' => 'BMC Impact Manager Event',
          'Locale_Language' => 'en_US',
          'Reported_Source_Real' => 'bluebox_monitor'})

      puts "Successfully create a remedy incident: #{response.to_hash[:create_operation_response][:request_id]}"
    else
      puts "Already had incidents relating to #{incident_name}. No need to create a new one."
    end
  end

  def query_incident(query_msg)
    wsdl_file = settings['remedy']['wsdlQuery']

    client = Savon.client(
        wsdl: get_wsdl['query'],
        log: false,
        soap_header: get_soap)

    begin
      puts "Query the incidents with query_msg: #{query_msg}"
      response = client.call(:get_list_operation, message: query_msg)
      response.to_hash[:get_list_operation_response][:get_list_values] || nil
    rescue Exception => exp_msg
      puts "Query failed with message: #{exp_msg}"
      nil
    end

  end

  def update_incident(updated_hash)
    puts "Start to update incident: #{updated_hash}"

    client = Savon.client(
        wsdl: get_wsdl['update'],
        log: true,
        soap_header: get_soap)
    response = client.call(:set_operation_update, message: updated_hash)
    puts "Successfully update a remedy incident: #{response.to_hash[:set_operation_update_response][:request_id]}"
  end

  def resolve_incident
    incidents = get_open_incidents
    if incidents
      # actually only one incident may match the incident_name
      if incidents.is_a? Array
        incident = incidents[0]
      else
        incident = incidents
      end

      puts "Start to resolve incident #{incident[:incident_number]}"
      # set the status of the incident to Resolved
      #
      updated_hash = {'Status' => 'Closed',
                      'Resolution' => 'Auto-resolved by Sensu',
                      'Incident_Number' => incident[:incident_number],
                      'Locale_Language' => 'en_US',}
      update_incident(updated_hash)
      puts "Successfully resolve incident #{incident[:incident_number]}"
    else
      puts 'Did not find the incidents to be resolved.'
    end
  end

  def get_open_incidents
    status = ["'Status'=\"New\"", "'Status'=\"Assigned\"",
              "'Status'=\"In Progress\"", "'Status'=\"Pending\""].join(' OR ')
    description = "'Description' LIKE \"%#{incident_name}%\""
    qualification = "(#{status}) AND #{description}"
    query_msg = {'Qualification' => qualification,
                 'startRecord' => 0,
                 'maxLimit' => 100}
    query_incident(query_msg)
  end

  def handle
    begin
      timeout(10) do
        case @event['action']
          when 'create'
            create_incident
          when 'resolve'
            resolve_incident
        end
      end
    rescue Timeout::Error
      puts "remedy -- timed out while attempting to handle a incident --  #{incident_name}"
    end
  end

end
