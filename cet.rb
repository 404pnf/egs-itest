# -*- coding: utf-8 -*-

require 'csv'
require 'pp'
require 'html_massage'
require 'sanitize'

# 如何使用

# ruby -w cet.rb cet.csv
# 会生成 out-cet.csv

# 需要用libreoffice打开生成文件并排序
# 直接在libreoffcie中用 data > sort
# 然后先按 sort 排列，再按附件地址 排列
# 然后再删除 sort 这列
# 比在程序中排序方便多了

DEBUG = nil #true

# stdlib zlib adler32 generate a checksum with numbers only
# Zlib::adler32(str)
# ref: http://www.ruby-doc.org/stdlib-2.0/libdoc/zlib/rdoc/Zlib.html#method-c-adler32
# http://en.wikipedia.org/wiki/Adler-32

input = ARGV[0]


# help function
def remove_html_class_and_id str
 # str.gsub(/(<[^ ]+) [^>]+>/, '\1>') #别忘了之前的那个封闭标签不在\1中
 #  str.gsub(/(<[^ \/]+) [^>]+>/,'\1>')
  #Sanitize.clean(str, Sanitize::Config::RESTRICTED)
  Sanitize.clean(str, Sanitize::Config::BASIC)
end

csv = CSV.read(input, :headers => true)
# csv的每一条记录不是array它的class是CSV::Row
# 需要先变为array 开始Hash[*array]总是报奇数项目就是因为这个出错误
# 因为CSV::Row本身就带这headre信息，还带有一个行号信息。正式这个行号信息让元素变为了奇数
hash = csv.map {|e| Hash[*e.to_a.flatten]} # an arry of hashes
pp "题目数： #{hash.size}"
id = rand(hash.size) if DEBUG
pp "随机显示 #{id} :" if DEBUG
pp "orig csv_hash:    #{hash[id]}" if DEBUG

# step 1
# add keys
# 序号；考点；分值；时间限制；填空题输入大小
step_1 = hash.map { |h| 
  %w(egs-序号 egs-考点 egs-分值 egs-时间限制 egs-填空题输入大小).each { |key| h[key] = nil}
  h['egs-序号'] = h['id']
  h['egs-父级题目id'] = h['father_id']
  h['egs-Directions材料题干'] = h['Directions材料题干']
  h}
pp "step 1:"  if DEBUG
pp step_1[id] if DEBUG

# step 2
# add 标题 
# 增加一列：命名规则：试卷类别+”-”+ egs对应标签题型+”-”+基本题型  （英文连字符连接）
step_2 = hash.map { |h| 
  h['egs-标题'] = [ h['试卷类别'], h['Egs对应标签题型'], h['基本题型'] ].join('-'); 
  %w(Egs对应标签题型 题型 基本题型 选项是否随机出现 是否依赖上级父题目 子题目是否可以随机出现 Directions材料题干 资源地址).each {|word| h["egs-#{word}"] = h[word]}

  h}
pp "step 2:"  if DEBUG
pp step_2[id] if DEBUG

# step 3
# 选项与解析

# 子题（既父级题目id不为空的）：
# csv结构中，'选项与解析' ->  选项之间分隔符为”_|_”，正确答案的数组编号（从0开始）与选项之间分隔符为 “||”
# 需要拼成的EGS目标列的规则为：

# 选项状态值+”--”+选项+*[“||”+解析]+”&&”
# 选项状态值：
# 其中“0--” 表示错误答案；“1--” 表示正确答案；
# “&&”为选项分隔符，最后一个选项后面不出现；
# “||”为解析内容与选项之间的分隔符，只有正确答案才跟解析
# 注意：不能改变原有顺序

# step 3
# 更新父级题目id不为空的 '选项与解析' --> 'egs选项与解析'
# 例子 
# "Because she has got an appointment_|_Because she doesn’t want to_|_Because she has to work_|_Because she wants to eat in a new restaurant||2"

