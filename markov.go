package main

import (
	"bufio"
	"io"
	"strings"
)

type Markov struct {
	db   *DB
	ntok int
}

func NewMarkov(ntok int, db *DB) *Markov {
	if ntok < 1 {
		panic("ntok too small")
	}

	return &Markov{
		db,
		ntok,
	}
}

func (m *Markov) Parse(r io.Reader) error {
	scanner := bufio.NewScanner(r)
	scanner.Split(scan)

	tokbuf := make([]string, m.ntok)

	tx, err := m.db.Begin()
	if err != nil {
		return err
	}

	for scanner.Scan() {
		tok := scanner.Text()

		err = tx.Insert(strings.Join(tokbuf, " "), tok)
		if err != nil {
			tx.Rollback()
			return err
		}

		copy(tokbuf, tokbuf[1:])
		tokbuf[m.ntok-1] = tok
	}

	err = scanner.Err()
	if err != io.EOF {
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
	buf := make([]string, mintok)
	tokbuf := make([]string, m.ntok)

	for len(buf) < mintok {
		tok, err := m.db.Next(strings.Join(tokbuf, " "))
		if err != nil {
			return "", err
		}

		buf = append(buf, tok)
		copy(tokbuf, tokbuf[1:])
		tokbuf[m.ntok-1] = tok
	}

	return strings.Join(buf, " "), nil
}
