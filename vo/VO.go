package vo

import "github.com/donnie4w/go-logger/logger"

func Add(a, b int) (int ,error) {
	logger.Debug("Add:",a+b,9527%10)
	return a + b,nil
}
