package main

import (
	"container/list"
	"crypto/sha1"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"os"
	"sync"
	"time"
	"unsafe"
	"github.com/fzzy/radix/redis"

	"strconv"
	"github.com/donnie4w/go-logger/logger"
	"my_test/vo"
	"github.com/golang/protobuf/proto"
)

var Per_value uint64 = 1000

/**
返回类型
*/
func run(arg string) (string, int) {
	fmt.Println(arg)
	return "返回值", 100
}

type IFly interface {
	Fly()
}

type Brid struct {
	Name    string
	Age     uint32
	Address string
}

//实现接口IFly
func (bird *Brid) Fly() {
	data, _ := json.Marshal(*bird)
	fmt.Printf("接口测试:%v\n", string(data))
}

/***
chan ---
 for(value: values){

 }
*/
func sum(values []int, resultChan chan int) {
	sum := 0
	for index, value := range values {
		sum += value

		fmt.Printf("%d,value:%d\n", index, value)
	}

	resultChan <- sum             // 将计算结果发送到channel中
	temp := <-resultChan          //  callback
	resultChan <- temp            //
	fmt.Printf("temp:%d\n", temp) //
}

/**变量名称大写  包外可以访问**/
const (
	Sunday = iota
	Monday
	Tuesday
	Wednesday
	Thursday
	Friday
	Saturday
	numberOfDays
)

// PersonInfo 一         的
// int
type PersonInfo struct {
	ID      int
	Name    string
	Address string
}

//define a new type is Integer   ----- typedef
type Integer int

//传递指针  修改值
func (a *Integer) Add(b Integer) {
	*a += b
}

type Rect struct {
	x, y          float64
	width, height float64
}

//继承Rect基类
type RectSub struct {
	Rect
	log.Logger
}

func (rect *RectSub) ComArea0() float64 {
	rect.x = 1
	rect.y = 2
	rect.ComArea() //调用父类的方法
	return rect.x * rect.y
}

func (rect *Rect) ComArea() float64 {
	return rect.x * rect.y
}

func (_r *Rect) SetX(x float64) {
	_r.x = x
}
func (_r *Rect) SetY(y float64) {
	_r.y = y
}
func errHndlr(err error) {
	if err != nil {
		fmt.Println("error:", err)
		os.Exit(1)
	}
}

func _log(i int) {
	logger.Debug("Debug>>>>>>>>>>>>>>>>>>>>>>" + strconv.Itoa(i))
	logger.Info("Info>>>>>>>>>>>>>>>>>>>>>>>>>" + strconv.Itoa(i))
	logger.Warn("Warn>>>>>>>>>>>>>>>>>>>>>>>>>" + strconv.Itoa(i))
	//logger.Error("Error>>>>>>>>>>>>>>>>>>>>>>>>>" + strconv.Itoa(i))
	//logger.Fatal("Fatal>>>>>>>>>>>>>>>>>>>>>>>>>" + strconv.Itoa(i))
}


/**
 测试pb文件
 */
func test_pb()  {
	test := &vo.Test {
		Label: proto.String("测试pb"),
		Type:  proto.Int32(17),
		Reps:  []int64{1, 2, 3},
		Optionalgroup: &vo.Test_OptionalGroup {
			RequiredField: proto.String("good bye"),
		},
	}

	data, err := proto.Marshal(test)
	logger.Debug(json.Marshal(data))

	if err != nil {
		log.Fatal("marshaling error: ", err)
	}
	newTest := &vo.Test{}
	err = proto.Unmarshal(data, newTest)
	logger.Debug(newTest.GetLabel())
	if err != nil {
		log.Fatal("unmarshaling error: ", err)
	}
	// Now test and newTest contain the same data.
	if test.GetLabel() != newTest.GetLabel() {
		log.Fatalf("data mismatch %q != %q", test.GetLabel(), newTest.GetLabel())
	}
}

