# -*- coding: utf-8 -*-

require 'csv'
require 'pp'

DEBUG = true

input = ARGV[0]
csv = CSV.read(input, :headers => true)
# csv的每一条记录不是array它的class是CSV::Row
# 需要先变为array 开始Hash[*array]总是报奇数项目就是因为这个出错误
# 因为CSV::Row本身就带这headre信息，还带有一个行号信息。正式这个行号信息让元素变为了奇数
hash = csv.map {|e| Hash[*e.to_a.flatten]} # an arry of hashes
pp "题目数： #{hash.size}"
#id = rand(hash.size) if DEBUG
#pp "随机显示 #{id} :" if DEBUG
#pp "orig csv_hash:    #{hash[id]}" if DEBUG


# 我们来清除不符合要求的题

# 必须保证该题是父题，否则所有子题都删除了！！
record_id = [] ; hash.each {|record| record_id << record['序号自定义']}
#pp "#{record_id.size}"

del_no_mp3_hash = hash.delete_if {|record|
  # 删除没有'附件地址'的条目
  record['父级题目id自定义'].empty? && record['附件地址'].empty? 
}

del_bad_transcript_hash = del_no_mp3_hash.delete_if {|record|
  # 选项与解析中没有音频脚本， M W Q 代表 M: W: Q: 三个脚本中的关键词man, woman, question
  record['父级题目id自定义'].empty? && !(record['选项与解析'].include? ('M' || 'Q' || 'W')) 
}

pp temp_hash = del_bad_transcript_hash.select {|record|
  # 是子题，但对应的父级不存在
  !record['父级题目id自定义'].empty? && !(record_id.include? record['父级题目id自定义'])
}

del_no_parent_id_hash = del_bad_transcript_hash.delete_if {|record|
  # 是子题，但对应的父级不存在
  !record['父级题目id自定义'].empty? && !(record_id.include? record['父级题目id自定义'])
}


pp "#{del_no_parent_id_hash.size}"
=begin
arr_of_csv = sorted.map { |h| h.values.to_csv(:force_quotes => true) }
pp arr_of_csv[id] if DEBUG
final_csv_str = ''
final_csv_str << headers << "\n" << arr_of_csv.join # arr_of_csv already has "\n" at the end of each record
outputfile = 'out-cet-more.csv'
File.write(outputfile, final_csv_str)
pp "生成的csv文件是 #{outputfile}。"
=end


