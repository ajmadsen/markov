package main

import "testing"

func TestNull(t *testing.T) {
	db, err := OpenDB("test.db")
	if err != nil {
		t.Fatal(err)
	}
	db.db.Exec(`DELETE FROM chain`)

	db.Insert("this\000that", "the")
	db.Insert("this\000that", "other")
	db.Insert("this\000that", "word")
	db.Insert("this\000and", "that")
	db.Insert("this\000or", "that")

	var cnt int
	cntrow := db.count.QueryRow("this\000that")
	err = cntrow.Scan(&cnt)

	if cnt != 3 {
		t.Fatalf("sqlite doesn't like null chars: found [%d] rows when it should have found [%d]", cnt, 3)
	}

	t.Log("this\000that")
}
