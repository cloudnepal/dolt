#!/usr/bin/env bats
load $BATS_TEST_DIRNAME/helper/common.bash

setup() {
    setup_common

    dolt sql <<SQL
CREATE TABLE test (
  pk BIGINT NOT NULL COMMENT 'tag:0',
  c1 BIGINT COMMENT 'tag:1',
  c2 BIGINT COMMENT 'tag:2',
  c3 BIGINT COMMENT 'tag:3',
  c4 BIGINT COMMENT 'tag:4',
  c5 BIGINT COMMENT 'tag:5',
  PRIMARY KEY (pk)
);
SQL
}

teardown() {
    assert_feature_version
    teardown_common
}

@test "json-diff: new row" {
    dolt add .
    dolt commit -m table
    dolt sql -q 'insert into test values (0,0,0,0,0,0)'
    dolt add .
    dolt commit -m row

    dolt diff -r json
    run dolt diff -r json
    [ "$status" -eq 0 ]
    [ "$output" = "" ]

    run dolt diff -r json head
    [ "$status" -eq 0 ]
    [ "$output" = "" ]

    dolt diff -r json head^
    run dolt diff -r json head^
    [ "$status" -eq 0 ]
    [[ "$output" =~ '{"tables":[{"name":"test","schema_diff":[],"data_diff":[{"from_row":{},"to_row":{"c1":0,"c2":0,"c3":0,"c4":0,"c5":0,"pk":0}}]}]}' ]] || false

    dolt diff -r json head^ head
    run dolt diff -r json head^ head
    [ "$status" -eq 0 ]
    [[ "$output" =~ '{"tables":[{"name":"test","schema_diff":[],"data_diff":[{"from_row":{},"to_row":{"c1":0,"c2":0,"c3":0,"c4":0,"c5":0,"pk":0}}]}]}' ]] || false

    dolt diff -r json head head^
    run dolt diff -r json head head^
    [ "$status" -eq 0 ]
    [[ "$output" =~ '{"tables":[{"name":"test","schema_diff":[],"data_diff":[{"from_row":{"c1":0,"c2":0,"c3":0,"c4":0,"c5":0,"pk":0},"to_row":{}}]}]}' ]] || false
}

@test "json-diff: data and schema changes" {
    dolt sql <<SQL
drop table test;
create table test (pk int primary key, c1 int, c2 int);
insert into test values (1,2,3);
insert into test values (4,5,6);
SQL
    dolt commit -am "First commit"

    dolt sql <<SQL
alter table test 
drop column c2,
add column c3 varchar(10);
insert into test values (7,8,9);
delete from test where pk = 1;
update test set c1 = 100 where pk = 4;
SQL

    dolt diff -r json
    run dolt diff -r json

    EXPECTED=$(cat <<'EOF'
{"tables":[{"name":"test","schema_diff":["ALTER TABLE `test` DROP `c2`;","ALTER TABLE `test` ADD `c3` varchar(10);"],"data_diff":[{"from_row":{"c1":2,"c3":3,"pk":1},"to_row":{}},{"from_row":{"c1":5,"c3":6,"pk":4},"to_row":{"c1":100,"pk":4}},{"from_row":{},"to_row":{"c1":8,"pk":7}}]}]}
EOF
)

    [ "$status" -eq 0 ]
    [[ "$output" =~ "$EXPECTED" ]] || false

    run dolt diff -r json --data --schema
    [ "$status" -eq 0 ]
    [[ "$output" =~ "$EXPECTED" ]] || false

    dolt diff -r json --schema
    run dolt diff -r json --schema

    EXPECTED=$(cat <<'EOF'
{"tables":[{"name":"test","schema_diff":["ALTER TABLE `test` DROP `c2`;","ALTER TABLE `test` ADD `c3` varchar(10);"],"data_diff":[]}]}
EOF
)
    [[ "$output" =~ "$EXPECTED" ]] || false

    dolt diff -r json --data
    run dolt diff -r json --data
    EXPECTED=$(cat <<'EOF'
{"tables":[{"name":"test","schema_diff":[],"data_diff":[{"from_row":{"c1":2,"c3":3,"pk":1},"to_row":{}},{"from_row":{"c1":5,"c3":6,"pk":4},"to_row":{"c1":100,"pk":4}},{"from_row":{},"to_row":{"c1":8,"pk":7}}]}]}
EOF
)
    
    [[ "$output" =~ "$EXPECTED" ]] || false
}

