# METS packager (largely extracted from the PackagerMetsSwap class in http://php.swordapp.org/ )
# Given appropriate files and metadata about them, will construct the mets.xml file and package
# up both files and mets.xml into a zip file suitable for uploading to a repository capable of
# accepting METS-packaged inputs (like SWORD).

class Deposit::Packagers::Mets

  # Takes a hash of options, which can include some or all of these:

  # sac_root_in - The root location of the files (without final directory)
  # sac_dir_in - The directory to zip up in the sac_root_in directory
  # sac_root_out - The location to write the package out to
  # sac_file_out - The filename to save the package as
  # sac_metadata_filename - The name of the metadata file (defaults to "mets.xml")
  # sac_type - The type (e.g. ScholarlyWork)
  # sac_title - The title of the item
  # sac_abstract - The abstract of the item
  # sac_creators - Creators
  # sac_subjects - Subjects
  # sac_identifier - Identifier
  # sac_date_available - Date made available
  # sac_status_statement - Status
  # sac_copyright_holder - Copyright holder
  # sac_custodian - Custodian
  # sac_citation - Bibliographic citation
  # sac_language - Language
  # sac_files - File names
  # sac_mimetypes - MIME type
  # sac_provenances - Provenances
  # sac_rights - Rights
  # sac_filecount = Number of files added

  attr_accessor :sac_root_in, :sac_dir_in, :sac_root_out, :sac_file_out, :sac_metadata_filename,
                :sac_type, :sac_title, :sac_abstract, :sac_identifier,
                :sac_date_available, :sac_status_statement, :sac_copyright_holder, :sac_custodian,
                :sac_citation, :sac_language

  def initialize(params = {})

    # Set defaults
    @params = params.merge( "sac_metadata_filename" => "mets.xml" ) {|key, oldval, newval| oldval}

    single_elements = [ 'sac_root_in', 'sac_dir_in', 'sac_root_out', 'sac_file_out', 'sac_metadata_filename',
      'sac_type', 'sac_title', 'sac_abstract', 'sac_identifier',
      'sac_date_available', 'sac_statusstatement', 'sac_copyright_holder', 'sac_custodian',
      'sac_citation', 'sac_language']

    multiple_elements = [ 'sac_creators', 'sac_subjects', 'sac_files', 'sac_mimetypes', 'sac_provenances', 'sac_rights']

    known_elements = single_elements + multiple_elements

    single_elements.each do |param|
      # Yeah, we'll make us some ghetto HashWithIndifferentAccess here
      if val = (params[param] || params[param.to_sym])
        puts "Calling #{param}= as to_sym, with #{val} as the value"
        # e.g., sac_abstract = params['sac_abstract']
        self.send("#{param}=".to_sym, val)
      end
    end

    @sac_filecount = 0

    # Initialize the multiple-holding elements
    @sac_creators = []
    @sac_subjects = []
    @sac_files = []
    @sac_mimetypes = []
    @sac_provenances = []
    @sac_rights = []
  end

  def add_creator(sac_creator)
    @sac_creators << sac_creator
  end

  def add_file(sac_thefile, sac_themimetype)
    @sac_files << sac_thefile
    @sac_mimetypes << sac_themimetype
    @sac_filecount += 1
  end

  def add_subject(sac_subject)
    @sac_subjects << sac_subject
  end

  def add_provenance(sac_provenance)
    @sac_provenances << sac_provenance
  end

  def add_rights(sac_right)
    @sac_rights << sac_right
  end

  def metadata_filename
    mfn = [@sac_root_in, @sac_dir_in, @sac_metadata_filename].compact.join('/')
    puts("metadata_filename: #{mfn}")
    "/tmp/foggy.xml"
  end

  def mets_header
    hdr = "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\" ?>\n" +
          "<mets ID=\"sort-mets_mets\" OBJID=\"sword-mets\" LABEL=\"DSpace SWORD Item\"\n" +
          "\tPROFILE=\"DSpace METS SIP Profile 1.0\" xmlns=\"http://www.loc.gov/METS/\"\n" +
          "\txmlns:xlink=\"http://www.w3.org/1999/xlink\"\n"+
          "\txmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n" +
          "\txsi:schemaLocation=\"http://www.loc.gov/METS/ http://www.loc.gov/standards/mets/mets.xsd\">\n" +
          "\t<metsHdr CREATEDATE=\"2007-09-01T00:00:00\">\n" +
          "\t\t<agent ROLE=\"CUSTODIAN\" TYPE=\"ORGANIZATION\">\n"
    hdr << "\t\t\t<name>#{(@sac_custodian || 'Unknown')}</name>\n"
    hdr << "\t\t</agent>\n"
    hdr << "\t</metsHdr>\n"
  end

  def mets_footer
    "</mets>\n"
  end

  def value_string(value)
    "<epdcx:valueString>#{value}</epdcx:valueString>\n"
  end

  def statement(property_uri, value)
    "<epdcx:statement epdcx:propertyURI=\"#{property_uri}\">\n#{value}</epdcx:statement>\n"
  end

  def value_string_ses_uri(ses_uri, value)
    "<epdcx:valueString epdcx:sesURI=\"#{ses_uri}\">#{value}</epdcx:valueString>\n"
  end

  def statement_value_uri(property_uri, value)
    "<epdcx:statement epdcx:propertyURI=\"#{property_uri}\" "+
    "epdcx:valueURI=\"#{value}\" />\n"
  end

  def statement_ves_uri(property_uri, ves_uri, value)
    "<epdcx:statement epdcx:propertyURI=\"#{property_uri}\" "+
    "epdcx:vesURI=\"#{ves_uri}\">\n#{value}</epdcx:statement>\n"
  end

  def statement_ves_uri_value_uri(property_uri, ves_uri, value)
    "<epdcx:statement epdcx:propertyURI=\"#{property_uri}\" " +
    "epdcx:vesURI=\"#{ves_uri}\" " +
    "epdcx:valueURI=\"#{value}\" />\n"
  end

  # Write the metadata (mets) file
  def create_mets_file
    File.open(metadata_filename, 'w') do |f|
      f.write(mets_header)
      f.write(dmd_sec)
      f.write(file_group)
      f.write(struct_map)
      f.write(mets_footer)
    end
  end

  require 'zip/zip'

  def archive_filename
    afn = [@sac_root_out, @sac_file_out].compact.join('/')
    puts("archive_filename: #{afn}")
    "/tmp/fluffy.zip"
  end

  def create_archive
    create_mets_file

    # Create the zipped package
    Zip::ZipFile.open(archive_filename, Zip::ZipFile::CREATE) do |zip|
      zip.add('mets.xml', metadata_filename)
      @sac_files.each do |sac_file|
        zip.add(File.basename(sac_file), [@sac_root_in, @sac_dir_in, sac_file].compact.reject{|a| a.empty?}.join('/'))
      end
    end
  end

  def dmd_sec_header
    "\t<dmdSec ID=\"sword-mets-dmd-1\" GROUPID=\"sword-mets-dmd-1_group-1\">\n" +
    "\t\t<mdWrap LABEL=\"SWAP Metadata\" MDTYPE=\"OTHER\" OTHERMDTYPE=\"EPDCX\"\n" +
    "\t\t\tMIMETYPE=\"text/xml\">\n" +
    "\t\t<xmlData>\n" +
    "\t\t\t<epdcx:descriptionSet xmlns:epdcx=\"http://purl.org/eprint/epdcx/2006-11-16/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://purl.org/eprint/epdcx/2006-11-16/ http://purl.org/eprint/epdcx/xsd/2006-11-16/epdcx.xsd\">\n"
  end

  def dmd_sec_footer
    "\t\t\t</epdcx:descriptionSet>\n" +
    "\t\t</xmlData>\n" +
    "\t</mdWrap>\n" +
    "</dmdSec>\n"
  end

  def dc_elem(name)
    "http://purl.org/dc/elements/1.1/#{name}"
  end

  def dc_term(name)
    "http://purl.org/dc/terms/#{name}"
  end

  def ep_ent_type(name)
    "http://purl.org/eprint/entityType/#{name}"
  end

  def ep_term(name)
    "http://purl.org/eprint/terms/#{name}"
  end

  def dmd_sec
    dmd_sec_body = "<epdcx:description epdcx:resourceId=\"sword-mets-epdcx-1\">\n"

    if @sac_type
      dmd_sec_body << statement_ves_uri_value_uri(dc_elem('type'), ep_term("Type"), @sac_type)
    end

    if @sac_title
      dmd_sec_body << statement(dc_elem("title"), value_string(@sac_title))
    end

    if @sac_abstract
      dmd_sec_body << statement(dc_term('abstract'), value_string(@sac_abstract))
    end

    @sac_creators.each do |sac_creator|
      dmd_sec_body << statement(dc_elem("creator"), value_string(sac_creator))
    end

    @sac_subjects.each do |sac_subject|
      dmd_sec_body << statement(dc_elem("subject"), value_string(sac_subject))
    end

    @sac_provenances.each do |sac_provenance|
      dmd_sec_body << statement(dc_term("provenance"), value_string(sac_provenance))
    end

    @sac_rights.each do |sac_right|
      dmd_sec_body << statement(dc_term("rights"), value_string(sac_right))
    end

    if @sac_identifier
      dmd_sec_body << statement(dc_elem("identifier"), value_string(@sac_identifier))
    end

    dmd_sec_body << "<epdcx:statement epdcx:propertyURI=\"#{ep_term('isExpressedAs')}\" " +
                    "epdcx:valueRef=\"sword-mets-expr-1\" />\n"

    dmd_sec_body << "</epdcx:description>\n"

    dmd_sec_body << "<epdcx:description epdcx:resourceId=\"sword-mets-expr-1\">\n"

    dmd_sec_body << statement_value_uri(dc_elem("type"), ep_ent_type("Expression"))

    if @sac_language
      dmd_sec_body << statement_ves_uri(dc_elem("language"), dc_term("RFC3066"), value_string(@sac_language))
    end

    dmd_sec_body << statement_ves_uri_value_uri(dc_elem("type"), ep_term("Type"), ep_ent_type("Expression"))

    if @sac_date_available
      dmd_sec_body << statement(dc_term("available"), value_string_ses_uri(dc_term("W3CDTF"), @sac_date_available))
    end

    if @sac_status_statement
      dmd_sec_body << statement_ves_uri_value_uri(ep_term("Status"), ep_term("Status"), @sac_status_statement)
    end

    if @sac_copyright_holder
      dmd_sec_body << statement(ep_term("copyrightHolder"), value_string(@sac_copyright_holder))
    end

    if @sac_citation
      statement(ep_term("bibliographicCitation"), value_string(@sac_citation))
    end

    dmd_sec_body << "</epdcx:description>\n"

    dmd_sec_header +
    dmd_sec_body +
    dmd_sec_footer
  end

  def file_group
    str = "\t<fileSec>\n"
    str << "\t\t<fileGrp ID=\"sword-mets-fgrp-1\" USE=\"CONTENT\">\n"

    @sac_filecount.times do |i|
      str << "\t\t\t<file GROUPID=\"sword-mets-fgid-0\" ID=\"sword-mets-file-#{i}\" "
      str << "MIMETYPE=\"#{@sac_mimetypes[i]}\">\n"
      str << "\t\t\t\t<FLocat LOCTYPE=\"URL\" xlink:href=\"#{clean(@sac_files[i])}\" />\n"
      str << "\t\t\t</file>\n"
    end
    str << "\t\t</fileGrp>\n"
    str << "\t</fileSec>\n"

    str
  end

  def struct_map
    str = "\t<structMap ID=\"sword-mets-struct-1\" LABEL=\"structure\" TYPE=\"LOGICAL\">\n"
    str << "\t\t<div ID=\"sword-mets-div-1\" DMDID=\"sword-mets-dmd-1\" TYPE=\"SWORD Object\">\n"
    str << "\t\t\t<div ID=\"sword-mets-div-2\" TYPE=\"File\">\n"
    @sac_filecount.times do |i|
      str << "\t\t\t\t<fptr FILEID=\"sword-mets-file-#{i}\" />\n"
    end
    str << "\t\t\t</div>\n"
    str << "\t\t</div>\n"
    str << "\t</structMap>\n"

    str
  end

  def clean(data)
    data
  end
  #    function clean($data) {
  #        return str_replace('&#039;', '&apos;', htmlspecialchars($data, ENT_QUOTES));
  #    }
end
