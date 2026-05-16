package mockgames

import (
	"crypto/rand"
	"encoding/hex"
)

func newID(prefix string) string {
	var bytes [8]byte
	if _, err := rand.Read(bytes[:]); err != nil {
		return prefix + "-mock"
	}
	return prefix + "-" + hex.EncodeToString(bytes[:])
}