@test "json-diff: with table args" {
    dolt sql -q 'create table other (pk int not null primary key)'
    dolt add .
    dolt commit -m tables
    dolt sql -q 'insert into test values (0,0,0,0,0,0)'
    dolt sql -q 'insert into other values (9)'

    dolt diff -r json test
    run dolt diff -r json test
    [ "$status" -eq 0 ]
    [[ "$output" =~ '{"tables":[{"name":"test","schema_diff":[],"data_diff":[{"from_row":{},"to_row":{"c1":0,"c2":0,"c3":0,"c4":0,"c5":0,"pk":0}}]}]}' ]] || false
    [[ ! "$output" =~ "other" ]] || false

    dolt diff -r json other
    run dolt diff -r json other
    [ "$status" -eq 0 ]
    [[ "$output" =~ '{"tables":[{"name":"other","schema_diff":[],"data_diff":[{"from_row":{},"to_row":{"pk":9}}]}]}' ]] || false
    [[ ! "$output" =~ "test" ]] || false
}

@test "json-diff: with where clause" {
    dolt sql -q "insert into test values (0, 0, 0, 0, 0, 0)"
    dolt sql -q "insert into test values (1, 1, 1, 1, 1, 1)"
    dolt add test
    dolt commit -m "table created"
    dolt sql -q "insert into test values (2, 222, 0, 0, 0, 0)"
    dolt sql -q "insert into test values (3, 333, 0, 0, 0, 0)"

    run dolt diff -r json --where "to_pk=2"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "222" ]] || false
    [[ ! "$output" =~ "333" ]] || false
}

@test "json-diff: --cached" {
    run dolt diff -r json --cached
    [ $status -eq 0 ]
    [ "$output" = "" ]

    dolt add test
    dolt diff -r json --cached
    run dolt diff -r json --cached
    [ $status -eq 0 ]
    [[ $output =~ '{"tables":[{"name":"test","schema_diff":' ]] || false  

    dolt commit -m "First commit"
    dolt sql -q "insert into test values (0, 0, 0, 0, 0, 0)"
    run dolt diff -r json
    [ $status -eq 0 ]

    CORRECT_DIFF=$output
    dolt add test
    run dolt diff -r json --cached
    [ $status -eq 0 ]
    [ "$output" = "$CORRECT_DIFF" ]

    # Make sure it ignores changes to the working set that aren't staged
    dolt sql -q "create table test2 (pk int, c1 int, primary key(pk))"
    run dolt diff -r json --cached
    [ $status -eq 0 ]
    [ "$output" = "$CORRECT_DIFF" ]
}

@test "json-diff: table with same name on different branches with different primary key sets" {
    dolt branch another-branch
    dolt sql <<SQL
CREATE TABLE a (
  id int PRIMARY KEY,
  pv1 int,
  pv2 int
);
SQL
    dolt add -A
    dolt commit -m "hi"
    dolt checkout another-branch
    dolt sql <<SQL
CREATE TABLE a (
  id int,
  cv1 int,
  cv2 int,
  primary key (id, cv1)
);
SQL
    dolt add -A
    dolt commit -m "hello"
    run dolt diff -r json main another-branch
    echo $output
    ! [[ "$output" =~ "panic" ]] || false
    [[ "$output" =~ "pv1" ]] || false
    [[ "$output" =~ "cv1" ]] || false
    [ $status -eq 0 ]
}