# step_2.each {|h| p h["father_id"].class} # 证明father_id即使为空也只是空字符串
# step_2.each {|h| p h["选项与解析"] if h["father_id"] != ''} # 证明father_id即使为空也只是空字符串
step_3 = step_2.map {|h|
  if !h["father_id"].empty?
    answers, correct_id = h['选项与解析'].split('||')
    correct_id = correct_id.to_i
    #explanation = HtmlMassage.html(h['正确答案解析']) #去掉html标签中的属性值
    explanation = h['正确答案解析'].strip # strip surrounding white spaces
    #explanation = remove_html_class_and_id explanation    
    egs_choices = []
    answers.split('_|_').each_with_index {|choice, idx|
      if idx == correct_id
        if explanation.nil? or  explanation.empty?
          egs_choices << "1--#{choice}"
        else
          egs_choices << "1--#{choice}||#{explanation}"
        end
      else
        egs_choices << "0--#{choice}"
      end
    }
    egs_choices_str = egs_choices.join('&&')
    h['egs-选项与解析'] = egs_choices_str
  end
 
# 父题（既父级题目id为空的）：                                                 
# 对应EGS目标列“选项与解析”，但要扫描下csv中的“题干”，                         #
# 如果题干内容在“选项与解析”中有，则直接使用“选项与解析”中的内容，前面加上"||" #
# 否则为csv文件的“选项与解析”+“题干”，前面加上“||”                             #
#                                                                              #
# 以上是最初描述，实际发现有问题                                               #
#                                                                              #
# 按照规则                                                                     #
#                                                                              #
# 父级题：解析中含有题干内容的话，就直接用解析，不含有，就解析+题干            #
#                                                                              #
# 有不少题目的实际情况是                                                       #
#                                                                              #
# 解析为:                                                                      #
# W: hello? M: hello! Q: What are they doing?                                  #
#                                                                              #
# 题干为下列：                                                                 #
# '  '                                                                         #
# '2'                                                                          #
# '-'                                                                          #
# 这些奇怪的东西                                                               #
#                                                                              #
# 这种情况下解析中自然不包含题干！                                             #
#                                                                              #
# 程序就自然把题干的文字又当成解析引入进来。                                   #
#                                                                              #
# 解决方法：                                                                   #
#                                                                              #
# 不用之前约定的东西                                                           #
# 直接判断解析中有没有关键字“Q: ”                                              #
# 如果有，就忽略题干内容                                                       #
# 如果没有，拼题干内容                                                         #


  if h["father_id"].empty?
    # gem html_massage
    # see: https://github.com/harlantwood/html_massage

    # strip all attributes of html tags
    # or else we got <p style="font-size: 10px" ... etc
    # 额外过滤掉所有dvi标签的class和id属性
    # HtmlMassage.html 没有这个功能？！
    # <div id=""resourceScript"">
    #=> "\n<div class=\"\"glossary\"\" id=\"\"Glossary\"\">\n"
    #>> s.gsub(/<div [^>]+>/,'<div>')
    #=> "\n<div>\n"
    #explanation = HtmlMassage.html(h['选项与解析'])
    explanation = h['选项与解析']
    explanation = remove_html_class_and_id explanation
    #tigan = HtmlMassage.html(h['题干'])
    tigan = h['题干']
    #tigan = remove_html_class_and_id tigan # 不能取消属性，否则题干消失了！
    if explanation.include? 'Q:'
      egs_choices_str = "||#{explanation}"
    else
      egs_choices_str = "||#{explanation} Q: #{tigan}"
    end
    h['egs-选项与解析'] = egs_choices_str
  end
  h
}

#pp step_3[4530] if DEBUG
#pp step_3[1862] if DEBUG
#pp "检查选项与解析"
pp step_3[id] if DEBUG

