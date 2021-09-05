### 基本格式

vi hello.sh

```java
#! /bin/bash   ##表示用哪一种shell解析器来解析执行这个脚本
```

执行脚本：`sh hello.sh`
或者给脚本添加x权限 `./hello.sh`

### 变量

变量=值（例如A=7）
**注意：**等号两侧不能有空格
变量名一般习惯为大写
**使用变量：$A**

**注意：**变量中的值没有类型，全部为字符串

### 算数运算

- 用expr
  `expr $A + $B`
  赋值
  `C=expr $A + $B`
  注意中间空格
- 用(())
  `((1+2))`
  赋值
  `A=$((1+2))`
- 自增
  `count=1
  ((count++))
  echo $count`
- 用$[]
  `a=$[1+2]`
  echo $a用let
  `i=1
  let i++
  let i=i+2`

### 流程控制
```if 条件
if 条件
then
	执行代码
elif 条件
	then
	执行代码
else
	执行代码
fi
```

### 常用判断运算符

**字符串比较**
= 字符串是否相等
!= 字符串是否不相等
-z 字符串长度为0返回true
-n 字符串长度不为0返回true

```java
if[ 'aa' = 'bb' ];then echo "ok";else echo "not ok";fi
if[ -n "aa" ];;then echo "ok";else echo "not ok";fi
if[ -z "" ];;then echo "ok";else echo "not ok";fi
```

**整数比较**
-lt 小于
-le 小于等于
-eq 等于
-gt 大于
-ge 大于等于
-ne 不等于
**文件判断**
-d 是否为目录
`if [ -d /bin ];then echo ok;else echo notok;fi`
-f 是否为文件
`if [ -f /bin/ls ];then echo ok;else echo notok;fi`

### 循环控制

while 表达式
do

```java
i=1
while((i<3))
do
echo $i
let i++
```

case语句

```case $i in
start)
echo "starting"
;;
stop)
echo "stoping"
;;
*)
echo "Usage:{start|stop}"
esac```
```

