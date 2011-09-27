require 'fileutils'
require 'test/unit'
require "#{File.expand_path(File.dirname(__FILE__))}/../lib/deposit.rb"

class DepositTest < Test::Unit::TestCase

  TEST_SERVICE_DOC = "http://localhost:8080/sd-uri"
  TEST_SWORD_UN = "sword"
  TEST_SWORD_PW = "sword"
  TEST_DEFAULT_COLLECTION = "http://localhost:8080/col-uri/default"

  TEST_FIXTURES_DIR = "#{File.expand_path(File.dirname(__FILE__))}/fixtures"
  TEST_OUTPUT_DIR = "#{File.expand_path(File.dirname(__FILE__))}/fixtures/test_outputs"

  # setup for test
  def setup
  end

  def config_me
    Deposit.configure do
      sword(:test) do
        name "Digital Access to Scholarship at Harvard"
        service_doc_url "http://bachman.hul.harvard.edu:9034/sword/servicedocument"
        username "ryan.waldron@gmail.com"
        password "rewrew"
        default_collection "http://bachman.hul.harvard.edu:9034/sword/deposit/1/2"
      end
    end
  end

  def test_configurator
    config_me
    assert Deposit.repositories[:test].class == Deposit::SwordClient
  end

  def test_connection
    config_me
    assert Deposit.repositories[:test].connection.is_a? Deposit::SwordClient::Connection
  end

  # test an atomentry can be made
  # find the created test object in the test_outputs directory
  def test_atomentry
    atom = Deposit::SwordClient::AtomEntry.new
    File.open("#{TEST_OUTPUT_DIR}/atom.xml", "w"){ |f| f << atom.xml}
    assert_not_nil atom
  end

  # test a multipart object can be made
  # find the created test object in the test_outputs directory
  def test_multipart
    atom = Deposit::SwordClient::AtomEntry.new
    multi = Deposit::SwordClient::MultiPart.new(atom, "#{TEST_FIXTURES_DIR}/example.zip")
    FileUtils.cp(multi.filepath,"#{TEST_OUTPUT_DIR}/multi.dat")    
    assert_not_nil multi
  end

  # test a simple post to the repo
  def test_post
    sword = Deposit::SwordClient.new(nil,@config)
    posted = sword.execute("post","collection",nil,"#{TEST_FIXTURES_DIR}/example.zip")
    assert_not_nil posted
  end

  # test sending data to a repo
'  def test_content_operations
    metadata = {"identifier" => "ID", "title" => "my great book", "author" => "the great author"}
    sword = SwordClient.new

    # send a new collection and get edit-IRI back
    posted = sword.execute("post","collection",TEST_DEFAULT_COLLECTION,"#{TEST_FIXTURES_DIR}/example.zip",metadata)
    assert_not_nil posted

    # send new atom entry to the repo
    newatom = sword.execute("put","edit",posted,metadata)
    assert_not_nil newatom

    # post more content to the container
    more = sword.execute("post","edit",posted,"#{TEST_FIXTURES_DIR}/sample.odt")
    assert_not_nil more

    # replace the container content
    replaced = sword.execute("put","edit-media",posted,"#{TEST_FIXTURES_DIR}/example.zip")
    assert_not_nil replaced

    # test deleting the content
    empty = sword.execute("delete","edit-media",posted)
    assert_not_nil empty

    # test deleting the container
    deleted = sword.execute("delete","edit",posted)
    assert_not_nil deleted

    # test it is not there any more
    gone = sword.execute("get","edit",posted)
    assert gone == ""

  end
'

end