@test "json-diff: keyless table" {
    dolt sql -q "create table t(pk int, val int)"
    dolt commit -am "cm1"

    dolt sql -q "INSERT INTO t values (1, 1)"

    dolt diff -r json
    run dolt diff -r json
    [ $status -eq 0 ]
    [[ "$output" = '{"tables":[{"name":"t","schema_diff":[],"data_diff":[{"from_row":{},"to_row":{"pk":1,"val":1}}]}]}' ]] || false

    dolt commit -am "cm2"

    dolt sql -q "INSERT INTO t values (1, 1)"

    dolt diff -r json 
    run dolt diff -r json 
    [ $status -eq 0 ]
    [[ "$output" = '{"tables":[{"name":"t","schema_diff":[],"data_diff":[{"from_row":{},"to_row":{"pk":1,"val":1}}]}]}' ]] || false

    dolt commit -am "cm3"

    dolt sql -q "UPDATE t SET val = 2 where pk = 1"
    
    dolt diff -r json 
    run dolt diff -r json

    EXPECTED=$(cat <<'EOF'
{"tables":[{"name":"t","schema_diff":[],"data_diff":[{"from_row":{"pk":1,"val":1},"to_row":{}},{"from_row":{"pk":1,"val":1},"to_row":{}},{"from_row":{},"to_row":{"pk":1,"val":2}},{"from_row":{},"to_row":{"pk":1,"val":2}}]}]}
EOF
)
    
    [ $status -eq 0 ]
    [[ "$output" =~ "$EXPECTED" ]] || false
}

@test "json-diff: adding and removing primary key" {
    dolt sql <<SQL
create table t(pk int, val int);
insert into t values (1,1);
SQL
    dolt commit -am "creating table"

    dolt sql -q "alter table t add primary key (pk)"

    dolt diff -r json
    run no_stderr dolt diff -r json
    [ $status -eq 0 ]
    [ "$output" = '{"tables":[{"name":"t","schema_diff":["ALTER TABLE `t` DROP PRIMARY KEY;","ALTER TABLE `t` ADD PRIMARY KEY (pk);"],"data_diff":[]}]}' ]

    run no_stdout dolt diff -r json
    [ $status -eq 0 ]
    [ "$output" = 'Primary key sets differ between revisions for table t, skipping data diff' ]

    dolt diff -r json
    run dolt diff -r json
    [ $status -eq 0 ]
    [[ "$output" =~ '{"tables":[{"name":"t","schema_diff":["ALTER TABLE `t` DROP PRIMARY KEY;","ALTER TABLE `t` ADD PRIMARY KEY (pk);"]' ]] || false
    [[ "$output" =~ 'Primary key sets differ between revisions for table t, skipping data diff' ]] || false
    

    dolt commit -am 'added primary key'

    dolt sql -q "alter table t drop primary key"

    dolt diff -r json
    run dolt diff -r json
    [ $status -eq 0 ]
    [[ "$output" =~ '{"tables":[{"name":"t","schema_diff":["ALTER TABLE `t` DROP PRIMARY KEY;"]' ]] || false
    [[ "$output" =~ 'Primary key sets differ between revisions for table t, skipping data diff' ]] || false
}

function no_stderr {
    "$@" 2>/dev/null
}

function no_stdout {
    "$@" 1>/dev/null
}

@test "json-diff: works with spaces in column names" {
   dolt sql -q 'CREATE table t (pk int, `type of food` varchar(100));'
   dolt sql -q "INSERT INTO t VALUES (1, 'ramen');"


       EXPECTED_TABLE1=$(cat <<'EOF'
{"tables":[{"name":"t","schema_diff":["CREATE TABLE `t` (\n  `pk` int,\n  `type of food` varchar(100)\n) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;"],"data_diff":[{"from_row":{},"to_row":{"pk":1,"type of food":"ramen"}}]},{"name":"test","schema_diff":["CREATE TABLE `test` (\n  `pk` bigint NOT NULL COMMENT 'tag:0',\n  `c1` bigint COMMENT 'tag:1',\n  `c2` bigint COMMENT 'tag:2',\n  `c3` bigint COMMENT 'tag:3',\n  `c4` bigint COMMENT 'tag:4',\n  `c5` bigint COMMENT 'tag:5',\n  PRIMARY KEY (`pk`)\n) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;"],"data_diff":[]}]}
EOF
)
   
   dolt diff -r json
   run dolt diff -r json
   [ $status -eq 0 ]
   [[ $output =~ "$EXPECTED" ]] || false
}
