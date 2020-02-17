# 硬件同步原语(CAS)

硬件同步原语(Atomic Hardware Primitives) 是由计算机提供的一组原子操作, 我们比较常用的原语主要是_CAS_和_FAA_这两种.



## CAS

CAS(Compare and Swap)，它的字面意思是: _先比较_, _再交换_。

通过比较需要的比较的值(compare)是否与已经存储的值(old)相等, 如果等于, 那就把变量p赋值为new, 并返回true, 否则就不改变变量(compare)， 并返回false.



## FAA

FAA原语的语义是, 先获取变量p当前的值value, 然后给变量p增加inc, 然后返回变量之前的value.



原语的特殊之处就是, 他们都是由计算机硬件, 具体说就是CPU提供的实现，可以保证操作的_原子性_。