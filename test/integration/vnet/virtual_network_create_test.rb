#-------------------------------------------------------------------------
# Copyright 2013 Microsoft Open Technologies, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#--------------------------------------------------------------------------
require 'integration/test_helper'
require 'support/virtual_network_helper'

describe Azure::VirtualNetworkManagement::VirtualNetwork do
  subject { Azure::VirtualNetworkManagementService.new }
  let(:in_vnet_name) { 'newvnet' }
  let(:geo_location) { 'East US' }
  let(:in_address_space) { ['172.16.0.0/12'] }
  let(:invalid_address_space) { ['', ''] }
  let(:invalid_cidr_address_space) { ['10.0.0.0'] }
  let(:created_state) { 'Created' }
  let(:xml_err_msg) { 'XML Schema validation error in network configuration' }
  let(:input_options) {
    {
        subnet: [{name: 'Subnet-1', ip_address: '172.16.0.0', cidr: 12}],
        dns: [{name: 'DNS', ip_address: '1.2.3.4'}]
    }
  }

  describe 'virtual network' do
    before do
      Azure::Loggerx.expects(:puts).returns(nil).at_least(0)
      VCR.insert_cassette "vnet/#{name}"
    end

    after do
      VCR.eject_cassette
    end

    it 'should be created with valid params' do
      subject.set_network_configuration(in_vnet_name,
                                        geo_location,
                                        in_address_space,
                                        input_options)

      VirtualNetworkHelper.check_config(subject.list_virtual_networks,
                                        in_vnet_name, geo_location,
                                        created_state, in_address_space,
                                        input_options)
    end

    it 'should update virtual network with valid params' do
      update_address_space = ['10.0.0.0/8']
      update_options = {
          subnet: [{name: 'Subnet-1', ip_address: '10.0.0.0', cidr: 16}],
          dns: [{name: 'DNS', ip_address: '1.2.3.4'}]
      }

      subject.set_network_configuration(in_vnet_name, geo_location,
                                        update_address_space,
                                        update_options)
      VirtualNetworkHelper.check_config(subject.list_virtual_networks,
                                        in_vnet_name, geo_location,
                                        created_state, update_address_space,
                                        update_options)

    end

    it 'should throw an exception for invalid subnet' do
      options = {
          subnet: [{name: 'Subnet-1', ip_address: '10.0.0.0/8', cidr: 12}],
          dns: [{name: 'demodns', ip_address: '2.3.4.5'}]
      }

      exception = assert_raises(RuntimeError) do
        subject.set_network_configuration(in_vnet_name,
                                          geo_location,
                                          in_address_space,
                                          options)
      end

      assert_match('IP address is not valid', exception.message)
    end

    it 'should throw an exception for invalid options' do
      exception = assert_raises(RuntimeError) do
        subject.set_network_configuration(in_vnet_name,
                                          geo_location,
                                          invalid_address_space,
                                          input_options)
      end
      assert_match(xml_err_msg, exception.message)
    end

    it 'should throw an exception for invalid cidr address' do
      exception = assert_raises(RuntimeError) do
        subject.set_network_configuration(in_vnet_name,
                                          geo_location,
                                          invalid_cidr_address_space,
                                          input_options)
      end
      assert_match("Cidr is invalid for IP #{invalid_cidr_address_space[0]}", exception.message)
    end
  end
end
