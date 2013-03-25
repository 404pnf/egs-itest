# -*- coding: utf-8 -*-

# -*- coding: utf-8 -*-
require 'csv'
require 'pp'
#require 'smarter_csv'

input = ARGV[0]
csv = CSV.read(input, :headers => true)
# csv的每一条记录不是array它的class是CSV::Row
# 需要先变为array 开始Hash[*array]总是报奇数项目就是因为这个出错误
# 因为CSV::Row本身就带这headre信息，还带有一个行号信息。正式这个行号信息让元素变为了奇数
hash = csv.map {|e| Hash[*e.to_a.flatten]} # an arry of hashes
p "题目数： #{hash.size}"
id = rand(hash.size)
#pp "随机显示 #{id} :   #{hash[id]}"

# step 1
# add keys
# 序号；考点；分值；时间限制；填空题输入大小
step_1 = hash.map { |h| %w(egs序号 egs考点 egs分值 egs时间限制 egs填空题输入大小).each { |key| h[key] = nil}; h}
pp step_1[id]

# step 2
# add 标题 
# 增加一列：命名规则：试卷类别+”-”+ egs对应标签题型+”-”+基本题型  （英文连字符连接）
step_2 = hash.map { |h| 
  h['egs标题'] = [ h['试卷类别'], h['egs对应标签题型'], h['基本题型'] ].compact # remove nil
    .join('-'); 
  h['egs对应标签题型'] = h['Egs对应标签题型'];
  h['egs题型'] = h['题型'];
  h['egs基本题型'] =  h['基本题型'];
  h['egs选项是否随机出现'] = h['选项是否随机出现'];
  h['egs是否依赖上级父题目'] = h['是否依赖上级父题目'];
  h['egs子题目是否可以随机出现'] = h['子题目是否可以随机出现'];
  h['egs材料题干'] = h['Directions材料题干'];
  h}
pp step_2[id]

# step 3
# 选项与解析
# 父题（既父级题目id为空的）：
# 对应EGS目标列“选项与解析”，但要扫描下csv中的“题干”，如果题干内容在“选项与解析”中有，则直接使用“选项与解析”中的内容。
# 否则为csv文件的“选项与解析”+“题干”

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
  if h["father_id"] != ''
    choices, correct_choice_index = h['选项与解析'].split('||')
    a, b, c, d = choices.split('_|_')
    arr_of_choice = [a,b,c,d]
    jiexi = h['正确答案解析']
    correct_choice = arr_of_choice[correct_choice_index.to_i] # array[index]
    #p a, b, c,
    #p d # jiexi
    #p correct_choice
    # join them to egs 
    egs_choices = arr_of_choice.each_with_index.map { |choice, idx|
      if idx == correct_choice_index.to_i
        choice = "0--#{choice}||#{jiexi}"
      else
        choice = "1--#{choice}"
      end
    }
    p egs_choices.join('&&')
  end
  h
}





# ref: https://github.com/tilo/smarter_csv
# ref: http://stackoverflow.com/questions/4420677/storing-csv-data-in-ruby-hash

