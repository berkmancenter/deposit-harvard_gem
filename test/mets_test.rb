require 'fileutils'
require 'test/unit'
require "#{File.expand_path(File.dirname(__FILE__))}/../lib/deposit.rb"

class MetsTest < Test::Unit::TestCase

  TEST_FIXTURES_DIR = "#{File.expand_path(File.dirname(__FILE__))}/fixtures"
  TEST_OUTPUT_DIR = "#{File.expand_path(File.dirname(__FILE__))}/fixtures/test_outputs"

  # setup for test
  def setup
  end

  def test_initialize
    assert Deposit::Packagers::Mets.new.class == Deposit::Packagers::Mets
  end

  def test_default_metadata_filename
    m = Deposit::Packagers::Mets.new
    assert m.sac_metadata_filename == "mets.xml"
  end

  def test_normal_multiples_with_wrong_type
    ['sac_creators', 'sac_provenances', 'sac_rights', 'sac_subjects'].each do |sac_attr|
      assert_raise(ArgumentError) {
        m = Deposit::Packagers::Mets.new sac_attr => 'Waldo'
      }
    end
  end

  def test_normal_multiples_initialize
    values = ["one", "other"]
    ['sac_creators', 'sac_provenances', :sac_rights, :sac_subjects].each do |sac_attr|
      m = Deposit::Packagers::Mets.new sac_attr => values
      assert m.send(sac_attr.to_sym).is_a? Array
      assert m.send(sac_attr.to_sym) == values
    end
  end

  def test_normal_singles_initialize
    value = "foodlenoodle"
    [ 'sac_root_in', 'sac_dir_in', 'sac_root_out', 'sac_file_out',
      'sac_metadata_filename', 'sac_type', 'sac_title', 'sac_abstract',
      'sac_identifier', 'sac_date_available', 'sac_status_statement',
      'sac_copyright_holder', 'sac_custodian', 'sac_citation', 'sac_language'].each do |sac_attr|
      m = Deposit::Packagers::Mets.new sac_attr => value
      assert m.send(sac_attr.to_sym) == value
    end
  end

  def test_add_files
    m = Deposit::Packagers::Mets.new
    3.times do |i|
      m.add_file File.join(TEST_FIXTURES_DIR, "pdf#{i+1}.pdf"), "application/pdf"
    end
    assert m.sac_files.is_a? Array
    assert m.sac_files.size == 3
    assert m.sac_filecount == 3
    puts m.sac_files
  end
end
