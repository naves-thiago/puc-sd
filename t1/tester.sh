#!/bin/bash
lua server.lua $1 &
PID=$!
lua test.lua $2 $1

kill -9 $PID