# final step
# keep egs keys only
final_hash = step_3.each {|h|
  h.keep_if {|k,_| k =~ /egs/}
  h
}
pp final_hash[id] if DEBUG


# final_hash is an ARRAY of hashes
sorted = final_hash.each { |record|
  record['序号自定义'] = record['egs-序号']
  record['标题自定义'] = record['egs-标题']
  record['父级题目id自定义'] = record['egs-父级题目id']
  record['题型 试卷题型'] = record['egs-题型']
  record['基本题型-EGS试题'] = record['egs-基本题型']
  record['Directions-材料-题干'] = record['egs-Directions材料题干']
  record['选项与解析'] = record['egs-选项与解析']
  record['选项是否随机出现-1是-0否- 默认1）'] = record['egs-选项是否随机出现']
  record['考点'] = record['egs-考点']
  record['标签'] = record['egs-Egs对应标签题型']
  record['分值'] = record['egs-分值']
  record['时间限制'] = record['egs-时间限制']
  record['是否依赖上级父题目-1是-0否-默认1'] = record['egs-是否依赖上级父题目']
  record['子题目是否可以随机出现-1是-2否-默认2'] = record['egs-子题目是否可以随机出现']
  # 更新附件地址的mp3路径
  # 从 /resourcefile/2021003/710/some-mp3-FILE.mp3
  # 到 /itest/egs/upload/files/mp3/some-mp3-file.mp3
  # 文件名转为小写
  record['附件地址'] = record['egs-资源地址']
  record['附件地址'] = '/itest/egs/upload/files/mp3/' + record['附件地址'].split('/').last.downcase if record['附件地址'].match('/')
  record['填空题输入框大小'] = record['egs-填空题输入大小']
  record.delete_if {|k, _|  k =~ /egs/}
  }

# 我们来清除wyq认为不符合要求的题
# 这些题题在itest中一直没有方法去发现，在转到egs时我们删除这些错题

# 必须保证该题是父题，否则所有子题都删除了！！


del_no_mp3_hash = sorted.delete_if {|record|
  # 删除没有'附件地址'的条目
  record['父级题目id自定义'].empty? && record['附件地址'].empty? 
}

del_bad_transcript_hash = del_no_mp3_hash.delete_if {|record|
  # 选项与解析中没有音频脚本， M W Q 代表 M: W: Q: 三个脚本中的关键词man, woman, question
  record['父级题目id自定义'].empty? && !(record['选项与解析'].include?('M:' || 'Q:' || 'W:')) 
}

record_id = [] ; del_bad_transcript_hash.each {|record| record_id << record['序号自定义']}
del_no_parent_id_hash = del_bad_transcript_hash.delete_if {|record|
  # 是子题，但对应的父级不存在
  # 本次导出的题目中不存在有这种现象的
  !record['父级题目id自定义'].empty? && !(record_id.include? record['父级题目id自定义'])
}


sort_by_parent_id_hash = del_no_parent_id_hash.sort_by {|record|
  if record['父级题目id自定义'].empty?
    record['sort'] =  record['序号自定义']
  else 
    record['sort'] =  record['父级题目id自定义']
  end
  record['sort']
}

final_sorted = sort_by_parent_id_hash.each {|record|
  record
}

#final_sorted = del_no_parent_id_hash

pp "删除不符合要求的题目后，共有题目：#{del_no_parent_id_hash.size}条。"

headers = final_sorted[1].keys.join(',')
arr_of_csv = final_sorted.map { |h| h.values.to_csv(:force_quotes => true) }
pp arr_of_csv[id] if DEBUG
final_csv_str = ''
final_csv_str << headers << "\n" << arr_of_csv.join # arr_of_csv already has "\n" at the end of each record
outputfile = 'out-cet.csv'
File.write(outputfile, final_csv_str)
pp "生成的csv文件是 #{outputfile}。"

# ref: http://stackoverflow.com/questions/4420677/storing-csv-data-in-ruby-hash

