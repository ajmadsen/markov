package main

import (
	"bytes"
	"errors"
	"unicode"
	"unicode/utf8"
)

func scan(data []byte, atEOF bool) (advance int, token []byte, err error) {
	// skip whitespace
	for len(data) > 0 {
		r, size := utf8.DecodeRune(data)
		if r == utf8.RuneError {
			err = errors.New("scanner: invalid rune")
			return
		}
		if unicode.IsSpace(r) {
			advance += size
			data = data[size:]
		} else {
			break
		}
	}

	// check if we have more to process
	if len(data) == 0 {
		return 0, nil, nil
	}

	// get index of next space or punctuation
	idx := bytes.IndexFunc(data, func(r rune) bool {
		return unicode.IsSpace(r) || unicode.IsPunct(r)
	})

	if idx == 0 {
		if !atEOF {
			return 0, nil, nil
		}

		token = data
		advance += len(data)

		return
	}

	token = data[:idx]
	advance += idx

	return
}
