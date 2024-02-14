package main

import (
	"github.com/jinzhu/copier"
)

type Person struct {
	Name string
}

func main() {
	src := Person{Name: "Alice"}

	var dest Person
	err := copier.Copy(&dest, &src)
	if err != nil {
		panic(err)
	}
}
