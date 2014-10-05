package main

import (
	"flag"
	"log"
	"os"
	"strings"
)

var (
	filename string
	mintok   int
	db       string
	ntok     int
	nstr     int
)

const terminals = ".!?\n"

func init() {
	flag.StringVar(&filename, "p", "", "file to parse")
	flag.IntVar(&mintok, "m", 20, "minimum tokens to generate")
	flag.StringVar(&db, "db", "markov.db", "markov chain database")
	flag.IntVar(&ntok, "t", 2, "number of tokens to use for chain")
	flag.IntVar(&nstr, "n", 0, "number of strings to generate")
}

func main() {
	flag.Parse()

	switch {
	case filename != "":
		doParse()
	case nstr > 0:
		doGenerate()
	default:
		flag.PrintDefaults()
	}
}

func doParse() {
	log.Printf("opening db [%s] for chain storage", db)
	db, err := OpenDB(db)
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("opening file [%s] for chain generation", filename)
	f, err := os.Open(filename)
	if err != nil {
		log.Fatal(err)
	}

	m := NewMarkov(ntok, terminals, db)

	log.Printf("parsing file with ntok = [%d]", ntok)
	err = m.Parse(f)

	if err != nil {
		log.Fatal(err)
	}

	err = m.Close()
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("success")
}

func doGenerate() {
	log.Printf("opening db [%s] for chain storage", db)
	db, err := OpenDB(db)
	if err != nil {
		log.Fatal(err)
	}

	m := NewMarkov(ntok, terminals, db)
	strs := make([]string, nstr)

	for i := 0; i < nstr; i++ {
		log.Printf("generating string with mintok = [%v]", mintok)
		strs[i], err = m.Generate(mintok)
		if err != nil {
			log.Fatal(err)
		}
	}

	log.Printf("generated [%d] strings:\n%s", nstr, strings.Join(strs, "\n"))

	err = m.Close()
	if err != nil {
		log.Fatal(err)
	}
}
