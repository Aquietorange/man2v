package tool

import (
	"bytes"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"math/big"
	"sync"
)

//截取文件 str =开始位置,len=截取长度, -1=截取到尾部
func Substr(s string, str, lena int) string {
	ss := []byte(s)
	if str > len(ss) {
		return ""
	}
	if lena == -1 {
		return string(ss[str:])
	} else {
		return string(ss[str : str+lena])
	}
}

//取 小于 max 的 随机整数
func Randint(min int64, max int64) int64 {
	n, _ := rand.Int(rand.Reader, big.NewInt(max))
	return n.Int64() + min
}

//环形队列
type CircleQueue struct {
	Total int
	lock  sync.RWMutex //读写锁
	valus []CircleQueueContent
	Maxl  int
}

type CircleQueueContent struct {
	Id      int    `json:"id"`
	Content string `json:"content"`
}

//控制 Lines 长度 不超过 maxl 下追加新line
func (cir *CircleQueue) Append(line string) {
	cir.lock.Lock()
	if len(cir.valus) >= cir.Maxl {
		cir.valus = cir.valus[1:]
	}
	cir.Total++
	cir.valus = append(cir.valus, CircleQueueContent{
		Id:      cir.Total,
		Content: line,
	})
	cir.lock.Unlock()
}

func (cir *CircleQueue) Getlines(strid int) []CircleQueueContent {
	var lines []CircleQueueContent
	cir.lock.Lock()
	if strid < cir.Total {
		lines = cir.valus
	} else {

		for _, v := range cir.valus {
			if v.Id > strid {
				lines = append(lines, v)
			}
		}

	}
	cir.lock.Unlock()
	return lines
}

//创建一个环形队列 指定 最大容量
func NewCircleQueue(Maxl int) *CircleQueue {

	var cir = &CircleQueue{
		Maxl: 100,
	}
	return cir
}

var byteGroups = []int{8, 4, 4, 4, 12}

type UUID [16]byte

// String returns the string representation of this UUID.
func (u *UUID) String() string {
	bytes := u.Bytes()
	result := hex.EncodeToString(bytes[0 : byteGroups[0]/2])
	start := byteGroups[0] / 2
	for i := 1; i < len(byteGroups); i++ {
		nBytes := byteGroups[i] / 2
		result += "-"
		result += hex.EncodeToString(bytes[start : start+nBytes])
		start += nBytes
	}
	return result
}

// Bytes returns the bytes representation of this UUID.
func (u *UUID) Bytes() []byte {
	return u[:]
}

// Equals returns true if this UUID equals another UUID by value.
func (u *UUID) Equals(another *UUID) bool {
	if u == nil && another == nil {
		return true
	}
	if u == nil || another == nil {
		return false
	}
	return bytes.Equal(u.Bytes(), another.Bytes())
}

// New creates a UUID with random value.
func NewUUID() UUID {
	var uuid UUID
	rand.Read(uuid.Bytes())
	return uuid
}

// ParseString converts a UUID in string form to object.
func ParseString(str string) (UUID, error) {
	var uuid UUID

	text := []byte(str)
	if len(text) < 32 {
		return uuid, errors.New(str)
	}

	b := uuid.Bytes()

	for _, byteGroup := range byteGroups {
		if text[0] == '-' {
			text = text[1:]
		}

		if _, err := hex.Decode(b[:byteGroup/2], text[:byteGroup]); err != nil {
			return uuid, err
		}

		text = text[byteGroup:]
		b = b[byteGroup/2:]
	}

	return uuid, nil
}
