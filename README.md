## jianpu-ly w/ normalize writing
A choice for text file writing in jianpu-ly.py. Easy to writing, reading and checking



This jianputly adds a normalize text file supporting for jianpu-ly.py v1.838 by Mr. S.S.Brwon, it is an additional choice of score writing.


For normalize text file,

1. The Melody, Lyrics, Hanzi and  chords should be written in their paragragh and start with M:, L:, H:, and chords= accordingly, each paragragh begins and end by a blank line as a letter writing.

2. In paragragh of melody (or music/score), the attachment and its note can put together, and two more spaces or a return for the bar, the lilypond codes block mark by LP::LP can put in one line also. That would be easy to writing, reading and checking.

3. Other syntax can see the document from Mr. S.S.Brown.<http://ssb22.user.srcf.net/mwrhome/jianpu-ly.html>


In Hanzi:

### 一款符合书写习惯的简谱记谱法

jianpu-ly.py 是基于lilypond的简谱写谱软件，由英国剑桥大学S.S.Brown 教授编写。

jianpuly.py 在v1.1838版jianpu-ly.py基础上，增加了标准化文本读入功能，供有需要的用户选择，（也可用原有输入法或混合使用）

1. 乐谱、歌词、汉字歌词、和弦写在各自的段落中，分别用标识“M:”"L:","H:","chords="开头，段落前后各用一空行与其它文本隔开。

2. 为方便乐谱书写、阅读跟校对，音符跟修饰符附件之间可不留空格，音符组之间需用空格隔开, 小节线可用两个空格或换行或"|"作为标识，lilypond代码块LP::LP可写在一行之内。如  1( 2 3) 4~ &nbsp; 4 5 6 7 LP:\bar "||" :LP &nbsp; 1'--- 

3. 其它记谱规则见<guide_zh_CN.md>
 