func main() {


	test_pb()

	_value,_:=vo.Add(99,2)
	_log(_value);

	c, err := redis.DialTimeout("tcp", "127.0.0.1:6379", time.Duration(10)*time.Second)
	errHndlr(err)
	defer c.Close()

	{
		sub_rect := new(RectSub)
		sub_rect.ComArea0()
	}

	{
		/*
			初始化实例
			rect1 := new(Rect)
			rect2 := &Rect{}//引用
			rect3 := &Rect{0, 0, 100, 200}
			rect4 := &Rect{width: 100, height: 200}
		*/
		_xx := &Rect{11, 11, 100, 200}
		fmt.Printf("_xx 面积%f\n", _xx.ComArea())

		rect := new(Rect)
		rect.x = 100
		rect.y = 19
		area := rect.ComArea()
		fmt.Printf("面积%f\n", area)
	}

	{
		//传递值
		c := [3]int{1, 2, 3}
		var f = c         //值传递 , copy
		f[1]++            //修改f,但是c不变
		fmt.Println(c, f) //修改同一内存地址数据  ----

		//指向同一内存地址,传递引用
		var d = &c //地址---  & 取地址
		d[1]++
		fmt.Println(c, *d) //修改同一内存地址数据  ----
	}

	var _a Integer = 100
	_a.Add(1)
	fmt.Printf("a:%d\n", _a)

	var _person_map map[string]PersonInfo = make(map[string]PersonInfo, 10)
	_person_map["1"] = PersonInfo{89, "石头哥哥", "重庆"}

	delete(_person_map, "0")

	//for index, value := range list.New() {
	//	if index=target_index {
	//
	//	}
	//}

	/**
	status  进行判断是否存在指定值
	*/
	a_persion, status := _person_map["2"] //
	if status {
		fmt.Printf("found\n")
		fmt.Println(a_persion.Address + ":" + string(a_persion.ID) + ":" + a_persion.Name)
	} else {
		_json_, _ := json.Marshal(a_persion) //[]byte ----jsonstring
		fmt.Printf("@@%v ,%d\n", string(_json_), status)
	}

	_channel := make(chan int)

	go func() {
		for {
			time.Sleep(time.Second * 1)
			_channel <- 78
		}
	}() //跟参数列表,表示直接调用

	res := func(x, y int) int {
		z := x * y % 10
		fmt.Printf("匿名函数测试:%d\n", z)
		return z
	}(54, 997)

	fmt.Printf("匿名函数测试返回结果:%d\n", res)

	//
	select {
	case i := <-_channel:
		fmt.Println(i)
	}

	a := []int{1, 2, 3, 4, 5, 6}
	fmt.Printf("base:%v\n", a)
	f_modiy := func(_array []int) {
		_array[0] = 100
		fmt.Printf("f_modiy :%v\n", a)
	}
	f_modiy(a) //匿名函数
	fmt.Printf("%v\n", a)

	/**
	range : 返回1个值
	第一个返回值: 索引
	第二个返回值: 返回集合中的元素
	*/

	_test_array := []uint32{10, 89, 99}
	myslice := _test_array[:]
	for index, value := range myslice {
		fmt.Printf("index:%d,value:%d\n", index, value)
	}

	values := [11]int{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
	resultChan := make(chan int, 2)
	var _size uintptr = unsafe.Sizeof(resultChan)
	fmt.Printf("size:%d\n", _size)
	fmt.Printf("len:%d\n", len(resultChan))

	//切片
	go sum(values[0:len(values)/2], resultChan)
	go sum(values[len(values)/2:len(values)], resultChan)

	/***/
	_hash := sha1.New()
	println(_hash.BlockSize())

	sum1, _ok := <-resultChan
	sum2, _ok2 := <-resultChan

	//time.Sleep(1);
	if _ok && _ok2 {
		fmt.Println("Result:", sum1, sum2, sum1+sum2)
		//close(resultChan)
	}

	var _fly IFly = new(Brid)
	_fly.Fly()

	list.New()
	fmt.Printf("随机数:%f\n", rand.Float32())
	value := 1000
	fmt.Printf("测试:%d\n", value)
	fmt.Println("测试!!!!!")

	arg := "这是测试string"
	//fmt.Println(arg);
	_, __value := run(arg) // 赋值
	log.Printf("--%d\n", __value)
	if arg == "" {
		/**
		打开文件
		*/
		fd, err := os.Open("")
		if err != nil {
			log.Println("Open file failed:", err)
			return
		}
		defer fd.Close()
	}

	/**
	匿名函数  闭包
	*/

	f := func(x, y uint32) uint32 {
		return x + y
	}

	fmt.Printf("%d\n", f(100, 11))

	{

		var lock sync.RWMutex
		//var _cond sync.Cond
		//    c.L.Lock()
		//    for !condition() {
		//        c.Wait()
		//    }
		//    ... make use of condition ...
		//    c.L.Unlock()
		//
		lock.Lock()
		go run("协程测试!!!")
		defer lock.Unlock()
	}

	var _v_map map[int]int
	_v_map = make(map[int]int, 10)
	fmt.Println(_v_map)

	_v_map[1] = 10000
	map_value, ok := _v_map[1] // first is map value ,second is status
	if ok {
		fmt.Printf("map value%d,%v\n", map_value, ok)
	}

	//变量初始化
	init_value := 100
	fmt.Printf("init_value:%d\n", init_value)
	//变量赋值
	var v1 int
	v1 = 100
	fmt.Printf("init_value:%d\n", v1)

	//编译期行为
	const vv0, name = 100, "石头哥哥"
	fmt.Printf("%v\n", name)

	const (
		c0 = iota // 0
		c1        //1
		c2        //2
	)

	defer func() {
		fmt.Print("测试defer!!!!\n")
	}()

}
