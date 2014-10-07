package main

import (
	"bufio"
	"bytes"
	"errors"
	"strings"
	"unicode"
	"unicode/utf8"
)

func scanner(terminals string) bufio.SplitFunc {
	return func(data []byte, atEOF bool) (advance int, token []byte, err error) {
		// find start of next token
		idx := bytes.IndexFunc(data, func(r rune) bool {
			// find first non-space character, or first terminal
			return !unicode.IsSpace(r) || strings.ContainsRune(terminals, r)
		})

		// advance data to start of token
		if idx > 0 {
			advance += idx
			data = data[idx:]
		}

		// check for terminal
		r, siz := utf8.DecodeRune(data)
		switch {
		case !utf8.ValidRune(r):
			// need more data
			if atEOF {
				err = errors.New("scanner: invalid utf8")
				return
			}
			return 0, nil, nil
		case strings.ContainsRune(terminals, r):
			// return terminal
			advance += siz
			token = data[:siz]
			return
		case unicode.IsPunct(r):
			// return punctuation
			advance += siz
			token = data[:siz]
			return
		}

		// find end of token, with special cases
		switch {
		case bytes.HasPrefix(data, []byte("http")):
			// we need to go to the end of the word
			idx = bytes.IndexFunc(data, unicode.IsSpace)
		default:
			idx = bytes.IndexFunc(data, func(r rune) bool {
				return unicode.IsSpace(r) || unicode.IsPunct(r) || strings.ContainsRune(terminals, r)
			})
		}

		// if we have a complete token
		if idx > 0 {
			advance += idx
			token = data[:idx]
			return
		}

		// we don't have a complete token
		if !atEOF {
			// ask for more
			return 0, nil, nil
		}

		// return what we have
		return len(data), data, nil
	}
}
