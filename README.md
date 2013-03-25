# csv to hash

      csv = CSV.read(input, :headers => true)
      # csv的每一条记录不是array它的class是CSV::Row
      # 需要先变为array 开始Hash[*array]总是报奇数项目就是因为这个出错误
      # 因为CSV::Row本身就带这headre信息，还带有一个行号信息。正式这个行号信息让元素变为了奇数
      hash = csv.map {|e| Hash[*e.to_a.flatten]} # an arry of hashes

# stdlib zlib adler32 generate a checksum with numbers only

      Zlib::adler32(str)

ref: 
<http://www.ruby-doc.org/stdlib-2.0/libdoc/zlib/rdoc/Zlib.html#method-c-adler32>
<http://en.wikipedia.org/wiki/Adler-32>
