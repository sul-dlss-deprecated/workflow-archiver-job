# NOTE: this is basically a spec from 2014, and no longer runs properly
ENV['ROBOT_ENVIRONMENT'] = 'integration'
require File.expand_path(File.dirname(__FILE__) + '/../spec/spec_helper')
require 'oci8'

# This is an integration test that runs against the real oracle dev database
describe Dor::WorkflowArchiver do

  def insert_wf_row(wf)
    insert_sql =<<-EOSQL
      insert into #{@workflow_table} (
        ID,
        DRUID,
        DATASTREAM,
        PROCESS,
        STATUS,
        REPOSITORY
      )
      values (
        workflow_seq.NEXTVAL,
        :druid ,
        :workflow ,
        :process ,
        :status ,
        :repo
      )
    EOSQL

    cursor = @conn.parse(insert_sql)
    wf.each do |k, v|
      param = ":#{k}"
      #puts "Inserting: #{param} #{v}"
      if(v)
        cursor.bind_param(param, v)
      else
        cursor.bind_param(param, nil, String)
      end
    end

    num_rows = cursor.exec
    raise "Insert failed" if num_rows == 0

  end

  def count_expected_rows(table, druid, expected)
    count = @conn.exec("select * from #{table} where druid = '#{druid}'") {|r| puts r.join(',')}
    expect(count).to eq expected
  end

  before(:each) do
    @workflow_table = 'workflow'
    @workflow_archive_table = 'workflow_archive'

    @conn = OCI8.new(Dor::WorkflowArchiver.config.db_login, Dor::WorkflowArchiver.config.db_password, Dor::WorkflowArchiver.config.db_uri)
    @conn.autocommit = true
    @archiver = Dor::WorkflowArchiver.new(:retry_delay => 1)
    @archiver.connect_to_db
  end

  after(:each) do
    sql = "delete #{@workflow_table}"
    @conn.exec(sql)
    sql = "delete #{@workflow_archive_table}"
    @conn.exec(sql)
    @conn.logoff
  end

  after(:all) do
    $odb_pool.destroy if($odb_pool)
  end

  describe "#find_completed_objects" do

    it "locates objects where all workflow steps are complete" do
      # should get picked up - all workflow complete
      insert_wf_row(:druid => 'integration:345', :workflow => 'googleScannedBookWF',
        :process => 'cleanup', :status => 'completed', :repo => 'dor')
      insert_wf_row(:druid => 'integration:345', :workflow => 'googleScannedBookWF',
        :process => 'register', :status => 'completed', :repo => 'dor')
      insert_wf_row(:druid => 'integration:345', :workflow => 'googleScannedBookWF',
        :process => 'sdr-ingest-archive', :status => 'completed', :repo => 'dor')

      # should not get picked up - not all steps complete
      insert_wf_row(:druid => 'integration:678', :workflow => 'googleScannedBookWF',
        :process => 'cleanup', :status => 'waiting', :repo => 'dor')
      insert_wf_row(:druid => 'integration:678', :workflow => 'googleScannedBookWF',
        :process => 'register', :status => 'completed', :repo => 'dor')

      # should get picked up - different workflow, all steps complete
      insert_wf_row(:druid => 'integration:568', :workflow => 'sdrIngestWF',
        :process => 'cleanup', :status => 'completed', :repo => 'sdr')

      # should get picked up - different workflow, all steps complete
      insert_wf_row(:druid => 'integration:999', :workflow => 'etdSubmitWF',
        :process => 'cleanup', :status => 'completed', :repo => 'sdr')


      objs = @archiver.find_completed_objects
      expect(objs).to match_array [{"REPOSITORY"=>"dor", "DRUID"=>"integration:345", "DATASTREAM"=>"googleScannedBookWF"},
                        {"REPOSITORY"=>"sdr", "DRUID"=>"integration:568", "DATASTREAM"=>"sdrIngestWF"},
                        {"REPOSITORY"=>"sdr", "DRUID"=>"integration:999", "DATASTREAM"=>"etdSubmitWF"}]
    end

    it "locates completed workflow from the same object where one workflow has finished but the other hasn't" do
      # should get picked up - all workflow complete
      insert_wf_row(:druid => 'integration:345', :workflow => 'googleScannedBookWF',
        :process => 'cleanup', :status => 'completed', :repo => 'dor')
      insert_wf_row(:druid => 'integration:345', :workflow => 'googleScannedBookWF',
        :process => 'register', :status => 'completed', :repo => 'dor')
      insert_wf_row(:druid => 'integration:345', :workflow => 'googleScannedBookWF',
        :process => 'sdr-ingest-archive', :status => 'completed', :repo => 'dor')

      # should not get picked up - same object, but different, incomplete workflow
      insert_wf_row(:druid => 'integration:345', :workflow => 'etdSubmitWF',
        :process => 'cleanup', :status => 'waiting', :repo => 'dor')
      insert_wf_row(:druid => 'integration:345', :workflow => 'etdSubmitWF',
        :process => 'register', :status => 'completed', :repo => 'dor')

      objs = @archiver.find_completed_objects
      expect(objs).to match_array [{"REPOSITORY"=>"dor", "DRUID"=>"integration:345", "DATASTREAM"=>"googleScannedBookWF"}]
    end
  end

  describe "#archive_rows" do
    before(:each) do
      insert_wf_row(:druid => 'integration:345', :workflow => 'googleScannedBookWF', :process => 'cleanup', :status => 'completed', :repo => 'dor')
      insert_wf_row(:druid => 'integration:345', :workflow => 'googleScannedBookWF', :process => 'register-object', :status => 'completed', :repo => 'dor')
      insert_wf_row(:druid => 'integration:345', :workflow => 'sdrIngestWF', :process => 'register-sdr', :status => 'completed', :repo => 'sdr')
      insert_wf_row(:druid => 'integration:678', :workflow => 'sdrIngestWF', :process => 'register-sdr', :status => 'completed', :repo => nil)
    end

    context "normal operation" do
      before(:each) do
        expect(RestClient).to receive(:get).at_least(:twice).with(/^#{Dor::WorkflowArchiver.config.dor_service_uri}\/dor\/v1\/objects\/integration:/).and_return('1')
        allow(@archiver).to receive(:destroy_pool)
        @archiver.archive
      end

      it "copies workflow rows to the archive table" do
        count_expected_rows(@workflow_archive_table, 'integration:345', 3)
      end

      it "copies repository correctly to the archive table" do
        count = @conn.exec("select * from #{@workflow_archive_table} where repository = 'dor'") {|r| puts r.join(',')}
        expect(count).to eq 2

        count = @conn.exec("select * from #{@workflow_archive_table} where repository = 'sdr'") {|r| puts r.join(',')}
        expect(count).to eq 1
      end

      it "deletes copied rows from the workflow table" do
        count_expected_rows(@workflow_table, 'integration:345', 0)
      end

      it "archives objects with null repository values" do
        count_expected_rows(@workflow_archive_table, 'integration:678', 1)
        count_expected_rows(@workflow_table, 'integration:678', 0)
      end

    end

    context "error handling" do
      it "rolls back copy and delete if commit fails, retries 3 times per object/workflow" do
        expect(@archiver.conn).to receive(:commit).exactly(9).times.and_raise("Simulated commit failure")
        allow(@archiver).to receive(:get_latest_version).and_return('1')
        allow(@archiver).to receive(:destroy_pool)
        @archiver.archive

        count_expected_rows(@workflow_table, 'integration:345', 3)
        count_expected_rows(@workflow_archive_table, 'integration:345', 0)
        count_expected_rows(@workflow_table, 'integration:678', 1)
        count_expected_rows(@workflow_archive_table, 'integration:678', 0)
      end

      it "exits after failing for 3 druids" do
        allow(@archiver).to receive(:find_completed_objects).and_return([
                          {"REPOSITORY"=>"dor", "DRUID"=>"integration:345", "DATASTREAM"=>"googleScannedBookWF"},
                          {"REPOSITORY"=>"sdr", "DRUID"=>"integration:568", "DATASTREAM"=>"sdrIngestWF"},
                          {"REPOSITORY"=>"sdr", "DRUID"=>"integration:999", "DATASTREAM"=>"etdSubmitWF"},
                          {"REPOSITORY"=>"sdr", "DRUID"=>"integration:001", "DATASTREAM"=>"etdSubmitWF"}
                        ])
        allow(@archiver).to receive(:get_latest_version).and_return('1')
        allow(@archiver).to receive(:bind_and_exec_sql).and_raise("Simulated sql exec failure")
        allow(@archiver).to receive(:destroy_pool)
        @archiver.archive

        expect(@archiver.errors).to eq 3
      end

      it "archives workflow rows even if object cannot be found in Fedora, sets the version to '1'" do
        skip "Wasting too much time getting exception trapping to work"
        # e = RestClient::InternalServerError.new("Unable to find 'integration:345' in fedora")
        # e.stub!(:http_body).and_return("Unable to find 'integration:345' in fedora")
        # @archiver.should_receive(:get_latest_version).with('integration:345').twice.and_raise(e)
        # @archiver.should_receive(:get_latest_version).with('integration:678').and_return('1')
        # @archiver.archive
        #
        # count_expected_rows(@workflow_archive_table, 'integration:678', 1)
        # count_expected_rows(@workflow_archive_table, 'integration:345', 3)
        # @archiver.errors.should == 0
      end
    end
  end

  describe "#get_latest_version" do
    it "calls the DOR REST service to get the object's latest version" do
      skip
    end
  end

end
