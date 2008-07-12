require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "ARGF.readline" do
  before :each do
    ARGV.clear
    @contents_file1 = File.read(File.dirname(__FILE__) + '/fixtures/file1.txt')    
    @contents_file2 = File.read(File.dirname(__FILE__) + '/fixtures/file2.txt')
    @contents_stdin = File.read(File.dirname(__FILE__) + '/fixtures/stdin.txt')
  end

  after :each do
    # Close any open file (catch exception if already closed)
    ARGF.close rescue nil
  end
  
  it "reads one line of a file" do
    ARGFSpecs.file_args('file1.txt')
    ARGF.readline().should == @contents_file1.split($/).first+$/
  end
  
  it "reads all lines of a file" do
    ARGFSpecs.file_args('file1.txt')
    number_of_lines = @contents_file1.split($/).size
    all_lines = []
    for i in 1..number_of_lines
      all_lines << ARGF.readline()
    end
    all_lines.should == @contents_file1.split($/).collect { |l| l+$/ }
  end
  
  it "reads all lines of stdin" do
    ARGFSpecs.file_args('-')
    number_of_lines = @contents_stdin.split($/).size
    all_lines = []
    STDIN.reopen(File.dirname(__FILE__) + '/fixtures/stdin.txt')
    for i in 1..number_of_lines
      all_lines << ARGF.readline()
    end
    all_lines.should == @contents_stdin.split($/).collect { |l| l+$/ }
  end
  
  it "reads all lines of two files" do
    ARGFSpecs.file_args('file1.txt', 'file2.txt')
    number_of_lines = @contents_file1.split($/).size + @contents_file2.split($/).size
    all_lines = []
    for i in 1..number_of_lines
      all_lines << ARGF.readline()
    end
    all_lines.should == (@contents_file1+ @contents_file2).split($/).collect { |l| l+$/ }
  end
  
  it "raises an EOFError when reaching end of files" do
    ARGFSpecs.file_args('file1.txt', 'file2.txt')
    lambda { while line = ARGF.readline;end }.should raise_error(EOFError)
  end
  
  # Note: this test will only work on platforms that is capable of doing
  # safe rename. Unfortunately there is no method in 1.8.X to test that.
  # This has been corrected in Ruby 1.9.x
  it "modifies the files when in place edit mode is on" do
    # create fixture files that can be altered
    file1 = tmp('file1.txt'); file2 = tmp('file2.txt'); file3 = tmp('file3.txt')
    File.open(file1,'w') { |fh| fh.write(@contents_file1) }
    File.open(file2,'w') { |fh| fh.write(@contents_file2) }
    File.open(file3,'w') { } # touch
    ARGV.concat([file1, file2, file3])
    $-i = ""  # activate in place edit mode
    
    modified_lines = []
    begin
      while line = ARGF.readline
        modified_line = line+'.new'+$/
        modified_lines << modified_line
        print modified_line
      end
    rescue EOFError
      # TODO: I could not find a way to test the changes on the last file
      # its content seems to be written only when the ruby process terminates
      # i tried various combination of flush, close on ARGF and STDOUT but could
      # fix the problem. 
      # Workaround: add a third empty file on the command line
      contents_modified_files = File.read(file1) + File.read(file2)
      contents_modified_files.should == modified_lines.join
    ensure
      # cleanup the mess
      [file1, file2, file3].each { |f| File.delete(f) if File.exists?(f)}
      # disable in place edit mode
      $-i = nil      
    end
  end
  
    it "modifies an backups two files when in place edit mode is on" do
    # create fixture files that can be altered
    file1 = tmp('file1.txt'); file2 = tmp('file2.txt'); file3 = tmp('file3.txt')
    File.open(file1,'w') { |fh| fh.write(@contents_file1) }
    File.open(file2,'w') { |fh| fh.write(@contents_file2) }
    File.open(file3,'w') { } # touch
    ARGV.concat([file1, file2, file3])
    $-i = ".bak"  # activate in place edit mode with backup
    
    modified_lines = []
    begin
      while line = ARGF.readline
        modified_line = line+'.new'+$/
        modified_lines << modified_line
        print modified_line
      end
    rescue EOFError
      # TODO: I could not find a way to test the changes on the last file
      # its content seems to be written only when the ruby process terminates
      # i tried various combination of flush, close on ARGF and STDOUT but could
      # fix the problem. 
      # Workaround: add a third empty file on the command line
      File.exists?(file1+$-i).should == true
      File.exists?(file2+$-i).should == true
      File.read(file1+$-i).should == @contents_file1
      File.read(file2+$-i).should == @contents_file2
      contents_modified_files = File.read(file1) + File.read(file2)
      contents_modified_files.should == modified_lines.join
    ensure
      # cleanup the mess
      [file1, file2, file3, file1+$-i, file2+$-i, file3+$-i].each { |f| File.delete(f) if File.exists?(f)}
      # disable in place edit mode
      $-i = nil
    end
  end
  
end