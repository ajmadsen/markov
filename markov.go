package main

import (
	"bufio"
	"io"
	"regexp"
	"strings"
)

var sp = regexp.MustCompile(`[\s]+`)

var assoc = regexp.MustCompile(` ([,.!?:\]\)\}])|([\[\(\{]) | ([-\/]) `)

type Markov struct {
	db        *DB
	ntok      int
	terminals string
}

func NewMarkov(ntok int, terminals string, db *DB) *Markov {
	if ntok < 1 {
		panic("ntok too small")
	}

	return &Markov{
		db,
		ntok,
		terminals,
	}
}

func (m *Markov) Parse(r io.Reader) error {
	ntok := 0

	s := bufio.NewScanner(r)
	s.Split(scanner(m.terminals))

	tokbuf := make([]string, m.ntok)

	tx, err := m.db.Begin()
	if err != nil {
		return err
	}

	for s.Scan() {
		tok := s.Text()

		err = tx.Insert(strings.Join(tokbuf, " "), tok)
		if err != nil {
			tx.Rollback()
			return err
		}

		if strings.Contains(m.terminals, tok) {
			// flush token buffer
			tokbuf = make([]string, m.ntok)
		} else {
			copy(tokbuf, tokbuf[1:])
			tokbuf[m.ntok-1] = tok
		}

		ntok++
		if ntok%10000 == 0 {
			//			log.Printf("Parsed %d tok", ntok)
		}
	}

	err = s.Err()
	if err != nil {
		tx.Rollback()
		return err
	}

	err = tx.Commit()
	if err != nil {
		return err
	}

	return nil
}

func (m *Markov) Generate(mintok int) (string, error) {
	tokbuf := make([]string, m.ntok)
	var buf []string

	for len(buf) < mintok || !strings.Contains(m.terminals, tokbuf[m.ntok-1]) {
		tok, err := m.db.Next(strings.Join(tokbuf, " "))
		if err != nil {
			return "", err
		}

		buf = append(buf, tok)

		if strings.Contains(m.terminals, tok) {
			tokbuf = make([]string, m.ntok)
		} else {
			copy(tokbuf, tokbuf[1:])
			tokbuf[m.ntok-1] = tok
		}
	}

	str := strings.Join(buf, " ")
	str = sp.ReplaceAllLiteralString(str, " ")
	str = assoc.ReplaceAllString(str, "${1}")
	str = strings.Replace(str, " ' ", "'", -1)

	// clean up quotes kinda
	for strings.Contains(str, " \" ") {
		// first group right
		str = strings.Replace(str, " \" ", " \"", 1)

		// then group left
		str = strings.Replace(str, " \" ", "\" ", 1)
	}

	// strip leading spaces
	str = strings.TrimPrefix(str, " ")

	return str, nil
}

func (m *Markov) Close() error {
	return m.db.Close()
}
